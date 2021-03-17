create or replace TRIGGER ALPS.DOCAPTCHG
--
-- $Id$
--
AFTER INSERT OR UPDATE
ON ALPS.DOCAPPOINTMENTS
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
declare
out_msg varchar2(255);
begin
  if :new.loadno is not null and :new.loadno > 0 then
        zda.add_load_appointment(:new.loadno,:new.appointmentid,:new.starttime,:new.facility,:new.apttype,:new.lastuser,out_msg);
  end if;
  
 zda.update_order_appointment(:new.appointmentid,:new.starttime,:new.facility,:new.apttype,:new.lastuser,out_msg);


end;
/
exit;
