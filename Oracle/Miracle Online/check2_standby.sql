-- *************************************************************************************************
-- Miracle online check script af standby DB

-----------------------------------------------------------
-- RUN Spool SCRIPT
-- Setup spooling file 1: win/unix 2: logdestination
-- 18.02.2010, JMA: Change the (5) not to include archive info
--                  Add (5.1) to include detailed info on the archive process
-- 16.10.2011, JMA: Fix issue with impropper archive log numbers displayed after failover
-- 27.06.2012, JMA: Fix issue with impropper archive log numbers after failover (12) & (13) due to not using 
--                  SELECT MAX (RESETLOGS_TIME) FROM v$log_history
-----------------------------------------------------------
define os = &1
define logdir = &2
set echo off

@@spool &1 &2

-----------------------------------------------------------
-- RUN PRE SQL SCRIPT SCRIPT
-- 
-----------------------------------------------------------7
@@check_standby_prescript.sql

alter session set nls_territory=denmark;
alter session set nls_date_format='DD-MON-RRRR HH24:MI';

set line      180
set pagesize  40
set trimspool on

col host_name       format a15
col instance_name   format a15
col dest_name       format a30
col destination     format a50
col "Tjek version"  format a15
col "Bagefter Dage HH:MI:SS" format a30
col name            format a40
col standby_status  format a110
col archive_status  format a100
col log_process_status   format a100
col value           format a90
col gb          format 99G999G999
col checked     format a21
col BY          format a10
col client      format a20
col osuser      format a20
col user_ip     format a15
col isdba       format a5
col db          format a8
col server_name format a15
col server_ip   format a15
col component   format a30

--  Bruges til at kunne skelne mlm. DB version længere nede
col db_v        new_value dbv  format 999      
col db_v2       new_value dbv2 format 99999D9 

DOC
 ---------------------------------------------------------------------------
 (1) Check runtime
 ---------------------------------------------------------------------------
#

select sysdate "CHECK RUNTIME" from dual;

select 
    to_char(sysdate,'DD-MM-YYYY HH24:MI:SS') checked
    ,sys_context('USERENV','CURRENT_USER')  "BY"
    ,sys_context('USERENV','HOST')  client
    ,sys_context('USERENV','OS_USER')  osuser
    ,sys_context('USERENV','IP_ADDRESS') user_ip
    ,sys_context('USERENV','ISDBA')  isdba
    ,sys_context('USERENV','DB_NAME')  db
    ,host_name server_name
   -- ,UTL_INADDR.GET_HOST_ADDRESS server_ip
    ,to_number(substr(version,1,(instr(version,'.'))-1)) db_v
    ,to_number(substr(version,1,(instr(version,'.',1,2))-1),'999d99',  'NLS_NUMERIC_CHARACTERS = ''.,''') db_v2
    --,version
from v$instance;

DOC
 ---------------------------------------------------------------------------
 (2) Check version
 ---------------------------------------------------------------------------
# 
select 'Standby 1.1' "Tjek version" from dual;

DOC
 ---------------------------------------------------------------------------
 (3) Instance Information
 ---------------------------------------------------------------------------
#

select host_name, instance_name,
       startup_time, open_mode, logins, database_role
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
union all
select '' from dual
;

set feedback 6
set heading on

DOC
 ---------------------------------------------------------------------------
 (4) Database version information
 ---------------------------------------------------------------------------
#

col value           format a90

select * from v$version;

select name, value, isdefault
from v$parameter
where name in ('optimizer_features_enable','compatible')
union all
select'spfile', decode(value, NULL, 'OBS >> PFILE << OBS', value), decode(value, NULL, '*****************', isdefault)
from v$parameter 
where name = 'spfile'
union 
select name, 
case when name = 'standby_file_management' and value = 'MANUAL' 
then '[' || value || '] Er dette korrekt ? - du vil selv definere dine datafiler på standby siden ??'|| chr(10) else value end value, isdefault
from v$parameter
where name in ('standby_file_management','db_file_name_convert')
;

col value           format a20

DOC
 ---------------------------------------------------------------------------
 (5) DB status og diverse info
 ---------------------------------------------------------------------------
# 
select host_name, instance_name,
       --decode(controlfile_type,'CURRENT','Primær DB','Standby DB') "DB type",
       startup_time, open_mode, logins, database_role, protection_level, protection_mode 
from   v$database db, v$instance i;

DOC
 ----------------------------------------------------------------------------------------------------
 (6) Sanity Check af standby status
 ----------------------------------------------------------------------------------------------------
# 	
  
SELECT CASE
          WHEN protection_level = protection_mode
               AND protection_level IN
                      ('MAXIMUM AVAILABILITY', 'MAXIMUM PROTECTION')
          THEN
             (SELECT    'Pr. '
                     || TO_CHAR (SYSDATE, 'DD-MM-YYYY HH24:MI.SS')
                     || ' er standby ['
                     || (SELECT instance_name FROM v$instance)
                     || '] synkroniseret via ' || decode((select count(*) from v$version where banner like '%Enterprise Edition%'),1,'Dataguard: ','Fattigmandsstandby: ')
                     || protection_mode
                     || CHR (10)
                     || 'Synkroniseret frem til '
                     || med_til
                FROM (SELECT TO_CHAR (MAX (checkpoint_time),
                                      'dd-mm-yyyy hh24:mi:ss')
                                med_til
                        FROM v$datafile_header))
          WHEN protection_level = protection_mode
               AND protection_level = 'MAXIMUM PERFORMANCE'
          THEN
             (SELECT    'Pr. '
                     || TO_CHAR (SYSDATE, 'DD-MM-YYYY HH24:MI.SS')
                     || ' er standby ['
                     || (SELECT instance_name FROM v$instance)
                     || '] synkroniseret via ' || decode((select count(*) from v$version where banner like '%Enterprise Edition%'),1,'Dataguard: ','Fattigmandsstandby: ')
                     || protection_mode
                     || CHR (10)
                     || 'Synkroniseret frem til '
                     || med_til
                FROM (SELECT TO_CHAR (MAX (checkpoint_time),
                                      'dd-mm-yyyy hh24:mi:ss')
                                med_til
                        FROM v$datafile_header))
          WHEN protection_level = 'RESYNCHRONIZATION'
          THEN
             (SELECT    'Pr. '
                     || TO_CHAR (SYSDATE, 'DD-MM-YYYY HH24:MI.SS')
                     || ' er standby ['
                     || (SELECT instance_name FROM v$instance)
                     || '] via DataGuard tilbage på vej mod protection level: '
                     || protection_mode
                     || CHR (10)
                     || 'Synkroniseret frem til '
                     || med_til
                FROM (SELECT TO_CHAR (MAX (checkpoint_time),
                                      'dd-mm-yyyy hh24:mi:ss')
                                med_til
                        FROM v$datafile_header))
          WHEN protection_level <> protection_mode
          THEN
             (SELECT    'Pr. '
                     || TO_CHAR (SYSDATE, 'DD-MM-YYYY HH24:MI.SS')
                     || ' er standby ['
                     || (SELECT instance_name FROM v$instance)
                     || '] i ukendt status. '
                     || 'Protection level: '
                     || protection_level
                     || ' Protection mode: '
                     || protection_mode
                     || CHR (10)
                     || 'CHECK Levels/modes/forbindelser mlm. serverne - check primær siden mm.'
                     || CHR (10)
                     || 'Synkroniseret frem til '
                     || med_til
                FROM (SELECT TO_CHAR (MAX (checkpoint_time),
                                      'dd-mm-yyyy hh24:mi:ss')
                                med_til
                        FROM v$datafile_header))
          ELSE
             'Dette burde ikke kunne forekomme - så check lige scriptet !!!'
       END
          standby_status
  FROM v$database;
  
  
DOC
 ----------------------------------------------------------------------------------------------------
 (6.1) Check af archive log apply på standby (hvis 'bagefter' er negativ, så er serverne ikke i sync mht. tid)
 ----------------------------------------------------------------------------------------------------
# 	

/*
Show info on lates archive log recieved, applied and time since last apply
*/
SELECT    'Archivelog apply er således bagud: '
       || bagefter
       || CHR (10)
       || 'Seneste logfile modtaget er '
       || (SELECT MAX (sequence#)
             FROM V$ARCHIVED_LOG
            WHERE FIRST_TIME >=
                     (SELECT MAX (RESETLOGS_TIME) FROM v$ARCHIVED_LOG))
       || CHR (10)
       || 'Seneste logfile applied  er '
       || (SELECT MAX (sequence#)
             FROM v$log_history
            WHERE FIRST_TIME >=
                     (SELECT MAX (RESETLOGS_TIME) FROM v$log_history))
       || CHR (10)
       || 'Logfile applied  er '
       || (  (SELECT MAX (sequence#)
                FROM V$ARCHIVED_LOG
               WHERE FIRST_TIME >=
                        (SELECT MAX (RESETLOGS_TIME) FROM v$ARCHIVED_LOG))
           - (SELECT MAX (sequence#)
                FROM v$log_history
               WHERE FIRST_TIME >=
                        (SELECT MAX (RESETLOGS_TIME) FROM v$log_history)))
       || '  filer bagud'
          AS archive_status
  FROM (SELECT NUMTODSINTERVAL (SYSDATE - MAX (checkpoint_time), 'DAY')
                  bagefter
          FROM v$datafile_header);

/*
Validate if the MRP0 log apply process is running
*/
SELECT CASE
          WHEN (SELECT COUNT (1)
                  FROM v$managed_standby
                 WHERE process = 'MRP0') > 0
          THEN
             (SELECT    'Archive log apply process (MRP0) is running '
                     || CHR (10)
                     || '  pid: '
                     || pid
                     || CHR (10)
                     || '  process: '
                     || process
                     || CHR (10)
                     || '  status: '
                     || status
                     || CHR (10)
                     || '  sequence# '
                     || sequence#
                FROM v$managed_standby
               WHERE process = 'MRP0')
          ELSE
             'Archive log apply process (MRP0) is NOT running !!!!!'
       END
          log_process_status
  FROM DUAL;

DOC
 ---------------------------------------------------------------------------
 (7) Memory allocated at instance startup
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
 (8) Non default parameters in pfile / spfile
 ---------------------------------------------------------------------------
#
col value format a50

select name, value from v$parameter where isdefault = 'FALSE'
order by name;

DOC
 ---------------------------------------------------------------------------
 (9) Configured memory parameters in pfile / spfile
 ---------------------------------------------------------------------------
# 

col value format 999G999G999G999

select name,to_number(value) value , isdefault
from v$parameter
where name in ('shared_pool_size','java_pool_size','large_pool_size','db_cache_size','sga_target','sga_max_size',
'pga_aggregate_target','streams_pool_size','hash_area_size','db_block_buffers','memory_target') 
--and isdefault = 'FALSE' 
order by 3, 1;	  
DOC
 ---------------------------------------------------------------------------
 (10) Offline/Missing datafiles (Der bør ikke være nogen!!)
 ---------------------------------------------------------------------------
#

select b.file#, b.name, a.status 
from v$datafile_header a, v$datafile b 
where a.status <> 'ONLINE'
and a.file# = b.file#
order by file#;

DOC
 ---------------------------------------------------------------------------
 (11) Log history Info
 ---------------------------------------------------------------------------
# 

SELECT TO_CHAR (MAX (first_time), 'dd-mm-yyyy hh24:mi:ss') "Archive log fra",
       MAX (sequence#) "Seneste Archive log fra"
  FROM v$log_history
  WHERE FIRST_TIME >= (SELECT MAX (RESETLOGS_TIME)
                            FROM v$log_history);

DOC
 ---------------------------------------------------------------------------
 (12) Datafile headers
 ---------------------------------------------------------------------------
# 

select to_char(checkpoint_time,'dd-mm-yyyy hh24:mi:ss') chkpt_time, status , 
       tablespace_name, file# 
from   v$datafile_header 
order  by file#;

DOC
 ---------------------------------------------------------------------------
 (13) Seneste 10 modtagne Archive Log filer (ikke på fattigmands)
 ---------------------------------------------------------------------------
# 

select * from (
  SELECT SEQUENCE#, FIRST_TIME, NEXT_TIME, applied
  FROM V$ARCHIVED_LOG 
  WHERE FIRST_TIME > (SELECT MAX (RESETLOGS_TIME)
                            FROM v$log_history)
  ORDER BY SEQUENCE# desc)
where rownum < 11
order by SEQUENCE#;

DOC
 ---------------------------------------------------------------------------
 (14) Seneste 10 applied Archive Log filer (ikke på fattigmands)
 ---------------------------------------------------------------------------
# 

select * from (
  SELECT SEQUENCE#, FIRST_TIME, NEXT_TIME, applied
  FROM V$ARCHIVED_LOG 
  WHERE applied = 'YES'
  AND FIRST_TIME > (SELECT MAX (RESETLOGS_TIME)
                            FROM v$log_history)
  ORDER BY SEQUENCE# desc)
where rownum < 11
order by SEQUENCE#;

DOC
 ---------------------------------------------------------------------------
 (15) Standby Processer
 ---------------------------------------------------------------------------
# 

select pid, process, status, sequence#
from v$managed_standby
order by process;

DOC
 ---------------------------------------------------------------------------
 (16) v$archive_dest  (her ses evt. delay)
 ---------------------------------------------------------------------------
# 

select dest_name, destination, delay_mins
from v$archive_dest
where status <> 'INACTIVE';

DOC
 ---------------------------------------------------------------------------
 (17) v$archive_dest_status
 ---------------------------------------------------------------------------
# 

select dest_id, dest_name, status, protection_mode, archived_seq#, applied_seq#
from v$archive_dest_status
where status <> 'INACTIVE';

DOC
 ---------------------------------------------------------------------------
 (18) v$archive_gap (bør være tom)
 ---------------------------------------------------------------------------
# 
select * from v$archive_gap;

DOC
 ---------------------------------------------------------------------------
 (19) Check alertlog for errors!
 ---------------------------------------------------------------------------
#
select value from v$parameter where name = 'background_dump_dest';


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
 (E02) OS Info
 ---------------------------------------------------------------------------
#
col stat_name format a30
col value format 99999999999999999
col comments format a50

select STAT_NAME, VALUE
from V$OSSTAT;

DOC
 ---------------------------------------------------------------------------
 (E03) File systems <> Datafiles  
 ---------------------------------------------------------------------------
#

col filesystem format a60

select substr(name,1, instr(replace(name,'\','/'),'/',-1,1)) filesystem
, round(sum(bytes)/(1024*1024*1024)) gb 
from v$datafile 
group by substr(name,1, instr(replace(name,'\','/'),'/',-1,1))
;

DOC
 ---------------------------------------------------------------------------
 (E04) Archive log destinations
 ---------------------------------------------------------------------------
#

col destination format A25
col db_unique_name format a15
col dest_name format a20

select dest_name, status, target, archiver, schedule, destination, net_timeout, process ,
valid_now, valid_type, valid_role, db_unique_name
from v$archive_dest
where status <> 'INACTIVE'
;

DOC
 ---------------------------------------------------------------------------
 (E05) REDO log grupper
 ---------------------------------------------------------------------------
#

select lg.* 
, case when antal_online >= antal_standby and protection_mode <> 'MAXIMUM PERFORMANCE'  
       then 'OBS - Der skal mindst være een STANDBY gruppe extra' else null end "COMMENT"
from 
(
select (select count(distinct group#) from v$logfile where type = 'ONLINE') antal_online
, (select count(distinct group#) from v$logfile where type = 'STANDBY') antal_standby
, protection_mode
from v$database
) lg;

DOC
 ---------------------------------------------------------------------------
 (E06) Data Guard Stats (hvis EE)
 ---------------------------------------------------------------------------
#

col name format a30
col value format a20
col unit format a50

select name, value, unit
from v$dataguard_stats
;

-----------------------------
-- RUN POST SQL SCRIPT
-----------------------------
@check_standby_postscript.sql

-----------------------------
-- RUN CUSTOM CHECK
-----------------------------
@custom_standby_check.sql

-----------------------------
-- RUN MAINTENANCE SCRIPT
-- Rotate alertlog etc.
-----------------------------

set serveroutput on
set verify off

variable o_cmd varchar2(100);
column hostcmd new_value o_cmd     noprint

declare
w_cmd varchar2(100);
begin
  
  if instr(upper('&1'),'WIN') > 0 then
     w_cmd := 'check_maintenance.cmd';
  else
     w_cmd := './CHECK_MAINTENANCE.SH';
  end if;
  
  dbms_output.put_line('Dette er en ' || '&1' || ', og kommandoen er ' || w_cmd);
  
  :o_cmd     := w_cmd;
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
