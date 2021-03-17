create or replace trigger XchngIn_aiu
--
-- $Id$
--
after insert or update
on XchngIn
for each row
declare

send_queue varchar2(10) := 'pecas_in';
errno integer;
begin

    if :new.processed = 'N' then
        errno :=zqm.send(send_queue,to_char(:new.transmission));
    end if;
end xchngin_ziu;
/

exit;
