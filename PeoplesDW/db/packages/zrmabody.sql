create or replace package body alps.rma as
--
-- $Id$
--


-- Public procedures


procedure get_next_rma(out_rma     out varchar2,
                       out_message out varchar2) is
   cnt integer := 1;
   wk_rma orderhdr.rma%type;
begin
   out_message := null;

   while (cnt = 1)
   loop
      select rmaseq.nextval
         into wk_rma
         from dual;
      select count(1)
         into cnt
         from orderhdr
         where rma = wk_rma;
   end loop;
   out_rma := wk_rma;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end get_next_rma;


procedure start_rf_return(io_rma          in out varchar2,
                          io_custid       in out varchar2,
                          io_orderid   	in out number,
                          io_shipid    	in out number,
                          out_rma_is_new  out varchar2,
                          out_loadno   	out number,
                          out_stopno   	out number,
                          out_shipno   	out number,
                          out_po       	out varchar2,
                          out_shipper     out varchar2,
                          out_error    	out varchar2,
                          out_message  	out varchar2) is
   cursor c_order is
      select rma, custid, loadno, stopno, shipno, po, ordertype, orderstatus,
             shipper
         from orderhdr
         where orderid = io_orderid
           and shipid = io_shipid;
   ord c_order%rowtype;
   cursor c_cust is
      select nvl(rmarequired, 'N') rmarequired
         from customer
         where custid = io_custid;
   cust c_cust%rowtype;
   cursor c_rma_cust is
      select orderid, shipid, custid, loadno, stopno, shipno, po, shipper,
             ordertype, orderstatus
         from orderhdr
         where rma = io_rma
           and custid = io_custid;
   cursor c_rma_no_cust is
      select orderid, shipid, custid, loadno, stopno, shipno, po, shipper,
             ordertype, orderstatus
         from orderhdr
         where rma = io_rma;
   rma c_rma_cust%rowtype;
   rowfound boolean := false;
   cnt integer;
   msg varchar(80);
begin
   out_rma_is_new := 'N';
   out_loadno := null;
   out_stopno := null;
   out_shipno := null;
   out_po := null;
   out_shipper := null;
   out_error := 'N';
   out_message := null;

-- called with an order, verify it
   if ((io_orderid != 0) and (io_shipid != 0)) then
      open c_order;
      fetch c_order into ord;
      rowfound := c_order%found;
      close c_order;
      if not rowfound then
         out_message := 'Order not found';
      elsif (ord.ordertype not in ('Q', 'V')) then
         out_message := 'Not a return';
      elsif (ord.orderstatus not in ('A','1')) then
         out_message := 'Not Arrived/Entered';
      else
         io_rma := ord.rma;
         io_custid := ord.custid;
         out_rma_is_new := 'N';
         out_loadno := ord.loadno;
         out_stopno := ord.stopno;
         out_shipno := ord.shipno;
         out_po := ord.po;
         out_shipper := ord.shipper;
      end if;
      return;
   end if;

-- no rma given, verify it and generate one
   if (io_rma is null) then
      open c_cust;
      fetch c_cust into cust;
      rowfound := c_cust%found;
      close c_cust;
      if not rowfound then
         out_message := 'Cust not found';
      elsif (cust.rmarequired = 'Y') then
         out_message := 'RMA required';
      else
         get_next_rma(io_rma, msg);
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
         else
            out_rma_is_new := 'Y';
         end if;
      end if;
      return;
   end if;

-- rma given, verify it
   if (io_custid is null) then
      select count(1) into cnt
         from orderhdr
         where rma = io_rma;
   else
      select count(1) into cnt
         from orderhdr
         where rma = io_rma
           and custid = io_custid;
   end if;

   if (cnt > 1) then
      out_message := 'Duplicate RMAs';
   elsif (cnt = 1) then
      if (io_custid is null) then
         open c_rma_no_cust;
         fetch c_rma_no_cust into rma;
         close c_rma_no_cust;
      else
         open c_rma_cust;
         fetch c_rma_cust into rma;
         close c_rma_cust;
      end if;

      if (rma.ordertype not in ('Q', 'V')) then
         out_message := 'Not a return';
      elsif (rma.orderstatus not in ('A','1')) then
         out_message := 'Not Arrived/Entered';
      else
         io_custid := rma.custid;
         io_orderid := rma.orderid;
         io_shipid := rma.shipid;
         out_rma_is_new := 'N';
         out_loadno := rma.loadno;
         out_stopno := rma.stopno;
         out_shipno := rma.shipno;
         out_po := rma.po;
         out_shipper := rma.shipper;
      end if;
   else
      out_rma_is_new := 'Y';
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end start_rf_return;


end rma;
/

show errors package body rma;
exit;
