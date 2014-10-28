exec sp_executesql @stmt=N'
                begin try
                if (select convert(int,value_in_use) from sys.configurations where name = ''default trace enabled'' ) = 1
                begin
                declare @curr_tracefilename varchar(500) ;
                declare @base_tracefilename varchar(500) ;
                declare @indx int ;

                select @curr_tracefilename = path from sys.traces where is_default = 1 ;
                set @curr_tracefilename = reverse(@curr_tracefilename);
                select @indx  = patindex(''%\%'', @curr_tracefilename) ;
                set @curr_tracefilename = reverse(@curr_tracefilename) ;
                set @base_tracefilename = left( @curr_tracefilename,len(@curr_tracefilename) - @indx) + ''\log.trc'' ;

                select  (dense_rank() over (order by StartTime desc))%2 as l1
                ,       convert(int, EventClass) as EventClass
                ,       DatabaseName
                ,       Filename
                ,       (Duration/1000) as Duration
                ,       StartTime
                ,       EndTime
                ,       (IntegerData*8.0/1024) as ChangeInSize
                from ::fn_trace_gettable( @base_tracefilename, default )
                left outer join sys.databases as d on (d.name = DB_NAME())
                where EventClass >=  92      and EventClass <=  95        and ServerName = @@servername   and DatabaseName = db_name()  and (d.create_date < EndTime)
                order by StartTime desc ;
                end     else
                select -1 as l1, 0 as EventClass, 0 DatabaseName, 0 as Filename, 0 as Duration, 0 as StartTime, 0 as EndTime,0 as ChangeInSize
                end try
                begin catch
                select -100 as l1
                ,       ERROR_NUMBER() as EventClass
                ,       ERROR_SEVERITY() DatabaseName
                ,       ERROR_STATE() as Filename
                ,       ERROR_MESSAGE() as Duration
                ,       1 as StartTime, 1 as EndTime,1 as ChangeInSize
                end catch
              ',@params=N''