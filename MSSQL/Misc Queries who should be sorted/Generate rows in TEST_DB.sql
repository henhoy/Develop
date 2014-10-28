/*
drop table frag_idx
create table frag_idx (id int, text varchar(20))
create index non_frag_idx on frag_idx (id)
*/

declare @count int;

set @count = 0

while @count < 1000
begin
  set @count = @count + 1;
  insert into frag_idx values ( @count, 'test ' + convert (varchar, @count) + ' test end t' )
end


-- select * from frag_idx order by id