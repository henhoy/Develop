/***********************************************************************************************
**
** Miracle Online, SQL Server script
**
** Collect info regarding SQL Server
**
** How to invoke:
** sqlcmd -S hmh-win2k3\sql2005 -E -w 1400 -h-1 -m5 -i sqlserver.sql -o sqlserver.htm
**
** -S	<server>\<instance> or <instance> (if default instance)
** -E	Connect with OS privilegies alt. -U <user> -P <password>
** -h-1	No headers
** -m1	Suppress warnings like change of database
** -i   Input script (this one)
** -o   Output htm file
**
** Maintained by Henrik Høyer, hmh@miracleas.dk
** 
** SVN tags:
** $Date: 2013-12-04 20:00:39 +0100 (on, 04 dec 2013) $
** $Revision: 486 $
***********************************************************************************************/

set nocount on
SET LOCK_TIMEOUT 10000
set arithabort on
set ansi_warnings on

/*** Set (override) command line parameters ***/

:setvar SQLCMDHEADERS -1
:setvar SQLCMDERRORLEVEL 5
:setvar SQLCMDCOLWIDTH 1400
:setvar SQLCMDMAXVARTYPEWIDTH 3800
--:setvar SQLCMDMAXFIXEDTYPEWIDTH 3500

/*** Create a few helper functions **/

use master
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MO_GetShortName]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
  execute dbo.sp_executesql @statement = N'
    drop function [dbo].[MO_GetShortName]
    '
end
execute dbo.sp_executesql @statement = N'
create function [dbo].[MO_GetShortName] (@input nvarchar(255), @length tinyint = 30)
returns nvarchar(255)
as
begin
  declare @output nvarchar(255)
  set @output = case when len(@input) > @length then ''<a class="substr" title="'' + @input + ''">'' + substring(@input,1,@length) + ''...'' else @input end;
  return (@output);
end;
'
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MO_GetShortFileName]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
  execute dbo.sp_executesql @statement = N'
    drop function [dbo].[MO_GetShortFileName]
    '
end

execute dbo.sp_executesql @statement = N'
create function [dbo].[MO_GetShortFileName] (@input nvarchar(255), @length tinyint = 45)
returns nvarchar(255)
as
begin
  declare @output nvarchar(255)
  set @output = case
                  when len (@input) > @length then
                    ''<a class="substr" title="'' + @input + ''">'' +
                     substring(@input,0,charindex(''\'',@input,4)+1)+ ''..\..'' +
                     reverse(substring(reverse(@input),0,charindex(''\'',reverse(@input))+1)) +
                     ''</a>''
                  else @input
                end;
  return (@output);
end;
'

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MO_ReturnJobTime]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
  execute dbo.sp_executesql @statement = N'
    drop function [dbo].[MO_ReturnJobTime]
    '
end

execute dbo.sp_executesql @statement = N'
create function [dbo].[MO_ReturnJobTime] (@ymd int, @hms int)
returns datetime
as
begin
  declare @timepart char(8), @time char(6), @date char(8);
  set @date = rtrim(cast(@ymd as char));
  set @time = replicate(''0'',6-datalength(rtrim(cast(@hms as char)))) + rtrim(cast(@hms as char));
  set @timepart = substring(@time,1,2) + '':'' + substring(@time,3,2) + '':'' + substring(@time,5,2);
  return cast(@date+'' ''+@timepart as datetime);
end;
'
go 

-- Create lookup table MORLT (MiracleOnlineRuntimeLookupTable)
create table #MORLT (
Name  varchar(50),
Value varchar(100)
)

/* Insert SQL Server check version */
insert into #MORLT values ('sqlserver_check_version','1.5');
/* Insert SQL Server version */
insert into #MORLT select 'sqlserver_version', convert(varchar(2),PARSENAME(CONVERT(VARCHAR(100),SERVERPROPERTY('ProductVersion')),4));
/* Insert default daysback value for latest online check */
insert into #MORLT values ('latest_online_check','20');
/* Insert default minimum value for defragmented pages */
insert into #MORLT values ('min_defrag_pages','2500');
/* Insert default run of index fragmentation scan value */
insert into #MORLT values ('run_defrag_index','YES');
/* Insert default runs of one minute for miniperf collection.*/
insert into #MORLT values ('wait_loop_counter','1');

declare @starttime varchar(40);
select @starttime = convert(varchar,getdate(),120)
insert into #MORLT values ('starttime',@starttime);

-- Create ignore waits table
-- Insert your own ignore waits using sqlserver_config.sql
create table #ignore_waits (wait varchar(100))
insert into #ignore_waits values ('KSOURCE_WAKEUP')
insert into #ignore_waits values ('SLEEP_BPOOL_FLUSH')
insert into #ignore_waits values ('BROKER_TASK_STOP')
insert into #ignore_waits values ('DBMIRRORING_CMD')
insert into #ignore_waits values ('SQLTRACE_INCREMENTAL_FLUSH_SLEEP')
insert into #ignore_waits values ('XE_TIMER_EVENT')
insert into #ignore_waits values ('XE_DISPATCHER_WAIT')
insert into #ignore_waits values ('FT_IFTS_SCHEDULER_IDLE_WAIT')
insert into #ignore_waits values ('SQLTRACE_BUFFER_FLUSH')
insert into #ignore_waits values ('CLR_AUTO_EVENT')
insert into #ignore_waits values ('BROKER_EVENTHANDLER')
insert into #ignore_waits values ('LAZYWRITER_SLEEP')
insert into #ignore_waits values ('BAD_PAGE_PROCESS')
insert into #ignore_waits values ('BROKER_TRANSMITTER')
insert into #ignore_waits values ('CHECKPOINT_QUEUE')
insert into #ignore_waits values ('DBMIRROR_EVENTS_QUEUE')
insert into #ignore_waits values ('LAZYWRITER_SLEEP')
insert into #ignore_waits values ('ONDEMAND_TASK_QUEUE')
insert into #ignore_waits values ('REQUEST_FOR_DEADLOCK_SEARCH')
insert into #ignore_waits values ('LOGMGR_QUEUE')
insert into #ignore_waits values ('SLEEP_TASK')
insert into #ignore_waits values ('SQLTRACE_BUFFER_FLUSH')
insert into #ignore_waits values ('CLR_MANUAL_EVENT')
insert into #ignore_waits values ('BROKER_RECEIVE_WAITFOR')
insert into #ignore_waits values ('PREEMPTIVE_OS_GETPROCADDRESS')
insert into #ignore_waits values ('PREEMPTIVE_OS_AUTHENTICATIONOPS')
insert into #ignore_waits values ('BROKER_TO_FLUSH')
insert into #ignore_waits values ('WAITFOR')
insert into #ignore_waits values ('FT_IFTSHC_MUTEX')

:r sqlserver_config.sql

select '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" ' +
       '"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'

select '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en"> '
select '<head>'
select '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />'
select '<meta name="generator" content="SQL Server Report " />'
select '<style type="text/css"> 
          body {font:10pt Arial,Helvetica,sans-serif; color:black; background:White;} 
          p {font:10pt Arial,Helvetica,sans-serif; color:black; background:White;} 
          p.alignright {text-align:right;}
		  ul.list{ list-style-type:none; }          
          table {width:100%}
          table,tr,td {font:10pt Arial,Helvetica,sans-serif; color:Black; background:#ffffcc; padding:0px 0px 0px 0px; margin:0px 0px 0px 0px; border-style:inset;border-width:1px;} 
		  tr.topiccell { vertical-align:top;  }
          td.ok { background:#33CC66; text-align:center;}
          td.disabledok { text-align:left; }
		  td.highlight { background:#ffff66; }
		  td.caution { background:#ffff66; color:Red; }
          td.warn { background:#ffff66; text-align:center; }
          td.disabledwarn { text-align:left; }
          td.error { background:#cc3300; text-align:center; }
		  td.failed { color:Red }
          td.disablederror { text-align:left; }
          td.alignleft { text-align:left;}
          td.aligncenter {text-align:center;}
          td.alignright {text-align:right;}        
	      td.ignore { background:#999999; text-align:center; }
	      td.disabledignore { text-align:left; }
          td.sumcell { text-align:right; font-weight:bold;}
		  th.width2 { width:"2%"}
          th.width10 { width:"10%"}
		  th.width20 { width:"20%"}
		  th.width40 { width:"40%"}
          th {font:bold 10pt Arial,Helvetica,sans-serif; color:#336699; background:#cccc99; padding:0px 0px 0px 0px; border-style:inset;border-width:1px;} 
          h1 {font:bold 16pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; border-bottom:1px solid #cccc99; margin-top:0pt; margin-bottom:0pt; padding:0px 0px 0px 0px;} 
          h2 {font:bold 10pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; margin-top:4pt; margin-bottom:0pt;} 
          a {font:9pt Arial,Helvetica,sans-serif; color:#663300; background:#ffffcc; margin-top:10pt; margin-bottom:0pt; vertical-align:top;}
          a.substr {font:10pt Arial,Helvetica,sans-serif; color:#0000cc; background:#ffffcc; margin-top:10pt; margin-bottom:0pt; vertical-align:top;}
		  .ah1 {font:bold 14pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; margin-top:50pt; margin-bottom:20pt;}
          .ah2 {font:bold 10pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; margin-top:10pt; margin-bottom:0pt;}
          .center {text-align:center;} 
        </style>
        <title>SQL Server Report for ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</title>'
select '</head>'

select '<body>'
select '<h1>Miracle SQL Server Report for instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</h1><br />' +
--       '<h2> Check executed at: ' + convert(varchar(17), getdate(),13) + '</h2>'
       '<h2> Check executed at: ' +  Value + '</h2>'
from #MORLT where Name = 'starttime';

/*********************************************************************************************/
/* Collecting Latest 60 seconds of activities                                                */
/*                                                                                           */
/*********************************************************************************************/
select   [Spid] = spid, 
         [Thread ID] = kpid, 
         [Status] = convert(varchar(10), status), 
         [LoginName] = convert(varchar(20), loginame), 
         [IO] = physical_io, 
         [CPU] = cpu, 
         [MemUsage] = memusage,
         [HostName]= convert(varchar(20), hostname),
         [program_name],
         [sql_handle]
into #beginprocess
from     [master].[dbo].[sysprocesses] 
where spid > 50
order by CPU desc

create table #my_beg_waitstats
        ([wait_type] nvarchar(60) not null,
		[waiting_tasks_count] bigint not null, 
        [wait_time_ms] bigint not null,
        [signal_wait_time_ms] bigint not null,
        now datetime not null default getdate())
create table #my_beg_otherstats
	    (spid smallint not null,
	    cpu_time bigint,
	    total_scheduled_time int,
	    total_elapsed_time int,
	    reads bigint,
	    writes bigint,
	    logical_reads bigint)

declare @i int,
		@myspid smallint,
        @now datetime
begin
  select @now = getdate()
  select @myspid = @@SPID
  insert into #my_beg_waitstats
              ([wait_type], [waiting_tasks_count], [wait_time_ms], [signal_wait_time_ms], now)	
  select [wait_type], [waiting_tasks_count], [wait_time_ms], [signal_wait_time_ms], @now
  from sys.dm_os_wait_stats

  insert into #my_beg_otherstats
  select session_id,cpu_time, total_scheduled_time, total_elapsed_time,
	     reads,writes, logical_reads 
  from sys.dm_exec_sessions 
  where session_id=@myspid;
end
go

select * 
into #beg_virtual_file_stats
from sys.dm_io_virtual_file_stats(null,null);

select *
into #dopc_begin
from sys.dm_os_performance_counters 
where cntr_type = 272696576
and (object_name like '%SQL Statistics%' or object_name like '%Access Methods%' or object_name like '%Latches%' or (object_name like '%Databases%' and instance_name = '_Total')
  or object_name like '%Buffer Manager%' or object_name like '%General Statistics%' or (object_name like '%Locks%' and instance_name = '_Total'));

-- Then we wait
declare @waittimes int
set @waittimes = (select convert(int,Value) from #MORLT where Name = 'wait_loop_counter');

while @waittimes > 0
begin 
  waitfor DELAY '000:01:00'   -- et minut
  set @waittimes = @waittimes - 1;
end

select *
into #dopc_end
from sys.dm_os_performance_counters 
where cntr_type = 272696576
and (object_name like '%SQL Statistics%' or object_name like '%Access Methods%' or object_name like '%Latches%' or (object_name like '%Databases%' and instance_name = '_Total')
  or object_name like '%Buffer Manager%' or object_name like '%General Statistics%' or (object_name like '%Locks%' and instance_name = '_Total'));

select   [Spid] = spid, 
         [Thread ID] = kpid, 
         [Status] = convert(varchar(10), status), 
         [LoginName] = convert(varchar(20), loginame), 
         [IO] = physical_io, 
         [CPU] = cpu, 
         [MemUsage] = memusage,
         [HostName]= convert(varchar(20), hostname),
         [program_name],
         [sql_handle]
into #endprocess
from     [master].[dbo].[sysprocesses] 
where spid > 50
order by CPU desc

create table #my_end_waitstats
        ([wait_type] nvarchar(60) not null,
		[waiting_tasks_count] bigint not null, 
        [wait_time_ms] bigint not null,
        [signal_wait_time_ms] bigint not null,
        now datetime not null default getdate())
create table #my_end_otherstats
	    (spid smallint not null,
	    cpu_time bigint,
	    total_scheduled_time int,
	    total_elapsed_time int,
	    reads bigint,
	    writes bigint,
	    logical_reads bigint)

declare @i int,
		@myspid smallint,
        @now datetime

begin
  select @now = getdate()
  select @myspid = @@SPID
  insert into #my_end_waitstats
              ([wait_type], [waiting_tasks_count], [wait_time_ms], [signal_wait_time_ms], now)	
  select [wait_type], [waiting_tasks_count], [wait_time_ms], [signal_wait_time_ms], @now
  from sys.dm_os_wait_stats

  insert into #my_end_otherstats
  select session_id,cpu_time, total_scheduled_time, total_elapsed_time,
	     reads,writes, logical_reads 
  from sys.dm_exec_sessions 
  where session_id=@myspid;
end

select * 
into #end_virtual_file_stats
from sys.dm_io_virtual_file_stats(null,null);

select '<p class="alignright"> Miracle Online SQL Server report, version ' + Value + '</p>' from #MORLT where Name = 'sqlserver_check_version';

/*********************************************************************************************/
/* Internal links                                                                            */
/*                                                                                           */
/*********************************************************************************************/
select '<a name="Topic" class="ah2">Topic</a>'
select '<table>'
select '<tr>' +
         '<td><ul class="list" ><li><a href="#InstanceInformation"> Instance Information </a></li></ul></td>' +
		 '<td><ul class="list" ><li><a href="#SQLAgentInfo"> SQL Agent Info </a></li></ul></td>' +
		 '<td><ul class="list" ><li><a href="#RecoveryInfo"> Recovery Information </a></li></ul></td>' + 
		 '<td><ul class="list" ><li><a href="#StorageInfo"> Storage Information </a></li></ul></td>' +
		 '<td><ul class="list" ><li><a href="#ErrorInfo"> Log Information </a></li></ul></td>' +
		 '<td><ul class="list" ><li><a href="#RuntimeInfo"> Runtime Information (databases)</a></li></ul></td>' +		 		 
		 '<td><ul class="list" ><li><a href="#PerfInfo"> Runtime Performance Information </a></li></ul></td>' +		 		 
		 '<td><ul class="list" ><li><a href="#MiscInfo"> Miscellaneous Information </a></li></ul></td>' +
	   '</tr>' +
	   '<tr class="topiccell">' +
		 '<td>' +                  -- Instance Information
           '<ul class="list" >' +
	         '<li><a href="#InstanceProperties"> Instance &amp; License Information </a></li>' +
	         '<li><a href="#InstanceProperties"> Instance Default Information </a></li>' +
			 '<li><a href="#UpTimeInfo"> Instance Runtime Information </a></li>' +
			 '<li><a href="#CPUInfo"> CPU Information </a></li>' +
	       '</ul>' +
         '</td>' +
	     '<td>' +                  -- SQL Agent Info
           '<ul class="list" >' +	   
             '<li><a href="#JobInfo"> Job Information </a></li>' +
             '<li><a href="#SQLAgentlogInfo"> SQL Agentlog information </a></li>' +
           '</ul>' +		 
	     '</td>' +
         '<td>' +                  -- Backup Info
           '<ul class="list" >' +
		     '<li><a href="#BackupInfo">Database Backup Information </a></li>' +
			 '<li><a href="#SuspectPageInfo">Suspect Page(s) information </a></li>' +			 
             '<li><a href="#BackupStatFull">Full backup Statistics </a></li>' +
		     '<li><a href="#BackupStatInc">Incremental backup Statistics </a></li>' +
             '<li><a href="#BackupStatTrans">Transactionlog backup Statistics </a></li>' +
           '</ul>' +
         '</td>' +
         '<td>' +                  -- Storage Info
           '<ul class="list" >' +
		     '<li><a href="#SpaceInfo"> Database space Information </a></li>' +
             '<li><a href="#DetailSpaceInfo"> Databae detail space Information </a></li>' +
			 '<li><a href="#DatabasevsStorageInfo"> Databae size vs Storage information</a></li>' +
		     '<li><a href="#VirLogInfo"> Virtual Log Information </a></li>' +
		   '</ul> ' +
  	     '</td>' +		 
	     '<td>' +                  --  Error Information
           '<ul class="list" >' + 
	  	     '<li><a href="#ErrorlogInfo"> Errorlog Information </a></li>' +
             '<li><a href="#ErrorlogSum"> Errorlog Summering </a></li>' +
		     '<li><a href="#SysTraceInfo"> Trace Information </a></li>' +
		   '</ul>' +
  	     '</td>' + 
	     '<td>' +                  --  Runtime Information Databases  
           '<ul class="list" >' + 
	  	     '<li><a href="#MirroringInfo"> Mirroring Information </a></li>' +
			 '<li><a href="#RebuildIndexes"> Index Fragmentation </a></li>' +
			 '<li><a href="#MissingIndexes"> Missing Index Information </a></li>' +
			 '<li><a href="#IndexUsageInfo"> Index Usage information </a></li>' +
			 '<li><a href="#DatabaseStatistics"> Database Statistics Overview </a></li>' +
		   '</ul>' +
  	     '</td>' + 		 
		 '<td>' +                  --  Runtime Performance Information
           '<ul class="list" >' + 
		     '<li><a href="#DatabaseInformation"> Misc. Database Information</a></li>' +
			 '<li><a href="#PlanCacheInformation"> Plan Cache Information</a></li>' +
		     '<li><a href="#BlockingInfo"> Blocking Information </a></li>' +
			 '<li><a href="#InstanceActivity"> Latest X minutes of Activity </a></li>' +
			 '<li><a href="#Top20AvgIoWaitsNow"> Top 20 IO Waits Information (Currently)</a></li>' +
			 '<li><a href="#Top20AvgIoWaitsAccu"> Top 20 IO Waits Information (Accumulated)</a></li>' +
			 '<li><a href="#Top20WaitsNow"> Top 20 Wait stats Information (Currently)</a></li>' +
			 '<li><a href="#Top20WaitsAccu"> Top 20 Waits stat Information (Accumulated)</a></li>' +		
			 '<li><a href="#AccuPerfCount"> Sampled perf counters</a></li>' +
		   '</ul>' +
  	     '</td>' + 		 
         '<td>' +                  -- Miscellaneous Information
           '<ul class="list" >' + 	   
             '<li><a href="#DatabaseProperties"> Properties for databases </a></li>' +
             '<li><a href="#ConfValues"> Configuration Values </a></li>' +
			'</ul>' +
	     '</td>' +
       '</tr>' +
     '</table>' +
   '<br />'	
  
 
 select '<br /><a name="InstanceInformation" class="ah1">Instance Information:</a><br />'
 
 /*********************************************************************************************/
/* Instance properties and licens information                                                */
/*                                                                                           */
/*********************************************************************************************/
declare @total_buffer int;
declare @page_life_expect int;
declare @current_connections int;
declare @ver int;

select @ver = Value from #MORLT where Name = 'sqlserver_version';
-- When SQL Server version is below (2008) then we ca use "Total Pages"
if @ver <= 10 
begin
  select @total_buffer = cntr_value
  from sys.dm_os_performance_counters 
  where RTRIM([object_name]) like '%Buffer Manager'
  and counter_name = 'Total pages';
end;

-- When SQL Server version is 2012 we need to query other Memory counters in sys.dm_os_performance_counters
if @ver = 11
begin
  select @total_buffer = cntr_value
  from sys.dm_os_performance_counters 
  where RTRIM([object_name]) like '%Memory Manager'
  and counter_name = 'Total Server Memory (KB)';
end;

-- Collect current page life expectancy
select @page_life_expect = cntr_value
from sys.dm_os_performance_counters
where RTRIM([object_name]) like '%Buffer Manager%'
and counter_name = 'Page life expectancy';

-- Collect number of current connections
select @current_connections = (select count(*) from sys.dm_exec_connections);

create table #SYSINF(ID int,  Name  sysname, Internal_Value int, Value nvarchar(512))
insert #SYSINF exec master.dbo.xp_msver

declare @RegPathParams sysname;
declare @Arg sysname;
declare @Param sysname;
declare @MasterPath nvarchar(512);
declare @LogPath nvarchar(512);
declare @n int;
declare @numastat nvarchar(25);

select @n=0
select @RegPathParams=N'Software\Microsoft\MSSQLServer\MSSQLServer'+'\Parameters'
select @Param='dummy'
while(not @Param is null)
begin
  select @Param=null
  select @Arg='SqlArg'+convert(nvarchar,@n)
  exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', @RegPathParams, @Arg, @Param OUTPUT
  if(@Param like '-d%')
    begin
	  select @Param=substring(@Param, 3, 255)
	  select @MasterPath=substring(@Param, 1, len(@Param) - charindex('\', reverse(@Param)))
	end
  else if(@Param like '-l%')
    begin
	  select @Param=substring(@Param, 3, 255)
	  select @LogPath=substring(@Param, 1, len(@Param) - charindex('\', reverse(@Param)))
	end
  select @n=@n+1
end

declare @BackupDirectory nvarchar(512)
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'BackupDirectory', @BackupDirectory OUTPUT

declare @MssqlRoot nvarchar(512)
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\Setup', N'SQLPath', @MssqlRoot OUTPUT

declare @SmoDefaultFile nvarchar(512)
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultData', @SmoDefaultFile OUTPUT
			
declare @SmoDefaultLog nvarchar(512)
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultLog', @SmoDefaultLog OUTPUT

declare @SmoLoginMode int
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', @SmoLoginMode OUTPUT

declare @SmoAuditLevel int
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'AuditLevel', @SmoAuditLevel OUTPUT

SELECT @numastat = 
         case 
           when count( distinct memory_node_id) > 1 then convert(varchar,count( distinct memory_node_id)-1) + ' nodes'
           else 'No Numa or disabled'
         end
FROM sys.dm_os_memory_clerks

select '<a name="InstanceProperties" class="ah2">SQL Server Instance Information for instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
select '<table>'

select '<tr><th>Server \ Instance Name</th><th>Machine Name</th><th>Product Version</th><th>Product Level</th><th>Edition</th><th> Engine Edition</th><th>ResDb. Ver</th><th>Last ResDb. update</th></tr>'
--select '<tr><th>Server \ Instance Name</th><th>Machine Name</th><th>Product Version</th><th>Edition</th><th> Engine Edition</th><th>ResDb. Ver</th><th>Last ResDb. update</th></tr>'
select '<tr>' +
       '<td class="aligncenter" >' + convert(sysname,SERVERPROPERTY('ServerName')) + '</td>' +
       '<td class="aligncenter" >' + convert(sysname,SERVERPROPERTY('ComputerNamePhysicalNetBIOS')) + '</td>' +
--       '<td class="aligncenter" >' + convert(sysname,SERVERPROPERTY('MachineName')) + '</td>' +
       '<td class="aligncenter" >' + SUBSTRING(@@version,0,CHARINDEX('Copyright', @@version)-23) + '</td>' +
---       '<td class="aligncenter" >' + convert(sysname,SERVERPROPERTY('ProductVersion')) + '</td>' +
       '<td class="aligncenter" >' + convert(sysname,SERVERPROPERTY ('ProductLevel')) + '</td>' +
       '<td class="aligncenter" >' + convert(sysname,SERVERPROPERTY ('Edition')) + '</td>' +
       '<td class="aligncenter" >' + convert(sysname,SERVERPROPERTY ('EngineEdition')) + '</td>' +
       '<td class="aligncenter" >' + convert(sysname,SERVERPROPERTY('ResourceVersion')) + '</td>' +
       '<td class="aligncenter" >' + convert(sysname,SERVERPROPERTY('ResourceLastUpdateDateTime')) + '</td>' +      
       '</tr>'
select '</table><br />'

select '<table>'
select '<tr><th>Platform</th><th>OS Version</th><th>Processors</th><th>Numa</th><th>Process ID</th><th>Phys. Mem MB</th><th>Max Mem MB</th><th>Min Mem MB</th><th>Cur. Mem MB</th>' + 
       '<th>Cur. Page life (min)</th><th>Cur. Connections</th></tr>'
select '<tr>' +
       '<td class="aligncenter" >' + (select Value from #SYSINF where Name = N'Platform') + '</td>' +
       '<td class="aligncenter" >' + (select Value from #SYSINF where Name = N'WindowsVersion') + '</td>' +
       '<td class="aligncenter" >' + (select Value from #SYSINF where Name = N'ProcessorCount') + '</td>' +
	   '<td class="aligncenter" >' + @numastat + '</td>' +
       '<td class="aligncenter" >' + convert(sysname,SERVERPROPERTY('ProcessID')) + '</td>' +
       '<td class="aligncenter" >' + (select convert(sysname,Internal_Value) from #SYSINF where Name = N'PhysicalMemory') + '</td>' +
       '<td class="aligncenter" >' + (select convert(sysname,value_in_use) from sys.configurations where name = 'max server memory (MB)') + '</td>' +
       '<td class="aligncenter" >' + (select convert(sysname,value_in_use) from sys.configurations where name = 'min server memory (MB)') + '</td>' +
       '<td class="aligncenter" >' + case
	                                   when @ver = 11 then convert(sysname, @total_buffer/1024)
									   else convert(sysname,@total_buffer*8/1024) 
									 end + '</td>' +
	   '<td class="aligncenter" >' + convert(sysname, @page_life_expect) + '</td>' +
	   '<td class="aligncenter" >' + convert(sysname, @current_connections) + '</td>' +
       '</tr>'
select '</table><br />'

--select '<h2> SQL Server License Information for instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</h2>'
select '<table>'
select '<tr><th>Cluster configuration</th><th>Full Text Installed</th><th>Server Collation</th><th>Auth. Method</th><th>Login Audit Method</th></tr>'
select '<tr>' +
       '<td class="aligncenter" >' +  case
                   when SERVERPROPERTY ('IsClustered') = 0 then 'Not Clustered'
                   when SERVERPROPERTY ('IsClustered') = 1 then 'Clustered'
                 end + '</td>' +
       '<td class="aligncenter" >' +  case
                   when SERVERPROPERTY ('IsFullTextInstalled') = 0 then 'Full-text is not installed'
                   when SERVERPROPERTY ('IsFullTextInstalled') = 1 then 'Full-text installed'
                 end + '</td>' +
       '<td class="aligncenter" >' +  convert(sysname,SERVERPROPERTY ('Collation')) + '</td>' +  
       '<td class="aligncenter" >' +  case
                   when  @SmoLoginMode = 1 then 'Windows Authentication'
                   when  @SmoLoginMode = 2 then 'Mixed Authentication'
                 end + '</td>' +
       '<td class="aligncenter" >' +  case
                   when  @SmoAuditLevel = 0 then 'None'
                   when  @SmoAuditLevel = 1 then 'On Success'
                   when  @SmoAuditLevel = 2 then 'On Failed'
                   when  @SmoAuditLevel = 3 then 'All'
                 end + '</td>' +                 
       '</tr>'
select '</table><br />'
--select '<a href="#Topic"> Back to Topic</a><br />'

select '<table>'
select '<tr><th>Instance Property Path Type</th><th>Path</th></tr>'
select '<tr><td>MSSQL Root Dir</td><td>' + @MssqlRoot + '</td></tr>' +
       '<tr><td>Backup Dir</td><td>' + @BackupDirectory + '</td></tr>' +
       '<tr><td>Default Data Dir</td><td>' + isnull(@SmoDefaultFile,@MasterPath + '(default)') + '</td></tr>' +
       '<tr><td>Default Log Dir</td><td>' + isnull(@SmoDefaultLog,@LogPath + '(default)') + '</td></tr>' 
select '</table><br />'
select '<a href="#Topic"> Back to Topic</a><br />'


drop table #SYSINF

/*********************************************************************************************/
/* Show Server and Instance uptime information                                               */
/*                                                                                           */
/*                                                                                           */
/*********************************************************************************************/
select '<a name="UpTimeInfo" class="ah2">SQL Server Uptime information for instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
select '<table>'
select '<tr><th>Server Startup Time</th><th>Server Uptime (days)</th><th>SQL Server Startup Time</th><th>SQL Server Uptime (days)</th></tr>'
select '<tr>'
select '<td align="center">' + convert(char, dm_sys.ServerStartupTime) + '</td><td align="center">' + convert(char, datediff(d, dm_sys.ServerStartupTime, getdate()))  + '</td>'+  
       '<td align="center">' +convert(char, SQLInf.SQLServerStartupTime)  + '</td><td align="center">' +  convert(char, datediff(d, SQLInf.SQLServerStartupTime, getdate())) + '</td>'
from (select dateadd(s, 1 - ms_ticks/1000, getdate()) as ServerStartupTime from sys.dm_os_sys_info) as dm_sys,
     (select create_date as SQLServerStartupTime 
      from sys.databases
      where name = 'tempdb') as SQLInf
select '</tr>'
select '</table>'
select '<a href="#Topic"> Back to Topic</a><br />'
go


/*********************************************************************************************/
/* Show CPU Utilization for the last n minutes                                               */
/*                                                                                           */
/*                                                                                           */
/*********************************************************************************************/
set QUOTED_IDENTIFIER on

declare @ts_now bigint
declare @ver int
declare @sql nvarchar(200)

select @ver = Value from #MORLT where Name = 'sqlserver_version';
-- When SQL Server version is 9 (2005) then use cpu_ticks / cpu_ticks_in_ms
if @ver = 9 
begin
  set @sql = N'select @ts_now = cpu_ticks / convert(float, cpu_ticks_in_ms) from sys.dm_os_sys_info;'
  exec sp_executesql @query = @sql, @params = N'@ts_now bigint output', @ts_now = @ts_now OUTPUT
end
-- When SQL Server version is 10 (2008) then use ms_ticks
if @ver >= 10
begin
  select @ts_now = ms_ticks from sys.dm_os_sys_info;
end

;with CPUINFO ( cputime, maxsql, minsql, avgsql, maxidle, minidle, avgidle, maxother, minother, avgother)
as (
select datediff(mi,
	            min(dateadd(ms, -1 * (@ts_now - [timestamp]), GetDate()) ), 
                max(dateadd(ms, -1 * (@ts_now - [timestamp]), GetDate()) ) ) as cputime, 
	max(SQLProcessUtilization) as maxsql,
	min(SQLProcessUtilization) as minsql,
	avg(SQLProcessUtilization) as avgsql,
	max(SystemIdle) as maxidle,
	min(SystemIdle) as minidle,
	avg(SystemIdle) as avgidle,
    max(100 - SystemIdle - SQLProcessUtilization) as maxother,	
    min(100 - SystemIdle - SQLProcessUtilization) as minother,
    avg(100 - SystemIdle - SQLProcessUtilization) as avgother
from (
	select 
		--record.value('(./Record/@id)[1]', 'int') as record_id,
		record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') as SystemIdle,
		record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') as SQLProcessUtilization,
		timestamp
	from (
		select timestamp, convert(xml, record) as record 
        from sys.dm_os_ring_buffers 
		where ring_buffer_type = 'RING_BUFFER_SCHEDULER_MONITOR'
		and record like '%<SystemHealth>%') as x
	) as y
)

-- Special internal link - select from CPUINFO ! - ONLY REUSE WITH CARE !!
select '<a name="CPUInfo" class="ah2">CPU Utilization for the last ' + rtrim(convert(char, cputime)) + ' minutes for instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</a>' +
       '<table>' +
       '<tr><th> </th><th>Minimum CPU</th><th>maximum CPU</th><th>Average CPU</th></tr>' +
       '<tr><td>SQL Process Utilization</td><td align="center">' + convert(char, minsql) + '</td><td align="center">' + convert(char, maxsql) + '</td><td align="center">' + convert(char, avgsql) + '</td></tr>' +
       '<tr><td>Other Process Utilization</td><td align="center">' + convert(char, minother) + '</td><td align="center">' + convert(char, maxother) + '</td><td align="center">' + convert(char, avgother) + '</td></tr>' +
       '<tr><td>System Idle</td><td align="center">' + convert(char, minidle) + '</td><td align="center">' + convert(char, maxidle) + '</td><td align="center">' + convert(char, avgidle) + '</td></tr>'
from CPUINFO
go
select '</table>'



select '<a href="#Topic"> Back to Topic</a><br />'
go

select '<br /><a name="SQLAgentInfo" class="ah1">SQL Agent Information:</a><br />'
/*********************************************************************************************/
/* Collect job information                                                                   */
/*                                                                                           */
/*                                                                                           */
/*********************************************************************************************/
use msdb
go

select '<a name="JobInfo" class="ah2">Enabled Jobs @ SQL Server Agent for database instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
select '<table>'
select '<tr><th>Job Name</th><th>Job status</th><th>Last runtime</th><th>Last result</th><th>Overall (%)</th><th>Next runtime</th></tr>'

select '<tr>' +
       '<td>' + rtrim(sj.name) + '</td>' +
       '<td>' + case 
                  when sj.enabled = 0 then 'Not Enabled'
                  when sj.enabled = 1 then 'Enabled'
                end + '</td>' + 
       '<td class="aligncenter" >' + case
                  when sjs.last_run_date is null then 'No Run'
				  when sjs.last_run_date = 0 then 'No Run'
                   else convert(varchar(17),master.dbo.MO_ReturnJobTime(last_run_date, last_run_time), 13)
                end + '</td>' +
       '<td' + case 
                  when sjs.last_run_outcome = 0 then ' class="failed" >Failed'
                  when sjs.last_run_outcome = 1 then '>Successfull'
                  when sjs.last_run_outcome = 3 then '>Canceled'
                  else '>Undefined outcome'
                end + '</td>' +
       '<td' + case  -- Special <td> !!
                  when sjrs.Success_Pct > 95 then ' class="ok">' + convert(char(3),sjrs.Success_Pct)
                  when sjrs.Success_Pct <= 95 and sjrs.Success_Pct >= 50 then ' class="warn">' + convert(char(2),sjrs.Success_Pct)
                  when sjrs.Success_Pct < 50 then ' class="error">' + convert(char(2),sjrs.Success_Pct)
                  else ' class="ignore">No History '
                end + 
                ' (' + isnull(convert(varchar(3),sjrs.failed_runs),'') + ' of ' + isnull(convert(varchar(3),sjrs.total_runs),'') + ' failed)' + '</td>' +  
       '<td' + case -- Special <td> !!
                  when sjsch.next_run_date is null then ' class="aligncenter" >No Schedule'
				  when sjsch.next_run_date = 0 then ' class="aligncenter" >No Schedule'
				  else
                    case
                      when (master.dbo.MO_ReturnJobTime(next_run_date, next_run_time) - getdate()+0.02 < 0) -- Adding app. 30 min for update of sysjobhistry
					  then ' class="warn" >'
					  else ' class="aligncenter" >'
					end + 
				    convert(varchar(17),master.dbo.MO_ReturnJobTime(next_run_date, next_run_time), 13)
                end + '</td>' +
       '</tr>'
from dbo.sysjobs sj 
left outer join dbo.sysjobservers sjs
  on sj.job_id = sjs.job_id 
left outer join dbo.sysjobschedules sjsch
  on sj.job_id = sjsch.job_id
left outer join (select tjr.job_id, tjr.total_runs, case when fjr.failed_runs is null then 0 else fjr.failed_runs end as failed_runs,
                   ((tjr.total_runs - case when fjr.failed_runs is null then 0 else fjr.failed_runs end) * 100) / tjr.total_runs Success_Pct
            from (select job_id, count(*) total_runs
                  from dbo.sysjobhistory
                  group by job_id) tjr
                  left outer join
                  (select job_id, count(*) failed_runs
                  from dbo.sysjobhistory
                  where run_status = 0
                  group by job_id) fjr
                  on tjr.job_id = fjr.job_id ) sjrs  -- sys_job_run_success
  on sj.job_id = sjrs.job_id
where sj.enabled = 1
order by sj.name
go
select '</table>'
go
select '<a name="JobInfo" class="ah2">Disabled Jobs  @ SQL Server Agent for database instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
select '<table>'
select '<tr><th>Job Name - (Disableds jobs only)</th><th>Job status</th><th>Last runtime</th><th>Last result</th><th>Overall (%)</th><th>Next runtime</th></tr>'

select '<tr>' +
       '<td>' + rtrim(sj.name) + '</td>' +
       '<td>' + case 
                  when sj.enabled = 0 then 'Not Enabled'
                  when sj.enabled = 1 then 'Enabled'
                end + '</td>' + 
       '<td>' + case
                  when sjs.last_run_date is null then 'No Run'
				  when sjs.last_run_date = 0 then 'No Run'
                  else convert(varchar(17),master.dbo.MO_ReturnJobTime(last_run_date, last_run_time), 13)
                end + '</td>' +
       '<td>' + case 
                  when sjs.last_run_outcome = 0 then 'Failed'
                  when sjs.last_run_outcome = 1 then 'Successfull'
                  when sjs.last_run_outcome = 3 then 'Canceled'
                  else 'Undefined outcome'
                end + '</td>' +
       '<td' + case  -- Special <td> !!
                  when sjrs.Success_Pct > 95 then ' class="disabledok">' + convert(char(3),sjrs.Success_Pct)
                  when sjrs.Success_Pct <= 95 and sjrs.Success_Pct >= 50 then ' class="disabledwarn">' + convert(char(2),sjrs.Success_Pct)
                  when sjrs.Success_Pct < 50 then ' class="disablederror">' + convert(char(2),sjrs.Success_Pct)
                  else ' class="disabledignore">No History '
                end + 
                ' (' + isnull(convert(varchar(3),sjrs.failed_runs),'') + ' of ' + isnull(convert(varchar(3),sjrs.total_runs),'') + ' failed)' + '</td>' +  
       '<td>' + case
                  when sjsch.next_run_date is null then ' No Schedule'
				  when sjsch.next_run_date = 0 then ' No Schedule'
                  else convert(varchar(17),master.dbo.MO_ReturnJobTime(next_run_date, next_run_time), 13)
                end + '</td>' +
       '</tr>'
from dbo.sysjobs sj 
left outer join dbo.sysjobservers sjs
  on sj.job_id = sjs.job_id 
left outer join dbo.sysjobschedules sjsch
  on sj.job_id = sjsch.job_id
left outer join (select tjr.job_id, tjr.total_runs, case when fjr.failed_runs is null then 0 else fjr.failed_runs end as failed_runs,
                   ((tjr.total_runs - case when fjr.failed_runs is null then 0 else fjr.failed_runs end) * 100) / tjr.total_runs Success_Pct
            from (select job_id, count(*) total_runs
                  from dbo.sysjobhistory
                  group by job_id) tjr
                  left outer join
                  (select job_id, count(*) failed_runs
                  from dbo.sysjobhistory
                  where run_status = 0
                  group by job_id) fjr
                  on tjr.job_id = fjr.job_id ) sjrs  -- sys_job_run_success
  on sj.job_id = sjrs.job_id
where sj.enabled = 0
order by sj.name
go
select '</table>'
go
select '<a href="#Topic"> Back to Topic</a><br />'


/*********************************************************************************************/
/* Show SQL Agentlog information                                                                      */
/*                                                                                           */
/*********************************************************************************************/

declare @archno tinyint
declare @count tinyint
declare @latest_online_check datetime
declare @NumAgentLogs int
declare @LogDate datetime
declare @AgentLog nvarchar(255)

-- set @latest_online_check = (select latest_online_check from [miracle_online].[dbo].[Miracle_Online_Info])
set @latest_online_check = getdate() - (select convert(int,Value) from #MORLT where Name = 'latest_online_check')

create table #tbl_enumagentlogs (ArchiveNo int, CreateDate datetime, Size int)
insert into #tbl_enumagentlogs EXEC master.dbo.xp_enumerrorlogs 2 

select @LogDate = case
         when @latest_online_check < min(CreateDate) then min(CreateDate)
         else (select max(CreateDate) from #tbl_enumagentlogs where CreateDate < @latest_online_check)
       end
from #tbl_enumagentlogs

-- Count number of SQL Agent logs
select @NumAgentLogs = (select count(*) from #tbl_enumagentlogs)

set @archno = (select min(ArchiveNo) from #tbl_enumagentlogs where CreateDate <= @LogDate)

create table #Mir_Col_Agentlog (LogDate datetime, ErrorLevel nvarchar(3), ErrorText nvarchar(800))
set @count = 0
while @count < @archno
begin
  insert into #Mir_Col_Agentlog EXEC master.dbo.xp_readerrorlog @count, 2, NULL, NULL, NULL, NULL, N'desc'
  set @count = @count + 1
end

execute master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'ErrorLogFile', @AgentLog OUTPUT, N'no_output'

-- Output section  
select '<a name="SQLAgentlogInfo" class="ah2">SQL Agent log info for database instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'

-- Table with basic agentlog information
select '<table>'
select '<tr><th>Path to SQL Agent log</th><th>Number if logs</th></tr>'
select '<tr><td>' + @AgentLog + '</td><td  align="center">' + convert(sysname, ISNULL(@NumAgentLogs, -1)) + '</td></tr>'
select '</table>'

update #Mir_Col_Agentlog  set LogDate = convert(datetime,convert(varchar, LogDate, 120),120)

select '<table>'
select '<tr><th>Log Date</th><th>Error Level : Error Text - (Information messages "Level 3" is filtered out)</th></tr>'

;with error (LogDate, no, errortext) as (
select O.LogDate as LogDate, count(*) no
       ,STUFF((
         select '  Level ' + [ErrorLevel] + ': ' + [ErrorText] + '<br />'
         from #Mir_Col_Agentlog
         where (LogDate = O.LogDate)
		 and LogDate > @latest_online_check
		 and ErrorLevel < 3
		 order by LogDate
         for xml path (''), TYPE ).value('.','VARCHAR(MAX)') , 1, 2, '') as NM
     /* Use .value to uncomment XML entities e.g. &gt; &lt; etc*/
from #Mir_Col_Agentlog O
group by O.LogDate
)
select '<tr>' + 
       '<td>' + convert(char, LogDate, 13) + '</td>' +
       '<td>' + errortext + '</td>' +
       '</tr>'
from error
where errortext is not null
order by LogDate;
--
select '</table>'

select '<a href="#Topic"> Back to Topic</a><br />'

-- update [miracle_online].[dbo].[Miracle_Online_Info] set Latest_Online_Check = getdate ()

select '<br /><a name="RecoveryInfo" class="ah1">Recovery Information:</a><br />'
/*********************************************************************************************/
/* Collect backup information                                                                */
/*                                                                                           */
/*                                                                                           */
/*********************************************************************************************/
select '<a name="BackupInfo" class="ah2">Latest backup info for database instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'

create table #temp (
      Id INT IDENTITY(1,1),
      ParentObject VARCHAR(255),
      [Object] VARCHAR(255),
      Field VARCHAR(255),
      [Value] VARCHAR(255)
)

create table #temp2 (
  DatabaseName varchar(255),
  LastRanDBCCCHECKDB varchar(255)
)

INSERT INTO #temp
EXECUTE sp_MSforeachdb  'DBCC DBINFO ( ''?'') WITH TABLERESULTS';
;WITH CHECKDB1 AS
        (SELECT Value,ROW_NUMBER() OVER (ORDER BY Id) AS rn1 FROM #temp WHERE Field IN ('dbi_dbname')),
      CHECKDB2 AS 
        (SELECT Value, ROW_NUMBER() OVER (ORDER BY Id) AS rn2 FROM #temp WHERE Field IN ('dbi_dbccLastKnownGood'))
insert into #temp2
SELECT CHECKDB1.Value AS DatabaseName, CHECKDB2.Value AS LastRanDBCCCHECKDB
FROM CHECKDB1 JOIN CHECKDB2
ON rn1 =rn2;

select '<table>'
go
select '<tr><th>Database Name</th><th>Created</th><th>Recovery Model</th><th>Status</th><th>Latest db backup</th><th>Latest Inc backup</th><th>Latest log backup</th><th>Log Reuse Wait</th><th>Latest CheckDb</th></tr>'


select '<tr>' +
       '<td>' + c.name + '</td>' + 
       '<td>' + convert(char(8), c.create_date,3) + '</td>' +
       '<td align="left">' + convert(sysname,DatabasePropertyEX(c.name,'Recovery')) + '</td>' +
       '<td align="left">' + convert(sysname,DatabasePropertyEX(c.name,'Status')) + '</td>' +
       '<td align="left">' + 
                case 
                  when a.latest_db_backup IS NULL then '<font color="#FF0000">No Backup</font>' 
                  else convert(char, a.latest_db_backup, 13) 
                end + '</td>' +
       '<td align="left">' + 
                case 
                  when d.latest_db_backup IS NULL then 'No Inc. Backup' 
                  else convert(char, d.latest_db_backup, 13) 
                end + '</td>' +
       '<td align="left">' + 
                case 
                  when b.latest_log_backup IS NULL -- DB_option=FULL, log_bck=never and database is not model
                    AND convert(sysname,DatabasePropertyEX(c.name,'Recovery')) = 'FULL' AND c.name != 'model' then '<font color="#FF0000">No Backup</font>' 
				  when b.latest_log_backup IS NULL -- DB_option=FULL, log_bck=never and database is model
                    AND convert(sysname,DatabasePropertyEX(c.name,'Recovery')) = 'FULL' AND c.name = 'model' then '<font>No Backup</font>' 
                  when b.latest_log_backup IS NULL -- DB_option=SIMPLE, log_bck=never
                    AND convert(sysname,DatabasePropertyEX(c.name,'Recovery')) = 'SIMPLE'  then 'Not Applicable' 
                  when b.latest_log_backup IS NULL -- DB_option=BULK_LOGGED, log_bck=never
                    AND convert(sysname,DatabasePropertyEX(c.name,'Recovery')) = 'BULK_LOGGED'  then '<font color="#FF0000">WARNING BULK-LOGGED!</font>' 
                  else convert(char, b.latest_log_backup, 13) 
                end + '</td>' +
       '<td>' + convert(sysname,c.log_reuse_wait_desc collate database_default) + '</td>' + 
	   '<td ' + case when datediff(MONTH, LastRanDBCCCHECKDB,GETDATE()) > 2 then ' class="failed" >' else '>' end +
	            convert(varchar(10),LastRanDBCCCHECKDB) + '</td>' +
       '</tr>'
from  ((select server_name, database_name, max(backup_finish_date) latest_db_backup
        from backupset where type = 'D' and server_name = convert(sysname,SERVERPROPERTY('ServerName')) 
        group by server_name, database_name) as a
      full outer join
       (select server_name, database_name, max(backup_finish_date) latest_db_backup
        from backupset where type = 'I' and server_name = convert(sysname,SERVERPROPERTY('ServerName')) 
        group by server_name, database_name) as d
      on (a.database_name = d.database_name)
      full outer join 
       (select server_name, database_name, max(backup_finish_date) latest_log_backup
        from backupset where type = 'L' and server_name = convert(sysname,SERVERPROPERTY('ServerName'))
        group by server_name, database_name)as b
      on (a.database_name = b.database_name))
	  --right outer join #temp2 t2
	  --on (a.database_name = t2.DatabaseName)
      right outer join
       master.sys.databases c
      on a.database_name = c.name
	  join #temp2 t2
	  on c.name = t2.DatabaseName
where lower(c.name) != 'tempdb'
order by c.name
go

select '</table>'
go
select '<a href="#Topic"> Back to Topic</a><br />'

/*********************************************************************************************/
/* Collect backup information                                                                */
/*                                                                                           */
/*                                                                                           */
/*********************************************************************************************/
create table #backupinfo( 
id int IDENTITY(1,1) primary key clustered, 
b_type char(1), 
bf_date char(11),
db_name varchar(200),
parent_id int null)

-- Insert "parent" rows in table
insert into #backupinfo 
  select distinct type, convert(varchar(11),max(backup_finish_date),106), null, null backup_finish_date 
  from backupset bs
  right outer join
  master.dbo.sysdatabases sd
    on bs.database_name = sd.name
  where  bs.server_name = convert(sysname,SERVERPROPERTY('ServerName'))
  group by bs.database_name, type
  order by type, backup_finish_date

-- Insert actual backup info
insert into #backupinfo
select bs.type, bs.backup_finish_date, bs.database_name, id
from (select type, convert(varchar(11),max(backup_finish_date),106) backup_finish_date, database_name 
      from backupset
      group by type, database_name ) bs
  inner join
  #backupinfo bf
    on type = b_type and backup_finish_date = bf_date

declare backup_info cursor for
  select id, b_type, bf_date
  from #backupinfo 
  where db_name is null and parent_id is null
  order by b_type, bf_date desc
declare @backupinfo varchar(4000)
declare @id int
declare @b_type char(1)
declare @bf_date char(11)

open backup_info
fetch backup_info into @id, @b_type, @bf_date

select '<table>' + '<tr><th>Backup info</th></tr>' + '<tr><td>'

while @@fetch_status >= 0
begin
  select @backupinfo = null
  select @backupinfo = isnull(@backupinfo + ', ', '') + [db_name]
  from #backupinfo
  where parent_id = @id  
  select @backupinfo = 'Latest ' + case 
                                     when (@b_type = 'D') then 'full'
                                     when (@b_type = 'I') then 'incremental'
                                     when (@b_type = 'L') then 'transaction log'
                                   end
                                 + ' backup finished at ' + @bf_date + ' for the following databases: ' + '<br />- ' + @backupinfo + '<br />'
  select  @backupinfo 
  fetch backup_info into @id, @b_type, @bf_date
end
select '</td></tr>' + '</table>';

deallocate backup_info
select '<a href="#Topic"> Back to Topic</a><br />'

/*********************************************************************************************/
/* Collect information about suspect pages.                                                  */
/*                                                                                           */
/*********************************************************************************************/
select '<a name="SuspectPageInfo" class="ah2">Suspect page info for SQL Server instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
select '<table>'
select '<tr><th class="width40" >Database Name</th><th class="width10" >File ID</th><th class="width10" >Page ID</th>' +
       '<th class="width10" >Event Type</th><th class="width10" >Error Count</th><th class="width40" >Last Update</th></tr>'
select '<tr>' +
       '<td>' + DB_NAME(database_id) + '</td>' +
	   '<td>' + convert(varchar, file_id) + '</td>' +
	   '<td>' + convert(varchar, page_id) + '</td>' +
	   '<td>' + case
	              when (event_type = 1) then '<font color="#FF0000">OS CRC error</font>'
				  when (event_type = 2) then '<font color="#FF0000">Bad Checksum</font>'
				  when (event_type = 3) then '<font color="#FF0000">Torn Page error</font>'
				  else 'Page Fixed'
			    end + '</td>' +
	   '<td>' + convert(varchar, error_count) + '</td>' +
	   '<td>' + convert(varchar, last_update_date,113) + '</td></tr>'
from msdb..suspect_pages;
	   
select '</table>'
select '<a href="#Topic"> Back to Topic</a><br />'

/*********************************************************************************************/
/* Collect backup Statistics information for full, incremental & transaction backup's        */
/*                                                                                           */
/*                                                                                           */
/*********************************************************************************************/

create table #bckloop ( n int, bck_type char, anchor_name varchar(30), description varchar(100));

insert into #bckloop values (1, 'D', '"BackupStatFull"', 'Full backup statistics for the periode ');
insert into #bckloop values (2, 'I', '"BackupStatInc"', 'Incremental backup statistics for the periode ');
insert into #bckloop values (3, 'L', '"BackupStatTrans"', 'Transaction log backup statistics for the periode ');

declare @bck_type char;
declare @a_name varchar(30);
declare @description varchar(100);

declare f_bckloop cursor for
select bck_type, anchor_name, description
from  #bckloop
order by n;

open f_bckloop;

FETCH f_bckloop into @bck_type, @a_name, @description;

WHILE (@@FETCH_STATUS = 0)
begin
  select '<a name='+@a_name+' class="ah2">'+@description+'"'+convert(char, getdate()-30,3)+'" to "'+convert(char, getdate(),3)+'" for instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
  select '<table>'

  select '<tr><th class="width20" >Database Name</th>' +
  --select '<tr><th "width=20%" >Database Name</th>' +
         '<th>'+convert(char(2), getdate()-30,3)+'</th><th>'+convert(char(2), getdate()-29,3)+'</th><th>'+convert(char(2), getdate()-28,3)+'</th>'+
         '<th>'+convert(char(2), getdate()-27,3)+'</th><th>'+convert(char(2), getdate()-26,3)+'</th><th>'+convert(char(2), getdate()-25,3)+'</th>'+
         '<th>'+convert(char(2), getdate()-24,3)+'</th><th>'+convert(char(2), getdate()-23,3)+'</th><th>'+convert(char(2), getdate()-22,3)+'</th>'+
         '<th>'+convert(char(2), getdate()-21,3)+'</th><th>'+convert(char(2), getdate()-20,3)+'</th><th>'+convert(char(2), getdate()-19,3)+'</th>'+
         '<th>'+convert(char(2), getdate()-18,3)+'</th><th>'+convert(char(2), getdate()-17,3)+'</th><th>'+convert(char(2), getdate()-16,3)+'</th>'+
         '<th>'+convert(char(2), getdate()-15,3)+'</th><th>'+convert(char(2), getdate()-14,3)+'</th><th>'+convert(char(2), getdate()-13,3)+'</th>'+
         '<th>'+convert(char(2), getdate()-12,3)+'</th><th>'+convert(char(2), getdate()-11,3)+'</th><th>'+convert(char(2), getdate()-10,3)+'</th>'+
         '<th>'+convert(char(2), getdate()-9,3)+'</th><th>'+convert(char(2), getdate()-8,3)+'</th><th>'+convert(char(2), getdate()-7,3)+'</th>'+
         '<th>'+convert(char(2), getdate()-6,3)+'</th><th>'+convert(char(2), getdate()-5,3)+'</th><th>'+convert(char(2), getdate()-4,3)+'</th>'+
         '<th>'+convert(char(2), getdate()-3,3)+'</th><th>'+convert(char(2), getdate()-2,3)+'</th><th>'+convert(char(2), getdate()-1, 3)+'</th>'+
         '<th>'+convert(char(2), getdate(), 3)+'</th></tr>'

  select '<tr><td>' + [master].[dbo].[MO_GetShortName] (database_name, 25) + '</td>' + 
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-30, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-29, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-28, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-27, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-26, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-25, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-24, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-23, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-22, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-21, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-20, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-19, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-18, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-17, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-16, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-15, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-14, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-13, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-12, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-11, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-10, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-9, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-8, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-7, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-6, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-5, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-4, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-3, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-2, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-1, 10) then 1 else 0 end )) + '</td>' +
         '<td>' + convert(char(3),sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate(), 10) then 1 else 0 end )) + '</td></tr>'
  from msdb.dbo.backupset
  where type = @bck_type
  and backup_finish_date > getdate()-31
  group by database_name;
  
  select '</table>'

  select '<a href="#Topic"> Back to Topic</a><br />'

  FETCH f_bckloop into @bck_type, @a_name, @description;
end;

CLOSE f_bckloop;

DEALLOCATE f_bckloop;

drop table #bckloop;


select '<br /><a name="StorageInfo" class="ah1">Storage Information:</a><br />'

/*********************************************************************************************/
/* Collect database total space information                                                  */
/*                                                                                           */
/*********************************************************************************************/
declare @dbname               nvarchar(100)
declare @dbid                 int
declare @exec_stmt            varchar(1600)
declare @state_desc           nvarchar(60)
 
create table #space_info
(
  DatabaseName                varchar(100) null,
  state_desc                  nvarchar(60) null,
  FileGroupName               varchar(120) null,
  Name                        varchar(120) null,
  FileName                    varchar(250) null,
  SizeKB                      dec(15) null,
  UsedKB                      dec(15) null,
  FreeKB                      dec(15) null,
  MaxSizeKB                   dec(15) null,
  PctFree                     dec(15) null,
  Status                      int null,
  Growth                      int null
)

create table #drivefreespace (drive varchar(20), mbfree bigint);
insert #drivefreespace  exec master..xp_fixeddrives;

declare dbname_crr cursor for 
  select name, state_desc, database_id from master.sys.databases;

open dbname_crr
fetch dbname_crr into @dbname, @state_desc, @dbid

while @@fetch_status >= 0
begin
--  if convert(sysname,DatabasePropertyEX(@name,'Status')) != 'OFFLINE'
    if  @state_desc = 'ONLINE'
    begin
      set @exec_stmt = 'use ' + quotename(@dbname, N'[') +
        'insert into #space_info (DatabaseName, state_desc, FileGroupName, Name, FileName, SizeKB, UsedKB, FreeKB, MaxSizeKB, PctFree, Status, Growth) ' +
        'select ''' + @dbname + ''',''' + @state_desc + ''', fg.groupname, f.name, f.filename, f.size*8 , fileproperty(name, ''spaceused'')*8,
           f.size*8 - fileproperty(name, ''spaceused'')*8,
           maxsize,
           100 - (fileproperty(name, ''spaceused'')*8) / (cast(size as decimal(15))*8) * 100,
           f.Status, f.Growth
        from sysfiles as f
        left outer join sysfilegroups as fg  
        on f.groupid = fg.groupid'
      --select @exec_stmt
      execute (@exec_stmt)
    end
  else
    begin
      insert into #space_info values (@dbname, @state_desc, 'DB OFFLINE', 'Unknown', 0, 0, 0, 0, 0, 0, 0, 0)
    end
  
  fetch dbname_crr into @dbname, @state_desc, @dbid
end

deallocate dbname_crr

select '<a name="SpaceInfo" class="ah2">Database space info for SQL Server instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
select '<table>'
select '<tr><th class="width40" >System Database Name</th><th class="width10" >Status</th><th class="width10" >Datafile Size MB</th>' +
       '<th class="width10" >Datafile Free MB</th><th class="width10" >Logfile Size MB</th><th class="width10" >Logfile Free MB</th><th class="width10" >Total Size MB</th>'
-- Query out system databases 
select '<tr><td>' + [master].[dbo].[MO_GetShortName] (DatabaseName, 65) +'</td>' +
       '<td class="alignleft" >' + state_desc + '</td>' + 
       '<td class="alignright" >' + RTRIM(cast(cast( 
  	                sum(case
                      when FileGroupName is not null then SizeKB
                      else 0
                    end)/1024 as decimal(10,2)) as char)) + '</td>' +
       '<td class="alignright" >' + RTRIM(cast(cast( 
  	                sum(case
                      when FileGroupName is not null then FreeKB
                      else 0
                    end)/1024 as decimal(10,2)) as char)) + '</td>' +					
       '<td class="alignright" >' + RTRIM(cast(cast( 
  	                sum(case
                      when FileGroupName is null then SizeKB
                      else 0
                    end)/1024 as decimal(10,2)) as char)) + '</td>' +
       '<td class="alignright" >' + RTRIM(cast(cast( 
  	                sum(case
                      when FileGroupName is null then FreeKB
                      else 0
                    end)/1024 as decimal(10,2)) as char)) + '</td>' +
       '<td class="alignright" >' + RTRIM(cast(cast(sum(SizeKB)/1024 as decimal(10,2)) as char)) + '</td>' +
	   '</tr>'
from #space_info
where DatabaseName in ('master','msdb','model','tempdb')
group by DatabaseName, state_desc
order by DatabaseName;
-- Query out user databases
select '<tr><th>User Database Name</th>' --<td></td><td></td><td></td><td></td><td></td><td></td>'
select '<tr><td>' + [master].[dbo].[MO_GetShortName] (DatabaseName, 35) +'</td>' +
       '<td class="alignleft" >' + state_desc + '</td>' + 
       '<td class="alignright" >' + RTRIM(cast(cast( 
  	                sum(case
                      when FileGroupName is not null then SizeKB
                      else 0
                    end)/1024 as decimal(10,2)) as char)) + '</td>' +
       '<td class="alignright" >' + RTRIM(cast(cast( 
  	                sum(case
                      when FileGroupName is not null then FreeKB
                      else 0
                    end)/1024 as decimal(10,2)) as char)) + '</td>' +
					'<td class="alignright" >' + RTRIM(cast(cast( 
  	                sum(case
                      when FileGroupName is null then SizeKB
                      else 0
                    end)/1024 as decimal(10,2)) as char)) + '</td>' +
       '<td class="alignright" >' + RTRIM(cast(cast( 
  	                sum(case
                      when FileGroupName is null then FreeKB
                      else 0
                    end)/1024 as decimal(10,2)) as char)) + '</td>' +
        '<td class="alignright" >' + RTRIM(cast(cast(sum(SizeKB)/1024 as decimal(10,2)) as char)) + '</td>' + 
        '</tr>' 
from #space_info
where DatabaseName not in ('master','msdb','model','tempdb')
group by DatabaseName, state_desc
order by DatabaseName;
-- Query out sum og space for databases
select '<tr><th>Total Database Sizes</th>'
select '<tr><td class="sumcellleft" >Total size</td><td></td>' +
	   '<td class="sumcell" >' + RTRIM(cast(cast( 
  	                sum(case
                      when FileGroupName is not null then SizeKB
                      else 0
                    end)/1024 as decimal(10,2)) as char)) + '</td>' +
       '<td class="sumcell" >' + RTRIM(cast(cast( 
  	                sum(case
                      when FileGroupName is not null then FreeKB
                      else 0
                    end)/1024 as decimal(10,2)) as char)) + '</td>' +					
      '<td class="sumcell" >' + RTRIM(cast(cast( 
  	                sum(case
                      when FileGroupName is null then SizeKB
                      else 0
                    end)/1024 as decimal(10,2)) as char)) + '</td>' +		
       '<td class="sumcell" >' + RTRIM(cast(cast( 
  	                sum(case
                      when FileGroupName is null then FreeKB
                      else 0
                    end)/1024 as decimal(10,2)) as char)) + '</td>' +
		'<td class="sumcell" >' + cast(cast(sum(SizeKB)/1024 as decimal(10,2)) as char) + '</td>' +
		'</tr>' 					
from #space_info;	   

select '</table>'
go

select '<a href="#Topic"> Back to Topic</a><br />'

/* Database detail space information                                                  */

select '<a name="DetailSpaceInfo" class="ah2">Database detail space info for SQL Server instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
select '<table>'
select '<tr><th>Database Name</th><th>Filegroup Name</th><th>Name</th><th>File Name</th><th>Size MB</th>' + 
       '<th>Used MB</th><th>Free MB</th><th>Maxsize MB</th><th> % Free</th><th>Growth</th></tr>'
    
select '<tr>' +
       '<td>' + [master].[dbo].[MO_GetShortName] (DatabaseName, 25) + '</td>' +
       '<td>' + ISNULL(FileGroupName,'..LogFile..') + '</td>' +
	   '<td>' + [master].[dbo].[MO_GetShortName] (Name, 25) + '</td>' +
	   '<td>' + [master].[dbo].[MO_GetShortFileName] (FileName, 45) + '</td>' +
       '<td align="right">' + cast(cast(SizeKB/1024 as decimal(10,2)) as char) + '</td>' +
       '<td align="right">' + cast(cast(UsedKB/1024 as decimal(10,2)) as char) + '</td>' +
       '<td align="right">' + cast(cast(FreeKB/1024 as decimal(10,2)) as char) + '</td>' +
       '<td align="right">' + case 
                  when MaxSizeKB = -1 then 'Unlimited' 
                  else cast(cast(MaxSizeKB*8/1024 as decimal(10,2)) as char)  
                end + '</td>' +
       '<td align="center">' + cast(PctFree as char) + '</td>' +
       '<td>' + case
                  when (Status & 0x100000) = 0x100000 then 'by ' + cast(Growth as varchar(2)) + '%'
                  when (Status & 0x2) = 0x2 then 'by ' + cast(Growth*8/1024 as varchar(100)) + 'MB'
                  when (Status & 0x40) = 0x40 then 'by ' + cast(Growth*8/1024 as varchar(100)) + 'MB'
                  else 'NULL'
                end + '</td></tr>'
from #space_info
order by DatabaseName
select '</table>'
select '<a href="#Topic"> Back to Topic</a><br />'

select '<a name="DatabasevsStorageInfo" class="ah2">Database size versus storage info for SQL Server instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
select '<table>'
select '<tr><th>Disk Drive</th><th>Size of DBs (MB)</th><th>Size of used in DBs (MB)</th>' +
       '<th>Free on Disk (MB)</th></tr>'

;with dbsize (drive, physsizemb, usedsizemb) 
as (
select SUBSTRING(FileName,1,1) drive, SUM(SizeKB)/1024 physsizemb, SUM(UsedKB/1024) usedsizemb
from #space_info
group by SUBSTRING(FileName,1,1)
)
select '<tr>' +
       '<td>' + ds.drive + '</td>' +
	   '<td align="right">' + cast(cast(ds.physsizemb as decimal(10,2)) as char) + '</td>' + 
	   '<td align="right">' + cast(cast(ds.usedsizemb as decimal(10,2)) as char) + '</td>' +
       '<td align="right">' + cast(cast(df.mbfree as decimal(10,2)) as char) + '</td>'
--	   '<td align="right">' + cast(cast((df.mbfree-ds.physsizemb)/df.mbfree*100 as decimal(10,2)) as char) + '</td>' +
	   '</tr>'
from dbsize ds
join #drivefreespace df
on ds.drive = df.drive;
select '</table>'

select '<a href="#Topic"> Back to Topic</a><br />'

/*********************************************************************************************/
/* Collect Virtual log information                                                           */
/*                                                                                           */
/*********************************************************************************************/

declare @ver int;

create table #DbLogInfo(
RecoveryUnitID bigint,
FileId int,
FileSize decimal(20),
StartOffset bigint,
FSegNo bigint,
status int,
Parity int,
CreateLSN numeric(24));

-- In version below 2012 the RecoveryUnitID column dosn't exist, so we need to drop the it
select @ver = Value from #MORLT where Name = 'sqlserver_version';
if @ver < 11
begin
  alter table #DbLogInfo drop column RecoveryUnitID;
end

create table #AllDbLogInfo(
DbName     nvarchar(150),
FileId     int,
minMb      decimal(10,2),
MedianMb   decimal(10,2),
maxMb      decimal(10,2),
avgMb      decimal(10,2),
havg       decimal(10,2),
stdevMb    decimal(10,2),
sumMb      decimal(10,2),
numLogs    int,
usedVlogs  int,
pctLogused int)

declare @name nvarchar(150);
declare @dbid int;
declare @stmt nvarchar(200);

declare dbname_crr cursor for
  select name, database_id from master.sys.databases where state = 0 order by database_id;

open dbname_crr
fetch dbname_crr into @name, @dbid

while @@fetch_status >= 0
begin
  truncate table #DbLogInfo;
  set @stmt = 'dbcc loginfo('+ convert(varchar,@dbid) +')';
  insert into #DbLogInfo exec(@stmt);
  insert into #AllDbLogInfo (DbName, FileId, minMb, maxMb, avgMb, stdevMb, sumMb, numLogs)
  select @name, FileId,
    MIN(FileSize)/1048576,
    MAX(FileSize)/1048576,
    AVG(FileSize)/1048576,
    STDEV(FileSize)/1047576,
    SUM(FileSize)/1048576,
    COUNT(FileSize)
  from #DbLogInfo
  group by FileId;
  -- Update AllDbLogInfo with the Harmonic Mean value
  update #AllDbLogInfo 
  set havg = (select (1/AVG(1/FileSize)/1048576)
              from #DbLogInfo as DLI
              where DLI.FileId = #AllDbLogInfo.FileId
              group by FileId)
  where DbName = @name;
  -- Update AllDbLogInfo with the Median value
  WITH Median AS (
  SELECT FileId, FileSize,
    ROW_NUMBER() OVER(PARTITION BY FileId ORDER BY FileSize) AS RowNum,
    COUNT(*) OVER(PARTITION BY FileId) AS Cnt
  FROM #DbLogInfo)
  UPDATE #AllDbLogInfo set MedianMb = (SELECT avg(FileSize)/1048576
                                       FROM Median as M
                                       WHERE RowNum IN((Cnt + 1) / 2, (Cnt + 2) / 2)
                                       and M.FileId = #AllDbLogInfo.FileId)
   where DbName = @name;
  -- Update #AllDbLogInfo with Virtual log in use.
  update #AllDbLogInfo set usedVlogs = (select count(*)
                                        from #DbLogInfo as DLI
                                        where status = 2
                                        and DLI.FileId = #AllDbLogInfo.FileId)
  where DbName = @name;
  --Update #AllDbLogInfo with Vpercent log in use.
  update #AllDbLogInfo set pctLogused = (select cntr_value
                                         from sys.dm_os_performance_counters
                                         where instance_name = @name 
                                         and cntr_type = 65792
                                         and counter_name = 'Percent Log Used'
                                         and instance_name != '_Total')
  where DbName = @name;

  fetch dbname_crr into @name, @dbid
end
deallocate dbname_crr

select '<a name="VirLogInfo" class="ah2">Virtual Log space info for database instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
select '<table>'
select '<tr><th>Db Name</th><th>Min Mb</th><th>Median Mb</th><th>Max Mb</th><th>Avg Mb</th><th>Stdev Mb</th><th>Har. avg</th><th>Sum Mb</th><th>Num Vlogs</th><th>Used Vlog</th><th>Pct Logused</th></tr>'
select '<tr>' + 
       '<td>' + master.dbo.MO_GetShortName(DbName, 25) + '</td>' +
	   '<td>' + convert(varchar,minMb) + '</td>' + 
	   '<td>' + convert(varchar,MedianMb) + '</td>' +
	   '<td>' + convert(varchar,maxMb) + '</td>' +
	   '<td>' + convert(varchar,avgMb) + '</td>' + 
	   '<td>' + convert(varchar,stdevMb) + '</td>' +
	   '<td>' + convert(varchar,havg) + '</td>' +
	   '<td>' + convert(varchar,sumMb) + '</td>' + 
	   '<td ' + case
	              when numLogs > 150 then ' class="caution" >'
                  else ' class="highlight" >'
                end + convert(varchar,numLogs) + '</td>'+ 
	   '<td>' + convert(varchar,usedVlogs) + '</td>' +
	   '<td>' + convert(varchar,pctLogused) + '</td></tr>'
from #AllDbLogInfo;        
select '</table>'

select '<a href="#Topic"> Back to Topic</a><br />'


select '<br /><a name="ErrorInfo" class="ah1">Error Log Information:</a><br />'
/*********************************************************************************************/
/* Errorlog information                                                                      */
/*                                                                                           */
/*********************************************************************************************/
declare @archno tinyint
declare @count tinyint
declare @latest_online_check datetime
declare @NumErrorLogs int
declare @ErrorLog varchar(255)
declare @LogDate datetime

-- set @latest_online_check = (select latest_online_check from [miracle_online].[dbo].[Miracle_Online_Info])
set @latest_online_check = getdate() - (select convert(int,Value) from #MORLT where Name = 'latest_online_check')

create table #tbl_enumerrorlogs (ArchiveNo int, CreateDate datetime, Size int)
insert into #tbl_enumerrorlogs EXEC master.dbo.xp_enumerrorlogs 

select @LogDate = case
         when @latest_online_check < min(CreateDate) then min(CreateDate)
         else (select max(CreateDate) from #tbl_enumerrorlogs where CreateDate < @latest_online_check)
       end
from #tbl_enumerrorlogs

set @archno = (select min(ArchiveNo) from #tbl_enumerrorlogs where CreateDate <= @LogDate)

create table #Mir_Col_Errorlog (LogDate datetime, Source nvarchar(35), Error_text nvarchar(2048))
set @count = 0
while @count < @archno
begin
  insert into #Mir_Col_Errorlog EXEC master.dbo.xp_readerrorlog @count, 1, NULL, NULL, NULL, NULL, N'desc'
  set @count = @count + 1
end

-- Collect information regarding current errorlog and configured number of errorlogs.
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'NumErrorLogs', @NumErrorLogs OUTPUT
select @ErrorLog = convert(sysname,ServerProperty('ErrorLogFileName'))

-- Output section  
select '<a name="ErrorlogInfo" class="ah2">Errorlog info for SQL Server instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'

-- Table with basic errorlog information
select '<table>'
select '<tr><th>Path to Errorlog</th><th>Configured number of Errorlogs</th></tr>'
select '<tr><td>' + @ErrorLog + '</td><td  align="center">' + 
       case 
         when @NumErrorLogs is null then '6 (default)'
         else convert(sysname, ISNULL(@NumErrorLogs, -1))
       end  + '</td></tr>';
--select '<tr><td>' + @ErrorLog + '</td><td align="center">' + convert(sysname, ISNULL(@NumErrorLogs, -1)) + '</td></tr>'
select '</table>'

-- Table with runtime information

select '<table>'
select '<tr><th>Actual number of Arch logs</th><th>Oldest Rotation</th><th>Newest Rotation</th><th>Avg logsize (KB)</th><th>Max logsize (KB)</th></tr>'
select '<tr><td align="center">' + convert(sysname,count(ArchiveNo)-1) + '</td>' + 
        '<td align="center">' + convert(sysname,convert(varchar,min(CreateDate),120)) + '</td>' +
        '<td align="center">' + convert(sysname,convert(varchar,max(CreateDate),120)) + '</td>' +
        '<td align="center">' + convert(sysname,avg(Size)/1024) + '</td>' +
        '<td align="center">' + convert(sysname,max(Size)/1024) + '</td></tr>' 
from #tbl_enumerrorlogs;
select '</table><br />'

/*
-- Table with errorlog contents
select '<table>'
select '<tr><th>Log Date</th><th>Error Text</th></tr>'

update #Mir_Col_Errorlog set LogDate = convert(datetime,convert(varchar, LogDate, 120),120)

;with error (LogDate, no, errortext) as (
select O.LogDate as LogDate, count(*) no
       ,STUFF((
         select '  ' + [Source] + ': ' + [Error_text] + '<br />'
         from #Mir_Col_Errorlog
         where (LogDate = O.LogDate)
		 and LogDate > @latest_online_check
		 order by LogDate
         for xml path (''), TYPE ).value('.','VARCHAR(MAX)') , 1, 2, '') as NM
     /* Use .value to uncomment XML entities e.g. &gt; &lt; etc*/
from #Mir_Col_Errorlog O
group by O.LogDate
)
select '<tr>' + 
       '<td>' + convert(char, LogDate, 13) + '</td>' +
       '<td>' + errortext + '</td>' +
       '</tr>'
from error
where errortext is not null
and ((errortext like '%Error%') or (errortext like '%Failure%'))
and errortext not like '%Logon%'
and errortext not like '%finished without errors%'
and errortext not like '%ERRORLOG%'
and errortext not like '%found 0 errors and repaired 0 errors%'
order by LogDate;
select '</table>'
*/

select '<br /><table><tr><th> SQL Server Errorlog </th></tr> <tr><td class="aligncenter" ><b> FULL ERRORLOG OUTPUT NOW IN EXTERNAL HTML FILE FORMAT -> "DATESTAMP_COMPUTERNAME_INSTANCE_NAME.HTML" </b></td></tr></table>'

select '<br /><table>'
select '<tr><th> Error:Serverity:State </th><th> Error Count </th></tr>'

select '<tr><td>' + Error_text + '</td><td>' + convert(varchar,count(*)) + '</td></tr>'
from #Mir_Col_Errorlog 
where Error_text like '%Error:%Severity:%State%'
and LogDate > @latest_online_check
group by Error_text;

select '</table>'

select '<a href="#Topic"> Back to Topic</a><br />'

-- update [miracle_online].[dbo].[Miracle_Online_Info] set Latest_Online_Check = getdate ()
/*********************************************************************************************/
/* Summering of errorlog information                                                         */
/*                                                                                           */
/*********************************************************************************************/

select '<a name="ErrorlogSum" class="ah2">Summering from Errorlog for SQL Server instance: '+ convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
select '<table>'
select '<tr><th>Error Source</th><th>Error Date</th><th>Error Count</th></tr>'
select '<tr>' +
       '<td>' + Source + '</td>' +
       '<td>' + convert(char, LogDate, 106) + '</td>' +
       '<td>' + convert(char, count(*)) + '</td>' + 
       '</td>'
from #Mir_Col_Errorlog 
where Source in ('Logon', 'Backup')
and Error_text like '%Error%' 
and LogDate > @latest_online_check
group by Source, convert(char, LogDate, 106)
order by Source, convert(char, LogDate, 106)
select '</table>'
go
select '<a href="#Topic"> Back to Topic</a><br />'

use master
go

/*********************************************************************************************/
/* Displaying Misc trace information                                                    */
/*                                                                                           */
/*********************************************************************************************/

select '<a name="SysTraceInfo" class="ah2">Displaying trace information for SQL Server instance: '+ convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
select '<table>'
select '<tr><th>ID</th><th>Info</th><th>Status</th><th>Start Time</th><th>Stop Time</th></tr>'
select '<tr><td>' +
       convert(varchar,id)
       + '</td><td>' +
       case
         when path is null then '"Collecting rowset data"'
         else path
       end +
        +'</td><td>' +
       case 
         when status = 1 then 'running'
         when status = 0 then 'stopped'
       end
       + '</td><td>' +
       convert(varchar,start_time,120)
       + '</td><td>' +
       case
         when stop_time is null and is_default = 1 then 'DEFAULT TRACE!'
         when stop_time is null then 'Not defined'
         else convert(varchar,stop_time,120)
       end
       + '</td></tr>'
from sys.traces
select '</table>'
select '<a href="#Topic"> Back to Topic</a><br />'

select '<br /><a name="RuntimeInfo" class="ah1">Misc. Runtime Information:</a><br />'
/*********************************************************************************************/
/* Displaying Database Mirroring information                                                  */
/*                                                                                           */
/*********************************************************************************************/

select '<a name="MirroringInfo" class="ah2">Displaying database Mirroring information for SQL Server instance: '+ convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
select '<table>'
select '<tr><th>Database Name</th><th>Database ID</th><th>Role Desc.</th><th>State</th><th>Safety Level</th><th>Partner Name</th>' +
       '<th>Partner Instance</th><th>Witnes Name</th><th>Witnes State</th></tr>'
select '<tr><td>' + master.dbo.MO_GetShortName(d.name, 25) + 
       '</td><td>' + convert(nvarchar,d.database_id) +
       '</td><td>' + m.mirroring_role_desc COLLATE database_default +
       '</td><td>' + m.mirroring_state_desc +
       '</td><td>' + m.mirroring_safety_level_desc COLLATE database_default +
       '</td><td>' + m.mirroring_partner_name +
       '</td><td>' + m.mirroring_partner_instance +
       '</td><td>' + m.mirroring_witness_name  + 
       '</td><td>' + m.mirroring_witness_state_desc COLLATE database_default +
       '</td>'
FROM   sys.database_mirroring m JOIN sys.databases d
ON     m.database_id = d.database_id
WHERE  mirroring_state_desc IS NOT NULL
order by d.name;
select '</table>'
select '<a href="#Topic"> Back to Topic</a><br />'


/*********************************************************************************************/
/* Displaying indexes which might be good to rebuild/reorganize                              */
/*                                                                                           */
/*********************************************************************************************/
DECLARE @objectid int;
DECLARE @indexid int;
DECLARE @partitioncount bigint;
DECLARE @schemaname nvarchar(130); 
DECLARE @objectname nvarchar(130); 
DECLARE @indexname nvarchar(130); 
DECLARE @partitionnum bigint;
DECLARE @partitions bigint;
DECLARE @frag float;
DECLARE @command nvarchar(1200); 
declare @dbname nvarchar(100);
declare @dbid int;
declare @exec_stmt varchar(1600);
declare @pages bigint;
declare @min_defrag_pages int;
declare @run_defrag_index varchar(3);

set @min_defrag_pages = (select convert(int,Value) from #MORLT where Name = 'min_defrag_pages');

set @run_defrag_index = (select Value from #MORLT where Name = 'run_defrag_index');

declare dbname_crr cursor for 
select name, database_id from master.sys.databases
where name not in ('tempdb','model','AdventureWorksDW','AdventureWorks')
and state = 0;
		
create table #work_to_do 
(
DatabaseID	int null,
DatabaseName	varchar(130) null,
ObjectID	int null,
ObjectName	varchar(130) null,
SchemaName      varchar(130) null,
IndexID		int null,
IndexName	varchar(130) null,
PartitionNum	int null,
Frag		float null,
page_count      bigint
)

declare work_crr cursor for
select DatabaseName, ObjectID, IndexID
from #work_to_do

-- Declare the cursor for the list of partitions to be processed.
DECLARE partitions CURSOR FOR SELECT * FROM #work_to_do;

open dbname_crr
fetch dbname_crr into @dbname, @dbid
while @@fetch_status >= 0
begin
--  if (convert(sysname,DatabasePropertyEX(@dbname,'Status')) != 'OFFLINE') and (@run_defrag_index = 'YES')
    if (@run_defrag_index = 'YES')
      begin
		-- Conditionally select tables and indexes from the sys.dm_db_index_physical_stats function 
		-- and convert object and index IDs to names.
		INSERT INTO #work_to_do 		
		SELECT @dbid, @dbname, object_id, object_name(object_id, @dbid), OBJECT_SCHEMA_NAME(object_id, @dbid), index_id, null, partition_number, avg_fragmentation_in_percent, page_count
		FROM sys.dm_db_index_physical_stats (DB_ID(@dbname), NULL, NULL , NULL, 'LIMITED')

		WHERE avg_fragmentation_in_percent > 10.0 
		AND index_id > 0
		AND page_count > @min_defrag_pages;
	  end
	fetch dbname_crr into @dbname, @dbid
end		

deallocate dbname_crr

open work_crr
fetch work_crr into @dbname, @objectid, @indexid
	while @@fetch_status >= 0
	begin
		set @exec_stmt =
		'update #work_to_do set IndexName = (select name from [' + @dbname + '].sys.indexes ' +
		                                     'where object_id = ' + convert(varchar,@objectid)+ ' ' + 
		                                     'and index_id = ' + convert(varchar, @indexid) + ') ' +
                'where ObjectID = ' + convert(varchar,@objectid)  +
                'and IndexID = ' + convert(varchar, @indexid) + ';'
		exec (@exec_stmt)
		fetch work_crr into @dbname, @objectid, @indexid
	end
deallocate work_crr

-- Open the cursor.
OPEN partitions;

select '<a name="RebuildIndexes" class="ah2">Consider to rebuild these indexes on the instance: '+ convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
select '<table>'
select '<tr><th>Database Name</th><th>Table</th><th>Index</th><th>Fragmentation (%)</th><th>Pages (min '+ convert(varchar,@min_defrag_pages) +')</th><th>Rebuild/reorganize Index Statement</th></tr>'

-- Loop through the partitions.
WHILE (1=1)
    BEGIN;
        FETCH NEXT
           FROM partitions
           INTO @dbid, @dbname, @objectid, @objectname, @schemaname, @indexid, @indexname, @partitionnum, @frag, @pages;
        IF @@FETCH_STATUS < 0 BREAK;
        -- 30 is an arbitrary decision point at which to switch between reorganizing and rebuilding.
        IF @frag < 30.0
            SET @command = N'USE [' + @dbname + ']<br />go<br />' + 'ALTER INDEX [' + @indexname + '] ON ' + @schemaname + '.' + @objectname + ' REORGANIZE';
        IF @frag >= 30.0
            SET @command = N'USE [' + @dbname + ']<br />go<br />' + 'ALTER INDEX [' + @indexname + '] ON ' + @schemaname + '.' + @objectname + ' REBUILD';
        IF @partitioncount > 1
            SET @command = @command + N' PARTITION=' + CAST(@partitionnum AS nvarchar(10));
        select '<tr><td>' + RTRIM(@dbname) +'</td><td>'+ RTRIM(@objectname) +'</td><td>'+ RTRIM(@indexname) +'</td><td>'+ RTRIM(@frag) +'</td><td>'+ convert(varchar(25),@pages) +'</td><td>'+ RTRIM(@command)+'</td></tr>'
--      select '<tr><td>' + [master].[dbo].[MO_GeShortName](RTRIM(@dbname),25) +'</td><td>'+ RTRIM(@objectname) +'</td><td>'+ RTRIM(@indexname) +'</td><td>'+ RTRIM(@frag) +'</td><td>'+ convert(varchar(25),@pages) +'</td><td>'+ RTRIM(@command)+'</td></tr>'		
        --EXEC (@command);
        -- PRINT N'Executed: ' + @command;
	set @command = null;
    END;
select '</table>'

-- Close and deallocate the cursor.
CLOSE partitions;
DEALLOCATE partitions;

If @run_defrag_index = 'NO'
  select '<b>Index fragmentation collection is disabled !</b><br />'

-- Drop the temporary table.
DROP TABLE #work_to_do;
GO 

select '<a href="#Topic"> Back to Topic</a><br />'

/*********************************************************************************************/
/* Displaying missing index candidate                                                        */
/*                                                                                           */
/*********************************************************************************************/

select '<a name="MissingIndexes" class="ah2">Missing Index Candidates on the instance: '+ convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
select '<br />You need to investigate impact further before applying!<br />'

select '<table>'
select '<tr><th>Impact Ratio</th><th>Object</th><th>Create Index Statement</th><th>Last User Seek</th><th>Last User Scan</th></tr>'

SELECT '<tr>' +
       '<td>' +  convert(varchar,convert(decimal(14,2), (migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans)))) + '</td>' +
	   '<td>' + QUOTENAME(db_name(mid.database_id))+'.'+QUOTENAME(OBJECT_SCHEMA_NAME(mid.object_id, mid.database_id))+'.'+QUOTENAME(OBJECT_NAME(mid.object_id, mid.database_id)) + '</td>' +
	   '<td>' + 
	     'CREATE INDEX [mi_' + SUBSTRING(CONVERT(VARCHAR(64), NEWID()), 1, 8) + ']' + ' ON ' + mid.statement + ' (' + ISNULL(mid.equality_columns, '') + CASE 
		  WHEN mid.equality_columns IS NOT NULL
			  AND mid.inequality_columns IS NOT NULL
			  THEN ','
		  ELSE ''
		  END + ISNULL(mid.inequality_columns, '') + ')' + ISNULL(' INCLUDE (' + mid.included_columns + ')', '') +
	   '</td>' +
	   '<td>' +
  	     case
	       when migs.last_user_seek is null then 'NULL'
		   else convert(varchar, migs.last_user_seek, 113)
	     end + 
	   '</td>' +
	   '<td>' +
  	     case
	       when migs.last_user_scan is null then 'NULL'
		   else convert(varchar, migs.last_user_scan, 113)
	     end + 
	   '</td></tr>' 	
FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs
	ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid
	ON mig.index_handle = mid.index_handle
WHERE migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans) > 1000
and last_user_seek > GETDATE() - 30
ORDER BY migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) DESC

select '</table>'

select '<a href="#Topic"> Back to Topic</a><br />'

/*********************************************************************************************/
/* Displaying index usage information                                                        */
/*                                                                                           */
/*********************************************************************************************/

select '<a name="IndexUsageInfo" class="ah2">Index Usage information: '+ convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
select '<br />You need to investigate further before deleting indexes!<br />'

declare @dbname               nvarchar(128)
declare @dbid                 int
declare @exec_stmt            varchar(max)
declare @state_desc           nvarchar(60)

CREATE table #idx_usage_inf (
    [DatabaseName] [nvarchar] (128) NULL,
    [DatabaseID] [int] NULL,
	[SchemaName] [nvarchar](128) NULL,
	[ObjectName] [nvarchar](128) NULL,
	[IndexName] [sysname] NULL,
	[type_desc] [nvarchar](60) NULL,
	[user_seeks] [bigint] NULL,
	[user_scans] [bigint] NULL,
	[user_lookups] [bigint] NULL,
	[user_updates] [bigint] NULL,
	[last_user_seek] [datetime] NULL,
	[last_user_scan] [datetime] NULL,
	[last_user_lookup] [datetime] NULL,
	[last_user_update] [datetime] NULL
)

declare dbname_crr cursor for 
  select name, state_desc, database_id from master.sys.databases where database_id > 4;
  
open dbname_crr
fetch dbname_crr into @dbname, @state_desc, @dbid  

while @@fetch_status >= 0
begin
  if  @state_desc = 'ONLINE'
    begin
      set @exec_stmt = 'use ' + quotename(@dbname, N'[') +
      ' insert into #idx_usage_inf (DatabaseName, DatabaseID, SchemaName, ObjectName, IndexName, type_desc, ' +
      ' user_seeks, user_scans, user_lookups, user_updates, last_user_seek, last_user_scan, last_user_lookup, last_user_update) ' +
      ' SELECT ''' + @dbname + ''',''' + convert(varchar,@dbid) + ''', OBJECT_SCHEMA_NAME(I.OBJECT_ID) AS SchemaName,' +
      ' OBJECT_NAME(I.OBJECT_ID) AS ObjectName, I.NAME AS IndexName, I.type_desc,' +
      ' user_seeks, user_scans, user_lookups, user_updates,' +
      ' last_user_seek, last_user_scan, last_user_lookup, last_user_update' +
      ' FROM sys.indexes I' +
      ' LEFT OUTER JOIN sys.dm_db_index_usage_stats ixs' +
      ' ON (ixs.OBJECT_ID = I.OBJECT_ID AND I.index_id = ixs.index_id AND ixs.database_id = DB_ID())' +
      ' WHERE OBJECTPROPERTY(I.OBJECT_ID, ''IsUserTable'') = 1' +
      ' ORDER BY SchemaName, ObjectName, IndexName;'
      execute (@exec_stmt);
    end
  fetch dbname_crr into @dbname, @state_desc, @dbid
end

close dbname_crr
deallocate dbname_crr

select '<table>'
select '<tr><th>Database Name</th><th>Unused Indexes</th><th>Avg Idx Updates</th><th>Max Idx Updates</th><th>Sum Idx Updates</th><th>Latest Update</th></tr>'

select '<tr>' +
       '<td>' + DatabaseName + '</td>' +
       '<td class="aligncenter" >' + convert(varchar,COUNT(*)) + '</td>' +
       '<td class="aligncenter" >' + convert(varchar,AVG(user_updates)) + '</td>' +
       '<td class="aligncenter" >' + convert(varchar,MAX(user_updates)) + '</td>' +
       '<td class="aligncenter" >' + convert(varchar,SUM(user_updates)) + '</td>' +
       '<td class="aligncenter" >' + convert(varchar,MAX(last_user_update)) + '</td></tr>'
from #idx_usage_inf
where (user_seeks + user_scans + user_lookups) = 0
and user_updates is not null 
and last_user_update is not null
group by DatabaseName
select '</table>'
drop table #idx_usage_inf
go

select '<a href="#Topic"> Back to Topic</a><br />'

/*********************************************************************************************/
/* Displaying Statistics Information for Databases                                           */
/*                                                                                           */
/*********************************************************************************************/
select '<a name="DatabaseStatistics" class="ah2">SQL Server Database Statistics Overview for instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
--select '<br />You need to investigate further before deleting indexes!<br />'

create table #instance_stats (
database_name sysname,
table_name sysname,
index_name sysname,
last_stats_date datetime);
 
declare @dbname               nvarchar(100)
declare @dbid                 int
declare @exec_stmt            varchar(1600)
declare @state_desc           nvarchar(60)
declare dbname_crr cursor for 
  select name, state_desc, database_id from master.sys.databases;
open dbname_crr
fetch dbname_crr into @dbname, @state_desc, @dbid
while @@fetch_status >= 0
begin
    if  @state_desc = 'ONLINE'
    begin
      set @exec_stmt = 'use ' + quotename(@dbname, N'[') +
        'insert into #instance_stats (database_name, table_name, index_name, last_stats_date) ' +
        'select ''' + @dbname + ''', OBJECT_NAME(object_id) [TableName], 
         name [IndexName], STATS_DATE(object_id, stats_id) [LastStatsUpdate]
         FROM sys.stats
         WHERE name NOT LIKE ''_WA%''
         AND STATS_DATE(object_id, stats_id) IS NOT NULL
         AND OBJECTPROPERTY(object_id, ''IsMSShipped'') = 0 '
      execute (@exec_stmt)
    end
  else
    begin
      insert into #instance_stats values (@dbname, 'DB OFFLINE', 'DB OFFLINE', GETDATE())
    end
  
  fetch dbname_crr into @dbname, @state_desc, @dbid
end
deallocate dbname_crr

select '<table>'
select '<tr><th>Database Name</th><th>0-24 hour</th><th>1-7 days</th><th>7-14 days</th><th>14-31 days</th><th>31-365 days</th><th> More than 365 days</th></tr>'
;with statsdate as (
SELECT database_name,
       table_name, index_name, last_stats_date [LastStatsUpdate]
       --STATS_DATE(object_id, stats_id) [LastStatsUpdate]
FROM #instance_stats )
select '<tr>' +
       '<td>' + database_name + '</td>' +
       '<td class="aligncenter" >' + convert(sysname, sum(case when [LastStatsUpdate] > GETDATE()-1 then 1 else 0 end )) + '</td>' +
       '<td class="aligncenter" >' + convert(sysname, sum(case when [LastStatsUpdate] > GETDATE()-7 and [LastStatsUpdate] < GETDATE()-1 then 1 else 0 end )) + '</td>' +
       '<td class="aligncenter" >' + convert(sysname, sum(case when [LastStatsUpdate] > GETDATE()-14 and [LastStatsUpdate] < GETDATE()-7 then 1 else 0 end )) + '</td>' +
       '<td class="aligncenter" >' + convert(sysname, sum(case when [LastStatsUpdate] > GETDATE()-31 and [LastStatsUpdate] < GETDATE()-14 then 1 else 0 end )) + '</td>' +
       '<td class="aligncenter" >' + convert(sysname, sum(case when [LastStatsUpdate] > GETDATE()-365 and [LastStatsUpdate] < GETDATE()-31 then 1 else 0 end )) + '</td>' +
       '<td class="aligncenter" >' + convert(sysname, sum(case when [LastStatsUpdate] < GETDATE()-365 then 1 else 0 end )) + '</td></tr>'
from statsdate
group by database_name;
select '</table>';
drop table #instance_stats
go
select '<a href="#Topic"> Back to Topic</a><br />'

/*****************/
/* PerfInfo part */
select '<br /><a name="PerfInfo" class="ah1">Runtime Performance Information:</a><br />'

/*********************************************************************************************/
/* Displaying Database Misc. information                                                     */
/*                                                                                           */
/*********************************************************************************************/
select '<a name="DatabaseInformation" class="ah2">Misc. Information for the databases on SQL Server instance: '+ convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'

declare @total_buffer int;
declare @ver int;

select @ver = Value from #MORLT where Name = 'sqlserver_version';
-- When SQL Server version is below (2008) then we ca use "Total Pages"
if @ver <= 10 
begin
  select @total_buffer = cntr_value
  from sys.dm_os_performance_counters 
  where RTRIM([object_name]) like '%Buffer Manager'
  and counter_name = 'Total pages';
end;

-- When SQL Server version is 2012 we need to query other Memory counters in sys.dm_os_performance_counters
if @ver = 11
begin
  select @total_buffer = cntr_value
  from sys.dm_os_performance_counters 
  where RTRIM([object_name]) like '%Memory Manager'
  and counter_name = 'Total Server Memory (KB)';
-- Convert the KB value to app. pages.  
  set @total_buffer=@total_buffer/8;
end;

select '<table>';
select '<tr><th>Database Name</th><th>Cached Pages</th><th>Cached MB</th><th>Pct of Total Buffer Pages</th><th>CPU Time (sec)</th><th>CPU Time (pct)</th></tr>'

;WITH DB_CPU_Stats
AS
(SELECT DatabaseID, DB_Name(DatabaseID) AS [DatabaseName], SUM(total_worker_time) AS [CPU_Time_Ms]
 FROM sys.dm_exec_query_stats AS qs
 CROSS APPLY (SELECT CONVERT(int, value) AS [DatabaseID] 
              FROM sys.dm_exec_plan_attributes(qs.plan_handle)
              WHERE attribute = N'dbid') AS F_DB
 GROUP BY DatabaseID)
,CPU_TOP AS (
SELECT top 10 ROW_NUMBER() OVER(ORDER BY [CPU_Time_Ms] DESC) AS [row_num],
       DatabaseName, [CPU_Time_Ms], 
       CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0 AS DECIMAL(5, 2)) AS [CPUPercent]
FROM DB_CPU_Stats
WHERE DatabaseID > 0 -- 4 -- system databases
AND DatabaseID <> 32767 -- ResourceDB
)
select '<tr>' +
       '<td>' + master.dbo.MO_GetShortName(cache_inf.DatabaseName,25) + '</td>' +
	   '<td>' + convert(varchar(12),cache_inf.cached_pages_count) + '</td>' +
       '<td>' + convert(varchar(12),cache_inf.cached_pages_count/128) +'</td>' +
       '<td>' + convert(varchar(12),cache_inf.cached_pages_count * 100 / @total_buffer) +'</td>' +
	   '<td>' + 
       case
         when CPU_Time_Ms is null then '0'
         else convert(varchar,CPU_Time_Ms/1000) -- Convert to seconds
       end + 
       '</td>' +
	   '<td>' + 
       case 
         when CPUPercent is null then '0.0' 
         else convert(varchar,CPUPercent)
       end + 
       '</td>' +
	   '</tr>'
from CPU_TOP CT
right outer join
( SELECT CASE database_id 
                WHEN 32767 THEN 'ResourceDb' 
                ELSE db_name(database_id) 
              END AS DatabaseName
              ,count(*)AS cached_pages_count
              ,left(cast(convert(varchar(20),cast(count(*) *8/1024 as money),1) as varchar),
                    len(convert(varchar(20), cast (count(*) *8/1024 as money),1))-3) KB
       FROM sys.dm_os_buffer_descriptors
       GROUP BY db_name(database_id) ,database_id) cache_inf 
on CT.DatabaseName = cache_inf.DatabaseName
order by cached_pages_count desc

--order by CPUPercent desc;

select '</table>';
select '<a href="#Topic"> Back to Topic</a><br />'

/*********************************************************************************************/
/* Displaying Instance Plan Cache information                                                */
/*                                                                                           */
/*********************************************************************************************/
select '<a name="PlanCacheInformation" class="ah2">Plan Cache information for SQL Server instance: '+ convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'

select '<table>' +
       '<tr><th>CacheType</th><th>Total_Plans</th><th>Pct of All Plans</th><th>Total MBs</th><th>Pct of Total Plan Cache</th><th>Avg Use Count</th>' +
       '<th>Total MBs - USE Count 1</th><th>Total Plans - USE Count 1</th><th>Pct of Use count 1 plans</th></tr>'

;with cache as (
SELECT objtype AS [CacheType]
        , count_big(*) AS [Total_Plans]
        , sum(cast(size_in_bytes as decimal(18,2)))/1024/1024 AS [Total MBs]
        , avg(usecounts) AS [Avg Use Count]
        , sum(cast((CASE WHEN usecounts = 1 THEN size_in_bytes ELSE 0 END) as decimal(18,2)))/1024/1024 AS [Total MBs - USE Count 1]
        , sum(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END) AS [Total Plans - USE Count 1]
FROM sys.dm_exec_cached_plans
GROUP BY objtype)
select '<tr>' +
       '<td>' + CacheType + '</td>' +
       '<td class="aligncenter" >' + convert(varchar,convert(numeric(18,2),Total_Plans)) + '</td>' +
       '<td class="aligncenter" >' + convert(varchar,convert(numeric(18,2),100 * CONVERT(numeric(10,2),Total_Plans)/ CONVERT(numeric(10,2),SUM(Total_Plans) over () ))) + '</td>' +
       '<td class="aligncenter" >' + convert(varchar,convert(numeric(18,2),[Total MBs])) + '</td>' +
       '<td class="aligncenter" >' + convert(varchar,convert(numeric(18,2),100 * CONVERT(numeric(18,2), [Total MBs]) / convert(numeric(18,2),SUM([Total MBs]) over () ))) + '</td>' +
       '<td class="aligncenter" >' + convert(varchar,[Avg Use Count]) + '</td>' +
       '<td class="aligncenter" >' + convert(varchar,convert(numeric(18,2),[Total MBs - USE Count 1])) + '</td>' +
       '<td class="aligncenter" >' + convert(varchar,[Total Plans - USE Count 1]) + '</td>' +
       '<td class="aligncenter" >' + CONVERT(varchar,convert(numeric(18,2), 100*CONVERT(numeric(10,2),[Total Plans - USE Count 1]) / CONVERT(numeric(10,2),SUM(Total_Plans) over () ))) + '</td>' +
       '</tr>'
from cache
order by Total_Plans desc

select '</table>'


/*********************************************************************************************/
/* Displaying Database Blocking information                                                  */
/*                                                                                           */
/*********************************************************************************************/
select '<a name="BlockingInfo" class="ah2">Blocking information for the SQL Server instance: '+ convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'

SELECT s.spid, BlockingSPID = s.blocked, DatabaseName = DB_NAME(s.dbid),
       s.program_name, s.loginame, ObjectName = OBJECT_NAME(objectid, s.dbid), Definition = CAST(text AS VARCHAR(MAX)),
       s.hostname, s.last_batch
INTO #Processes
FROM sys.sysprocesses s
CROSS APPLY sys.dm_exec_sql_text (sql_handle);
--WHERE s.spid > 50

select '<table>';
select '<tr><th>Blocking SPPID</th><th>SPID</th><th>Database Name</th><th>Hostname</th><th>Login</th><th>Last Batch</th><th>Blocking Statement</th></tr>';
WITH Blocking(spid, BlockingSPID, DatabaseName, Hostname, Login, Last_batch, BlockingStatement, RowNo, LevelRow) AS
(
  SELECT s.spid, s.BlockingSPID, s.DatabaseName, s.hostname, s.loginame, s.last_batch, s.Definition, ROW_NUMBER() OVER(ORDER BY s.spid), 0 AS LevelRow
  FROM #Processes s
  JOIN #Processes s1 ON s.spid = s1.BlockingSPID
  WHERE s.BlockingSPID = 0
  UNION ALL 
  SELECT  r.spid,  r.BlockingSPID, r.DatabaseName, r.hostname, r.loginame, r.last_batch, r.Definition, d.RowNo, d.LevelRow + 1
  FROM #Processes r
  JOIN Blocking d ON r.BlockingSPID = d.spid
  WHERE r.BlockingSPID > 0
 )
SELECT '<tr>' + 
       '<td>' + 
	   case 
	     when BlockingSPID = 0 then 'BLOCKER'
		 else replicate('_ ',LevelRow) + convert(varchar,BlockingSPID)
       end + '</td>' +
	   '<td>' + convert(varchar,spid) + '</td>' +
       '<td>' + master.dbo.MO_GetShortName(RTRIM(DatabaseName),25) + '</td>' +
       '<td>' + RTRIM(Hostname) + '</td>' +
       '<td>' + RTRIM(Login) + '</td>' +
       '<td>' + convert(varchar,Last_batch, 20) + '</td>' +
--	'<td>' + convert(varchar,RowNo) + '</td>' +
--	'<td>' + convert(varchar,LevelRow) + '</td>' +
	   '<td>' + BlockingStatement + '</td>' +
	   '</tr>'
FROM Blocking
ORDER BY RowNo, LevelRow;
select '</table>';
select '<a href="#Topic"> Back to Topic</a><br />'

/*********************************************************************************************/
/* Displaying Latest X minutes of activities                                                 */
/*                                                                                           */
/*********************************************************************************************/
select '<a name="InstanceActivity" class="ah2">Latest activites (' + Value +
       ' minutes) for the instance: '+ convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
from #MORLT 
where Name = 'wait_loop_counter';

---- Sort by CPU Usage ----

select '<table>'
select '<tr><th>CPU Usage</th><th>Spid</th><th>Status</th><th>Loginname</th><th>Hostname</th><th>Program Name</th><th>Query Text</th></tr>'
select top 10 + '<tr>' +
       '<td>' + convert(varchar,e.CPU-b.CPU) + '</td>' + 
	   '<td>' + convert(varchar,e.Spid) + '</td>' + 
	   '<td>' + rtrim(e.Status) + '</td>' +
	   '<td>' + rtrim(e.LoginName) + '</td>' +
	   '<td>' + rtrim(e.HostName) + '</td>' +
	   '<td>' + rtrim(e.program_name) + '</td>' +
	   '<td>' + 
	     case 
		   when qt.text is null then 'NULL'
--		   else qt.text
           else replace(replace(replace(replace(substring(qt.text,1,2000), '>', '¤gt;'), '<', '¤lt;'), '&', '¤amp;' ), '¤', '&') + '. . . .'
		 end + '</td></tr>'
from #beginprocess b
inner join #endprocess e
  on b.Spid=e.Spid
CROSS APPLY sys.dm_exec_sql_text(b.sql_handle) as qt
where
e.CPU-b.CPU > 0
order by e.CPU-b.CPU desc
select '</table>'

---- Sort by IO Usage ----

select '<table>'
select '<tr><th>IO Usage</th><th>Spid</th><th>Status</th><th>Loginname</th><th>Hostname</th><th>Program Name</th><th>Query Text</th></tr>'
select top 10 + '<tr>' +
       '<td>' + convert(varchar,e.IO-b.IO) + '</td>' + 
	   '<td>' + convert(varchar,e.Spid) + '</td>' + 
	   '<td>' + rtrim(e.Status) + '</td>' +
	   '<td>' + rtrim(e.LoginName) + '</td>' +
	   '<td>' + rtrim(e.HostName) + '</td>' +
	   '<td>' + rtrim(e.program_name) + '</td>' +
	   '<td>' + 
	     case 
		   when qt.text is null then 'NULL'
--		   else qt.text
           else replace(replace(replace(replace(substring(qt.text,1,2000), '>', '¤gt;'), '<', '¤lt;'), '&', '¤amp;' ), '¤', '&') + '. . . .'
		 end + '</td></tr>'
from #beginprocess b
inner join #endprocess e
  on b.Spid=e.Spid
CROSS APPLY sys.dm_exec_sql_text(b.sql_handle) as qt
where
e.IO-b.IO > 0
order by e.IO-b.IO desc
select '</table>'
---- Sort by MEM Usage ----

select '<table>'
select '<tr><th>Mem Usage</th><th>Spid</th><th>Status</th><th>Loginname</th><th>Hostname</th><th>Program Name</th><th>Query Text</th></tr>'
select top 10 + '<tr>' +
       '<td>' + convert(varchar,e.MemUsage-b.MemUsage) + '</td>' + 
	   '<td>' + convert(varchar,e.Spid) + '</td>' + 
	   '<td>' + rtrim(e.Status) + '</td>' +
	   '<td>' + rtrim(e.LoginName) + '</td>' +
	   '<td>' + rtrim(e.HostName) + '</td>' +
	   '<td>' + rtrim(e.program_name) + '</td>' +
	   '<td>' + 
	     case 
		   when substring(qt.text,1,25) is null then 'NULL'
--		   else qt.text
           else replace(replace(replace(replace(substring(qt.text,1,2000), '>', '¤gt;'), '<', '¤lt;'), '&', '¤amp;' ), '¤', '&') + '. . . .'
		 end + '</td></tr>'
from #beginprocess b
inner join #endprocess e
  on b.Spid=e.Spid
CROSS APPLY sys.dm_exec_sql_text(b.sql_handle) as qt
where
e.MemUsage-b.MemUsage > 0
order by e.MemUsage-b.MemUsage desc
select '</table>'

drop table #beginprocess
drop table #endprocess

select '<a href="#Topic"> Back to Topic</a><br />'

/*********************************************************************************************/
/* Displaying Top 20 Average IO waits for this run                                           */
/*                                                                                           */
/*********************************************************************************************/
select '<a name="Top20AvgIoWaitsNow" class="ah2">Top 20 Average IO waits (latest ' + Value + 
        ' minutes) for the instance: '+ convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'		
from #MORLT 
where Name = 'wait_loop_counter';

select '<br />You need to investigate further before concluding!<br />'

select '<table>'
select '<tr><th>Database</th><th>Physical File</th><th>Type</th><th>File ID</th>' + 
       '<th>Num Reads</th><th>Byte Reads</th><th>Wait ms</th><th>Avg Read ms</th><th>Accu Avg Read ms</th>' + 
       '<th>Num Writes</th><th>Byte Writes</th><th>Wait ms</th><th>Avg Write ms</th><th>Accu Avg Write ms</th>' +
	   '<th>Total IO Waits ms </th></tr>'
select top 20 '<tr>' + 
       '<td>' + master.dbo.MO_GetShortName (DB_NAME(mf.database_id), 25) + '</td>' +
       '<td>' + master.dbo.MO_GetShortFileName(mf.physical_name, 65) + '</td>' +
       '<td>' + mf.type_desc collate database_default + '</td>' +
	   '<td>' + CONVERT(varchar, mf.file_id) + '</td>' +
       '<td>' + CONVERT(varchar, e.num_of_reads-b.num_of_reads) + '</td>' +
       '<td>' + CONVERT(varchar, e.num_of_bytes_read-b.num_of_bytes_read) + '</td>' +
       '<td>' + CONVERT(varchar, e.io_stall_read_ms-b.io_stall_read_ms) + '</td>' +
       '<td class="highlight" >' + CONVERT(varchar,((e.io_stall_read_ms-b.io_stall_read_ms) / (1 + (e.num_of_reads-b.num_of_reads)))) + '</td>' +
       '<td>' + CONVERT(varchar, e.io_stall_read_ms / (1 + e.num_of_reads)) + '</td>' +
       '<td>' + CONVERT(varchar, e.num_of_writes-b.num_of_writes) + '</td>' +
       '<td>' + CONVERT(varchar, e.num_of_bytes_written-b.num_of_bytes_written) + '</td>' +
       '<td>' + CONVERT(varchar, e.io_stall_write_ms-b.io_stall_write_ms) + '</td>' +
       '<td class="highlight" >' + CONVERT(varchar,((e.io_stall_write_ms-b.io_stall_write_ms) / (1 + (e.num_of_writes-b.num_of_writes)))) + '</td>' +
       '<td>' + CONVERT(varchar, e.io_stall_write_ms / (1 + e.num_of_writes)) + '</td>' +
       '<td>' + CONVERT(varchar, e.io_stall-b.io_stall) + '</td>' +
       '</tr>'
from #beg_virtual_file_stats b
join #end_virtual_file_stats e
on  b.database_id = e.database_id
and b.file_id = e.file_id
join sys.master_files mf
on mf.database_id = b.database_id
and mf.file_id = b.file_id
where e.num_of_reads-b.num_of_reads > 0
or    e.num_of_writes-b.num_of_writes > 0
order by e.io_stall-b.io_stall desc
select '</table>'
	   
select '<a href="#Topic"> Back to Topic</a><br />'

/*********************************************************************************************/
/* Displaying Top 20 Average IO waits                                                        */
/*                                                                                           */
/*********************************************************************************************/
select '<a name="Top20AvgIoWaitsAccu" class="ah2">Top 20 Average IO waits (accu) for the instance: '+ convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
select '<br />You need to investigate further before concluding!<br />'

select '<table>'
select '<tr><th>Database</th><th>Physical File</th><th>Type</th><th>File ID</th><th>Num Reads</th><th>KBytes Reads</th><th>IO Waits Reads ms</th><th>Num Writes</th>' +
       '<th>KBytes Writes</th><th>IO Waits Writes ms</th><th>IO Waits</th><th>Total Avg IO Waits ms</th></tr>'

SELECT top 20 '<tr>' +
       '<td>' + master.dbo.MO_GetShortName (DB_NAME(mf.database_id), 25) + '</td>' +
       '<td>' + master.dbo.MO_GetShortFileName(mf.physical_name, 65) + '</td>' +
       '<td>' + mf.type_desc collate database_default + '</td>' +
       '<td>' + convert(varchar,vfs.file_id) + '</td>' +
       '<td>' + convert(varchar,vfs.num_of_reads) + '</td>' +
       '<td>' + convert(varchar,vfs.num_of_bytes_read/1024) + '</td>' +
       '<td>' + convert(varchar,vfs.io_stall_read_ms) + '</td>' +
       '<td>' + convert(varchar,vfs.num_of_writes) + '</td>' +
       '<td>' + convert(varchar,vfs.num_of_bytes_written/1024) + '</td>' +
       '<td>' + convert(varchar,vfs.io_stall_write_ms) + '</td>' +
       '<td>' + convert(varchar,vfs.io_stall) + '</td>' +
       '<td>' + convert(varchar,CAST((vfs.io_stall_read_ms + vfs.io_stall_write_ms)	/  (1.0 + vfs.num_of_reads + vfs.num_of_writes) AS DECIMAL(10,1) )) + '</td>'
FROM sys.dm_io_virtual_file_stats(NULL, NULL) vfs
JOIN sys.master_files mf
	ON mf.database_id = vfs.database_id
	AND mf.file_id = vfs.file_id
ORDER by (vfs.io_stall_read_ms + vfs.io_stall_write_ms)	/  (1.0 + vfs.num_of_reads + vfs.num_of_writes) desc

select '</table>'

select '<a href="#Topic"> Back to Topic</a><br />'

/*********************************************************************************************/
/* Displaying Top 20 waits stats for this run                                                */
/*                                                                                           */
/*********************************************************************************************/
select '<a name="Top20WaitsNow" class="ah2">Top 20 wait stats (latest ' + Value +
       ' minutes) for the instance: '+ convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
from #MORLT 
where Name = 'wait_loop_counter';

select '<table>'
select '<tr><th>Wait Type</th><th>Waits</th><th>Wait ms</th><th>Signal Wait ms</th><th>Percent</th></tr>'
; with runtimewait as (
select
  s.[wait_type], 
  s.[waiting_tasks_count]-m.[waiting_tasks_count] waits,
  s.[wait_time_ms]-m.[wait_time_ms] wait_time, 
  s.[signal_wait_time_ms]-m.[signal_wait_time_ms] signal_wait_time,
  100 * (s.wait_time_ms-m.wait_time_ms) / SUM(s.wait_time_ms-m.wait_time_ms) over () as pct,
  ROW_NUMBER() over(order by (s.wait_time_ms-m.wait_time_ms)desc, (s.waiting_tasks_count-m.waiting_tasks_count)) as rn
from #my_end_waitstats s, #my_beg_waitstats m
where s.[wait_type]=m.[wait_type] 
and s.[wait_time_ms]-m.[wait_time_ms] > 0
and NOT exists (select wait from #ignore_waits where wait = s.[wait_type])
)
select top 20 '<tr>' +
  '<td>' + wait_type + '</td>' +
  '<td>' + convert(varchar,waits) + '</td>' +
  '<td>' + convert(varchar,wait_time) + '</td>' +
  '<td>' + convert(varchar,signal_wait_time) + '</td>' +
  '<td>' + convert(varchar,pct) + '</td>' +
  '</tr>'
from runtimewait
order by pct desc;
select '</table>'

select '<a href="#Topic"> Back to Topic</a><br />'

/*********************************************************************************************/
/* Displaying Top 20 waits stats since instance start                                        */
/*                                                                                           */
/*********************************************************************************************/
select '<a name="Top20WaitsAccu" class="ah2">Top 20 wait stats (accumulated since instance start) for the instance: '+ convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
select '<table>'
select '<tr><th>Wait Type</th><th>Wait sec</th><th>Signal Wait sec</th><th>Percent</th><th>Running Pct</th></tr>'
;WITH Waits AS (
SELECT 
	wait_type, 
	wait_time_ms / 1000. AS wait_time_s,
	signal_wait_time_ms / 1000. AS signal_wait_time_s,
    100. * wait_time_ms / SUM(wait_time_ms) OVER() AS pct,
    ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS rn
FROM sys.dm_os_wait_stats dows
WHERE NOT exists (select wait from #ignore_waits where wait = dows.wait_type ) 
) 
SELECT top 20 '<tr>' +
  '<td>' + W1.wait_type + '</td>' +
  '<td>' + convert(varchar,CAST(W1.wait_time_s AS DECIMAL(12, 2))) + '</td>' +
  '<td>' + convert(varchar,CAST(W1.signal_wait_time_s AS DECIMAL(12, 2))) + '</td>' +
  '<td>' + convert(varchar,CAST(W1.pct AS DECIMAL(12, 2))) + '</td>' +
  '<td>' + convert(varchar,CAST(SUM(W2.pct) AS DECIMAL(12, 2))) + '</td>' +
  '<tr>'
FROM Waits AS W1
INNER JOIN Waits AS W2 ON W2.rn <= W1.rn
GROUP BY W1.rn, W1.wait_type, W1.wait_time_s,W1.signal_wait_time_s, W1.pct
HAVING SUM(W2.pct) - W1.pct < 95; 

select '</table>'

select '<a href="#Topic"> Back to Topic</a><br />'

/*********************************************************************************************/
/* Displaying some sampled accumulative performance counters                                 */
/*                                                                                           */
/*********************************************************************************************/
select '<a name="AccuPerfCount" class="ah2">Sampled perf counters for the instance: '+ convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'

select '<table>'
select '<tr><th>Object</th><th>Counter</th><th>Rate/Sec</th></tr>'
;with dopc as (
select b.object_name, b.counter_name, b.instance_name, e.cntr_value-b.cntr_value diff_value
from #dopc_begin b 
join #dopc_end e
on b.object_name = e.object_name and b.counter_name = e.counter_name and b.instance_name = e.instance_name
)
select '<tr>' +
       '<td>' + rtrim(substring(object_name,charindex(':',object_name)+1,30)) + '</td>' +
       '<td>' + rtrim(counter_name) +  
                case when instance_name = '_Total' then ' (' + rtrim(instance_name) + ')'
                     else ''
                end + '</td>' +
       '<td class="aligncenter" >' + convert(varchar,diff_value) + '</td>'
from dopc
where  diff_value > 0
and (
	   (object_name like '%Access Methods%') -- and counter_name in ('Full Scans/sec','Index Searches/sec','Page Deallocations/sec','Page Splits/sec','Pages Allocated/sec','Probe Scans/sec','Range Scans/sec','Table Lock Escalations/sec '))
    or (object_name like '%Buffer Manager%') -- and counter_name in ('%Checkpoint pages/sec%','%Lazy writes/sec%','%Page lookups/sec%','%Page reads/sec%','%Page writes/sec%','%Readahead pages/sec%'))
    or (object_name like '%General statistics%')
    or (object_name like '%Latches%')
    or (object_name like '%Latches%')
    or (object_name like '%Locks%')
    or (object_name like '%SQL Statistics%')
    or (object_name like '%Databases%')
    )
;                                                                                               
select '</table>'

select '<a href="#Topic"> Back to Topic</a><br />'

/* DatabaseInfo part */
select '<br /><a name="MiscInfo" class="ah1">Miscellaneous Information:</a><br />'

/*********************************************************************************************/
/* Displaying Database Properties information                                                */
/*                                                                                           */
/*********************************************************************************************/

select '<a name="DatabaseProperties" class="ah2">Properties for the databases on SQL Server instance: '+ convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
select '<table>'
select '<tr><th>Database Name</th><th>User Access</th><th>Open Mode</th><th>Database State</th><th>Recovery Model</th><th>Snapshot Isolation State</th><th>Read Committed Snapshot</th>' +
       '<th>Auto Close</th><th>Auto Shrink</th><th>Auto Create Stats</th><th>Auto Update Stats</th><th>Auto Update Stats Async</th><th>Full Text Enabled</th><th>Compability Level</th><th>Collation Name</th><th>Page Verification</th></tr>'
select '<tr>' + 
       '<td>' + master.dbo.MO_GetShortName(name,25) + '</td>' +
       '<td>' + case
                  when user_access = 0 then 'Multi'
                  when user_access = 1 then 'Single'
                  when user_access = 2 then 'Restricted'
               end + '</td>' +
      '<td>' + case
                 when is_read_only = 0 then 'Read Write'
                 when is_read_only = 1 then 'Read Only'
               end + '</td>' +
      '<td>' + case
                 when state = 0 then 'Online'
                 when state = 1 then 'Restoring'
                 when state = 2 then 'Recovering'
                 when state = 3 then 'Recovery Pending'
                 when state = 4 then 'Suspect'
                 when state = 5 then 'Emergency'
                 when state = 6 then 'Offline'
               end + '</td>' +
       '<td>' + case
                  when recovery_model = 1 then 'Full'
                  when recovery_model = 2 then 'Bulk Logged'
                  when recovery_model = 3 then 'Simple'
               end + '</td>' +
       '<td>' + case
                  when snapshot_isolation_state = 0 then 'Off'
                  when snapshot_isolation_state = 1 then 'On'
                  when snapshot_isolation_state = 2 then 'In Transition to On'
                  when snapshot_isolation_state = 3 then 'In Transition to Off'
               end + '</td>' +
       '<td>' + case
                  when is_read_committed_snapshot_on = 0 then 'Off'
                  when is_read_committed_snapshot_on = 1 then 'On'
               end + '</td>' +
      '<td>' +  case
                  when is_auto_close_on = 0 then 'False'
                  when is_auto_close_on = 1 then '<font color="#FF0000">True</font>'
                end + '</td>' +
      '<td>' + case
                 when is_auto_shrink_on = 0 then 'False'
                 when is_auto_shrink_on = 1 then '<font color="#FF0000">True</font>'
               end + '</td>' +
      '<td>' + case
                 when is_auto_create_stats_on = 0 then 'False'
                 when is_auto_create_stats_on = 1 then 'True'
               end + '</td>' +
      '<td>' + case
                 when is_auto_update_stats_on = 0 then 'False'
                 when is_auto_update_stats_on = 1 then 'True'
               end + '</td>' +
	  '<td>' + case
                 when is_auto_update_stats_async_on = 0 then 'False'
                 when is_auto_update_stats_async_on = 1 then 'True'
               end + '</td>' +
      '<td>' + case
                 when is_fulltext_enabled = 0 then 'False'
                 when is_fulltext_enabled = 1 then 'True'
               end + '</td>' +
      '<td>' + convert(varchar(3),compatibility_level) + '</td>' +
      '<td>' + collation_name + '</td>' +
      '<td>' + case
                 when page_verify_option = 0 then 'None'
                 when page_verify_option = 1 then 'Torn Page Detection'
                 when page_verify_option = 2 then 'Checksum'
               end + '</td>' +
              '</tr>'
from sys.databases
go
select '</table>'
select '<a href="#Topic"> Back to Topic</a><br />'
go

/*********************************************************************************************/
/* Information of configuration values for the SQL Server instance                           */
/*                                                                                           */
/*********************************************************************************************/
select '<br />'

select '<a name="ConfValues" class="ah2">Configuration values for SQL Server instance: '+ convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'

DECLARE @config_defaults TABLE (
    name nvarchar(35),
    default_value sql_variant
)
 
INSERT INTO @config_defaults (name, default_value) VALUES ('access check cache bucket count',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('access check cache quota',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('Ad Hoc Distributed Queries',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('affinity I/O mask',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('affinity mask',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('affinity64 I/O mask',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('affinity64 mask',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('Agent XPs',1)
INSERT INTO @config_defaults (name, default_value) VALUES ('allow updates',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('awe enabled',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('backup compression default',0) 
INSERT INTO @config_defaults (name, default_value) VALUES ('blocked process threshold', 0)
INSERT INTO @config_defaults (name, default_value) VALUES ('blocked process threshold (s)',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('c2 audit mode',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('clr enabled',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('common criteria compliance enabled',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('contained database authentication',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('cost threshold for parallelism',5) 
INSERT INTO @config_defaults (name, default_value) VALUES ('cross db ownership chaining',0) 
INSERT INTO @config_defaults (name, default_value) VALUES ('cursor threshold',-1)
INSERT INTO @config_defaults (name, default_value) VALUES ('Database Mail XPs',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('default full-text language',1033)
INSERT INTO @config_defaults (name, default_value) VALUES ('default language',0) 
INSERT INTO @config_defaults (name, default_value) VALUES ('default trace enabled',1)
INSERT INTO @config_defaults (name, default_value) VALUES ('disallow results from triggers',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('EKM provider enabled',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('filestream access level',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('fill factor (%)',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('ft crawl bandwidth (max)',100)
INSERT INTO @config_defaults (name, default_value) VALUES ('ft crawl bandwidth (min)',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('ft notify bandwidth (max)',100)
INSERT INTO @config_defaults (name, default_value) VALUES ('ft notify bandwidth (min)',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('index create memory (KB)',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('in-doubt xact resolution',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('lightweight pooling',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('locks',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('max degree of parallelism',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('max full-text crawl range',4)
INSERT INTO @config_defaults (name, default_value) VALUES ('max server memory (MB)',2147483647)
INSERT INTO @config_defaults (name, default_value) VALUES ('max text repl size (B)',65536)
INSERT INTO @config_defaults (name, default_value) VALUES ('max worker threads',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('media retention',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('min memory per query (KB)',1024)
INSERT INTO @config_defaults (name, default_value) VALUES ('min server memory (MB)',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('nested triggers',1)
INSERT INTO @config_defaults (name, default_value) VALUES ('network packet size (B)',4096)
INSERT INTO @config_defaults (name, default_value) VALUES ('Ole Automation Procedures',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('open objects',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('optimize for ad hoc workloads',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('PH timeout (s)',60)
INSERT INTO @config_defaults (name, default_value) VALUES ('precompute rank',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('priority boost',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('query governor cost limit',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('query wait (s)',-1)
INSERT INTO @config_defaults (name, default_value) VALUES ('recovery interval (min)',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('remote access',1)
INSERT INTO @config_defaults (name, default_value) VALUES ('remote admin connections',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('remote login timeout (s)',20)
INSERT INTO @config_defaults (name, default_value) VALUES ('remote proc trans',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('remote query timeout (s)',600)
INSERT INTO @config_defaults (name, default_value) VALUES ('Replication XPs',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('scan for startup procs',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('server trigger recursion',1)
INSERT INTO @config_defaults (name, default_value) VALUES ('set working set size',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('show advanced options',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('SMO and DMO XPs',1)
INSERT INTO @config_defaults (name, default_value) VALUES ('SQL Mail XPs',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('transform noise words',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('two digit year cutoff',2049)
INSERT INTO @config_defaults (name, default_value) VALUES ('user connections',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('user options',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('Web Assistant Procedures',0)
INSERT INTO @config_defaults (name, default_value) VALUES ('xp_cmdshell',0)

select '<br />NOTE: SQL Server may change the min server memory value "in flight" in some environments so it may commonly show up as being "non default"!<br />' 
select '<table>'
select '<tr><th>Parameter name</th><th>Value / Value in use</th><th>Default Value</th><th>Min / Max Value</th><th>Parameter type</th><th>Advanced</th><th>Description</th></tr>'
select '<tr>' +
       '<td>' + c.name + '</td>' +
       '<td ' + case
                  when c.value != c.value_in_use OR (c.value_in_use != d.default_value) then 
                    'class="warn" >' + convert(varchar,c.value) + ' / ' + convert(varchar,value_in_use)
                  else 'class="aligncenter" >' + convert(varchar, c.value_in_use)
                end + '</td>' +
       '<td class="aligncenter" >' + convert(varchar,d.default_value) + '</td>' +
       '<td class="aligncenter" >' + cast( c.minimum as varchar(30)) + ' / ' + cast( c.maximum as varchar(30)) + '</td>' +
       '<td>' + case 
                  when c.is_dynamic = 1 then 'Dynamic'
                  when c.is_dynamic = 0 then 'Static'
                end + '</td>' +
       '<td>' + case
                  when c.is_advanced = 1 then 'Yes'
                  when c.is_advanced = 0 then 'No'
                end +  '</td>' +
       '<td>' + c.description + '</td>' +
       '</tr>'
from sys.configurations c
left outer JOIN @config_defaults d ON c.name = d.name
order by c.name
select '</table>'
go

select '<a href="#Topic"> Back to Topic</a><br />'  

select '<h2> SQL Server check executed in ' + convert(varchar,DATEDIFF(minute,'19000101', getdate() - convert(datetime,Value,120))) + ' minutes</h2>' from #MORLT where Name = 'starttime'
select '<p class="alignright"> Miracle Online SQL Server report, version ' + Value + '</p>' from #MORLT where Name = 'sqlserver_check_version';
select '</body></html>'
go

/*****************************************************************************/
/** End of sqlserver.sql                                                    **/
/*****************************************************************************/

--:setvar Instance (select @@servicename)
:setvar Ext ".html" 
:setvar Dash "_"
:setvar Slash "\"
:setvar Errorlogname "ErrorLog"
--:setvar OutputType "Errorlog"

:OUT $(Log_Dir)$(Slash)$(DateStamp)$(Dash)$(COMPUTERNAME)$(Dash)$(INSTANCE_NAME)$(Dash)$(Errorlogname)$(Ext)

select '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" ' +
       '"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'

select '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en"> '
select '<head>'
select '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />'
select '<meta name="generator" content="SQL Server Report " />'
select '<style type="text/css"> 
          body {font:10pt Arial,Helvetica,sans-serif; color:black; background:White;} 
          p {font:10pt Arial,Helvetica,sans-serif; color:black; background:White;} 
          p.alignright {text-align:right;}
		  ul.list{ list-style-type:none; }          
          table {width:100%}
          table,tr,td {font:10pt Arial,Helvetica,sans-serif; color:Black; background:#ffffcc; padding:0px 0px 0px 0px; margin:0px 0px 0px 0px; border-style:inset;border-width:1px;} 
		  tr.topiccell { vertical-align:top;  }
          td.ok { background:#33CC66; text-align:center;}
          td.disabledok { text-align:left; }
          td.warn { background:#ffff66; text-align:center; }
          td.disabledwarn { text-align:left; }
          td.error { background:#cc3300; text-align:center; }
		  td.failed { color:Red }
          td.disablederror { text-align:left; }
          td.alignleft { text-align:left;}
          td.aligncenter {text-align:center;}
          td.alignright {text-align:right;}        
	      td.ignore { background:#999999; text-align:center; }
	      td.disabledignore { text-align:left; }
          td.sumcell { text-align:right; font-weight:bold;}
		  th.width2 { width:"2%"}
          th.width10 { width:"10%"}
		  th.width20 { width:"20%"}
		  th.width40 { width:"40%"}
          th {font:bold 10pt Arial,Helvetica,sans-serif; color:#336699; background:#cccc99; padding:0px 0px 0px 0px; border-style:inset;border-width:1px;} 
          h1 {font:bold 16pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; border-bottom:1px solid #cccc99; margin-top:0pt; margin-bottom:0pt; padding:0px 0px 0px 0px;} 
          h2 {font:bold 10pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; margin-top:4pt; margin-bottom:0pt;} 
          a {font:9pt Arial,Helvetica,sans-serif; color:#663300; background:#ffffcc; margin-top:10pt; margin-bottom:0pt; vertical-align:top;}
          a.substr {font:10pt Arial,Helvetica,sans-serif; color:#0000cc; background:#ffffcc; margin-top:10pt; margin-bottom:0pt; vertical-align:top;}
		  .ah1 {font:bold 14pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; margin-top:50pt; margin-bottom:20pt;}
          .ah2 {font:bold 10pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; margin-top:10pt; margin-bottom:0pt;}
          .center {text-align:center;} 
        </style>
        <title>SQL Server Report for ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</title>'
select '</head>';

select '<body>'
select '<h1>Miracle SQL Server Errorlog Report for instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</h1><br />' +
       '<h2> Check executed at: ' +  Value + '</h2>'
from #MORLT where Name = 'starttime';
select '<p class="alignright"> Miracle Online SQL Server report, version ' + Value + '</p>' from #MORLT where Name = 'sqlserver_check_version';

declare @latest_online_check datetime
set @latest_online_check = getdate() - (select convert(int,Value) from #MORLT where Name = 'latest_online_check')

update #Mir_Col_Errorlog set LogDate = convert(datetime,convert(varchar, LogDate, 120),120)

select '<table>'
select '<tr><th>Log Date</th><th>Error Text</th></tr>'

;with error (LogDate, no, errortext) as (
select O.LogDate as LogDate, count(*) no
       ,STUFF((
         select '  ' + [Source] + ': ' + [Error_text] + '<br />'
         from #Mir_Col_Errorlog
         where (LogDate = O.LogDate)
		 and LogDate > @latest_online_check
		 --order by LogDate
         for xml path (''), TYPE ).value('.','VARCHAR(MAX)') , 1, 2, '') as NM
     /* Use .value to uncomment XML entities e.g. &gt; &lt; etc*/
from #Mir_Col_Errorlog O
--where NM is not null
group by O.LogDate
)
select '<tr>' + 
       '<td>' + convert(char, LogDate, 13) + '</td>' +
       '<td>' + errortext + '</td>' +
       '</tr>'
from error
where errortext is not null
and ((errortext like '%Error%') or (errortext like '%Failure%'))
and errortext not like '%Logon%'
and errortext not like '%finished without errors%'
and errortext not like '%ERRORLOG%'
and errortext not like '%found 0 errors and repaired 0 errors%'
and errortext not like '%Database:%error%'
order by LogDate;

select '</table>'

select '</body>'  
go  

