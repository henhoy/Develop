-- select * from sys.sysprocesses
SELECT  s.spid, BlockingSPID = s.blocked, DatabaseName = DB_NAME(s.dbid), s.program_name, s.loginame, ObjectName = OBJECT_NAME(objectid, s.dbid), Definition = CAST(text AS VARCHAR(MAX))
FROM      sys.sysprocesses s
CROSS APPLY sys.dm_exec_sql_text (sql_handle)
WHERE  s.spid > 50

select der.session_id spid, der.blocking_session_id as BlockingSPID, db_name(der.database_id) DatabaseName, des.program_name program_name, des.login_name as loginname,
       object_name(objectid, der.database_id)object_name, CAST(text AS VARCHAR(MAX)), der.start_time as start_time, der.wait_type, der.wait_time/1000/60 minutes_in_wait
from sys.dm_exec_requests as der
left outer join sys.dm_exec_sessions as des
on der.session_id = des.session_id
cross apply sys.dm_exec_sql_text (der.sql_handle)
where der.status <> 'background'

--select * from sys.dm_exec_requests
--select * from sys.dm_exec_sessions 
--select * from sys.sysprocesses

--select *
--from sys.dm_exec_requests as der
--join sys.dm_exec_sessions as des
--on der.session_id = des.session_id

--select * from sys.dm_db_task_space_usage