--
-- $Id$
--
set serveroutput on
set verify off
declare
   l_updflag varchar2(1);

   cursor c_ph(p_lpid varchar2) is
      select whenoccurred, quantity
         from platehistory
         where lpid = p_lpid
           and status = 'A'
           and quantity > 0
      union
      select sysdate as whenoccurred, quantity
         from plate
         where lpid = p_lpid
      order by whenoccurred;
   ph c_ph%rowtype := null;
begin

   l_updflag := upper('&&1');

   dbms_output.enable(1000000);
   for lp in (select lpid, custid, item, unitofmeasure, uomentered, qtyentered
               from plate
               where type = 'PA'
                 and qtyentered = 0) loop

      open c_ph(lp.lpid);
      fetch c_ph into ph;
      close c_ph;

      lp.qtyentered := zlbl.uom_qty_conv(lp.custid, lp.item, ph.quantity, lp.unitofmeasure,
            lp.uomentered);
--    if exact conversion use uomentered else unitofmeasure
      if ph.quantity != zlbl.uom_qty_conv(lp.custid, lp.item, lp.qtyentered, lp.uomentered,
            lp.unitofmeasure) then
         lp.qtyentered := ph.quantity;
         lp.uomentered := lp.unitofmeasure;
      end if;

      dbms_output.put_line(lp.lpid||' should be '||lp.qtyentered||' '||lp.uomentered);
      if l_updflag = 'Y' then
         update plate
            set qtyentered = lp.qtyentered,
                uomentered = lp.uomentered,
                lastuser = 'SYNAPSE',
                lastupdate = sysdate
            where lpid = lp.lpid;
      end if;
   end loop;
end;
/
