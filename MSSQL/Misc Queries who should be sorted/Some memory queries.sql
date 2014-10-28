--create table #DOPC (
--sample int,
--object_name nchar(128),
--counter_name nchar(128),
--instance_name nchar(128),
--cntr_value bigint,
--cntr_type int);

--declare @waittimes int, @sample int;
--set @waittimes = 2
--set @sample = 1

--insert into #dopc
--select @sample,dopc.* 
--from sys.dm_os_performance_counters dopc
--where counter_name != 'Usage';

--while @waittimes > 0
--begin 
--  waitfor DELAY '000:01:00'   -- et minut
--  set @waittimes = @waittimes - 1;
--  set @sample = @sample + 1;
--  insert into #dopc
--  select @sample,dopc.* 
--  from sys.dm_os_performance_counters dopc
--  where counter_name != 'Usage';
--end;


--drop table #DOPC

select min(cntr_value) min, max(cntr_value) max, avg(cntr_value) avg
from #DOPC
where counter_name in ('Page life expectancy');



select object_name, counter_name, instance_name, min(cntr_value) min, max(cntr_value) max, avg(cntr_value) avg
from #DOPC
where counter_name != 'Usage'
and object_name not like '%Batch Resp Statistics%'
and object_name not like '%Broker Statistics%'
group by object_name, counter_name, instance_name;

select * from #DOPC
where sample = 1
and cntr_type = 65792;