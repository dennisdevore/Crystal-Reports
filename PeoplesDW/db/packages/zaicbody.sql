create or replace package body alps.zaiconversion as
--
-- $Id$
--


-- Public procedures


procedure start_conversion
   (in_facility in varchar2,
    in_custid   in varchar2,
    in_user     in varchar2,
    out_error   out varchar2,
    out_message out varchar2)
is
   l_cnt pls_integer;
begin
   out_error := 'N';
   out_message := null;

   for oh in (select ordertype, count(1) as cnt
                from orderhdr
                where nvl(fromfacility,in_facility) = in_facility
                  and nvl(tofacility,in_facility) = in_facility
                  and custid = in_custid
                  and orderstatus not in ('0','1','9','R','X')
                group by ordertype) loop

      if oh.ordertype in ('R','Q','P','A','C','I') then
         out_message := 'Open receipts exist';
         return;
      end if;

      if oh.ordertype in ('O','V') then
         out_message := 'Open orders exist';
         return;
      end if;

      if oh.ordertype in ('T','U') then
         out_message := 'Open transfers exist';
         return;
      end if;
   end loop;

   select count(1) into l_cnt
      from plate
      where facility = in_facility
        and custid = in_custid
        and type = 'PA'
        and status not in ('A','P');
   if l_cnt != 0 then
      out_message := 'Transient LPs exist';
      return;
   end if;

   select count(1) into l_cnt
      from tasks
      where facility = in_facility
        and custid = in_custid;
   if l_cnt != 0 then
      out_message := 'Customer has tasks';
      return;
   end if;

   update plate
      set status = 'X',
          lastuser = in_user,
          lastupdate = sysdate
      where facility = in_facility
        and custid = in_custid
        and type = 'PA'
        and status = 'A';

   update plate
      set status = 'X',
          lastuser = in_user,
          lastupdate = sysdate
      where facility = in_facility
        and custid = in_custid
        and type = 'MP'
        and nvl(status,'A') = 'A';

   update customer
      set paperbased = 'N',
          lastuser = in_user,
          lastupdate = sysdate
      where custid = in_custid;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end start_conversion;


procedure convert_detail
   (in_facility  in varchar2,
    in_custid    in varchar2,
    in_location  in varchar2,
    in_item      in varchar2,
    in_lotno     in varchar2,
    in_orderid   in number,
    in_shipid    in number,
    in_created   in varchar2,
    in_invclass  in varchar2,
    in_invstatus in varchar2,
    in_lpcnt     in number,
    in_lpqty     in number,
    in_lpid      in varchar2,
    in_totqty    in number,
    in_adjust    in varchar2,
    in_user      in varchar2,
    out_error    out varchar2,
    out_msgno    out number,
    out_message  out varchar2)
is
   cursor c_lp is
      select rowid, plate.*
         from plate
         where facility = in_facility
           and location = in_location
           and custid = in_custid
           and item = in_item
           and nvl(lotnumber, '(none)') = nvl(in_lotno, '(none)')
           and nvl(orderid,0) = in_orderid
           and nvl(shipid,0) = in_shipid
           and nvl(invstatus,'??') = nvl(in_invstatus,'??')
           and nvl(inventoryclass,'??') = nvl(in_invclass,'??')
           and to_char(trunc(creationdate), 'MM/DD/YYYY') = in_created
           and type = 'PA'
           and status = 'X';
   lp c_lp%rowtype;
   l_qtyentered plate.qtyentered%type;
   l_weight plate.weight%type;
   l_found boolean;
   l_cnt integer := 0;
   l_err varchar2(1);
   l_msg varchar2(255);
   l_adjqty number := 0;
   l_newqty number;
   l_decrease boolean;
   l_adjrowid1 varchar2(20);
   l_adjrowid2 varchar2(20);
   l_errorno number;
   l_leaveqty number := 0;
   l_lpidpfx plate.lpid%type;
   l_lpidnum number(16);
   l_delim pls_integer;
begin
   out_error := 'N';
   out_message := null;

   open c_lp;
   fetch c_lp into lp;
   l_found := c_lp%found;
   close c_lp;

   if not l_found then
      out_message := 'No detail found';
      return;
   end if;

-- check the range of LPs - no arithmetic into alphas
   if in_lpcnt > 0 then
      l_delim := instr(translate(in_lpid, 'ABCDEFGHIJKLMNOPQRSTUVWXZY',
            '??????????????????????????'), '?', -1);
      if l_delim = 0 then
         l_lpidpfx := null;
         l_lpidnum := in_lpid;
      else
         l_lpidnum := substr(in_lpid, l_delim+1);
         if (length(l_lpidnum+in_lpcnt-1) > 15-l_delim) then
            out_message := 'Unusable 1st LP';
            return;
         end if;
         l_lpidpfx := substr(in_lpid, 1, l_delim);
      end if;
   end if;

-- build new plates
   while (l_cnt < in_lpcnt) loop

      if l_cnt = 0 then
         l_qtyentered := zlbl.uom_qty_conv(lp.custid, lp.item, in_lpqty, lp.unitofmeasure,
               lp.uomentered);
         l_weight := in_lpqty * zcwt.lp_item_weight(lp.lpid, lp.custid, lp.item, lp.unitofmeasure);
      end if;

      begin
         insert into plate
            (lpid,
             item,
             custid,
             facility,
             location,
             status,
             holdreason,
             unitofmeasure,
             quantity,
             type,
             serialnumber,
             lotnumber,
             creationdate,
             manufacturedate,
             expirationdate,
             expiryaction,
             lastcountdate,
             po,
             recmethod,
             condition,
             lastoperator,
             lasttask,
             fifodate,
             destlocation,
             destfacility,
             countryof,
             parentlpid,
             useritem1,
             useritem2,
             useritem3,
             disposition,
             lastuser,
             lastupdate,
             invstatus,
             qtyentered,
             itementered,
             uomentered,
             inventoryclass,
             loadno,
             stopno,
             shipno,
             orderid,
             shipid,
             weight,
             adjreason,
             qtyrcvd,
             controlnumber,
             qcdisposition,
             fromlpid,
             taskid,
             dropseq,
             fromshippinglpid,
             workorderseq,
             workordersubseq,
             qtytasked,
             childfacility,
             childitem,
             parentfacility,
             parentitem,
             prevlocation,
             anvdate)
         values
            (l_lpidpfx||lpad((l_lpidnum+l_cnt),15-l_delim,'0'),
             lp.item,
             lp.custid,
             lp.facility,
             lp.location,
             'A',
             lp.holdreason,
             lp.unitofmeasure,
             in_lpqty,
             lp.type,
             lp.serialnumber,
             lp.lotnumber,
             lp.creationdate,
             lp.manufacturedate,
             lp.expirationdate,
             lp.expiryaction,
             lp.lastcountdate,
             lp.po,
             lp.recmethod,
             lp.condition,
             in_user,
             'AI',
             lp.fifodate,
             null,
             null,
             lp.countryof,
             null,
             lp.useritem1,
             lp.useritem2,
             lp.useritem3,
             lp.disposition,
             in_user,
             sysdate,
             lp.invstatus,
             l_qtyentered,
             lp.itementered,
             lp.uomentered,
             lp.inventoryclass,
             lp.loadno,
             lp.stopno,
             lp.shipno,
             lp.orderid,
             lp.shipid,
             l_weight,
             lp.adjreason,
             in_lpqty,
             lp.controlnumber,
             lp.qcdisposition,
             lp.lpid,
             lp.taskid,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             lp.facility,
             lp.item,
             null,
             lp.anvdate);
      exception when DUP_VAL_ON_INDEX then
         out_message := 'LP #'|| to_char(l_cnt+1) || ' in use';
         return;
      end;

      l_cnt := l_cnt + 1;
   end loop;

-- cleanup old plates
   if in_adjust = 'Y' then
      l_adjqty := (in_lpcnt*in_lpqty) - in_totqty;
   elsif in_totqty > (in_lpcnt*in_lpqty) then
      l_leaveqty := in_totqty - (in_lpcnt*in_lpqty);
   end if;

   open c_lp;
   loop
      fetch c_lp into lp;
      exit when c_lp%notfound;

      l_decrease := true;
      if l_adjqty != 0 then
         update plate
            set status = 'A'                          -- so adjustment won't barf
            where rowid = lp.rowid;

         if l_adjqty > 0 then                         -- overage apply all at once
            l_newqty := lp.quantity + l_adjqty;
            l_adjqty := 0;
         elsif abs(l_adjqty) < lp.quantity then       -- last shortage
            l_newqty := lp.quantity - abs(l_adjqty);
            l_adjqty := 0;
         else                                         -- not (or only) last shortage
            l_newqty := 0;
            l_adjqty := l_adjqty + lp.quantity;
            l_decrease := false;                      -- adjustment will delete lp
         end if;

         zia.inventory_adjustment(lp.lpid, lp.custid, lp.item, lp.inventoryclass,
               lp.invstatus, lp.lotnumber, lp.serialnumber, lp.useritem1,
               lp.useritem2, lp.useritem3, lp.location, lp.expirationdate,
               l_newqty, lp.custid, lp.item, lp.inventoryclass, lp.invstatus,
               lp.lotnumber, lp.serialnumber, lp.useritem1, lp.useritem2,
               lp.useritem3, lp.location, lp.expirationdate, lp.quantity,
               lp.facility, 'SG', in_user, 'AI', l_newqty * lp.weight / lp.quantity,
               lp.weight, lp.manufacturedate, lp.manufacturedate,
               lp.anvdate, lp.anvdate,
               l_adjrowid1, l_adjrowid2, l_errorno, l_msg);
         if l_errorno != 0 then
            out_error := 'I';
            out_msgno := l_errorno;
            out_message := l_msg;
            exit;
         end if;

         lp.quantity := l_newqty;                     -- for zrf.decrease()

      elsif l_leaveqty > 0 then
         if lp.quantity > l_leaveqty then             -- only leave some of plate
            lp.quantity := lp.quantity - l_leaveqty;
            l_leaveqty := 0;
         else
            l_leaveqty := l_leaveqty - lp.quantity;   -- leave all of plate
            l_decrease := false;
         end if;
      end if;

      if l_decrease then
         zrf.decrease_lp(lp.lpid, lp.custid, lp.item, lp.quantity, lp.lotnumber,
               lp.unitofmeasure, in_user, 'AI', lp.invstatus, lp.inventoryclass, l_err, l_msg);
         if (l_err != 'N') or (l_msg is not null) then
            out_error := l_err;
            out_message := l_msg;
            exit;
         end if;
      end if;
   end loop;
   close c_lp;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end convert_detail;


end zaiconversion;
/

show errors package body zaiconversion;
exit;
