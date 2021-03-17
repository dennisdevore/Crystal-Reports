--
-- $Id$
--
-- This script is intended to update available plates
-- which actually have a non-null useritem1 column
set serveroutput on
declare
   cursor c_lp is
      select rowid, plate.*
         from plate
         where custid = '23300'
           and status = 'A'
           and type ='PA'
           and useritem1 is not null;
   selcnt integer := 0;
   updcnt integer := 0;
   msg varchar2(255);
begin
 	dbms_output.enable(1000000);

   for lp in c_lp loop
      selcnt := selcnt + 1;

      zbill.add_asof_inventory(lp.facility, lp.custid, lp.item, lp.lotnumber,
            lp.unitofmeasure, sysdate, -lp.quantity, -lp.weight, 'LotConvDec', 'AD',
            lp.inventoryclass, lp.invstatus, lp.orderid, lp.shipid, lp.lpid,
            'LOTCONV', msg);
      if (msg = 'OKAY') then
         zbill.add_asof_inventory(lp.facility, lp.custid, lp.item, lp.useritem1,
               lp.unitofmeasure, sysdate, lp.quantity, -lp.weight, 'LotConvInc', 'AD',
               lp.inventoryclass, lp.invstatus, lp.orderid, lp.shipid, lp.lpid,
               'LOTCONV', msg);
         if (msg = 'OKAY') then
            update plate
               set lotnumber = useritem1,
                   useritem1 = null,
                   lastupdate = sysdate,
                   lastuser = 'LOTCONV',
                   lasttask = 'LC'
               where rowid = lp.rowid;
            commit;
            updcnt := updcnt + 1;
         else
            rollback;
            dbms_output.put_line('Dec ' || lp.lpid || ': ' || msg);
         end if;
      else
         rollback;
         dbms_output.put_line('Inc ' || lp.lpid || ': ' || msg);
      end if;
   end loop;
  	dbms_output.put_line('Selected: ' || selcnt);
  	dbms_output.put_line('Updated: ' || updcnt);
end;
/
