
/**********    MiracleDB - Trace    ****************************************


Author:			Miracle SQL Server Team
Contact:		MiracleDB@miracleas.dk (http://www.miracleas.dk)
Documentation:	http://MiracleDB.codeplex.com/
Created:		2010-08-25
Modified:		2010-08-25
Version:		1.0

Overview:		This part of the MiracleDB solution can be used to easily
				create traces on you production or test invironment.
				It automates the process of collecting data and grouping
				the result in an easy to read form.
				
How to install:	Just open this file in SQL Server Management Studio on the
				target instance, and hit F5.
				This solution requires a database named MiracleDB, and if one
				does not exists, one will be created.

Detailed desc:	Creating a trace:

				DECLARE @intTraceId INT
				EXEC @intTraceId = trace.Init 
					@intTypeId = 1,								/* Allways = 1, not yet implemented */
					@intRunTimeInMiliseconds = 0,				/* For how long do you wish the trace to run */
					@intMaxSize = 50,							/* Max file size in MB for each trace file */
					@intRollOver = true,						/* When a tracefile is filled up, should it start a new one */
					@intDurationGreaterThanInMiliseconds = 0,	/* Filter to only collect executions that run for more than x milliseconds */
					@intReadsGreaterThan = 0,					/* Filter to only collect executions that reads more than x times */
					@intWritesGreaterThan = 0,					/* Filter to only collect executions that writes more than x times */
					@strPath = 'G:\TraceFiles',					/* Path to store trace files */
					@intAutoStart = 0							/* Specifies if you wish to start the trace right away */

				PRINT @intTraceId								/* Prints out the TraceId */

				Starting a trace:
				
				EXEC trace.Start @intTraceId
				
				Stopping a trace:
				
				EXEC trace.Stop @intTraceId
				
				Removing a trace from SQL-server:
				
				EXEC trace.Remove @intTraceId
				
				Getting status of all traces, including traces not started by this tool
				
				EXEC trace.Status	
				
				Import trace from tracefiles:
				
				EXEC trace.Import 
					@intTypeId = 1,								/* Allways = 1, not yet implemented */
					@strDateStart = '2010-07-28',				/* Start date for trace files */
					@strDateStop = '2010-07-28',				/* Stop date for trace files */
					@strHourStart = '00:00:01',					/* Start time for trace files (If date expands over several days, it will only include traces from this time) */
					@strHourStop = '23:59:59',					/* Stop time for trace files (If date expands over several days, it will only include traces to this time) */
					@intAppend = 0								/* Append to existing imports. As long as the files (and MiracleDB) exists you can always import files again. */

				Looking at the result:
				
				EXEC trace.Report 
					@dtmDateStart = '2010-07-28 00:00:00',		/* From time to look at */
					@dtmDateStop = '2010-07-28 23:59:59',		/* To time to look at */
					@intReportTypeId = 1,						/* 1: reads, 2: duration, 3: writes, 4: occurencies, 5: CPU */
					@intMinValue = 0,							/* Min value for the type selected in ReportType */
					@intMax = 100								/* Max number of results */
				

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
SET @Version = '1.0' --This is the version of the MiracleDB idx stuff about to be deployed
IF NOT EXISTS (SELECT * FROM MiracleDB.Version WHERE AppName = 'trace')
	INSERT INTO MiracleDB.Version (AppName, Version) VALUES ('trace', @Version)
ELSE BEGIN
	DECLARE @CurrentVersion VARCHAR(200)
	SELECT TOP 1 @CurrentVersion = Version FROM MiracleDB.Version WHERE AppName = 'trace' ORDER BY Version DESC
	IF @CurrentVersion >= @Version 
		RAISERROR ('Current version of MiracleDB trace is the same or newer than the one you are trying to deploy.',10,1)
	INSERT INTO MiracleDB.Version (AppName, Version) VALUES ('trace', @Version)
END

GO

/*********** Schema : trace ***********/

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'trace') BEGIN
	EXEC sp_executesql N'CREATE SCHEMA trace'
	PRINT 'Schema : trace was created'
END ELSE BEGIN
	PRINT 'Schema : trace already existed'
END	
	
GO

/*********** Table : Trace ***********/

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'Trace' AND schema_id = schema_id('trace')) BEGIN
	CREATE TABLE trace.Trace(
		[TraceId] [int] IDENTITY(1,1) NOT NULL,
		[SqlTraceId] [int] NULL,
		[OutputFile] [varchar](245) NULL,
		[Path][varchar](250) NULL,
		[AutoStart][int] NULL,
		[TypeId] [int] NULL,
		[MaxSize][bigint] NULL,
		[RollOver][bit] NULL,
		[RunTimeInMiliseconds] [int] NULL,
		[DurationGreaterThanInMiliseconds] [int] NULL,
		[ReadsGreaterThan] [int] NULL,
		[WritesGreaterThan] [int] NULL,
		[StartAt] [datetime] NULL,
		[StopAt] [datetime] NULL,
		[Removed][int] NULL,
		[DateCreated] [datetime] NOT NULL
	)
	ALTER TABLE trace.Trace ADD  CONSTRAINT [DF_CollectionTrace_DateCreated_1]  DEFAULT (GETDATE()) FOR [DateCreated]
	PRINT 'Table : trace.Trace was created'
END ELSE BEGIN
	PRINT 'Table : trace.Trace already existed'
END
GO

/*********** Table : Events ***********/

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'Events' AND schema_id = schema_id('trace')) BEGIN
	CREATE TABLE trace.Events(
		[EventClass] [smallint] NOT NULL,
		[EventName] [varchar](50) NOT NULL,
		[EventDescription] [varchar](300) NULL
	) ON [PRIMARY]	
	PRINT 'Table : trace.Events was created'
END ELSE BEGIN
	PRINT 'Table : trace.Events already exists'
END
GO

INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (44, 'SP:StmtStarting', 'SQL statement inside a stored procedure is starting.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (45, 'SP:StmtCompleted', 'SQL statement inside a stored procedure has completed.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (46, 'Object:Created', 'Indicates that an object has been created, such as for CREATE INDEX, CREATE TABLE, and CREATE DATABA');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (47, 'Object:Deleted', 'Indicates that an object has been deleted, such as in DROP INDEX and DROP TABLE statements.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (48, 'Reserved', '');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (49, 'Reserved', '');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (50, 'SQL Transaction', 'Tracks Transact-SQL BEGIN, COMMIT, SAVE, and ROLLBACK TRANSACTION statements.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (51, 'Scan:Started', 'Indicates when a table or index scan has started.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (52, 'Scan:Stopped', 'Indicates when a table or index scan has stopped.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (53, 'CursorOpen', 'Indicates when a cursor is opened on a Transact-SQL statement by ODBC, OLE DB, or DB-Library.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (54, 'Transaction Log', 'Tracks when transactions are written to the transaction log.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (55, 'Hash Warning', 'Indicates that a hashing operation (for example, hash join, hash aggregate, hash union, and hash dis');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (56, 'Reserved', '');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (57, 'Reserved', '');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (58, 'Auto Update Stats', 'Indicates an automatic updating of index statistics has occurred.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (59, 'Lock:Deadlock Chain', 'Produced for each of the events leading up to the deadlock.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (60, 'Lock:Escalation', 'Indicates that a finer-grained lock has been converted to a coarser-grained lock (for example, a row');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (61, 'OLE DB Errors', 'Indicates that an OLE DB error has occurred.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (62, 'Reserved', '');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (63, 'Reserved', '');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (64, 'Reserved', '');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (65, 'Reserved', '');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (66, 'Reserved', '');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (67, 'Execution Warnings', 'Indicates any warnings that occurred during the execution of a SQL Server statement or stored proced');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (68, 'Execution Plan', 'Displays the plan tree of the Transact-SQL statement executed.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (69, 'Sort Warnings', 'Indicates sort operations that do not fit into memory. Does not include sort operations involving th');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (70, 'CursorPrepare', 'Indicates when a cursor on a Transact-SQL statement is prepared for use by ODBC, OLE DB, or DB-Libra');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (71, 'Prepare SQL', 'ODBC, OLE DB, or DB-Library has prepared a Transact-SQL statement or statements for use.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (72, 'Exec Prepared SQL', 'ODBC, OLE DB, or DB-Library has executed a prepared Transact-SQL statement or statements.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (73, 'Unprepare SQL', 'ODBC, OLE DB, or DB-Library has unprepared (deleted) a prepared Transact-SQL statement or statements');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (74, 'CursorExecute', 'A cursor previously prepared on a Transact-SQL statement by ODBC, OLE DB, or DB-Library is executed.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (75, 'CursorRecompile', 'A cursor opened on a Transact-SQL statement by ODBC or DB-Library has been recompiled either directl');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (76, 'CursorImplicitConversion', 'A cursor on a Transact-SQL statement is converted by SQL Server from one type to another.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (77, 'CursorUnprepare', 'A prepared cursor on a Transact-SQL statement is unprepared (deleted) by ODBC, OLE DB, or DB-Library');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (78, 'CursorClose', 'A cursor previously opened on a Transact-SQL statement by ODBC, OLE DB, or DB-Library is closed.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (79, 'Missing Column Statistics', 'Column statistics that could have been useful for the optimizer are not available.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (80, 'Missing Join Predicate', 'Query that has no join predicate is being executed. This could result in a long-running query.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (81, 'Server Memory Change', 'Microsoft SQL Server memory usage has increased or decreased by either 1 megabyte (MB) or 5 percent ');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (82, 'User Configurable (0)', 'Event data defined by the user.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (83, 'User Configurable (1)', 'Event data defined by the user.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (84, 'User Configurable (2)', 'Event data defined by the user.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (85, 'User Configurable (3)', 'Event data defined by the user.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (86, 'User Configurable (4)', 'Event data defined by the user.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (87, 'User Configurable (5)', 'Event data defined by the user.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (88, 'User Configurable (6)', 'Event data defined by the user.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (89, 'User Configurable (7)', 'Event data defined by the user.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (90, 'User Configurable (8)', 'Event data defined by the user.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (91, 'User Configurable (9)', 'Event data defined by the user.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (92, 'Data File Auto Grow', 'Indicates that a data file was extended automatically by the server.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (93, 'Log File Auto Grow', 'Indicates that a data file was extended automatically by the server.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (94, 'Data File Auto Shrink', 'Indicates that a data file was shrunk automatically by the server.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (95, 'Log File Auto Shrink', 'Indicates that a log file was shrunk automatically by the server.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (96, 'Show Plan Text', 'Displays the query plan tree of the SQL statement from the query optimizer.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (97, 'Show Plan ALL', 'Displays the query plan with full compile-time details of the SQL statement executed.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (98, 'Show Plan Statistics', 'Displays the query plan with full run-time details of the SQL statement executed.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (99, 'Reserved', '');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (100, 'RPC Output Parameter', 'Produces output VALUES of the parameters for every RPC.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (101, 'Reserved', '');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (102, 'Audit Statement GDR', 'Occurs every time a GRANT, DENY, REVOKE for a statement permission is issued by any user in SQL Serv');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (103, 'Audit Object GDR', 'Occurs every time a GRANT, DENY, REVOKE for an object permission is issued by any user in SQL Server');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (104, 'Audit Add/Drop Login', 'Occurs when a SQL Server login is added or removed; for sp_addlogin and sp_droplogin.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (105, 'Audit Login GDR', 'Occurs when a Microsoft Windows&reg; login right is added or removed; for sp_grantlogin, sp_revokelo');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (106, 'Audit Login Change Property', 'Occurs when a property of a login, except passwords, is modified; for sp_defaultdb and sp_defaultlan');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (107, 'Audit Login Change Password', 'Occurs when a SQL Server login password is changed.Passwords are not recorded.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (108, 'Audit Add Login to Server Role', 'Occurs when a login is added or removed from a fixed server role; for sp_addsrvrolemember, and sp_dr');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (109, 'Audit Add DB User', 'Occurs when a login is added or removed as a database user (Windows or SQL Server) to a database; fo');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (110, 'Audit Add Member to DB', 'Occurs when a login is added or removed as a database user (fixed or user-defined) to a database; fo');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (111, 'Audit Add/Drop Role', 'Occurs when a login is added or removed as a database user to a database; for sp_addrole and sp_drop');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (112, 'App Role Pass Change', 'Occurs when a password of an application role is changed.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (113, 'Audit Statement Permission', 'Occurs when a statement permission (such as CREATE TABLE) is used.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (114, 'Audit Object Permission', 'Occurs when an object permission (such as SELECT) is used, both successfully or unsuccessfully.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (115, 'Audit Backup/Restore', 'Occurs when a BACKUP or RESTORE command is issued.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (116, 'Audit DBCC', 'Occurs when DBCC commands are issued.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (117, 'Audit Change Audit', 'Occurs when audit trace modifications are made.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (118, 'Audit Object Derived Permission', 'Occurs when a CREATE, ALTER, and DROP object commands are issued.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (0, 'Reserved', '');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (1, 'Reserved', '');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (2, 'Reserved', '');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (3, 'Reserved', '');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (4, 'Reserved', '');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (5, 'Reserved', '');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (6, 'Reserved', '');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (7, 'Reserved', '');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (8, 'Reserved', '');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (9, 'Reserved', '');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (10, 'RPC:Completed', 'Occurs when a remote procedure call (RPC) has completed.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (11, 'RPC:Starting', 'Occurs when an RPC has started.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (12, 'SQL:BatchCompleted', 'Occurs when a Transact-SQL batch has completed.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (13, 'SQL:BatchStarting', 'Occurs when a Transact-SQL batch has started.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (14, 'Login', 'Occurs when a user successfully logs in to SQL Server.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (15, 'Logout', 'Occurs when a user logs out of SQL Server.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (16, 'Attention', 'Occurs when attention events, such as client-interrupt requests or broken client connections, happen');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (17, 'ExistingConnection', 'Detects all activity by users connected to SQL Server before the trace started.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (18, 'ServiceControl', 'Occurs when the SQL Server service state is modified.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (19, 'DTCTransaction', 'Tracks Microsoft Distributed Transaction Coordinator (MS DTC) coordinated transactions between two o');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (20, 'Login Failed', 'Indicates that a login attempt to SQL Server from a client failed.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (21, 'EventLog', 'Indicates that events have been logged in the Microsoft Windows NT&reg; application log.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (22, 'ErrorLog', 'Indicates that error events have been logged in the SQL Server error log.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (23, 'Lock:Released', 'Indicates that a lock on a resource, such as a page, has been released.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (24, 'Lock:Acquired', 'Indicates acquisition of a lock on a resource, such as a data page.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (25, 'Lock:Deadlock', 'Indicates that two concurrent transactions have deadlocked each other by trying to obtain incompatib');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (26, 'Lock:Cancel', 'Indicates that the acquisition of a lock on a resource has been canceled (for example, due to a dead');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (27, 'Lock:Timeout', 'Indicates that a request for a lock on a resource, such as a page, has timed out due to another tran');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (28, 'DOP Event', 'Occurs before a SELECT, INSERT, or UPDATE statement is executed.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (29, 'Reserved', 'Use Event 28 instead.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (30, 'Reserved', 'Use Event 28 instead.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (31, 'Reserved', 'Use Event 28 instead.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (32, 'Reserved', '');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (33, 'Exception', 'Indicates that an exception has occurred in SQL Server.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (34, 'SP:CacheMiss', 'Indicates when a stored procedure is not found in the procedure cache.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (35, 'SP:CacheInsert', 'Indicates when an item is inserted into the procedure cache.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (36, 'SP:CacheRemove', 'Indicates when an item is removed from the procedure cache.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (37, 'SP:Recompile', 'Indicates that a stored procedure was recompiled.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (38, 'SP:CacheHit', 'Indicates when a stored procedure is found in the procedure cache.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (39, 'SP:ExecContextHit', 'Indicates when the execution version of a stored procedure has been found in the procedure cache.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (40, 'SQL:StmtStarting', 'Occurs when the Transact-SQL statement has started.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (41, 'SQL:StmtCompleted', 'Occurs when the Transact-SQL statement has completed.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (42, 'SP:Starting', 'Indicates when the stored procedure has started.');
INSERT INTO trace.Events (EventClass, EventName, EventDescription) VALUES (43, 'SP:Completed', 'Indicates when the stored procedure has completed.');
GO

/*********** Table : ColumnList ***********/

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'ColumnList' AND schema_id = schema_id('trace')) BEGIN
	CREATE TABLE trace.ColumnList(
	[ColumnID] [smallint] NOT NULL,
	[ColumnName] [varchar](50) NOT NULL,
	[ColumnDescription] [varchar](300) NULL,
	[DataType] [varchar](25) NULL
) ON [PRIMARY]
	PRINT 'Table : trace.ColumnList was created'
END ELSE BEGIN
	PRINT 'Table : trace.ColumnList already exists'
END
GO

INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (1, 'TextData', 'Text value dependent on the event class that is captured in the trace', 'nvarchar(128)');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (2, 'BinaryData', 'Binary value dependent on the event class captured in the trace', 'varbinary');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (3, 'DatabaseID', 'ID of the database specified by the USE database statement, or the default database if no USE databa', 'int');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (4, 'TransactionID', 'System-assigned ID of the transaction', 'bigint');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (5, 'Reserved', null, null);
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (6, 'NTUserName', 'Microsoft Windows NT; user name', 'nvarchar(128)');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (7, 'NTDomainName', 'Windows NT domain to which the user belongs', 'nvarchar(128)');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (8, 'ClientHostName', 'Name of the client computer that originated the request.', 'nvarchar(128)');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (9, 'ClientProcessID', 'ID assigned by the client computer to the process in which the client application is running', 'int');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (10, 'ApplicationName', 'Name of the client application that created the connection to an instance of SQL Server. This column', 'nvarchar(128)');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (11, 'SQLSecurityLoginName', 'SQL Server login name of the client', 'nvarchar(128)');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (12, 'SPID', 'Server Process ID assigned by SQL Server to the process associated with the client', 'int');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (13, 'Duration', 'Amount of elapsed time (in milliseconds) taken by the event. This data column is not populated by th', 'bigint');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (14, 'StartTime', 'Time at which the event started, when available', 'datetime');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (15, 'EndTime', 'Time at which the event ended. This column is not populated for starting event classes, such as SQL:', 'datetime');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (16, 'Reads', 'Number of logical disk reads performed by the server on behalf of the event. This column is not popu', 'bigint');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (17, 'Writes', 'Number of physical disk writes performed by the server on behalf of the event', 'bigint');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (18, 'CPU', 'Amount of CPU time (in milliseconds) used by the event', 'int');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (19, 'Permissions', 'Represents the bitmap of permissions; used by Security Auditing', 'int');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (20, 'Severity', 'Severity level of an exception', 'int');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (21, 'EventSubClass', 'Type of event subclass. This data column is not populated for all event classes', 'int');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (22, 'ObjectID', 'System-assigned ID of the object', 'int');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (23, 'Success', 'Success of the permissions usage attempt; used for auditing. 1 = success 0 = failure', 'int');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (24, 'IndexID', 'ID for the index on the object affected by the event. To determine the index ID for an object, use t', 'int');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (25, 'IntegerData', 'Integer value dependent on the event class captured in the trace', 'int');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (26, 'ServerName', 'Name of the instance of SQL Server (either servername or servername\instancename) being traced', 'nvarchar(128)');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (27, 'EventClass', 'Type of event class being recorded', 'int');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (28, 'ObjectType', 'Type of object (such as table, function, or stored procedure)', 'int');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (29, 'NestLevel', 'The nesting level at which this stored procedure is executing. See @@NESTLEVEL', 'int');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (30, 'State', 'Server state, in case of an error', 'int');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (31, 'Error', 'Error number', 'int');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (32, 'Mode', 'Lock mode of the lock acquired. This column is not populated by the Lock:Released event', 'int');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (33, 'Handle', 'Handle of the object referenced in the event', 'int');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (34, 'ObjectName', 'Name of object accessed', 'nvarchar(128)');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (35, 'DatabaseName', 'Name of the database specified in the USE database statement', 'nvarchar(128)');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (36, 'Filename', 'Logical name of the file name modified', 'nvarchar(128)');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (37, 'ObjectOwner', 'Owner ID of the object referenced', 'nvarchar(128)');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (38, 'TargetRoleName', 'Name of the database or server-wide role targeted by a statement', 'nvarchar(128)');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (39, 'TargetUserName', 'User name of the target of some action', 'nvarchar(128)');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (40, 'DatabaseUserName', 'SQL Server database username of the client', 'nvarchar(128)');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (41, 'LoginSID', 'Security identification number (SID) of the logged-in user', 'varbinary');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (42, 'TargetLoginName', 'Login name of the target of some action', 'nvarchar(128)');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (43, 'TargetLoginSID', 'SID of the login that is the target of some action', 'varbinary');
INSERT INTO trace.ColumnList (ColumnID, ColumnName, ColumnDescription, DataType) VALUES (44, 'ColumnPermissionsSet', 'Column-level permissions status; used by Security Auditing', 'int');
GO

/*********** Table : Result ***********/

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'Result' AND schema_id = schema_id('trace')) BEGIN
	CREATE TABLE trace.Result(
	[TextData] [varchar](max) NULL,
	[TextDataOriginal] [varchar](max) NULL,
	[BinaryData] [image] NULL,
	[DatabaseID] [int] NULL,
	[TransactionID] [bigint] NULL,
	[LineNumber] [int] NULL,
	[NTUserName] [nvarchar](256) NULL,
	[NTDomainName] [nvarchar](256) NULL,
	[HostName] [nvarchar](256) NULL,
	[ClientProcessID] [int] NULL,
	[ApplicationName] [nvarchar](256) NULL,
	[LoginName] [nvarchar](256) NULL,
	[SPID] [int] NULL,
	[Duration] [bigint] NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[Reads] [bigint] NULL,
	[Writes] [bigint] NULL,
	[CPU] [int] NULL,
	[Permissions] [bigint] NULL,
	[Severity] [int] NULL,
	[EventSubClass] [int] NULL,
	[ObjectID] [int] NULL,
	[Success] [int] NULL,
	[IndexID] [int] NULL,
	[IntegerData] [int] NULL,
	[ServerName] [nvarchar](256) NULL,
	[EventClass] [int] NULL,
	[ObjectType] [int] NULL,
	[NestLevel] [int] NULL,
	[State] [int] NULL,
	[Error] [int] NULL,
	[Mode] [int] NULL,
	[Handle] [int] NULL,
	[ObjectName] [nvarchar](256) NULL,
	[DatabaseName] [nvarchar](256) NULL,
	[FileName] [nvarchar](256) NULL,
	[OwnerName] [nvarchar](256) NULL,
	[RoleName] [nvarchar](256) NULL,
	[TargetUserName] [nvarchar](256) NULL,
	[DBUserName] [nvarchar](256) NULL,
	[LoginSid] [image] NULL,
	[TargetLoginName] [nvarchar](256) NULL,
	[TargetLoginSid] [image] NULL,
	[ColumnPermissions] [int] NULL,
	[LinkedServerName] [nvarchar](256) NULL,
	[ProviderName] [nvarchar](256) NULL,
	[MethodName] [nvarchar](256) NULL,
	[RowCounts] [bigint] NULL,
	[RequestID] [int] NULL,
	[XactSequence] [bigint] NULL,
	[EventSequence] [int] NULL,
	[BigintData1] [bigint] NULL,
	[BigintData2] [bigint] NULL,
	[GUID] [uniqueidentifier] NULL,
	[IntegerData2] [int] NULL,
	[ObjectID2] [bigint] NULL,
	[Type] [int] NULL,
	[OwnerID] [int] NULL,
	[ParentName] [nvarchar](256) NULL,
	[IsSystem] [int] NULL,
	[Offset] [int] NULL,
	[SourceDatabaseID] [int] NULL,
	[SqlHandle] [image] NULL,
	[SessionLoginName] [nvarchar](256) NULL,
	[PlanHandle] [image] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
	PRINT 'Table : trace.Result was created'
END ELSE BEGIN
	PRINT 'Table : trace.Result already exists'
END
GO

/*********** Stored procedure : AddEvent ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'AddEvent' AND schema_id = schema_id('Trace')) BEGIN
	DROP PROCEDURE trace.AddEvent
	PRINT 'Stored procedure : trace.AddEvent was dropped'
END
GO

CREATE PROCEDURE trace.AddEvent
(
	@TraceID	int,
	@EventList	varchar(1000),
	@ColumnList	varchar(1000) = NULL
)
AS
BEGIN
	CREATE TABLE #EventList
	(
		EventID		smallint NULL,
		EventName	varchar(50) COLLATE database_default NOT NULL 
	)

	CREATE TABLE #ColumnList
	(
		ColumnID		smallint NULL,
		ColumnName		varchar(50) COLLATE database_default NOT NULL 
	)

	CREATE TABLE #DistinctEvents
	(
		EventID smallint PRIMARY KEY
	)

	CREATE TABLE #DistinctColumns
	(
		ColumnID smallint PRIMARY KEY
	)

	SET NOCOUNT ON

	DECLARE @ProcedureName varchar(25), @EventName varchar(50), @ColumnName varchar(50), @Error varchar(100)
	DECLARE @Pos int, @ReturnValue int
	DECLARE @EventID int, @ColumnID int
	DECLARE @On bit
	DECLARE @TraceErrors table (Error int, [Description] varchar(100))

	SET @ProcedureName = 'AddEvent'
	SET @On = 1

	IF NOT EXISTS
	(
		SELECT 1 
		FROM ::fn_trace_getinfo(@TraceID)
	)
	BEGIN
		RAISERROR('Cannot find trace with ID %d. Source: %s', 16, 1, @TraceID, @ProcedureName)
		RETURN -1
	END

	IF LTRIM(@EventList) = ''
	BEGIN
		RAISERROR('Provide a valid list of Events. @EventList cannot be left blank. Source: %s', 16, 1, @TraceID, @ProcedureName)
		RETURN -1		
	END

	SET @EventList = LTRIM(RTRIM(@EventList))+ ','
	SET @Pos = CHARINDEX(',', @EventList, 1)

	IF REPLACE(@EventList, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @EventName = LTRIM(RTRIM(LEFT(@EventList, @Pos - 1)))

			IF @EventName <> ''
			BEGIN
				INSERT INTO #EventList (EventName) VALUES (@EventName)
			END

			SET @EventList = RIGHT(@EventList, LEN(@EventList) - @Pos)
			SET @Pos = CHARINDEX(',', @EventList, 1)

		END
	END	
	
	UPDATE #EventList
	SET EventID = E.EventClass
	FROM #EventList AS EL 
	JOIN Trace.Events AS E
	ON E.EventName = EL.EventName
	DELETE #EventList WHERE EventID IS NULL

	IF @@ROWCOUNT > 0
	BEGIN
		RAISERROR('Warning: some (or all) of the specified events are not recognized. Please double check the spelling and make sure all the events exists in the Events table. Source: %s', 0, 1, @ProcedureName)
	END

	IF LTRIM(@ColumnList) = ''
	BEGIN
		RAISERROR('Provide a valid list of Columns. @ColumnList cannot be left blank. Source: %s', 16, 1, @TraceID, @ProcedureName)
		RETURN -1		
	END

	SET @ColumnList = LTRIM(RTRIM(@ColumnList))+ ','
	SET @Pos = CHARINDEX(',', @ColumnList, 1)

	IF REPLACE(@ColumnList, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @ColumnName = LTRIM(RTRIM(LEFT(@ColumnList, @Pos - 1)))

			IF @ColumnName <> ''
			BEGIN
				INSERT INTO #ColumnList (ColumnName) VALUES (@ColumnName)
			END

			SET @ColumnList = RIGHT(@ColumnList, LEN(@ColumnList) - @Pos)
			SET @Pos = CHARINDEX(',', @ColumnList, 1)

		END
	END	
	
	UPDATE #ColumnList
	SET ColumnID = C.ColumnID
	FROM #ColumnList AS CL 
	JOIN Trace.ColumnList AS C
	ON C.ColumnName = CL.ColumnName

	DELETE #ColumnList WHERE ColumnID IS NULL

	IF @@ROWCOUNT > 0
	BEGIN
		RAISERROR('Warning: some (or all) of the specified columns are not recognized. Please double check the spelling and make sure all the columns exists in the Columns table. Source: %s', 0, 1, @ProcedureName)
	END

	INSERT INTO #DistinctEvents (EventID)
	SELECT DISTINCT EventID FROM #EventList
	
	INSERT INTO #DistinctColumns (ColumnID)
	SELECT DISTINCT ColumnID FROM #ColumnList

	INSERT INTO @TraceErrors (Error, Description) VALUES (1, 'Unknown error')
	INSERT INTO @TraceErrors (Error, Description) VALUES (2, 'The trace is currently running')
	INSERT INTO @TraceErrors (Error, Description) VALUES (3, 'The specified Event is not valid')
	INSERT INTO @TraceErrors (Error, Description) VALUES (4, 'The specified Column is not valid')
	INSERT INTO @TraceErrors (Error, Description) VALUES (9, 'The specified Trace Handle is not valid')
	INSERT INTO @TraceErrors (Error, Description) VALUES (11, 'The specified Column is used internally and cannot be removed')
	INSERT INTO @TraceErrors (Error, Description) VALUES (13, 'Out of memory')
	INSERT INTO @TraceErrors (Error, Description) VALUES (16, 'The function is not valid for this trace')

	SET @EventID = (SELECT MIN(EventID) FROM #DistinctEvents)
	WHILE @EventID IS NOT NULL
	BEGIN
		SET @ColumnID = (SELECT MIN(ColumnID) FROM #DistinctColumns)
		WHILE @ColumnID IS NOT NULL
		BEGIN
			EXEC @ReturnValue = sp_trace_setevent
								@traceid = @TraceID,
								@eventid = @EventID,
								@columnid = @ColumnID,
								@on = @On

			IF @ReturnValue <> 0
			BEGIN
				SET @Error = (SELECT [Description] FROM @TraceErrors WHERE Error = @ReturnValue)
				SET @Error = COALESCE(@Error, 'Unknown error ' + CAST(@ReturnValue AS varchar(10)))
				RAISERROR('Failed to add Event %d with Column %d. Error: %s. Source: %s', 16, 1, @EventID, @ColumnID, @Error, @ProcedureName)
				RETURN -1
			END

			SET @ColumnID = (SELECT MIN(ColumnID) FROM #DistinctColumns WHERE ColumnID > @ColumnID)			
		END
		SET @EventID = (SELECT MIN(EventID) FROM #DistinctEvents WHERE EventID > @EventID)
	END

END
GO
PRINT 'Stored Procedure : Trace.AddEvent was created'
GO

/*********** Stored procedure : AddFilter ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'AddFilter' AND schema_id = schema_id('trace')) BEGIN
	DROP PROCEDURE trace.AddFilter
	PRINT 'Stored procedure : trace.AddFilter was dropped'
END
GO

CREATE PROCEDURE trace.AddFilter
(
	@TraceID		int,
	@ColumnName		varchar(50),
	@Value			sql_variant,
	@ComparisonOperator	varchar(8) = '=',
	@LogicalOperator	varchar(3) = 'OR'
)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @ProcedureName varchar(25), @Error varchar(100), @DataType varchar(20)
	DECLARE @ReturnValue int, @CompOp int, @LogOp int, @ColumnID int
	DECLARE @TraceErrors table (Error int, [Description] varchar(100))
	DECLARE @ComparisonOperators table (OperatorID int, Operator varchar(8))
	DECLARE @bigint bigint, @datetime datetime, @int int, @nvarchar nvarchar(128), @varbinary varbinary


	SET @ProcedureName = 'AddFilter'

	IF NOT EXISTS
	(
		SELECT 1 
		FROM ::fn_trace_getinfo(@TraceID)
	)
	BEGIN
		RAISERROR('Cannot find trace with ID %d. Source: %s', 16, 1, @TraceID, @ProcedureName)
		RETURN -1
	END
	
	IF (LTRIM(@ColumnName) = '') OR (@ColumnName IS NULL)
	BEGIN
		RAISERROR('Provide a valid value for @ColumnName parameter. Source: %s', 16, 1, @ProcedureName)
		RETURN -1		
	END

	IF (LTRIM(CAST(@Value AS varchar)) = '') OR (@Value IS NULL)
	BEGIN
		RAISERROR('Provide a valid value for @Value parameter. NULLs and empty values are not allowed. Source: %s', 16, 1, @ProcedureName)
		RETURN -1		
	END

	IF UPPER(@LogicalOperator) NOT IN ('AND', 'OR')
	BEGIN
		RAISERROR('Provide a valid value for @LogicalOperator parameter. Only ''AND'' and ''OR'' are allowed. Source: %s', 16, 1, @ProcedureName)
		RETURN -1		
	END

	INSERT @ComparisonOperators (OperatorID, Operator) VALUES (0, '=')
	INSERT @ComparisonOperators (OperatorID, Operator) VALUES (1, '<>')
	INSERT @ComparisonOperators (OperatorID, Operator) VALUES (2, '>')
	INSERT @ComparisonOperators (OperatorID, Operator) VALUES (3, '<')
	INSERT @ComparisonOperators (OperatorID, Operator) VALUES (4, '>=')
	INSERT @ComparisonOperators (OperatorID, Operator) VALUES (5, '<=')
	INSERT @ComparisonOperators (OperatorID, Operator) VALUES (6, 'LIKE')
	INSERT @ComparisonOperators (OperatorID, Operator) VALUES (7, 'NOT LIKE')
	
	SET @CompOp = (SELECT OperatorID FROM @ComparisonOperators WHERE LOWER(Operator) = LOWER(@ComparisonOperator))
	
	IF @CompOp IS NULL
	BEGIN
		RAISERROR('Provide a valid comparison operator. Source: %s', 16, 1, @ProcedureName)
		RETURN -1
	END

	SET @LogOp = CASE UPPER(@LogicalOperator) WHEN 'AND' THEN 0 WHEN 'OR' THEN 1 END

	IF @LogOp IS NULL
	BEGIN
		RAISERROR('Provide a valid logical operator. Source: %s', 16, 1, @ProcedureName)
		RETURN -1
	END

	SELECT @ColumnID = ColumnID, @DataType = DataType FROM Trace.ColumnList WHERE ColumnName = @ColumnName

	IF (@ColumnID IS NULL) OR (@DataType IS NULL)
	BEGIN
		RAISERROR('Provide a valid column name. Source: %s', 16, 1, @ProcedureName)
		RETURN -1
	END

	IF NOT EXISTS
	(
		SELECT 1
		FROM ::fn_trace_geteventinfo(@TraceID)
		WHERE ColumnID = @ColumnID
	)
	BEGIN
		RAISERROR('The data column you are trying to filter on, is not currently added to the trace definition. Add the column and retry setting the filter. Source: %s', 16, 1, @ProcedureName)
		RETURN -1		
	END

	INSERT INTO @TraceErrors (Error, Description) VALUES (1, 'Unknown error')
	INSERT INTO @TraceErrors (Error, Description) VALUES (2, 'The trace is currently running')
	INSERT INTO @TraceErrors (Error, Description) VALUES (4, 'The specified Column is not valid')
	INSERT INTO @TraceErrors (Error, Description) VALUES (5, 'The specified Column is not allowed for filtering')
	INSERT INTO @TraceErrors (Error, Description) VALUES (6, 'The specified Comparison Operator is not valid')
	INSERT INTO @TraceErrors (Error, Description) VALUES (7, 'The specified Logical Operator is not valid')
	INSERT INTO @TraceErrors (Error, Description) VALUES (9, 'The specified Trace Handle is not valid')
	INSERT INTO @TraceErrors (Error, Description) VALUES (13, 'Out of memory')
	INSERT INTO @TraceErrors (Error, Description) VALUES (16, 'The function is not valid for this trace')

	IF @DataType = 'bigint'
	BEGIN
		SET @bigint = CAST(@Value AS bigint)
		EXEC @ReturnValue = sp_trace_setfilter 
							@traceid = @TraceID, 
							@columnid = @ColumnID,
							@logical_operator = @LogOp,
							@comparison_operator = @CompOp,
							@value = @bigint
	END
	ELSE IF @DataType = 'datetime'
	BEGIN
		SET @datetime = CAST(@Value AS datetime)
		EXEC @ReturnValue = sp_trace_setfilter 
							@traceid = @TraceID, 
							@columnid = @ColumnID,
							@logical_operator = @LogOp,
							@comparison_operator = @CompOp,
							@value = @datetime	
	END
	ELSE IF @DataType = 'int'
	BEGIN
		SET @int = CAST(@Value AS int)
		EXEC @ReturnValue = sp_trace_setfilter 
							@traceid = @TraceID, 
							@columnid = @ColumnID,
							@logical_operator = @LogOp,
							@comparison_operator = @CompOp,
							@value = @int	
	END
	ELSE IF @DataType = 'nvarchar(128)'
	BEGIN
		SET @nvarchar = CAST(@Value AS nvarchar(128))
		EXEC @ReturnValue = sp_trace_setfilter 
							@traceid = @TraceID, 
							@columnid = @ColumnID,
							@logical_operator = @LogOp,
							@comparison_operator = @CompOp,
							@value = @nvarchar	
	END
	ELSE IF @DataType = 'varbinary'
	BEGIN
		SET @varbinary = CAST(@Value AS varbinary)
		EXEC @ReturnValue = sp_trace_setfilter 
							@traceid = @TraceID, 
							@columnid = @ColumnID,
							@logical_operator = @LogOp,
							@comparison_operator = @CompOp,
							@value = @varbinary			
	END
	ELSE
	BEGIN
		RAISERROR('Unrecognized datatype for the filter column. Source: %s', 16, 1, @ProcedureName)
		RETURN -1
	END

	IF @ReturnValue <> 0
	BEGIN
		SET @Error = (SELECT [Description] FROM @TraceErrors WHERE Error = @ReturnValue)
		SET @Error = COALESCE(@Error, 'Unknown error ' + CAST(@ReturnValue AS varchar(10)))
		RAISERROR('Failed to add Filter. Error: %s. Source: %s', 16, 1, @Error, @ProcedureName)
		RETURN -1
	END

	RETURN 0
END
GO
PRINT 'Stored Procedure : trace.AddFilter was created'
GO

/*********** Stored procedure : CreateTrace ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'CreateTrace' AND schema_id = schema_id('trace')) BEGIN
	DROP PROCEDURE Trace.CreateTrace
	PRINT 'Stored procedure : trace.CreateTrace was dropped'
END
GO
  
CREATE PROCEDURE trace.CreateTrace
(  
 @OutputFile nvarchar(245) = NULL,  
 @OverwriteFile bit = 0,  
 @MaxSize bigint = 5,  
 @Rollover bit = 1,  
 @Shutdown bit = 0,  
 @Blackbox bit = 0,  
 @StopAt  datetime = NULL,  
 @OutputTraceID int = NULL OUT  
)  
AS  
BEGIN  
 SET NOCOUNT ON  
   
 DECLARE @ReturnValue int, @FileExists int, @MaxAllowedSize int, @Options int  
 DECLARE @ProcedureName varchar(25), @TraceFileExt nchar(4), @OSCommand nvarchar(255)  
 DECLARE @Error varchar(100)  
 DECLARE @TraceErrors table (Error int, [Description] varchar(100))  
  
 SET @ProcedureName = 'CreateTrace'  
 SET @TraceFileExt = '.trc'  
 SET @MaxAllowedSize = 1024  
  
 IF COALESCE(@Blackbox, 0) = 0  
 BEGIN  
  IF (@MaxSize IS NULL) OR (@MaxSize <= 0) OR (@MaxSize > @MaxAllowedSize)  
  BEGIN  
   RAISERROR('Invalid trace file size. Valid values are between 1 and %d. You could change the maximum allowed size by editing the stored procedure and setting @MaxAllowedSize to a desired value. Source: %s', 16, 1, @MaxAllowedSize, @ProcedureName)  
   RETURN -1  
  END  
   
  IF @StopAt < CURRENT_TIMESTAMP  
  BEGIN  
   RAISERROR('The trace stop time cannot be in the past. Source: %s', 16, 1, @ProcedureName)  
   RETURN -1  
  END  
   
  SET @Options =   CASE @Rollover WHEN 1 THEN 2 ELSE 0 END  
    + CASE @Shutdown WHEN 1 THEN 4 ELSE 0 END  
   
  IF @Options < 2 AND (@MaxSize IS NULL) 
  BEGIN  
   RAISERROR('Please provide valid tracing options. If you don''t specify any, the trace will default to ''Rollover to new file'' when the specified max trace file size is reached', 16, 1, @ProcedureName)  
   RETURN -1  
  END  
   
  IF (@OutputFile IS NOT NULL) AND (LTRIM(@OutputFile) <> '')  
  BEGIN  
   SET @OutputFile = RTRIM(@OutputFile) + @TraceFileExt  
   
   EXEC @ReturnValue = master..xp_fileexist @OutputFile, @FileExists OUT  
   
   IF @ReturnValue <> 0  
   BEGIN  
    RAISERROR('Error occured while checking for trace output file existence. Source: %s', 16, 1, @ProcedureName)  
    RETURN -1  
   END  
     
   IF @OverwriteFile = 1  
   BEGIN  
    IF @FileExists = 1  
    BEGIN  
     SET @OSCommand = 'Del ' + @OutputFile  
     EXEC @ReturnValue = master..xp_cmdshell @OSCommand, 'no_output'  
   
     IF @ReturnValue <> 0  
     BEGIN  
      RAISERROR('Error occured while deleting the trace output file. Source: %s', 16, 1, @ProcedureName)  
      RETURN -1  
     END  
    END  
   END  
   ELSE  
   BEGIN  
    IF @FileExists = 1  
    BEGIN  
     RAISERROR('Trace output file already exists. Either delete it or set @OverwriteFile to 1 and try again. Source: %s', 16, 1, @ProcedureName)  
     RETURN -1  
    END     
   END    
  END  
  ELSE  
  BEGIN  
   RAISERROR('@OutputFile is a mandatory parameter and you must provide a valid value. Source: %s', 16, 1, @ProcedureName)  
   RETURN -1  
  END  
 END  
 ELSE  
 BEGIN  
  IF (@Rollover = 1) OR (@Shutdown = 1)  
  BEGIN  
   RAISERROR('Warning: When setting @Blackbox to 1, any other options you set will be ignored, as @Blackbox option is not compatible with other options. Source: %s', 0, 1, @ProcedureName)  
   SET @Options = 8  
  END  
 END  
  
 INSERT INTO @TraceErrors (Error, [Description]) VALUES (1, 'Unknown error')  
 INSERT INTO @TraceErrors (Error, [Description]) VALUES (10, 'Invalid options')  
 INSERT INTO @TraceErrors (Error, [Description]) VALUES (12, 'File not created')  
 INSERT INTO @TraceErrors (Error, [Description]) VALUES (13, 'Out of memory')  
 INSERT INTO @TraceErrors (Error, [Description]) VALUES (14, 'Invalid stop time')  
 INSERT INTO @TraceErrors (Error, [Description]) VALUES (15, 'Invalid parameters')  
  
 IF @Blackbox = 0  
 BEGIN  
  SET @OutputFile = LEFT(@OutputFile, LEN(@OutputFile) - LEN(@TraceFileExt))  
  EXEC @ReturnValue = sp_trace_create @traceid = @OutputTraceID OUT,  
           @options = @Options,  
       @tracefile = @OutputFile,  
       @maxfilesize = @MaxSize,  
       @stoptime = @StopAt  
 END  
 ELSE  
 BEGIN  
  EXEC @ReturnValue = sp_trace_create @traceid = @OutputTraceID OUT,  
           @options = @Options  
 END  
    
 IF @ReturnValue <> 0  
 BEGIN  
  SET @Error = (SELECT [Description] FROM @TraceErrors WHERE Error = @ReturnValue)  
  SET @Error = COALESCE(@Error, 'Unknown error ' + CAST(@ReturnValue AS varchar(10)))  
  RAISERROR('Failed to create trace. Error: %s. Source: %s', 16, 1, @Error, @ProcedureName)  
  RETURN -1  
 END  
 ELSE  
 BEGIN  
  SELECT @OutputTraceID AS TraceID  
  RETURN 0  
 END  
END  
GO
PRINT 'Stored Procedure : Trace.CreateTrace was created'
GO

/*********** Stored procedure : Start ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'Start' AND schema_id = schema_id('trace')) BEGIN
	DROP PROCEDURE trace.Start
	PRINT 'Stored procedure : trace.Start was dropped'
END
GO

CREATE PROC trace.Start
(
	@TraceID int
)
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @ReturnValue int, @Start int
	DECLARE @ProcedureName varchar(25), @Error varchar(100)
	DECLARE @TraceErrors table (Error int, [Description] varchar(100))
	
	SET @ProcedureName = 'Start'
	SET @Start = 1

	IF NOT EXISTS
	(
		SELECT 1 
		FROM ::fn_trace_getinfo(@TraceID)
	)
	BEGIN
		RAISERROR('Cannot find trace with ID %d. Source: %s', 16, 1, @TraceID, @ProcedureName)
		RETURN -1
	END

	INSERT INTO @TraceErrors (Error, [Description]) VALUES (1, 'Unknown error')
	INSERT INTO @TraceErrors (Error, [Description]) VALUES (8, 'The specified Status is not valid')
	INSERT INTO @TraceErrors (Error, [Description]) VALUES (9, 'The specified Trace Handle is not valid')
	INSERT INTO @TraceErrors (Error, [Description]) VALUES (13, 'Out of memory')
		
	EXEC @ReturnValue = sp_trace_setstatus @traceid = @TraceID, @status = @Start

	IF @ReturnValue <> 0
	BEGIN
		SET @Error = (SELECT [Description] FROM @TraceErrors WHERE Error = @ReturnValue)
		SET @Error = COALESCE(@Error, 'Unknown error ' + CAST(@ReturnValue AS varchar(10)))
		RAISERROR('Failed to start trace. Error: %s. Source: %s', 16, 1, @Error, @ProcedureName)
		RETURN -1
	END
	
	UPDATE	Trace.Trace 
	SET		StartAt = GETDATE()
	WHERE	SqlTraceId = @TraceID

	RETURN 0

END
GO
PRINT 'Stored Procedure : Trace.Start was created'
GO

/*********** Stored procedure : Stop ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'Stop' AND schema_id = schema_id('trace')) BEGIN
	DROP PROCEDURE trace.Stop
	PRINT 'Stored procedure : trace.Stop was dropped'
END
GO

CREATE PROCEDURE trace.Stop
(
	@TraceID int
)
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @ReturnValue int, @Stop int
	DECLARE @ProcedureName varchar(25), @Error varchar(100)
	DECLARE @TraceErrors table (Error int, [Description] varchar(100))

	SET @ProcedureName = 'Stop'
	SET @Stop = 0

	IF NOT EXISTS
	(
		SELECT 1 
		FROM ::fn_trace_getinfo(@TraceID)
	)
	BEGIN
		RAISERROR('Cannot find trace with ID %d. Source: %s', 16, 1, @TraceID, @ProcedureName)
		RETURN -1
	END

	INSERT INTO @TraceErrors (Error, [Description]) VALUES (1, 'Unknown error')
	INSERT INTO @TraceErrors (Error, [Description]) VALUES (8, 'The specified Status is not valid')
	INSERT INTO @TraceErrors (Error, [Description]) VALUES (9, 'The specified Trace Handle is not valid')
	INSERT INTO @TraceErrors (Error, [Description]) VALUES (13, 'Out of memory')
		
	EXEC @ReturnValue = sp_trace_setstatus @traceid = @TraceID, @status = @Stop

	IF @ReturnValue <> 0
	BEGIN
		SET @Error = (SELECT [Description] FROM @TraceErrors WHERE Error = @ReturnValue)
		SET @Error = COALESCE(@Error, 'Unknown error ' + CAST(@ReturnValue AS varchar(10)))
		RAISERROR('Failed to stop trace. Error: %s. Source: %s', 16, 1, @Error, @ProcedureName)
		RETURN -1
	END
	
	UPDATE	Trace.Trace 
	SET		StopAt = GETDATE()
	WHERE	SqlTraceId = @TraceID

	RETURN 0

END
GO
PRINT 'Stored Procedure : trace.Stop was created'
GO

/*********** Stored procedure : Init ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'Init' AND schema_id = schema_id('trace')) BEGIN
	DROP PROCEDURE Trace.Init
	PRINT 'Stored procedure : trace.Init was dropped'
END
GO

CREATE PROCEDURE trace.Init
	@intTypeId INT = 1,
	@intRunTimeInMiliseconds INT = 0,
	@intMaxSize BIGINT = 5,
	@intRollOver BIT = 0,
	@intDurationGreaterThanInMiliseconds INT = 0,
	@intReadsGreaterThan INT = 0,
	@intWritesGreaterThan INT = 0,
	@strPath VARCHAR(250),
	@intAutoStart INT = 1	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @intOutputTraceId INT
	DECLARE @dtmStartTime DATETIME
	DECLARE @dtmStopTime DATETIME
	DECLARE @strFileName VARCHAR(1000)
	
	IF @intAutoStart = 1 BEGIN
		SET @dtmStartTime = GETDATE()
	END

	/* Run time in minutes can not exceed 10 minutes */
	IF @intRunTimeInMiliseconds > 50000 BEGIN SET @intRunTimeInMiliseconds = 50000 END

	IF @intRunTimeInMiliseconds <> 0 BEGIN
		SET @dtmStopTime = DATEADD(ms, @intRunTimeInMiliseconds, @dtmStartTime)
	END ELSE BEGIN
		SET @dtmStopTime = NULL
	END	
	
	SET @strFileName = @strPath + '\' + CONVERT(VARCHAR, @intTypeId) + '-' + CONVERT(VARCHAR, GETDATE(), 112) + '-' + REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':', '')

	/* Check on Duration, Reads, Writes */
	IF @intTypeId = 1 BEGIN

		EXEC Trace.CreateTrace @strFileName, 0, @intMaxSize, @intRollOver, 0, 0, @dtmStopTime, @intOutputTraceId OUTPUT
		EXEC Trace.AddEvent @intOutputTraceId, 'RPC:Completed,SQL:BatchCompleted','TextData,BinaryData,DatabaseID,TransactionID,Reserved,NTUserName,NTDomainName,ClientHostName,ClientProcessID,ApplicationName,SQLSecurityLoginName,SPID,Duration,StartTime,EndTime,Reads,Writes,CPU,Permissions,Severity,EventSubClass,ObjectID,Success,IndexID,IntegerData,ServerName,EventClass,ObjectType,NestLevel,State,Error,Mode,Handle,ObjectName,DatabaseName,Filename,ObjectOwner,TargetRoleName,TargetUserName,DatabaseUserName,LoginSID,TargetLoginName,TargetLoginSID,ColumnPermissionsSet,RowCounts'

		IF @intDurationGreaterThanInMiliseconds <> 0 BEGIN
			EXEC Trace.AddFilter @intOutputTraceId, 'Duration', @intDurationGreaterThanInMiliseconds,'>=','OR'
		END
		IF @intReadsGreaterThan <> 0 BEGIN
			EXEC Trace.AddFilter @intOutputTraceId, 'Reads', @intReadsGreaterThan,'>=','OR'
		END
		IF @intWritesGreaterThan <> 0 BEGIN
			EXEC Trace.AddFilter @intOutputTraceId, 'Writes', @intWritesGreaterThan,'>=','OR'
		END
		EXEC Trace.AddFilter @intOutputTraceId, 'NTUserName', 'SYSTEM','<>','AND'
		IF @intAutoStart = 1 BEGIN
			EXEC Trace.Start @intOutputTraceId
		END

	END 
	/* Check on Deadloacks */
	IF @intTypeId = 2 BEGIN
		EXEC Trace.CreateTrace @strFileName, 0, @intMaxSize, @intRollOver, 0, 0, @dtmStopTime, @intOutputTraceId OUTPUT
		EXEC Trace.AddEvent @intOutputTraceId, 'Lock:Deadlock, Lock:Deadlock Chain, RPC:Starting, SQL:BatchStarting', 'TextData,BinaryData,DatabaseID,TransactionID,Reserved,NTUserName,NTDomainName,ClientHostName,ClientProcessID,ApplicationName,SQLSecurityLoginName,SPID,Duration,StartTime,EndTime,Reads,Writes,CPU,Permissions,Severity,EventSubClass,ObjectID,Success,IndexID,IntegerData,ServerName,EventClass,ObjectType,NestLevel,State,Error,Mode,Handle,ObjectName,DatabaseName,Filename,ObjectOwner,TargetRoleName,TargetUserName,DatabaseUserName,LoginSID,TargetLoginName,TargetLoginSID,ColumnPermissionsSet'
		EXEC Trace.AddFilter @intOutputTraceId, 'NTUserName', 'SYSTEM','<>','AND'
		IF @intAutoStart = 1 BEGIN
			EXEC Trace.Start @intOutputTraceId
		END
	END
	/* Check recompilations */
	IF @intTypeId = 3 BEGIN
		EXEC Trace.CreateTrace @strFileName, 0, @intMaxSize, @intRollOver, 0, 0, @dtmStopTime, @intOutputTraceId OUTPUT
		EXEC Trace.AddEvent @intOutputTraceId, 'SP:Recompile', 'TextData,BinaryData,DatabaseID,TransactionID,Reserved,NTUserName,NTDomainName,ClientHostName,ClientProcessID,ApplicationName,SQLSecurityLoginName,SPID,Duration,StartTime,EndTime,Reads,Writes,CPU,Permissions,Severity,EventSubClass,ObjectID,Success,IndexID,IntegerData,ServerName,EventClass,ObjectType,NestLevel,State,Error,Mode,Handle,ObjectName,DatabaseName,Filename,ObjectOwner,TargetRoleName,TargetUserName,DatabaseUserName,LoginSID,TargetLoginName,TargetLoginSID,ColumnPermissionsSet'
		EXEC Trace.AddFilter @intOutputTraceId, 'NTUserName', 'SYSTEM','<>','AND'
		IF @intAutoStart = 1 BEGIN
			EXEC Trace.Start @intOutputTraceId
		END
	END

	IF EXISTS (SELECT TraceId FROM Trace.Trace WHERE SqlTraceId = @intOutputTraceId) BEGIN
		UPDATE	Trace.Trace
		SET		Removed = 1
		WHERE	SqlTraceId = @intOutputTraceId
	END
	
	INSERT	INTO Trace.Trace(SqlTraceId, OutputFile, TypeId, RunTimeInMiliseconds, DurationGreaterThanInMiliseconds, ReadsGreaterThan, WritesGreaterThan, StartAt, StopAt, Removed)
	VALUES	(@intOutputTraceId, @strFileName, @intTypeId, @intRunTimeInMiliseconds, @intDurationGreaterThanInMiliseconds, @intReadsGreaterThan, @intWritesGreaterThan, @dtmStartTime, @dtmStopTime, 0)
	
	RETURN @intOutputTraceId
END
GO
PRINT 'Stored Procedure : trace.Init was created'
GO

/*********** Stored procedure : Remove ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'Remove' AND schema_id = schema_id('trace')) BEGIN
	DROP PROCEDURE trace.Remove
	PRINT 'Stored procedure : trace.Remove was dropped'
END
GO

CREATE PROCEDURE trace.Remove
(
	@TraceID int
)
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @ReturnValue int, @Clear int
	DECLARE @ProcedureName varchar(25), @Error varchar(100)
	DECLARE @TraceErrors table (Error int, [Description] varchar(100))

	SET @ProcedureName = 'Remove'
	SET @Clear = 2

	IF NOT EXISTS
	(
		SELECT 1 
		FROM ::fn_trace_getinfo(@TraceID)
	)
	BEGIN
		RAISERROR('Cannot find trace with ID %d. Source: %s', 16, 1, @TraceID, @ProcedureName)
		RETURN -1
	END

	INSERT INTO @TraceErrors (Error, [Description]) VALUES (1, 'Unknown error')
	INSERT INTO @TraceErrors (Error, [Description]) VALUES (8, 'The specified Status is not valid')
	INSERT INTO @TraceErrors (Error, [Description]) VALUES (9, 'The specified Trace Handle is not valid')
	INSERT INTO @TraceErrors (Error, [Description]) VALUES (13, 'Out of memory')
		
	EXEC @ReturnValue = sp_trace_setstatus @traceid = @TraceID, @status = @Clear

	IF @ReturnValue <> 0
	BEGIN
		SET @Error = (SELECT [Description] FROM @TraceErrors WHERE Error = @ReturnValue)
		SET @Error = COALESCE(@Error, 'Unknown error ' + CAST(@ReturnValue AS varchar(10)))
		RAISERROR('Failed to clear trace. Error: %s. Source: %s', 16, 1, @Error, @ProcedureName)
		RETURN -1
	END

	RETURN 0

END
GO
PRINT 'Stored Procedure : trace.Remove was created'
GO

/*********** Stored procedure : Remove ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'Status' AND schema_id = schema_id('trace')) BEGIN
	DROP PROCEDURE trace.Status
	PRINT 'Stored procedure : trace.Status was dropped'
END
GO

CREATE PROCEDURE trace.Status
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @intMiracleTraceId INT
	DECLARE @intTraceId INT
	DECLARE @bitTraceExists BIT
	DECLARE @bitTraceRunning BIT
	DECLARE @dtmStartAt DATETIME
	DECLARE @dtmStopAt DATETIME
	DECLARE @intRemoved INT
	DECLARE @strOutputFile VARCHAR(250)

	DECLARE @tmpTraceTable TABLE (
		[MiracleTraceId][int],
		[MiracleTrace][bit],
		[TraceId][int],
		[Existing][bit],
		[Running][bit],
		[StartTime][datetime],
		[StopTime][datetime],
		[OutputFile][varchar](250)
	)

	DECLARE curTraceTmp CURSOR FOR
	SELECT	MiracleTraceId = TraceId, 
			TraceId = SqlTraceId,
			StartAt,
			StopAt,
			Removed,
			OutputFile
	FROM	trace.Trace

	OPEN curTraceTmp

	FETCH NEXT FROM curTraceTmp
	INTO @intMiracleTraceId, @intTraceId, @dtmStartAt, @dtmStopAt, @intRemoved, @strOutputFile

	WHILE @@FETCH_STATUS = 0 BEGIN
		SET @bitTraceExists = 0
		SET @bitTraceRunning = 0
		
		IF EXISTS (SELECT traceid FROM ::fn_trace_getinfo(@intTraceId)) AND @intRemoved = 0 BEGIN
			SET @bitTraceExists = 1
		END
		IF EXISTS (SELECT traceid FROM ::fn_trace_getinfo(@intTraceId) WHERE property = 5 AND value = 1) AND @bitTraceExists = 1 BEGIN
			IF (@dtmStopAt IS NULL) BEGIN
				SET @bitTraceRunning = 1
			END ELSE IF (GETDATE() > @dtmStopAt) BEGIN
				SET @bitTraceRunning = 1
			END
		END
		
		INSERT	INTO @tmpTraceTable (MiracleTraceId, MiracleTrace, TraceId, Existing, Running, StartTime, StopTime, OutputFile)
		VALUES	(@intMiracleTraceId, 1, @intTraceId, @bitTraceExists, @bitTraceRunning, @dtmStartAt, @dtmStopAt, @strOutputFile)

		FETCH NEXT FROM curTraceTmp
		INTO @intMiracleTraceId, @intTraceId, @dtmStartAt, @dtmStopAt, @intRemoved, @strOutputFile
	END
	CLOSE curTraceTmp
	DEALLOCATE curTraceTmp
	
	DECLARE curTraceTmp CURSOR FOR
	SELECT	traceid
	FROM	::fn_trace_getinfo(0)
	WHERE	traceid NOT IN (SELECT TraceId FROM @tmpTraceTable)
	GROUP	BY traceid
	
	OPEN curTraceTmp
	
	FETCH NEXT FROM curTraceTmp 
	INTO @intTraceId
	
	WHILE @@FETCH_STATUS = 0 BEGIN
	
		SELECT	@strOutputFile = CONVERT(VARCHAR(250), value)
		FROM	::fn_trace_getinfo(0)
		WHERE	traceid = @intTraceId 
				AND property = 2
				
		SELECT	@bitTraceRunning = CONVERT(BIT, value)
		FROM	::fn_trace_getinfo(0)
		WHERE	traceid = @intTraceId 
				AND property = 5
				
		INSERT	INTO @tmpTraceTable (MiracleTraceId, MiracleTrace, TraceId, Existing, Running, StartTime, StopTime, OutputFile)
		VALUES	(0, 0, @intTraceId, 1, @bitTraceRunning, null, null, @strOutputFile)
	
		FETCH NEXT FROM curTraceTmp 
		INTO @intTraceId
	END
	CLOSE curTraceTmp
	DEALLOCATE curTraceTmp


	SELECT * FROM @tmpTraceTable
END
GO
PRINT 'Stored Procedure : trace.Status was created'
GO

/*********** Stored procedure : Import ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'Import' AND schema_id = schema_id('trace')) BEGIN
	DROP PROCEDURE trace.Import
	PRINT 'Stored procedure : trace.Import was dropped'
END
GO

CREATE PROCEDURE trace.Import
	@intTypeId INT = 1,
	@strDateStart VARCHAR(10),
	@strDateStop VARCHAR(10),
	@strHourStart VARCHAR(8) = '00:00:01',
	@strHourStop VARCHAR(8) = '23:59:59',
	@intAppend INT = 1
AS
BEGIN
	
	SET NOCOUNT ON;

	IF @intAppend = 0 BEGIN
		TRUNCATE TABLE Trace.Result
	END
	
	DECLARE @strOutputFile VARCHAR(254)
	DECLARE @dtmStartDate DATETIME
	DECLARE @dtmStopDate DATETIME
	DECLARE @strStart VARCHAR(50)
	DECLARE @strStop VARCHAR(50)

	SET @dtmStartDate = CONVERT(DATETIME, @strDateStart)
	SET @dtmStopDate = CONVERT(DATETIME, @strDateStop)

	WHILE @dtmStartDate <= @dtmStopDate BEGIN
		SET @strStart = REPLACE(CONVERT(VARCHAR, @dtmStartDate, 102), '.', '-') + ' ' + @strHourStart
		SET @strStop = REPLACE(CONVERT(VARCHAR, @dtmStartDate, 102), '.', '-') + ' ' + @strHourStop
		
		DECLARE curTmp CURSOR FOR
		SELECT	OutputFile
		FROM	Trace.Trace
		WHERE	TypeId = @intTypeId
				AND StartAt BETWEEN @strStart AND @strStop

		OPEN curTmp
		FETCH NEXT FROM curTmp
		INTO @strOutputFile

		WHILE @@FETCH_STATUS = 0 BEGIN

			BEGIN TRY
				INSERT	INTO trace.Result (TextData,TextDataOriginal,BinaryData,DatabaseID,TransactionID,LineNumber,NTUserName,NTDomainName,HostName,ClientProcessID,ApplicationName,LoginName,SPID,Duration,StartTime,EndTime,Reads,Writes,CPU,[Permissions],Severity,EventSubClass,ObjectID,Success,IndexID,IntegerData,ServerName,EventClass,ObjectType,NestLevel,State,Error,Mode,Handle,ObjectName,DatabaseName,[FileName],OwnerName,RoleName,TargetUserName,DBUserName,LoginSid,TargetLoginName,TargetLoginSid,ColumnPermissions,LinkedServerName,ProviderName,MethodName,RowCounts,RequestID,XactSequence,EventSequence,BigintData1,BigintData2,GUID,IntegerData2,ObjectID2,[Type],OwnerID,ParentName,IsSystem,Offset,SourceDatabaseID,SqlHandle,SessionLoginName,PlanHandle)
					SELECT Trace.TextdataCleanup(TextData),TextData,BinaryData,DatabaseID,TransactionID,LineNumber,NTUserName,NTDomainName,HostName,ClientProcessID,ApplicationName,LoginName,SPID,Duration,StartTime,EndTime,Reads,Writes,CPU,[Permissions],Severity,EventSubClass,ObjectID,Success,IndexID,IntegerData,ServerName,EventClass,ObjectType,NestLevel,State,Error,Mode,Handle,ObjectName,DatabaseName,[FileName],OwnerName,RoleName,TargetUserName,DBUserName,LoginSid,TargetLoginName,TargetLoginSid,ColumnPermissions,LinkedServerName,ProviderName,MethodName,RowCounts,RequestID,XactSequence,EventSequence,BigintData1,BigintData2,GUID,IntegerData2,ObjectID2,[Type],OwnerID,ParentName,IsSystem,Offset,SourceDatabaseID,SqlHandle,SessionLoginName,PlanHandle
					FROM fn_trace_gettable(@strOutputFile + '.trc', default)
					WHERE	TextData IS NOT NULL
			END TRY
			BEGIN CATCH
				PRINT @strOutputFile + '.trc did not exist'
			END CATCH

			BEGIN TRY
				INSERT	INTO trace.Result (TextData,TextDataOriginal,BinaryData,DatabaseID,TransactionID,LineNumber,NTUserName,NTDomainName,HostName,ClientProcessID,ApplicationName,LoginName,SPID,Duration,StartTime,EndTime,Reads,Writes,CPU,[Permissions],Severity,EventSubClass,ObjectID,Success,IndexID,IntegerData,ServerName,EventClass,ObjectType,NestLevel,State,Error,Mode,Handle,ObjectName,DatabaseName,[FileName],OwnerName,RoleName,TargetUserName,DBUserName,LoginSid,TargetLoginName,TargetLoginSid,ColumnPermissions,LinkedServerName,ProviderName,MethodName,RowCounts,RequestID,XactSequence,EventSequence,BigintData1,BigintData2,GUID,IntegerData2,ObjectID2,[Type],OwnerID,ParentName,IsSystem,Offset,SourceDatabaseID,SqlHandle,SessionLoginName,PlanHandle)
					SELECT Trace.TextdataCleanup(TextData),TextData,BinaryData,DatabaseID,TransactionID,LineNumber,NTUserName,NTDomainName,HostName,ClientProcessID,ApplicationName,LoginName,SPID,Duration,StartTime,EndTime,Reads,Writes,CPU,[Permissions],Severity,EventSubClass,ObjectID,Success,IndexID,IntegerData,ServerName,EventClass,ObjectType,NestLevel,State,Error,Mode,Handle,ObjectName,DatabaseName,[FileName],OwnerName,RoleName,TargetUserName,DBUserName,LoginSid,TargetLoginName,TargetLoginSid,ColumnPermissions,LinkedServerName,ProviderName,MethodName,RowCounts,RequestID,XactSequence,EventSequence,BigintData1,BigintData2,GUID,IntegerData2,ObjectID2,[Type],OwnerID,ParentName,IsSystem,Offset,SourceDatabaseID,SqlHandle,SessionLoginName,PlanHandle
					FROM fn_trace_gettable(@strOutputFile + '_1.trc', default)
					WHERE	TextData IS NOT NULL
			END TRY
			BEGIN CATCH
			END CATCH
			
			BEGIN TRY
				INSERT	INTO trace.Result (TextData,TextDataOriginal,BinaryData,DatabaseID,TransactionID,LineNumber,NTUserName,NTDomainName,HostName,ClientProcessID,ApplicationName,LoginName,SPID,Duration,StartTime,EndTime,Reads,Writes,CPU,[Permissions],Severity,EventSubClass,ObjectID,Success,IndexID,IntegerData,ServerName,EventClass,ObjectType,NestLevel,State,Error,Mode,Handle,ObjectName,DatabaseName,[FileName],OwnerName,RoleName,TargetUserName,DBUserName,LoginSid,TargetLoginName,TargetLoginSid,ColumnPermissions,LinkedServerName,ProviderName,MethodName,RowCounts,RequestID,XactSequence,EventSequence,BigintData1,BigintData2,GUID,IntegerData2,ObjectID2,[Type],OwnerID,ParentName,IsSystem,Offset,SourceDatabaseID,SqlHandle,SessionLoginName,PlanHandle)
					SELECT Trace.TextdataCleanup(TextData),TextData,BinaryData,DatabaseID,TransactionID,LineNumber,NTUserName,NTDomainName,HostName,ClientProcessID,ApplicationName,LoginName,SPID,Duration,StartTime,EndTime,Reads,Writes,CPU,[Permissions],Severity,EventSubClass,ObjectID,Success,IndexID,IntegerData,ServerName,EventClass,ObjectType,NestLevel,State,Error,Mode,Handle,ObjectName,DatabaseName,[FileName],OwnerName,RoleName,TargetUserName,DBUserName,LoginSid,TargetLoginName,TargetLoginSid,ColumnPermissions,LinkedServerName,ProviderName,MethodName,RowCounts,RequestID,XactSequence,EventSequence,BigintData1,BigintData2,GUID,IntegerData2,ObjectID2,[Type],OwnerID,ParentName,IsSystem,Offset,SourceDatabaseID,SqlHandle,SessionLoginName,PlanHandle
					FROM fn_trace_gettable(@strOutputFile + '_1.trc', default)
					WHERE	TextData IS NOT NULL
			END TRY
			BEGIN CATCH
			END CATCH

			FETCH NEXT FROM curTmp
			INTO @strOutputFile
		END
		CLOSE curTmp
		DEALLOCATE curTmp

		SET @dtmStartDate = DATEADD(dd, 1, @dtmStartDate)
	END	
END

GO
PRINT 'Stored Procedure : trace.Import was created'
GO

/*********** Stored procedure : Report ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'Report' AND schema_id = schema_id('trace')) BEGIN
	DROP PROCEDURE trace.Report
	PRINT 'Stored procedure : trace.Report was dropped'
END
GO

CREATE PROCEDURE [trace].[Report]  
 @dtmDateStart DATETIME,  
 @dtmDateStop DATETIME,  
 @intReportTypeId INT,  
 @intMinValue INT,  
 @intMax INT  
AS  
BEGIN  
   
 SET NOCOUNT ON;  
 DECLARE @strDatabaseName VARCHAR(250)  
 DECLARE @strLoginName VARCHAR(250)  
 DECLARE @intNo INT  
 DECLARE @intTraceResultTypeId INT  
  
 DECLARE @tmpTable TABLE (  
  [TraceResultTypeId][int],  
  [TextData][varchar](max),  
  [Query][varchar](max),  
  [NoOfOccurencies][int],  
  [AverageReads][int],  
  [AverageDuration][int],  
  [AverageWrites][int],  
  [AverageCPU][int],
  [Importance][bigint],  
  [DatabaseName][varchar](250),  
  [LoginName][varchar](250)  
 )  
  
    IF @intReportTypeId = 1 BEGIN  
  
   INSERT INTO @tmpTable(TraceResultTypeId, TextData, Query, NoOfOccurencies, AverageReads, AverageDuration, AverageWrites, AverageCPU, Importance, DatabaseName, LoginName)  
   SELECT TraceResultTypeId = 1,  
     TextData = CONVERT(VARCHAR(max), TextData),   
     Query = 'SELECT * FROM trace.Result WHERE TextData = ''' + REPLACE(CONVERT(VARCHAR(max), TextData), '''', '''''') + '''',  
     NoOfOccurencies = COUNT(*),   
     AverageReads = AVG(Reads),  
     AverageDuration = AVG(Duration),  
     AverageWrites = AVG(Writes),  
     AverageCPU = AVG(cpu),
     Importance = CONVERT(BIGINT, COUNT(*)) * CONVERT(BIGINT, AVG(Reads)),
     DatabaseName = sys.databases.name,  
     LoginName  
   FROM trace.Result   
     INNER JOIN sys.databases ON (sys.databases.database_id = trace.Result.DatabaseID)  
   WHERE (@intMinValue = 0 OR Reads > @intMinValue)  
     AND StartTime BETWEEN @dtmDateStart AND @dtmDateStop  
   GROUP BY CONVERT(VARCHAR(max), TextData), sys.databases.name, LoginName  
   ORDER BY Importance DESC  
  
 END ELSE IF @intReportTypeId = 2 BEGIN  
  
   INSERT INTO @tmpTable(TraceResultTypeId, TextData, Query, NoOfOccurencies, AverageReads, AverageDuration, AverageWrites, AverageCPU, Importance, DatabaseName, LoginName)  
   SELECT TraceResultTypeId = 2,  
     TextData = CONVERT(VARCHAR(max), TextData),   
     Query = 'SELECT * FROM trace.Result WHERE TextData = ''' + REPLACE(CONVERT(VARCHAR(max), TextData), '''', '''''') + '''',  
     NoOfOccurencies = COUNT(*),   
     AverageReads = AVG(Reads),  
     AverageDuration = AVG(Duration),  
     AverageWrites = AVG(Writes),  
     AverageCPU = AVG(cpu),
     Importance = CONVERT(BIGINT, COUNT(*)) * CONVERT(BIGINT, AVG(Duration)),  
     DatabaseName = sys.databases.name,  
     LoginName  
   FROM trace.Result    
     INNER JOIN sys.databases ON (sys.databases.database_id = trace.Result.DatabaseID)  
   WHERE (@intMinValue = 0 OR Duration > @intMinValue)  
     AND StartTime BETWEEN @dtmDateStart AND @dtmDateStop  
   GROUP BY CONVERT(VARCHAR(max), TextData), sys.databases.name, LoginName  
   ORDER BY Importance DESC  
  
 END ELSE IF @intReportTypeId = 3 BEGIN  
  
   INSERT INTO @tmpTable(TraceResultTypeId, TextData, Query, NoOfOccurencies, AverageReads, AverageDuration, AverageWrites, AverageCPU, Importance, DatabaseName, LoginName)  
   SELECT TraceResultTypeId = 3,  
     TextData = CONVERT(VARCHAR(max), TextData),   
     Query = 'SELECT * FROM trace.Result WHERE TextData = ''' + REPLACE(CONVERT(VARCHAR(max), TextData), '''', '''''') + '''',  
     NoOfOccurencies = COUNT(*),   
     AverageReads = AVG(Reads),  
     AverageDuration = AVG(Duration),  
     AverageWrites = AVG(Writes),  
     AverageCPU = AVG(cpu),
     Importance = CONVERT(BIGINT, COUNT(*)) * CONVERT(BIGINT, AVG(Writes)),  
     DatabaseName = sys.databases.name,  
     LoginName  
   FROM trace.Result    
     INNER JOIN sys.databases ON (sys.databases.database_id = trace.Result.DatabaseID)  
   WHERE (@intMinValue = 0 OR Writes > @intMinValue)  
     AND StartTime BETWEEN @dtmDateStart AND @dtmDateStop  
   GROUP BY CONVERT(VARCHAR(max), TextData), sys.databases.name, LoginName  
   ORDER BY Importance DESC  
  
 END ELSE IF @intReportTypeId = 4 BEGIN  
  
   INSERT INTO @tmpTable(TraceResultTypeId, TextData, Query, NoOfOccurencies, AverageReads, AverageDuration, AverageWrites, AverageCPU, Importance, DatabaseName, LoginName)  
   SELECT TraceResultTypeId = 4,  
     TextData = CONVERT(VARCHAR(max), TextData),  
     Query = 'SELECT * FROM trace.Result WHERE TextData = ''' + REPLACE(CONVERT(VARCHAR(max), TextData), '''', '''''') + '''',  
     NoOfOccurencies = COUNT(*),   
     AverageReads = AVG(Reads),  
     AverageDuration = AVG(Duration),  
     AverageWrites = AVG(Writes),  
     AverageCPU = AVG(cpu),
     Importance = COUNT(*),  
     DatabaseName = sys.databases.name,  
     LoginName  
   FROM trace.Result    
     INNER JOIN sys.databases ON (sys.databases.database_id = trace.Result.DatabaseID)  
   WHERE StartTime BETWEEN @dtmDateStart AND @dtmDateStop  
   GROUP BY CONVERT(VARCHAR(max), TextData), sys.databases.name, LoginName  
   ORDER BY Importance DESC  
  
  END ELSE IF @intReportTypeId = 5 BEGIN  
  
   INSERT INTO @tmpTable(TraceResultTypeId, TextData, Query, NoOfOccurencies, AverageReads, AverageDuration, AverageWrites, AverageCPU, Importance, DatabaseName, LoginName)  
   SELECT TraceResultTypeId = 5,  
     TextData = CONVERT(VARCHAR(max), TextData),  
     Query = 'SELECT * FROM trace.Result WHERE TextData = ''' + REPLACE(CONVERT(VARCHAR(max), TextData), '''', '''''') + '''',  
     NoOfOccurencies = COUNT(*),   
     AverageReads = AVG(Reads),  
     AverageDuration = AVG(Duration),  
     AverageWrites = AVG(Writes),  
     AverageCPU = AVG(cpu),
     Importance = CONVERT(BIGINT, COUNT(*)) * CONVERT(BIGINT, AVG(cpu)),  
     DatabaseName = sys.databases.name,  
     LoginName  
   FROM trace.Result    
     INNER JOIN sys.databases ON (sys.databases.database_id = trace.Result.DatabaseID)  
   WHERE StartTime BETWEEN @dtmDateStart AND @dtmDateStop  
   GROUP BY CONVERT(VARCHAR(max), TextData), sys.databases.name, LoginName  
   ORDER BY Importance DESC  
 END  
  
 SET ROWCOUNT @intMax  
  
 SELECT *  
 FROM @tmpTable  
 ORDER BY Importance DESC  
  
 SET ROWCOUNT 0  
  
END

GO
PRINT 'Stored Procedure : trace.Report was created'
GO

/*********** Stored procedure : Report ***********/

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'TextdataCleanup' AND schema_id = schema_id('trace')) BEGIN
	DROP FUNCTION trace.TextdataCleanup
	PRINT 'Stored procedure : trace.TextdataCleanup was dropped'
END
GO

CREATE FUNCTION [trace].[TextdataCleanup] 
(
	@strTextdata VARCHAR(max)
)
RETURNS VARCHAR(max)
AS
BEGIN

	DECLARE @strOutput VARCHAR(max)
	DECLARE @intNFound INT
	DECLARE @intStart INT
	DECLARE @intCounter INT
	DECLARE @strCurrent VARCHAR(1)
	DECLARE @strCurrentNext VARCHAR(1)
	DECLARE @strCurrentPrevious VARCHAR(1)
	
	/* REMOVE DOUBLE PLING */
	SET @strOutput = ''
	SET @intStart = 0
	
	SET @intCounter = 1
	
	WHILE @intCounter <= LEN(@strTextdata) BEGIN

		SET @strCurrent = SUBSTRING(@strTextdata, @intCounter, 1)
		SET @strCurrentNext = ''
		SET @strCurrentPrevious = ''
		
		IF @intCounter > 1 BEGIN
			SET @strCurrentPrevious = SUBSTRING(@strTextdata, @intCounter - 1, 1)
		END
		IF LEN(@strTextdata) > @intCounter BEGIN
			SET @strCurrentNext = SUBSTRING(@strTextdata, @intCounter + 1, 1)
		END

		IF @strCurrent = '''' AND @intStart = 0 AND @strCurrentNext = '''' BEGIN	
			SET @intStart = @intCounter
		END ELSE IF @intStart > 0 AND @strCurrent = '''' AND @strCurrentNext = '''' BEGIN
			SET @intStart = 0
			SET @intCounter = @intCounter + 1
		END ELSE IF @intStart = 0 BEGIN
			SET @strOutput = @strOutput + @strCurrent
		END
		SET @intCounter = @intCounter + 1

	END
	
	SET @strTextdata = @strOutput
	
	/* REMOVE PLINGS */
	SET @intCounter = 1
	SET @strOutput = ''
	SET @intNFound = 0

	WHILE @intCounter <= LEN(@strTextdata) BEGIN

		SET @strCurrent = SUBSTRING(@strTextdata, @intCounter, 1)
		SET @strCurrentNext = ''
		SET @strCurrentPrevious = ''
		
		IF @intCounter > 1 BEGIN
			SET @strCurrentPrevious = SUBSTRING(@strTextdata, @intCounter - 1, 1)
		END
		IF LEN(@strTextdata) > @intCounter BEGIN
			SET @strCurrentNext = SUBSTRING(@strTextdata, @intCounter + 1, 1)
		END
		
		IF @strCurrent = '''' AND @strCurrentPrevious = 'N' BEGIN
			SET @intStart = @intCounter
			SET @intNFound = 1
			SET @strOutput = @strOutput + @strCurrent
		END ELSE IF @intStart > 0 AND @strCurrent = '''' AND @intNFound = 1 BEGIN
			SET @intNFound = 0
			SET @intStart = 0
			SET @strOutput = @strOutput + @strCurrent
		END ELSE IF  @intStart = 0 AND @strCurrent = '''' AND @intNFound = 0 BEGIN
			SET @intStart = @intCounter
		END ELSE IF @intStart > 0 AND @strCurrent = '''' AND @intNFound = 0 BEGIN
			SET @intStart = 0
		END ELSE IF (@intNFound = 0 AND @intStart = 0) OR (@intNFound = 1) BEGIN
			SET @strOutput = @strOutput + @strCurrent
		END
		
		SET @intCounter = @intCounter + 1
	END

	SET @strTextdata = @strOutput
	
	/* REMOVE ALL NUMBERS */
	SET @intCounter = 1
	SET @strOutput = ''

	WHILE @intCounter <= LEN(@strTextdata) BEGIN
		SET @strCurrent = SUBSTRING(@strTextdata, @intCounter, 1)
		IF ISNUMERIC(@strCurrent) = 0 OR @strCurrent = ',' BEGIN
			SET @strOutput = @strOutput + @strCurrent
		END
		SET @intCounter = @intCounter + 1
	END

	SET @strTextdata = @strOutput
	
	RETURN @strTextData

END

GO
PRINT 'Stored Procedure : trace.TextdataCleanup was created'
GO