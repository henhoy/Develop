SET NOCOUNT ON;
DECLARE @objectid int;
DECLARE @indexid int;
DECLARE @partitioncount bigint;
DECLARE @schemaname nvarchar(130); 
DECLARE @objectname nvarchar(130); 
DECLARE @indexname nvarchar(130); 
DECLARE @partitionnum bigint;
DECLARE @partitions bigint;
DECLARE @frag float;
DECLARE @command nvarchar(4000); 
declare @dbname nvarchar(100);
declare @dbid int;
declare @exec_stmt nvarchar(1600);
declare @pagecount int;

declare @minpagecount int;
declare @avgfragmentation int;

-- Set run time variables
set @minpagecount = 250;
set @avgfragmentation = 10;

CREATE TABLE #work_to_do(
	[objectid] [int] NULL,
	[objectname] [sysname] NOT NULL,
	[indexid] [int] NULL,
	[indexname] [sysname] NULL,
	[schemaname] [sysname] NOT NULL,
	[partitionnum] [int] NULL,
	[frag] [float] NULL,
	[pagecount] [bigint] NULL
)

declare dbname_crr cursor for 
select name, database_id from master.sys.databases
where name not in ('tempdb','model','master','mssql_systemresource_db','msdb','distribution')
and name not like 'AdventureWorks%'
and state = 0;

open dbname_crr
fetch dbname_crr into @dbname, @dbid

while @@FETCH_STATUS >= 0
begin  
  -- Conditionally select tables and indexes from the sys.dm_db_index_physical_stats function 
  -- and convert object and index IDs to names.
  
  set @exec_stmt = 'use ' +  quotename(@dbname, N'[') + ' ' +
  'insert INTO #work_to_do
  SELECT
    ddips.object_id AS objectid, o.name as objectname,
    ddips.index_id AS indexid, i.name as indexname,
	s.name as schemaname,
    partition_number AS partitionnum,
    avg_fragmentation_in_percent AS frag, ddips.page_count as pagecount
  FROM sys.dm_db_index_physical_stats (' + cast(@dbid as nvarchar) + ', NULL, NULL , NULL, ''LIMITED'') ddips
  join sys.objects o on o.object_id = ddips.object_id
  join sys.indexes i on i.index_id = ddips.index_id and i.object_id = ddips.object_id
  join sys.schemas s on s.schema_id = o.schema_id
  WHERE ddips.avg_fragmentation_in_percent > ' + cast(@avgfragmentation as nvarchar) + ' AND ddips.index_id > 0;'

  --print @exec_stmt; -- DEBUG
  exec (@exec_stmt)

  -- Declare the cursor for the list of partitions to be processed.
  DECLARE partitions CURSOR FOR SELECT objectname, indexname, schemaname, frag FROM #work_to_do where pagecount > 10 --@minpagecount;
  
  -- Open the cursor.
  OPEN partitions;
  
  -- Loop through the partitions.
  WHILE (1=1)
      BEGIN;
          FETCH NEXT
             FROM partitions
			 INTO @objectname, @indexname, @schemaname, @frag;
          IF @@FETCH_STATUS < 0 BREAK;

          --SELECT @partitioncount = count (*)
          --FROM sys.partitions
          --WHERE object_id = @objectid AND index_id = @indexid;
  
  -- 30 is an arbitrary decision point at which to switch between reorganizing and rebuilding.
          --IF @frag < 30.0
          --    SET @command = N'use ' +  quotename(@dbname, N'[') + ' ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REORGANIZE';
          IF @frag >= 10.0
              SET @command = N'use ' +  quotename(@dbname, N'[') + ' ALTER INDEX ' + quotename(@indexname, N'[') + N' ON ' + quotename(@schemaname, N'[') + N'.' + quotename(@objectname, N'[') + N' REBUILD';
          EXEC (@command);
          --PRINT N'Executed: ' + @command;
      END;
  
  -- Close and deallocate the cursor.
  CLOSE partitions;
  DEALLOCATE partitions;

  -- Truncate the temporary table
  truncate table #work_to_do;
  
  fetch dbname_crr into @dbname, @dbid
  --GO
end;

close dbname_crr;
deallocate dbname_crr;

DROP TABLE #work_to_do;