set verify off
set echo off

col current_alert_name    new_value cur_alert_log
col archived_alert_name   new_value arch_alert_log
col archived_alert_fname  new_value arch_alert_fname

col o_cmd    new_value cmd
col o_cmd2   new_value cmd2
col o_delim  new_value delim

select decode('&1','WIN','\','/')        o_delim  from dual;
select decode('&1','WIN','move','mv')    o_cmd    from dual;
select decode('&1','WIN','echo set','echo export') o_cmd2   from dual;

select
value||'&delim.alert_'||instance_name||'.log ' as current_alert_name,
value|| '&delim' ||to_char(sysdate,'yyyymmdd-hh24mi')||'_'|| host_name ||'_alert_'||instance_name||'_'||'.log' archived_alert_name,
to_char(sysdate,'yyyymmdd-hh24mi')||'_'||host_name||'_alert_'||instance_name||'_'||'.log' archived_alert_fname
from v$instance, v$parameter
where v$parameter.name = 'background_dump_dest';

host &cmd &cur_alert_log &arch_alert_log

host &cmd2 ALERT_LOG=&arch_alert_log> xx_sets.cmd
host &cmd2 ALERT_FNAME=&arch_alert_fname>> xx_sets.cmd

--execute sys.dbms_system.ksdwrt(2,' Alertlog continued from file '||'''&arch_alert_log''');
exit
