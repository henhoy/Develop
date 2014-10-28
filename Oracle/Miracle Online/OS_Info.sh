#!/usr/bin/ksh
#----------------------------------------------------------------
# SCRIPT:
#
# AUTHOR: Mette Stephansen, samt ran og lån fra Randal Michael
#
#----------------------------------------------------------------

  MIG=$(basename $0)
  HOST=$(hostname)
  screen=N

    case $(uname) in

        SunOS) date=`date +%Y%m%d`
           date2=`date +%Y-%m-%d`
               time=`date +%H:%M:%S`
         ;;
        *)
           date=`date +%C%y%m%d`
               date2=`date +%C%y-%m-%d`
               time=`date +%H:%M:%S`
               ;;
  esac

  osinfo=`uname -a`
  mach=`uname`
  myn=`uname -n`
  version=`uname -v`
  release=`uname -r`
  build=`cat /etc/*-release`
  uptime=`uptime`
  crontab=`crontab -l 2>/dev/null`

  FILE=`date +%Y%m%d`-`date +%H%M`_`hostname`

  html=${FILE}_Disk_space.html
  txt=${FILE}_Disk_space.txt

  wkfile=${date}_Disk_spac_wk.txt
  wkfile2=${date}_Disk_spac_wk2.txt

  PC_LIMIT=65

  DiskWarning=75
  DiskCritical=90
  red='FF0000'
  yellow='EEDD11'
  green='009900'
  black='000000'
  white='FFFFFF'

###  U S A G E  ###
usage()
{
    echo
    echo "Sådan kan du bruge $MIG.... "
    echo
    echo $MIG "-h <htmlfilnavn> -t <txtfilnavn> -s"
    echo
}

###  T E C H O  ###
techo()
{
  echo "$*" >> $txt
}

###  H E C H O  ###
hecho()
{
  echo "$*" >> $html
}

###  G E T _ O S  ###
function get_OS
{

typeset -u OS # Use the UPPERCASE values for the OS variable
OS=`uname`    # Grab the Operating system, i.e. AIX, HP-UX
print $OS     # Send back the UPPERCASE value

}

###  I N I T  ###
init()
{

echo `date +%H:%M:%S` "in init()"

#options = -t og -h -s

while getopts “:h:t:s” INPUT
do
   case $INPUT in
     h) html=$OPTARG ;;
     t) txt=$OPTARG;;
     s) screen=Y;;
    \?) usage
        exit 1;;
   esac
done

> $txt
> $html

echo > $txt

html_header

}

###  R Y D O P  ###
rydop()
{
  rm -f $wkfile $wkfile2
  rm -f $PAGING_STAT
}

###  C A L C  ###
calc()
{
result=$(bc <<EOF
scale=$3
($1 / $2)
EOF
)
print $result
}

###  P A D S T R I N G  ###
padstring() {
    printf "%-${2}s" $1
}

###  H T M L _ H E A D E R  ###
html_header()
{

  hecho '<head>'
  hecho '<style type="text/css">'
  hecho 'p, td, div, th {font-family:Arial, Helvetica, sans-serif;}'
  hecho '</style>'
  hecho '</head>'
  hecho '<p><img src="http://miracleas.dk/images/miracle/images/logo/miracle_online_170.gif">'
  hecho '<p align=right>Online tjek d.'
  hecho $date2
  hecho '&nbsp;&nbsp;'
  hecho $time
  hecho '<font face=sans-serif>'
}

###  D I S K I N F O  ###
diskinfo()
{
  echo `date +%H:%M:%S` "in diskinfo()"
  case $(uname) in

  HP-UX)  df -kP | awk 'FNR>1' | grep % | awk '{print $6, $1, $2, $3, $4, $5}' > $wkfile;;

    SunOS) df -lkF zfs > $wkfile2
           cat $wkfile2 | grep % | awk '{print $6, $1, $2, $3, $4, $5}' > $wkfile;;

  Linux) df -kP | awk 'FNR>1' | grep % | awk '{print $6, $1, $2, $3, $4, $5}' > $wkfile;;

    AIX)   df -kP | awk 'FNR>1' | grep % | awk '{print $6, $1, $2, $3, $4, $5}' > $wkfile;;

      *) rm $wkfile
               echo "Ukendt Operativsystem " $(uname)
         return 1;;
  esac

  printdiskinfo

}

###  P R I N T D I S K I N F O  ###
printdiskinfo()
{

hecho '<h3>Disk Information</h3><p>'

GHtml="<p><table width=450px border=0 cellspacing=8 cellpadding=0>"
GHtml="$GHtml <tr><td height=20>"

#----------------------------------------------
# Læs fra wkfilen output fra -df kommandoerne
# til at danne "graferne" over diskforbruget
#----------------------------------------------
while read inputline
do

     mount="$(echo $inputline | awk '{print $1}')"
       pct="$(echo $inputline | awk '{print $6}' | sed 's/.$//' )"

   FGC=$white
   if (( "$pct" >= $DiskCritical )); then
      BGC=$red
   else
      if (( "$pct" >= $DiskWarning )); then
         BGC=$yellow
         FGC=$black
      else
         BGC=$green
      fi
   fi

   GHtml=$GHtml$mount
   GHtml="$GHtml <table border=0 cellspacing=0 cellpadding=0 height=15 width=100%><tr><td bgcolor=#CCCCCC>"
   GHtml="$GHtml    <table width=$pct% border=0 cellspacing=0 cellpadding=0 height=100%><tr><td bgcolor=#$BGC >"
   GHtml="$GHtml <div align=center><b><font size=1 color=#$FGC>Used $pct %"
   GHtml="$GHtml    </font></b></div>"
   GHtml="$GHtml    </td></tr></table>"
   GHtml="$GHtml </td></tr></table>"

done < $wkfile

GHtml="$GHtml </table>"

hecho $GHtml

# Diskforbrug til HTML output

hecho '<p><table border=1 cellpadding=2><font face=sans-serif>'
hecho '<tr>'
hecho '<th>Mount point'
hecho '<th>File system'
hecho '<th>Total MB'
hecho '<th>Used MB'
hecho '<th>Avail MB'
hecho '<th>Used %'
hecho '</tr>'


# Diskforbrug til TXT output

techo
techo "Oversigt over diskforbuget"
techo "--------------------------"
techo

#----------------------------------------------
# Læs fra wkfilen output fra -df kommandoerne
# til at danne tabellen over diskforbruget
#----------------------------------------------

while read inputline
do
    mount="$(echo $inputline | awk '{print $1}')"
  filsyst="$(echo $inputline | awk '{print $2}')"
   blocks="$(echo $inputline | awk '{print $3}')"
     used="$(echo $inputline | awk '{print $4}')"
    avail="$(echo $inputline | awk '{print $5}')"
      pct="$(echo $inputline | awk '{print $6}' | sed 's/.$//' )"   #fjern %'en

  hecho '<tr align=right><td align=left>' $mount '<td align=left>' $filsyst '<td>' $(calc $blocks 1024 2)
  hecho '                <td>' $(calc $used 1024 2) '<td>' $(calc $avail 1024 2)'<td>' $pct ' %</tr>'

  techo $mount  $filsyst $(calc $blocks 1024 2)  $(calc $used 1024 2)  $(calc $avail 1024 2)  $pct '%'

done < $wkfile

hecho '</table>'
techo

}

###  M E M I N F O ###
meminfo()
{
echo `date +%H:%M:%S` "in meminfo()"

> $wkfile

case $(uname) in

  HP-UX)  top -d1 -f $wkfile2
          cat $wkfile2 | grep Memory: | awk '{print $2, $5, $8}' > $wkfile;;

        SunOS) ;;

  Linux) top -n1 | grep Mem: | awk '{print $3, $5, $7}' > $wkfile;;

        AIX)  svmon | grep memory | awk '{print $2, $3, $4}' > $wkfile;;

      *) rm $wkfile
               echo "Ukendt Operativsystem " $(uname)
         return 1;;
esac

while read inputline
do
    # Linux har et irriterende k stående bagefter tallet - det fjerner vi lige
    case $(uname) in Linux | HP-UX)
    total="$(echo $inputline | awk '{print $1}' | sed 's/.$//' )"
     used="$(echo $inputline | awk '{print $2}' | sed 's/.$//' )"
     free="$(echo $inputline | awk '{print $3}' | sed 's/.$//' )";;
   *)
       total="$(echo $inputline | awk '{print $1}' )"
         used="$(echo $inputline | awk '{print $2}' )"
         free="$(echo $inputline | awk '{print $3}' )";;
     esac

  hecho '<tr><td>Total Memory : <td>' $(calc $total 1024 2) 'MB'
  hecho '<tr><td>Used Memory : <td>' $(calc $used 1024 2) 'MB'
  hecho '<tr><td>Free Memory : <td>' $(calc $free 1024 2) 'MB'

  techo 'Total Memory      : ' $(calc $total 1024 2) 'MB'
  techo 'Used Memory       : ' $(calc $used 1024 2) 'MB'
  techo 'Free Memory       : ' $(calc $free 1024 2) 'MB'
done < $wkfile

hecho '</table>'
techo

}

###  O S I N F O ###
osinfo()
{
echo `date +%H:%M:%S` "in osinfo()"
#----------------
# Hent oppetid
#----------------

uptime2="$(echo $uptime| cut -d, -f1)"
uptime3="$(echo $uptime| cut -d, -f2)"
cpu1="$(echo $uptime| cut -d, -f4)"

cpu1="$(echo $cpu1| cut -d: -f2)"
cpu2="$(echo $uptime| cut -d, -f5)"
cpu3="$(echo $uptime| cut -d, -f6)"

case $(uname) in
AIX)
   buildversion='n/a'
       ;;
*)
   buildversion=$build
  ;;
esac

#---------------------------------------------------

techo
techo "OS Info"
techo "-------"
techo
techo 'Operating System  : ' $mach
techo 'Machine           : ' $myn
techo 'IP adr.           : '
techo 'Version           : ' $version
techo 'Release           : ' $release
techo 'Build             : ' $buildversion
techo '                  : ' $osinfo
techo
techo 'Uptime            : ' $uptime2 $uptime3
techo 'CPU%              :  last 1 min. >' $cpu1 '%, last 5 min. >' $cpu2 '%, last 15 min. >'  $cpu3 '%'
techo

hecho "<h3>OS Info</h3>"

hecho '<table border = 0>'
hecho '<tr><td width="200px">Operating System :<td>' $mach
hecho '<tr><td>Machine  : <td>' $myn

hecho '<tr><td>Version  :<td>' $version
hecho '<tr><td>Release  :<td>' $release
hecho '<tr><td>Build    :<td>' $buildversion
hecho '<tr><td>OS Info  :<td>' $osinfo

hecho '<tr><td>&nbsp;</tr>'
hecho '<tr><td>Uptime  : <td>' $uptime2 $uptime3
hecho '<tr><td>CPU%    : <td>' 'last 1 min. >' $cpu1 '%, &nbsp;&nbsp; last 5 min. >' $cpu2 '%, &nbsp;&nbsp; last 15 min. >'  $cpu3 '%'
hecho '<tr><td>&nbsp;</tr>'

case $(uname) in
        SunOS) ipsolaris;;
      *) ;;
esac

#meminfo

hecho '</table>'

}

ipsolaris()
{
echo `date +%H:%M:%S` "in ipsolaris()"

  techo "IP adresser: "
    hecho "<tr><td>IP adresse(r) : <td>"

  ipall=""

  ifconfig -a | grep inet | awk '{print $2}' \
  | while read ipadr
    do
       ipall=$ipall"[ "$ipadr" ]  "
    done

  techo $ipall
  hecho $ipall

}

###  P R O C I N F O  ###
procinfo()
{
echo `date +%H:%M:%S` "in procinfo()"
hecho "<h3>DB Info</h3>"


techo "DB Info"
techo "--------"
techo

techo "Instanser:"
hecho "<h4>Instanser</h4>"


ps -ef | grep pmon | grep -v grep | awk '{print}' \
            | while read linie
do
  techo $linie
  hecho $linie "<br>"
done

techo
hecho "<br> "

techo "Listeners:"
hecho "<h4>Listeners</h4>"

ps -ef | grep tnslsnr | grep -v grep | awk '{print}' \
            | while read linie
do
  techo $linie
  hecho $linie "<br>"
done

techo
hecho "<br> "

}

###  C P U I N F O  ###
cpuinfo()
{
echo `date +%H:%M:%S` "in cpuinfo()"
techo "CPU Info"
techo "---------"
techo

hecho "<h3>CPU Info</h3>"
hecho '<table border=0>'

case $(uname) in

        AIX) cpuinfo_aix  ;;
          *) cpuinfo_andre ;;
esac

hecho '</table>'
techo

}

###  C P U I N F O _ A I X  ###
cpuinfo_aix()
{
  echo `date +%H:%M:%S` "in cpuinfo_aix()"
  vmstat | grep lcpu | awk '{print $3, $4}' | while read lcpu memory
  do
    techo "Antal CPU'er       : " $lcpu
  techo "Installeret memory : " $memory
  techo

  hecho "<tr><td>Antal CPU'er: <td>" $lcpu
  hecho "<tr><td>Installeret memory: <td>" $memory
  done

  vmstat | tail -1 | awk '{ print $14, $15, $16, $17 }' | while read user system idle waits
  do
     techo "User part          :  ${user} %"
     techo "System part        :  ${system} %"
     techo "I/O wait state     :  ${waits} %"
     techo "Idle time          :  ${idle} %"

     hecho '<tr><td width="200px">User part : <td align=right>' $user '%'
     hecho '<tr><td>System part :    <td align=right>' $system '%'
     hecho '<tr><td>I/O wait part :  <td align=right>' $waits '%'
     hecho '<tr><td>Idle time :      <td align=right>' $idle '%'
  done

}

###  C P U I N F O _ A N D R E  ###
cpuinfo_andre()
{
echo `date +%H:%M:%S` "in cpuinfo_andre()"

case $(uname) in
  SunOS)
  psrinfo | wc -l | awk '{print $1}' | while read lcpu
  do
    lcpux=$lcpu
  done

  psrinfo -p | awk '{print $1}' | while read pcpu
  do
   pcpux=$pcpu
  done

  techo 'Antal CPU  fys/log     : ' $pcpux " / " $lcpux
  hecho '<tr><td>Antal CPUer fys/log  : <td align=left>' $pcpux " / " $lcpux
  ;;

  *)
    ;;

esac

seconds=5  # Defines the number of seconds for each sample
interval=2 # Defines the total number of sampling intervals

# These "F-numbers" point to the correct field in the
# command output for each UNIX flavor.

case $(uname) in
AIX|HP-UX|SunOS)
       F1=2
       F2=3
       F3=4
       F4=5
       F5=5
       ;;
Linux)
       F1=3
       F2=4
       F3=5
       F4=6
       F5=8
       ;;
*) echo
   echo "ERROR: Usupporteret Operativ-system: $(uname) ..... vi stopper"
   echo
   exit 1 ;;
esac

sar $seconds  $interval | grep Average \
          | awk '{print $'$F1', $'$F2', $'$F3', $'$F4', $'$F5'}' \
          | while read FIRST SECOND THIRD FORTH FIFTH
do
      # Based on the UNIX Flavor, tell the user the
      # result of the statistics gathered.

      case $(uname) in
      AIX|HP-UX|SunOS)
            techo "User part         : ${FIRST} %"
            techo "System part       : ${SECOND} %"
            techo "I/O wait state    : ${THIRD} %"
            techo "Idle time         : ${FORTH} %"

            hecho '<tr><td width="200px">User part : <td align=right>' ${FIRST} '%'
            hecho '<tr><td>System part :    <td align=right>' ${SECOND} '%'
            hecho '<tr><td>I/O wait part :  <td align=right>' ${THIRD} '%'
            hecho '<tr><td>Idle time :      <td align=right>' ${FORTH} '%'

            ;;
      Linux)
            techo "User part         : ${FIRST} %"
            techo "Nice part         : ${SECOND} %"
            techo "System part       : ${THIRD} %"
            techo "I/O wait part     : ${FORTH} %"
            techo "Idle time         : ${FIFTH} %"

            hecho '<tr><td width="200px">User part : <td align=right>' ${FIRST} '%'
            hecho '<tr><td>Nice part :      <td align=right>' ${SECOND} '%'
            hecho '<tr><td>System part :    <td align=right>' ${THIRD} '%'
            hecho '<tr><td>I/O wait part :  <td align=right>' ${FORTH} '%'
            hecho '<tr><td>Idle time :      <td align=right>' ${FIFTH} '%'

            ;;
      esac
done

}

###  L I N U X _ S W A P _ M O N  ###
function Linux_swap_mon
{
echo `date +%H:%M:%S` "in Linux_swap_mon()"
free -m | grep -i swap | while read junk SW_TOTAL SW_USED SW_FREE
do

# Use the bc utility in a here document to calculate
# the percentage of free and used swap space.

PERCENT_USED=$(bc <<EOF
scale=2
($SW_USED * 100 / $SW_TOTAL)
EOF
)

PERCENT_FREE=$(bc <<EOF
scale=2
($SW_FREE * 100 / $SW_TOTAL)
EOF
)

     techo "Swap/Page Info"
     techo "---------------"
     techo

     # Produce the rest of the paging space report:
     techo "Total Swap Space  : ${SW_TOTAL} MB"
     techo "Swap Space Used   : ${SW_USED} MB"
     techo "Space Free        : ${SW_FREE} MB"
     techo
     techo "Swap Space Used   : ${PERCENT_USED} %"
     techo "Swap Space Free   : ${PERCENT_FREE} %"

     # Grap the integer portion of the percent used to
     # test for the over limit threshold

     INT_PERCENT_USED=$(echo $PERCENT_USED | cut -d. -f1)

     if (( PC_LIMIT <= INT_PERCENT_USED ))
     then
          tput smso
          techo "WARNING: Paging Space has Exceeded the ${PC_LIMIT}% Upper Limit! ${INT_PERCENT_USED}"
          tput rmso
     fi

     # Til HTML filen

     hecho "<p><h3>Swap/Page Info</h3>"
     hecho "<table border=0>"

     hecho "<tr><td width=\"200px\">Total Swap Space  : <td> ${SW_TOTAL} MB"
     hecho "<tr><td>Swap Space Used : <td align=right> ${SW_USED} MB"
     hecho "<tr><td>Swap Space Free : <td align=right> ${SW_FREE} MB"
     hecho
     hecho "<tr><td>Swap Space Used  : <td align=right> ${PERCENT_USED} %"
     hecho "<tr><td>Swap Space Free  : <td align=right> ${PERCENT_FREE} %"

     hecho "</table>"

done

techo
}


###  H P _ U X _ S W A P _ M O N  ###
function HP_UX_swap_mon
{
echo `date +%H:%M:%S` "in HP_UX_swap_mon()"
# Start a while read loop by using the piped in input from
# the swapinfo -tm command output.


#swapinfo -tm | grep dev | while read junk SW_TOTAL SW_USED \
#                               SW_FREE PERCENT_USED junk2
#do
#    # Calculate the percentage of free swap space
#
#    ((PERCENT_FREE = 100 - $(echo $PERCENT_USED | cut -d% -f1) ))
#
#
#    echo "Swap/Page Info"
#    echo "---------------"
#    echo
#    echo "Total Amount of Swap Space  : ${SW_TOTAL} MB"
#    echo "Total MB of Swap Space Used :  ${SW_USED} MB"
#    echo "Total MB of Swap Space Free :  ${SW_FREE} MB"
#    echo "Percent of Swap Space Used  : ${PERCENT_USED}"
#    echo "Percent of Swap Space Free  : ${PERCENT_FREE} %"
# echo
#
#    # Check for paging space exceeded the predefined limit
#
#    if (( PC_LIMIT <= $(echo $PERCENT_USED | cut -d% -f1) ))
#    then
#        # Swap space is over the predefined limit, send notification
#         techo "WARNING: Swap Space has Exceeded the ${PC_LIMIT}% Upper Limit!"
#    fi
#
#done

echo
}

###  A I X _ P A G I N G _ M O N  ###
function AIX_paging_mon
{
echo `date +%H:%M:%S` "in AIX_paging_mon()"
PAGING_STAT=tmp_paging_stat.out # Paging Stat hold file

# Load the data in a file without the column headings

lsps -s | tail +2 > $PAGING_STAT

# Start a while loop and feed the loop from the bottom using
# the $PAGING_STAT file as redirected input

while read TOTAL PERCENT
do
     # Clean up the data by removing the suffixes
     PAGING_MB=$(echo $TOTAL | cut -d 'MB' -f1)
     PAGING_PC=$(echo $PERCENT | cut -d% -f1)

     # Calculate the missing data: %Free, MB used and MB free
     (( PAGING_PC_FREE = 100 - PAGING_PC ))
     (( MB_USED = PAGING_MB * PAGING_PC / 100 ))
     (( MB_FREE = PAGING_MB - MB_USED ))

     # Produce the rest of the paging space report:
     techo "Swap/Page Info"
     techo "---------------"
     techo
     techo "Total Paging Space: ${PAGING_MB} MB"
     techo "Paging Space Used : ${MB_USED} MB"
     techo "Paging Space Free : ${MB_FREE} MB"
     techo "Paging Space Used : ${PERCENT}"
     techo "Paging Space Free : ${PAGING_PC_FREE} %"
   techo

     # Check for paging space exceeded the predefined limit
     if ((PC_LIMIT <= PAGING_PC))
     then
          # Paging space is over the limit, send notification
          techo "WARNING: Paging Space has Exceeded the ${PC_LIMIT}% Upper Limit!\n"
     fi

# Til HTML filen

     hecho "<p><h3>Swap/Page Info</h3>"
     hecho "<table border=0>"

     hecho "<tr><td width=\"200px\">Total Paging Space  : <td> ${PAGING_MB} MB"
     hecho "<tr><td>Paging Space Used : <td align=right> ${MB_USED} MB"
     hecho "<tr><td>Paging Space Free : <td align=right> ${MB_FREE} MB"
     hecho "<tr><td>Paging Space Used  : <td align=right> ${PERCENT} "
     hecho "<tr><td>Paging Space Free  : <td align=right> ${PAGING_PC_FREE} %"

     hecho "</table>"

done < $PAGING_STAT

rm -f $PAGING_STAT

echo
}

###  S U N _ S W A P _ M O N  ###
function SUN_swap_mon
{
echo `date +%H:%M:%S` "in SUN_swap_mon()"
# Use two awk statements to extract the $9 and $11 fields
# from the swap -s command output

SW_USED=$(swap -s | awk '{print $9}' | cut -dk -f1)
SW_FREE=$(swap -s | awk '{print $11}' | cut -dk -f1)

# Add SW_USED to SW_FREE to get the total swap space

((SW_TOTAL = SW_USED + SW_FREE))

# Calculate the percent used and percent free using the
# bc utility in a here documentation with command substitution

PERCENT_USED=$(bc <<EOF
scale=2
($SW_USED * 100 / $SW_TOTAL)
EOF
)

PERCENT_FREE=$(bc <<EOF
scale=2
($SW_FREE * 100 / $SW_TOTAL)
EOF
)

# Convert the KB measurements to MB measurements

((SW_TOTAL_MB = SW_TOTAL / 1000))
((SW_USED_MB  = SW_USED / 1000))
((SW_FREE_MB  = SW_FREE / 1000))

# Produce the remaining part of the report
techo
techo "Total Amount of Swap Space:  ${SW_TOTAL_MB} MB"
techo "Total KB of Swap Space Used: ${SW_USED_MB} MB"
techo "Total KB of Swap Space Free: ${SW_FREE_MB} MB"
techo "Percent of Swap Space Used:  ${PERCENT_USED} %"
techo "Percent of Swap Space Free:  ${PERCENT_FREE} %"


# Til HTML filen

hecho "<p><h3>Swap/Page Info</h3>"
hecho "<table border=0>"

hecho "<tr><td width=\"200px\">Total Swap Space:  <td align=right> ${SW_TOTAL_MB} MB"
hecho "<tr><td>Swap Space Used: <td align=right> ${SW_USED_MB} MB"
hecho "<tr><td>Swap Space Free : <td align=right> ${SW_FREE_MB} MB"
hecho "<tr><td>Swap Space Used :  <td align=right> ${PERCENT_USED} %"
hecho "<tr><td>Swap Space Free :  <td align=right> ${PERCENT_FREE} %"

hecho "</table>"

# Grab the integer portion of the percent used

INT_PERCENT_USED=$(echo $PERCENT_USED | cut -d. -f1)

# Check to see if the percentage used maxmum threshold
# has beed exceeded

if (( PC_LIMIT <= INT_PERCENT_USED ))
then
    # Percent used has exceeded the threshold, send notification
    echo "WARNING: Swap Space has Exceeded the ${PC_LIMIT}% Upper Limit!"
fi

echo

}

###  S W A P I N F O  ###
swapinfo()
{
echo `date +%H:%M:%S` "in swapinfo()"
# Hvilket OS er vi på ?

   case $(uname) in

        AIX)   AIX_paging_mon  ;;
        HP-UX) HP_UX_swap_mon  ;;
        Linux) Linux_swap_mon  ;;
        SunOS) SUN_swap_mon    ;;
        *) echo
           echo "ERROR: Usupporteret Operativ-system: $uname ..... vi stopper"
           echo
           exit 1 ;;
   esac
}

#############################################################################
{

echo
echo `date +%H:%M:%S` "$MIG gaar igang med dagens dont ....."
echo

   init $*

   echo
   echo "HTML output: " $html
   echo "TXT  output: " $txt
   echo

   techo 'Online tjek d.' $date2 ' kl.' $time
   techo
   techo $(get_OS) " on " $HOST
   techo

   diskinfo
   osinfo

   cpuinfo
   swapinfo

   procinfo

   if [ "$screen" = 'Y' ] ; then
      echo "#################################################################################"
      cat $txt
      echo "#################################################################################"
   fi

   rydop

echo
echo `date +%H:%M:%S` "$MIG siger \"Farvel og tak\" ....."
echo

}
