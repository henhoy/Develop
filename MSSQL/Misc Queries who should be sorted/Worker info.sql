select * from sys.dm_os_schedulers

select * from sys.dm_os_tasks

select * from sys.dm_os_threads

select * from sys.dm_os_workers

select * from sys.dm_exec_requests

SELECT 
    t1.session_id,
    CONVERT(varchar(10), t1.status) AS status,
    CONVERT(varchar(15), t1.command) AS command,
    CONVERT(varchar(10), t2.state) AS worker_state,
    w_suspended = 
      CASE t2.wait_started_ms_ticks
        WHEN 0 THEN 0
        ELSE 
          t3.ms_ticks - t2.wait_started_ms_ticks
      END,
    w_runnable = 
      CASE t2.wait_resumed_ms_ticks
        WHEN 0 THEN 0
        ELSE 
          t3.ms_ticks - t2.wait_resumed_ms_ticks
      END
  FROM sys.dm_exec_requests AS t1
  INNER JOIN sys.dm_os_workers AS t2
    ON t2.task_address = t1.task_address
  CROSS JOIN sys.dm_os_sys_info AS t3
  WHERE t1.scheduler_id IS NOT NULL
--  and command = 'DB MIRROR';

--select * from sys.databases where state = 1;
SELECT max_workers_count, 
(SELECT COUNT(*) FROM sys.dm_os_threads) UsedThreads, 
max_workers_count - (SELECT COUNT(*) FROM sys.dm_os_threads) AvailableThreads,
CAST((SELECT COUNT(*) from sys.dm_os_threads) AS DECIMAL(12,2))/CAST(max_workers_count AS DECIMAL(12,2)) PercentUsed
FROM sys.dm_os_sys_info