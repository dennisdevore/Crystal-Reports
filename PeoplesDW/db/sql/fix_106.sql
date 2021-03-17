--
-- $Id$
--
set serveroutput on
declare
   cursor c_ad is
      select *
         from asofinventorydtl
         where facility = '106'
           and custid in ('6007','8560');
   msg varchar2(255);
   cnt integer := 0;
begin
   dbms_output.enable(1000000);

   for ad in c_ad loop
      cnt := cnt + 1;

      zbill.add_asof_inventory(ad.facility, ad.custid, ad.item, ad.lotnumber, ad.uom,
            ad.effdate, -ad.adjustment, -ad.weightadjustment, ad.reason, ad.trantype,
            ad.inventoryclass, ad.invstatus, ad.orderid, ad.shipid, ad.lpid, ad.lastuser, msg);

      if (msg != 'OKAY') then
         dbms_output.put_line('- results: ' || '<' || msg || '>');
      else
         zbill.add_asof_inventory('107', ad.custid, ad.item, ad.lotnumber, ad.uom,
               ad.effdate, ad.adjustment, ad.weightadjustment, ad.reason, ad.trantype,
               ad.inventoryclass, ad.invstatus, ad.orderid, ad.shipid, ad.lpid,
               ad.lastuser, msg);

         if (msg != 'OKAY') then
            dbms_output.put_line('+ results: ' || '<' || msg || '>');
         end if;
      end if;
   end loop;

   dbms_output.put_line('count = ' || cnt || ' ... no commit!!');
end;
/
