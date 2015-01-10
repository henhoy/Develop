
/**********    MiracleDB - Indexing    ****************************************


Author:			Miracle SQL Server Team
Contact:		MiracleDB@miracleas.dk (http://www.miracleas.dk)
Documentation:	http://MiracleDB.codeplex.com/
Created:		2010-08-21 
Modified:		2010-08-21
Version:		1

Overview:		This part of the MiracleDB solution can be used to schedule
				intelligent index rebuilds and reorganizations, as well
				as keep track of time spend, and fragmentation levels.
				The solution also includes some usefull views and procedures
				for easy access to index stats from the SQL Server.

How to install:	Just open this file in SQL Server Management Studio on the
				target instance, and hit F5.
				This solution requires a database named MiracleDB, and if one
				does not exists, one will be created.

Detailed desc:	For automatic index maintenance, you need to schedule
				EXEC idx.CollectData
				followed by:
				EXEC idx.ExecuteTasks @ScheduleType = 'Index maintenance'
				
				idx.CollectData collects a list of all indexes that needs to 
				be rebuild or reorganized.
				base.ExecuteTasks performes the commands, and logs the stats.
				
				To see daily stats for the maintenance jobs, you can run:
				SELECT * FROM idx.MaintenanceStats
				
				To see all the stats:
				SELECT * FROM idx.MaintenanceLog
				
				Other usefull tools are:
				SELECT * FROM idx.MissingIndexes
				EXEC idx.IndexUsage
				EXEC idx.IndexUsage @DatabaseName = 'MyDatabase'
				EXEC idx.IndexUsage @DatabaseName = 'MyDatabase', @SchemaName = '[dbo]', @TableName = '[MyTable]'
				EXEC idx.IndexUsage @DatabaseName = 'MyDatabase', @TableName = '[MyTable]'
				@SchemaName is default [dbo] if not explicit added
				

******************************************************************************/

USE master
GO
SET NOCOUNT ON
GO
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'MiracleDB') BEGIN
	PRINT 'Creating MiracleDB database...'
	CREATE DATABASE MiracleDB
END
ELSE
	PRINT 'MiracleDB database already exists'
GO

USE MiracleDB
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'MiracleDB') BEGIN
	PRINT 'Creating MiracleDB schema...'
	EXEC sp_executesql N'CREATE SCHEMA MiracleDB'
END ELSE 
	PRINT 'MiracleDB schema already exists'
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'Version' AND schema_id = schema_id('MiracleDB')) BEGIN
	PRINT 'Creating MiracleDB.Version table...'
	CREATE TABLE [MiracleDB].[Version] (
		Id INT IDENTITY PRIMARY KEY,
		AppName VARCHAR(200) NOT NULL,
		Version INT NOT NULL,
		DeployDate DATETIME DEFAULT GETDATE()
	)	
END ELSE
	PRINT 'MiracleDB.Version table already exists'
GO

IF NOT EXISTS(
	SELECT * 
	FROM 
		sys.objects t1 
		inner join sys.columns t2 on t1.object_id = t2.object_id
	WHERE 
		t1.name = 'Version' 
		AND t1.schema_id = schema_id('MiracleDB')
		AND t2.name = 'Version'
		AND t2.system_type_id = 167
		AND t2.max_length = 200
) BEGIN
	PRINT 'Altering MiracleDB.Version - Set Version column type to VARCHAR(200)'
	ALTER TABLE MiracleDB.Version
	ALTER COLUMN Version VARCHAR(200)
END ELSE
	PRINT 'MiracleDB.Version.Version column already VARCHAR(200)'


DECLARE @Version VARCHAR(200)
SET @Version = '1.4' --This is the version of the MiracleDB idx stuff about to be deployed
IF NOT EXISTS (SELECT * FROM MiracleDB.Version WHERE AppName = 'idx')
	INSERT INTO MiracleDB.Version (AppName, Version) VALUES ('idx', @Version)
ELSE BEGIN
	DECLARE @CurrentVersion VARCHAR(200)
	SELECT TOP 1 @CurrentVersion = Version FROM MiracleDB.Version WHERE AppName = 'idx' ORDER BY Version DESC
	IF @CurrentVersion >= @Version 
		RAISERROR ('Current version of MiracleDB idx is the same or newer than the one you are trying to deploy.',10,1)
	INSERT INTO MiracleDB.Version (AppName, Version) VALUES ('idx', @Version)
END



DECLARE @VersionBase VARCHAR(200)
SET @VersionBase = '1.0' --This is the version of the MiracleDB idx stuff about to be deployed
IF NOT EXISTS (SELECT * FROM MiracleDB.Version WHERE AppName = 'base')
	INSERT INTO MiracleDB.Version (AppName, Version) VALUES ('base', @VersionBase)
ELSE BEGIN
	DECLARE @CurrentVersionBase VARCHAR(200)
	SELECT TOP 1 @CurrentVersionBase = Version FROM MiracleDB.Version WHERE AppName = 'base' ORDER BY Version DESC
	IF @CurrentVersionBase >= @Version 
		RAISERROR ('Current version of MiracleDB base is the same or newer than the one you are trying to deploy.',10,1)
	INSERT INTO MiracleDB.Version (AppName, Version) VALUES ('base', @VersionBase)
END




--Begin Index deployment
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'idx') BEGIN
	PRINT 'Creating idx schema...'
	EXEC sp_executesql N'CREATE SCHEMA idx'
END ELSE
	PRINT 'idx schema already exists'
GO


IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'base') BEGIN
	PRINT 'Creating base schema...'
	EXEC sp_executesql N'CREATE SCHEMA base'
END ELSE
	PRINT 'base schema already exists'
GO


IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'Settings' AND schema_id = schema_id('base')) BEGIN
	PRINT 'Creating base.Settings table...'
	CREATE TABLE base.Settings (
		ConfigurationKey VARCHAR(200) PRIMARY KEY,
		Value VARCHAR(200),
		Description VARCHAR(4000)
	)	
END ELSE
	PRINT 'base.Settings table already exists'
GO

PRINT 'Dropping idx.QuoteName function...'
IF EXISTS(SELECT * FROM sys.objects WHERE name = 'QuoteName' AND schema_id = schema_id('idx')) BEGIN
	DROP FUNCTION idx.QuoteName
END
GO

PRINT 'Creating or updating base.QuoteName function...'
IF EXISTS(SELECT * FROM sys.objects WHERE name = 'QuoteName' AND schema_id = schema_id('base')) BEGIN
	DROP FUNCTION base.QuoteName
END
GO

CREATE FUNCTION base.QuoteName (
	@Input VARCHAR(500)
)
RETURNS VARCHAR(500)
AS
BEGIN
DECLARE @Output VARCHAR(500)
SET @Output = LTRIM(RTRIM(@Input))
IF NOT LEFT(@Output, 1) = '[' 
	SET @Output = '[' + @Output
IF NOT RIGHT(@Output, 1) = ']' 
	SET @Output = @Output + ']'
RETURN @Output
END
GO


PRINT 'Dropping idx.GetConfigurationValue function...'
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'GetConfigurationValue' AND schema_id = schema_id('idx')) BEGIN
	DROP FUNCTION idx.GetConfigurationValue
END
GO

PRINT 'Creating or updating base.GetConfigurationValue function...'
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'GetConfigurationValue' AND schema_id = schema_id('base')) BEGIN
	DROP FUNCTION base.GetConfigurationValue
END
GO


CREATE FUNCTION base.GetConfigurationValue (
	@ConfigurationKey VARCHAR(200)
)
RETURNS VARCHAR(200)
AS
BEGIN
RETURN (SELECT Value FROM base.Settings WHERE ConfigurationKey = @ConfigurationKey)
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'Settings' AND schema_id = schema_id('idx'))
BEGIN
    declare @sqlstmt varchar(max);
    if (substring(@@version,11,15) = 'SQL Server 2008')
    begin                             
	  set @sqlstmt = 'MERGE INTO base.Settings dest ' +
	                    'USING idx.Settings src ON src.ConfigurationKey = dest.ConfigurationKey ' +
            	        'WHEN NOT MATCHED BY TARGET THEN ' +
	  	                'INSERT (ConfigurationKey, Value, Description) ' +
	  	                'VALUES (src.ConfigurationKey, src.Value, src.Description); ' +
	                    'DROP TABLE idx.Settings;';
      print @sqlstmt;
      exec @sqlstmt;
    end;
    if (substring(@@version,11,15) = 'SQL Server 2005')
    begin
	  set @sqlstmt = 'insert into base.settings ' + 
                      'select * from idx.settings idx ' +
                      'where idx.ConfigurationKey not in (select ConfigurationKey from base.settings); ' +
                      'DROP TABLE idx.Settings;';
      print @sqlstmt;
      exec @sqlstmt;
    end;
END

IF (base.GetConfigurationValue('Index_LowerFragmentationThreshold') IS NULL)
	INSERT INTO base.Settings (ConfigurationKey, Value, Description)
	VALUES ('Index_LowerFragmentationThreshold', '15', 'Indexes with fragmentation below this value, will not be optimized at all. Indexes with fragmentation between this value, and Index_HigerFragmentationThreshold will be reorganized')

IF (base.GetConfigurationValue('Index_LowerPageCountThreshold') IS NULL)
	INSERT INTO base.Settings (ConfigurationKey, Value, Description)
	VALUES ('Index_LowerPageCountThreshold', '50', 'Indexes with fewer pages than this value, will not be optimized at all')

IF (base.GetConfigurationValue('Index_DoOnlineIfPossible') IS NULL)
	INSERT INTO base.Settings (ConfigurationKey, Value, Description)
	VALUES ('Index_DoOnlineIfPossible', '1', 'If set to 1, all rebuilds will be performed online if possible. If set to 0, nothing will be performed online')

IF (base.GetConfigurationValue('Index_DoReorganizeIfOnlineNotPossible') IS NULL)
	INSERT INTO base.Settings (ConfigurationKey, Value, Description)
	VALUES ('Index_DoReorganizeIfOnlineNotPossible', '1', 'If set to 1, only online operations will be performed. If a rebuild cannot be performed online, it will revert to do reorganize only')

IF (base.GetConfigurationValue('Index_SortInTempDB') IS NULL)
	INSERT INTO base.Settings (ConfigurationKey, Value, Description)
	VALUES ('Index_SortInTempDB', 'ON', 'Perform sort in tempdb if set to ON. If set to OFF, it won'' use TempDB')

IF (base.GetConfigurationValue('Index_HigherFragmentationThreshold') IS NULL)
	INSERT INTO base.Settings (ConfigurationKey, Value, Description)
	VALUES ('Index_HigherFragmentationThreshold', '30', 'Indexes with fragmentation higher than this value, will be rebuild. Indexes with fragmentation between Index_LowerFragmentationThreshold, and this value will be reorganized')

IF (base.GetConfigurationValue('Index_HigherPageCountThreshold') IS NULL)
	INSERT INTO base.Settings (ConfigurationKey, Value, Description)
	VALUES ('Index_HigherPageCountThreshold', '0', 'Indexes with more pages than this value, will not be optimized at all. If value set to 0, there is no upper limit')

IF (base.GetConfigurationValue('Index_MAXDOP') IS NULL)
	INSERT INTO base.Settings (ConfigurationKey, Value, Description)
	VALUES ('Index_MAXDOP', '0', 'If set to 0, the MAXDOP setting from the server configuration is used. Otherwise the index will be rebuild using this MAXDOP value if the SQL Server version is Developer or Enterprise.')
GO


IF NOT EXISTS(SELECT * FROM sys.objects WHERE name = 'IndexStats' AND schema_id = schema_id('idx')) BEGIN
	PRINT 'Creating idx.IndexStats table...'
	CREATE TABLE idx.IndexStats (
		id INT IDENTITY(1,1) PRIMARY KEY,
		ScheduleId int,
		database_id int, 
		database_name sysname,
		object_id int,
		object_name sysname,
		schema_name sysname,
		index_id int,
		index_name sysname,
		partition_number int,
		IsPartitioned int,
		avg_fragmentation_in_percent float,
		page_count int,
		OnlineRebuildPossible int,
		DateDetected datetime,	
		ReadyForExecution int default 0,				
		BatchId uniqueidentifier,
		avg_fragmentation_in_percent_after float,
		page_count_after int,
		PerformedOnline bit,						--Was the rebuild performed online?
		Type VARCHAR(10),
	)
	CREATE INDEX IX_IndexStats_BatchId ON idx.IndexStats (BatchId)
END ELSE
	PRINT 'idx.IndexStats table already exists'
GO


IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'Scheduler' AND schema_id = schema_id('base')) BEGIN
	PRINT 'Creating base.Scheduler table...'
	CREATE TABLE base.Scheduler (
		ScheduleId int identity(1,1) primary key,
		ScheduleType nvarchar(50), -- index reorg, index rebuild, backup osv.
		sqlstring nvarchar(max),
		RunAt datetime,
		BatchId uniqueidentifier,
		DateStart datetime,
		DateEnd dateTime,
		DateCreated datetime,
		ReturnCode nvarchar(100),
		ErrorMessage nvarchar(2048)
	)
END ELSE
	PRINT 'base.Scheduler already exists'
GO

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'Scheduler' AND schema_id = schema_id('idx'))
BEGIN
	SET IDENTITY_INSERT base.Scheduler ON
	INSERT INTO base.Scheduler (ScheduleId, ScheduleType, sqlstring, RunAt, BatchId, DateStart,DateEnd, DateCreated, ReturnCode, ErrorMessage)
	SELECT ScheduleId, ScheduleType, sqlstring, RunAt, BatchId, DateStart,DateEnd, DateCreated, ReturnCode, ErrorMessage
	FROM idx.Scheduler
	SET IDENTITY_INSERT base.Scheduler OFF
	DROP TABLE idx.Scheduler
END


PRINT 'Dropping idx.ExecuteTasks procedure...'
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'ExecuteTask' AND schema_id = schema_id('idx')) BEGIN
	DROP PROCEDURE idx.ExecuteTask
END
GO

PRINT 'Creating or updating base.ExecuteTasks procedure...'
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'ExecuteTask' AND schema_id = schema_id('base')) BEGIN
	DROP PROCEDURE base.ExecuteTask
END
GO

CREATE PROCEDURE base.ExecuteTask
@ScheduleId INT -- id of task to run				
AS
SET NOCOUNT ON
DECLARE @Sqltext NVARCHAR(MAX)
DECLARE @BatchId uniqueidentifier
SET @BatchId = NEWID()


UPDATE base.Scheduler
SET BatchId = @BatchId, DateStart = GETDATE()
WHERE 
	ScheduleId = @ScheduleId
	AND DateStart IS NULL
SELECT
	@Sqltext = sqlstring
FROM base.Scheduler
WHERE 
	ScheduleId = @ScheduleId
	
BEGIN TRY
	EXEC sp_executesql @Sqltext
END TRY
BEGIN CATCH
	UPDATE base.Scheduler
	SET 
		ReturnCode = @@ERROR, ErrorMessage = ERROR_MESSAGE()
	WHERE 
		ScheduleId = @ScheduleId
END CATCH
	

UPDATE base.Scheduler
SET DateEnd = GETDATE()
WHERE ScheduleId = @ScheduleId
GO


PRINT 'Dropping idx.CreateTask procedure...'
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'CreateTask' AND schema_id = schema_id('idx')) BEGIN
	DROP PROCEDURE idx.CreateTask
END
GO


PRINT 'Creating or updating base.CreateTask procedure...'
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'CreateTask' AND schema_id = schema_id('base')) BEGIN
	DROP PROCEDURE base.CreateTask
END
GO

CREATE PROCEDURE base.CreateTask
@ScheduleType NVARCHAR(100),
@sqlstring NVARCHAR(MAX) = NULL,
@RunAt DATETIME,
@id INT OUTPUT
AS
SET NOCOUNT ON
INSERT INTO base.Scheduler (ScheduleType, RunAt, sqlstring, DateCreated)
VALUES (@ScheduleType, @RunAt, @sqlstring, GETDATE())
SET @id = SCOPE_IDENTITY()

IF @RunAt IS NULL
	EXEC base.ExecuteTask @id
GO


PRINT 'Dropping idx.UpdateTask procedure...'
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'UpdateTask' AND schema_id = schema_id('idx')) BEGIN
	DROP PROCEDURE idx.UpdateTask
END
GO


PRINT 'Creating or updating base.UpdateTask procedure...'
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'UpdateTask' AND schema_id = schema_id('base')) BEGIN
	DROP PROCEDURE base.UpdateTask
END
GO

CREATE PROCEDURE base.UpdateTask
@id INT,
@sqlstring NVARCHAR(MAX)
AS
SET NOCOUNT ON
UPDATE base.Scheduler 
SET sqlstring = @sqlstring
WHERE ScheduleId = @id
GO



PRINT 'Dropping idx.ExecuteTasks procedure...'
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'ExecuteTasks' AND schema_id = schema_id('idx')) BEGIN
	DROP PROCEDURE idx.ExecuteTasks
END
GO



PRINT 'Creating or updating base.ExecuteTasks procedure...'
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'ExecuteTasks' AND schema_id = schema_id('base')) BEGIN
	DROP PROCEDURE base.ExecuteTasks
END
GO

CREATE PROCEDURE base.ExecuteTasks
@ScheduleType VARCHAR(200),
@TasksToExecute INT = -1 
				-- -1  executes all tasks en queue
				-- 0   executes nothing
				-- >=1 executes the number of elements, or untill no more tasks in queue
				
AS
SET NOCOUNT ON
DECLARE @Sqltext NVARCHAR(MAX)
DECLARE @BatchId uniqueidentifier
SET @BatchId = NEWID()
DECLARE @id TABLE (id INT)


WHILE (
	((@TasksToExecute > 0) OR (@TasksToExecute < 0))
	AND EXISTS (SELECT * FROM base.Scheduler 
				WHERE 
					DateStart IS NULL 
					AND RunAt < GETDATE()
					AND ScheduleType = @ScheduleType
					AND ScheduleId NOT IN ( --Cannot have parallel index rebuilds on the same object
						select ScheduleId from idx.IndexStats where object_id in (
							select object_id
							from 
								idx.IndexStats t1 
								INNER JOIN base.Scheduler t2 on t1.ScheduleId = t2.ScheduleId
							where t2.DateStart IS NOT NULL and t2.DateEnd IS NULL
						)
					) 
	)
)
BEGIN
	UPDATE TOP (1) base.Scheduler
	SET BatchId = @BatchId, DateStart = GETDATE()
	OUTPUT INSERTED.ScheduleId INTO @id
		WHERE 
		DateStart IS NULL 
		AND RunAt < GETDATE()
		AND ScheduleType = @ScheduleType
		AND ScheduleId NOT IN (
			select ScheduleId from idx.IndexStats where object_id in (
				select object_id
				from 
					idx.IndexStats t1 
					INNER JOIN base.Scheduler t2 on t1.ScheduleId = t2.ScheduleId
				where t2.DateStart IS NOT NULL and t2.DateEnd IS NULL
			)
)

	
	SELECT TOP 1
		@Sqltext = sqlstring
	FROM base.Scheduler
	WHERE 
		ScheduleId = (select id from @id)
	
	BEGIN TRY
		EXEC sp_executesql @Sqltext
	END TRY
	BEGIN CATCH
		UPDATE base.Scheduler
		SET 
			ReturnCode = @@ERROR, ErrorMessage = ERROR_MESSAGE()
		WHERE 
			ScheduleId = (select id from @id)
	END CATCH
	

	UPDATE TOP (1) base.Scheduler
	SET DateEnd = GETDATE()
	WHERE ScheduleId = (select id from @id)
	
	DELETE FROM @id
	
	SET @TasksToExecute = @TasksToExecute - 1
END	
GO




PRINT 'Creating or updating idx.CollectData procedure...'
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'CollectData' AND schema_id = schema_id('idx')) BEGIN
	DROP PROCEDURE idx.CollectData
END
GO

CREATE PROCEDURE idx.CollectData
@database_id int = 0,
@object_id int = 0,
@index_id int = 0,
@partition_id int = 0
AS
SET NOCOUNT ON
DECLARE @LowerFragmentationThreshold NVARCHAR(200)
SET @LowerFragmentationThreshold = base.GetConfigurationValue('Index_LowerFragmentationThreshold')
DECLARE @LowerPageCountThreshold NVARCHAR(200)
SET @LowerPageCountThreshold = base.GetConfigurationValue('Index_LowerPageCountThreshold')
DECLARE @HigherPageCountThreshold NVARCHAR(200)
SET @HigherPageCountThreshold = base.GetConfigurationValue('Index_HigherPageCountThreshold')

DECLARE dbs CURSOR
READ_ONLY
FOR 
SELECT database_id, name FROM sys.databases
WHERE 
	database_id not in (1,2,3,4)
	and state_desc = 'ONLINE'
	and is_read_only = 0
	and (database_id = @database_id or @database_id = 0)

DECLARE @sqlcmd NVARCHAR(4000)

DECLARE @db_id int
DECLARE @db_name sysname
OPEN dbs

FETCH NEXT FROM dbs INTO @db_id, @db_name
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN
		SET @sqlcmd = N'USE ' + quotename(@db_name) + ';'
		SET @sqlcmd = @sqlcmd + N'INSERT INTO MiracleDB.idx.IndexStats (database_id,database_name,object_id,object_name,schema_name,index_id,index_name,partition_number, IsPartitioned,avg_fragmentation_in_percent,page_count, OnlineRebuildPossible)'
		SET @sqlcmd = @sqlcmd + N'
(SELECT 
	t1.database_id, 
	t1_1.name,
	t1.object_id,  
	t3.name,
	t4.name, 
	t1.index_id, 
	t2.name, 
	partition_number,
	case when t7.object_id is null then 0 else 1 end as IsPartitioned, 
	avg_fragmentation_in_percent, 
	page_count, 
	min(case 
		when t6.name in (''text'', ''ntext'', ''image'', ''xml'', ''hierarchyid'', ''geometry'', ''geography'') then 0 
		when t6.name in (''varbinary'', ''varchar'', ''nvarchar'') and t5.max_length = -1 then 0
		else 1 end) as OnlineRebuildPossible
FROM 
	sys.dm_db_index_physical_stats(' + cast(@db_id as nvarchar(10)) + ', ' + case when @object_id <> 0 then cast(@object_id as nvarchar(10)) else 'null' end + ', ' + case when @index_id <> 0 then cast(@index_id as nvarchar(10)) else 'null' end + ', ' + case when @partition_id <> 0 then cast(@partition_id as nvarchar(10)) else 'null' end + ', null) t1
	inner join sys.databases t1_1 on t1.database_id = t1_1.database_id
	inner join sys.indexes t2 on t1.object_id = t2.object_id and t1.index_id = t2.index_id
	inner join sys.objects t3 on t1.object_id = t3.object_id
	inner join sys.schemas t4 on t3.schema_id = t4.schema_id
	inner join sys.columns t5 on t1.object_id = t5.object_id
	inner join sys.types t6 on t5.system_type_id = t6.system_type_id
	left outer join (
		select distinct p.object_id
		from 
			sys.partitions p
			inner join sys.indexes i on p.[object_id] = i.[object_id] and p.index_id = i.index_id
			inner join sys.data_spaces ds on i.data_space_id = ds.data_space_id
			inner join sys.partition_schemes ps on ds.data_space_id = ps.data_space_id
			inner JOIN sys.partition_functions pf on ps.function_id = pf.function_id
	) t7 on t1.object_id = t7.object_id
WHERE 
	t1.index_type_desc <> ''HEAP''
	and t4.name <> ''sys''
	and t1.database_id > 4 
	AND avg_fragmentation_in_percent >= ' + cast(@LowerFragmentationThreshold as nvarchar(10))+ '
	AND page_count between ' + cast(@LowerPageCountThreshold as nvarchar(10))+ ' and ' + case when @HigherPageCountThreshold = 0 then cast(2000000000 as nvarchar(15)) else cast(@HigherPageCountThreshold as nvarchar(10)) end + '
GROUP BY 
	t1.database_id, t1_1.name, t1.object_id, t3.name, t4.name, t1.index_id, t2.name, partition_number, t7.object_id, avg_fragmentation_in_percent, page_count
	)' 
	
	EXEC sp_executesql @sqlcmd
	
	END
	FETCH NEXT FROM dbs INTO @db_id, @db_name
END

CLOSE dbs
DEALLOCATE dbs


;with cte as (
	select 
		ROW_NUMBER() over (PARTITION BY  database_id,object_id,index_id,partition_number order by id) as rn,
		*
	FROM idx.IndexStats
	WHERE avg_fragmentation_in_percent_after IS NULL
)

DELETE FROM cte 
WHERE rn > 1



DECLARE @DoOnlineIfPossible VARCHAR(200)
SET @DoOnlineIfPossible = base.GetConfigurationValue('Index_DoOnlineIfPossible')
DECLARE @Index_DoReorganizeIfOnlineNotPossible VARCHAR(200)
SET @Index_DoReorganizeIfOnlineNotPossible = base.GetConfigurationValue('Index_DoReorganizeIfOnlineNotPossible')
DECLARE @SortInTempDB VARCHAR(200)
SET @SortInTempDB = base.GetConfigurationValue('Index_SortInTempDB')
DECLARE @HigherFragmentationThreshold VARCHAR(200)
SET @HigherFragmentationThreshold = base.GetConfigurationValue('Index_HigherFragmentationThreshold')
DECLARE @MaxDop VARCHAR(200)
SET @MaxDop = base.GetConfigurationValue('Index_MAXDOP')

DECLARE @database_id2 int
DECLARE @object_id2 int
DECLARE @index_id2 int
DECLARE @partition_id2 int
DECLARE @IsPartitioned int
DECLARE @schema_name sysname
DECLARE @index_name sysname
DECLARE @partition_number INT
DECLARE @avg_fragmentation_in_percent float
DECLARE @avg_fragmentation_in_percent_after float
DECLARE @page_count_after INT

DECLARE @PerformOnline VARCHAR(3)
DECLARE @Type VARCHAR(10)
DECLARE @OnlineRebuildPossible INT
DECLARE @SqlCommand NVARCHAR(2000)
DECLARE @ErrorMessage NVARCHAR(2048)
SET @ErrorMessage = ''
DECLARE @BatchId uniqueidentifier
SET @BatchId = NEWID()
DECLARE @id TABLE (id INT)

WHILE EXISTS (SELECT * FROM idx.IndexStats WHERE DateDetected IS NULL) 
BEGIN
	UPDATE TOP (1) idx.IndexStats
	SET BatchId = @BatchId, DateDetected = GETDATE()
	OUTPUT INSERTED.id INTO @id
	WHERE DateDetected IS NULL AND ReadyForExecution = 0
	
	SELECT TOP 1
		@database_id2 = database_id,
		@object_id2 = object_id, 
		@schema_name = schema_name,
		@index_id2 = index_id,
		@index_name = index_name,
		@OnlineRebuildPossible = OnlineRebuildPossible,
		@partition_number = partition_number,
		@IsPartitioned = IsPartitioned,
		@avg_fragmentation_in_percent = avg_fragmentation_in_percent
	FROM idx.IndexStats
	WHERE 
		id = (select id from @id)
		
	
	IF (@@VERSION not like '%Enterprise%' and @@VERSION not like '%Developer%')
		SET @OnlineRebuildPossible = 0
		
	IF (@OnlineRebuildPossible = 1 AND @DoOnlineIfPossible = 1) 
		SET @PerformOnline = 'ON'
	ELSE
		SET @PerformOnline = 'OFF'
		
	
	SET @SqlCommand = N'USE ' + quotename(db_name(@database_id2)) + N'; '
	IF (
		(@avg_fragmentation_in_percent < @HigherFragmentationThreshold))
		OR
		(@Index_DoReorganizeIfOnlineNotPossible = 1 AND @PerformOnline = 'OFF')
	BEGIN
		SET @SqlCommand = @SqlCommand 
			+ N'ALTER INDEX ' 
			+ quotename(@index_name) + N' ON ' 
			+ quotename(@schema_name) + N'.' 
			+ quotename(CAST(OBJECT_NAME(@object_id2, @database_id2) AS VARCHAR(200))) + N' REORGANIZE '
			
		IF (@IsPartitioned = 1)  
			SET @SqlCommand = @SqlCommand + N'PARTITION = ' + CAST(@partition_number AS VARCHAR(10))
			
			
	END
	ELSE
	BEGIN
		SET @SqlCommand = @SqlCommand 
			+ N'ALTER INDEX ' 
			+ quotename(@index_name) + N' ON ' 
			+ quotename(@schema_name) + N'.' 
			+ quotename(CAST(OBJECT_NAME(@object_id2, @database_id2) AS VARCHAR(100))) + N' REBUILD '
		
		IF (@IsPartitioned = 1 AND @PerformOnline = 'OFF')  
			SET @SqlCommand = @SqlCommand + N'PARTITION = ' + CAST(@partition_number AS VARCHAR(10)) 
			
		SET @SqlCommand = @SqlCommand + ' 
			
		WITH (
			ONLINE = ' + @PerformOnline + N',
			SORT_IN_TEMPDB = ' + @SortInTempDB + N',
			MAXDOP = ' + @MaxDop + N'		
		);'
	END

	
	DECLARE @scid int
	DECLARE @sctype NVARCHAR(100) 
	DECLARE @now DATETIME
	SET @now = GETDATE()
	SET @sctype = 'Index maintenance'
	EXEC base.CreateTask @sctype, @RunAt = @now, @id = @scid OUT
	
	SET @SqlCommand = @SqlCommand + '
	USE MiracleDB; 
	DECLARE @avg_fragmentation_in_percent_after float
	DECLARE @page_count_after int
	SELECT	
		@avg_fragmentation_in_percent_after = avg_fragmentation_in_percent,
		@page_count_after = page_count
	FROM 
		sys.dm_db_index_physical_stats('+cast(@database_id2 as varchar(10))+', '+cast(@object_id2 as varchar(10))+', '+cast(@index_id2 as varchar(10))+', '+cast(@partition_number as varchar(10))+', null)

	UPDATE idx.IndexStats
	SET 
		avg_fragmentation_in_percent_after = @avg_fragmentation_in_percent_after,
		page_count_after = @page_count_after,
		PerformedOnline = CASE WHEN '''+@PerformOnline+''' = ''ON'' THEN 1 ELSE 0 END,
		Type = CASE WHEN '+cast(@avg_fragmentation_in_percent as varchar(20))+' < '+casT(@HigherFragmentationThreshold as varchar(20))+' OR ('+cast(@Index_DoReorganizeIfOnlineNotPossible as varchar(20))+' = 1 AND '''+casT(@PerformOnline as varchar(20))+''' = ''OFF'') THEN ''REORGANIZE'' ELSE ''REBUILD'' END
	WHERE 
		ScheduleId = ' + cast(@scId as varchar(10))
			
	EXEC base.UpdateTask @scid, @SqlCommand
	
	UPDATE idx.IndexStats
	SET 
		ScheduleId = @scId,
		ReadyForExecution = 1
	WHERE 
		id = (select id from @id)
		
	DELETE FROM @id
END
GO





PRINT 'Creating or updating idx.MaintenanceStatus view...'
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'MaintenanceStatus' AND schema_id = schema_id('idx')) BEGIN
	DROP VIEW idx.MaintenanceStatus
END
GO

CREATE VIEW idx.MaintenanceStatus
AS
with cte
as
(select 
	DATEADD(dd, 0, DATEDIFF(dd, 0, DateCreated)) as Day,
	COUNT(*) AS NewTasksInQueue,
	SUM(Page_count)*8/1024 AS SizeInMB,
	MIN(DateStart) as StartTime,
	MAX(DateEnd) AS EndTime,
	SUM(DATEDIFF(mi, DateStart, DateEnd)) AS TotalRunTimeInMinutes
 from base.Scheduler t1
inner join idx.IndexStats t2 on t1.ScheduleId = t2.ScheduleId
group by DATEADD(dd, 0, DATEDIFF(dd, 0, DateCreated))
)
select top 10000
	t1.Day, 
	t1.NewTasksInQueue,
	t1.SizeInMB as SizeInMBAddedToQueue,
	t2.TasksProcessed,
	t2.SizeInMB as SizeInMBProcessed,
	StartTime,
	EndTime,
	TotalRunTimeInMinutes
 from cte t1
inner join 
	(select 
		count(*) as TasksProcessed, 
		SUM(Page_count)*8/1024 AS SizeInMB,
		DATEADD(dd, 0, DATEDIFF(dd, 0, DateStart)) as Day 
	from base.Scheduler  t1
	inner join idx.IndexStats t2 on t1.ScheduleId = t2.ScheduleId
	where DateEnd is not null 
	group by DATEADD(dd, 0, DATEDIFF(dd, 0, DateStart))) t2 on t1.Day = t2.Day
order by t1.day
GO


PRINT 'Creating or updating idx.UsageSnapshot table...'
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'UsageSnapshot' AND schema_id = schema_id('idx')) BEGIN
	DROP TABLE idx.UsageSnapshot
END
GO
CREATE TABLE [idx].[UsageSnapshot](
	[DatabaseName] [nvarchar](128) NOT NULL,
	[SchemaName] [nvarchar](50) NOT NULL,
	[TableName] [nvarchar](500) NOT NULL,
	[IndexName] [nvarchar](500) NOT NULL,
	[range_scan_count] [bigint] NOT NULL,
	[singleton_lookup_count] [bigint] NOT NULL,
	[leaf_insert_count] [bigint] NOT NULL,
	[leaf_update_count] [bigint] NOT NULL,
	[row_lock_count] [bigint] NOT NULL,
	[row_lock_wait_in_ms] [bigint] NOT NULL,
	[page_lock_count] [bigint] NOT NULL,
	[page_lock_wait_in_ms] [bigint] NOT NULL,
	[StatDate] DATETIME NOT NULL
)
GO



PRINT 'Creating or updating idx.MissingIndexes view...'
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'MissingIndexes' AND schema_id = schema_id('idx')) BEGIN
	DROP VIEW idx.MissingIndexes
END
GO
CREATE VIEW idx.MissingIndexes
AS
SELECT 
QUOTENAME(DB_NAME(d.database_id)) AS DatabaseName, 
statement AS TableName,
'USE ' + QUOTENAME(DB_NAME(d.database_id)) + '; CREATE NONCLUSTERED INDEX IX_' + replace(replace(replace(replace(isnull(equality_columns, '') + isnull(inequality_columns, ''), ',', '_'), '[', ''),']', ''), ' ', '') + CASE WHEN included_columns IS NOT NULL THEN '_INC_' + replace(replace(replace(replace(included_columns, ',', '_'), '[', ''),']', ''), ' ', '') ELSE '' END + ' ON ' + statement + ' (' + 
CASE 
WHEN equality_columns IS NOT NULL AND inequality_columns IS NOT NULL THEN equality_columns + ', ' + inequality_columns
WHEN equality_columns IS NOT NULL AND inequality_columns IS NULL THEN equality_columns
WHEN equality_columns IS NULL AND inequality_columns IS NOT NULL THEN inequality_columns
END + ')' + 
CASE WHEN included_columns IS NOT NULL THEN ' INCLUDE (' + replace(replace(replace(included_columns, '[', ''),']', ''), ' ', '') + ')' ELSE '' END + 
CASE WHEN @@Version LIKE '%Enterprise%' THEN ' WITH (ONLINE = ON)' ELSE '' END AS CreateIndexStmt,
d.equality_columns, 
d.inequality_columns, 
d.included_columns, 
user_seeks,
user_scans,
avg_total_user_cost,
avg_user_impact
FROM sys.dm_db_missing_index_groups g
join sys.dm_db_missing_index_group_stats gs on gs.group_handle = g.index_group_handle
join sys.dm_db_missing_index_details d on g.index_handle = d.index_handle
GO


PRINT 'Creating or updating idx.IndexUsage procedure...'
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'IndexUsage' AND schema_id = schema_id('idx')) BEGIN
	DROP PROCEDURE idx.IndexUsage
END
GO

CREATE PROCEDURE idx.IndexUsage
@DatabaseName VARCHAR(200) = NULL,
@SchemaName VARCHAR(50) = '[dbo]',
@TableName VARCHAR(200) = NULL
AS
SET NOCOUNT ON
IF (@TableName IS NOT NULL AND @DatabaseName IS NULL)
	RAISERROR('@TableName cannot be set without also providing a value for @DatabaseName', 16,1)



TRUNCATE TABLE idx.UsageSnapshot
DECLARE @sql NVARCHAR(4000)

DECLARE Databases CURSOR
READ_ONLY
FOR SELECT QUOTENAME(name) FROM sys.databases where database_id > 4 and QUOTENAME(name) = ISNULL(base.QuoteName(@DatabaseName), name)

DECLARE @name NVARCHAR(200)
OPEN Databases

FETCH NEXT FROM Databases INTO @name
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN
		SET @sql = N'USE ' + @name + N';
		INSERT INTO MiracleDB.idx.UsageSnapshot
		SELECT
			QUOTENAME(db_name(t1.database_id)) as DatabaseName,
			QUOTENAME(SCHEMA_NAME(t2.schema_id)),
			QUOTENAME(OBJECT_NAME(t1.object_id, t1.database_id)) AS TableName, 
			t3.name as IndexName,
			range_scan_count, 
			singleton_lookup_count, 
			leaf_insert_count, 
			leaf_update_count, 
			row_lock_count,
			row_lock_wait_in_ms,
			page_lock_count,
			page_lock_wait_in_ms,
			GETDATE() AS StatDate
		FROM sys.dm_db_index_operational_stats(DB_ID(), null, null, null) t1
		INNER JOIN sys.objects t2 on t1.object_id = t2.object_id
		INNER JOIN sys.indexes t3 on t1.object_id = t3.object_id and t1.index_id = t3.index_id
		WHERE t2.is_ms_shipped <> 1 AND t3.type_desc <> ''HEAP'''
		
		EXEC sp_executesql @sql
	END
	FETCH NEXT FROM Databases INTO @name
END

CLOSE Databases
DEALLOCATE Databases

SELECT * FROM idx.UsageSnapshot
WHERE 
	TableName = ISNULL(base.QuoteName(@TableName), TableName)
	AND SchemaName = @SchemaName

GO


PRINT 'Creating or updating idx.MaintenanceLog...'
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'MaintenanceLog' AND schema_id = schema_id('idx')) BEGIN
	DROP VIEW idx.MaintenanceLog
END
GO
CREATE VIEW idx.MaintenanceLog
AS
SELECT
	t1.ScheduleId,
	database_name,
	object_name,
	schema_name,
	index_name,
	partition_number,
	avg_fragmentation_in_percent as avg_fragmentation_in_percent_before,
	avg_fragmentation_in_percent_after,
	page_count as page_count_before,
	page_count_after,
	PerformedOnline,
	Type,
	sqlstring,
	DateStart,
	DateEnd,
	DATEDIFF(ss, DateStart, DateEnd) AS DurationInSec,
	ErrorMessage
FROM 
	idx.IndexStats t1
	LEFT OUTER JOIN base.Scheduler t2 ON t1.ScheduleId = t2.ScheduleId
GO

PRINT '
MiracleDB indexing component is now installed.'	