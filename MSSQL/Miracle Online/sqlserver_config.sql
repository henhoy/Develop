/* Remember to save this file as "sqlserver_config.sql" */

/* Update the default (20) daysback value for latest online check */
--update #MORLT set value = '7' where name = 'latest_online_check';

/* Update the default (2500) minimum value for defragmented pages */
--update  #MORLT  set value = '5000' where name = 'min_defrag_pages';
