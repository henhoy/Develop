-- We try to use sysjobactivity in job query to get "real time" and correct last run


drop table #tempjobinfo

select sj.name,
       sj.description,
       sj.enabled,
       sjs.last_run_date,
       sjs.last_run_duration,
       sjs.last_run_outcome,
       sjs.last_outcome_message,
       sjrs.success_pct,
       sjrs.failed_runs,sjrs.total_runs,
       sjsch.next_scheduled_run_date
into #tempjobinfo
--select *
from dbo.sysjobs sj 
left outer join dbo.sysjobservers sjs
  on sj.job_id = sjs.job_id 
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

select * from #tempjobinfo