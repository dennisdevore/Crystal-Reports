--
-- $Id$
--
set serveroutput on
declare
   cursor c_lp is
      select *
         from plate
         where facility = '107'
           and location = 'KITTING01';
   selcnt integer := 0;
   delcnt integer := 0;
   msg varchar2(255);
begin
 	dbms_output.enable(1000000);

   for lp in c_lp loop
      selcnt := selcnt + 1;
      zlp.plate_to_deletedplate(lp.lpid, 'KitFix', '', msg);
      if (msg is null) then
         zbill.add_asof_inventory(lp.facility, lp.custid, lp.item, lp.lotnumber,
               lp.unitofmeasure, sysdate, -lp.quantity, -lp.weight, 'KitIn', 'AD',
               lp.inventoryclass, lp.invstatus, lp.orderid, lp.shipid, lp.lpid,
               'KitFix', msg);
         if (msg = 'OKAY') then
            delcnt := delcnt + 1;
         else
  	         dbms_output.put_line('asof ' || lp.lpid || ': ' || msg);
         end if;
      else
         dbms_output.put_line('del ' || lp.lpid || ': ' || msg);
      end if;
   end loop;
  	dbms_output.put_line('Selected: ' || selcnt);
  	dbms_output.put_line('Deleted: ' || delcnt);
end;
/
