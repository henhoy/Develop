
/**********    MiracleDB - Delta    ****************************************


Author:			Miracle SQL Server Team
Contact:		MiracleDB@miracleas.dk (http://www.miracleas.dk)
Documentation:	http://MiracleDB.codeplex.com/
Created:		2010-08-25
Modified:		2010-08-25
Version:		0.9

Overview:		This part of the MiracleDB solution can be used to easily
				monitor changes to your DB environement.
				It monitores delta changes between each run on : 
				Databases, Tables, Stored procedures, Views, Indexes.
								
How to install:	Just open this file in SQL Server Management Studio on the
				target instance, and hit F5.
				This solution requires a database named MiracleDB, and if one
				does not exists, one will be created.

Detailed desc:	
				Creating your first delta: 
				EXEC delta.Run
				
				Looking at the result:
				EXEC delta.Report
				
				When running the Report, 2 other reports will be shown: 
				ExtendedResult and ExtendedSizeResult. 
				It will automatically add parameters to these.
				
				Remove all data
				EXEC delta.Remove


******************************************************************************/


/*********** Init ***********/

USE master
GO
SET NOCOUNT ON
GO
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'MiracleDB')
	CREATE DATABASE MiracleDB
GO

USE MiracleDB
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'MiracleDB')
	EXEC sp_executesql N'CREATE SCHEMA MiracleDB'
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'Version' AND schema_id = schema_id('MiracleDB')) BEGIN
	CREATE TABLE [MiracleDB].[Version] (
		Id INT IDENTITY PRIMARY KEY,
		AppName VARCHAR(200) NOT NULL,
		Version VARCHAR(200) NOT NULL,
		DeployDate DATETIME DEFAULT GETDATE()
	)
END


DECLARE @Version VARCHAR(200)
SET @Version = '0.9' --This is the version of the MiracleDB idx stuff about to be deployed
IF NOT EXISTS (SELECT * FROM MiracleDB.Version WHERE AppName = 'delta')
	INSERT INTO MiracleDB.Version (AppName, Version) VALUES ('delta', @Version)
ELSE BEGIN
	DECLARE @CurrentVersion VARCHAR(200)
	SELECT TOP 1 @CurrentVersion = Version FROM MiracleDB.Version WHERE AppName = 'delta' ORDER BY Version DESC
	IF @CurrentVersion >= @Version 
		RAISERROR ('Current version of MiracleDB trace is the same or newer than the one you are trying to deploy.',10,1)
	INSERT INTO MiracleDB.Version (AppName, Version) VALUES ('delta', @Version)
END

GO

/*********** Schema : delta ***********/

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'delta') BEGIN
	EXEC sp_executesql N'CREATE SCHEMA delta'
	PRINT 'Schema : delta was created'
END ELSE BEGIN
	PRINT 'Schema : delta already existed'
END	
	
GO

/*********** Table : Delta ***********/

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'tblDelta' AND schema_id = schema_id('delta')) BEGIN
	CREATE TABLE Delta.tblDelta (
		[ID][INT] identity,
		[DateCreated][DateTime] default GETDATE()
	)
	PRINT 'Table : delta.tblDelta was created'
END ELSE BEGIN
	PRINT 'Table : delta.tblDelta already existed'
END

/*********** Table : Type ***********/

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'tblType' AND schema_id = schema_id('delta')) BEGIN
	CREATE TABLE Delta.tblType (
		[TypeId][INT],
		[Title][varchar](256)
	)
	
	INSERT	INTO delta.tblType (TypeId, Title) VALUES (1, 'Database')
	INSERT	INTO delta.tblType (TypeId, Title) VALUES (2, 'Table')
	INSERT	INTO delta.tblType (TypeId, Title) VALUES (3, 'Stored procedure')
	INSERT	INTO delta.tblType (TypeId, Title) VALUES (4, 'View')
	INSERT	INTO delta.tblType (TypeId, Title) VALUES (5, 'Index')
	INSERT	INTO delta.tblType (TypeId, Title) VALUES (6, 'Size')
	INSERT	INTO delta.tblType (TypeId, Title) VALUES (7, 'Property')
	
	PRINT 'Table : delta.tblType was created'
END ELSE BEGIN
	PRINT 'Table : delta.tblType already existed'
END

/*********** Table : Properties ***********/

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'tblProperties' AND schema_id = schema_id('delta')) BEGIN
	CREATE TABLE delta.tblProperties (
		[Version][varchar](256),
		[ProductVersion][varchar](256),
		[ProductLevel][varchar](256),
		[Edition][varchar](256),
		[BuildClrVersion][varchar](256),
		[Collation][varchar](256),
		[CollationID][varchar](256),
		[ComparisonStyle][varchar](256),
		[ComputerNamePhysicalNetBIOS][varchar](256),
		[EditionID][varchar](256),
		[EngineEdition][varchar](256),
		[InstanceName][varchar](256),
		[IsClustered][varchar](256),
		[IsFullTextInstalled][varchar](256),
		[IsIntegratedSecurityOnly][varchar](256),
		[IsSingleUser][varchar](256),
		[LCID][varchar](256),
		[LicenseType][varchar](256),
		[MachineName][varchar](256),
		[NumLicenses][varchar](256),
		[ProcessID][varchar](256),
		[ResourceLastUpdateDateTime][datetime],
		[ResourceVersion][varchar](256),
		[ServerName][varchar](256),
		[SqlCharSet][varchar](256),
		[SqlCharSetName][varchar](256),
		[SqlSortOrder][varchar](256),
		[SqlSortOrderName][varchar](256),
		[FilestreamShareName][varchar](256),
		[FilestreamConfiguredLevel][varchar](256),
		[FilestreamEffectiveLevel][varchar](256),
		[DeltaId][int],
		[MyCheck][bigint]
	)
	PRINT 'Table : delta.tblProperties was created'
END ELSE BEGIN
	PRINT 'Table : delta.tblProperties already existed'
END

/*********** Table : Tables ***********/

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'tblTables' AND schema_id = schema_id('delta')) BEGIN
	CREATE TABLE delta.tblTables (
		[database_id][int],
		[object_id][bigint],
		[ObjectName][varchar](1024),
		[CreateScript][varchar](max),
		[DeltaId][int],
		[MyCheck][bigint]
	)
	PRINT 'Table : delta.tblTables was created'
END ELSE BEGIN
	PRINT 'Table : delta.tblTables already existed'
END

/*********** Table : StoredProcedures ***********/

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'tblStoredProcedures' AND schema_id = schema_id('delta')) BEGIN
	CREATE TABLE delta.tblStoredProcedures (
		[database_id][int],
		[object_id][bigint],
		[ObjectName][varchar](1024),
		[CreateScript][varchar](max),
		[DeltaId][int],
		[MyCheck][bigint]
	)
	PRINT 'Table : delta.tblStoredProcedures was created'
END ELSE BEGIN
	PRINT 'Table : delta.tblStoredProcedures already existed'
END

/*********** Table : Views ***********/

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'tblViews' AND schema_id = schema_id('delta')) BEGIN
	CREATE TABLE Delta.tblViews (
		[database_id][int],
		[object_id][bigint],
		[ObjectName][varchar](1024),
		[CreateScript][varchar](max),
		[DeltaId][int],
		[MyCheck][bigint]
	)
	PRINT 'Table : delta.tblViews was created'
END ELSE BEGIN
	PRINT 'Table : delta.tblViews already existed'
END

/*********** Table : Indexes ***********/

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'tblIndexes' AND schema_id = schema_id('delta')) BEGIN
	CREATE TABLE Delta.tblIndexes (
		[database_id][int],
		[object_id][bigint],
		[TableName][varchar](1024),
		[ObjectName][varchar](1024),
		[CreateScript][varchar](max),
		[DeltaId][int],
		[MyCheck][bigint]
	)
	PRINT 'Table : delta.tblIndexes was created'
END ELSE BEGIN
	PRINT 'Table : delta.tblIndexes already existed'
END

/*********** Table : Size ***********/

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'tblSize' AND schema_id = schema_id('delta')) BEGIN
	CREATE TABLE Delta.tblSize (
		[database_id][int],
		[TableName][varchar](1024),
		[Rows][varchar](11),
		[Reserved][varchar](18),
		[Data][varchar](18),
		[Index_Size][varchar]( 18 ),
		[Unused][varchar]( 18 ),
		[DeltaId][int]
	)
	PRINT 'Table : delta.tblSize was created'
END ELSE BEGIN
	PRINT 'Table : delta.tblSize already existed'
END

/*********** Table : Report ***********/

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'tblReport' AND schema_id = schema_id('delta')) BEGIN
	CREATE TABLE Delta.tblReport (
		[ID][int] identity,
		[DeltaId][int],
		[TypeId][int],
		[DatabaseId][int],
		[ObjectId][bigint],
		[ObjectName][varchar](1024),
		[LogText][varchar](1024)
	)
	PRINT 'Table : delta.tblReport was created'
END ELSE BEGIN
	PRINT 'Table : delta.tblReport already existed'
END

/*********** Stored procedure : stpDatabases ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'stpDatabases' AND schema_id = schema_id('delta')) BEGIN
	DROP PROCEDURE delta.stpDatabases
	PRINT 'Stored procedure : delta.stpDatabases was dropped'
END
GO

CREATE PROCEDURE delta.stpDatabases
	@DeltaId INT
AS
BEGIN
	
	SET NOCOUNT ON;

    IF EXISTS (SELECT * FROM sys.objects WHERE name = 'tblDatabases' AND type = 'U') BEGIN
		INSERT	INTO delta.tblDatabases
		SELECT	*, DeltaID = @DeltaId, MyCheck = CHECKSUM(
			name + 
			CONVERT(VARCHAR, database_id) +
			CONVERT(VARCHAR, source_database_id) +
			CONVERT(VARCHAR, owner_sid) +
			CONVERT(VARCHAR, create_date) +
			CONVERT(VARCHAR, compatibility_level) +
			CONVERT(VARCHAR, collation_name) +
			CONVERT(VARCHAR, user_access) +
			--CONVERT(VARCHAR, user_access_desc) +
			CONVERT(VARCHAR, is_read_only) +
			CONVERT(VARCHAR, is_auto_close_on) +
			CONVERT(VARCHAR, is_auto_shrink_on) +
			CONVERT(VARCHAR, state) +
			--CONVERT(VARCHAR, state_desc) +
			CONVERT(VARCHAR, is_in_standby) +
			CONVERT(VARCHAR, is_cleanly_shutdown) +
			CONVERT(VARCHAR, is_supplemental_logging_enabled) +
			CONVERT(VARCHAR, snapshot_isolation_state) +
			--CONVERT(VARCHAR, snapshot_isolation_state_desc) +
			CONVERT(VARCHAR, is_read_committed_snapshot_on) +
			CONVERT(VARCHAR, recovery_model) +
			--CONVERT(VARCHAR, recovery_model_desc) +
			CONVERT(VARCHAR, page_verify_option) +
			CONVERT(VARCHAR, is_auto_create_stats_on) +
			CONVERT(VARCHAR, is_auto_update_stats_on) +
			CONVERT(VARCHAR, is_auto_update_stats_async_on) +
			CONVERT(VARCHAR, is_ansi_null_default_on) +
			CONVERT(VARCHAR, is_ansi_nulls_on) +
			CONVERT(VARCHAR, is_ansi_padding_on) +
			CONVERT(VARCHAR, is_ansi_warnings_on) +
			CONVERT(VARCHAR, is_arithabort_on) +
			CONVERT(VARCHAR, is_concat_null_yields_null_on) +
			CONVERT(VARCHAR, is_numeric_roundabort_on) +
			CONVERT(VARCHAR, is_quoted_identifier_on) +
			CONVERT(VARCHAR, is_recursive_triggers_on) +
			CONVERT(VARCHAR, is_cursor_close_on_commit_on) +
			CONVERT(VARCHAR, is_local_cursor_default) +
			CONVERT(VARCHAR, is_fulltext_enabled) +
			CONVERT(VARCHAR, is_trustworthy_on) +
			CONVERT(VARCHAR, is_db_chaining_on) +
			CONVERT(VARCHAR, is_parameterization_forced) +
			CONVERT(VARCHAR, is_master_key_encrypted_by_server) +
			CONVERT(VARCHAR, is_published) +
			CONVERT(VARCHAR, is_subscribed) +
			CONVERT(VARCHAR, is_merge_published) +
			CONVERT(VARCHAR, is_distributor) +
			CONVERT(VARCHAR, is_sync_with_backup) +
			--service_broker_guid +
			CONVERT(VARCHAR, is_broker_enabled) +
			CONVERT(VARCHAR, log_reuse_wait) +
			CONVERT(VARCHAR, is_date_correlation_on) +
			CONVERT(VARCHAR, is_cdc_enabled) +
			CONVERT(VARCHAR, is_encrypted) +
			CONVERT(VARCHAR, is_honor_broker_priority_on)
			)
		FROM	sys.databases
		
	END ELSE BEGIN
		SELECT *, DeltaID = @DeltaId, MyCheck = CHECKSUM(
			name + 
			CONVERT(VARCHAR, database_id) +
			CONVERT(VARCHAR, source_database_id) +
			CONVERT(VARCHAR, owner_sid) +
			CONVERT(VARCHAR, create_date) +
			CONVERT(VARCHAR, compatibility_level) +
			CONVERT(VARCHAR, collation_name) +
			CONVERT(VARCHAR, user_access) +
			--CONVERT(VARCHAR, user_access_desc) +
			CONVERT(VARCHAR, is_read_only) +
			CONVERT(VARCHAR, is_auto_close_on) +
			CONVERT(VARCHAR, is_auto_shrink_on) +
			CONVERT(VARCHAR, state) +
			--CONVERT(VARCHAR, state_desc) +
			CONVERT(VARCHAR, is_in_standby) +
			CONVERT(VARCHAR, is_cleanly_shutdown) +
			CONVERT(VARCHAR, is_supplemental_logging_enabled) +
			CONVERT(VARCHAR, snapshot_isolation_state) +
			--CONVERT(VARCHAR, snapshot_isolation_state_desc) +
			CONVERT(VARCHAR, is_read_committed_snapshot_on) +
			CONVERT(VARCHAR, recovery_model) +
			--CONVERT(VARCHAR, recovery_model_desc) +
			CONVERT(VARCHAR, page_verify_option) +
			CONVERT(VARCHAR, is_auto_create_stats_on) +
			CONVERT(VARCHAR, is_auto_update_stats_on) +
			CONVERT(VARCHAR, is_auto_update_stats_async_on) +
			CONVERT(VARCHAR, is_ansi_null_default_on) +
			CONVERT(VARCHAR, is_ansi_nulls_on) +
			CONVERT(VARCHAR, is_ansi_padding_on) +
			CONVERT(VARCHAR, is_ansi_warnings_on) +
			CONVERT(VARCHAR, is_arithabort_on) +
			CONVERT(VARCHAR, is_concat_null_yields_null_on) +
			CONVERT(VARCHAR, is_numeric_roundabort_on) +
			CONVERT(VARCHAR, is_quoted_identifier_on) +
			CONVERT(VARCHAR, is_recursive_triggers_on) +
			CONVERT(VARCHAR, is_cursor_close_on_commit_on) +
			CONVERT(VARCHAR, is_local_cursor_default) +
			CONVERT(VARCHAR, is_fulltext_enabled) +
			CONVERT(VARCHAR, is_trustworthy_on) +
			CONVERT(VARCHAR, is_db_chaining_on) +
			CONVERT(VARCHAR, is_parameterization_forced) +
			CONVERT(VARCHAR, is_master_key_encrypted_by_server) +
			CONVERT(VARCHAR, is_published) +
			CONVERT(VARCHAR, is_subscribed) +
			CONVERT(VARCHAR, is_merge_published) +
			CONVERT(VARCHAR, is_distributor) +
			CONVERT(VARCHAR, is_sync_with_backup) +
			--service_broker_guid +
			CONVERT(VARCHAR, is_broker_enabled) +
			CONVERT(VARCHAR, log_reuse_wait) +
			CONVERT(VARCHAR, is_date_correlation_on) +
			CONVERT(VARCHAR, is_cdc_enabled) +
			CONVERT(VARCHAR, is_encrypted) +
			CONVERT(VARCHAR, is_honor_broker_priority_on)
			)
		INTO	delta.tblDatabases
		FROM	sys.databases
	END
	
	/* GET DIFFERENCES FROM NEW TO OLD */
	IF @DeltaId <> 1 BEGIN
	
	DECLARE @OldID INT
	SELECT	TOP 1 @OldID = DeltaId 
	FROM	delta.tblDatabases
	WHERE	DeltaId < @DeltaId
	ORDER	BY DeltaId DESC

	INSERT	INTO delta.tblReport(DeltaId, TypeId, DatabaseId, ObjectId, ObjectName, LogText)
	SELECT	@DeltaId, 
			1, 
			DatabaseId = CASE WHEN database_id IS NULL THEN database_id_OLD ELSE database_id END,
			null,
			databasename,
			LogText = CASE WHEN database_id IS NULL THEN 'DatabaseId: ' + CONVERT(VARCHAR, database_id_OLD) + ' - Database: '+ databasename +' was deleted' 
			WHEN database_id_OLD IS NULL THEN 'DatabaseId: ' + CONVERT(VARCHAR, database_id) + ' - Database: '+ databasename +' was added'
			WHEN MyCheck <> MyCheck_OLD  THEN 'DatabaseId: ' + CONVERT(VARCHAR, database_id) + ' - Database. '+ databasename +' was modified'
			END
	FROM	(
	SELECT	T1.database_id, T1.MyCheck, database_id_OLD = T2.database_id, MyCheck_OLD = T2.MyCheck, databasename = T1.name
	FROM	delta.tblDatabases AS T1
			LEFT OUTER JOIN delta.tblDatabases AS T2 ON (T2.database_id = T1.database_id AND T2.DeltaId = @OldID)
	WHERE	T1.DeltaId = @DeltaId
			AND (T2.MyCheck IS NULL
			OR T1.MyCheck <> T2.MyCheck)
	UNION
	SELECT	database_id_OLD = T2.database_id, MyCheck_OLD = T2.MyCheck, T1.database_id, T1.MyCheck, databasename = T1.name
	FROM	delta.tblDatabases AS T1
			LEFT OUTER JOIN delta.tblDatabases AS T2 ON (T2.database_id = T1.database_id AND T2.DeltaId = @DeltaId)
	WHERE	T1.DeltaId = @OldID
			AND (T2.MyCheck IS NULL
			OR T1.MyCheck <> T2.MyCheck)
			) AS T3
	END
END
GO
PRINT 'Stored Procedure : delta.stpDatabases was created'
GO
/*********** Stored procedure : stpTables ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'stpTables' AND schema_id = schema_id('delta')) BEGIN
	DROP PROCEDURE delta.stpTables
	PRINT 'Stored procedure : delta.stpTables was dropped'
END
GO

CREATE PROCEDURE delta.stpTables
	@DeltaId INT
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @SQL VARCHAR(MAX)
	SET @SQL = '
	DECLARE @ObjectId BIGINT
	DECLARE @ObjectName VARCHAR(1024)
	DECLARE @ObjectName2 VARCHAR(1024)
	DECLARE @CreateScript VARCHAR(MAX)

	DECLARE curDeltaTable1 CURSOR FOR
	SELECT	sys.objects.object_id, 
			ObjectName = sys.schemas.name + ''.'' + sys.objects.name,
			ObjectName2 = sys.objects.name
	FROM	sys.objects
			INNER JOIN sys.schemas ON (sys.schemas.schema_id = sys.objects.schema_id)
	WHERE	type = ''U''
	
	OPEN curDeltaTable1

	FETCH NEXT FROM curDeltaTable1
	INTO @ObjectId, @ObjectName, @ObjectName2

	WHILE @@FETCH_STATUS = 0 BEGIN
	
		declare @sql varchar(8000)            
		declare @table varchar(100)            
		declare @cols table (datatype varchar(50))          
		insert into @cols values(''bit'')          
		insert into @cols values(''binary'')          
		insert into @cols values(''bigint'')          
		insert into @cols values(''int'')          
		insert into @cols values(''float'')          
		insert into @cols values(''datetime'')          
		insert into @cols values(''text'')          
		insert into @cols values(''image'')          
		insert into @cols values(''uniqueidentifier'')          
		insert into @cols values(''smalldatetime'')          
		insert into @cols values(''tinyint'')          
		insert into @cols values(''smallint'')          
		insert into @cols values(''sql_variant'')          
		           
		set @sql=''''            
		Select @sql=@sql+             
		case when charindex(''('',@sql,1)<=0 then ''('' else '''' end +Column_Name + '' '' +Data_Type +             
		case when Data_Type in (Select datatype from @cols) then '''' else  ''('' end+
		case when data_type in (''real'',''money'',''decimal'',''numeric'')  then cast(isnull(numeric_precision,'''') as varchar)+'',''+
		case when data_type in (''real'',''money'',''decimal'',''numeric'') then cast(isnull(Numeric_Scale,'''') as varchar) end
		when data_type in (''char'',''nvarchar'',''varchar'',''nchar'') then cast(isnull(Character_Maximum_Length,'''') as varchar)       else '''' end+
		case when Data_Type in (Select datatype from @cols)then '''' else  '')'' end+
		case when Is_Nullable=''No'' then '' Not null,'' else '' null,'' end           
		from Information_Schema.COLUMNS where Table_Name=@ObjectName or Table_Name=@ObjectName2
		
		select  @table=  ''Create table '' + table_Name from Information_Schema.COLUMNS where table_Name=@ObjectName or Table_Name=@ObjectName2
		select @sql=@table + substring(@sql,1,len(@sql)-1) +'' )''  
		
		INSERT	INTO MiracleDB.delta.tblTables (database_id, object_id, ObjectName, CreateScript, DeltaId, MyCheck)
		VALUES	(@database_id, @ObjectId, @ObjectName, @sql, @DeltaId, CHECKSUM(@sql))        
	
		FETCH NEXT FROM curDeltaTable1
		INTO @ObjectId, @ObjectName, @ObjectName2
	END
	CLOSE curDeltaTable1
	DEALLOCATE curDeltaTable1
	'
    
	DECLARE @database_id INT
	DECLARE @name VARCHAR(1024)
	DECLARE @SQL2 VARCHAR(MAX)
	DECLARE @SQL3 VARCHAR(MAX)

	DECLARE curTableDelta CURSOR FOR
	SELECT	database_id, name
	FROM	sys.databases
	WHERE	database_id > 4
			AND name <> 'MiracleDB'
	
	OPEN curTableDelta

	FETCH NEXT FROM curTableDelta
	INTO @database_id, @name

	WHILE @@FETCH_STATUS = 0 BEGIN
			SET @SQL2 = ''
			SET @SQL3 = @SQL
			SET @SQL3 = REPLACE(@SQL3, '@database_id', CONVERT(VARCHAR, @database_id))
			SET @SQL3 = REPLACE(@SQL3, '@DeltaId', CONVERT(VARCHAR, @DeltaId))

			SET @SQL2 = 'USE [' + @Name + ']; '+@SQL3+';'
			EXEC(@SQL2)
		FETCH NEXT FROM curTableDelta
		INTO @database_id, @name
	END
	CLOSE curTableDelta
	DEALLOCATE curTableDelta
	
	/* GET DIFFERENCES FROM NEW TO OLD */
	IF @DeltaId <> 1 BEGIN
		DECLARE @OldID INT
		SELECT	TOP 1 @OldID = DeltaId
		FROM	Delta.tblTables
		WHERE	DeltaId < @DeltaId
		ORDER	BY DeltaId DESC

		INSERT	INTO delta.tblReport(DeltaId, TypeId, DatabaseId, ObjectId, ObjectName, LogText)
		SELECT	@DeltaId,
				2,
				DatabaseId = CASE WHEN database_id IS NULL THEN database_id_OLD ELSE database_id END,
				ObjectId,
				ObjectName,
				LogText = CASE WHEN database_id IS NULL THEN 'DatabaseId: ' + CONVERT(VARCHAR, database_id_OLD) + ' - Table: '+ ObjectName +' was deleted' 
				WHEN database_id_OLD IS NULL THEN 'DatabaseId: ' + CONVERT(VARCHAR, database_id) + ' - Table: '+ ObjectName +' was added'
				WHEN MyCheck <> MyCheck_OLD  THEN 'DatabaseId: ' + CONVERT(VARCHAR, database_id) + ' - Table: '+ ObjectName +' was modified'
				END
		FROM	(
		SELECT	T1.database_id, T1.MyCheck, database_id_OLD = T2.database_id, MyCheck_OLD = T2.MyCheck, ObjectName = T1.ObjectName, ObjectId = T1.object_id
		FROM	delta.tblTables AS T1
				LEFT OUTER JOIN delta.tblTables AS T2 ON (T2.database_id = T1.database_id AND T2.ObjectName = T1.ObjectName AND T2.DeltaId = @OldID)
		WHERE	T1.DeltaId = @DeltaId
				AND (T2.MyCheck IS NULL
				OR T1.MyCheck <> T2.MyCheck)
		UNION
		SELECT	database_id_OLD = T2.database_id, MyCheck_OLD = T2.MyCheck, T1.database_id, T1.MyCheck, ObjectName = T1.ObjectName, ObjectId = T1.object_id
		FROM	delta.tblTables AS T1
				LEFT OUTER JOIN delta.tblTables AS T2 ON (T2.database_id = T1.database_id AND T2.ObjectName = T1.ObjectName AND T2.DeltaId = @DeltaId)
		WHERE	T1.DeltaId = @OldID
				AND (T2.MyCheck IS NULL
				OR T1.MyCheck <> T2.MyCheck)
				) AS T3
	END	
END
GO
PRINT 'Stored Procedure : delta.stpTables was created'
GO

/*********** Stored procedure : stpStoredProceduers ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'stpStoredProcedures' AND schema_id = schema_id('delta')) BEGIN
	DROP PROCEDURE delta.stpStoredProcedures
	PRINT 'Stored procedure : delta.stpStoredProcedures was dropped'
END
GO

CREATE PROCEDURE delta.stpStoredProcedures
	@DeltaId INT
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @SQL VARCHAR(MAX)
	SET @SQL = '
	
	DECLARE @ObjectId BIGINT
	DECLARE @ObjectName VARCHAR(1024)
	DECLARE @SchemaName VARCHAR(1024)
	DECLARE @CreateScript VARCHAR(MAX)

	DECLARE curDeltaStoredprocedure1 CURSOR FOR
	SELECT	sys.objects.object_id, ObjectName = sys.objects.name, SchemaName = sys.schemas.name
	FROM	sys.objects
			INNER JOIN sys.schemas ON (sys.schemas.schema_id = sys.objects.schema_id)
	WHERE	type = ''P''

	OPEN curDeltaStoredprocedure1

	FETCH NEXT FROM curDeltaStoredprocedure1
	INTO @ObjectId, @ObjectName, @SchemaName

	WHILE @@FETCH_STATUS = 0 BEGIN

		SET @CreateScript = ''''
		SELECT	@CreateScript = @CreateScript + replace(text,'''''''','''')
		FROM	syscomments
		WHERE	id = @ObjectId
		
		INSERT	INTO MiracleDB.delta.tblStoredProcedures (database_id, object_id, ObjectName, CreateScript, DeltaId, MyCheck)
		VALUES	(@database_id, @ObjectId, @SchemaName + ''.'' + @ObjectName, @CreateScript, @DeltaId, CHECKSUM(@CreateScript))
		
		FETCH NEXT FROM curDeltaStoredprocedure1
		INTO @ObjectId, @ObjectName, @SchemaName
	END
	CLOSE curDeltaStoredprocedure1
	DEALLOCATE curDeltaStoredprocedure1

	'
    
	DECLARE @SQL2 VARCHAR(MAX)
	DECLARE @SQL3 VARCHAR(MAX)
	DECLARE @database_id INT
	DECLARE @name VARCHAR(1024)

	DECLARE curDatabaseDelta1 CURSOR FOR
	SELECT	database_id, name
	FROM	sys.databases
	WHERE	database_id > 4
			AND name <> 'MiracleDB'
	ORDER	BY database_id DESC

	OPEN curDatabaseDelta1

	FETCH NEXT FROM curDatabaseDelta1
	INTO @database_id, @name

	WHILE @@FETCH_STATUS = 0 BEGIN
		SET @SQL3 = @SQL
			SET @SQL3 = REPLACE(@SQL3, '@DeltaId', CONVERT(VARCHAR, @DeltaId))
			SET @SQL3 = REPLACE(@SQL3, '@database_id', CONVERT(VARCHAR, @database_id))
			SET @SQL2 = 'USE [' + @Name + ']; '+@SQL3+''
			EXEC (@SQL2)
		FETCH NEXT FROM curDatabaseDelta1
		INTO @database_id, @name
	END
	CLOSE curDatabaseDelta1
	DEALLOCATE curDatabaseDelta1
	
	/* GET DIFFERENCES FROM NEW TO OLD */
	IF @DeltaId <> 1 BEGIN
	
	DECLARE @OldID INT
	SELECT	TOP 1 @OldID = DeltaId
	FROM	Delta.tblStoredProcedures
	WHERE	DeltaId < @DeltaId
	ORDER	BY DeltaId DESC

	INSERT	INTO Delta.tblReport(DeltaId, TypeId, DatabaseId, ObjectId, ObjectName, LogText)
	SELECT	@DeltaId,
			3, 
			DatabaseId = CASE WHEN database_id IS NULL THEN database_id_OLD ELSE database_id END,
			ObjectId,
			ObjectName,
			LogText = CASE WHEN database_id IS NULL THEN 'DatabaseId: ' + CONVERT(VARCHAR, database_id_OLD) + ' - Stored Procedure: '+ ObjectName +' was deleted' 
			WHEN database_id_OLD IS NULL THEN 'DatabaseId: ' + CONVERT(VARCHAR, database_id) + ' - Stored Procedure: '+ ObjectName +' was added'
			WHEN MyCheck <> MyCheck_OLD  THEN 'DatabaseId: ' + CONVERT(VARCHAR, database_id) + ' - Stored Procedure: '+ ObjectName +' was modified'
			END
	FROM	(
	SELECT	T1.database_id, T1.MyCheck, database_id_OLD = T2.database_id, MyCheck_OLD = T2.MyCheck, ObjectName = T1.ObjectName, ObjectId = T1.object_id
	FROM	delta.tblStoredProcedures AS T1
			LEFT OUTER JOIN delta.tblStoredProcedures AS T2 ON (T2.database_id = T1.database_id AND T2.ObjectName = T1.ObjectName AND T2.DeltaId = @OldID)
	WHERE	T1.DeltaId = @DeltaId
			AND (T2.MyCheck IS NULL
			OR T1.MyCheck <> T2.MyCheck)
	UNION
	SELECT	database_id_OLD = T2.database_id, MyCheck_OLD = T2.MyCheck, T1.database_id, T1.MyCheck, ObjectName = T1.ObjectName, ObjectId = T1.object_id
	FROM	delta.tblStoredProcedures AS T1
			LEFT OUTER JOIN delta.tblStoredProcedures AS T2 ON (T2.database_id = T1.database_id AND T2.ObjectName = T1.ObjectName AND T2.DeltaId = @DeltaId)
	WHERE	T1.DeltaId = @OldID
			AND (T2.MyCheck IS NULL
			OR T1.MyCheck <> T2.MyCheck)
			) AS T3
	END
END
GO
PRINT 'Stored Procedure : delta.stpStoredProcedures was created'
GO

/*********** Stored procedure : stpStoredProceduers ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'stpIndexes' AND schema_id = schema_id('delta')) BEGIN
	DROP PROCEDURE delta.stpIndexes
	PRINT 'Stored procedure : delta.stpIndexes was dropped'
END
GO

CREATE PROCEDURE Delta.stpIndexes
	@DeltaId INT
AS
BEGIN
	
	SET NOCOUNT ON;

DECLARE @SQL VARCHAR(max)
SET @SQL = '
DECLARE @TableName VARCHAR(1024)
DECLARE @SchemaName VARCHAR(1024)
DECLARE @IndexName VARCHAR(1024)
DECLARE @type_desc VARCHAR(1024)
DECLARE @object_id INT
DECLARE @is_primary_key INT
DECLARE @is_unique INT
DECLARE @data_space_id INT
DECLARE @fill_factor INT
DECLARE @index_id INT
DECLARE @is_padded INT
DECLARE @ignore_dup_key INT
DECLARE @allow_row_locks INT
DECLARE @allow_page_locks INT
DECLARE @statistics_norecompute INT
DECLARE @CreateScript VARCHAR(max)
DECLARE @CreateScriptColumns VARCHAR(max)
DECLARE @CreateScriptIncludedColumns VARCHAR(max)

DECLARE @object_id2 INT
DECLARE @col_name VARCHAR(1024)
DECLARE @index_column_id INT
DECLARE @key_ordinal INT
DECLARE @partition_ordinal INT
DECLARE @is_descending_key INT

DECLARE @IncludedColumnsCounter INT

DECLARE curIndexes CURSOR FOR
SELECT	TableName = sys.objects.NAME, 
		SchemaName = SCHEMA_NAME(sys.objects.SCHEMA_ID),
		IndexName = sys.indexes.name,
		type_desc = sys.indexes.type_desc,
		object_id = sys.indexes.object_id,
		is_primary_key = sys.indexes.is_primary_key,
		is_unique = sys.indexes.is_unique,
		data_space_id = sys.indexes.data_space_id,
		fill_factor = sys.indexes.fill_factor,
		index_id = sys.indexes.index_id,
		is_padded = sys.indexes.is_padded,
		ignore_dup_key = sys.indexes.ignore_dup_key,
		allow_row_locks = sys.indexes.allow_row_locks,
		allow_page_locks = sys.indexes.allow_page_locks
FROM	sys.objects
		INNER JOIN sys.indexes ON (sys.objects.object_id = sys.indexes.object_id and sys.indexes.type_desc!=''HEAP'')
WHERE	sys.objects.type=''U'' 
		AND sys.objects.name <> ''sysdiagrams''
ORDER	BY sys.objects.name

OPEN curIndexes

FETCH NEXT FROM curIndexes
INTO @TableName, @Schemaname, @IndexName, @type_desc, @object_id, @is_primary_key, @is_unique, @data_space_id, @fill_factor, @index_id, @is_padded, @ignore_dup_key, @allow_row_locks, @allow_page_locks

WHILE @@FETCH_STATUS = 0 BEGIN
	SET @CreateScript = ''''
	
	IF @type_desc=''CLUSTERED'' AND @is_primary_key=1 BEGIN--OR     @IndexType=''NON CLUSTERED''  or
		SET @CreateScript = @CreateScript + 
			''ALTER TABLE '' + ''['' + @SchemaName + ''].['' + @TableName +''] '' +
			''ADD CONSTRAINT [''+@IndexName+'']'' +'' PRIMARY KEY CLUSTERED ''
		END
	IF @type_desc=''NONCLUSTERED'' AND @is_unique = 1 BEGIN --OR @IndexType=''NON CLUSTERED''  or
		SET @CreateScript = @CreateScript + 
			''ALTER TABLE '' + ''['' + @SchemaName + ''].['' + @TableName +''] '' +
			''ADD CONSTRAINT [''+@IndexName+'']'' +'' UNIQUE NONCLUSTERED ''
	END
	IF @type_desc=''NONCLUSTERED'' AND  @is_unique=0 AND @is_primary_key=0 BEGIN
		SET @CreateScript = @CreateScript +
			''CREATE NONCLUSTERED INDEX [''+@IndexName+''] ON'' + '' ['' + @SchemaName + ''].['' +
			@TableName  + '']''
	END
	IF @type_desc=''CLUSTERED'' AND @is_unique = 0 AND @is_primary_key=0 BEGIN
		SET @CreateScript = @CreateScript + 
			''CREATE CLUSTERED INDEX [''+ @IndexName +''] ON'' + '' ['' + @SchemaName + ''].['' +
			@TableName + '']''
	END
	SET @CreateScript = @CreateScript + ''(''
	
	SET @IncludedColumnsCounter = 0
	SET @CreateScriptColumns = ''''
	SET @CreateScriptIncludedColumns = ''''
	
	DECLARE curIndexes2 CURSOR FOR
	SELECT	object_id,
			COL_NAME(object_id(@SchemaName + ''.'' + @TableName),column_id),
			index_column_id,
			key_ordinal,
			partition_ordinal,
			is_descending_key 
	FROM	sys.index_columns
	WHERE	object_id = object_id(@SchemaName + ''.'' + @TableName)
			AND index_id = @index_id --AND key_ordinal<>0and Partition_ordinal!=1  
	ORDER	BY key_ordinal DESC

	OPEN curIndexes2
	FETCH NEXT FROM curIndexes2
	INTO @object_id2, @col_name, @index_column_id, @key_ordinal, @partition_ordinal, @is_descending_key
	
	WHILE @@FETCH_STATUS = 0 BEGIN
	
		IF @key_ordinal = 0 BEGIN
			IF @IncludedColumnsCounter = 0 BEGIN SET @CreateScriptIncludedColumns = @CreateScriptIncludedColumns + '' INCLUDED ('' END
			SET @CreateScriptIncludedColumns = @CreateScriptIncludedColumns + ''[''+@col_name+''],''
			SET @IncludedColumnsCounter = @IncludedColumnsCounter + 1
		END ELSE BEGIN
			IF @is_descending_key=0 BEGIN
				SET @CreateScriptColumns = @CreateScriptColumns + ''[''+@col_name+''] ASC,''
			END
			IF @is_descending_key = 1 BEGIN
				SET @CreateScriptColumns = @CreateScriptColumns + ''[''+@col_name+''] DESC,''
			END
		END
	
		FETCH NEXT FROM curIndexes2
		INTO @object_id2, @col_name, @index_column_id, @key_ordinal, @partition_ordinal, @is_descending_key
	END
	CLOSE curIndexes2
	DEALLOCATE curIndexes2
	SET @CreateScriptColumns = SUBSTRING(@CreateScriptColumns, 0, LEN(@CreateScriptColumns))
	SET @CreateScriptColumns = @CreateScriptColumns +  '')''
	SET @CreateScript = @CreateScript + @CreateScriptColumns
	
	IF @IncludedColumnsCounter > 0 BEGIN
		SET @CreateScriptIncludedColumns = SUBSTRING(@CreateScriptIncludedColumns, 0, LEN(@CreateScriptIncludedColumns))
		SET @CreateScriptIncludedColumns = @CreateScriptIncludedColumns +  '')''
		SET @CreateScript = @CreateScript + @CreateScriptIncludedColumns
	END
	
	IF @type_desc = ''NONCLUSTERED'' AND @is_unique = 0 AND @is_primary_key = 0 BEGIN
		SET @statistics_norecompute = 1
	END ELSE BEGIN
		SET @statistics_norecompute = 0
	END
	
	SET @CreateScript = @CreateScript + '' WITH (PAD_INDEX = '' + CASE WHEN @is_padded = 1 THEN ''ON'' ELSE ''OFF'' END + '', '' +
			''STATISTICS_NORECOMPUTE  = '' + CASE WHEN @statistics_norecompute = 1 THEN ''ON'' ELSE ''OFF'' END + '', '' +
			''SORT_IN_TEMPDB = OFF, '' +
			''IGNORE_DUP_KEY = OFF, '' +
			''DROP_EXISTING = OFF, '' + 
			''ONLINE = OFF, '' +
			''ALLOW_ROW_LOCKS = '' + CASE WHEN @allow_row_locks = 1 THEN ''ON'' ELSE ''OFF'' END + '', '' +
			''ALLOW_PAGE_LOCKS = '' + CASE WHEN @allow_page_locks = 1 THEN ''ON'' ELSE ''OFF'' END + '''' +
			CASE WHEN @fill_factor <> 0 THEN '', FILLFACTOR = '' + CONVERT(VARCHAR, @fill_factor) ELSE '''' END + 
			'')''
	
	INSERT	INTO MiracleDB.delta.tblIndexes (database_id, object_id, TableName, ObjectName, CreateScript, DeltaId, MyCheck)
	VALUES	(@database_id, @object_id, @TableName, @IndexName, @CreateScript, @DeltaId, CHECKSUM(@CreateScript))
	
	FETCH NEXT FROM curIndexes
	INTO @TableName, @Schemaname, @IndexName, @type_desc, @object_id, @is_primary_key, @is_unique, @data_space_id, @fill_factor, @index_id, @is_padded, @ignore_dup_key, @allow_row_locks, @allow_page_locks
END
CLOSE curIndexes
DEALLOCATE curIndexes
'

	DECLARE @SQL2 VARCHAR(MAX)
	DECLARE @SQL3 VARCHAR(MAX)
	DECLARE @database_id INT
	DECLARE @name VARCHAR(1024)

	DECLARE curDatabaseDelta2 CURSOR FOR
	SELECT	database_id, name
	FROM	sys.databases
	WHERE	database_id > 4
			AND name <> 'MiracleDB'
	ORDER	BY database_id ASC

	OPEN curDatabaseDelta2

	FETCH NEXT FROM curDatabaseDelta2
	INTO @database_id, @name

	WHILE @@FETCH_STATUS = 0 BEGIN
		SET @SQL3 = @SQL
			SET @SQL3 = REPLACE(@SQL3, '@DeltaId', CONVERT(VARCHAR, @DeltaId))
			SET @SQL3 = REPLACE(@SQL3, '@database_id', CONVERT(VARCHAR, @database_id))
			SET @SQL2 = 'USE [' + @Name + ']; '+@SQL3+';'
			EXEC (@SQL2)
		FETCH NEXT FROM curDatabaseDelta2
		INTO @database_id, @name
	END
	CLOSE curDatabaseDelta2
	DEALLOCATE curDatabaseDelta2
	
	/* GET DIFFERENCES FROM NEW TO OLD */
	IF @DeltaId <> 1 BEGIN
		DECLARE @OldID INT
		SELECT	TOP 1 @OldID = DeltaId
		FROM	Delta.tblIndexes
		WHERE	DeltaId < @DeltaId
		ORDER	BY DeltaId DESC

		INSERT	INTO Delta.tblReport(DeltaId, TypeId, DatabaseId, ObjectId, ObjectName, LogText)
		SELECT	@DeltaId,
				5,
				DatabaseId = CASE WHEN database_id IS NULL THEN database_id_OLD ELSE database_id END,
				ObjectId,
				ObjectName,
				LogText = CASE WHEN database_id IS NULL THEN 'DatabaseId: ' + CONVERT(VARCHAR, database_id_OLD) + ' - Table: '+ TableName + ' - Index: '+ ObjectName +' was deleted' 
				WHEN database_id_OLD IS NULL THEN 'DatabaseId: ' + CONVERT(VARCHAR, database_id) + ' - Table: '+ TableName + ' - Index: '+ ObjectName +' was added'
				WHEN MyCheck <> MyCheck_OLD  THEN 'DatabaseId: ' + CONVERT(VARCHAR, database_id) + ' - Table: '+ TableName + ' - Index: '+ ObjectName +' was modified'
				END
		FROM	(
		SELECT	T1.database_id, T1.MyCheck, database_id_OLD = T2.database_id, MyCheck_OLD = T2.MyCheck, ObjectName = T1.ObjectName, ObjectId = T1.object_id, TableName = T1.TableName
		FROM	delta.tblIndexes AS T1
				LEFT OUTER JOIN delta.tblIndexes AS T2 ON (T2.database_id = T1.database_id AND T2.object_id = T1.object_id AND T2.ObjectName = T1.ObjectName AND T2.DeltaId = @OldID)
		WHERE	T1.DeltaId = @DeltaId
				AND (T2.MyCheck IS NULL
				OR T1.MyCheck <> T2.MyCheck)
		UNION
		SELECT	database_id_OLD = T2.database_id, MyCheck_OLD = T2.MyCheck, T1.database_id, T1.MyCheck, ObjectName = T1.ObjectName, ObjectId = T1.object_id, TableName = T1.TableName
		FROM	delta.tblIndexes AS T1
				LEFT OUTER JOIN delta.tblIndexes AS T2 ON (T2.database_id = T1.database_id AND T2.object_id = T1.object_id AND T2.ObjectName = T1.ObjectName AND T2.DeltaId = @DeltaId)
		WHERE	T1.DeltaId = @OldID
				AND (T2.MyCheck IS NULL
				OR T1.MyCheck <> T2.MyCheck)
				) AS T3
	END
	
END
GO
PRINT 'Stored Procedure : delta.stpIndexes was created'
GO

/*********** Stored procedure : stpViews ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'stpViews' AND schema_id = schema_id('delta')) BEGIN
	DROP PROCEDURE delta.stpViews
	PRINT 'Stored procedure : delta.stpViews was dropped'
END
GO

CREATE PROCEDURE Delta.stpViews
	@DeltaId INT
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @SQL VARCHAR(MAX)
	SET @SQL = '
	
	DECLARE @ObjectId BIGINT
	DECLARE @ObjectName VARCHAR(1024)
	DECLARE @SchemaName VARCHAR(1024)
	DECLARE @CreateScript VARCHAR(MAX)

	DECLARE curDeltaView1 CURSOR FOR
	SELECT	sys.objects.object_id, ObjectName = sys.objects.name, SchemaName = sys.schemas.name
	FROM	sys.objects
			INNER JOIN sys.schemas ON (sys.schemas.schema_id = sys.objects.schema_id)
	WHERE	type = ''V''

	OPEN curDeltaView1

	FETCH NEXT FROM curDeltaView1
	INTO @ObjectId, @ObjectName, @SchemaName

	WHILE @@FETCH_STATUS = 0 BEGIN

		SET @CreateScript = ''''
		SELECT	@CreateScript = @CreateScript + replace(text,'''''''','''')
		FROM	syscomments
		WHERE	id = @ObjectId
		
		INSERT	INTO MiracleDB.delta.tblViews (database_id, object_id, ObjectName, CreateScript, DeltaId, MyCheck)
		VALUES	(@database_id, @ObjectId, @SchemaName + ''.'' + @ObjectName, @CreateScript, @DeltaId, CHECKSUM(@CreateScript))
		
		FETCH NEXT FROM curDeltaView1
		INTO @ObjectId, @ObjectName, @SchemaName
	END
	CLOSE curDeltaView1
	DEALLOCATE curDeltaView1

	'
    
	DECLARE @SQL2 VARCHAR(MAX)
	DECLARE @SQL3 VARCHAR(MAX)
	DECLARE @database_id INT
	DECLARE @name VARCHAR(1024)

	DECLARE curDatabaseDelta3 CURSOR FOR
	SELECT	database_id, name
	FROM	sys.databases
	WHERE	database_id > 4
			AND name <> 'MiracleDB'
	ORDER	BY database_id DESC

	OPEN curDatabaseDelta3

	FETCH NEXT FROM curDatabaseDelta3
	INTO @database_id, @name

	WHILE @@FETCH_STATUS = 0 BEGIN
		SET @SQL3 = @SQL
			SET @SQL3 = REPLACE(@SQL3, '@DeltaId', CONVERT(VARCHAR, @DeltaId))
			SET @SQL3 = REPLACE(@SQL3, '@database_id', CONVERT(VARCHAR, @database_id))
			SET @SQL2 = 'USE [' + @Name + ']; '+@SQL3+''
			EXEC (@SQL2)
		FETCH NEXT FROM curDatabaseDelta3
		INTO @database_id, @name
	END
	CLOSE curDatabaseDelta3
	DEALLOCATE curDatabaseDelta3
	
	/* GET DIFFERENCES FROM NEW TO OLD */
	IF @DeltaId <> 1 BEGIN
	
	DECLARE @OldID INT
	SELECT	TOP 1 @OldID = DeltaId
	FROM	Delta.tblViews
	WHERE	DeltaId < @DeltaId
	ORDER	BY DeltaId DESC

	INSERT	INTO Delta.tblReport(DeltaId, TypeId, DatabaseId, ObjectId, ObjectName, LogText)
	SELECT	@DeltaId,
			4,
			DatabaseId = CASE WHEN database_id IS NULL THEN database_id_OLD ELSE database_id END,
			ObjectId,
			ObjectName,
			LogText = CASE WHEN database_id IS NULL THEN 'DatabaseId: ' + CONVERT(VARCHAR, database_id_OLD) + ' - View: '+ ObjectName +' was deleted' 
			WHEN database_id_OLD IS NULL THEN 'DatabaseId: ' + CONVERT(VARCHAR, database_id) + ' - View: '+ ObjectName +' was added'
			WHEN MyCheck <> MyCheck_OLD  THEN 'DatabaseId: ' + CONVERT(VARCHAR, database_id) + ' - View: '+ ObjectName +' was modified'
			END
	FROM	(
	SELECT	T1.database_id, T1.MyCheck, database_id_OLD = T2.database_id, MyCheck_OLD = T2.MyCheck, ObjectName = T1.ObjectName, ObjectId = T1.object_id
	FROM	delta.tblViews AS T1
			LEFT OUTER JOIN delta.tblViews AS T2 ON (T2.database_id = T1.database_id AND T2.ObjectName = T1.ObjectName AND T2.DeltaId = @OldID)
	WHERE	T1.DeltaId = @DeltaId
			AND (T2.MyCheck IS NULL
			OR T1.MyCheck <> T2.MyCheck)
	UNION
	SELECT	database_id_OLD = T2.database_id, MyCheck_OLD = T2.MyCheck, T1.database_id, T1.MyCheck, ObjectName = T1.ObjectName, ObjectId = T1.object_id
	FROM	delta.tblViews AS T1
			LEFT OUTER JOIN delta.tblViews AS T2 ON (T2.database_id = T1.database_id AND T2.ObjectName = T1.ObjectName AND T2.DeltaId = @DeltaId)
	WHERE	T1.DeltaId = @OldID
			AND (T2.MyCheck IS NULL
			OR T1.MyCheck <> T2.MyCheck)
			) AS T3
	END
END
GO

PRINT 'Stored Procedure : delta.stpViews was created'
GO

/*********** Stored procedure : stpSize ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'stpSize' AND schema_id = schema_id('delta')) BEGIN
	DROP PROCEDURE delta.stpSize
	PRINT 'Stored procedure : delta.stpSize was dropped'
END
GO

CREATE PROCEDURE Delta.stpSize
	@DeltaId INT
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @SQL VARCHAR(MAX)
	SET @SQL = '
	DECLARE @TableName VARCHAR(256)
	DECLARE @SchemaName VARCHAR(256)
	DECLARE @Table VARCHAR(256)

	DECLARE @tmpTable TABLE (
		TabName sysname,
		[Rows] varchar (11),
		Reserved varchar (18),
		Data varchar (18),
		Index_Size varchar ( 18 ),
		Unused varchar ( 18 )
	)

	DECLARE curTableDelta CURSOR FOR
	Select TableName = sys.tables.name,
	SchemaName = sys.schemas.name 
	From sys.tables 
	Inner Join sys.schemas ON (sys.schemas.schema_id = sys.tables.schema_id)

	OPEN curTableDelta

	FETCH NEXT FROM curTableDelta
	INTO @TableName, @SchemaName

	WHILE @@FETCH_STATUS = 0 BEGIN

		SET @Table = ''['' + @SchemaName + ''].['' + @TableName + '']''
		INSERT INTO @tmpTable EXEC sp_spaceused @Table
		SET @Table = @SchemaName + ''.'' + @TableName
		
		INSERT	INTO MiracleDB.delta.tblSize(database_id, TableName, Rows, Reserved, Data, Index_Size, Unused, DeltaId)
		SELECT	@database_id, @Table, Rows, Reserved, Data, Index_Size, Unused, @DeltaId
		FROM	@tmpTable
		
		DELETE FROM @tmpTable
		
		FETCH NEXT FROM curTableDelta
		INTO @TableName, @SchemaName
	END
	CLOSE curTableDelta
	DEALLOCATE curTableDelta
	'
    
	DECLARE @SQL2 VARCHAR(MAX)
	DECLARE @SQL3 VARCHAR(MAX)
	DECLARE @database_id INT
	DECLARE @name VARCHAR(256)

	DECLARE curDatabaseDelta CURSOR FOR
	SELECT	database_id, name
	FROM	sys.databases
	WHERE	database_id > 4
			AND name <> 'MiracleDB'
	ORDER	BY database_id ASC

	OPEN curDatabaseDelta

	FETCH NEXT FROM curDatabaseDelta
	INTO @database_id, @name

	WHILE @@FETCH_STATUS = 0 BEGIN
		SET @SQL3 = @SQL
		SET @SQL3 = REPLACE(@SQL3, '@database_id', CONVERT(VARCHAR, @database_id))
		SET @SQL3 = REPLACE(@SQL3, '@DeltaId', CONVERT(VARCHAR, @DeltaId))

		SET @SQL2 = 'USE [' + @Name + ']; '+@SQL3+''
		EXEC (@SQL2)
		
		FETCH NEXT FROM curDatabaseDelta
		INTO @database_id, @name
	END
	CLOSE curDatabaseDelta
	DEALLOCATE curDatabaseDelta	

END
GO

PRINT 'Stored Procedure : delta.stpSize was created'
GO

/*********** Stored procedure : stpProperties ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'stpProperties' AND schema_id = schema_id('delta')) BEGIN
	DROP PROCEDURE delta.stpProperties
	PRINT 'Stored procedure : delta.stpProperties was dropped'
END
GO

CREATE PROCEDURE Delta.stpProperties
	@DeltaId INT
AS
BEGIN
	
	SET NOCOUNT ON;
	
	INSERT	INTO delta.tblProperties 
	SELECT	Version = @@Version,
		ProductVersion = CONVERT(VARCHAR(256),SERVERPROPERTY('productversion')), 
		ProductLevel = CONVERT(VARCHAR(256),SERVERPROPERTY ('productlevel')), 
		Edition = CONVERT(VARCHAR(256),SERVERPROPERTY ('edition')),
		BuildClrVersion = CONVERT(VARCHAR(256),SERVERPROPERTY('BuildClrVersion')),
		Collation = CONVERT(VARCHAR(256),SERVERPROPERTY('Collation')),
		CollationID = CONVERT(VARCHAR(256),SERVERPROPERTY('CollationID')),
		ComparisonStyle = CONVERT(VARCHAR(256),SERVERPROPERTY('ComparisonStyle')),
		ComputerNamePhysicalNetBIOS = CONVERT(VARCHAR(256),SERVERPROPERTY('ComputerNamePhysicalNetBIOS')),
		EditionID = CONVERT(VARCHAR(256),SERVERPROPERTY('EditionID')),
		EngineEdition = CONVERT(VARCHAR(256),SERVERPROPERTY('EngineEdition')),
		InstanceName = CONVERT(VARCHAR(256),SERVERPROPERTY('InstanceName')),
		IsClustered = CONVERT(VARCHAR(256),SERVERPROPERTY('IsClustered')),
		IsFullTextInstalled = CONVERT(VARCHAR(256),SERVERPROPERTY('IsFullTextInstalled')),
		IsIntegratedSecurityOnly = CONVERT(VARCHAR(256),SERVERPROPERTY('IsIntegratedSecurityOnly')),
		IsSingleUser = CONVERT(VARCHAR(256),SERVERPROPERTY('IsSingleUser')),
		LCID = CONVERT(VARCHAR(256),SERVERPROPERTY('LCID')),
		LicenseType = CONVERT(VARCHAR(256),SERVERPROPERTY('LicenseType')),
		MachineName = CONVERT(VARCHAR(256),SERVERPROPERTY('MachineName')),
		NumLicenses = CONVERT(VARCHAR(256),SERVERPROPERTY('NumLicenses')),
		ProcessID = CONVERT(VARCHAR(256),SERVERPROPERTY('ProcessID')),
		ResourceLastUpdateDateTime = CONVERT(VARCHAR(256),SERVERPROPERTY('ResourceLastUpdateDateTime')),
		ResourceVersion = CONVERT(VARCHAR(256),SERVERPROPERTY('ResourceLastUpdateDateTime')),
		ServerName = CONVERT(VARCHAR(256),SERVERPROPERTY('ServerName')),
		SqlCharSet = CONVERT(VARCHAR(256),SERVERPROPERTY('SqlCharSet')),
		SqlCharSetName = CONVERT(VARCHAR(256),SERVERPROPERTY('SqlCharSetName')),
		SqlSortOrder = CONVERT(VARCHAR(256),SERVERPROPERTY('SqlSortOrder')),
		SqlSortOrderName = CONVERT(VARCHAR(256),SERVERPROPERTY('SqlSortOrderName')),
		FilestreamShareName = CONVERT(VARCHAR(256),SERVERPROPERTY('FilestreamShareName')),
		FilestreamConfiguredLevel = CONVERT(VARCHAR(256),SERVERPROPERTY('FilestreamConfiguredLevel')),
		FilestreamEffectiveLevel = CONVERT(VARCHAR(256),SERVERPROPERTY('FilestreamEffectiveLevel')),
		@DeltaId,
		''
		
	UPDATE	delta.tblProperties
	SET		MyCheck = CHECKSUM(
			Version + 
			ProductVersion + 
			ProductLevel +
			Edition +
			BuildClrVersion +
			Collation +
			CollationID +
			ComparisonStyle +
			ComputerNamePhysicalNetBIOS +
			EditionID +
			EngineEdition +
			InstanceName +
			IsClustered +
			IsFullTextInstalled +
			IsIntegratedSecurityOnly +
			IsSingleUser +
			LCID +
			LicenseType +
			MachineName +
			NumLicenses +
			ProcessID +
			CONVERT(VARCHAR, ResourceLastUpdateDateTime) +
			ResourceVersion +
			ServerName +
			SqlCharSet +
			SqlCharSetName +
			SqlSortOrder +
			SqlSortOrderName +
			FilestreamShareName +
			FilestreamConfiguredLevel +
			FilestreamEffectiveLevel
			)
	WHERE	DeltaId = @DeltaId

	/* GET DIFFERENCES FROM NEW TO OLD */
	IF @DeltaId <> 1 BEGIN
		DECLARE @MyCheck INT
		DECLARE @MyCheck_Old INT
		
		SELECT	TOP 1 @MyCheck_Old = MyCheck 
		FROM	delta.tblProperties
		WHERE	DeltaId < @DeltaId
		ORDER	BY DeltaId DESC
		
		SELECT	@MyCheck = MyCheck
		FROM	delta.tblProperties
		WHERE	DeltaId = @DeltaId
		
		IF @MyCheck <> @MyCheck_Old BEGIN
			INSERT	INTO delta.tblReport(DeltaId, DatabaseId, ObjectId, ObjectName, LogText)
			VALUES	(@DeltaId, null, null, null, 'System properties has changed')
		END
	END
END
GO

PRINT 'Stored Procedure : delta.stpProperties was created'
GO

/*********** Stored procedure : Run ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'Run' AND schema_id = schema_id('delta')) BEGIN
	DROP PROCEDURE delta.Run
	PRINT 'Stored procedure : delta.Run was dropped'
END
GO

CREATE PROCEDURE delta.Run
	
AS
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @DeltaId INT
	DECLARE @DateCreated DATETIME
	SET @DateCreated = GETDATE()
	INSERT	INTO delta.tblDelta (DateCreated) VALUES (@DateCreated)

	SET @DeltaId = SCOPE_IDENTITY()
	
	EXEC delta.stpIndexes @DeltaId
	EXEC delta.stpDatabases @DeltaId
	EXEC delta.stpTables @DeltaId
	EXEC delta.stpSize @DeltaId
	EXEC delta.stpProperties @DeltaId
	EXEC delta.stpStoredProcedures @DeltaId
	EXEC delta.stpViews @DeltaId
	
END
GO

PRINT 'Stored Procedure : delta.Run was created'
GO

/*********** Stored procedure : Remove ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'Remove' AND schema_id = schema_id('delta')) BEGIN
	DROP PROCEDURE delta.Remove
	PRINT 'Stored procedure : delta.Remove was dropped'
END
GO

CREATE PROCEDURE delta.Remove
	
AS
BEGIN
	
	SET NOCOUNT ON;

	TRUNCATE TABLE delta.tblDelta
	IF EXISTS (SELECT * FROM sys.objects WHERE name = 'tblDatabases' AND schema_id = schema_id('delta')) BEGIN
		TRUNCATE TABLE delta.tblDatabases
	END
	TRUNCATE TABLE delta.tblTables
	TRUNCATE TABLE delta.tblSize
	TRUNCATE TABLE delta.tblProperties
	TRUNCATE TABLE delta.tblStoredProcedures
	TRUNCATE TABLE delta.tblIndexes
	TRUNCATE TABLE delta.tblViews
	TRUNCATE TABLE delta.tblReport
	
END
GO

PRINT 'Stored Procedure : delta.Remove was created'
GO

/*********** Stored procedure : Report ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'Report' AND schema_id = schema_id('delta')) BEGIN
	DROP PROCEDURE delta.Report
	PRINT 'Stored procedure : delta.Report was dropped'
END
GO


CREATE PROCEDURE delta.Report
	
AS
BEGIN
	
	SET NOCOUNT ON;
	
	SELECT	delta.tblDelta.*,
			NoOfModifications = ISNULL(NoOfModifications, 0),
			ResultQuery = 'EXEC delta.ExtendedResult ' + CONVERT(VARCHAR, delta.tblDelta.Id),
			ResultSizeQuery = 'EXEC Delta.ExtendedSizeResult ' + CONVERT(VARCHAR, delta.tblDelta.Id) + ', ''Reserved'' /*(Order by variables: Rows, Reserved, Data, Index_Size, Unused)*/'
	FROM	delta.tblDelta
			LEFT OUTER JOIN (SELECT delta.tblReport.DeltaId, NoOfModifications = COUNT(*) FROM delta.tblReport GROUP BY DeltaId) AS T1 ON (T1.DeltaId = delta.tblDelta.ID)
	
END
GO

PRINT 'Stored Procedure : delta.Report was created'
GO

/*********** Stored procedure : ExtendedResult ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'ExtendedResult' AND schema_id = schema_id('delta')) BEGIN
	DROP PROCEDURE delta.ExtendedResult
	PRINT 'Stored procedure : delta.ExtendedResult was dropped'
END
GO


CREATE PROCEDURE delta.ExtendedResult
	@DeltaId INT
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @TypeId INT
	DECLARE @Title VARCHAR(256)
	DECLARE @OldId INT

	DECLARE @tableReport TABLE (
		[ObjectType][varchar](256),
		[ObjectId][varchar](256),
		[ObjectName][varchar](1024),
		[LogText][varchar](1024),
		[OldData][varchar](max),
		[NewData][varchar](max)
	)

	DECLARE curReport CURSOR FOR
	SELECT	TypeId, 
			Title 
	FROM	delta.tblType

	OPEN curReport

	FETCH NEXT FROM curReport
	INTO @TypeId, @Title

	WHILE @@FETCH_STATUS = 0 BEGIN

		IF EXISTS (SELECT ID FROM delta.tblReport WHERE DeltaId = @DeltaId AND TypeId = @TypeId) BEGIN
			
			SELECT	TOP 1 @OldId = ID
			FROM	delta.tblDelta
			WHERE	ID < @DeltaId
			ORDER	BY ID DESC
			
			/* Table changes */
			IF @TypeId = 1 BEGIN
				INSERT	INTO @tableReport (ObjectType, ObjectId, ObjectName, LogText, OldData, NewData)
				SELECT	@Title, T1.ObjectId, T1.ObjectName, LogText, '', ''
				FROM	delta.tblReport AS T1
						LEFT OUTER JOIN delta.tblDatabases AS T2 ON (T2.DeltaId = T1.DeltaId AND T2.database_id = T1.DatabaseId)
						LEFT OUTER JOIN delta.tblDatabases AS T3 ON (T3.DeltaId = @OldId AND T3.database_id = T1.DatabaseId)
				WHERE	T1.DeltaId = @DeltaId
						AND TypeId = @TypeId
			END ELSE IF @TypeId = 2 BEGIN
				INSERT	INTO @tableReport (ObjectType, ObjectId, ObjectName, LogText, OldData, NewData)
				SELECT	@Title, T1.ObjectId, T1.ObjectName, LogText, ISNULL(T3.CreateScript, ''), ISNULL(T2.CreateScript, '')
				FROM	delta.tblReport AS T1
						LEFT OUTER JOIN delta.tblTables AS T2 ON (T2.DeltaId = T1.DeltaId AND T2.object_id = T1.ObjectId AND T2.ObjectName = T1.ObjectName AND T2.database_id = T1.DatabaseId)
						LEFT OUTER JOIN delta.tblTables AS T3 ON (T3.DeltaId = @OldId AND T3.object_id = T1.ObjectId AND T3.ObjectName = T1.ObjectName AND T3.database_id = T1.DatabaseId)
				WHERE	T1.DeltaId = @DeltaId
						AND TypeId = @TypeId
			END ELSE IF @TypeId = 3 BEGIN
				INSERT	INTO @tableReport (ObjectType, ObjectId, ObjectName, LogText, OldData, NewData)
				SELECT	@Title, T1.ObjectId, T1.ObjectName, LogText, ISNULL(T3.CreateScript, ''), ISNULL(T2.CreateScript, '')
				FROM	delta.tblReport AS T1
						LEFT OUTER JOIN delta.tblStoredProcedures AS T2 ON (T2.DeltaId = T1.DeltaId AND T2.object_id = T1.ObjectId AND T2.ObjectName = T1.ObjectName AND T2.database_id = T1.DatabaseId)
						LEFT OUTER JOIN delta.tblStoredProcedures AS T3 ON (T3.DeltaId = @OldId AND T3.object_id = T1.ObjectId AND T3.ObjectName = T1.ObjectName AND T3.database_id = T1.DatabaseId)
				WHERE	T1.DeltaId = @DeltaId
						AND TypeId = @TypeId
			END ELSE IF @TypeId = 4 BEGIN
				INSERT	INTO @tableReport (ObjectType, ObjectId, ObjectName, LogText, OldData, NewData)
				SELECT	@Title, T1.ObjectId, T1.ObjectName, LogText, ISNULL(T3.CreateScript, ''), ISNULL(T2.CreateScript, '')
				FROM	delta.tblReport AS T1
						LEFT OUTER JOIN delta.tblViews AS T2 ON (T2.DeltaId = T1.DeltaId AND T2.object_id = T1.ObjectId AND T2.ObjectName = T1.ObjectName AND T2.database_id = T1.DatabaseId)
						LEFT OUTER JOIN delta.tblViews AS T3 ON (T3.DeltaId = @OldId AND T3.object_id = T1.ObjectId AND T3.ObjectName = T1.ObjectName AND T3.database_id = T1.DatabaseId)
				WHERE	T1.DeltaId = @DeltaId
						AND TypeId = @TypeId
			END ELSE IF @TypeId = 5 BEGIN
				INSERT	INTO @tableReport (ObjectType, ObjectId, ObjectName, LogText, OldData, NewData)
				SELECT	@Title, T1.ObjectId, T1.ObjectName, LogText, ISNULL(T3.CreateScript, ''), ISNULL(T2.CreateScript, '')
				FROM	delta.tblReport AS T1
						LEFT OUTER JOIN delta.tblIndexes AS T2 ON (T2.DeltaId = T1.DeltaId AND T2.object_id = T1.ObjectId AND T2.ObjectName = T1.ObjectName AND T2.database_id = T1.DatabaseId)
						LEFT OUTER JOIN delta.tblIndexes AS T3 ON (T3.DeltaId = @OldId AND T3.object_id = T1.ObjectId AND T3.ObjectName = T1.ObjectName AND T3.database_id = T1.DatabaseId)
				WHERE	T1.DeltaId = @DeltaId
						AND TypeId = @TypeId
			END
			
		END ELSE BEGIN
			INSERT	INTO @tableReport (ObjectType, ObjectId, ObjectName, LogText, OldData, NewData)
			VALUES	(@Title, '', '', 'No ' + @Title + '(s) have been modified', '', '')
		END

		FETCH NEXT FROM curReport
		INTO @TypeId, @Title
	END
	CLOSE curReport
	DEALLOCATE curReport

	SELECT * FROM @tableReport
	
END
GO

PRINT 'Stored Procedure : delta.ExtendedResult was created'
GO

/*********** Stored procedure : ExtendedSizeResult ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'ExtendedSizeResult' AND schema_id = schema_id('delta')) BEGIN
	DROP PROCEDURE delta.ExtendedSizeResult
	PRINT 'Stored procedure : delta.ExtendedSizeResult was dropped'
END
GO


CREATE PROCEDURE Delta.ExtendedSizeResult
	@DeltaId INT,
	@OrderBy VARCHAR(100)
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @OldId INT

	SELECT	TOP 1 @OldId = ID
	FROM	delta.tblDelta
	WHERE	ID < @DeltaId
	ORDER	BY ID DESC

	SELECT	DatabaseId = T1.database_id, 
			TableName = T1.TableName,
			Rows_Old = ISNULL(T2.Rows, 0),
			Rows = ISNULL(T1.Rows, 0),
			RowsDiff = CASE 
						WHEN CONVERT(INT, ISNULL(T2.Rows, 0)) = 0 OR CONVERT(INT, ISNULL(T1.Rows, 0)) = 0 THEN  
							ROUND((CONVERT(FLOAT, ISNULL(T1.Rows, 0)) - CONVERT(FLOAT, ISNULL(T2.Rows, 0))) / CONVERT(FLOAT, 1) * 100, 2) 
						ELSE 
							ROUND((CONVERT(FLOAT, ISNULL(T1.Rows, 0)) - CONVERT(FLOAT, ISNULL(T2.Rows, 0))) / CONVERT(FLOAT, ISNULL(T1.Rows, 0)) * 100, 2) 
						END,
			Reserved_Old = ISNULL(T2.Reserved, 0),
			Reserved = ISNULL(T1.Reserved, 0),
			ReservedDiff = CASE 
						WHEN CONVERT(INT, ISNULL(REPLACE(T2.Reserved, ' KB',''), 0)) = 0 OR CONVERT(INT, ISNULL(REPLACE(T1.Reserved, ' KB',''), 0)) = 0 THEN  
							ROUND((CONVERT(FLOAT, ISNULL(REPLACE(T1.Reserved, ' KB',''), 0)) - CONVERT(FLOAT, ISNULL(REPLACE(T2.Reserved, ' KB',''), 0))) / CONVERT(FLOAT, 1) * 100, 2) 
						ELSE 
							ROUND((CONVERT(FLOAT, ISNULL(REPLACE(T1.Reserved, ' KB',''), 0)) - CONVERT(FLOAT, ISNULL(REPLACE(T2.Reserved, ' KB',''), 0))) / CONVERT(FLOAT, ISNULL(REPLACE(T1.Reserved, ' KB',''), 0)) * 100, 2) 
						END,
			Data_Old = ISNULL(T2.Data, 0),
			Data = ISNULL(T1.Data, 0),
			DataDiff = CASE 
						WHEN CONVERT(INT, ISNULL(REPLACE(T2.Data, ' KB',''), 0)) = 0 OR CONVERT(INT, ISNULL(REPLACE(T1.Data, ' KB',''), 0)) = 0 THEN  
							ROUND((CONVERT(FLOAT, ISNULL(REPLACE(T1.Data, ' KB',''), 0)) - CONVERT(FLOAT, ISNULL(REPLACE(T2.Data, ' KB',''), 0))) / CONVERT(FLOAT, 1) * 100, 2) 
						ELSE 
							ROUND((CONVERT(FLOAT, ISNULL(REPLACE(T1.Data, ' KB',''), 0)) - CONVERT(FLOAT, ISNULL(REPLACE(T2.Data, ' KB',''), 0))) / CONVERT(FLOAT, ISNULL(REPLACE(T1.Data, ' KB',''), 0)) * 100, 2) 
						END,
			Index_Size_Old = ISNULL(T2.Index_Size, 0),
			Index_Size = ISNULL(T1.Index_Size, 0),
			Index_SizeDiff = CASE 
						WHEN CONVERT(INT, ISNULL(REPLACE(T2.Index_Size, ' KB',''), 0)) = 0 OR CONVERT(INT, ISNULL(REPLACE(T1.Index_Size, ' KB',''), 0)) = 0 THEN  
							ROUND((CONVERT(FLOAT, ISNULL(REPLACE(T1.Index_Size, ' KB',''), 0)) - CONVERT(FLOAT, ISNULL(REPLACE(T2.Index_Size, ' KB',''), 0))) / CONVERT(FLOAT, 1) * 100, 2) 
						ELSE 
							ROUND((CONVERT(FLOAT, ISNULL(REPLACE(T1.Index_Size, ' KB',''), 0)) - CONVERT(FLOAT, ISNULL(REPLACE(T2.Index_Size, ' KB',''), 0))) / CONVERT(FLOAT, ISNULL(REPLACE(T1.Index_Size, ' KB',''), 0)) * 100, 2) 
						END,
			Unused_Old = ISNULL(T2.Unused, 0),
			Unused = ISNULL(T1.Unused, 0),
			UnusedDiff = CASE 
						WHEN CONVERT(INT, ISNULL(REPLACE(T2.Unused, ' KB',''), 0)) = 0 OR CONVERT(INT, ISNULL(REPLACE(T1.Unused, ' KB',''), 0)) = 0 THEN  
							ROUND((CONVERT(FLOAT, ISNULL(REPLACE(T1.Unused, ' KB',''), 0)) - CONVERT(FLOAT, ISNULL(REPLACE(T2.Unused, ' KB',''), 0))) / CONVERT(FLOAT, 1) * 100, 2) 
						ELSE 
							ROUND((CONVERT(FLOAT, ISNULL(REPLACE(T1.Unused, ' KB',''), 0)) - CONVERT(FLOAT, ISNULL(REPLACE(T2.Unused, ' KB',''), 0))) / CONVERT(FLOAT, ISNULL(REPLACE(T1.Unused, ' KB',''), 0)) * 100, 2) 
						END
	FROM	delta.tblSize AS T1
			LEFT OUTER JOIN delta.tblSize AS T2 ON (T2.DeltaId = @OldId AND T2.TableName = T1.TableName AND T1.database_id = T2.database_id)
	WHERE	T1.DeltaId = @DeltaId
	ORDER	BY 
		CASE @OrderBy 
		WHEN 'Rows' THEN 
			CASE 
			WHEN CONVERT(INT, ISNULL(T2.Rows, 0)) = 0 OR CONVERT(INT, ISNULL(T1.Rows, 0)) = 0 THEN  
				ROUND((CONVERT(FLOAT, ISNULL(T1.Rows, 0)) - CONVERT(FLOAT, ISNULL(T2.Rows, 0))) / CONVERT(FLOAT, 1) * 100, 2) 
			ELSE 
				ROUND((CONVERT(FLOAT, ISNULL(T1.Rows, 0)) - CONVERT(FLOAT, ISNULL(T2.Rows, 0))) / CONVERT(FLOAT, ISNULL(T1.Rows, 0)) * 100, 2) 
			END
		WHEN 'Reserved' THEN 
			CASE 
			WHEN CONVERT(INT, ISNULL(REPLACE(T2.Reserved, ' KB',''), 0)) = 0 OR CONVERT(INT, ISNULL(REPLACE(T1.Reserved, ' KB',''), 0)) = 0 THEN  
				ROUND((CONVERT(FLOAT, ISNULL(REPLACE(T1.Reserved, ' KB',''), 0)) - CONVERT(FLOAT, ISNULL(REPLACE(T2.Reserved, ' KB',''), 0))) / CONVERT(FLOAT, 1) * 100, 2) 
			ELSE 
				ROUND((CONVERT(FLOAT, ISNULL(REPLACE(T1.Reserved, ' KB',''), 0)) - CONVERT(FLOAT, ISNULL(REPLACE(T2.Reserved, ' KB',''), 0))) / CONVERT(FLOAT, ISNULL(REPLACE(T1.Reserved, ' KB',''), 0)) * 100, 2) 
			END
		WHEN 'Data' THEN 
			CASE 
			WHEN CONVERT(INT, ISNULL(REPLACE(T2.Data, ' KB',''), 0)) = 0 OR CONVERT(INT, ISNULL(REPLACE(T1.Data, ' KB',''), 0)) = 0 THEN  
				ROUND((CONVERT(FLOAT, ISNULL(REPLACE(T1.Data, ' KB',''), 0)) - CONVERT(FLOAT, ISNULL(REPLACE(T2.Data, ' KB',''), 0))) / CONVERT(FLOAT, 1) * 100, 2) 
			ELSE 
				ROUND((CONVERT(FLOAT, ISNULL(REPLACE(T1.Data, ' KB',''), 0)) - CONVERT(FLOAT, ISNULL(REPLACE(T2.Data, ' KB',''), 0))) / CONVERT(FLOAT, ISNULL(REPLACE(T1.Data, ' KB',''), 0)) * 100, 2) 
			END
		WHEN 'Index_Size' THEN 
			CASE 
			WHEN CONVERT(INT, ISNULL(REPLACE(T2.Index_Size, ' KB',''), 0)) = 0 OR CONVERT(INT, ISNULL(REPLACE(T1.Index_Size, ' KB',''), 0)) = 0 THEN  
				ROUND((CONVERT(FLOAT, ISNULL(REPLACE(T1.Index_Size, ' KB',''), 0)) - CONVERT(FLOAT, ISNULL(REPLACE(T2.Index_Size, ' KB',''), 0))) / CONVERT(FLOAT, 1) * 100, 2) 
			ELSE 
				ROUND((CONVERT(FLOAT, ISNULL(REPLACE(T1.Index_Size, ' KB',''), 0)) - CONVERT(FLOAT, ISNULL(REPLACE(T2.Index_Size, ' KB',''), 0))) / CONVERT(FLOAT, ISNULL(REPLACE(T1.Index_Size, ' KB',''), 0)) * 100, 2) 
			END
		WHEN 'Unused' THEN 
			CASE 
			WHEN CONVERT(INT, ISNULL(REPLACE(T2.Unused, ' KB',''), 0)) = 0 OR CONVERT(INT, ISNULL(REPLACE(T1.Unused, ' KB',''), 0)) = 0 THEN  
				ROUND((CONVERT(FLOAT, ISNULL(REPLACE(T1.Unused, ' KB',''), 0)) - CONVERT(FLOAT, ISNULL(REPLACE(T2.Unused, ' KB',''), 0))) / CONVERT(FLOAT, 1) * 100, 2) 
			ELSE 
				ROUND((CONVERT(FLOAT, ISNULL(REPLACE(T1.Unused, ' KB',''), 0)) - CONVERT(FLOAT, ISNULL(REPLACE(T2.Unused, ' KB',''), 0))) / CONVERT(FLOAT, ISNULL(REPLACE(T1.Unused, ' KB',''), 0)) * 100, 2) 
			END
	END DESC, TableName ASC
END
GO


PRINT 'Stored Procedure : delta.ExtendedSizeResult was created'
GO