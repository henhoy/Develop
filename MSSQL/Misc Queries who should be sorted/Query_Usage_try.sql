drop table #beginprocess
drop table #endprocess

select   [Spid] = spid, 
         [Thread ID] = kpid, 
         [Status] = convert(varchar(10), status), 
         [LoginName] = convert(varchar(20), loginame), 
         [IO] = physical_io, 
         [CPU] = cpu, 
         [MemUsage] = memusage,
         [HostName]= convert(varchar(20), hostname),
         [program_name],
         [sql_handle]
into #beginProcess
from     [master].[dbo].[sysprocesses] 
where spid > 50
order by CPU desc

waitfor DELAY '000:01:00'   -- et minut

select   [Spid] = spid, 
         [Thread ID] = kpid, 
         [Status] = convert(varchar(10), status), 
         [LoginName] = convert(varchar(20), loginame), 
         [IO] = physical_io, 
         [CPU] = cpu, 
         [MemUsage] = memusage,
         [HostName]= convert(varchar(20), hostname),
         [program_name],
         [sql_handle]
into #endProcess
from     [master].[dbo].[sysprocesses] 
where spid > 50
order by CPU desc

-- Query til at vise cpu forbrugerne

select top 10 e.cpu-b.cpu as cpuForbrug,e.spid,e.status,e.loginName,e.hostname,e.program_name,qt.text as query_text
from #beginprocess B
inner join #endprocess E
  on b.spid=e.spid
CROSS APPLY sys.dm_exec_sql_text(b.sql_handle) as qt
where
e.cpu-b.cpu > 0
order by cpuforbrug desc

-- Query til at vise læsnings forbrugerne

select top 10 e.io-b.io as ioForbrug,e.spid,e.status,e.loginName,e.hostname,e.program_name,qt.text as query_text
from #beginprocess B
inner join #endprocess E
  on b.spid=e.spid
CROSS APPLY sys.dm_exec_sql_text(b.sql_handle) as qt
where
e.io-b.io > 0
order by ioForbrug desc

-- Query til at vise memory forbrugerne

select top 10 e.memusage-b.memusage as MemForbrug,e.spid,e.status,e.loginName,e.hostname,e.program_name,qt.text as query_text
from #beginprocess B
inner join #endprocess E
  on b.spid=e.spid
CROSS APPLY sys.dm_exec_sql_text(b.sql_handle) as qt
where
e.memusage-b.memusage > 0
order by MemForbrug desc
