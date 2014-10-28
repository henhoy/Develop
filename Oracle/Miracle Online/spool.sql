col sp_name new_value spool_name

select decode('&1','WIN',
(select '&2'|| '\' || to_char(sysdate,'yyyymmdd-hh24mi')||'_'||host_name||'_'||instance_name||'.txt'  
 from v$instance),
(select '&2'||'/'||to_char(sysdate,'yyyymmdd-hh24mi')||'_'||host_name||'_'||instance_name||'.txt' 
 from v$instance)
) as sp_name
from dual;

spool &spool_name