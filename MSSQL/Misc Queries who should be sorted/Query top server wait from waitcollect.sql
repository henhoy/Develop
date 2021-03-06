/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 1000 [SSN]
      ,[wait_type]
      ,[waiting_tasks_count]
      ,[wait_time_ms]
      ,[max_wait_time_ms]
      ,[signal_wait_time_ms]
  FROM [WaitCollect].[dbo].[Trend_dm_os_wait_stats]
  where wait_type like 'PAGE%'
  and ssn in (1,2)
  and waiting_tasks_count > 0
  order by wait_type