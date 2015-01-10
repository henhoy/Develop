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
** $HeadURL: http://10.42.42.9/onlinecheck/SQLServer/trunk/sqlserver.sql $
** $Date: 2012-09-21 08:17:26 +0200 (fr, 21 sep 2012) $
** $Revision: 398 $
***********************************************************************************************/

set nocount on
SET LOCK_TIMEOUT 10000
set arithabort on
set ansi_warnings on
SET QUOTED_IDENTIFIER ON

/*** Set (override) command line parameters ***/

:setvar SQLCMDHEADERS -1
:setvar SQLCMDERRORLEVEL 5
:setvar SQLCMDCOLWIDTH 1400
:setvar SQLCMDMAXVARTYPEWIDTH 3800
--:setvar SQLCMDMAXFIXEDTYPEWIDTH 3500

/*** Create a few helper functions **/

create table #MORLT (
Name  varchar(50),
Value varchar(100)
)

/* Insert SQL Server check version */
insert into #MORLT values ('sqlserver_check_version','1.4');
/* Insert SQL Server version */
insert into #MORLT select 'sqlserver_version', convert(varchar(2),PARSENAME(CONVERT(VARCHAR(100),SERVERPROPERTY('ProductVersion')),4));
/* Insert default daysback value for latest online check */
insert into #MORLT values ('latest_online_check','20');
/* Insert default minimum value for defragmented pages */
insert into #MORLT values ('min_defrag_pages','2500');
/* Insert default run of index fragmentation scan value */
insert into #MORLT values ('run_defrag_index','YES');

declare @starttime varchar(40);
select @starttime = convert(varchar,getdate(),120)
insert into #MORLT values ('starttime',@starttime);

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
select '<p class="alignright"> Miracle Online SQL Server report, version ' + Value + '</p>' from #MORLT where Name = 'sqlserver_check_version';



/*********************************************************************************************/
/* Errorlog information                                                                      */
/*                                                                                           */
/*********************************************************************************************/
declare @archno tinyint
declare @count tinyint
declare @latest_online_check datetime
declare @NumErrorLogs int
declare @ErrorLog varchar(255)
declare @logdate datetime

-- set @latest_online_check = (select latest_online_check from [miracle_online].[dbo].[Miracle_Online_Info])
set @latest_online_check = getdate() - (select convert(int,Value) from #MORLT where Name = 'latest_online_check')

create table #tbl_enumerrorlogs (ArchiveNo int, CreateDate datetime, Size int)
insert into #tbl_enumerrorlogs EXEC master.dbo.xp_enumerrorlogs 

select @logdate = case
         when @latest_online_check < min(CreateDate) then min(CreateDate)
         else (select max(CreateDate) from #tbl_enumerrorlogs where CreateDate < @latest_online_check)
       end
from #tbl_enumerrorlogs

set @archno = (select min(ArchiveNo) from #tbl_enumerrorlogs where CreateDate <= @logdate)

create table #Mir_Col_Errorlog (LogDate datetime, Source nvarchar(35), Error_text nvarchar(1024))
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
select '<a name="ErrorlogInfo" class="ah2">Errorlog info for database instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'

-- Table with basic errorlog information

/*
select '<table>'
select '<tr><th>Path to Errorlog</th><th>Configured number of Errorlogs</th></tr>'
select '<tr><td>' + @ErrorLog + '</td><td  align="center">' + convert(sysname, ISNULL(@NumErrorLogs, -1)) + '</td></tr>'
select '</table>'

-- Table with errorlog contents
select '<table>'
select '<tr><th>Log Date</th><th>Error Source</th><th>Error Text</th></tr>'
    
select '<tr>' + 
       '<td>' + convert(char, LogDate, 13) + '</td>' +
       '<td>' + Source + '</td>' +
       '<td>' + Error_text + '</td>' +
       '</tr>'
from #Mir_Col_Errorlog 
where Error_text like '%Error:%'  
and Source not like 'Logon'
and LogDate > @latest_online_check
order by LogDate
select '</table>'
*/

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

select '</body>'


:Out Errorlog.html


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
select '</head>'

select '<body>'

select '<table>'
select '<tr><th>Log Date</th><th>Error Text</th></tr>'

update #Mir_Col_Errorlog set LogDate = convert(datetime,convert(varchar, LogDate, 120),120)

;with error (logdate, no, errortext) as (
select O.LogDate as logdate, count(*) no
       ,STUFF((
         select '  ' + [Source] + ': ' + [Error_text] + '<br />'
         from #Mir_Col_Errorlog
         where (LogDate = O.LogDate)
		 order by LogDate
         for xml path (''), TYPE ).value('.','VARCHAR(MAX)') , 1, 2, '') as NM
     /* Use .value to uncomment XML entities e.g. &gt; &lt; etc*/
from #Mir_Col_Errorlog O
--where NM is not null
group by O.LogDate
)
select '<tr>' + 
       '<td>' + convert(char, logdate, 13) + '</td>' +
       '<td>' + errortext + '</td>' +
       '</tr>'
from error
where errortext is not null
and ((errortext like '%Error%') or (errortext like '%Failure%'))
and errortext not like '%Logon%'
and errortext not like '%finished without errors%'
and errortext not like '%ERRORLOG%'
and errortext not like '%found 0 errors and repaired 0 errors%'
order by logdate;

select '</table>'

select '</body>'







