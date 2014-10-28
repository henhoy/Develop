#!/usr/bin/sh

export SCRIPTDIR=/home/oracle10/miracle_online/script 
export LOGDIR=/home/oracle10/miracle_online/log 
export BACKUPLOG_DIR=/home/oracle/rman/logs
export FILE=`date +%Y%m%d`-`date +%H%M`
export DATE_ONLY=`date +%Y%m%d`
export FTP_USER=mo-thisted
export FTP_PWD=pwd2thisted
export ALERTCOPY=YES

# Get newest versions of scripts
ftp -n < get_update2011_scripts_unix.ftp
ftp -n < update2011_scripts_unix.ftp

# Run script on 1..m instances
export ORACLE_SID=tiap1
sqlplus "/ as sysdba" @${SCRIPTDIR}/check_start.sql UNIX ${LOGDIR}

# MOT alertlog filen
. xx_sets.cmd
perl mot.pl --scanlog ${ALERT_LOG} > ${LOGDIR}/${ALERT_FNAME}_MOT.log

# MOT på evt. RMAN logs
perl mot.pl -scan  ${BACKUPLOG_DIR} -filemask <de filer man vil lede i> -newer 8 -match "RMAN-","ORA-" > ${LOGDIR}/${FILE}_`hostname`_rman_backup_errors.log

cd ${LOGDIR}

# Get Disk Space utilization
df -kP>${FILE}_`hostname`.space.txt

# Get Listener Status
lsnrctl status  >  ${FILE}_`hostname`.listener.txt
lsnrctl service >> ${FILE}_`hostname`.listener.txt

# FTP results back to Miracle
ftp -n ftp.miracleas.dk <<EOF
user ${FTP_USER} ${FTP_PWD}
prompt
mput ${DATE_ONLY}*
bye
EOF
