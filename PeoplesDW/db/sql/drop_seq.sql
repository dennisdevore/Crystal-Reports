--
-- $Id$
--
begin
   for s in (select * from user_sequences) loop
      execute immediate 'drop sequence ' || s.sequence_name;
   end loop;
end;
/
