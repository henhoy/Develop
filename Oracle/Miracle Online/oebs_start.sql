-----------------------------------------------------------------------------------------
-- Skal der køres OEBS tjek eller ej
-----------------------------------------------------------------------------------------

set serveroutput on
set verify off

variable o_oebs varchar2(100);
column oebs new_value o_oebs noprint

declare
  w_oebs varchar2(100);
  w_apps number;
begin  
  select count(*) into w_apps from all_users where username = 'APPS';
    
  select decode(w_apps,0,'nooebs_tjek.sql','oebs_tjek.sql') into w_oebs from dual;
  :o_oebs := lower(w_oebs);
  
  dbms_output.put_line('Vi koerer ' || w_oebs || ' og starter ' || w_oebs || '.sql');
  
end;
/

select :o_oebs oebs from dual;

--- KØR 

@&o_oebs 