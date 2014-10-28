set lines 300
set pages 999
set echo off

alter session set nls_territory=denmark;
alter session set nls_date_format='DD-MON-RRRR HH24:MI';
alter session set nls_numeric_characters=',.';

alter session set current_schema=apps;

DOC
 ---------------------------------------------------------------------------
 (EBS-01) Hvilken version ?
 ---------------------------------------------------------------------------
#

col version format a30
col comments format a80
col "Base Version" format a15


--- hvilken vesion har vi og hvor kommer vi fra ?
select ARU_RELEASE_NAME||'.'||MINOR_VERSION||'.'||TAPE_VERSION version, START_DATE_ACTIVE updated,
ROW_SOURCE_COMMENTS COMMENTS, BASE_RELEASE_FLAG "Base Version" 
FROM AD_RELEASES 
--where END_DATE_ACTIVE IS NULL 
order by 2 desc
;

col name format a10
col host_name format a40
col version format a15
col platform_name format a40

select name, host_name, version, startup_time, platform_name 
from v$database cross join v$instance
;

col installed format a15
--col language_code format a10
col language_code heading 'Language|code'
col nls_language format a20

select decode(installed_flag,'I','Installed','B','Base','Unknown') installed,
	language_code, nls_language 
from fnd_languages
where installed_flag in ('I','B')
order by installed_flag
;

DOC
 ---------------------------------------------------------------------------
 (EBS-02) Hvilke komponenter i spil?
 ---------------------------------------------------------------------------
#

col node_name format a25
col server_address format a20
col host format a15
col domain format a30
col cp format  a5
col web format a5
col db format a5
col admin format a5
col forms format a5
col virtual_ip format a15


select substr(node_name, 1, 20) node_name, server_address, substr(host, 1, 15) host,
       substr(domain, 1, 20) domain, 
       decode(substr(support_cp, 1, 3),'N',null,substr(support_cp, 1, 3)) cp, 
       decode(substr(support_web, 1, 3),'N',null,substr(support_web, 1, 3)) webp, 
       decode(substr(support_admin, 1, 3),'N',null,substr(support_admin, 1, 3)) admin, 
       decode(substr(support_forms, 1, 3),'N',null,substr(support_forms, 1, 3)) forms, 
       decode(substr(support_db, 1, 3),'N',null,substr(support_db, 1, 3)) db, 
       substr(VIRTUAL_IP, 1, 30) virtual_ip 
from fnd_nodes
order by 1
;

DOC
 ---------------------------------------------------------------------------
 (EBS-03) Hvilke patche lagt på for nyligt?  45 dg eller seneste 10
 ---------------------------------------------------------------------------
#

col patch_name format a15
col patch_type format a10
col patch_action_options format a30
col driver_file_name format a20
col patch_top format a100
col platform format a10
col antal format 99999

with patches as
(
select patch_name, patch_type, max(ap.last_update_date) last_update_date, count(*) antal,
patch_top,
patch_action_options,
driver_file_name,
platform
from AD_APPLIED_PATCHES ap,  FND_UMS_BUGFIXES fub,        AD_PATCH_RUNS pr,        AD_PATCH_DRIVERS pd  
where ap.PATCH_NAME=to_char(fub.BUG_NUMBER(+))    
and pr.PATCH_DRIVER_ID(+)=pd.PATCH_DRIVER_ID    
and pd.APPLIED_PATCH_ID(+)=ap.APPLIED_PATCH_ID
and patch_top is not null   
group by patch_name, patch_type, patch_top, patch_action_options,driver_file_name,platform
order by LAST_UPDATE_DATE desc 
)
select * from patches
where (last_update_date > sysdate - 45 or rownum  <  11)
;

DOC
 ---------------------------------------------------------------------------
 (EBS-04) Hvilke interessante options?
 ---------------------------------------------------------------------------
#

col PROFILE_OPTION_ID format 99999
col PROFILE_OPTION_NAME format a30
col USER_PROFILE_OPTION_NAME format a40
col PROFILE_OPTION_VALUE format a30
col DESCRIPTION format a100


select t.PROFILE_OPTION_ID, t.PROFILE_OPTION_NAME, z.USER_PROFILE_OPTION_NAME,
       v.PROFILE_OPTION_VALUE, z.DESCRIPTION
from fnd_profile_options t, fnd_profile_option_values v, fnd_profile_options_tl z
where (v.PROFILE_OPTION_ID (+) = t.PROFILE_OPTION_ID)
  and (v.level_id = 10001)
  and (z.language='US')
  and (z.PROFILE_OPTION_NAME = t.PROFILE_OPTION_NAME)
  and (t.PROFILE_OPTION_NAME in ('CONC_GSM_ENABLED','CONC_PP_RESPONSE_TIMEOUT','CONC_TM_TRANSPORT_TYPE','GUEST_USER_PWD',
         'AFLOG_ENABLED','AFLOG_FILENAME','AFLOG_LEVEL','AFLOG_BUFFER_MODE','AFLOG_MODULE','FND_FWK_COMPATIBILITY_MODE',
          'FND_VALIDATION_LEVEL','FND_MIGRATED_TO_JRAD','AMPOOL_ENABLED',
          'CONC_PP_PROCESS_TIMEOUT','CONC_DEBUG','CONC_COPIES','CONC_FORCE_LOCAL_OUTPUT_MODE','CONC_HOLD','CONC_CD_ID','CONC_PMON_METHOD',
          'CONC_PP_INIT_DELAY','CONC_PRINT_WARNING','CONC_REPORT_ACCESS_LEVEL','CONC_REQUEST_LIMIT','CONC_SINGLE_THREAD',
          'CONC_TOKEN_TIMEOUT','CONC_VALIDATE_SUBMISSION','FND_CONC_ALLOW_DEBUG','CP_INSTANCE_CHECK','SQL_TRACE','PO_RVCTP_ENABLE_TRACE'))
order by z.USER_PROFILE_OPTION_NAME
;

DOC
 ---------------------------------------------------------------------------
 (EBS-05) Managers, deres processer, antal 
 ---------------------------------------------------------------------------
#

Column Manager  Heading 'Manager'  Format A60
Column Node     Heading 'Target'     Format A20
Column ApId     Heading 'Appl ID'  Format 9999990
Column Q_Id     Heading 'Q ID'     Format 9999990
Column Running  Heading 'Running'  Format A10
Column Max      Heading 'Max'      Format A10
Column Min      Heading 'Min'      Format A10
Column TargetP  Heading 'Target'   Format A10
Column Buf      Heading 'Buffers'  Format 9999999
column Diag_level Heading 'Diag level' format a10
column developer_parameters format a60

select Application_Id ApId, concurrent_queue_id Q_Id,
       User_Concurrent_Queue_Name Manager,  Target_Node Node,
       decode(Running_Processes,0,null, Running_Processes) Running, 
       decode(target_processes,0,null,target_processes) TargetP, 
       decode(min_processes,0,null,min_processes) Min,
       decode(Max_Processes,0,null,Max_Processes) Max, 
       Cache_Size Buf, Diagnostic_Level Diag_level,
       developer_parameters
from fnd_concurrent_queues_vl q left outer join FND_CP_SERVICES s on q.manager_type = s.service_id
order by User_Concurrent_Queue_Name 
;
     

DOC
 ---------------------------------------------------------------------------
 (EBS-06) Hvilke Managers findes ?
 ---------------------------------------------------------------------------
#

Column OsId       Format A13
Column CpId       Format 9999999990
Column Opid       Format 99999999
Column Manager    Format A50
Column Node       Format A20
Column Started_At Format A19
Column Program    Format A70

Column Q_Id       Format 99999990
Column Q_Id       Heading 'Q ID'

Column Cpid       Heading 'Cpid'
Column Node       Heading 'Node'
Column OsId       Heading 'System|Pid'
Column Opid 	  Heading 'Oracle|Pid'
Column Manager    Heading  Manager
Column Started_At Heading 'Started at'
Column Opid       Justify  Left
Column Program    Heading 'Program / Module'

Select distinct Concurrent_Process_Id CpId,
       GVP.PID Opid,
       Os_Process_ID Osid,
       Q.User_Concurrent_Queue_Name Manager,
       P.Node_Name Node,
       P.Process_Start_Date Started_At,gvs.program || ' / ' || gvs.module program
  from  Fnd_Concurrent_Processes P, Fnd_Concurrent_Queues_Vl Q,
        GV$Process GVP, GV$Session GVS
 where  Q.Application_Id = Queue_Application_ID
   And (Q.Concurrent_Queue_ID = P.Concurrent_Queue_ID)
   And (GVS.Process = Os_Process_ID )
   And (GVP.ADDR = GVS.PADDR )
   And  Process_Status_Code not in ('K','S')
  Order by Q.User_Concurrent_Queue_Name, Os_Process_Id,
           Concurrent_Process_ID
;

DOC
 ---------------------------------------------------------------------------
 (EBS-07) Hvilke Managers findes  - uden Oracle process
 ---------------------------------------------------------------------------
#

Column OsId       Format A13
Column CpId       Format 9999999990
Column Opid       Format 99999999
Column Manager    Format A50
Column Node       Format A20
Column Started_At Format A19

Column Q_Id       Format 99999990
Column Q_Id       Heading 'Q ID'

Column Cpid       Heading 'Cpid'
Column Node       Heading 'Node'
Column OsId       Heading 'System|Pid'
Column Opid 	  Heading 'Oracle|Pid'
Column Manager    Heading  Manager
Column Started_At Heading 'Started at'
Column Opid       Justify  Left

COlumn Process_status_code format a6 
Column Process_status_Code Heading 'Status'

Select distinct Concurrent_Process_Id CpId,
       Oracle_Process_ID Opid,
       Os_Process_ID Osid,
       User_Concurrent_Queue_Name Manager,
       P.Node_Name Node,
       P.Process_Start_Date Started_At, Process_Status_Code
  from  Fnd_Concurrent_Processes P, Fnd_Concurrent_Queues_Vl Q
 where  Q.Application_Id = Queue_Application_ID
   And  Q.Concurrent_Queue_ID = P.Concurrent_Queue_ID
   And  P.Concurrent_Queue_ID <> 1
   And  (Os_Process_ID ) Not in
           ( Select GVS.Process
               from GV$SESSION GVS
              Where GVS.Process Is Not Null )
  And  ( Process_Status_Code = 'A' OR
         Process_Status_Code = 'R' OR
         Process_Status_Code = 'T' )
  Order by Q.User_Concurrent_Queue_Name, Os_Process_Id,
           Concurrent_Process_ID
;

DOC
 ---------------------------------------------------------------------------
 (EBS-08) Output Post Processer status (seneste 30 dage)
 ---------------------------------------------------------------------------
#
Column OsId       Format A10
Column Opid       Format 9999999
Column CpId       Format 9999999990
column Ospid      Format A10
column process_start_date Heading 'Started at'
column service_parameters format a60
column gsm_internal_info format a30
column log_trace_file format a120
column node_name format a12
column process_status_code format a10
column process_status_code heading 'Status'

Column OsId       Heading 'System|Pid'
Column Opid 	  Heading 'Oracle|Pid'
Column Ospid 	  Heading 'Oracle|SPid'
Column Cpid       Heading 'Cpid'
column log_trace_file heading 'Logfile on App.server|Trace file on DB server'


SELECT 
  proc.concurrent_process_id cpid, proc.process_start_date, 
  decode(proc.process_status_code,'A','Active','K','Killed','S','Terminated','Unknown=' ||  proc.process_status_code) process_status_code,
  proc.os_process_id osid , proc.service_parameters, 
  ---decode (proc.process_status_code,'A',gsm_internal_info,null) gsm_internal_info,
  vproc.pid opid, vproc.spid ospid, proc.logfile_name || chr(10) || tracefile log_trace_file
  FROM fnd_concurrent_processes proc join fnd_concurrent_queues concq on  proc.queue_application_id = concq.application_id    
                         AND proc.concurrent_queue_id = concq.concurrent_queue_id 
                         and concq.concurrent_queue_name = 'FNDCPOPP'
       left outer join v$process vproc on proc.oracle_process_id = vproc.pid
       left outer join v$session vsess on vproc.addr = vsess.paddr 
where 
concq.concurrent_queue_name = 'FNDCPOPP' and
proc.creation_date > sysdate - 30 or proc.process_status_code = 'A'
order by proc.creation_date desc
;

DOC
 ---------------------------------------------------------------------------
 (EBS-09) Hvilke requests kører lige nu?
 ---------------------------------------------------------------------------
#

col req_name format a45
col user_name format a15
col cp_process format a30
col db_sid format a20
col db_process format a30
col event format a30
col sq heading "Wait|Secs"

select r.request_id req_id,
     ---  r.parent_request_id preq_id,
       ps.concurrent_program_name prog_name,
       p.user_concurrent_program_name || case
         when concurrent_program_name = 'FNDRSSUB' then
          (select ': ' || rs.user_request_set_name
             from fnd_request_sets_tl rs
            where rs.application_id = to_number(argument1)
              and rs.request_set_id = to_number(argument2)
              and rs.language = 'US')
       end || case
         when concurrent_program_name = 'FNDRSSTG' then
          (select ': ' || rss.user_stage_name
             from fnd_request_set_stages_tl rss
            where rss.set_application_id = to_number(argument1)
              and rss.request_set_id = to_number(argument2)
              and rss.request_set_stage_id = to_number(argument3)
              and rss.language = 'US')
       end req_name,
       r.phase_code p,
       r.status_code s,
       u.user_name,
       r.priority PRIO,
       (select node_name || ':' from fnd_concurrent_processes cp
         where concurrent_process_id = r.controlling_manager) ||
       r.os_process_id cp_process,
       nvl2(gi.INSTANCE_NAME, gi.instance_name || ':' || ss.sid || ',' ||pp.spid, null) db_process,
       decode(ss.status, 'ACTIVE', 'ACT', 'INACTIVE', 'INACT', ss.status) STAT,
       w.event,
       w.seconds_in_wait sw,
       r.actual_start_date
  from fnd_user                   u,
       fnd_concurrent_requests    r,
       fnd_concurrent_programs_tl p,
       fnd_concurrent_programs    ps,
       gv$session                 ss,
       gv$process                 pp,
       gv$session_wait            w,
       gv$instance                gi
 where 1 = 1
   and r.requested_by = u.user_id
   and (r.phase_code = 'R' or r.status_code = 'I')
   And r.Requested_Start_Date <= Sysdate
   and p.concurrent_program_id = r.concurrent_program_id
   and ps.concurrent_program_id = r.concurrent_program_id
   and p.language = 'US'
   and ss.audsid(+) = r.oracle_session_id
   and r.hold_flag = 'N'
   and pp.inst_id(+) = ss.inst_id
   and pp.addr(+) = ss.paddr
   and w.INST_ID(+) = ss.inst_id
   and w.sid(+) = ss.sid
   and gi.inst_id(+) = ss.inst_id
 order by decode(r.phase_code, 'R', 0, 1),
          NVL(R.priority, 999999999),
          R.Priority_Request_ID,
          R.Request_ID
;

DOC
 ---------------------------------------------------------------------------
 (EBS-10) Hvilke jobs har kørt hvor mange gange de seneste 5 uger
 ---------------------------------------------------------------------------
#

col CONC_PROG format a35
col user_conc_prog format a60
col output_print_style format a20
col output_file_type format a6
col output_file_type heading "Format"
col forrige_md format 99999999
col sidste_md format 99999999
col denne_md format 99999999
col ialt format 999999
col fejlet format 999999
col warning format 999999
col min format a12
col max format a12

break on report
compute sum of denne_uge on report
compute sum of uge1 on report
compute sum of uge2 on report
compute sum of uge3 on report
compute sum of uge4 on report
compute sum of uge5 on report
compute sum of ialt on report
compute sum of fejlet on report
compute sum of warning on report

with datoer as
(select trunc(sysdate,'IW') denne, trunc(sysdate-7,'IW') uge_1 ,trunc(sysdate-14,'IW') uge_2 ,trunc(sysdate-21,'IW') uge_3 
,trunc(sysdate-28,'IW') uge_4 ,trunc(sysdate-35,'IW') uge_5 ,trunc(sysdate-42,'IW') uge_6 from dual
)
---
SELECT 
   fcp.concurrent_program_name conc_prog,
   fcpt.user_concurrent_program_name user_conc_prog,
   fcp.output_print_style,
   fcp.output_file_type,
   sum(case when trunc(fcr.actual_start_date,'IW') = datoer.denne then 1 else null end) denne_uge ,
   sum(case when trunc(fcr.actual_start_date,'IW') = datoer.uge_1 then 1 else null end) uge1 ,
   sum(case when trunc(fcr.actual_start_date,'IW') = datoer.uge_2 then 1 else null end) uge2 ,
   sum(case when trunc(fcr.actual_start_date,'IW') = datoer.uge_3 then 1 else null end) uge3 ,
   sum(case when trunc(fcr.actual_start_date,'IW') = datoer.uge_4 then 1 else null end) uge4 ,
   sum(case when trunc(fcr.actual_start_date,'IW') = datoer.uge_5 then 1 else null end) uge5 ,
   count(fcr.actual_start_date) ialt,
   sum(case when fcr.STATUS_CODE in('E') then 1 else null end) fejlet,
   sum(case when fcr.STATUS_CODE in('G') then 1 else null end) warning,
   lpad(ltrim(ltrim(substr(numtodsinterval (min(fcr.actual_completion_date - fcr.actual_start_date),'Day'),10,10),'0 '),':'),12,' ') min,
   lpad(ltrim(ltrim(substr(numtodsinterval (max(fcr.actual_completion_date - fcr.actual_start_date),'Day'),10,10),'0 '),':'),12,' ') max
FROM
  fnd_concurrent_programs fcp,
  fnd_concurrent_programs_tl fcpt,
  fnd_concurrent_requests fcr,
  datoer 
WHERE  fcr.concurrent_program_id = fcp.concurrent_program_id
and    fcr.program_application_id = fcp.application_id
and    fcr.concurrent_program_id = fcpt.concurrent_program_id
and    fcr.program_application_id = fcpt.application_id
and    fcpt.language = USERENV('Lang')
group by 
   fcp.concurrent_program_name ,
   fcpt.user_concurrent_program_name ,
   fcp.output_print_style,
   fcp.output_file_type
order by 
   fcp.concurrent_program_name
;   

DOC
 ---------------------------------------------------------------------------
 (EBS-11) Fordeling af requests på status
 ---------------------------------------------------------------------------
#

col "Denne uge"  format 99999;
col "Uge-1"  format 99999;
col "Uge-2"  format 99999;
col "Uge-3"  format 99999;
col "Uge-4"  format 99999;
col "Uge-5"  format 99999;
col "Uge-6"  format 99999;
col "Uge-7"  format 99999;
col "Uge-8"  format 99999;
col "Uge-9"  format 99999;
col "Uge-10" format 99999;
col "Uge-11" format 99999;
col "Uge-12" format 99999;
col "Uge-13" format 99999;
col "Ældre" format 999999;
col idag format 999;   
col "Request status" format a20
col "Antal" format 9999999
col "i %" format 999.99

with status_codes as (
select distinct lookup_code, meaning from  fnd_lookup_values 
where lookup_type = 'CP_STATUS_CODE'
and language = 'US'
and view_application_id = 0
),
datoer as
(select trunc(sysdate,'IW') denne, trunc(sysdate-7,'IW') uge_1 ,trunc(sysdate-14,'IW') uge_2 ,trunc(sysdate-21,'IW') uge_3 
,trunc(sysdate-28,'IW') uge_4 ,trunc(sysdate-35,'IW') uge_5 ,trunc(sysdate-42,'IW') uge_6  
,trunc(sysdate-49,'IW') uge_7 ,trunc(sysdate-56,'IW') uge_8 ,trunc(sysdate-63,'IW') uge_9  
,trunc(sysdate-70,'IW') uge_10 ,trunc(sysdate-77,'IW') uge_11 ,trunc(sysdate-85,'IW') uge_12 
,trunc(sysdate-92,'IW') uge_13 ,trunc(sysdate-99,'IW') uge_14 from dual
),
requests as
(
SELECT trim(meaning || ' (' || lookup_code ||')') status, count(request_id) antal,
   sum(case when trunc(fcr.actual_start_date,'IW') = datoer.denne then 1 else null end) denne_uge ,
   sum(case when trunc(fcr.actual_start_date,'IW') = datoer.uge_1 then 1 else null end) uge1 ,
   sum(case when trunc(fcr.actual_start_date,'IW') = datoer.uge_2 then 1 else null end) uge2 ,
   sum(case when trunc(fcr.actual_start_date,'IW') = datoer.uge_3 then 1 else null end) uge3 ,
   sum(case when trunc(fcr.actual_start_date,'IW') = datoer.uge_4 then 1 else null end) uge4 ,
   sum(case when trunc(fcr.actual_start_date,'IW') = datoer.uge_5 then 1 else null end) uge5 ,
   sum(case when trunc(fcr.actual_start_date,'IW') = datoer.uge_6 then 1 else null end) uge6 ,
   sum(case when trunc(fcr.actual_start_date,'IW') = datoer.uge_7 then 1 else null end) uge7 ,
   sum(case when trunc(fcr.actual_start_date,'IW') = datoer.uge_8 then 1 else null end) uge8 ,
   sum(case when trunc(fcr.actual_start_date,'IW') = datoer.uge_9 then 1 else null end) uge9 ,
   sum(case when trunc(fcr.actual_start_date,'IW') = datoer.uge_10 then 1 else null end) uge10 ,
   sum(case when trunc(fcr.actual_start_date,'IW') = datoer.uge_11 then 1 else null end) uge11 ,
   sum(case when trunc(fcr.actual_start_date,'IW') = datoer.uge_12 then 1 else null end) uge12 ,
   sum(case when trunc(fcr.actual_start_date,'IW') = datoer.uge_13 then 1 else null end) uge13 ,
   sum(case when trunc(fcr.actual_start_date,'IW') < datoer.uge_14 then 1 else null end) uge14 ,
   count(fcr.actual_start_date) ialt
FROM fnd_concurrent_requests fcr 
    cross join datoer
    join status_codes on lookup_code = status_code
group by lookup_code, meaning
)
select status "Request status", antal "Antal",
trunc(RATIO_TO_REPORT(antal) OVER () *100,2) "i %"
, denne_uge "Denne uge", uge1 "Uge-1", uge2 "Uge-2", uge3 "Uge-3", uge4 "Uge-4", uge5 "Uge-5", uge6 "Uge-6"
, uge7 "Uge-7", uge8 "Uge-8", uge9 "Uge-9", uge10 "Uge-10", uge11 "Uge-11"
, uge12 "Uge-12", uge13 "Uge-13", uge14 "Ældre", ialt "Antal kørt"
from requests
order by 2 desc, 1
;

DOC
 ---------------------------------------------------------------------------
 (EBS-12) TOP 50 køretid på requests
-------------------------------------------------------------------------
#

col request_id format 999999999
col phase format a20
col status format a20
col program format a40

with status_codes as (
select distinct lookup_code, meaning from  fnd_lookup_values 
where lookup_type = 'CP_STATUS_CODE'
and language = 'US'
and view_application_id = 0
),
phase_codes as (
select distinct lookup_code, meaning from  fnd_lookup_values 
where lookup_type = 'CP_PHASE_CODE'
and language = 'US'
and view_application_id = 0
),
conc_programs as
(
SELECT f.request_id,
        DECODE(p.concurrent_program_name,
               'ALECDC',
               p.concurrent_program_name || ' ' || f.description || ' ',
               p.concurrent_program_name) program,
        pt.user_concurrent_program_name user_conc_prog,
        f.actual_start_date actual_start_date,
        f.actual_completion_date actual_completion_date,
        case when to_number( to_char(to_date('1','J') + ( f.actual_completion_date - f.actual_start_date), 'J') - 1) = 0 then null
        else  to_number( to_char(to_date('1','J') + ( f.actual_completion_date - f.actual_start_date), 'J') - 1) end days,
        to_char(to_date('00:00:00','HH24:MI:SS') + ( f.actual_completion_date - f.actual_start_date), 'HH24:MI:SS') time,
        trim(p.meaning || ' (' || p.lookup_code ||')') phase,
        trim(s.meaning || ' (' || s.lookup_code ||')') status
   FROM apps.fnd_concurrent_programs    p,
        apps.fnd_concurrent_programs_tl pt,
        apps.fnd_concurrent_requests    f,
        status_codes s,
        phase_codes p
  WHERE f.concurrent_program_id = p.concurrent_program_id
    AND f.program_application_id = p.application_id
    AND f.concurrent_program_id = pt.concurrent_program_id
    AND f.program_application_id = pt.application_id
    AND pt.language = USERENV('Lang')
    AND s.lookup_code =  f.status_code
    AND p.lookup_code = f.phase_code
    AND f.actual_start_date is not null
    AND f.actual_completion_date is not null
    AND p.concurrent_program_name not in ('FNDGSCST','FNDRSSUB')
  ORDER by f.actual_completion_date - f.actual_start_date desc
)
select *
from conc_programs
where rownum < 51
;
DOC
 ---------------------------------------------------------------------------
 (EBS-13) Hvilke programmer kører med trace flag ?
 ---------------------------------------------------------------------------
#

col CONC_PROG format a35
col language format A12
col program_name format a130
col email_address format a30


with programs as
(
select 
a.concurrent_program_name conc_prog,  
c.language,c.user_concurrent_program_name program_name,
 a.last_update_date,
 u.user_name, email_address,
 ROW_NUMBER() OVER (PARTITION BY concurrent_program_name ORDER BY language) AS curr,
 ROW_NUMBER() OVER (PARTITION BY concurrent_program_name ORDER BY language) -1 AS prev
from applsys.fnd_concurrent_programs a,
     applsys.fnd_concurrent_programs_tl c,
     fnd_user u
where  
a.concurrent_program_id = c.concurrent_program_id and
a.last_updated_by = u.user_id
and a.enable_trace = 'Y'
)
select conc_prog,
ltrim(max(SYS_CONNECT_BY_PATH(language,','))  ,',') AS Language, 
translate(ltrim(max(SYS_CONNECT_BY_PATH(program_name,'¤'))  ,'¤'),'¤',chr(10)) program_name,
last_update_date,
user_name, 
email_address
from programs
group by conc_prog, last_update_date, user_name, email_address
connect by prev = prior curr and conc_prog = prior conc_prog
start with curr = 1
;

DOC
 ---------------------------------------------------------------------------
 (EBS-14) AQ køerne og hvad der ligger i dem ?
 ---------------------------------------------------------------------------
#

col name format a30
col queue_table format a30
col consumer_name format a30
col retention format a10
col ready format a10
col waiting format a10
col expired format a10
col persist format a8
col recipients format a10
col object_type format a35

SELECT   
           a.name,
           a.queue_table,
           decode(a.retention,'0',null,a.retention) retention, 
           decode(q.waiting,0,null,q.waiting) waiting,
           decode(q.ready,0,null,q.ready) ready,
           decode(q.expired,0,null,q.expired) expired,
           decode(s.delivery_mode,'PERSISTENT','YES',NULL) persist,
           s.consumer_name,
           t.recipients,
           t.object_type
FROM       all_queues a left outer join V$AQ q on  q.qid = a.qid   
           join all_queue_tables t on a.queue_table = t.queue_table AND a.owner = t.owner
           left outer join  all_queue_subscribers s on a.owner = s.owner and a.owner = s.owner AND a.queue_table = s.queue_table
where      (a.queue_type = 'NORMAL_QUEUE' or (a.queue_type <> 'ERROR_QUEUE' and nvl(waiting,0)+nvl(ready,0)+nvl(expired,0) > 0))
           and a.owner = 'APPLSYS' 
           --and a.queue_table like 'WF_DEF%'  
ORDER BY   a.owner, a.queue_table, a.name
;

DOC
 ---------------------------------------------------------------------------
 (EBS-15) Deferred køerne - hvad ligger af forsk. workflow typer
 ---------------------------------------------------------------------------
#

select 
w.user_data.itemtype wf_type,
count(*) antal, 
decode(w.state, 0, '0 = Ready', 
1, '1 = Delayed', 
2, '2 = Retained/Processed', 
3, '3 = Exception') status
from apps.wf_deferred_table_m w 
group by state, w.user_data.itemtype
order by 1,2,3
;

DOC
 ---------------------------------------------------------------------------
 (EBS-16) Workflow baggrundsjobs - seneste 20
 ---------------------------------------------------------------------------
#

col phase_code format a10
col status_code format a10
col logfile format a100

with status_codes as (
select distinct lookup_code, meaning from  fnd_lookup_values 
where lookup_type = 'CP_STATUS_CODE'
and language = 'US'
and view_application_id = 0
),
phase_codes as (
select distinct lookup_code, meaning from  fnd_lookup_values 
where lookup_type = 'CP_PHASE_CODE'
and language = 'US'
and view_application_id = 0
),
workflow_jobs as (
select request_id, requested_start_date,
ph.meaning phase_code ,
st.meaning status_code,
priority,
actual_start_date,
actual_completion_date,
logfile_name logfile
FROM fnd_concurrent_requests r
 join FND_CONCURRENT_PROGRAMS_TL p on r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID
      and p.USER_CONCURRENT_PROGRAM_NAME LIKE 'Workflow%Background%' 
 join status_codes st on st.lookup_code = status_code
 join phase_codes ph on ph.lookup_code = phase_code
where p.LANGUAGE = 'US'
order by requested_start_date desc
)
select * from workflow_jobs
where rownum < 21
;

DOC
 ---------------------------------------------------------------------------
 (EBS-17) AQ tasks og Queue monitor (kun for 11.2 og fremefter)
 ---------------------------------------------------------------------------
#
 
col qmnc_pid format a10
col status format a15
col server_pid format a10
col server_name format a20
col task_name format a20
col server_start_time format a30
col last_server_start_time format a30
col task_start_time format a30
col last_failure_time format a30
col next_wakeup_time format a30
col last_failure_time format a30
col task_start_time format a30
col task_submit_time format a30
col task_expiry_time format a30

select 
qmnc_pid, status, num_servers, max_servers, last_server_start_time, last_server_pid, next_wakeup_time,
last_failure, last_failure_time
from sys.GV$QMON_COORDINATOR_STATS;

select 
qmnc_pid, server_pid, server_name,status, server_start_time, task_name, task_number,
task_start_time, last_failure, last_failure_time
from sys.GV$QMON_SERVER_STATS 
order by server_name
;

select
task_name, task_number, task_type, task_status status, server_name, num_failures, 
task_submit_time, task_expiry_time, task_start_time 
from sys.GV$QMON_TASKS;