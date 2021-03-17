--
-- $Id$
--
accept p_orderid prompt 'Enter orderid: '
accept p_shipid prompt 'Enter shipid: '

declare
   cursor c_id is
      select rowid, invoice, custid, facility, lastuser
         from invoicedtl
         where orderid = &&p_orderid
           and shipid = &&p_shipid;
   errno number;
   msg varchar2(255);
   inv invoicedtl.invoice%type := 0;
begin
   dbms_output.enable(1000000);
   for id in c_id loop
      if nvl(id.invoice, 0) = 0 then
         if inv = 0 then
            zba.locate_accessorial_invoice(id.custid, id.facility, id.lastuser, inv,
                  errno, msg);
            if (errno != 0) then
               dbms_output.put_line('Locate error ' || msg);
               exit;
            end if;
         end if;
         update invoicedtl
            set invoice = inv
            where rowid = id.rowid;

         zba.calc_accessorial_invoice(inv, errno, msg);
         if (errno != 0) then
            dbms_output.put_line('Calc error ' || msg);
            exit;
         end if;
         dbms_output.put_line('Used invoice ' || inv);
      end if;
   end loop;
end;
/
