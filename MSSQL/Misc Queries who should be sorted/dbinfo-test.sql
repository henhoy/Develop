create table #temp  (
      Id INT IDENTITY(1,1),
      ParentObject VARCHAR(255),
      [Object] VARCHAR(255),
      Field VARCHAR(255),
      [Value] VARCHAR(255)
)

declare @stmt varchar(1000);
set @stmt = 'dbcc dbinfo with tableresults'
INSERT INTO #temp exec (@stmt);

select parentobject, object, field, value, count(*) from #temp group by parentobject, object, field, value having COUNT(*) > 1;

select field, count(*) from #temp group by field having COUNT(*) > 1;

--select * from #temp

drop table #temp;