IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='test1')
    DROP EVENT SESSION [test1] ON SERVER;
CREATE EVENT SESSION [test1]
ON SERVER
ADD EVENT sqlserver.sql_statement_starting(
     ACTION (package0.collect_cpu_cycle_time, package0.collect_system_time, sqlserver.plan_handle, sqlserver.session_id, sqlserver.sql_text)
     WHERE (([sqlserver].[session_id]>=(50)))),
ADD EVENT sqlos.wait_info(
     ACTION (package0.collect_cpu_cycle_time, package0.collect_system_time, sqlserver.session_id)
     WHERE [sqlserver].[session_id]>=(50) AND (((opcode = 1 --End Events Only
             AND ((wait_type > 0 AND wait_type < 22) -- LCK_ waits
                    OR (wait_type > 31 AND wait_type < 38) -- LATCH_ waits
                    OR (wait_type > 47 AND wait_type < 54) -- PAGELATCH_ waits
                    OR (wait_type > 63 AND wait_type < 70) -- PAGEIOLATCH_ waits
                    OR (wait_type > 96 AND wait_type < 100) -- IO (Disk/Network) waits
                    OR (wait_type = 107) -- RESOURCE_SEMAPHORE waits
                    OR (wait_type = 113) -- SOS_WORKER waits
                    OR (wait_type = 120) -- SOS_SCHEDULER_YIELD waits
                    OR (wait_type = 178) -- WRITELOG waits
                    OR (wait_type > 174 AND wait_type < 177) -- FCB_REPLICA_ waits
                    OR (wait_type = 186) -- CMEMTHREAD waits
                    OR (wait_type = 187) -- CXPACKET waits
                    OR (wait_type = 207) -- TRACEWRITE waits
                    OR (wait_type = 269) -- RESOURCE_SEMAPHORE_MUTEX waits
                    OR (wait_type = 283) -- RESOURCE_SEMAPHORE_QUERY_COMPILE waits
                    OR (wait_type = 284) -- RESOURCE_SEMAPHORE_SMALL_QUERY waits
     ))))),
ADD EVENT sqlserver.sql_statement_completed(
     ACTION (package0.collect_cpu_cycle_time, package0.collect_system_time, sqlserver.plan_handle, sqlserver.session_id, sqlserver.sql_text)
     WHERE (([sqlserver].[session_id]>=(50)))),
ADD EVENT sqlserver.rpc_starting(
     ACTION (package0.collect_cpu_cycle_time, package0.collect_system_time, sqlserver.plan_handle, sqlserver.session_id, sqlserver.sql_text)
     WHERE (([sqlserver].[session_id]>=(50))))
ADD TARGET package0.asynchronous_file_target(
     SET filename='c:\temp\wait.etx', metadatafile='c:\temp\wait.mta', max_file_size=50, max_rollover_files=10)
WITH (MAX_MEMORY = 4096KB, EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS, MAX_DISPATCH_LATENCY = 2 SECONDS, MAX_EVENT_SIZE = 0KB, MEMORY_PARTITION_MODE = NONE, TRACK_CAUSALITY = OFF, STARTUP_STATE = OFF)


