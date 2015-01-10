
Use MiracleDB;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas where name = 'stats')
BEGIN
	PRINT 'Creating the Schema (stats)'
	EXEC sp_executesql N'CREATE SCHEMA stats'
END ELSE BEGIN
	PRINT 'Schema (stats) already exists'
END
GO

IF EXISTS (SELECT * FROM sys.objects where object_id = OBJECT_ID('CollectStatisticsInfo') and schema_id = schema_id('stats'))
BEGIN
	DROP PROCEDURE stats.CollectStatisticsInfo
END ELSE BEGIN
	PRINT 'Procedure (stats.CollectStatisticsInfo) was not found'
END
GO

CREATE PROCEDURE stats.CollectStatisticsInfo
 @database_id int = 0,
 @object_id int = 0,
 @index_id int = 0,
 @UpdateStatsPercentage int = 10,
 @DoFullScan smallint = 1,
 @SamplePercentage int = 25
AS

SET NOCOUNT ON

DECLARE @db_id int
DECLARE @db_name sysname
DECLARE @sqlcmd NVARCHAR(4000)

DECLARE MyDatabases CURSOR READ_ONLY FOR 
SELECT database_id, name FROM sys.databases
WHERE 
	database_id not in (1,2,3,4)
	and state_desc = 'ONLINE'
	and is_read_only = 0
	and (database_id = @database_id or @database_id = 0)
ORDER BY name

OPEN MyDatabases

FETCH NEXT FROM MyDatabases
INTO @db_id, @db_name

WHILE (@@fetch_status = 0) BEGIN

SET @sqlcmd = 'USE ' + Quotename(@db_name) + ' 
;with cte as
(
select 
 sys.stats.object_id,
 OBJECT_NAME(sys.stats.object_id) as colTableName,
 sys.stats.name,
 sys.sysindexes.indid as IndexID,
 Schema_name(sys.tables.schema_id) as SchemaName,
 rowcnt,
 rowmodctr,
 CASE WHEN rowcnt = 0 THEN 0 ELSE (CAST(rowmodctr as bigint) * 100) / CAST(rowcnt as BIGint) END as ColPercentModified
from sys.stats
inner join sys.sysindexes on (sys.stats.object_id = sys.sysindexes.id) and (sys.stats.stats_id = sys.sysindexes.indid)
inner join sys.tables on (sys.stats.object_id = sys.tables.object_id)
where auto_created = 0 and rowmodctr > 0 and rowcnt > 0
)
INSERT INTO MiracleDB.base.Scheduler (ScheduleType, RunAt, sqlstring, DateCreated)
SELECT 
 ''UPDATE STATISTICS'',
 Getdate(),
 CASE WHEN ' + CAST(@DoFullScan as CHAR(1)) + '= 1
	THEN
		''USE ' + Quotename(@db_name) + ';UPDATE STATISTICS '' + quotename(SchemaName) + ''.'' + quotename(colTableName) + '' '' +  quotename(name) + '' WITH FULLSCAN''
	ELSE
		''USE ' + Quotename(@db_name) + ';UPDATE STATISTICS '' + quotename(SchemaName) + ''.'' + quotename(colTableName) + '' '' +  quotename(name) + '' WITH SAMPLE ' + Cast(@SamplePercentage as varchar(2)) + ' PERCENT''
	END
	as SQLCmd,
 Getdate()
from cte
where (1 = 1)
AND ((ColPercentModified > ' + CAST(@UpdateStatsPercentage as varchar(2)) + ') OR (' + CAST(@UpdateStatsPercentage as varchar(2)) + ' = 0))
AND ((Object_id = ' + CAST(@Object_id as varchar) + ') OR (' + CAST(@object_id as varchar) + ' = 0))
AND ((IndexID = ' + CAST(@index_id as varchar) + ') OR (' + CAST(@Index_ID as varchar) + ' = 0))'

EXEC sp_executesql @sqlcmd

FETCH NEXT FROM MyDatabases
INTO @db_id, @db_name

END

CLOSE MyDatabases
DEALLOCATE MyDatabases

GO