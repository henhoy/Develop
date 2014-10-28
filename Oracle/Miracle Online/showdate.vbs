' ***************************************************************************************************
' ** Script           : showdate.vbs
' ** Type             : vbscript
' ** Info             : Returns a datestamp in the format YYYYMMDD (format YYYYMMDD-HH24MMss with timestamp)
' **                  :
' ** Usage            : Use the showdate.vbs i an *.cmd script to collect the datestamp
' **                  : Examples:
' **                  :
' **                  : FOR /f "tokens=1" %%A IN ('cscript.exe //nologo showdate.vbs') DO set DateStamp=%%A
' **                  : echo %Datestamp%_logfile.log  
' **                  :
' **                  : FOR /f "tokens=1" %%A IN ('cscript.exe //nologo showdate.vbs /dayoffset:-1') DO set DateStamp=%%A
' **                  : echo %Datestamp%_logfile.log  
' **                  :
' **                  : FOR /f "tokens=1" %%A IN ('cscript.exe //nologo showdate.vbs /withtimestamp:1') DO set DateStamp=%%A
' **                  : echo %Datestamp%_logfile.log  
' **                  :
' **                  :  
' ** History          : Ver. 1.0 20090206, Miracle/HMH - Created
' **                  : ver. 2.0 20110314, Miracle/HMH - Added parameter for +/- days offset
' **                  : ver. 3.0 20110427, Miracle/HMH - Added paremeter for add timestamp
' **
' ***************************************************************************************************
 
' Arguments object
Dim oArgs
set oArgs = WScript.Arguments
 
Dim oNamed
set oNamed = oArgs.Named
 
' Get the dayoffset parameter
Dim pDayOffset
  pDayOffset = oNamed("dayoffset")

' Get the withtimestamp parameter
Dim pWithTimestamp
  pWithTimestamp = oNamed("withtimestamp")
 
If IsEmpty(pDayOffset) then
  pDayOffset = 0
End If

If IsEmpty(pWithTimestamp) then
  pWithTimestamp = 0
End If

Dim pDate
pDate = Date+pDayOffset

'WScript.Echo pDate

' Get current hour
Dim pHour
pHour = Datepart("h",Now) 

If pHour < 10 Then
  pHour = 0 & pHour
End If

'Wscript.Echo pHour

Dim pMinute 
pMinute = Datepart("n",Now) 
If pMinute < 10 Then
  pMinute = 0 & pMinute
End If

'Wscript.Echo pMinute

Dim pSecond
pSecond = Datepart("s",Now)

If pSecond < 10 Then
  pSecond = 0 & pSecond
End If

'Wscript.Echo pSecond

Dim pTimeStamp
pTimeStamp = pHour & pMinute & pSecond

'Wscript.Echo pTimeStamp
 
' Get current year
strYear = DatePart("yyyy",pDate)
 
' Get current month, add leading zero if necessary
If DatePart("m",pDate) < 10 Then
    strMonth = 0 & DatePart("m",pDate)
Else
    strMonth = DatePart("m",pDate)
End If
 
' Get current day, add leading zero if necessary
If DatePart("d",pDate) < 10 Then
    strDay = 0 & DatePart("d",pDate)
Else
    strDay = DatePart("d",pDate)
End If

If pWithTimestamp = 0 Then 
  DateStamp = strYear & strMonth & strDay
Else
  DateStamp = strYear & strMonth & strDay & "-" & pTimeStamp
End IF
 
Wscript.Echo DateStamp
 
' End of showdate.vbs