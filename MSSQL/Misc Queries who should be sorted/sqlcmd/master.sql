drop table tempdb.dbo.testhmh;
go

create table tempdb.dbo.testhmh(text varchar(80));
go

insert into tempdb.dbo.testhmh values ('Dette er en test');
go

--:r child.sql

set nocount on

:Out child.txt

select * from tempdb.dbo.testhmh;