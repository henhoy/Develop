-----------------------------------------------------------------------------------------
--  Find ud af hvilken version, hvilken database type (standby, normal) og 
--
--  Derefter start enten standby- eller normal tjek
--
-----------------------------------------------------------------------------------------

set pause off
set serveroutput on
set verify off

variable o_standby varchar2(100);
column standby new_value o_standby noprint

declare
  w_standby varchar2(100);
begin  
  select controlfile_type into w_standby from v$database;
    
  /* filen vi starter er enten check.sql eller check_standby.sql */
  select decode(w_standby,'CURRENT',NULL,'_' || w_standby) into w_standby from dual;
  :o_standby := lower(w_standby);
  
  dbms_output.put_line('Vi koerer ' || w_standby || ' og starter check2.' || w_standby || '.sql');
  
end;
/

select :o_standby standby from dual;

---------------------------------------------------------------
-- Hvilken form for tjek skal køres: normal eller standby
---------------------------------------------------------------

@check2&o_standby &1 &2

exit