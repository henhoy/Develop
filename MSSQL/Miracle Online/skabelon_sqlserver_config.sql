/*
** Configuration file for sqlserver.sql
** Remove dashes (--) and set the value to change default behavior 
** Remember to save this file as "sqlserver_config.sql" 
**
** SVN tags:
** $Date: 2013-06-14 14:17:10 +0200 (fr, 14 jun 2013) $
** $Revision: 462 $
*/

/* Update the default (20) daysback value for latest online check */
--update #MORLT set Value = '7' where Name = 'latest_online_check';

/* Update the default (2500) minimum value for defragmented pages */
-- update  #MORLT  set Value = '5000' where Name = 'min_defrag_pages';
