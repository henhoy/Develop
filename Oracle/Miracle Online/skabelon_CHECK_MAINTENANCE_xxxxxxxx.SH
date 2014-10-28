## Kører en Oracle_sid afhængig version af check_maintenace jobbet
## Her kan du jo også ligge fx rotate af listenerlog, hvis du vil :-)

rotate_alert()
{
echo "Rotate Alert.log y/n : \c"
read answer

if [ "$answer" = "y" ] || [ "$answer" = "Y" ]
then
  sqlplus "/ as sysdba" @check_maintenance.sql UNIX 
fi
}

rotate_listener()
{
##  Listener Log info & evt. rotate
## angiv folder og filnavn - folder skal slutte med en / !!!!
export LISTENER_FDIR=/u01/app/oracle/diag/tnslsnr/localhost/listener/trace/
export LISTENER_FNAME=listener.log
export LISTENER=LISTENER

export DATO=`date +%Y%m%d`

# find filen og størrelsen

export lis_size=`ls -lr ${LISTENER_FDIR}${LISTENER_FNAME}| tail -1 | awk '{print $5}'`
 
echo "Listener loggen " ${LISTENER_FNAME} "is" $lis_size "bytes."
echo "Rotate Listener.log y/n : \c"
read answer

if [ "$answer" = "y" ] || [ "$answer" = "Y" ]
then
  rotate_listener_hardwork
fi
}

rotate_listener_hardwork()
{

# LSNRCTL 
lsnrctl <<EOF
set current_listener ${LISTENER}
set log_status off
EOF

echo 
mv -i ${LISTENER_FDIR}${LISTENER_FNAME} ${LISTENER_FDIR}${DATO}_${LISTENER_FNAME}
echo
echo ${LISTENER_FNAME} renamet til ${DATO}_${LISTENER_FNAME}
echo

# LSNRCTL 
lsnrctl <<EOF
set current_listener ${LISTENER}
set log_status on
EOF

}

## -----------------------------------------------------------------

rotate_alert 
rotate_listener
