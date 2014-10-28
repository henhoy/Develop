/***********************************************************************************************
**                                                                                             
** Miracle Online, SQL Server script for SQL Server version 2000
**
** Collect info regarding SQL Server 2000
**
** How to invoke:
** osql -S <connectstring> -E -w 1200 -h-1 -n -i sqlserver.sql -o sqlserver.htm
**
** -S	<server>\<instance> or <instance> (if default instance)
** -E	Connect with OS privilegies alt. -U <user> -P <password
** -h-1	No headers
** -n	Remove numbering
** -i   Input script (this one)
** -o   Output htm file
**
** Created 20090922, HMH/Miracle A/S: Ver. 0.1  This script is based on sql server 2005
**                                              Script version 0.9 revision 8.
**                                              Compared to the original version, then
**                                              ErrorLog summation and SQL Server configuration
**                                              values are removed
** Modified 20091116, HMH/Miracle A/S: Ver. 0.2 Added database properties information
**                                              Added summering on database files (mdf)
**                                              Added next run date in job schedule info
**                                              Fixed bug when handling databases in BULK mode
** Modified 20091202, HMH/Miracle A/S: Ver. 0.3 Fixed output of database properties
**                                              Added Log space information
** Modified 20100224, HMH/Miracle A/S: Ver. 0.4 Added new backup "Point of View"
** Modified 20101228, HMH/Miracle A/S: Ver. 0.5 Fixed bug in sqlserver log handling
**                                              Fixed bug in displaying backup statistics
**
***********************************************************************************************/

set nocount on
SET LOCK_TIMEOUT 10000

declare @@sqlserver_check_version varchar(10)
select @@sqlserver_check_version = '0.5';

select '<html>'
select '<head>'
select '<meta http-equiv="Content-Type" content="text/html; charset=WINDOWS-1252">'
select '<meta name="generator" content="SQL Server Report ">'
select '<style type="text/css"> 
          body {font:10pt Arial,Helvetica,sans-serif; color:black; background:White;} 
          p {font:10pt Arial,Helvetica,sans-serif; color:black; background:White;} 
          table,tr,td {font:10pt Arial,Helvetica,sans-serif; color:Black; background:#f7f7e7; padding:0px 0px 0px 0px; margin:0px 0px 0px 0px;} 
          th {font:bold 10pt Arial,Helvetica,sans-serif; color:#336699; background:#cccc99; padding:0px 0px 0px 0px;} 
          h1 {font:16pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; border-bottom:1px solid #cccc99; margin-top:0pt; margin-bottom:0pt; padding:0px 0px 0px 0px;} 
          h2 {font:bold 10pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; margin-top:4pt; margin-bottom:0pt;} 
          a {font:9pt Arial,Helvetica,sans-serif; color:#663300; background:#ffffff; margin-top:0pt; margin-bottom:0pt; vertical-align:top;}
        </style>
        <title>SQL Server 2000 Report for ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</title>'
select '</head>'

select '<body>'
select '<h1>Miracle SQL Server Report for instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</h1><br>'
select '<p align="right"> Miracle Online SQL Server 2000 report, version ' + @@sqlserver_check_version + '</p>'

/*********************************************************************************************/
/* Internal links                                                                            */
/*                                                                                           */
/*********************************************************************************************/
select '<p>'
select '<a name="#Topic"><h2>Topic</h2></a>'
select '<table width="100%" border="1" background="#ffffff">'
select '<tr>'
select '<td><a href="#InstanceProperties"> Instance & License Properties </a></td>'
select '<td><a href="#JobInfo"> Job Information </a></td>'
select '<td><a href="#BackupInfo"> Backup Information </a></td>'
select '<td><a href="#BackupStatFull">Full backup Statistics </a></td>'
select '<td><a href="#BackupStatInc">Incremental backup Statistics </a></td>'
select '<td><a href="#BackupStatTrans">Transactionlog backup Statistics </a></td>'
select '<td><a href="#SpaceInfo"> Data space Information </a></td>'
select '<td><a href="#LogSpaceInfo"> Log space Information </a></td>'
select '<td><a href="#ErrorlogInfo"> Errorlog Information </a></td>'
select '<td><a href="#Databaseproperties"> Database Properties </a></td>'
select '</tr>'
select '</table>'
select '</p>'

/*********************************************************************************************/
/* Instance properties and licens information                                                */
/*                                                                                           */
/*********************************************************************************************/

select '<a name="InstanceProperties"><h2>SQL Server Properties for instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</h2></a>'
select '<table width="100%" border="1">'
select '<tr><th>Server \ Instance Name</th><th>Product Version</th><th>Product Level</th><th>Edition</th><th> Engine Edition</th></tr>'
select '<tr>' +
       '<td>' + convert(sysname,SERVERPROPERTY('ServerName')) + '</td>' +
       '<td>' + convert(sysname,SERVERPROPERTY('ProductVersion')) + '</td>' +
       '<td>' + convert(sysname,SERVERPROPERTY ('ProductLevel')) + '</td>' +
       '<td>' + convert(sysname,SERVERPROPERTY ('Edition')) + '</td>' +
       '<td>' + convert(sysname,SERVERPROPERTY ('EngineEdition')) + '</td>'
select '</table><br>'
go

select '<h2> SQL Server License Properties for instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</h2>'
select '<table width="100%" border="1">'
select '<tr><th>Lisence Type</th><th>Number og Licenses</th><th>Cluster configuration</th><th>Full Text Installed</th></tr>'
select '<tr>' +
       '<td>' + convert(sysname,SERVERPROPERTY('LicenseType')) + '</td>' +
       '<td>' +  case 
                   when SERVERPROPERTY('NumLicenses') is null then 'N/A'
                   else convert(sysname,SERVERPROPERTY('NumLicenses'))
                 end + '</td>' +
       '<td>' +  case
                   when SERVERPROPERTY ('IsClustered') = 0 then 'Not Clustered'
                   when SERVERPROPERTY ('IsClustered') = 1 then 'Clustered'
                 end + '</td>' +
       '<td>' +  case
                   when SERVERPROPERTY ('IsFullTextInstalled') = 0 then 'Full-text installed'
                   when SERVERPROPERTY ('IsFullTextInstalled') = 1 then 'Full-text is not installed'
                 end + '</td>'
select '</table>'
select '<a href="#Topic"> Back to Topic</a><br>'
go

/*********************************************************************************************/
/* Collect job information                                                                   */
/*                                                                                           */
/*                                                                                           */
/*********************************************************************************************/
use msdb
go

select '<a name="#JobInfo"><h2>Jobs @ SQL Server Agent for database instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</h2></a>'
select '<table width="100%" border="1">'
select '<tr><th>Job Name</th><th>Job status</th><th>Last runtime</th><th>Last result</th><th>Next runtime</th></tr>'

select '<tr>' +
       '<td>' + sj.name + '</td>' +
       '<td>' + case 
                  when sj.enabled = 0 then 'Not Enabled'
                  when sj.enabled = 1 then 'Enabled'
                end + '</td>' + 
       '<td>' + case
                  when sjs.last_run_date = 0 then 'No Run'
                  else rtrim(cast(last_run_date as char)) + ' - ' + replicate('0',6-datalength(rtrim(cast(last_run_time as char)))) + rtrim(cast(last_run_time as char))
                end + '</td>' +
       '<td>' + case 
                  when sjs.last_run_outcome = 0 then 'Failed'
                  when sjs.last_run_outcome = 1 then 'Successfull'
                  when sjs.last_run_outcome = 3 then 'Canceled'
                  else 'Undefined outcome'
                end + '</td>' +
       '<td>' + case
                  when sjsch.next_run_date = 0 then 'No Schedule'
                  else rtrim(cast(next_run_date as char)) + ' - ' + replicate('0',6-datalength(rtrim(cast(next_run_time as char)))) + rtrim(cast(next_run_time as char))
                end + '</td>' +
       '</tr>'
from dbo.sysjobs sj, dbo.sysjobservers sjs, dbo.sysjobschedules sjsch
where sj.job_id = sjs.job_id
and sj.job_id = sjsch.job_id
order by sj.name
go
select '</table>'
go
select '<a href="#Topic"> Back to Topic</a><br>'

/*********************************************************************************************/
/* Collect backup information                                                                */
/*                                                                                           */
/*                                                                                           */
/*********************************************************************************************/
select '<a name="#BackupInfo"><h2>Latest backup info for database instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</h2></a>'
select '<table width="100%" border="1">'
go
select '<tr><th>Database Name</th><th>Created</th><th>Recovery Model</th><th>Status</th><th>Latest db backup</th><th>Latest Inc backup</th><th>Latest log backup</th></tr>'

select '<tr>' +
       '<td>' + c.name + '</td>' + 
       '<td>' + convert(char(8), c.crdate,3) + '</td>' +
       '<td align="left">' + convert(sysname,DatabasePropertyEX(c.name,'Recovery')) + '</td>' +
       '<td align="left">' + convert(sysname,DatabasePropertyEX(c.name,'Status')) + '</td>' +
       '<td align="left">' + 
                case 
                  when a.latest_db_backup IS NULL then '<font color="#FF0000">No Backup</font>' 
                  else convert(char, a.latest_db_backup, 13) 
                end + '</td>' +
       '<td align="left">' + 
                case 
                  when d.latest_db_backup IS NULL then 'No Inc. Backup</font>' 
                  else convert(char, d.latest_db_backup, 13) 
                end + '</td>' +
       '<td align="left">' + 
                case 
                  when b.latest_log_backup IS NULL -- DB_option=FULL, log_bck=never
                    AND convert(sysname,DatabasePropertyEX(c.name,'Recovery')) = 'FULL'  then '<font color="#FF0000">No Backup</font>' 
                  when b.latest_log_backup IS NULL -- DB_option=SIMPLE, log_bck=never
                    AND convert(sysname,DatabasePropertyEX(c.name,'Recovery')) = 'SIMPLE'  then 'Not Applicable' 
                  when b.latest_log_backup IS NULL -- DB_option=BULK_LOGGED, log_bck=never
                    AND convert(sysname,DatabasePropertyEX(c.name,'Recovery')) = 'BULK_LOGGED'  then '<font color="#FF0000">WARNING BULK-LOGGED!</font>' 
                  else convert(char, b.latest_log_backup, 13) 
                end + '</td>' +
       '</tr>'
from   ((select server_name, database_name, max(backup_finish_date) latest_db_backup
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
       right outer join
       master.dbo.sysdatabases c
       on a.database_name = c.name
       where lower(c.name) != 'tempdb'
       order by c.name
go
select '</table>'
select '<a href="#Topic"> Back to Topic</a><br>'


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
  order by b_type, bf_date
declare @backupinfo varchar(4000)
declare @id int
declare @b_type char(1)
declare @bf_date char(11)

open backup_info
fetch backup_info into @id, @b_type, @bf_date

select '<table>'
select '<tr><th>Backup info</th></tr>'

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
                                 + ' backup finished at ' + @bf_date + ' for the following databases: ' + @backupinfo
  select '<tr><td>' + @backupinfo + '</td></tr>'
  fetch backup_info into @id, @b_type, @bf_date
end
select '</table>'
go
deallocate backup_info
select '<a href="#Topic"> Back to Topic</a><br />'

/*********************************************************************************************/
/* Collect backup Statistics information for full backup's                                   */
/*                                                                                           */
/*                                                                                           */
/*********************************************************************************************/
select '<a name="#BackupStatFull"><h2>Full backup statistics for the periode "'+convert(char, getdate()-30,3)+'" to "'+convert(char, getdate(),3)+'" for instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</h2></a>'
select '<table width="100%" border="1">'
go
select '<tr><th>Database Name</th>' +
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

select '<td>' + database_name + '</td>' + 
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-30, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-29, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-28, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-27, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-26, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-25, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-24, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-23, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-22, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-21, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-20, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-19, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-18, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-17, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-16, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-15, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-14, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-13, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-12, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-11, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-10, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-9, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-8, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-7, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-6, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-5, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-4, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-3, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-2, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-1, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate(), 10) then 1 else 0 end )) + '</td></tr>'
from backupset
where type = 'D'
and backup_finish_date > getdate()-31
group by database_name

select '</table>'
go
select '<a href="#Topic"> Back to Topic</a><br>'

/*********************************************************************************************/
/* Collect backup Statistics information for incremental backup's                            */
/*                                                                                           */
/*                                                                                           */
/*********************************************************************************************/
select '<a name="#BackupStatInc"><h2>Incremental backup statistics for the periode "'+convert(char, getdate()-30,3)+'" to "'+convert(char, getdate(),3)+'" for instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</h2></a>'
select '<table width="100%" border="1">'
go
select '<tr><th>Database Name</th>' +
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

select '<td>' + database_name + '</td>' + 
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-30, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-29, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-28, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-27, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-26, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-25, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-24, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-23, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-22, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-21, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-20, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-19, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-18, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-17, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-16, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-15, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-14, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-13, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-12, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-11, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-10, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-9, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-8, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-7, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-6, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-5, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-4, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-3, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-2, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-1, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate(), 10) then 1 else 0 end )) + '</td></tr>'
from backupset
where type = 'I'
and backup_finish_date > getdate()-31
group by database_name

select '</table>'
go
select '<a href="#Topic"> Back to Topic</a><br>'


/*********************************************************************************************/
/* Collect backup Statistics information for Tranactionlog backup's                          */
/*                                                                                           */
/*                                                                                           */
/*********************************************************************************************/
select '<a name="#BackupStatTrans"><h2>Transaction log backup statistics for the periode "'+convert(char, getdate()-30,3)+'" to "'+convert(char, getdate(),3)+'" for instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</h2></a>'
select '<table width="100%" border="1">'
go
select '<tr><th>Database Name</th>' +
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

select '<td>' + database_name + '</td>' + 
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-30, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-29, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-28, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-27, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-26, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-25, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-24, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-23, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-22, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-21, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-20, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-19, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-18, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-17, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-16, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-15, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-14, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-13, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-12, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-11, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-10, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-9, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-8, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-7, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-6, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-5, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-4, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-3, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-2, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate()-1, 10) then 1 else 0 end )) + '</td>' +
'<td>' + convert(char,sum( case when convert(char(5), backup_finish_date, 10) = convert(char(5), getdate(), 10) then 1 else 0 end )) + '</td></tr>'
from backupset
where type = 'L'
and backup_finish_date > getdate()-31
group by database_name

select '</table>'
go
select '<a href="#Topic"> Back to Topic</a><br>'


/*********************************************************************************************/
/* Collect database space information (0nly *.mdf & *.ndf)                                   */
/*                                                                                           */
/*********************************************************************************************/

declare @name                 nvarchar(100)
declare @dbid                 int
declare @exec_stmt            varchar(1600)
 
create table #space_info
(
  DatabaseName                varchar(100) null,
  FileGroupName               varchar(120) null,
  Name                        varchar(120) null,
  FileName                    varchar(250) null,
  SizeKB                      dec(15) null,
  UsedKB                      dec(15) null,
  FreeKB                      dec(15) null,
  MaxSizeKB                   dec(15) null,
  pctfree                     dec(15) null,
  status                      int null,
  growth                      int null
)

declare dbname_crr cursor for 
  select name, dbid from master.dbo.sysdatabases

open dbname_crr
fetch dbname_crr into @name, @dbid

while @@fetch_status >= 0
begin
  if convert(sysname,DatabasePropertyEX(@name,'Status')) != 'OFFLINE' AND convert(sysname,DatabasePropertyEX(@name,'Status')) != 'RESTORING'
    begin
      set @exec_stmt = 'use ' + quotename(@name, N'[') +
        'insert into #space_info (DataBaseName, FileGroupName, Name, FileName, SizeKB, UsedKB, FreeKB, MaxSizeKB, PctFree, status, growth) ' +
        'select ''' + @name + ''', fg.groupname, f.name, f.filename, f.size*8 , fileproperty(name, ''spaceused'')*8,
           f.size*8 - fileproperty(name, ''spaceused'')*8,
           maxsize,
           100 - (fileproperty(name, ''spaceused'')*8) / (cast(size as decimal(15))*8) * 100,
           f.status, f.growth
        from sysfiles as f, sysfilegroups as fg ' + 
        'where f.groupid = fg.groupid' -- and current of dbname_crr'
      --select @exec_stmt
      execute (@exec_stmt)
    end
  else
    begin
      insert into #space_info values (@name, 'DB OFFLINE', 'Unknown', 0, 0, 0, 0, 0, 0, 0, 0)
    end
  
  fetch dbname_crr into @name, @dbid
end

deallocate dbname_crr

    select '<a name="#SpaceInfo"><h2>Space info for database instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</h2></a>'
    select '<table width="100%" border="1">'
    select '<tr><th>Database Name</th><th>Filegroup Name</th><th>Name</th><th>File Name</th><th>Size MB</th>' + 
           '<th>Used MB</th><th>Free MB</th><th>Maxsize MB</th><th> % Free</th><th>Growth</th></tr>'
    
    select '<tr>' +
           '<td>' + DataBaseName + '</td>' +
           '<td>' + FileGroupName + '</td>' +
           '<td>' + Name + '</td>' +
           '<td>' + FileName + '</td>' +
           '<td align="right">' + cast(cast(SizeKB/1024 as decimal(10,2)) as char) + '</td>' +
           '<td align="right">' + cast(cast(UsedKB/1024 as decimal(10,2)) as char) + '</td>' +
           '<td align="right">' + cast(cast(FreeKB/1024 as decimal(10,2)) as char) + '</td>' +
           '<td align="right">' + case 
                      when MaxSizeKB = -1 then 'Unlimited' 
                      else cast(cast(MaxSizeKB*8/1024 as decimal(10,2)) as char)  
                    end + '</td>' +
           '<td align="center">' + cast(PctFree as char) + '</td>' +
           '<td>' + case
                      when (status & 0x100000) = 0x100000 then 'by ' + cast(growth as varchar(2)) + '%'
                      when (status & 0x2) = 0x2 then 'by ' + cast(growth*8192/1048576 as varchar(100)) + 'MB'
                      when (status & 0x40) = 0x40 then 'by ' + cast(growth*8192/1048576 as varchar(100)) + 'MB'
                      else 'NULL'
                    end + '</td></tr>'
    from #space_info
    order by DataBaseName
-- Generating sum information    
    select '<tr><td><b>Sum of MDF files</b></td><td></td><td></td><td></td>' + 
           '<td align="right"><b>'+ cast(cast(sum(SizeKB)/1024 as decimal(10,2)) as char)+'</b></td>' +
           '<td align="right"><b>'+ cast(cast(sum(UsedKB)/1024 as decimal(10,2)) as char)+'</b></td>' +
           '<td align="right"><b>'+ cast(cast(sum(FreeKB)/1024 as decimal(10,2)) as char)+'</b></td>' +
           '<td></td></tr>' 
    from #space_info
    select '</table>'
go
select '<a href="#Topic"> Back to Topic</a><br>'
go

/*********************************************************************************************/
/* Collect database space information (only *.log)                                           */
/*                                                                                           */
/*********************************************************************************************/

declare @name                 nvarchar(100)
declare @dbid                 int
declare @exec_stmt            varchar(1600)
 
create table #log_space_info
(
  DatabaseName                varchar(100) null,
  Name                        varchar(120) null,
  FileName                    varchar(250) null,
  SizeKB                      dec(15) null,
  UsedKB                      dec(15) null,
  FreeKB                      dec(15) null,
  MaxSizeKB                   dec(15) null,
  pctfree                     dec(15) null,
  status                      int null,
  growth                      int null
)

declare dbname_crr cursor for 
  select name, dbid from master.dbo.sysdatabases

open dbname_crr
fetch dbname_crr into @name, @dbid

while @@fetch_status >= 0
begin
  if convert(sysname,DatabasePropertyEX(@name,'Status')) != 'OFFLINE'
    begin
      set @exec_stmt = 'use ' + quotename(@name, N'[') +
        'insert into #log_space_info (DataBaseName, Name, FileName, SizeKB, UsedKB, FreeKB, MaxSizeKB, PctFree, status, growth) ' +
        'select ''' + @name + ''', f.name, f.filename, f.size*8 , fileproperty(name, ''spaceused'')*8,
           f.size*8 - fileproperty(name, ''spaceused'')*8,
           maxsize,
           100 - (fileproperty(name, ''spaceused'')*8) / (cast(size as decimal(15))*8) * 100,
           f.status, f.growth
        from sysfiles as f
        where fileproperty(name, ''IsLogfile'') = 1' -- and current of dbname_crr'
      --select @exec_stmt
      execute (@exec_stmt)
    end
  else
    begin
      insert into #log_space_info values (@name, 'DB OFFLINE', 0, 0, 0, 0, 0, 0, 0, 0)
    end
  
  fetch dbname_crr into @name, @dbid
end

deallocate dbname_crr

    select '<a name="#LogSpaceInfo"><h2>Log space info for database instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</h2></a>'
    select '<table width="100%" border="1">'
    select '<tr><th>Database Name</th><th>Name</th><th>File Name</th><th>Size MB</th>' + 
           '<th>Used MB</th><th>Free MB</th><th>Maxsize MB</th><th> % Free</th><th>Growth</th></tr>'
    
    select '<tr>' +
           '<td>' + DataBaseName + '</td>' +
           '<td>' + Name + '</td>' +
           '<td>' + FileName + '</td>' +
           '<td align="right">' + cast(cast(SizeKB/1024 as decimal(10,2)) as char) + '</td>' +
           '<td align="right">' + cast(cast(UsedKB/1024 as decimal(10,2)) as char) + '</td>' +
           '<td align="right">' + cast(cast(FreeKB/1024 as decimal(10,2)) as char) + '</td>' +
           '<td align="right">' + case 
                      when MaxSizeKB = -1 then 'Unlimited' 
                      else cast(cast(MaxSizeKB*8/1024 as decimal(10,2)) as char)  
                    end + '</td>' +
           '<td align="center">' + cast(PctFree as char) + '</td>' +
           '<td>' + case
                      when (status & 0x100000) = 0x100000 then 'by ' + cast(growth as varchar(2)) + '%'
                      when (status & 0x2) = 0x2 then 'by ' + cast(growth*8192/1048576 as varchar(100)) + 'MB'
                      when (status & 0x40) = 0x40 then 'by ' + cast(growth*8192/1048576 as varchar(100)) + 'MB'
                      else 'NULL'
                    end + '</td></tr>'
    from #log_space_info
    order by DataBaseName
-- Generating sum information    
    select '<tr><td><b>Sum of LOG files</b></td><td></td><td></td>' + 
           '<td align="right"><b>'+ cast(cast(sum(SizeKB)/1024 as decimal(10,2)) as char)+'</b></td>' +
           '<td align="right"><b>'+ cast(cast(sum(UsedKB)/1024 as decimal(10,2)) as char)+'</b></td>' +
           '<td align="right"><b>'+ cast(cast(sum(FreeKB)/1024 as decimal(10,2)) as char)+'</b></td>' +
           '<td></td></tr>' 
    from #log_space_info
    select '</table>'
go

drop table #log_space_info
go

select '<a href="#Topic"> Back to Topic</a><br>'

/*********************************************************************************************/
/* Errorlog information                                                                      */
/*                                                                                           */
/*********************************************************************************************/

declare @archno tinyint
declare @count tinyint
declare @latest_online_check datetime
declare @sql_stmt varchar(4000)
declare @text_offset int
declare @process_info_length int
declare @ArchiveNo int
declare @off int
declare @logdate datetime

set @text_offset = 34
set @process_info_length = 10
set @count = 0
set @off = 1
set @latest_online_check = getdate() - 14

create table #mir_err_logs (ArchiveNo int, CreateDate nvarchar(24), Size int)
insert into #mir_err_logs EXEC master.dbo.xp_enumerrorlogs 

select @logdate = case
         when @latest_online_check < min(createdate) then min(createdate)
         else (select min(createdate) from #mir_err_logs where CreateDate < @latest_online_check)
       end
from #mir_err_logs

set @archno = (select min(ArchiveNo) from #mir_err_logs where createdate <= @logdate)
--set @ArchiveNo = (select min(ArchiveNo) from #mir_err_logs where CreateDate < @latest_online_check)

create table #mir_err_log_text_tmp_final(Text nvarchar(3910), ArchiveNo int null, LogDate datetime null, ProcessInfo nvarchar(100) null)
create table #mir_err_log_text_tmp(id int IDENTITY(0, 1) primary key clustered, Text nvarchar(3910), ContinuationRow bit, ArchiveNo int null)

while @count <= @ArchiveNo
  begin 
    if( @ArchiveNo > 0 )
      insert #mir_err_log_text_tmp (Text, ContinuationRow) exec master.dbo.sp_readerrorlog @ArchiveNo
    else
      insert #mir_err_log_text_tmp (Text, ContinuationRow) exec master.dbo.sp_readerrorlog
    update #mir_err_log_text_tmp set ArchiveNo = @ArchiveNo where ArchiveNo is null
    set @ArchiveNo = @ArchiveNo - 1
  end 

while exists ( select ContinuationRow from #mir_err_log_text_tmp where ContinuationRow = 1 )
  begin
    update t1
       set t1.Text = t1.Text + t2.Text
    from #mir_err_log_text_tmp as t1
      inner join #mir_err_log_text_tmp as t2 on t1.id + @off = t2.id
    where t1.ContinuationRow = 0
      and t2.ContinuationRow = 1
    delete t2
    from #mir_err_log_text_tmp as t2
      inner join #mir_err_log_text_tmp as t1 on t1.id + @off = t2.id
    where t2.ContinuationRow = 1
  set @off = @off + 1
end

insert #mir_err_log_text_tmp_final
  select Text = CASE WHEN Text like '[1-2][0-9][0-9][0-9]-[0-2][0-9]-[0-3][0-9] [0-6][0-9]:[0-6][0-9]:[0-9][0-9]%'
                       then /*structured row: remove date/spid part */ SUBSTRING(Text, @text_offset, 4000) else /*non structured row*/ Text end,
         ArchiveNo, 
         LogDate = CASE WHEN Text like '[1-2][0-9][0-9][0-9]-[0-2][0-9]-[0-3][0-9] [0-6][0-9]:[0-6][0-9]:[0-9][0-9]%'
                          then /*structured row: get date part */ CONVERT(datetime, LEFT(Text, 23), 121) else /*non structured row*/ null end,
         ProcessInfo = CASE WHEN Text like '[1-2][0-9][0-9][0-9]-[0-2][0-9]-[0-3][0-9] [0-6][0-9]:[0-6][0-9]:[0-9][0-9]%'
                              then /*structured row: get spid part */ rtrim(SUBSTRING(Text, 24, @process_info_length)) else /*non structured row*/ null end
  from #mir_err_log_text_tmp
  
select '<a name="#ErrorlogInfo"><h2>Errorlog info for database instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</h2></a>'
select '<table width="100%" border="1">'
select '<tr><th>Log Date</th><th>Error Source</th><th>Error Text</th>'
    
select '<tr>' + 
       '<td>' + convert(char, logdate, 13) + '</td>' +
       '<td>' + ProcessInfo + '</td>' +
       '<td>' + Text + '</td>'
from #mir_err_log_text_tmp_final 
where logdate > @latest_online_check
and ProcessInfo not like 'Logon'
and (Text like '%failed%' or Text like '%Error:%')
order by logdate
select '</tr>'
select '</table>'
select '<a href="#Topic"> Back to Topic</a><br>'


/*********************************************************************************************/
/* Displaying Database Properties information                                                */
/*                                                                                           */
/*********************************************************************************************/

use master
go

select '<a name="#DatabaseProperties"><h2>Properties for the databases on SQL Server instance: '+ convert(sysname,SERVERPROPERTY('ServerName')) + '</h2></a>'
select '<table width="100%" border="1">'
select '<tr><th>Database Name</th><th>User Access</th><th>Open Mode</th><th>Database State</th><th>Recovery Model</th>' +
       '<th>Auto Close</th><th>Auto Shrink</th><th>Auto Create Stats</th><th>Auto Update Stats</th><th>Full Text Enabled</th><th>Page Verification</th></tr>'
select '<tr>' + 
       '<td>' + name + '</td>' +
       '<td>' + case
                  when (status & 0x800)  = 0x800 then 'Restricted Mode'
                  when (status & 0x1000) = 0x1000 then 'Single User'
                  else 'Multi User'
               end + '</td>' +
      '<td>' + case
                 when (status & 0x400) = 0x400 then 'Read Only'
                 else 'Read Write'
               end + '</td>' +
      '<td>' + case
                 when (status & 0x20)   = 0x20 then 'Loading'
                 when (status & 0x40)   = 0x40 then 'Pre Recovering'
                 when (status & 0x80)   = 0x80 then 'Recovering'
                 when (status & 0x100)  = 0x100 then 'Not Recovered'
                 when (status & 0x200)  = 0x200 then 'Offline'
                 when (status & 0x8000) = 0x8000 then 'Emergency mode'
                 when (status & 0x40000000) = 0x40000000 then 'Cleanly Shutdown'
                 else 'Online'
               end + '</td>' +
       '<td>' + case
                  when (status & 0x4) = 0x4  then 'Bulk Logged'
                  when (status & 0x8) = 0x8 then 'Simple'
                  else 'Full'
               end + '</td>' +
      '<td>' +  case
                 when (status & 0x1) = 0x1 then '<font color="#FF0000">True</font>'
                 else 'False'
                end + '</td>' +
      '<td>' + case
                 when (status & 0x400000) = 0x400000 then '<font color="#FF0000">True</font>'
                 else 'False'
               end + '</td>' +
      '<td>' + case
                 when (status2 & 0x40000000) = 0x40000000 then 'True'
                 else 'False'
               end + '</td>' +
      '<td>' + case
                 when (status2 & 0x1000000) = 0x1000000 then 'True'
                 else 'False'
               end + '</td>' +
      '<td>' + case
                 when (status & 20000000) = 20000000 then 'True'
                 else 'False'
               end + '</td>' +
      '<td>' + case
                 when (status & 0x10) = 0x10 then 'Torn Page Detection'
                 else 'None'
               end + '</td>' +
              '</tr>'
from sysdatabases
go
select '</table>'
select '<a href="#Topic"> Back to Topic</a><br>'
go

--/*********************************************************************************************/
--/* Summering of errorlog information   - currently deactivated                               */
--/*                                                                                           */
--/*********************************************************************************************/

--select '<a name="#ErrorlogSum"><h2>Summering from Errorlog for SQL Server instance: '+ convert(sysname,SERVERPROPERTY('ServerName')) + '</h2></a>'
--select '<table width="100%" border="1">'
--select '<tr><th>Error Source</th><th>Error Date</th><th>Error Count</th>'
--select '<tr>' +
--       '<td>' + ProcessInfo + '</td>' +
--       '<td>' + convert(char, logdate, 106) + '</td>' +
--       '<td>' + convert(char, count(*)) + '</td>'
--from #mir_err_log_text_tmp_final 
--where ProcessInfo in ('Logon', 'backup')
--and ( Text like '%Error%' or Text like '%failed%')
--and logdate > @latest_online_check
--group by ProcessInfo, convert(char, logdate, 106)
--order by ProcessInfo, convert(char, logdate, 106)
--select '</tr>'
--select '</table>'
--go
--select '<a href="#Topic"> Back to Topic</a><br>'


select '</body>'
go