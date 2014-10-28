-------------------------------
-- Miracle online check script
-------------------------------
-- RUN Spool SCRIPT
-- Setup spooling file
------------------------------
define os = &1
define logdir = &2
set echo off

@@spool &1 &2

-------------------------------
-- RUN PRE SQL SCRIPT SCRIPT
-- Fx. Compile invalid objects
-------------------------------
@@check_prescript.sql

set lines    300
set pagesize 100
set trimspool on

col dbid format 999999999999
col host_name format a20
col instance_name format a16
col open_mode format a10
col logins format a10
col destination format a50
col error format a10
col object_name format a40
col object_type format a20
col what format a60
col value format a70
col name format a40
col file_name format a50
col owner format a20
col db_user format a15
col job_name format a40
col status format a15
col last_date format a18
col next_date format a18
col err_date format a18
col latest format a20
col tablespace_name format a30
col job format 99999999
col inst format 9999
col dest# format 99999
col job_name format a30
col comp_name format a50
col patch_time format a15
col action format a15
col version format a11
col comments format a30
col host format a20
col "Tjek version" format a20
col rman_type format a10
col comment format a10
col "MB Index" format 9999999
col "MB Data"  format 9999999
col "MB"       format 9999999
col "GB"       format 9G999G999
col component format a30
col username  format a10
col osuser    format a15
col machine   format a25
col program   format a20
col module    format a25
col dag       format a16
col uni       format a3
col RESOURCE_NAME format a25
col table_name format a30
col index_name format a30
col LAST_OPER_TYPE format a15
col DATO       format a15
col CHANGE#    format 999999999999999
col schema_user format a12
col priv_user   format a12
col checked     format a21
col BY          format a10
col client      format a20
col osuser      format a20
col user_ip     format a15
col isdba       format a5
col db          format a8
col server_name format a15
col server_ip   format a15
col pval2       format a20

--  Bruges til at kunne skelne mlm. DB version længere nede
col db_v        new_value dbv  format 999      
col db_v2       new_value dbv2 format 99999D9  


alter session set nls_territory=denmark;
alter session set nls_date_format='DD-MON-RRRR HH24:MI';
alter session set nls_numeric_characters=',.';

DOC
 ---------------------------------------------------------------------------
 (1) Check runtime
 ---------------------------------------------------------------------------
#

select 
    to_char(sysdate,'DD-MM-YYYY HH24:MI:SS') checked
    ,sys_context('USERENV','CURRENT_USER')  "BY"
    ,sys_context('USERENV','HOST')  client
    ,sys_context('USERENV','OS_USER')  osuser
    ,sys_context('USERENV','IP_ADDRESS') user_ip
    ,sys_context('USERENV','ISDBA')  isdba
    ,sys_context('USERENV','DB_NAME')  db
    ,host_name server_name
  --  ,UTL_INADDR.GET_HOST_ADDRESS server_ip
    ,to_number(substr(version,1,(instr(version,'.'))-1)) db_v
    ,to_number(substr(version,1,(instr(version,'.',1,2))-1),'999d99',  'NLS_NUMERIC_CHARACTERS = ''.,''') db_v2
    --,version
from v$instance;

DOC
 ---------------------------------------------------------------------------
 (2) Check version
 ---------------------------------------------------------------------------
#
select '2.1' "Tjek version" from dual;

DOC
 ---------------------------------------------------------------------------
 (3) Instance Information
 ---------------------------------------------------------------------------
#

select host_name, instance_name, dbid, 
       --decode(controlfile_type,'CURRENT','Primær DB','Standby DB') "DB type",
       startup_time, open_mode, logins, database_role,
     force_logging
from   v$database db, v$instance i;

set heading off
set feedback off
column comm format a100

select 'Der er en STANDBY destination - og du kører ikke med FORCELOGGING - er dette mon korrekt??' comm
from dual
where exists  (select 1 from v$archive_dest where target = 'STANDBY') and
exists (select 1 from v$database where force_logging <> 'YES');

select 'OBS - Denne database overvåges af en Data Guard Monitor' comm
from dual
where exists 
(select 1 from v$process where program like '%(DMON)%')
;

select 
case when value = 'DB' then 
(select 'audit_trail = DB, og size på AUD$ er: ' || to_char(round(sum(bytes)/(1024*1024))) 
 from   
    dba_extents 
 where segment_type='TABLE' 
 and   segment_name = 'AUD$' 
 and   owner = 'SYS') || ' MB' || chr(10)
else null end comm
from v$parameter
where name = 'audit_trail'
union all
select '' from dual;

set feedback 6
set heading on

DOC
 ---------------------------------------------------------------------------
 (4) Database version information
 ---------------------------------------------------------------------------
#
select * from v$version;

select name, value, isdefault
from v$parameter
where name in ('optimizer_features_enable','compatible')
union all
select'spfile', decode(value, NULL, 'OBS >> PFILE << OBS', value), decode(value, NULL, '*****************', isdefault)
from v$parameter 
where name = 'spfile'
union all
select'EE options', 
case when (select count(*) from v$version where banner like '%Enterprise Edition%') > 0
         and value = 'NONE' then 'Enterprise Edition, men ingen Tuning/Diag pakke (' || value || ')'
     when (select count(*) from v$version where banner like '%Enterprise Edition%') > 0
         and value <> 'NONE' then 'Enterprise Edition, og pakkerne ('  || value || ')'
     when (select count(*) from v$version where banner like '%Enterprise Edition%') = 0
         and value = 'NONE' then 'Standard Edition, og ingen Tuning/Diag pakker ('  || value || ')'
     when (select count(*) from v$version where banner like '%Enterprise Edition%') = 0
         and value <> 'NONE' then 'Standard Edition, og ingen Tuning/Diag pakker - men parameter er sat !!!!!! ('  || value || ')'
     end         
, isdefault
from v$parameter, v$instance
where name = 'control_management_pack_access'
;

DOC
 ---------------------------------------------------------------------------
 (5) Installed patches using OPatch utility
 ---------------------------------------------------------------------------
#
select to_char(ACTION_TIME,'DD-MON-RR HH24:MI') Patch_time, ACTION, VERSION, COMMENTS
from dba_registry_history
order by action_time;

DOC

 ---------------------------------------------------------------------------
 (6) Memory allocated at instance startup
 ---------------------------------------------------------------------------
#
col value format 999G999G999G999
COMPUTE SUM OF value ON REPORT
BREAK ON REPORT

select name, value,
round(value *100 / sum(value) over(order by 1)) pct
from v$sga;

CLEAR BREAKS
CLEAR COMPUTES

DOC
 ---------------------------------------------------------------------------
 (7) Configured memory parameters in pfile / spfile
 ---------------------------------------------------------------------------
#
 
select name,to_number(value) value , isdefault
from v$parameter
where name in ('shared_pool_size','java_pool_size','large_pool_size','db_cache_size','sga_target','sga_max_size',
'pga_aggregate_target','streams_pool_size','hash_area_size','db_block_buffers','memory_target')
--and isdefault = 'FALSE'
order by 3, 1;

set heading off


with memorysize as
(
select 
(select to_number(value) value 
      from v$parameter where name = 'sga_target') sga_target,
(select to_number(value) value 
      from v$parameter where name = 'sga_max_size') sga_max_size
from dual
)
select case when decode(sga_target,0, sga_max_size, sga_target) < sga_max_size then
       'OBS !!! Sga target (' || trim(to_char(sga_target,'999G999G999G999')) || ') < end sga_max_size (' 
       || trim(to_char(sga_max_size,'999G999G999G999')) || ')' else '' end obs
from memorysize;

set heading on

DOC
 ---------------------------------------------------------------------------
 (8) Non default parameters in pfile / spfile
 ---------------------------------------------------------------------------
#
col value format a70

select name, value from v$parameter where isdefault = 'FALSE'
order by name;

DOC
 ---------------------------------------------------------------------------
 (9) Problematic DBA_JOBS
 ---------------------------------------------------------------------------
#
col "Schema, priv,log-user" format a40
col err format 9999

select job, what, last_date, next_date, failures err, broken,
	   schema_user ||'-'||  priv_user ||'-' || log_user "Schema, priv,log-user",
(select 'Runs now' from dba_jobs_running r
 where r.job = j.job) "Comment"
from dba_jobs j
where broken = 'Y'
or failures > 0
or next_date < sysdate - 2/24/60
or next_date > sysdate + 400
order by broken desc, job;

DOC
 ---------------------------------------------------------------------------
 (10) List running DBA_JOBS
 ---------------------------------------------------------------------------
#

show parameter job_queue

select job, this_date start_date
from dba_jobs_running
order by 1;

DOC
 ---------------------------------------------------------------------------
 (11) Problematic DBMS_SCHEDULER jobs
 ---------------------------------------------------------------------------
#

col owner format a20
col job_name format a30
col err_date format a12
col first_start format a12
col last_start_date format a17
col next_run_date format a17
col schedule_name format a15
col repeat_interval format a30
col run_count format 999999
col status format a7

with rd as
(
select rd.owner || '.' || rd.job_name job_name, to_char(log_date,'DD-MON-RRRR') ERR_DATE, count(*) ERROR_CNT, status
from DBA_SCHEDULER_JOB_RUN_DETAILS rd
where log_date > sysdate - 14
   and status <> 'SUCCEEDED'
group by rd.owner, rd.job_name, to_char(log_date,'DD-MON-RRRR'), status
)
select rd.*
, to_char(start_date,'DD-MON-RRRR') first_start
, to_char(last_start_date,'DD-MON-RRRR HH24:MI') last_start_date, to_char(next_run_date,'DD-MON-RRRR HH24:MI') next_run_date
, schedule_name, repeat_interval, run_count
from rd
   left outer join DBA_SCHEDULER_JOBS j on RD.JOB_NAME = j.owner || '.'  || j.job_name 
where &dbv < 11
order by ERR_DATE;

with rd as
(
select rd.owner || '.' || rd.job_name job_name, to_char(log_date,'DD-MON-RRRR') ERR_DATE, count(*) ERROR_CNT, status
from DBA_SCHEDULER_JOB_RUN_DETAILS rd
where log_date > sysdate - 14
   and status <> 'SUCCEEDED'
group by rd.owner, rd.job_name, to_char(log_date,'DD-MON-RRRR'), status
)
select rd.*
, to_char(start_date,'DD-MON-RRRR') first_start
, to_char(last_start_date,'DD-MON-RRRR HH24:MI') last_start_date, to_char(next_run_date,'DD-MON-RRRR HH24:MI') next_run_date
, schedule_name, repeat_interval, run_count
from rd
   left outer join DBA_SCHEDULER_JOBS j on RD.JOB_NAME = j.owner || '.'  || j.job_name and job_style = 'REGULAR'
order by ERR_DATE;

col status format a15

DOC
 ---------------------------------------------------------------------------
 (12) LOG_MODE role, protections for database
 ---------------------------------------------------------------------------
#
select log_mode, database_role, CONTROLFILE_TYPE, protection_level, protection_mode, switchover_status
from v$database;

DOC
 ---------------------------------------------------------------------------
 (13) Archivelog destinations
 ---------------------------------------------------------------------------
#

SELECT DEST_ID DEST#, STATUS, TARGET, decode(destination, 'USE_DB_RECOVERY_FILE_DEST', (select A.value||'\'||B.instance_name||'\archivelog'
from v$parameter a, v$instance b
where a.name = 'db_recovery_file_dest'), destination) "DESTINATION", ERROR
, (select protection_mode from v$archive_dest_status s where s.dest_id = dest.dest_id) protection_mode
, (select archived_seq# from v$archive_dest_status s where s.dest_id = dest.dest_id) archived_seq#
FROM V$ARCHIVE_DEST dest
WHERE STATUS <> 'INACTIVE' and &dbv < 10
order by 1;

SELECT dest.DEST_ID DEST#, dest.STATUS, TARGET, decode(dest.destination, 'USE_DB_RECOVERY_FILE_DEST', (select A.value||'\'||B.instance_name||'\archivelog'
from v$parameter a, v$instance b
where a.name = 'db_recovery_file_dest'), dest.destination) "DESTINATION", dest.ERROR
, (select protection_mode from v$archive_dest_status s where s.dest_id = dest.dest_id) protection_mode
, (select archived_seq# from v$archive_dest_status s where s.dest_id = dest.dest_id) archived_seq#
, Case Protection_mode When 'MAXIMUM PERFORMANCE' Then 'N/A' Else Synchronization_Status End Synchronization
FROM V$ARCHIVE_DEST dest, V$ARCHIVE_DEST_status deststat
WHERE dest.STATUS <> 'INACTIVE' and &dbv > 9
and dest.dest_id = deststat.dest_id
order by 1;

DOC
 ---------------------------------------------------------------------------
 (14) Latest 10 archive logs
 ---------------------------------------------------------------------------
#

col archivelog_name format a100

select first_time fra, nexT_time til, name archivelog_name, standby_dest, archived,applied
from (select a.*, rownum rn from (
SELECT first_time , nexT_time , name, standby_dest, archived,applied
FROM V$ARCHIVED_LOG
order by first_time desc) a
) where rn < 11
order by rn desc;

DOC
 ---------------------------------------------------------------------------
 (15) Offline datafiles (none should be listed)
 ---------------------------------------------------------------------------
#
select b.file#, b.name, a.status from v$datafile_header a, v$datafile b
where a.status <> 'ONLINE'
and a.file# = b.file#
order by file#;

DOC
 ---------------------------------------------------------------------------
 (16) Datafiles that needs recovery (none should be listed in normal databases)
 ---------------------------------------------------------------------------
#
select * from v$recover_file
order by 1;

DOC
 ---------------------------------------------------------------------------
 (17) Last time unrecoverable operations was performed
 ---------------------------------------------------------------------------
#
select b.name tablespace_name, max(UNRECOVERABLE_TIME) UNRECOVERABLE_TIME
from v$datafile a, v$tablespace b
where a.TS#=b.ts#
and a.UNRECOVERABLE_TIME is not null
group by b.name
order by 2;

DOC
 ---------------------------------------------------------------------------
 (18) Unusable indexes
 ---------------------------------------------------------------------------
#

col index_owner format a20
col index_name  format a30
col partition_name format a30
col subpartition_name format a30

select owner, table_name, index_name, status
from dba_indexes
where status = 'UNUSABLE'
order by 1, 2, 3 ;

select  index_owner, index_name, partition_name,  status
from dba_ind_partitions
where status  = 'UNUSABLE'
order by 1, 2, 3 ;

select  index_owner, subpartition_name,  partition_name,  index_name, status
from dba_ind_subpartitions
where status  = 'UNUSABLE'
order by 1, 2, 3 ;


DOC
 ---------------------------------------------------------------------------
 (19) Invisble indexes (only 11g onwards)
 ---------------------------------------------------------------------------
#
select owner, table_name, index_name, visibility, status
from dba_indexes
where visibility = 'INVISIBLE'
order by 1, 2, 3 ;

DOC
 ---------------------------------------------------------------------------
 (20) Block Corruptions
 ---------------------------------------------------------------------------
# 

select * from v$database_block_corruption
order by file#;

column owner          format a10
column segment_name   format a30
column partition_name format a30
column descrption     format a20

SELECT /*+ RULE */  e.owner, e.segment_type, e.segment_name, e.partition_name, c.file#
     , greatest(e.block_id, c.block#) corr_start_block#
     , least(e.block_id+e.blocks-1, c.block#+c.blocks-1) corr_end_block#
     , least(e.block_id+e.blocks-1, c.block#+c.blocks-1) 
       - greatest(e.block_id, c.block#) + 1 blocks_corrupted
     , null description
  FROM dba_extents e, v$database_block_corruption c
 WHERE e.file_id = c.file#
   AND e.block_id <= c.block# + c.blocks - 1
   AND e.block_id + e.blocks - 1 >= c.block#
UNION
SELECT s.owner, s.segment_type, s.segment_name, s.partition_name, c.file#
     , header_block corr_start_block#
     , header_block corr_end_block#
     , 1 blocks_corrupted
     , 'Segment Header' description
  FROM dba_segments s, v$database_block_corruption c
 WHERE s.header_file = c.file#
   AND s.header_block between c.block# and c.block# + c.blocks - 1
UNION
SELECT null owner, null segment_type, null segment_name, null partition_name, c.file#
     , greatest(f.block_id, c.block#) corr_start_block#
     , least(f.block_id+f.blocks-1, c.block#+c.blocks-1) corr_end_block#
     , least(f.block_id+f.blocks-1, c.block#+c.blocks-1) 
       - greatest(f.block_id, c.block#) + 1 blocks_corrupted
     , 'Free Block' description
  FROM dba_free_space f, v$database_block_corruption c
 WHERE f.file_id = c.file#
   AND f.block_id <= c.block# + c.blocks - 1
   AND f.block_id + f.blocks - 1 >= c.block#
order by file#, corr_start_block#;

column owner          format a20

DOC
 ---------------------------------------------------------------------------
 (21) Datafiles in backup mode and last time they where in backup mode
 ---------------------------------------------------------------------------
#

col comments format a70

SELECT to_number(VALUE) MAX_NO_OF_DATAFILES, CURRENT_NO_DATA_FILES,
case when VALUE-CURRENT_NO_DATA_FILES < 10 then 'OBS - soon running out of datafiles increase "db_files" parameter ' else null end comments
FROM v$parameter cross join (SELECT COUNT (*) CURRENT_NO_DATA_FILES FROM DBA_DATA_FILES)
WHERE NAME = 'db_files'
;

select * from v$backup
order by 1;

select  /*+ RULE */ sum(decode(status,'ACTIVE',1,0)) "Active", sum(decode(status,'ACTIVE',0,1)) "Not active"
from v$backup;

column backup_type      format a30 heading 'Backup Type'
column recoverable_to   heading 'Recoverable To'

with backup_files as
(
---- vi materialiserer dette statement, da bla GFs controlfile er så stor, at planen er helt i hampen ogh kører x timer
---- vi tager v$datafiler med (som i det næste tjeki scriptet og kører derfra)
select  /*+materialize */  vd.file#, vd.name,max(vbd.completion_time) completion_time, inc_level, rman_type
from v$datafile vd, (
           select 'Backup' rman_type, d2.file#,  d2.completion_time, nvl(d2.incremental_level,0) inc_level, d2.stamp,
                  row_number() over (partition by d2.incremental_level, d2.file# order by D2.STAMP desc) rn
       from v$backup_datafile d2, v$backup_set s2
           where nvl(input_file_scan_only,'NO') = 'NO' and d2.stamp = s2.stamp (+)
       ) vbd
where vd.file# = vbd.file# (+) and rn=1
group by vd.file#, vd.name, inc_level, rman_type
),
last_backup as
(
select  /*+ materialize */  'Latest Backup Level ' || inc_level backup_type,  max(completion_time) latest_backup  
from backup_files 
group by inc_level)
----
select /*+ RULE */ 'Archivelog Backup' backup_type
       ,max_next_time recoverable_to
from v$backup_archivelog_summary
UNION
select /*+ RULE */ 'Controlfile Backup' backup_type
       ,max_checkpoint_time recoverable_to
from v$backup_controlfile_summary
union all
select * from last_backup
;

--- præ V10.2
with backup_files as
(
---- vi materialiserer dette statement, da bla GFs controlfile er så stor, at planen er helt i hampen ogh kører x timer
---- vi tager v$datafiler med (som i det næste tjeki scriptet og kører derfra)
select  /*+materialize */  vd.file#, vd.name,max(vbd.completion_time) completion_time, inc_level, rman_type
from v$datafile vd, (
           select 'Backup' rman_type, d2.file#,  d2.completion_time, nvl(d2.incremental_level,0) inc_level, d2.stamp,
                  row_number() over (partition by d2.incremental_level, d2.file# order by D2.STAMP desc) rn
       from v$backup_datafile d2, v$backup_set s2
           where nvl(input_file_scan_only,'NO') = 'NO' and d2.stamp = s2.stamp (+)
       ) vbd
where vd.file# = vbd.file# (+) and rn=1
group by vd.file#, vd.name, inc_level, rman_type
),
last_backup as
(
select  /*+ materialize */  'Latest Backup Level ' || inc_level backup_type,  max(completion_time) latest_backup  
from backup_files 
group by inc_level)
----
select * from (
select  'Archivelog last backup' type, max(next_time) latest_backup 
from V$BACKUP_REDOLOG
union all
select /*+ RULE */ 'SPFile last backup' ,max(completion_time)  
from V$BACKUP_SPFILE
union all
select /*+ RULE */ 'Last backup of Controlfile', max(COMPLETION_TIME) from v$backup_set
where CONTROLFILE_INCLUDED = 'YES'
union all
select * from last_backup
)
where exists
     (select 1 from v$instance where version like '8.%' or version like '9.%' or version like '10.1.%')
;



DOC
 ---------------------------------------------------------------------------
 (22) Show latest RMAN backup of datafiles
 ---------------------------------------------------------------------------
#
col name format a80
col file# format 99999

select  /*+ RULE */ vd.file#, vd.name, decode(max(vbd.completion_time),null,'** NO RMAN BACKUP **', 
max(vbd.completion_time)) latest, inc_level, rman_type
from v$datafile vd, (
           select 'Backup' rman_type, d2.file#,  d2.completion_time, nvl(d2.incremental_level,0) inc_level, d2.stamp
       from v$backup_datafile d2, v$backup_set s2
           where nvl(input_file_scan_only,'NO') = 'NO' and d2.stamp = s2.stamp (+)
     -- union all
       --    select 'Copy' rman_type, d1.file#, d1.completion_time, nvl(d1.incremental_level,0)  inc_level, d1.stamp
       --    from v$datafile_copy d1, v$backup_set s1
       --    where nvl(input_file_scan_only,'NO') = 'NO' and d1.stamp = s1.stamp (+)
       ) vbd
where vd.file# = vbd.file# (+)
group by vd.file#, vd.name, inc_level, rman_type
order by rman_type, latest desc ;

col name format a40

DOC
 ---------------------------------------------------------------------------
 (23) Show RMAN backup history of datafiles
 ---------------------------------------------------------------------------
#

col name  format a50;
col "-1"  format 999;
col "-2"  format 999;
col "-3"  format 999;
col "-4"  format 999;
col "-5"  format 999;
col "-6"  format 999;
col "-7"  format 999;
col "-8"  format 999;
col "-9"  format 999;
col "-10" format 999;
col "-11" format 999;
col "-12" format 999;
col "-13" format 999;
col "-14" format 999;
col "-15" format 999;
col "-16" format 999;
col "-17" format 999;
col "-18" format 999;
col "-19" format 999;
col "-20" format 999;
col "-21" format 999;
col "-22" format 999;
col "-23" format 999;
col "-24" format 999;
col "-25" format 999;
col "-26" format 999;
col "-27" format 999;
col "-28" format 999;
col "-29" format 999;
col "-30" format 999;
col idag format 999;
col file#   format 999;
col "Level" format 99999;
col "Type"  format a9;

with archlog_details as
(
select /*+ RULE */ count(*) antal, count(distinct start_time) jobs,   trunc(sysdate,'DD') - trunc(completion_time,'DD') last_backup_end
from v$backup_archivelog_details d 
    join v$backup_set s on S.SET_COUNT = d.id2 and S.SET_STAMP = d.id1
group by   trunc(sysdate,'DD') - trunc(completion_time,'DD') 
)
select  'Antal backups' hvad,
sum(bu0) idag,   sum(bu1) "-1",   sum(bu2) "-2",   sum(bu3) "-3",
sum(bu4) "-4",   sum(bu5) "-5",   sum(bu6) "-6",   sum(bu7) "-7",
sum(bu8) "-8",   sum(bu9) "-9",   sum(bu10) "-10", sum(bu11) "-11",
sum(bu12) "-12", sum(bu13) "-13", sum(bu14) "-14", sum(bu15) "-15",
sum(bu16) "-16", sum(bu17) "-17", sum(bu18) "-18", sum(bu19) "-19",
sum(bu20) "-20", sum(bu21) "-21", sum(bu22) "-22", sum(bu23) "-23",
sum(bu24) "-24", sum(bu25) "-25", sum(bu26) "-26", sum(bu27) "-27",
sum(bu28) "-28", sum(bu29) "-29"
from (
select 
 case when last_backup_end = 0  then jobs else null end bu0,
 case when last_backup_end = 1  then jobs else null end bu1,
 case when last_backup_end = 2  then jobs else null end bu2,
 case when last_backup_end = 3  then jobs else null end bu3,
 case when last_backup_end = 4  then jobs else null end bu4,
 case when last_backup_end = 5  then jobs else null end bu5,
 case when last_backup_end = 6  then jobs else null end bu6,
 case when last_backup_end = 7  then jobs else null end bu7,
 case when last_backup_end = 8  then jobs else null end bu8,
 case when last_backup_end = 9  then jobs else null end bu9,
 case when last_backup_end = 10 then jobs else null end bu10,
 case when last_backup_end = 11 then jobs else null end bu11,
 case when last_backup_end = 12 then jobs else null end bu12,
 case when last_backup_end = 13 then jobs else null end bu13,
 case when last_backup_end = 14 then jobs else null end bu14,
 case when last_backup_end = 15 then jobs else null end bu15,
 case when last_backup_end = 16 then jobs else null end bu16,
 case when last_backup_end = 17 then jobs else null end bu17,
 case when last_backup_end = 18 then jobs else null end bu18,
 case when last_backup_end = 19 then jobs else null end bu19,
 case when last_backup_end = 20 then jobs else null end bu20,
 case when last_backup_end = 21 then jobs else null end bu21,
 case when last_backup_end = 22 then jobs else null end bu22,
 case when last_backup_end = 23 then jobs else null end bu23,
 case when last_backup_end = 24 then jobs else null end bu24,
 case when last_backup_end = 25 then jobs else null end bu25,
 case when last_backup_end = 26 then jobs else null end bu26,
 case when last_backup_end = 27 then jobs else null end bu27,
 case when last_backup_end = 28 then jobs else null end bu28,
 case when last_backup_end = 29 then jobs else null end bu29,
 case when last_backup_end = 30 then jobs else null end bu30
from archlog_details
)
union all
select  'Antal archivelog filer' hvad,
sum(bu0) idag,   sum(bu1) "-1",   sum(bu2) "-2",   sum(bu3) "-3",
sum(bu4) "-4",   sum(bu5) "-5",   sum(bu6) "-6",   sum(bu7) "-7",
sum(bu8) "-8",   sum(bu9) "-9",   sum(bu10) "-10", sum(bu11) "-11",
sum(bu12) "-12", sum(bu13) "-13", sum(bu14) "-14", sum(bu15) "-15",
sum(bu16) "-16", sum(bu17) "-17", sum(bu18) "-18", sum(bu19) "-19",
sum(bu20) "-20", sum(bu21) "-21", sum(bu22) "-22", sum(bu23) "-23",
sum(bu24) "-24", sum(bu25) "-25", sum(bu26) "-26", sum(bu27) "-27",
sum(bu28) "-28", sum(bu29) "-29"
from (
select 
 case when last_backup_end = 0  then antal else null end bu0,
 case when last_backup_end = 1  then antal else null end bu1,
 case when last_backup_end = 2  then antal else null end bu2,
 case when last_backup_end = 3  then antal else null end bu3,
 case when last_backup_end = 4  then antal else null end bu4,
 case when last_backup_end = 5  then antal else null end bu5,
 case when last_backup_end = 6  then antal else null end bu6,
 case when last_backup_end = 7  then antal else null end bu7,
 case when last_backup_end = 8  then antal else null end bu8,
 case when last_backup_end = 9  then antal else null end bu9,
 case when last_backup_end = 10 then antal else null end bu10,
 case when last_backup_end = 11 then antal else null end bu11,
 case when last_backup_end = 12 then antal else null end bu12,
 case when last_backup_end = 13 then antal else null end bu13,
 case when last_backup_end = 14 then antal else null end bu14,
 case when last_backup_end = 15 then antal else null end bu15,
 case when last_backup_end = 16 then antal else null end bu16,
 case when last_backup_end = 17 then antal else null end bu17,
 case when last_backup_end = 18 then antal else null end bu18,
 case when last_backup_end = 19 then antal else null end bu19,
 case when last_backup_end = 20 then antal else null end bu20,
 case when last_backup_end = 21 then antal else null end bu21,
 case when last_backup_end = 22 then antal else null end bu22,
 case when last_backup_end = 23 then antal else null end bu23,
 case when last_backup_end = 24 then antal else null end bu24,
 case when last_backup_end = 25 then antal else null end bu25,
 case when last_backup_end = 26 then antal else null end bu26,
 case when last_backup_end = 27 then antal else null end bu27,
 case when last_backup_end = 28 then antal else null end bu28,
 case when last_backup_end = 29 then antal else null end bu29,
 case when last_backup_end = 30 then antal else null end bu30
from archlog_details)
;

col name  format a50;
col "-1"  format 999;
col "-2"  format 999;
col "-3"  format 999;
col "-4"  format 999;
col "-5"  format 999;
col "-6"  format 999;
col "-7"  format 999;
col "-8"  format 999;
col "-9"  format 999;
col "-10" format 999;
col "-11" format 999;
col "-12" format 999;
col "-13" format 999;
col "-14" format 999;
col "-15" format 999;
col "-16" format 999;
col "-17" format 999;
col "-18" format 999;
col "-19" format 999;
col "-20" format 999;
col "-21" format 999;
col "-22" format 999;
col "-23" format 999;
col "-24" format 999;
col "-25" format 999;
col "-26" format 999;
col "-27" format 999;
col "-28" format 999;
col "-29" format 999;
col "-30" format 999;
col idag format 999;
col file#   format 999;
col "Level" format 99999;
col "Type"  format a9;

select  /*+ RULE */ file#, incremental_level "Level", decode(validated,'NO','BACKUP','VALIDATE') "Type" ,
sum(bu0) idag,   sum(bu1) "-1",   sum(bu2) "-2",   sum(bu3) "-3",
sum(bu4) "-4",   sum(bu5) "-5",   sum(bu6) "-6",   sum(bu7) "-7",
sum(bu8) "-8",   sum(bu9) "-9",   sum(bu10) "-10", sum(bu11) "-11",
sum(bu12) "-12", sum(bu13) "-13", sum(bu14) "-14", sum(bu15) "-15",
sum(bu16) "-16", sum(bu17) "-17", sum(bu18) "-18", sum(bu19) "-19",
sum(bu20) "-20", sum(bu21) "-21", sum(bu22) "-22", sum(bu23) "-23",
sum(bu24) "-24", sum(bu25) "-25", sum(bu26) "-26", sum(bu27) "-27",
sum(bu28) "-28", sum(bu29) "-29"
from (
select file#, name, incremental_level,  validated,
 case when last_backup_end = 0 then 1 else null end bu0,
 case when last_backup_end = 1 then 1 else null end bu1,
 case when last_backup_end = 2 then 1 else null end bu2,
 case when last_backup_end = 3 then 1 else null end bu3,
 case when last_backup_end = 4 then 1 else null end bu4,
 case when last_backup_end = 5 then 1 else null end bu5,
 case when last_backup_end = 6 then 1 else null end bu6,
 case when last_backup_end = 7 then 1 else null end bu7,
 case when last_backup_end = 8 then 1 else null end bu8,
 case when last_backup_end = 9 then 1 else null end bu9,
 case when last_backup_end = 10 then 1 else null end bu10,
 case when last_backup_end = 11 then 1 else null end bu11,
 case when last_backup_end = 12 then 1 else null end bu12,
 case when last_backup_end = 13 then 1 else null end bu13,
 case when last_backup_end = 14 then 1 else null end bu14,
 case when last_backup_end = 15 then 1 else null end bu15,
 case when last_backup_end = 16 then 1 else null end bu16,
 case when last_backup_end = 17 then 1 else null end bu17,
 case when last_backup_end = 18 then 1 else null end bu18,
 case when last_backup_end = 19 then 1 else null end bu19,
 case when last_backup_end = 20 then 1 else null end bu20,
 case when last_backup_end = 21 then 1 else null end bu21,
 case when last_backup_end = 22 then 1 else null end bu22,
 case when last_backup_end = 23 then 1 else null end bu23,
 case when last_backup_end = 24 then 1 else null end bu24,
 case when last_backup_end = 25 then 1 else null end bu25,
 case when last_backup_end = 26 then 1 else null end bu26,
 case when last_backup_end = 27 then 1 else null end bu27,
 case when last_backup_end = 28 then 1 else null end bu28,
 case when last_backup_end = 29 then 1 else null end bu29,
 case when last_backup_end = 30 then 1 else null end bu30
from (
   select b.file#,  df.name, trunc(sysdate,'DD') - trunc(b.completion_time,'DD') last_backup_end,
          nvl(b.incremental_level,0) incremental_level, s.input_file_scan_only validated
   from v$backup_datafile b , v$datafile df, v$backup_set s
   where b.file# = df.file#
   and b.set_stamp = s.set_stamp
   and b.set_count = s.set_count
   )
)
group by validated, incremental_level, file#, name
order by validated, incremental_level, file#
;

DOC
 ---------------------------------------------------------------------------
 (24) Space usage in FLASH_RECOVERY_AREA_USAGE
 ---------------------------------------------------------------------------
#

select  name,
round(space_limit/1024/1024) mb_total,
round(space_used/1024/1024) mb_used,
round(space_reclaimable/1024/1024) mb_reclaimable,
number_of_files
from  v$recovery_file_dest rfd
;

select
file_type,
round(space_limit*percent_space_used/100/1024/1024) mb_used,
round(space_limit*percent_space_reclaimable/100/1024/1024) mb_reclaimable,
percent_space_used,
percent_space_reclaimable,
frau.number_of_files
from v$recovery_file_dest rfd, v$flash_recovery_area_usage frau
;

DOC
 ---------------------------------------------------------------------------
 (25) Undo Statistics per day (version 10 +)
 ---------------------------------------------------------------------------
#

show parameter undo_retention

set heading off

select 'v$undostat for perioden: ' ||  to_char( min(begin_time),'DD-MM-YYYY HH24:MI') || ' - ' ||  to_char(max(end_time),'DD-MM-YYYY HH24:MI') text from v$undostat;

set heading on

select to_char(begin_time,'yyyy-mm-dd') dato, max(maxquerylen) max_runtime, min(tuned_undoretention) real_undo_retention,
       max(tuned_undoretention) max_undo_retention,
       sum(ssolderrcnt) num_ora1555, sum(nospaceerrcnt) extend_err
from  v$undostat
group by to_char(begin_time,'yyyy-mm-dd')
order by 1;

DOC
 ---------------------------------------------------------------------------
 (26) Resource limits
 ---------------------------------------------------------------------------
#

select resource_name, current_utilization, max_utilization, limit_value
from v$resource_limit
where max_utilization > 0
order by resource_name;

DOC
 ---------------------------------------------------------------------------
 (27) Optimizer mode
 ---------------------------------------------------------------------------
#
select name, value
from v$parameter
where name in ('optimizer_mode','optimizer_features_enable');

DOC
 ---------------------------------------------------------------------------
 (28) Last analyze date for tables
 ---------------------------------------------------------------------------
#

set heading off
col xxx format a100

select 'Stats retention = ' || dbms_stats.get_stats_history_retention xxx from dual
union all
select 'Stats tilbage fra = ' || trunc(dbms_stats.get_stats_history_availability,'DD') 
|| ' - svarende til ' || trunc(sysdate - to_date(trunc(dbms_stats.get_stats_history_availability,'DD')))  
|| ' dage' from dual;

set heading on

col "Monitor"    format 99G999
col "No Monitor" format 99G999
col owner        format a30

with summer as
(
select t.owner
, sum(case when (monitoring = 'YES') then 1 else 0 end) "Monitor"
, sum(case when (monitoring = 'YES') then 0 else 1 end) "No Monitor"
, sum(case when (last_analyzed < sysdate    and last_analyzed >= sysdate-7) then 1 else 0 end ) "0-7 Days"
, sum(case when (last_analyzed < sysdate-7  and last_analyzed >= sysdate-30) then 1 else 0 end ) "7-30 Days"
, sum(case when (last_analyzed < sysdate-30 and last_analyzed >= sysdate-90) then 1 else 0 end ) "30-90 Days"
, sum(case when (last_analyzed < sysdate-90 and last_analyzed >= sysdate-365) then 1 else 0 end ) "90-365 Days"
, sum(case when (last_analyzed < sysdate-365 ) then 1 else 0 end ) "> 1 Year"
, sum(case when (last_analyzed is null) then 1 else 0 end ) "Never"
from dba_tables t
group by t.owner
),
stales as
(
select owner,
sum(case when stattype_locked is not null then 1 else 0 end) locked,
sum(case when stale_stats = 'YES' then 1 else 0 end) stale,
sum(case when stattype_locked is not null and stale_stats ='YES'  then 1 else 0 end) locked_stale
from dba_tab_statistics
where table_name not like 'BIN%'
group by owner
)
select s.*, stale "Stale", locked "Locked", locked_stale "Locked+Stale"
from summer s left outer join stales ss on s.owner = ss.owner
order by s.owner;

select t.owner
, sum(case when (monitoring = 'YES') then 1 else 0 end) "Monitor"
, sum(case when (monitoring = 'YES') then 0 else 1 end) "No Monitor"
, sum(case when (last_analyzed < sysdate    and last_analyzed >= sysdate-7) then 1 else 0 end ) "0-7 Days"
, sum(case when (last_analyzed < sysdate-7  and last_analyzed >= sysdate-30) then 1 else 0 end ) "7-30 Days"
, sum(case when (last_analyzed < sysdate-30 and last_analyzed >= sysdate-90) then 1 else 0 end ) "30-90 Days"
, sum(case when (last_analyzed < sysdate-90 and last_analyzed >= sysdate-365) then 1 else 0 end ) "90-365 Days"
, sum(case when (last_analyzed < sysdate-365 ) then 1 else 0 end ) "> 1 Year"
, sum(case when (last_analyzed is null) then 1 else 0 end ) "Never"
from dba_tables t
where exists
     (select 1 from v$instance where version like '8.%' or version like '9.%' or version like '10.1%')
group by t.owner;

DOC
 ---------------------------------------------------------------------------
 (29) Last analyze date for indexes
 ---------------------------------------------------------------------------
#

select owner
, sum(case when (last_analyzed < sysdate    and last_analyzed >= sysdate-7) then 1 else 0 end ) "0-7 Days"
, sum(case when (last_analyzed < sysdate-7  and last_analyzed >= sysdate-30) then 1 else 0 end ) "7-30 Days"
, sum(case when (last_analyzed < sysdate-30 and last_analyzed >= sysdate-90) then 1 else 0 end ) "30-90 Days"
, sum(case when (last_analyzed < sysdate-90 and last_analyzed >= sysdate-365) then 1 else 0 end ) "90-365 Days"
, sum(case when (last_analyzed < sysdate-365 ) then 1 else 0 end ) "> 1 Year"
, sum(case when (last_analyzed is null) then 1 else 0 end ) "Never"
, sum(case when stale_stats = 'YES' then 1 else 0 end)  "Stale"
, sum(case when stattype_locked is not null then 1 else 0 end) "Locked"
, sum(case when stattype_locked is not null and stale_stats ='YES'  then 1 else 0 end) "Locked+Stale"
from dba_ind_statistics
where table_name not like 'BIN%'
group by owner
order by owner;

select owner
, sum(case when (last_analyzed < sysdate    and last_analyzed >= sysdate-7) then 1 else 0 end ) "0-7 Days"
, sum(case when (last_analyzed < sysdate-7  and last_analyzed >= sysdate-30) then 1 else 0 end ) "7-30 Days"
, sum(case when (last_analyzed < sysdate-30 and last_analyzed >= sysdate-90) then 1 else 0 end ) "30-90 Days"
, sum(case when (last_analyzed < sysdate-90 and last_analyzed >= sysdate-365) then 1 else 0 end ) "90-365 Days"
, sum(case when (last_analyzed < sysdate-365 ) then 1 else 0 end ) "> 1 Year"
, sum(case when (last_analyzed is null) then 1 else 0 end ) "Never"
from dba_indexes t
where exists
     (select 1 from v$instance where version like '8.%' or version like '9.%' or version like '10.1%')
group by owner
order by owner;

DOC
 ---------------------------------------------------------------------------
 (30) Sort information
 ---------------------------------------------------------------------------
#
col value format 999G999G999G999G999

select name, value
from v$sysstat
where name like '%sort%'
order by 1;

col value format a50

DOC
 ---------------------------------------------------------------------------
 (31) PGA information
 ---------------------------------------------------------------------------
#
col value format 999G999G999G999G999
select * from v$pgastat order by 1;
col value format a50

DOC
 ---------------------------------------------------------------------------
 (32) Invalid Objects
 ---------------------------------------------------------------------------
#

column owner          format a30

SELECT o.owner, o.object_name, o.object_type, o. status, o.LAST_DDL_TIME,
       DECODE(NVL(e.SEQUENCE, 0), 0, 'No', 'Yes') ERRORS
FROM  dba_OBJECTS o, dba_errors e
WHERE  o.status <> 'VALID'
AND o.object_name not like 'BIN$%'
--AND    o.object_type <> 'SYNONYM'
AND    o.owner = e.owner (+)
AND    o.object_name = e.NAME (+)
AND    o.OBJECT_TYPE = e.TYPE (+)
AND    e.SEQUENCE (+) = 1
ORDER BY 1, 3, 2;

DOC
 ---------------------------------------------------------------------------
 (33) Number of Invalid Objects for each user
 ---------------------------------------------------------------------------
#

column owner          format a30

select owner, count(*) Antal
from dba_objects
where status <> 'VALID'
AND object_name not like 'BIN$%'
group by owner
order by 1;

column owner          format a20

DOC
 ---------------------------------------------------------------------------
 (33A) Number of Disabled constraints & Triggers for each user
 ---------------------------------------------------------------------------
#

column "Constraint Owner" format a30
column "Unique" format 9999
column "Foreign key" format 9999
column "Check" format 9999
column "Referential" format 9999
column "With Check(View)" format 9999
column "With Read Only (View)" format 9999

column "Trigger Owner" format a30
column "Antal" format 9999

select decode(owner,null, 'I ALT >', owner) "Constraint Owner", 
count(*) "Antal" ,
sum(case when constraint_type = 'P' then 1 else 0 end) "Primary key",
sum(case when constraint_type = 'U' then 1 else 0 end) "Unique",
sum(case when constraint_type = 'F' then 1 else 0 end) "Foreign key",
sum(case when constraint_type = 'C' then 1 else 0 end) "Check",
sum(case when constraint_type = 'R' then 1 else 0 end) "Referential",
sum(case when constraint_type = 'V' then 1 else 0 end) "With Check(View)",
sum(case when constraint_type = 'O' then 1 else 0 end) "With Read Only (View)"
from all_constraints a
where  status = 'DISABLED' 
and A.CONSTRAINT_NAME not like 'BIN%'
group by grouping sets (owner,())
order by owner nulls last
;

select decode(owner,null, 'I ALT >', owner)  "Trigger Owner", 
count(*) "Antal"
from all_triggers a
where A.STATUS = 'DISABLED' 
and A.TRIGGER_NAME not like 'BIN%'
group by grouping sets (owner,())
order by owner nulls last
;

DOC
 ---------------------------------------------------------------------------
 (34) Database components
 ---------------------------------------------------------------------------
#
select comp_id,  comp_name,  schema, version, status
from   dba_registry
order  by comp_name;


-- Forskel mlm. binaries og de installerede versioner?  

set heading off



select  case when version > maxversion then 'OBS: Binaries ' || version_alm || 
          ' er højere version end (alle) komponenterne i databasen (' || maxversion_alm  || ') - se ovenfor' 
            else 'Binaries ' || version_alm || '  - Component versioner ' || maxversion_alm
            end "Component versioner"
from 
(
select (select max(version)                                from dba_registry where comp_id <> 'APEX') maxversion_alm, 
       (select max(lpad(replace(version,'.',null),10,'0')) from dba_registry where comp_id <> 'APEX') maxversion,
       (select lpad(replace(version,'.',null),10,'0')      from v$instance) version,
       (select version                                     from v$instance) version_alm
from  dual
);

set heading on

DOC
 ---------------------------------------------------------------------------
 (35) Tablespace space usage
 ---------------------------------------------------------------------------
#
#
col "Size MB"     format 999G999G999
col "Used MB"     format 999G999G999
col "Free MB"     format 999G999G999
col "MaxSize MB"  format 999G999G999
col "Max Free"    format 999G999G999
col "Auto On/Off" format a11
col obs           format a20

COMPUTE SUM OF "Size MB" ON REPORT 
COMPUTE SUM OF "Used MB" ON REPORT 
COMPUTE SUM OF "MaxSize MB" ON REPORT 
COMPUTE SUM OF "Max Free" ON REPORT 
BREAK ON REPORT

select d.tablespace_name,
       AUTOONOFF "Auto On/Off",
       d.bytes "Size MB",
       round(d.bytes - nvl(f.bytes, 0)) "Used MB",
       round(nvl(f.bytes, 0)) "Free MB",
       round(100*nvl(f.bytes, 0)/d.bytes) FreePct,
       nvl(m.bytes,d.bytes) "MaxSize MB",
       nvl(round(100*nvl(m.bytes-(d.bytes - nvl(f.bytes, 0)), 0)/m.bytes),round(100*nvl(f.bytes, 0)/d.bytes)) MaxFreePct,
     ( nvl(m.bytes,d.bytes) -   (d.bytes - nvl(f.bytes, 0)) ) "Max Free",
       case when d.bytes > nvl(m.bytes,d.bytes) then 'OBS! Maxsize < Size' else null end obs
from   (select tablespace_name, round(sum(bytes)/1024/1024,2) bytes
        from dba_data_files group by tablespace_name) d,
       (select tablespace_name, round(sum(bytes)/1024/1024,2) bytes
        from dba_free_space group by tablespace_name) f,
       (select tablespace_name, round(sum(decode(maxbytes,0,bytes,maxbytes))/1024/1024,2) bytes
        from dba_data_files
        group by tablespace_name) m,
        (select tablespace_name, sum(decode (autoextensible,'YES',1,0)) || ' / ' || sum(decode (autoextensible,'YES',0,1)) AUTOONOFF
         from dba_data_files
         group by tablespace_name) ex
where d.tablespace_name = f.tablespace_name (+)
and d.tablespace_name = m.tablespace_name (+)
and d.tablespace_name = ex.tablespace_name (+)
order by 8;

CLEAR BREAKS
CLEAR COMPUTES

DOC
 ---------------------------------------------------------------------------
 (36) Tempfiles
 ---------------------------------------------------------------------------
#
select tablespace_name, FILE_NAME, BYTES/1048576 "SIZE MB", MAXBYTES/1048576 "MAXSIZE MB"
from dba_temp_files;

DOC
 ---------------------------------------------------------------------------
 (37) DATABASE SIZES
 ---------------------------------------------------------------------------
#
col "TYPE" format A20
COMPUTE SUM OF "Size MB" ON REPORT
BREAK ON REPORT

SELECT 'DATAFILES' "TYPE", ROUND(SUM(BYTES)/1048576) "Size MB" FROM DBA_DATA_FILES
WHERE TABLESPACE_NAME NOT IN (SELECT DISTINCT TABLESPACE_NAME FROM DBA_ROLLBACK_SEGS WHERE OWNER = 'PUBLIC')
UNION
SELECT 'UNDO/RBS' "TYPE", ROUND(SUM(BYTES)/1048576) "Size MB" FROM DBA_DATA_FILES
WHERE TABLESPACE_NAME IN (SELECT DISTINCT TABLESPACE_NAME FROM DBA_ROLLBACK_SEGS WHERE OWNER = 'PUBLIC')
UNION
SELECT 'TEMPFILES' "TYPE", ROUND(SUM(BYTES)/1048576) "Size MB" FROM DBA_TEMP_FILES
UNION
SELECT 'REDOLOGFILES' "TYPE", ROUND(SUM(L.BYTES)/1048576) "Size MB" FROM V$LOGFILE LF, V$LOG L WHERE L.GROUP#=LF.GROUP#;

CLEAR BREAKS
CLEAR COMPUTES

DOC
 ---------------------------------------------------------------------------
 (38) Tablespace Quota monitoring if used
 ---------------------------------------------------------------------------
#
select username, tablespace_name, BYTES/1048576 "MB USED", MAX_BYTES/1048576 "MAX MB",
       round(bytes/MAX_BYTES*100,0) pct_used from dba_ts_quotas
where MAX_BYTES <> -1
order by 1, 2;

DOC
 ---------------------------------------------------------------------------
 (39) Reclaimable space in DBA_RECYCLEBIN
 ---------------------------------------------------------------------------
#

select decode(bin.owner,NULL,'Total for all schemas',bin.owner) schema
    ,ceil(sum(bin.space*par.value)/(1024*1024)) MB
    ,sum(1) "TOTAL NO OF OBJECTS"
    ,sum(case when bin.type = 'TABLE' then 1 else 0 end) tables
    ,sum(case when bin.type = 'LOB' then 1 else 0 end) lobs
    ,sum(case when bin.type = 'INDEX' then 1 else 0 end) indexes
    ,sum(case when bin.type = 'LOB_INDEX' then 1 else 0 end) lob_indexes
    ,sum(case when BIN.type in ('TABLE','INDEX','LOB','LOB_INDEX') then 0 else 1 end) other
    ,min(droptime) oldest_droptime
from dba_recyclebin bin, v$parameter par
where bin.ts_name is 
    not null and par.name='db_block_size'
group by grouping sets ( bin.owner, ())
;

DOC
 ---------------------------------------------------------------------------
 (40) Redolog switches - i antal og GB
 ---------------------------------------------------------------------------
#

col sekunder format a10

select name, decode(value,0,'n/a',value) sekunder, isdefault 
from v$parameter where name = 'archive_lag_target';

col gruppe format 99999;
col m_bytes format 99999;
col filnavn format a80

select Lf.GROUP# gruppe, l.bytes/1024/1024 m_bytes, lf.member filnavn
from v$log l
join v$logfile lf on lf.group# = l.group#
order by  lf.group#, member desc;

col HH01  format 999;
col HH02  format 999;
col HH03  format 999;
col HH04  format 999;
col HH05  format 999;
col HH06  format 999;
col HH07  format 999;
col HH08  format 999;
col HH09  format 999;
col HH10  format 999;
col HH11  format 999;
col HH12  format 999;
col HH13  format 999;
col HH14  format 999;
col HH15  format 999;
col HH16  format 999;
col HH17  format 999;
col HH18  format 999;
col HH19  format 999;
col HH20  format 999;
col HH21  format 999;
col HH22  format 999;
col HH23  format 999;
col HH24  format 999;

col gruppe format 99999;
col m_bytes format 99999;
col filnavn format a80

col GB    format 999.99;
col arch_logs format 9999;

with dagsum as
(
select substr(to_char(first_time,'YYYY/MM/DD, DY'),1,15) dag,  round(sum(blocks*block_size/1024/1024/1024),2) GB
 from v$archived_log
where dest_id = (select min(dest_id)  from  v$archive_dest where status = 'VALID' and target = 'PRIMARY')
group by  substr(to_char(first_time,'YYYY/MM/DD, DY'),1,15)
)
select a.*,
      nvl(hh01,0)+nvl(hh02,0)+nvl(hh03,0)+nvl(hh04,0)+nvl(hh05,0)+
    nvl(hh06,0)+nvl(hh07,0)+nvl(hh08,0)+nvl(hh09,0)+nvl(hh10,0)+
    nvl(hh11,0)+nvl(hh12,0)+
    nvl(hh13,0)+nvl(hh14,0)+nvl(hh15,0)+nvl(hh16,0)+nvl(hh17,0)+
    nvl(hh18,0)+nvl(hh19,0)+nvl(hh20,0)+nvl(hh21,0)+nvl(hh22,0)+
    nvl(hh23,0)+nvl(hh24,0) ialt, gb
from (select substr(to_char(first_time,'YYYY/MM/DD, DY'),1,15) DAG,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'00',1,NULL))  HH24,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'01',1,NULL))  HH01,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'02',1,NULL))  HH02,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'03',1,NULL))  HH03,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'04',1,NULL))  HH04,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'05',1,NULL))  HH05,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'06',1,NULL))  HH06,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'07',1,NULL))  HH07,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'08',1,NULL))  HH08,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'09',1,NULL))  HH09,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'10',1,NULL))  HH10,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'11',1,NULL))  HH11,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'12',1,NULL))  HH12,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'13',1,NULL))  HH13,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'14',1,NULL))  HH14,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'15',1,NULL))  HH15,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'16',1,NULL))  HH16,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'17',1,NULL))  HH17,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'18',1,NULL))  HH18,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'19',1,NULL))  HH19,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'20',1,NULL))  HH20,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'21',1,NULL))  HH21,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'22',1,NULL))  HH22,
     sum(decode(substr(to_char(first_time,'HH24'),1,2),'23',1,NULL))  HH23
from    v$log_history h
where   first_time > sysdate -40
group   by substr(to_char(first_time,'YYYY/MM/DD, DY'),1,15)
order   by substr(to_char(first_time,'YYYY/MM/DD, DY'),1,15)
) a
left outer join dagsum d on d.dag = a.dag
order by 1;

--- tisvarende bare med antal GB

col HH01  format 999.99;
col HH02  format 999.99;
col HH03  format 999.99;
col HH04  format 999.99;
col HH05  format 999.99;
col HH06  format 999.99;
col HH07  format 999.99;
col HH08  format 999.99;
col HH09  format 999.99;
col HH10  format 999.99;
col HH11  format 999.99;
col HH12  format 999.99;
col HH13  format 999.99;
col HH14  format 999.99;
col HH15  format 999.99;
col HH16  format 999.99;
col HH17  format 999.99;
col HH18  format 999.99;
col HH19  format 999.99;
col HH20  format 999.99;
col HH21  format 999.99;
col HH22  format 999.99;
col HH23  format 999.99;
col HH24  format 999.99;

with dagsum as
(
select substr(to_char(first_time,'YYYY/MM/DD, DY'),1,15) dag,  round(sum(blocks*block_size/1024/1024/1024),2) GB, count(*) arch_logs
 from v$archived_log
where dest_id = (select min(dest_id)  from  v$archive_dest where status = 'VALID' and target = 'PRIMARY')
group by  substr(to_char(first_time,'YYYY/MM/DD, DY'),1,15)
)
select a.*, gb , arch_logs
from (select substr(to_char(first_time,'YYYY/MM/DD, DY'),1,15) DAG,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'00',blocks*block_size/1024/1024/1024,NULL)),2)  HH24,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'01',blocks*block_size/1024/1024/1024,NULL)),2)  HH01,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'02',blocks*block_size/1024/1024/1024,NULL)),2)  HH02,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'03',blocks*block_size/1024/1024/1024,NULL)),2)  HH03,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'04',blocks*block_size/1024/1024/1024,NULL)),2)  HH04,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'05',blocks*block_size/1024/1024/1024,NULL)),2)  HH05,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'06',blocks*block_size/1024/1024/1024,NULL)),2)  HH06,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'07',blocks*block_size/1024/1024/1024,NULL)),2)  HH07,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'08',blocks*block_size/1024/1024/1024,NULL)),2)  HH08,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'09',blocks*block_size/1024/1024/1024,NULL)),2)  HH09,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'10',blocks*block_size/1024/1024/1024,NULL)),2)  HH10,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'11',blocks*block_size/1024/1024/1024,NULL)),2)  HH11,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'12',blocks*block_size/1024/1024/1024,NULL)),2)  HH12,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'13',blocks*block_size/1024/1024/1024,NULL)),2)  HH13,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'14',blocks*block_size/1024/1024/1024,NULL)),2)  HH14,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'15',blocks*block_size/1024/1024/1024,NULL)),2)  HH15,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'16',blocks*block_size/1024/1024/1024,NULL)),2)  HH16,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'17',blocks*block_size/1024/1024/1024,NULL)),2)  HH17,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'18',blocks*block_size/1024/1024/1024,NULL)),2)  HH18,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'19',blocks*block_size/1024/1024/1024,NULL)),2)  HH19,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'20',blocks*block_size/1024/1024/1024,NULL)),2)  HH20,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'21',blocks*block_size/1024/1024/1024,NULL)),2)  HH21,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'22',blocks*block_size/1024/1024/1024,NULL)),2)  HH22,
     round(sum(decode(substr(to_char(first_time,'HH24'),1,2),'23',blocks*block_size/1024/1024/1024,NULL)),2)  HH23
from    v$archived_log h
where   first_time > sysdate -40
group   by substr(to_char(first_time,'YYYY/MM/DD, DY'),1,15)
order   by substr(to_char(first_time,'YYYY/MM/DD, DY'),1,15)
) a
left outer join dagsum d on d.dag = a.dag
order by 1;

DOC
 ---------------------------------------------------------------------------
 (41) Segments close to max_extents (max 20 left or max 20% left)
 ---------------------------------------------------------------------------
#

select owner, segment_name, segment_type, bytes/1024/1024 "MB",
       extents, max_extents, max_extents-extents free_extents,
       trunc((extents/max_extents)*100,2) "%"
from   dba_segments
where  segment_type in ('TABLE','INDEX')
and    (extents/max_extents*100 > 80  or
        max_extents - extents < 21)
order by owner,  (extents/max_extents) desc;

DOC
 ---------------------------------------------------------------------------
 (42) Blocking locks
 ---------------------------------------------------------------------------
#
select SID, TYPE, LMODE, ctime, REQUEST from v$lock where block = 1;

select to_char(sysdate,'DD-MM-YYYY HH24:MI:SS') || ': ' ||
    s1.username || '('|| s1.osuser ||')@' || s1.machine
    || ' ( SID=' || s1.sid || ' ) Time=' || l1.ctime || ' ' || s1.program || ' blokerer for ' || chr(10)
    || s2.username || '('|| s2.osuser ||')@' || s2.machine || ' ( SID=' || s2.sid || ' )' || s2.program
    || ' med en lock af typen ' || l1.type AS blocking_status
    from v$lock l1, v$session s1, v$lock l2, v$session s2
    where s1.sid=l1.sid and s2.sid=l2.sid
    and l1.BLOCK=1 and l2.request > 0
    and l1.id1 = l2.id1
    and l2.id2 = l2.id2 ;

DOC
 ---------------------------------------------------------------------------
 (43) 2 phased commits - Pending transactions
 ---------------------------------------------------------------------------
#
select local_tran_id, state, fail_time, host, db_user
from dba_2pc_pending;

DOC
 ---------------------------------------------------------------------------
 (44) Check alertlog for errors!
 ---------------------------------------------------------------------------
#

col alertlog_lokation format a100
select value alertlog_lokation from v$parameter where name = 'background_dump_dest';

DOC
 ---------------------------------------------------------------------------
 (EE) EXTRAS EXTRAS
 ---------------------------------------------------------------------------
#

col username format a20

DOC
 ---------------------------------------------------------------------------
 (E01) Memory
 ---------------------------------------------------------------------------
#

var return_value refcursor

declare   
   xx sys_refcursor;
   v11_stmt  varchar2(200) := 'select * from v$memory_dynamic_components';
   v10_stmt  varchar2(200) := 'select * from v$sga_dynamic_components';
begin
      if &dbv > 10 then
         open xx for v11_stmt;
      else
         open xx for v10_stmt;
      end if;
      :return_value := xx;
end;
/
print return_value

DOC
 ---------------------------------------------------------------------------
 (E02) Histograms pr. owner (10+)
 ---------------------------------------------------------------------------
#

select owner, count(distinct table_name) antal_tab_view, count(distinct table_name || '.' || column_name) antaL_col,
       sum(decode(histogram,'HEIGHT BALANCED',1,0)) antal_hist_height,
       sum(decode(histogram,'FREQUENCY',1,0)) antal_hist_freq,
       max(last_analyzed) last_analyzed
from dba_tab_columns
group by owner
order by last_analyzed desc nulls last;

DOC
 ---------------------------------------------------------------------------
 (E03) Space consumption pr. schema
 ---------------------------------------------------------------------------
#

COMPUTE SUM OF "MB I alt" ON REPORT
COMPUTE SUM OF "TABLE" ON REPORT
COMPUTE SUM OF "INDEX" ON REPORT
COMPUTE SUM OF lobsegment ON REPORT
COMPUTE SUM OF lobindex ON REPORT
COMPUTE SUM OF lobpartition ON REPORT
COMPUTE SUM OF indexpartition ON REPORT
COMPUTE SUM OF nestedtable ON REPORT
COMPUTE SUM OF "ROLLBACK" ON REPORT
COMPUTE SUM OF "CLUSTER" ON REPORT
COMPUTE SUM OF "type2undo" ON REPORT
COMPUTE SUM OF "tablepartition" ON REPORT

BREAK ON REPORT

select owner, round(sum(s.bytes)/1024/1024) "MB I alt"
, round(sum(case when segment_type = 'TABLE'           then bytes else 0 end)/1024/1024) "TABLE"
, round(sum(case when segment_type = 'INDEX'           then bytes else 0 end)/1024/1024) "INDEX"
, round(sum(case when segment_type = 'LOBSEGMENT'      then bytes else 0 end)/1024/1024) lobsegment
, round(sum(case when segment_type = 'LOBINDEX'        then bytes else 0 end)/1024/1024) lobindex
, round(sum(case when segment_type = 'LOB PARTITION'   then bytes else 0 end)/1024/1024) lobpartition
, round(sum(case when segment_type = 'TABLE PARTITION' then bytes else 0 end)/1024/1024) tablepartition
, round(sum(case when segment_type = 'INDEX PARTITION' then bytes else 0 end)/1024/1024) indexpartition
, round(sum(case when segment_type = 'NESTED TABLE'    then bytes else 0 end)/1024/1024)  nestedtable
, round(sum(case when segment_type = 'ROLLBACK'        then bytes else 0 end)/1024/1024) "ROLLBACK"
, round(sum(case when segment_type = 'CLUSTER'         then bytes else 0 end)/1024/1024) "CLUSTER"
, round(sum(case when segment_type = 'TYPE2 UNDO'      then bytes else 0 end)/1024/1024) type2undo
from dba_segments s
group by owner
order by 2 desc;

clear breaks
clear computes

DOC
 ---------------------------------------------------------------------------
 (E04) Object types pr. schema
 ---------------------------------------------------------------------------
#

column tabeller format 999999
column views format 999999
column synonymer format 999999
column sekvenser format 999999
column pakker format 999999
column funktioner format 999999
column procedurer format 999999
column typer format 999999
column andet format 999999
column ialt format 99999999

select   decode(OWNER,NULL,'>> I ALT', owner) schema,
         sum(decode(o.object_type, 'TABLE',1,'')) tabeller,
         sum(decode(o.object_type, 'VIEW',1,'')) views,
         sum(decode(o.object_type, 'SYNONYM',1,'')) synonymer,
         sum(decode(o.object_type, 'SEQUENCE',1,'')) sekvenser,
         sum(decode(o.object_type, 'PACKAGE',1,'PACKAGE BODY',1,'')) pakker,
         sum(decode(o.object_type, 'FUNCTION',1,'')) funktioner,
         sum(decode(o.object_type, 'PROCEDURE',1,'')) procedurer,
         sum(decode(o.object_type,'TYPE',1,'')) typer,
         sum(case when o.object_type not in ('TABLE','VIEW','SYNONYM','SEQUENCE','PACKAGE','PACKAGE BODY','FUNCTION','PROCEDURE','TYPE') then 1 else null end) andet,
         count(*) ialt
from    dba_objects o
group by grouping sets(OWNER,())
order by owner nulls last;

DOC
 ---------------------------------------------------------------------------
 (E05) TOP 15 - largest tables shown (- diverse sys skemaer)
 ---------------------------------------------------------------------------
#
select * from
(
select t.owner
, t.table_name
, t.tablespace_name
, t.num_rows
, t.blocks
, t.last_analyzed
, t.monitoring
, round(sum(s.bytes)/1024/1024) "MB Data"
from dba_tables t, dba_segments s
where s.owner (+) = t.owner
and s.segment_name (+)= t.table_name
and t.owner not in('SYS','SYSTEM','WKSYS','MDSYS','XDB')
group by t.owner, t.table_name, t.num_rows, t.tablespace_name, t.blocks, t.last_analyzed, t.monitoring
order by round(sum(s.bytes)/1024/1024) desc nulls last, t.owner, t.table_name
)
where rownum < 16;

DOC
 ---------------------------------------------------------------------------
 (E06) TOP 15 - sum(index) om tables (- diverse sys skemaer)
 ---------------------------------------------------------------------------
#
select * from
(
select t.owner
, t.table_name
, t.tablespace_name
, count(distinct t.index_name) Ant_index
, min(t.last_analyzed) last_analyzed
, round(sum(s.bytes)/1024/1024) "MB Index"
from dba_indexes t, dba_segments s
where s.owner (+) = t.owner
and s.segment_name (+)= t.index_name
and t.owner not in('SYS','SYSTEM','WKSYS','MDSYS','XDB')
group by t.owner, t.table_name, t.tablespace_name
order by round(sum(s.bytes)/1024/1024) desc nulls last, t.owner, t.table_name
)
where rownum < 16;

DOC
 ---------------------------------------------------------------------------
 (E07) TOP 15 - largest indexes  (- diverse sys skemaer)
 ---------------------------------------------------------------------------
#
select * from
(
select t.index_name
, t.owner
, t.table_name
, t.distinct_keys
, t.num_rows
, decode(t.uniqueness,'UNIQUE','UNI',NULL) UNI
, t.last_analyzed
, round(sum(s.bytes)/1024/1024) "MB Index"
from dba_indexes t, dba_segments s
where s.owner (+) = t.owner
and s.segment_name (+)= t.index_name
and t.owner not in('SYS','SYSTEM','WKSYS','MDSYS','XDB')
group by t.index_name, t.owner, t.table_name, t.last_analyzed, t.distinct_keys, t.uniqueness, t.num_rows
order by round(sum(s.bytes)/1024/1024) desc nulls last
)
where rownum < 16;

DOC
 ---------------------------------------------------------------------------
 (E08) TOP 15 - most loaded func/package/procedure
 ---------------------------------------------------------------------------
#

select * from (
SELECT   doc.owner, doc.NAME, doc.TYPE, doc.loads, doc.sharable_mem
FROM     v$db_object_cache doc, v$instance ins
WHERE    doc.loads > 2
AND      doc.TYPE IN ('PACKAGE', 'PACKAGE BODY', 'FUNCTION', 'PROCEDURE')
ORDER BY doc.loads DESC)
where rownum < 16;

DOC
 ---------------------------------------------------------------------------
 (E09) Fejl fra RMANS Backup log (past 14 days) - (10+)
 ---------------------------------------------------------------------------
#

col "Status" format a10
col "Backup Id" format a20
col "Input Size" format a12
col "Output Size" format a12
col "Output Rate (Per Sec)" format a10
col "Input Size" format a10
col "Duration" format A10
col "Device" format a10
col "Start Time" format a22
col "End Time" format a22

SELECT   /*+ RULE */ command_id  AS "Backup Id",
         b.status AS "Status",
         TO_CHAR (b.start_time, 'dd.mm.YYYY HH24:MI:SS') AS "Start Time",
         TO_CHAR (b.end_time, 'dd.mm.YYYY HH24:MI:SS') AS "End Time",
         b.time_taken_display AS "Duration",
         b.input_type || (select nvl2(min(incremental_level),':' || min(incremental_level), null) from V$BACKUP_DATAFILE_DETAILS d where B.SESSION_KEY = D.SESSION_KEY) AS "Type",
         b.output_device_type AS "Device",
         b.input_bytes_display AS "Input Size",
         b.output_bytes_display AS "Output Size",
         b.output_bytes_per_sec_display AS "Output Rate (Per Sec)"
    FROM V$RMAN_BACKUP_JOB_DETAILS b 
where b.start_time > trunc(sysdate)-14
ORDER BY b.start_time DESC;

col output format a100
col status format a30

select * from v$rman_configuration;

select  /*+ RULE */ min(start_time) rmanlog_fra, max(start_time)  rmanlog_til
from v$rman_status s, v$rman_output o
where o.rman_status_recid = s.recid
and o.rman_status_stamp = s.stamp;

select   /*+ RULE */  
add_months(date '1988-1-1', trunc(o.stamp/(31*86400))) + mod(o.stamp,(31*86400)) /
86400 start_time,
output, operation, status
from v$rman_status s, v$rman_output o
where o.rman_status_recid = s.recid
and o.rman_status_stamp = s.stamp
and start_time > sysdate - 15
and status not in ('COMPLETED','RUNNING')
order by 1, o.recid;

DOC
 ---------------------------------------------------------------------------
 (E10) Session stats for users - now !
 ---------------------------------------------------------------------------
#

SELECT   (DECODE ((INITCAP (se.username)), NULL, 'SYS', se.username)
          ) username,
          count(distinct ss.sid) ant_sessions,
          round(SUM (DECODE (sn.NAME, 'redo size', ss.VALUE, 0))/1024) redosize_KB,
      round(MAX (DECODE (sn.NAME, 'redo size', ss.VALUE, 0))/1024) max_redosize_KB,
          SUM (DECODE (sn.NAME, 'sorts (disk)', ss.VALUE, 0)) sort_disk,
          SUM (DECODE (sn.NAME, 'sorts (memory)', ss.VALUE, 0)) sort_memory,
          SUM (DECODE (sn.NAME, 'consistent gets', ss.VALUE, 0)) consisgets,
          SUM (DECODE (sn.NAME, 'db block gets', ss.VALUE, 0)) dbblkgets,
          SUM (DECODE (sn.NAME, 'physical reads', ss.VALUE, 0)) physreads,
          ROUND(  (  SUM (DECODE (sn.NAME, 'consistent gets', ss.VALUE, 0))
             + SUM (DECODE (sn.NAME, 'db block gets', ss.VALUE, 0))
             - SUM (DECODE (sn.NAME, 'physical reads', ss.VALUE, 0))
            )
          / (  SUM (DECODE (sn.NAME, 'consistent gets', ss.VALUE, 0))
             + SUM (DECODE (sn.NAME, 'db block gets', ss.VALUE, 0))
             + 1
            ), 4)
          * 100 hitratio
    FROM v$sesstat ss, v$statname sn, v$session se
   WHERE ss.SID = se.SID
     AND sn.statistic# = ss.statistic#
     AND ss.VALUE != 0
     AND sn.NAME IN ('db block gets', 'consistent gets', 'physical reads','sorts (memory)','sorts (disk)','redo size')
     and se.type <> 'BACKGROUND'
   GROUP BY se.username
ORDER BY 1,2;

DOC
 ---------------------------------------------------------------------------
 (E11) TOP 15 - heavy pga memory users
 ---------------------------------------------------------------------------
#

select * from (
select nvl(a.username,'(oracle)') AS username, osuser, a.sid,
       a.machine, a.module, a.program, trunc(b.value/1024) AS pga_memory_kb
from   v$session a, v$sesstat b, v$statname c
where  a.sid = b.sid
and    b.statistic# = c.statistic#
and    c.name = 'session pga memory'
and    a.program is not null
and    a.type <> 'BACKGROUND'
order by  pga_memory_kb desc, a.module, username)
where rownum < 16;
DOC
 ---------------------------------------------------------------------------
 (E12) TOP 15 - heavy redo users
 ---------------------------------------------------------------------------
#

select * from (
select nvl(a.username,'(oracle)') AS username, osuser, a.sid,
       a.machine, a.module, a.program, trunc(b.value/1024) AS redo_memory_kb
from   v$session a, v$sesstat b, v$statname c
where  a.sid = b.sid
and    b.statistic# = c.statistic#
and    c.name = 'redo size'
and    a.program is not null
and    a.type <> 'BACKGROUND'
order by  redo_memory_kb desc, a.module, username)
where rownum < 16;

DOC
 ---------------------------------------------------------------------------
 (E13) No of users logged in active/inactive/killed
 ---------------------------------------------------------------------------
#

col status    format a10
compute sum of count on report
break on report

select username, machine, status, count(*) Count
from v$session
where type = 'USER'
group by username, machine, status
order by 1,2;

select status, count(*) count
from v$session
where type = 'USER'
group by  status
order by 1;

clear breaks

DOC
 ---------------------------------------------------------------------------
 (E14) NLS Settings for database
 ---------------------------------------------------------------------------
#

col parameter format a40
col value format a40

select * 
from nls_database_parameters;

DOC
 ---------------------------------------------------------------------------
 (E15) OS Info
 ---------------------------------------------------------------------------
#
col stat_name format a30
col value format 99999999999999999
col comments format a50

select STAT_NAME, VALUE
from V$OSSTAT;

DOC
 ---------------------------------------------------------------------------
 (E16) REDO logs 
 ---------------------------------------------------------------------------
#

col value format a30

select name, value, isdefault 
from v$parameter
where name like '%mttr%' or name like '%checkpoint%' or name like 'archive_lag_target';

select *
from v$log
order by group#;

set heading off

select case when max(L.SEQUENCE#)+1- min (L.SEQUENCE#)-count(*) = 0 then 
       null else 'Kig lige på redologs, archiving - der er noget uldent her !!!' end obs
from v$log l
;

set heading on


DOC
 ---------------------------------------------------------------------------
 (E17) REDO log grupper
 ---------------------------------------------------------------------------
#

col "COMMENT" format a60

with loggrupper as
(
select (select count(distinct group#) from v$logfile where type = 'ONLINE') antal_online
, (select count(distinct group#) from v$logfile where type = 'STANDBY') antal_standby
, protection_mode
from v$database
)
select lg.* 
, case when antal_online >= antal_standby and protection_mode <> 'MAXIMUM PERFORMANCE'  
       then 'OBS - Der skal mindst være een STANDBY gruppe extra' else null end "COMMENT"
from loggrupper lg;

DOC
 ---------------------------------------------------------------------------
 (E18)  System Stats / Fixed Stats
 ---------------------------------------------------------------------------
#

select *  
from sys.aux_stats$
;

select 'Fixed table stats (X$)' stat, count(*) antal, max(last_analyzed) last_analyzed
from DBA_TAB_STATISTICS 
where object_type ='FIXED TABLE'
;

DOC
 ---------------------------------------------------------------------------
 (E19) Datafiles  
 ---------------------------------------------------------------------------
#

col obs format a40
col tablespace_name format a20
col name format a40

select tablespace_name, name, rfile#, creation_time,  autoextensible auto, block_size, round(vdf.bytes/1024/1024) MBYTES, 
round(increment_by*block_size/1024/1024) NEXT_MBYTES,
round(maxbytes/1024/1024) MBYTES_MAX, increment_by next_blks, 
decode(increment_by,1,'> Increment=1 blk ',null) ||
decode(maxbytes,vdf.bytes,'> Datafile in max ' ,null) || 
case when autoextensible='YES' and vdf.bytes> maxbytes then '> size>max ' else null end obs
from v$datafile vdf
join  dba_data_files df on DF.FILE_ID = VDF.FILE#
order by 1, 2
;

DOC
 ---------------------------------------------------------------------------
 (E20) File systems <> Datafiles  
 ---------------------------------------------------------------------------
#

col filesystem format a60
col gb         format 999G999G999

select substr(name,1, instr(replace(name,'\','/'),'/',-1,1)) filesystem
, round(sum(bytes)/(1024*1024*1024)) gb 
from v$datafile 
group by substr(name,1, instr(replace(name,'\','/'),'/',-1,1))
;

DOC
 ---------------------------------------------------------------------------
 (E21) Objects in SYSTEM Tablespace
 ---------------------------------------------------------------------------
#

with objekter as
(
select owner, segment_name name, segment_type type, round(sum(bytes/(1024*1024))) mb
from dba_segments
where tablespace_name = 'SYSTEM' 
and owner not in ('SYSTEM', 'SYS', 'OUTLN','ORDSYS','CTXSYS','MDSYS','WMSYS','LBACSYS','ORDDATA','MDGSYS','DBSNMP')
group by owner, segment_name, segment_type
)
select case when grouping_id(o.owner) = 1 then 'Grand total '  
                when grouping_id(o.owner, o.name, o.type, A.CREATED, A.LAST_DDL_TIME) >  0 then 'Total for ' || o.owner 
                else o.owner end owner
, o.name, o.type, A.CREATED, A.LAST_DDL_TIME , sum(mb) mb
from objekter o join all_objects a on A.owner = o.owner and A.OBJECT_NAME = o.name and A.OBJECT_TYPE = o.type
group by grouping sets (( o.owner, o.name, o.type, A.CREATED, A.LAST_DDL_TIME),(o.owner),())
order by o.owner, name
;

DOC
 ---------------------------------------------------------------------------
 (E22) Objects in cache
 ---------------------------------------------------------------------------
#

col data_mb format 999999 heading 'MB Data'
col index_mb format 999999 heading 'MB Index'
col andet_mb format 999999 heading 'MB Other'
col ialt_mb format 999999 heading 'MB Total'
col db_keep_cache_size format 999999 heading 'db_keep_cache_size'
col com format a40 heading 'Comment'

with caches as (
select  (select  round(sum(bytes)/1048576) MB from dba_segments where BUFFER_POOL = 'KEEP' and segment_type = 'TABLE') data_mb
, (select round(sum(bytes)/1048576) MB from dba_segments where BUFFER_POOL = 'KEEP' and segment_type = 'INDEX') index_mb
, (select round(sum(bytes)/1048576) from dba_segments where BUFFER_POOL = 'KEEP' and segment_type not in ('INDEX','TABLE')) andet_mb
, (select round(to_number(value)/1048576) from v$parameter where name = 'db_keep_cache_size') db_keep_cache_size
from dual)
-------------------------------
select data_mb , index_mb, andet_mb, nvl(data_mb,0)+nvl(index_mb,0)+nvl(andet_mb,0) ialt_mb , db_keep_cache_size,
case when nvl(data_mb,0)+nvl(index_mb,0)+nvl(andet_mb,0) > db_keep_cache_size then 'Cache kan ikke rumme de cachede objekter' else null end COM
from caches
;

DOC
 ---------------------------------------------------------------------------
 (E23) Blokerende låse V2
 ---------------------------------------------------------------------------
#

/*
with blokerende as
(
select * from v$lock
where type='TM'
)
select 'User: ' ||
    s1.username || '('|| s1.osuser ||')@' || s1.machine
    || ' ( SID=' || s1.sid || ',' || s1.serial# || nvl2(s1.client_identifier,'-' || s1.client_identifier,s1.client_identifier) || ' ) Sekunder=' 
    || l1.ctime || ' ' || s1.program || ' blokerer for ' || chr(10) || '          '
    || s2.username || '('|| s2.osuser ||')@' || s2.machine || ' ( SID=' || s2.sid || nvl2(s2.client_identifier,'-' || s2.client_identifier,s2.client_identifier) || ' )' 
    || s2.program     || ' med en lock af typen ' || l1.type || ' på ' || do.owner || '.' || do.object_name AS blocking_status 
    from v$lock l1, v$session s1, v$lock l2, v$session s2, dba_objects do, blokerende bl
    where s1.sid=l1.sid and s2.sid=l2.sid
    and l1.BLOCK=1 and l2.request > 0
    and l1.id1 = l2.id1
    and l1.id2 = l2.id2
    and bl.sid (+) = l2.sid
    and bl.id1 = do.object_id (+)
order by l1.ctime desc
;
*/

col sessioner format a15
col lv format 99
col hvad format a70
col sek format 999999
col status format a10
col sql_text format a80
set recsep off

with lock_holders as
( 
  select w.session_id waiting_session
      ,  h.session_id holding_session
      ,  w.lock_type 
      ,  h.mode_held
      ,  w.mode_requested
      ,  w.lock_id1
      ,  w.lock_id2
  from dba_locks w
  join dba_locks h  on  w.lock_type = h.lock_type and  w.lock_id1 = h.lock_id1 and w.lock_id2 = h.lock_id2
  where
       h.blocking_others =  'Blocking'
  and  h.mode_held      !=  'None'
  and  h.mode_held      !=  'Null'
  and  w.mode_requested !=  'None'
),
lock_holders2 as
(
select * from lock_holders union all
(
    select holding_session, null, 'None', null, null, null, null  from lock_holders 
    minus
    select waiting_session, null, 'None', null, null, null, null  from lock_holders
)
),
lock_holders3 as
(
select  
   lpad(' ',3*(level-1)) || waiting_session sessioner, level lv, rownum rn
,  h.*
,  s1.username || '@' || s1.machine || '\' || s1.osuser ||  ' ( SID=' || s1.sid || ',' 
        || s1.serial# || nvl2(s1.client_identifier,'-' || s1.client_identifier,s1.client_identifier) || ' ' || s1.program || ' )' hvem
,  s1.seconds_in_wait sek 
,  s1.status 
,  s1.sql_id
,  s1.row_wait_obj# row_wait_obj
,  S1.EVENT
from lock_holders2 h
 join v$session s1 on s1.sid = h.waiting_session
connect by  prior waiting_session = holding_session
start with holding_session is null
)
select   
   Sessioner, lv ----, holding_session, waiting_session
,  hvem || chr(10) || case when lock_type = 'None' then null else '  Lock ' || lock_type || ' (' || l1.type || ') ' ||  o.owner || nvl2(o.object_name,'.',null) || o.object_name 
    || chr(10) || '  Wait: ' || event || ' Lock mode request:' 
    || case request 
    when 0 then 'none'
    when 1 then null
    when 2 then 'row-S (SS)'
    when 3 then 'row-X (SX)'
    when 4 then 'share (S)'
    when 5 then 'S/Row-X (SSX)'
    when 6 then 'exclusive (X)' end end hvad
,  sek 
,  h.status  
,  (select sql_text from v$sql sq where sq.sql_id = h.sql_id and rownum < 2) sql_text
from lock_holders3 h
 left outer join dba_objects o on o.object_id = h.row_wait_obj
 left outer join v$lock l1 on L1.ID1 = h.lock_id1 and l1.id2 = h.lock_id2 and l1.sid = h.waiting_session   
order by rn
;

-----------------------------
-- RUN POST SQL SCRIPT
-----------------------------
@check_postscript.sql

-----------------------------
-- RUN CUSTOM CHECK
-----------------------------
@custom_check.sql

-----------------------------
-- RUN OEBS tjek måske
-----------------------------
@oebs_start.sql

-----------------------------
-- RUN MAINTENANCE SCRIPT
-- Rotate alertlog etc.
-----------------------------

set serveroutput on
set verify off

variable o_cmd     varchar2(100);
column hostcmd new_value o_cmd     noprint

declare
w_cmd varchar2(100);
begin

  if instr(upper('&os'),'WIN') > 0 then
     w_cmd := 'check_maintenance.cmd';
  else
     w_cmd := './CHECK_MAINTENANCE.SH';
  end if;

  dbms_output.put_line('Vi koerer ' || '&os' || ' og kommandoen er ' || w_cmd);
  :o_cmd := w_cmd;
end;
/

select :o_cmd hostcmd from dual;

---------------------------------------------------------------
-- Hvilken form for hostkommando skal køres? Unix eller Win?
---------------------------------------------------------------

host &o_cmd &logdir

-----------------
-- The end
-----------------

spool off
exit
