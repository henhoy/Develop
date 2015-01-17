/*

script til rebuild af nødvendige indexes (obs på objectid og 2 parametre)
script til checkdb

Husk powerset on work_kunder\supergros\navision
*/


--SET CONTEXT_INFO  0x1 --Just to make sure everything's ok
--GO 
----treminate the script on any error. (Requires SQLCMD mode)
--:on error exit 
----If not in SQLCMD mode the above line will generate an error, so the next line won't hit
--SET CONTEXT_INFO 0x2
--GO
----make sure to use SQLCMD mode ( :on error needs that)
--IF CONTEXT_INFO()<>0x2 
--BEGIN
--    SELECT CONTEXT_INFO()
--    SELECT 'This script must be run in SQLCMD mode! (To enable it go to (Management Studio) Query->SQLCMD mode)\nPlease abort the script!'
--    RAISERROR('This script must be run in SQLCMD mode! (To enable it go to (Management Studio) Query->SQLCMD mode)\nPlease abort the script!',16,1) WITH NOWAIT 
--    WAITFOR DELAY '02:00'; --wait for the user to read the message, and terminate the script manually
--END
--GO

declare @phymem int, @maxsermem int, @navmem int, @bremem int, @boumem int;

create table #sysinf ( id int, name sysname, internal_value int, value nvarchar(512));

insert into #sysinf exec master.dbo.xp_msver

select @phymem=internal_value from #sysinf where name = 'PhysicalMemory'

select @maxsermem =
  case 
    when @phymem <= 1024   then 700
    when @phymem <= 2028   then 1500
    when @phymem <= 4096   then 3200
    when @phymem <= 6144   then 4800
    when @phymem <= 8192   then 6400
    when @phymem <= 12288  then 10000
    when @phymem <= 16384  then 13500
    when @phymem <= 24576  then 21500
    when @phymem <= 32768  then 29000
	else @phymem - 4096
  end



select @navmem = @maxsermem * 0.66, @bremem = @maxsermem * 0.16, @boumem = @maxsermem * 0.16


:setvar qnavmem @navmem

select @maxsermem, @phymem, @navmem, @bremem, @boumem


--:connect .\sql2012

--declare @newmem nvarchar(10);
--set @newmem = cast(@navmem as nvarchar(10))

--EXEC sys.sp_configure N'max server memory (MB)', @newmem
--GO
--RECONFIGURE WITH OVERRIDE
--GO

:connect .\sql2012
:on error exit
declare @newmem nvarchar(10), @instancename nvarchar(50), @expectedinstance nvarchar(50), @errormessage nvarchar(200);
select @instancename = cast(serverproperty ('InstanceName') as nvarchar);
select @instancename;

set @expectedinstance = 'SQLBOUNCE';
set @errormessage = 'Exiting ! - The expected instance is ' + @expectedinstance + ', but current instance is ' + isnull(@instancename,'''NULL''')

if @instancename <> @expectedinstance
begin
  SELECT @errormessage
  RAISERROR(@errormessage,16,1) WITH NOWAIT 
  WAITFOR DELAY '00:15'; --wait for the user to read the message, and terminate the script manually
end

set @newmem = cast($(qnavmem) as nvarchar(10))

select @newmem

-- Check expected instance name
if 

EXEC sys.sp_configure N'max server memory (MB)', @newmem
GO
RECONFIGURE WITH OVERRIDE
GO




drop table #sysinf;