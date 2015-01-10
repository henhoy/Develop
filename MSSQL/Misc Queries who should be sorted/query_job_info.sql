-- We try to use sysjobactivity in job query to get "real time" and correct last run

use msdb
go

select sj.name,
       case 
         when sj.enabled = 0 then 'Not Enabled'
         when sj.enabled = 1 then 'Enabled'
       end,
       case
         when sjs.last_run_date is null then 'No Run'
		 --when sjs.last_run_date = 0 then 'No Run'
         --else convert(varchar(17),master.dbo.MO_ReturnJobTime(last_run_date, last_run_time), 13)
         else sjsch.next_scheduled_run_date
       end,
       case 
         when sjs.last_run_outcome = 0 then 'Failed'
         when sjs.last_run_outcome = 1 then 'Successfull'
         when sjs.last_run_outcome = 3 then 'Canceled'
         else 'Undefined outcome'
       end,
       case  
         when sjrs.Success_Pct > 95 then ' class="ok">' + convert(char(3),sjrs.Success_Pct)
         when sjrs.Success_Pct <= 95 and sjrs.Success_Pct >= 50 then ' class="warn">' + convert(char(2),sjrs.Success_Pct)
         when sjrs.Success_Pct < 50 then ' class="error">' + convert(char(2),sjrs.Success_Pct)
         else ' class="ignore">No History '
       end,
       sjrs.failed_runs,sjrs.total_runs,
       case
--         when sjsch.next_run_date is null then 'No Schedule'
--		 when sjsch.next_run_date = 0 then 'No Schedule'
         --when sjsch.next_scheduled_run_date is null then 'No Schedule'
		 when sjsch.next_scheduled_run_date = 0 then 'No Schedule'
		 --else convert(varchar(17),master.dbo.MO_ReturnJobTime(last_run_date, last_run_time), 13)
         else sjsch.next_scheduled_run_date
	   end
from dbo.sysjobs sj 
left outer join dbo.sysjobservers sjs
  on sj.job_id = sjs.job_id 
--left outer join dbo.sysjobschedules sjsch
left outer join dbo.sysjobactivity sjsch
  on sj.job_id = sjsch.job_id
left outer join (select tjr.job_id, tjr.total_runs, case when fjr.failed_runs is null then 0 else fjr.failed_runs end as failed_runs,
                   ((tjr.total_runs - case when fjr.failed_runs is null then 0 else fjr.failed_runs end) * 100) / tjr.total_runs Success_Pct
            from (select job_id, count(*) total_runs
                  from dbo.sysjobhistory
                  group by job_id) tjr
                  left outer join
                  (select job_id, count(*) failed_runs
                  from dbo.sysjobhistory
                  where run_status = 0
                  group by job_id) fjr
                  on tjr.job_id = fjr.job_id ) sjrs  -- sys_job_run_success
  on sj.job_id = sjrs.job_id
where sj.enabled = 1
and sjsch.session_id = ( select max(session_id) from syssessions)
order by sj.name

/*
select * from sysjobschedules
-- select * from sysjobhistory
select * from sysjobactivity order by job_id

select * from syssessions


select * 
from sysjobschedules sjs
join sysjobactivity sja
on sjs.job_id = sja.job_id
and sja.session_id = ( select max(session_id) from syssessions)

select * from syscategories 

*/