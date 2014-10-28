
## Vi leder efter en specialversion til rul af alert loggen. 

special () {
  echo Vi fandt en specialversion: ${file_name} og koerer denne.
  sh ${file_name} 
}

standard() {
  echo Vi fandt ingen specialversion ${file_name} - saa vi koerer standardversionen: CHECK_MAINTENANCE.SH

  echo "Rotate Alert.log y/n : \c"
  read answer

  if [ "$answer" = "y" ] || [ "$answer" = "Y" ]
  then
    sqlplus "/ as sysdba" @check_maintenance.sql UNIX 
  fi
}

copyalert2log() {
##  Er alertcopy sat til NO/N?
##  Gaa til exit - vi kopierer IKKE alert loggen !
if [ "$ALERTCOPY" = "NO" ] || [ "$ALERTCOPY" = "N" ]
then
  exit
fi

if [ -f xx_sets.cmd ]; then
   ## Koer exports fra alertlog rul
   chmod 700 xx_sets.cmd
   . xx_sets.cmd
   ## kopier til Log destinationen 
   cp -f ${ALERT_LOG} $1/${ALERT_FNAME}
fi

}

echo Alertcopy $ALERTCOPY
export file_name=CHECK_MAINTENANCE_${ORACLE_SID}.SH

if [ -f $file_name ]; then
  special 
else
  standard 
fi

## kaldes med LOG_DIR som $1
copyalert2log $1