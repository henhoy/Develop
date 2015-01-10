SELECT  x.session_id,
        x.host_name,
        x.login_name,
        x.start_time,
        x.totalReads,
        x.totalWrites,
        x.totalCPU,
        x.writes_in_tempdb,
    (
            -- Query gets XML text for the sql query for the session_id
            SELECT      text AS [text()]
            FROM  sys.dm_exec_sql_text(x.sql_handle)
            FOR XML PATH(''), TYPE

    )AS sql_text,
     COALESCE(x.blocking_session_id, 0) AS blocking_session_id,
    (
        SELECT p.text
        FROM
        (
            -- Query gets the corresponding sql_handle info to find the XML text in the next query
            SELECT MIN(sql_handle) AS sql_handle
            FROM sys.dm_exec_requests r2
            WHERE r2.session_id = x.blocking_session_id
        ) AS r_blocking
        CROSS APPLY
        (
            -- Query will pull back the XML text for a blocking session if there is any from the sql_haldle
            SELECT text AS [text()]
            FROM sys.dm_exec_sql_text(r_blocking.sql_handle)
            FOR XML PATH(''), TYPE
        ) p (text)
    ) AS blocking_text
FROM
(
-- Query returns active session_id and metadata about the session for resource, blocking, and sql_handle
    SELECT  r.session_id,
            s.host_name,
            s.login_name,
            r.start_time,
            r.sql_handle,
            r.blocking_session_id,
            SUM(r.reads) AS totalReads,
            SUM(r.writes) AS totalWrites,
            SUM(r.cpu_time) AS totalCPU,
            SUM(tsu.user_objects_alloc_page_count + tsu.internal_objects_alloc_page_count) AS writes_in_tempdb
    FROM    sys.dm_exec_requests r
    JOIN    sys.dm_exec_sessions s ON s.session_id = r.session_id
    JOIN    sys.dm_db_task_space_usage tsu ON s.session_id = tsu.session_id and r.request_id = tsu.request_id
    WHERE   r.status IN ('running', 'runnable', 'suspended')
      and r.blocking_session_id <> 0
    GROUP BY    r.session_id,
                s.host_name,
                s.login_name,
                r.start_time,
                r.sql_handle,
                r.blocking_session_id
) x


SELECT  r.session_id,
            s.host_name,
            s.login_name,
            r.start_time,
            r.sql_handle,
            r.blocking_session_id,
            SUM(r.reads) AS totalReads,
            SUM(r.writes) AS totalWrites,
            SUM(r.cpu_time) AS totalCPU,
            SUM(tsu.user_objects_alloc_page_count + tsu.internal_objects_alloc_page_count) AS writes_in_tempdb
    FROM    sys.dm_exec_requests r
    JOIN    sys.dm_exec_sessions s ON s.session_id = r.session_id
    JOIN    sys.dm_db_task_space_usage tsu ON s.session_id = tsu.session_id and r.request_id = tsu.request_id
    WHERE   r.status IN ('running', 'runnable', 'suspended')
      and r.blocking_session_id <> 0
    GROUP BY    r.session_id,
                s.host_name,
                s.login_name,
                r.start_time,
                r.sql_handle,
                r.blocking_session_id