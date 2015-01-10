drop table #space_info

declare @name                 nvarchar(100)
declare @dbid                 int
declare @exec_stmt            varchar(1600)
declare @state_desc           nvarchar(60)
 
create table #space_info
(
  DatabaseName                varchar(100) null,
  state_desc                  nvarchar(60) null,
  FileGroupName               varchar(120) null,
  Name                        varchar(120) null,
  FileName                    varchar(250) null,
  SizeKB                      dec(15) null,
  UsedKB                      dec(15) null,
  FreeKB                      dec(15) null,
  MaxSizeKB                   dec(15) null,
  pctfree                     dec(15) null,
  status                      int null,
  growth                      int null
)

declare dbname_crr cursor for 
  select name, state_desc, database_id from master.sys.databases --where state = 0;

open dbname_crr
fetch dbname_crr into @name, @state_desc, @dbid

while @@fetch_status >= 0
begin
--  if convert(sysname,DatabasePropertyEX(@name,'Status')) != 'OFFLINE'
    if  @state_desc = 'ONLINE'
    begin
      set @exec_stmt = 'use ' + quotename(@name, N'[') +
        'insert into #space_info (DataBaseName, State_Desc, FileGroupName, Name, FileName, SizeKB, UsedKB, FreeKB, MaxSizeKB, PctFree, status, growth) ' +
        'select ''' + @name + ''',''' + @state_desc + ''', fg.groupname, f.name, f.filename, f.size*8 , fileproperty(name, ''spaceused'')*8,
           f.size*8 - fileproperty(name, ''spaceused'')*8,
           maxsize,
           100 - (fileproperty(name, ''spaceused'')*8) / (cast(size as decimal(15))*8) * 100,
           f.status, f.growth
        from sysfiles as f
        left outer join sysfilegroups as fg  
        on f.groupid = fg.groupid'
      --select @exec_stmt
      execute (@exec_stmt)
    end
  else
    begin
      insert into #space_info values (@name, @state_desc, 'DB OFFLINE', 'Unknown', 0, 0, 0, 0, 0, 0, 0, 0)
    end
  
  fetch dbname_crr into @name, @state_desc, @dbid
end

deallocate dbname_crr

select databasename, state_desc state, 
       sum(sizekb)/1024 as fulldbMB, -- Same as properties on DB
       sum(case
             when FileGroupName is not null then sizekb
             else 0
           end)/1024 as DatafileMB,   
       sum(case
             when FileGroupName is null then sizekb
             else 0
           end)/1024 as LogfileMB,
--       sum(case
--             when FileGroupName is not null then usedkb
--             else 0
--           end)/1024 as UsedDatafileMB,
--       sum(usedkb)/1024 , 
       sum(case
             when FileGroupName is not null then freekb
             else 0
           end)/1024  as FreeDatafileMB,
       sum(case
             when FileGroupName is null then freekb
             else 0
           end)/1024  as FreeLogfileMB
       --sum(freekb)/1024 as FreeMB
from #space_info
group by databasename, state_desc
order by DataBaseName

select * 
from #space_info
where databasename in ('master','model','msdb','tempdb')
order by databasename;

select * 
from #space_info
where databasename not in ('master','model','msdb','tempdb')
order by databasename;

--select * from #space_info
--    select '<a name="SpaceInfo" class="ah2">Data space info for database instance: ' + convert(sysname,SERVERPROPERTY('ServerName')) + '</a>'
--    select '<table>'
--    select '<tr><th>Database Name</th><th>Filegroup Name</th><th>Name</th><th>File Name</th><th>Size MB</th>' + 
--           '<th>Used MB</th><th>Free MB</th><th>Maxsize MB</th><th> % Free</th><th>Growth</th></tr>'
    
--    select '<tr>' +
--           '<td>' + case when len(DataBaseName) > 27 then '<a class="substr" title="' + DataBaseName + '">' + substring(DataBaseName,1,24) + '...' else DataBaseName end + '</td>' +
--           '<td>' + FileGroupName + '</td>' +
--           '<td>' + case when len(Name) > 27 then '<a class="substr" title="' + Name + '">' + substring(Name,1,24) + '...' else Name end + '</td>' +
--           '<td>' + case
--                      when len (FileName) > 45 then
--                        '<a class="substr" title="' + FileName + '">' +
--                        substring(FileName,0,charindex('\',FileName,4)+1)+ '..\..' +
--                        reverse(substring(reverse(FileName),0,charindex('\',reverse(FileName))+1)) +
--                        '</a>'
--                      else FileName
--                    end + '</td>' +
--           '<td align="right">' + cast(cast(SizeKB/1024 as decimal(10,2)) as char) + '</td>' +
--           '<td align="right">' + cast(cast(UsedKB/1024 as decimal(10,2)) as char) + '</td>' +
--           '<td align="right">' + cast(cast(FreeKB/1024 as decimal(10,2)) as char) + '</td>' +
--           '<td align="right">' + case 
--                      when MaxSizeKB = -1 then 'Unlimited' 
--                      else cast(cast(MaxSizeKB*8/1024 as decimal(10,2)) as char)  
--                    end + '</td>' +
--           '<td align="center">' + cast(PctFree as char) + '</td>' +
--           '<td>' + case
--                      when (status & 0x100000) = 0x100000 then 'by ' + cast(growth as varchar(2)) + '%'
--                      when (status & 0x2) = 0x2 then 'by ' + cast(growth*8/1024 as varchar(100)) + 'MB'
--                      when (status & 0x40) = 0x40 then 'by ' + cast(growth*8/1024 as varchar(100)) + 'MB'
--                      else 'NULL'
--                    end + '</td></tr>'
--    from #space_info
--    order by DataBaseName

-- Generating sum information    
--    select '<tr><td><b>Sum of MDF files</b></td><td></td><td></td><td></td>' + 
--           '<td align="right"><b>'+ cast(cast(sum(SizeKB)/1024 as decimal(10,2)) as char)+'</b></td>' +
--           '<td align="right"><b>'+ cast(cast(sum(UsedKB)/1024 as decimal(10,2)) as char)+'</b></td>' +
--           '<td align="right"><b>'+ cast(cast(sum(FreeKB)/1024 as decimal(10,2)) as char)+'</b></td>' +
--           '<td></td></tr>' 
--    from #space_info
--    select '</table>'


