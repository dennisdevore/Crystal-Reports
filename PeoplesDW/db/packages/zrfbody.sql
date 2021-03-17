create or replace package body alps.rf as
--
-- $Id$
--


-- Types


type anylptype is record
   (lpid plate.lpid%type,
    quantity plate.quantity%type,
    weight plate.weight%type
   );
type anylpcur is ref cursor return anylptype;


-- Private procedures


procedure single_misc_charge
   (in_facility  in varchar2,
    in_orderid   in number,
    in_shipid    in number,
    in_ordertype in varchar2,
    in_activity  in varchar2,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_qty       in number,
    in_uom       in varchar2,
    in_loadno    in number,
    in_stopno    in number,
    in_shipno    in number,
    in_user      in varchar2,
    out_message  out varchar2)
is
   cursor c_invoice(p_orderid number) is
      select invoice
         from invoicehdr
         where custid = in_custid
           and invtype = 'M'
           and orderid = p_orderid
           and facility = in_facility;
   cursor c_orderid(p_invoice number) is
      select orderid
         from invoicehdr
         where invoice = p_invoice;
   l_found boolean;
   l_msg varchar2(80);
   invh invoicehdr%rowtype;
   l_orderid orderdtl.orderid%type := in_orderid;
   l_shipid orderdtl.shipid%type := in_shipid;
begin
   out_message := null;

   if nvl(l_orderid, 0) != 0 then
      if in_ordertype != 'M' then
         invh.invoice := 0;
      else
         open c_invoice(l_orderid);
         fetch c_invoice into invh.invoice;
         l_found := c_invoice%found;
         close c_invoice;

         if not l_found then
            if zbill.GOOD = zbill.get_invoicehdr('CREATE', zbill.IT_MISC, in_custid,
                  in_facility, in_user, invh) then
               update invoicehdr
                  set orderid = l_orderid
                  where invoice = invh.invoice;
            else
               out_message := 'get_invoicehdr error';
               return;
            end if;
         end if;
      end if;
   else
      zbill.start_misc_invoice(in_facility, in_custid, in_user, invh.invoice, l_msg);
      if l_msg != 'OKAY' then
         out_message := l_msg;
         return;
      end if;
      open c_orderid(invh.invoice);
      fetch c_orderid into l_orderid;
      close c_orderid;
      l_shipid := 1;
   end if;

   insert into invoicedtl
      (billstatus, facility, custid, item, activity, activitydate,
       enteredqty, entereduom, lastuser, lastupdate, orderid,
       loadno,
       stopno,
       shipno,
       shipid, statusrsn, invoice, invtype, enteredweight, businessevent)
   values
      ('0', in_facility, in_custid, in_item, in_activity, sysdate,
       in_qty, in_uom, in_user, sysdate, l_orderid,
       decode(in_loadno, 0, null, in_loadno),
       decode(in_stopno, 0, null, in_stopno),
       decode(in_shipno, 0, null, in_shipno),
       l_shipid, 'MISC', invh.invoice, 'M', 0, zbill.EV_RFMISC);

   if invh.invoice != 0 then
      zbill.calc_details(invh.invoice, in_user, l_msg);
      if l_msg != 'OKAY' then
         out_message := l_msg;
      end if;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end single_misc_charge;


procedure single_order_auto_charge
   (in_event    in varchar2,
    in_facility in varchar2,
    in_custid   in varchar2,
    in_orderid  in number,
    in_shipid   in number,
    in_po       in varchar2,
    in_loadno   in number,
    in_stopno   in number,
    in_shipno   in number,
    in_user     in varchar2,
    out_message out varchar2)
is
   cursor c_cust is
      select rategroup
         from customer
         where custid = in_custid;
   cust c_cust%rowtype;
   custfound boolean;
   cursor c_rate is
      select W.activity, W.billmethod, R.uom
         from custrategroup G, custactvfacilities F, custratewhen W, custrate R
         where rategrouptype(W.custid,W.rategroup)
                = zbut.rategroup(in_custid, cust.rategroup)
           and W.businessevent = in_event
           and W.automatic = 'A'
           and G.custid = W.custid
           and G.rategroup = W.rategroup
           and G.status = 'ACTV'
           and W.custid = F.custid (+)
           and W.activity = F.activity (+)
           and 0 < instr(','||nvl(F.facilities,in_facility)||',',
                  ','||in_facility||',')
           and W.effdate =
                  (select max(effdate)
                     from custrate
                        where custid = W.custid
                          and activity = W.activity
                          and billmethod = W.billmethod
                          and rategroup = W.rategroup
                          and effdate <= trunc(sysdate))
           and R.activity = W.activity
           and R.billmethod = W.billmethod
           and R.custid = W.custid
           and R.effdate = W.effdate
           and R.rategroup = W.rategroup;
   cursor c_order is
      select orderstatus, ordertype
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
   oh c_order%rowtype;
   ohfound boolean := false;
   errno number;
   msg varchar2(255);
   logmsg varchar2(255);
   inv_num invoicedtl.invoice%type := null;
   inv_type invoicedtl.invtype%type := 'A';
begin
   out_message := null;

   open c_cust;
   fetch c_cust into cust;
   custfound := c_cust%found;
   close c_cust;

   if not custfound then
      return;
   end if;

   if ((in_event = 'EMPT')
    or (in_event in ('RECH', 'RETH', 'RPUT') and (in_orderid != 0))) then
      inv_type := 'R';
   else
      if (in_orderid != 0) then
         open c_order;
         fetch c_order into oh;
         ohfound := c_order%found;
         close c_order;
      end if;

      if (oh.orderstatus = 'A') then
         inv_type := 'R';
      end if;
   end if;

   for w in c_rate loop
      if inv_num is null and inv_type = 'A' and
        ((not ohfound)
                or (oh.orderstatus in ('9', 'R', 'X'))
                or (oh.ordertype = 'W'))
      then
         out_message := 'OKAY';
         zba.locate_accessorial_invoice(in_custid, in_facility, in_user, inv_num, errno, msg);
         if (errno != 0) then
            zms.log_msg('CAUTO_CHARGE', in_facility, in_custid, msg, 'E', in_user, logmsg);
            return;
         end if;
      end if;

      out_message := 'OKAY';
      insert into invoicedtl
         (billstatus, facility, custid, orderid, item,
          lotnumber, activity, activitydate, po, lpid,
          enteredqty, entereduom, lastuser, lastupdate, loadno,
          stopno, shipno,
          billmethod, shipid, orderitem, orderlot, invoice, invtype, enteredweight, businessevent)
      values
         ('0', in_facility, in_custid, in_orderid, null,
          null, w.activity, sysdate, in_po, null,
          0, w.uom, in_user, sysdate, decode(in_loadno, 0, null, in_loadno),
          decode(in_stopno, 0, null, in_stopno), decode(in_shipno, 0, null, in_shipno),
          w.billmethod, in_shipid, null, null, inv_num, inv_type, 0, in_event);
   end loop;

   if (inv_num is not null) then
      out_message := 'OKAY';
      zba.calc_accessorial_invoice(inv_num, errno, msg);
      if (errno != 0) then
         zms.log_msg('CAUTO_CHARGE', in_facility, in_custid, msg, 'E', in_user, logmsg);
      end if;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end single_order_auto_charge;


procedure move_ctn_kids
   (in_ctnid     in varchar2,
    in_location  in varchar2,
    in_status    in varchar2,
    in_user      in varchar2,
    in_tasktype  in varchar2,
    out_message  out varchar2)
is
   cursor c_kids is
      select rowid, type, fromlpid
         from shippingplate
         where parentlpid = in_ctnid;
begin
   out_message := null;

   for k in c_kids loop
      update shippingplate
         set location = in_location,
             prevlocation = location,
             status = in_status,
             lastuser = in_user,
             lastupdate = sysdate
         where rowid = k.rowid;

      if ((k.type != 'P') and (k.fromlpid is not null)) then
         update plate
            set location = in_location,
                prevlocation = location,
                lasttask = in_tasktype,
                lastoperator = in_user,
                lastuser = in_user,
                lastupdate = sysdate
            where lpid = k.fromlpid
              and type != 'XP';
      end if;
   end loop;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end move_ctn_kids;


function is_expiration_in_past
   (in_expdate in varchar2,
    in_mfgdate in varchar2,
    in_custid  in varchar2,
    in_item    in varchar2)
return varchar2
is
   expires date;
   pastdate varchar2(1) := 'N';
begin
   select zrf.calc_expiration(in_expdate, in_mfgdate, I.shelflife)
      into expires
      from custitemview I
      where I.custid = in_custid
        and I.item = in_item;

   if trunc(expires) < trunc(sysdate) then
      pastdate := 'Y';
   end if;

   return pastdate;

exception
   when OTHERS then
      return 'N';
end is_expiration_in_past;


-- Public functions

procedure single_misc_charge
   (in_facility  in varchar2,
    in_orderid   in number,
    in_shipid    in number,
    in_ordertype in varchar2,
    in_activity  in varchar2,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_qty       in number,
    in_uom       in varchar2,
    in_loadno    in number,
    in_stopno    in number,
    in_shipno    in number,
    in_user      in varchar2,
    in_comment1  in clob,
    in_weight    in number,
    out_message  out varchar2,
    in_billmethod in varchar2 default null)
is
   cursor c_invoice(p_orderid number) is
      select invoice
         from invoicehdr
         where custid = in_custid
           and invtype = 'M'
           and orderid = p_orderid
           and facility = in_facility;
   cursor c_orderid(p_invoice number) is
      select orderid
         from invoicehdr
         where invoice = p_invoice;
   l_found boolean;
   l_msg varchar2(80);
   invh invoicehdr%rowtype;
   l_orderid orderdtl.orderid%type := in_orderid;
   l_shipid orderdtl.shipid%type := in_shipid;
begin
   out_message := null;

   if nvl(l_orderid, 0) != 0 then
      if in_ordertype != 'M' then
         invh.invoice := 0;
      else
         open c_invoice(l_orderid);
         fetch c_invoice into invh.invoice;
         l_found := c_invoice%found;
         close c_invoice;

         if not l_found then
            if zbill.GOOD = zbill.get_invoicehdr('CREATE', zbill.IT_MISC, in_custid,
                  in_facility, in_user, invh) then
               update invoicehdr
                  set orderid = l_orderid
                  where invoice = invh.invoice;
            else
               out_message := 'get_invoicehdr error';
               return;
            end if;
         end if;
      end if;
   else
      zbill.start_misc_invoice(in_facility, in_custid, in_user, invh.invoice, l_msg);
      if l_msg != 'OKAY' then
         out_message := l_msg;
         return;
      end if;
      open c_orderid(invh.invoice);
      fetch c_orderid into l_orderid;
      close c_orderid;
      l_shipid := 1;
   end if;

   insert into invoicedtl
      (billstatus, facility, custid, item, activity, activitydate,
       enteredqty, entereduom, lastuser, lastupdate, orderid,
       loadno,
       stopno,
       shipno,
       shipid, statusrsn, invoice, invtype, enteredweight,
       comment1,billmethod, businessevent)
   values
      ('0', in_facility, in_custid, in_item, in_activity, sysdate,
       in_qty, in_uom, in_user, sysdate, l_orderid,
       decode(in_loadno, 0, null, in_loadno),
       decode(in_stopno, 0, null, in_stopno),
       decode(in_shipno, 0, null, in_shipno),
       l_shipid, 'MISC', invh.invoice, 'M', in_weight,
       in_comment1,in_billmethod, zbill.EV_RFMISC);

   if invh.invoice != 0 then
      zbill.calc_details(invh.invoice, in_user, l_msg);
      if l_msg != 'OKAY' then
         out_message := l_msg;
      end if;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end single_misc_charge;

function xlate_fromlpid
   (fromlp in varchar2,
    mylp   in varchar2)
return varchar2
is
   cursor c_from is
      select fromlpid
         from shippingplate
         where parentlpid = mylp
           and type = 'F';
   cursor c_lp is
      select lpid, type
         from plate
         where parentlpid = mylp;
   lp c_lp%rowtype;
   flip shippingplate.fromlpid%type := fromlp;
begin
   if (fromlp is null) then
      open c_from;
      fetch c_from into flip;
      if c_from%notfound then
         flip := mylp;
      end if;
      close c_from;
   else
      open c_lp;
      fetch c_lp into lp;
      if (c_lp%found) and (lp.type = 'XP') then
         flip := lp.lpid;
      end if;
      close c_lp;
   end if;
   return flip;
end xlate_fromlpid;


function calc_expiration
   (expires       in varchar2,
    manufactured  in varchar2,
    shelflife     in number)
return date
is
begin
   if ((expires is not null) or (shelflife = 0)) then
      return to_date(expires, 'MM/DD/RRRR');
   end if;

   if (manufactured is not null) then
      return to_date(manufactured, 'MM/DD/RRRR') + shelflife;
   end if;

   return trunc(sysdate) + shelflife;
end calc_expiration;


function is_location_physical
   (in_facility in varchar2,
    in_location in varchar2)
return varchar2
is
   cnt pls_integer;
begin

   select count(1) into cnt
      from location
      where facility = in_facility
        and locid = in_location;

   if (cnt != 0) then
      select count(1) into cnt
         from userheader
         where nameid = in_location;

      if (cnt = 0) then
         return 'Y';
      end if;
   end if;

   return 'N';

exception
   when OTHERS then
      return 'N';
end is_location_physical;


function is_plate_passed
   (in_lpid   in varchar2,
    in_lptype in varchar2)
return number
is
   cnt number := 0;
begin
   if (in_lptype in ('C', 'F', 'M', 'P')) then
      select count(1) into cnt
         from tasks
         where taskid in (select taskid from shippingplate
                           where status = 'S'
                             and dropseq < 0
                           start with lpid = in_lpid
                           connect by prior lpid = parentlpid)
           and priority = '8';
   else
      select count(1) into cnt
         from tasks
         where taskid in (select taskid from plate
                           where status = 'P'
                             and dropseq < 0
                           start with lpid = in_lpid
                           connect by prior lpid = parentlpid)
           and priority = '8';
      if (cnt = 0) then
         select count(1) into cnt
            from plate P, shippingplate S, tasks T
            where P.lpid = in_lpid
              and P.status = 'P'
              and S.fromlpid = P.lpid
              and S.status = 'S'
              and S.dropseq < 0
              and T.taskid = S.taskid
              and T.priority = '8';
      end if;
   end if;

   return cnt;

exception
   when OTHERS then
      return 0;
end is_plate_passed;


function last_nonsu_invstatus
   (in_lpid in varchar2)
return varchar2
is
   cursor c_ph is
      select invstatus
         from platehistory
         where lpid = in_lpid
           and invstatus != 'SU'
         order by whenoccurred desc;
   ph c_ph%rowtype;
begin
   open c_ph;
   fetch c_ph into ph;
   if c_ph%notfound then
      ph.invstatus := 'AV';
   end if;
   close c_ph;
   return ph.invstatus;

exception
   when OTHERS then
      return 'AV';
end last_nonsu_invstatus;


function any_tasks_for_lp
   (in_lpid       in varchar2,
    in_parentlpid in varchar2)
return boolean
is
   cnt pls_integer;
begin

   select count(1) into cnt
      from tasks
      where lpid in
         (select lpid from plate
            start with lpid = in_lpid
            connect by prior lpid = parentlpid);

   if cnt != 0 then
      return true;      -- lp or child has a task
   end if;

   select count(1) into cnt
      from subtasks
      where lpid in
         (select lpid from plate
            start with lpid = in_lpid
            connect by prior lpid = parentlpid);

   if cnt != 0 then
      return true;      -- lp or child has a subtask
   end if;

   if in_parentlpid is null then
      return false;     -- no parent implies no tasks; siblings do not count
   end if;

   select count(1) into cnt
      from tasks
      where lpid = in_parentlpid;

   if cnt != 0 then
      return true;      -- parent has a task
   end if;

   select count(1) into cnt
      from subtasks
      where lpid = in_parentlpid;

   if cnt != 0 then
      return true;      -- parent has a subtask
   end if;

   return false;

exception
   when OTHERS then
      return FALSE;
end any_tasks_for_lp;


function virtual_lpid
   (in_lpid in varchar2)
return varchar2
is
   cursor c_lp(p_lpid varchar2) is
      select LP.type as lptype,
             LP.parentlpid as mplpid,
             LP.virtuallp as lpvirtual,
             MP.type as mptype,
             MP.virtuallp as mpvirtual
         from plate LP, plate MP
         where LP.lpid = p_lpid
           and MP.lpid (+) = LP.parentlpid;
   lp c_lp%rowtype := null;
   l_lpid plate.lpid%type:= null;
begin
   open c_lp(in_lpid);
   fetch c_lp into lp;
   close c_lp;

   if (nvl(lp.lptype,'x') = 'MP') and (nvl(lp.lpvirtual,'N') = 'Y') then
      l_lpid := in_lpid;
   elsif (nvl(lp.mptype,'x') = 'MP') and (nvl(lp.mpvirtual,'N') = 'Y') then
      l_lpid := lp.mplpid;
   end if;

   return l_lpid;

exception
   when OTHERS then
      return null;
end virtual_lpid;


-- Public procedures


procedure move_shippingplate
   (in_rowid     in rowid,
    in_location  in varchar2,
    in_status    in varchar2,
    in_user      in varchar2,
    in_tasktype  in varchar2,
    out_message  out varchar2)
is
   stype shippingplate.type%type;
   fromlp shippingplate.fromlpid%type;
   slip shippingplate.lpid%type;
   mshp_status multishipdtl.status%type := 'unknown';
   new_status shippingplate.status%type;
   msg varchar2(80);
   cursor c_kids (mlip varchar2) is
      select rowid, lpid, type, fromlpid
         from shippingplate
         where parentlpid = mlip;
begin
   out_message := null;

   select fromlpid into slip
     from shippingplate
   where rowid = in_rowid;

   for mshp in (select status
            from multishipdtl
            where cartonid = slip)
   loop
    mshp_status := mshp.status;
   end loop;

   new_status := in_status;
   if mshp_status in ('SHIPPED','PROCESSED','INPROCESS') then
    new_status := 'SH';
   end if;

   update shippingplate
      set location = in_location,
          prevlocation = location,
          status = new_status,
          lastuser = in_user,
          lastupdate = sysdate
      where rowid = in_rowid
      returning lpid, type, fromlpid into slip, stype, fromlp;

   if ((stype != 'P') and (fromlp is not null)) then
      update plate
         set location = in_location,
             prevlocation = location,
             lasttask = in_tasktype,
             lastoperator = in_user,
             lastuser = in_user,
             lastupdate = sysdate
         where lpid in (select lpid from plate
                           start with lpid = fromlp
                           connect by prior lpid = parentlpid)
           and type != 'XP';
   end if;

   if (stype = 'C') then
      move_ctn_kids(slip, in_location, new_status, in_user, in_tasktype, msg);
      out_message := msg;

   elsif (stype = 'M') then
      for k in c_kids(slip) loop
         update shippingplate
            set location = in_location,
                prevlocation = location,
                status = new_status,
                lastuser = in_user,
                lastupdate = sysdate
            where rowid = k.rowid;

         if (k.type = 'C') then
            if (k.fromlpid is not null) then
               update plate
                  set location = in_location,
                      prevlocation = location,
                      lasttask = in_tasktype,
                      lastoperator = in_user,
                      lastuser = in_user,
                      lastupdate = sysdate
                  where lpid in (select lpid from plate
                                    start with lpid = k.fromlpid
                                    connect by prior lpid = parentlpid)
                    and type != 'XP';
            end if;
            move_ctn_kids(k.lpid, in_location, new_status, in_user, in_tasktype, msg);
            if (msg is not null) then
               out_message := msg;
               return;
            end if;

         elsif (k.type = 'F') then
            update plate
               set location = in_location,
                   prevlocation = location,
                   lastoperator = in_user,
                   lastuser = in_user,
                   lastupdate = sysdate
               where lpid in (select lpid from plate
                                 start with lpid = k.fromlpid
                                 connect by prior lpid = parentlpid)
                 and type != 'XP';
         end if;
      end loop;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end move_shippingplate;


procedure get_next_lpid
   (out_lpid    out varchar2,
    out_message out varchar2)
is
   cnt integer := 1;
   wk_lpid plate.lpid%type;
begin
   out_message := null;

   while (cnt >= 1)
   loop
      select lpad(lpidseq.nextval, 15, '0')
         into wk_lpid
         from dual;
      select count(1)
         into cnt
         from plate
         where lpid = wk_lpid;
      if (cnt = 0) then
         select count(1)
            into cnt
            from deletedplate
            where lpid = wk_lpid;
        if (cnt = 0) then
         select count(1)
            into cnt
            from multishipdtl
            where cartonid = wk_lpid;
         if (cnt = 0) then
          select count(1)
            into cnt
            from shippingplate
            where fromlpid = wk_lpid;
         end if;
        end if;
      end if;
   end loop;
   out_lpid := wk_lpid;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end get_next_lpid;


procedure verify_location
   (in_facility     in varchar2,
    in_location     in varchar2,
    in_equipment    in varchar2,
    out_loc_status  out varchar2,
    out_loc_type    out varchar2,
    out_check_id    out varchar2,
    out_error       out varchar2,
    out_message     out varchar2)
is
   loc_eqprof location.equipprof%type;
   cnt integer;
begin
   out_error := 'N';
   out_message := null;

   begin
      select rtrim(equipprof), rtrim(status),
             rtrim(checkdigit), rtrim(loctype)
         into loc_eqprof, out_loc_status,
              out_check_id, out_loc_type
         from location
         where facility = in_facility
           and locid = in_location;
   exception
      when NO_DATA_FOUND then
         out_message := 'Loc not in fac';
         return;
   end;

   if ((loc_eqprof is not null) and (in_equipment is not null)) then
      select count(1)
         into cnt
         from equipprofequip
         where profid = loc_eqprof
           and equipid = in_equipment;

      if (cnt = 0) then
         out_message := 'Equ not for loc';
         return;
      end if;
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end verify_location;


procedure verify_super_axs
   (in_user     in varchar2,
    in_pword    in varchar2,
    in_form     in varchar2,
    in_facility in varchar2,
    out_error   out varchar2,
    out_message out varchar2)
is
   cursor c_usr(p_user varchar2) is
      select blendedpword, groupid, userstatus
         from userheader
         where nameid = p_user;
   usr c_usr%rowtype;
   l_found boolean;
   l_axs userdetail.setting%type;
begin
   out_error := 'N';
   out_message := null;

   open c_usr(in_user);
   fetch c_usr into usr;
   l_found := c_usr%found;
   close c_usr;

   if not l_found then
      out_message := 'Invalid login';
      return;
   end if;

   if usr.userstatus != 'A' then
      out_message := 'Invalid login';
      return;
   end if;

   if zus.blenderize_user(in_user, in_pword) != usr.blendedpword then
      out_message := 'Invalid login';
      return;
   end if;

   if (usr.groupid = 'SUPER') then
    return;
   end if;

-- try name and facility
   begin
      select nvl(setting, 'ACCESSDENIED')
         into l_axs
         from userdetail
         where nameid = in_user
           and formid = in_form
           and facility = in_facility;
   exception
      when NO_DATA_FOUND then
         l_axs := 'x';
   end;

   if l_axs = 'SUPERVISOR' then
      return;
   end if;

   if l_axs != 'x' then
      out_message := 'No supervisor access';
      return;
   end if;

-- try name and null facility
   begin
      select nvl(setting, 'ACCESSDENIED')
         into l_axs
         from userdetail
         where nameid = in_user
           and formid = in_form
           and facility is null;
   exception
      when NO_DATA_FOUND then
         l_axs := 'x';
   end;

   if l_axs = 'SUPERVISOR' then
      return;
   end if;

   if l_axs != 'x' then
      out_message := 'No supervisor access';
      return;
   end if;

-- try group and facility
   begin
      select nvl(setting, 'ACCESSDENIED')
         into l_axs
         from userdetail
         where nameid = usr.groupid
           and formid = in_form
           and facility = in_facility;
   exception
      when NO_DATA_FOUND then
         l_axs := 'x';
   end;

   if l_axs = 'SUPERVISOR' then
      return;
   end if;

   if l_axs != 'x' then
      out_message := 'No supervisor access';
      return;
   end if;

-- try group and null facility
   begin
      select nvl(setting, 'ACCESSDENIED')
         into l_axs
         from userdetail
         where nameid = usr.groupid
           and formid = in_form
           and facility is null;
   exception
      when NO_DATA_FOUND then
         l_axs := 'ACCESSDENIED';
   end;

   if l_axs != 'SUPERVISOR' then
      out_message := 'No supervisor access';
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end verify_super_axs;


procedure verify_custitem
   (in_custid        in varchar2,
    in_item          in varchar2,
    out_item         out varchar2,
    out_baseuom      out varchar2,
    out_expiryact    out varchar2,
    out_recinvsts    out varchar2,
    out_weight       out number,
    out_cube         out number,
    out_amt          out number,
    out_shelflife    out number,
    out_parsefield   out varchar2,
    out_parseruleid  out varchar2,
    out_error        out varchar2,
    out_message      out varchar2)
is
   item_status custitem.status%type;
   real_item custitem.item%type;
begin
   out_error := 'N';
   out_message := null;

   begin
      select item, status, baseuom, expiryaction, recvinvstatus,
             zci.item_weight(in_custid, item, baseuom),
             zci.item_cube(in_custid, item, baseuom), useramt1, shelflife,
             decode(nvl(parseruleaction, 'N'), 'Y', upper(parseentryfield)),
             decode(nvl(parseruleaction, 'N'), 'Y', upper(parseruleid))
         into out_item, item_status, out_baseuom, out_expiryact, out_recinvsts,
              out_weight,
              out_cube, out_amt, out_shelflife,
              out_parsefield,
              out_parseruleid
         from custitemview
         where custid = in_custid
           and item = in_item;
   exception
      when NO_DATA_FOUND then
         item_status := null;
   end;

   if (item_status is null) then
      begin
         select zci.item_code(in_custid, in_item)
            into real_item
            from dual;
         if (real_item = 'Unknown') then
            out_message := 'Unknown item';
            return;
         end if;
      exception
         when NO_DATA_FOUND then
            out_message := 'Unknown item';
            return;
      end;

      begin
         select item, status, baseuom, expiryaction, recvinvstatus,
                zci.item_weight(in_custid, item, baseuom),
                zci.item_cube(in_custid, item, baseuom), useramt1, shelflife,
                decode(nvl(parseruleaction, 'N'), 'Y', upper(parseentryfield)),
                decode(nvl(parseruleaction, 'N'), 'Y', upper(parseruleid))
            into out_item, item_status, out_baseuom, out_expiryact, out_recinvsts,
                 out_weight,
                 out_cube, out_amt, out_shelflife,
                 out_parsefield,
                 out_parseruleid
            from custitemview
            where custid = in_custid
              and item = real_item;
      exception
         when NO_DATA_FOUND then
            out_message := 'Unknown item';
            return;
      end;
   end if;

   if item_status = 'PEND' then
      out_message := 'Item pending';
   elsif item_status != 'ACTV' then
      out_message := 'Item not active';
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end verify_custitem;


procedure start_receiving
   (in_facility  in varchar2,
    in_location  in varchar2,
    in_equipment in varchar2,
    in_loadno    in number,
    in_try_bulk  in varchar2,
    in_opmode    in varchar2,
    out_loadno   out number,
    out_po       out varchar2,
    out_custid   out varchar2,
    out_custname out varchar2,
    out_is_dock  out varchar2,
    out_has_xfer out varchar2,
    out_error    out varchar2,
    out_message  out varchar2)
is
   cursor c_door is
      select loadno
         from door
         where facility = in_facility
           and doorloc = in_location;
   ldno loads.loadno%type;
   cursor c_order is
      select O.po as po, O.custid as custid,
             substr(nvl(C.lookup, C.name),1,20) as cname,
             O.ordertype as ordertype
         from orderhdr O, customer C
         where O.loadno = ldno
           and O.orderstatus = 'A'
           and O.ordertype in ('R', 'T', 'C')
           and C.custid = O.custid;
   fo c_order%rowtype;
   cursor c_load is
      select loadstatus, loadtype
         from loads
         where loadno = ldno;
   l c_load%rowtype;
   dockfound boolean;
   loadfound boolean;
   cnt integer;
   err varchar2(1);
   msg varchar2(80);
   locstatus location.status%type;
   loctype location.loctype%type;
   checkid location.checkdigit%type;
   trans_order_cnt integer;
begin
   out_error := 'N';
   out_message := null;

   zrf.verify_location(in_facility, in_location, in_equipment, locstatus, loctype,
         checkid, err, msg);
   if (err != 'N') then
      out_error := err;
      out_message := msg;
      return;
   end if;
   if (msg is not null) then
      out_message := msg;
      return;
   end if;

-- try for a dock door first
   open c_door;
   fetch c_door into ldno;
   dockfound := c_door%found;
   close c_door;

   if dockfound then
      out_is_dock := 'Y';
      if ((in_loadno != 0) and (in_loadno != ldno)) then
         out_message := 'Load not at loc';
         return;
      end if;
   else
      out_is_dock := 'N';
      if (in_try_bulk != 'Y') then
         out_message := 'No loads at loc';
         return;
      end if;

--    try for the staging location of a bulk receipt
      if (in_loadno = 0) then
         select count(distinct loadno) into cnt
            from plate
            where facility = in_facility
              and location = in_location
              and item = ZUNK.UNK_RCPT_ITEM;
         if (cnt = 0) then
            out_message := 'No loads at loc';
            return;
         elsif (cnt > 1) then
            out_message := 'Load # needed';
            return;
         else
            select loadno into ldno
               from plate
               where facility = in_facility
                 and location = in_location
                 and item = ZUNK.UNK_RCPT_ITEM
                 and rownum = 1;
         end if;
      else
         select count(1) into cnt
            from plate
            where facility = in_facility
              and location = in_location
              and item = ZUNK.UNK_RCPT_ITEM
              and loadno = in_loadno;
         if (cnt = 0) then
            out_message := 'Load not at loc';
            return;
         end if;
         ldno := in_loadno;
      end if;
   end if;

   open c_load;
   fetch c_load into l;
   loadfound := c_load%found;
   close c_load;

   if not loadfound then
      out_message := 'Load not found';
      return;
   end if;

   if (substr(l.loadtype, 1, 1) != 'I') then
      out_message := 'Not inbound';
      return;
   end if;

   if ((l.loadstatus != 'A') and (l.loadstatus != 'E' or dockfound)) then
      out_message := 'Not arrived';
      return;
   end if;

   cnt := 0;
   trans_order_cnt := 0;
   for o in c_order loop
      cnt := cnt + 1;
      if (o.ordertype = 'C') then
         trans_order_cnt := trans_order_cnt + 1;
      end if;
      if (c_order%rowcount = 1) then
         fo := o;
      else
         if (o.custid != fo.custid) then
            fo.custid := null;
            fo.cname := '(mixed)';
         end if;

         if (nvl(o.po, 'x') != nvl(fo.po, 'x')) then
            fo.po := null;
         end if;

         if (o.ordertype = 'T') then
            fo.ordertype := o.ordertype;
         end if;
      end if;
   end loop;

   if (cnt = 0) then
      out_message := 'No rcpt at loc';
   else
      if  (trans_order_cnt > 0 and
           nvl(in_opmode,'O') != 'O')then
         out_message := 'Trns Ords req O opmd';
   else
      out_loadno := ldno;
      out_custid := fo.custid;
      out_custname := fo.cname;
      out_po := fo.po;
      if (fo.ordertype = 'T') then
         out_has_xfer := 'Y';
      else
         out_has_xfer := 'N';
      end if;
   end if;
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end start_receiving;


procedure get_baseuom_factor
   (in_custid  in varchar2,
    in_item      in varchar2,
    in_baseuom   in varchar2,
    in_touom     in varchar2,
    io_factor    in out number,
    out_error    out varchar2,
    out_message  out varchar2)
is
   loopcount integer := 0;
   cur_uom custitemuom.touom%type := in_touom;
   cursor c_equom (uom varchar2) is
      select fromuom, qty
         from custitemuom
         where custid = in_custid
           and item = in_item
           and touom = uom;
   e c_equom%rowtype;
begin
   io_factor := 1;
   out_error := 'N';
   out_message := null;

   while cur_uom != in_baseuom
   loop
      if loopcount > 256 then
         out_message := 'No path to buom';
         return;
      end if;
      open c_equom(cur_uom);
      fetch c_equom into e;
      if c_equom%notfound then
         close c_equom;
         out_message := 'No path to buom';
         return;
      end if;
      close c_equom;
      cur_uom := e.fromuom;
      io_factor := io_factor * e.qty;
      loopcount := loopcount + 1;
   end loop;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end get_baseuom_factor;


procedure mark_dock_empty
   (in_dockdoor   in varchar2,
    in_facility   in varchar2,
    in_equipment  in varchar2,
    in_user       in varchar2,
    in_loadno     in number,
    in_nosetemp   in number,
    in_middletemp in number,
    in_tailtemp   in number,
    out_error     out varchar2,
    out_message   out varchar2)
is
   ldno number;
   ldtype loads.loadtype%type;
   ldstatus loads.loadstatus%type;
   ldtrailer loads.trailer%type;
   ldcarrier loads.carrier%type;
   err varchar2(1);
   msg varchar2(80);
   locstatus location.status%type;
   loctype location.loctype%type;
   checkid location.checkdigit%type;
   cnt pls_integer;
begin
   out_error := 'N';
   out_message := null;

   zrf.verify_location(in_facility, in_dockdoor, in_equipment, locstatus, loctype,
         checkid, err, msg);
   if (err != 'N') then
      out_error := err;
      out_message := msg;
      return;
   end if;
   if (msg is not null) then
      out_message := msg;
      return;
   end if;

   begin
      select loadno
         into ldno
         from door
         where facility = in_facility
           and doorloc = in_dockdoor;
   exception
      when NO_DATA_FOUND then
         out_message := 'No load at door';
         return;
   end;

   if (in_loadno != -1 and in_loadno != ldno) then
      out_message := 'Load not here';
      return;
   end if;

   begin
      select loadstatus, loadtype, trailer, carrier
         into ldstatus, ldtype, ldtrailer, ldcarrier
         from loads
         where loadno = ldno;
   exception
      when NO_DATA_FOUND then
         out_message := 'Load not found';
         return;
   end;

   if (substr(ldtype, 1, 1) != 'I') then
      out_message := 'Not inbound';
      return;
   end if;

   if (ldstatus != 'A') then
      out_message := 'Not arrived';
      return;
   end if;

   select count(1) into cnt
      from plate
      where loadno = ldno
        and status = 'U'
        and zlbl.is_lp_unprocessed_autogen(lpid) = 'N'
        and item != 'UNKNOWN';
   if cnt != 0 then
      out_message := 'LPs being received';
      return;
   end if;

   for oh in (select OH.rowid from orderhdr OH, customer CU
                  where OH.loadno = ldno
                    and CU.custid = OH.custid
                    and nvl(CU.tracktrailertemps,'N') = 'Y') loop
      update orderhdr
         set trailernosetemp = in_nosetemp,
             trailermiddletemp = in_middletemp,
             trailertailtemp = in_tailtemp,
             lastuser = in_user,
             lastupdate = sysdate
         where rowid = oh.rowid;
   end loop;

   update loads
      set loadstatus = 'E',
          lastuser = in_user,
          lastupdate = sysdate
      where loadno = ldno;

   begin
      update trailer
         set contents_status = 'E',
             activity_type = 'EPT'
       where carrier = ldcarrier
         and trailer_number = ldtrailer
         and loadno = ldno;
   exception when others then
      null;
   end;


exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end mark_dock_empty;


procedure verify_facility
   (in_facility     in varchar2,
    in_user         in varchar2,
    out_usecheckids out varchar2,
    out_error       out varchar2,
    out_message     out varchar2)
is
   cnt integer;
   facsts facility.facilitystatus%type;
   ufacility userheader.facility%type;
   ugroupid userheader.groupid%type;
   uchangefac userheader.chgfacility%type;
begin
   out_error := 'N';
   out_message := null;
   out_usecheckids := 'Y';

   begin
      select facility, groupid, upper(chgfacility)
         into ufacility, ugroupid, uchangefac
         from userheader
         where nameid = in_user;
   exception
      when NO_DATA_FOUND then
         out_message := 'User not found';
         return;
   end;

   if (uchangefac = 'S') then
      select count(1) into cnt
         from userfacility
         where nameid = in_user
           and facility = in_facility;
      if (cnt = 0) then
         select count(1) into cnt
            from userfacility
            where nameid = ugroupid
              and facility = in_facility;
         if (cnt = 0) then
            out_message := 'Unapproved fac';
            return;
         end if;
      end if;
   elsif (uchangefac = 'A') then
      select count(1) into cnt
         from facility
         where facility = in_facility;
      if (cnt = 0) then
         out_message := 'Unknown fac';
         return;
      end if;
   elsif (in_facility != ufacility) then
      out_message := 'Unapproved fac';
      return;
   end if;

   begin
      select facilitystatus, nvl(use_location_checkdigit, 'Y')
         into facsts, out_usecheckids
         from facility
         where facility = in_facility;
   exception
      when NO_DATA_FOUND then
         out_message := 'Unknown fac';
         return;
   end;

   if (facsts != 'A') then
      out_message := 'Fac not active';
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end verify_facility;


procedure verify_customer
   (in_custid    in varchar2,
    in_user      in varchar2,
    out_error    out varchar2,
    out_message  out varchar2)
is
   cnt integer;
   custsts customer.status%type;
   ugroupid userheader.groupid%type;
   uallcusts userheader.allcusts%type;
   paper customer.paperbased%type;
begin
   out_error := 'N';
   out_message := null;

   begin
      select groupid, upper(allcusts)
         into ugroupid, uallcusts
         from userheader
         where nameid = in_user;
   exception
      when NO_DATA_FOUND then
         out_message := 'User not found';
         return;
   end;

   if (uallcusts = 'S') then
      select count(1) into cnt
         from usercustomer
         where nameid = in_user
           and custid = in_custid;
      if (cnt = 0) then
         select count(1) into cnt
            from usercustomer
            where nameid = ugroupid
              and custid = in_custid;
         if (cnt = 0) then
            out_message := 'Unapproved cust';
            return;
         end if;
      end if;
   elsif (uallcusts = 'A') then
      select count(1) into cnt
         from customer
         where custid = in_custid;
      if (cnt = 0) then
         out_message := 'Unknown cust';
         return;
      end if;
   end if;

   begin
      select status, paperbased
         into custsts, paper
         from customer
         where custid = in_custid;
   exception
      when NO_DATA_FOUND then
         out_message := 'Unknown cust';
         return;
   end;

   if (custsts != 'ACTV') then
      out_message := 'Cust not active';
   end if;

   if (paper = 'Y') then
      out_message := 'Cust uses Aggreg Inv';
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end verify_customer;


procedure bind_lp_to_user
   (in_lpid      in varchar2,
    in_facility  in varchar2,
    in_custid    in varchar2,
    in_user      in varchar2,
    in_equipment in varchar2,
    in_tasktype  in varchar2,
    in_shipok    in varchar2,
    out_error    out varchar2,
    out_message  out varchar2,
    out_facility out varchar2,
    out_location out varchar2,
    out_status   out varchar2,
    out_item     out varchar2,
    out_custid   out varchar2,
    out_rowid    out varchar2,
    out_wasship  out varchar2,
    out_lpid     out varchar2,
    out_lptype   out varchar2)
is
   cursor c_lp (p_lpid varchar2) is
      select item, custid, facility, location, status, rowid
         from plate
         where lpid = p_lpid;
   lp c_lp%rowtype;
   cursor c_ship (p_spid varchar2) is
      select item, custid, facility, location, status, rowid
         from shippingplate
         where lpid = p_spid;
   cursor c_work (p_lpid varchar2) is
      select tasktype
         from tasks
         where lpid in
            (select lpid from plate
               start with lpid = p_lpid
               connect by prior lpid = parentlpid)
      union
      select tasktype
         from subtasks
         where lpid in
            (select lpid from plate
               start with lpid = p_lpid
               connect by prior lpid = parentlpid);
   w c_work%rowtype;
   wfound boolean;
   lptype plate.type%type;
   xrefid plate.lpid%type;
   xreftype plate.type%type;
   parentid plate.lpid%type;
   parenttype plate.type%type;
   topid plate.lpid%type;
   toptype plate.type%type;
   err varchar2(1);
   is_ship boolean := false;
   msg varchar2(80);
   locstatus location.status%type;
   loctype location.loctype%type;
   checkid location.checkdigit%type;
   lpid plate.lpid%type;
   l_cnt pls_integer;
   hold_lptype plate.type%type;
begin
   out_error := 'N';
   out_message := null;
   out_facility := null;
   out_location := null;
   out_status := null;
   out_item := null;
   out_custid := null;
   out_rowid := null;
   out_wasship := 'N';

   zrf.identify_lp(in_lpid, lptype, xrefid, xreftype, parentid, parenttype,
         topid, toptype, msg);
   if (msg is not null) then
      out_error := 'Y';
      out_message := msg;
      return;
   end if;

   if (lptype = '?') then
      out_message := 'Unknown plate';
      return;
   end if;

   if (lptype = 'DP') then
      out_message := 'LP is deleted';
      return;
   end if;

   hold_lptype := lptype;
   lpid := nvl(topid, nvl(parentid, nvl(xrefid, in_lpid)));
   lptype := nvl(toptype, nvl(parenttype, nvl(xreftype, lptype)));

-- user entered an LP which is a full pick, need to check and see if this is
-- a multiply-transferred LP (prn 8491)
   if (lptype = 'F') and (substr(in_lpid, -1, 1) != 'S') then
      select count(distinct facility) into l_cnt
         from shippingplate
         where fromlpid = in_lpid
           and type = 'F';
      if l_cnt > 1 then
         select count(1) into l_cnt
            from shippingplate
            where facility = in_facility
              and fromlpid = in_lpid
              and type = 'F'
              and status != 'SH';
         if l_cnt = 0 then
            lpid := in_lpid;
            lptype := hold_lptype;
         end if;
      end if;
   end if;

   if (lptype in ('C', 'F', 'M', 'P')) then
      open c_ship(lpid);
      fetch c_ship into lp;
      close c_ship;
      out_wasship := 'Y';
      is_ship := true;
   else
      open c_lp(lpid);
      fetch c_lp into lp;
      close c_lp;
   end if;

   out_facility := lp.facility;
   out_location := lp.location;
   out_status := lp.status;
   out_item := lp.item;
   out_custid := lp.custid;
   out_rowid := rowidtochar(lp.rowid);
   out_lpid := lpid;
   out_lptype := lptype;

   if (is_ship) then                         -- shippingplate edits
      if (in_shipok != 'Y') then
         out_message := 'SLP not allowed';
         return;
      end if;
      if ((lp.status != 'S')
      and (lp.status != 'P' or 'Y' != zrf.is_location_physical(lp.facility, lp.location))) then
         out_message := 'SLP not staged';
         return;
      end if;
   else                                      -- plate edits
      if (((in_tasktype = 'PA' and lp.status != 'A')
        or (in_tasktype != 'PA' and (lp.status not in ('A','K')
         and (lp.status != 'P' or 'Y' != zrf.is_location_physical(lp.facility, lp.location)))))
      and zlbl.is_lp_unprocessed_autogen(lpid) = 'N') then
         out_message := 'LP unavailable';
         return;
      end if;
   end if;

   if (is_plate_passed(lpid, lptype) != 0) then
      out_message := 'Resume pending';
      return;
   end if;

   if (lp.facility != in_facility) then
      out_message := 'Not in your fac';
      return;
   end if;

   if (lp.custid is not null) then
      if (in_custid is not null) then
         if (in_custid != lp.custid) then
            out_message := 'Not login cust';
            return;
         end if;
      else
         zrf.verify_customer(lp.custid, in_user, err, msg);
         if (err != 'N') then
            out_error := err;
            out_message := msg;
            return;
         end if;
         if (msg is not null) then
            out_message := msg;
            return;
         end if;
      end if;
   end if;

   zrf.verify_location(lp.facility, lp.location, in_equipment, locstatus, loctype,
         checkid, err, msg);
   if (err != 'N') then
      out_error := err;
      out_message := msg;
      return;
   end if;
   if (msg is not null) then
      out_message := msg;
      return;
   end if;

   open c_work(lpid);
   fetch c_work into w;
   wfound := c_work%found;
   close c_work;

   if wfound then
      out_message := w.tasktype || ' task pending';
      return;
   end if;

   if (is_ship) then
      zrf.move_shippingplate(lp.rowid, in_user, 'M', in_user, in_tasktype, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
      end if;
   else
      update plate
         set location = in_user,
             prevlocation = location,
             status = 'M',
             lasttask = in_tasktype,
             lastoperator = in_user,
             lastuser = in_user,
             lastupdate = sysdate
         where lpid in (select lpid from plate
                           start with rowid = lp.rowid
                           connect by prior lpid = parentlpid);
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end bind_lp_to_user;


procedure wand_taskable_lp
   (in_lpid      in varchar2,
    in_user      in varchar2,
    in_equipment in varchar2,
    in_facility  in varchar2,
    in_location  in varchar2,
    in_tasktype  in varchar2,
    out_error    out varchar2,
    out_message  out varchar2)
is
   cursor c_task is
      select T.taskid, T.curruserid, T.fromloc, T.facility, T.toprofile, L.loctype
         from tasks T, location L
         where T.tasktype = in_tasktype
           and T.lpid = in_lpid
           and L.facility = T.facility
           and L.locid = T.fromloc;
   t c_task%rowtype;
   tfound boolean;
   cursor c_lp is
      select facility, location, status, rowid
         from plate
         where lpid = in_lpid;
   l c_lp%rowtype;
   lfound boolean;
   cursor c_newtask is
      select T.taskid
         from tasks T, plate P
         where T.facility = in_facility
           and T.fromloc = in_location
           and T.tasktype = in_tasktype
           and T.curruserid is null
           and P.lpid = T.lpid
           and P.status in ('A','P');
   nt c_newtask%rowtype;
   ntfound boolean;
   cnt integer;
   orig_taskid tasks.taskid%type;
begin
   out_error := 'N';
   out_message := null;

   open c_task;
   fetch c_task into t;
   tfound := c_task%found;
   close c_task;

   if not tfound then
      out_message := 'No ' || in_tasktype || ' task for LP';
      return;
   end if;

   if (t.facility != in_facility) then
      out_message := 'Task not in facility';
      return;
   end if;

   if (t.fromloc != in_location) then
      out_message := 'Task not at location';
      return;
   end if;

   if ((t.loctype = 'PND') and (t.toprofile is not null)) then
      select count(1) into cnt
         from equipprofequip
         where profid = t.toprofile
           and equipid = in_equipment;
      if (cnt = 0) then
         out_message := 'Equip not for to loc';
         return;
      end if;
   end if;

   open c_lp;
   fetch c_lp into l;
   lfound := c_lp%found;
   close c_lp;

   if not lfound then
      out_message := 'Unknown plate';
      return;
   end if;

   if (l.facility != in_facility) then
      out_message := 'LP not in facility';
      return;
   end if;

   if (l.location != in_location) then
      if (l.location = in_user) then
         out_message := 'Already wanded';
      else
         out_message := 'LP not at location';
      end if;
      return;
   end if;

   if l.status not in ('A','P') then
      out_message := 'LP not available';
      return;
   end if;

   begin
      select T.taskid into orig_taskid
         from tasks T, plate P
         where T.curruserid = in_user
           and T.tasktype = in_tasktype
           and T.facility = in_facility
           and P.lpid = T.lpid
           and P.status in ('A','P');
   exception
      when NO_DATA_FOUND then
         orig_taskid := null;
   end;

   if orig_taskid is not null then           -- user has an assigned task (1st scan)
      if t.curruserid is null then           --    scanned task is free
         update tasks                        --       free assigned task
            set curruserid = null,
                priority = prevpriority,
                lastuser = in_user,
                lastupdate = sysdate
            where taskid = orig_taskid;
         update tasks                        --       take scanned task
            set curruserid = in_user,
                prevpriority = priority,
                priority = '0',
                lastuser = in_user,
                lastupdate = sysdate
            where taskid = t.taskid;
      elsif t.curruserid != in_user then     --    scanned task is assigned to someone else
         update tasks                        --       take scanned task
            set curruserid = in_user,
                lastuser = in_user,
                lastupdate = sysdate
            where taskid = t.taskid;
         update tasks                        --       give assigned task to other user
            set curruserid = t.curruserid,
                lastuser = in_user,
                lastupdate = sysdate
            where taskid = orig_taskid;
      end if;
   else                                      -- user has no assigned task (not 1st scan)
      if t.curruserid is null then           --    scanned task is free
         update tasks                        --       take scanned task
            set curruserid = in_user,
                prevpriority = priority,
                priority = '0',
                lastuser = in_user,
                lastupdate = sysdate
            where taskid = t.taskid;
      else                                   --    scanned task assigned to someone else
         open c_newtask;                     --       find new task for other user
         fetch c_newtask into nt;
         ntfound := c_newtask%found;
         close c_newtask;

         if not ntfound then                 --       nothing available
            out_message := 'Other user has task';
            return;
         end if;

         update tasks                        --       take scanned task
            set curruserid = in_user,
                lastuser = in_user,
                lastupdate = sysdate
            where taskid = t.taskid;

         update tasks                        --       assign new task to other user
            set curruserid = t.curruserid,
                prevpriority = priority,
                priority = '0',
                lastuser = in_user,
                lastupdate = sysdate
            where taskid = nt.taskid;
      end if;
   end if;

   update plate
      set location = in_user,
          prevlocation = location,
          status = decode(status,'P', decode(in_tasktype, 'SP', 'P', 'M'), 'M'),
          lasttask = in_tasktype,
          lastoperator = in_user,
          lastuser = in_user,
          lastupdate = sysdate
      where lpid in (select lpid from plate
                        start with rowid = l.rowid
                        connect by prior lpid = parentlpid);

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end wand_taskable_lp;


procedure identify_lp
   (in_lpid        in varchar2,
    out_lptype     out varchar2,
    out_xrefid     out varchar2,
    out_xreftype   out varchar2,
    out_parentid   out varchar2,
    out_parenttype out varchar2,
    out_topid      out varchar2,
    out_toptype    out varchar2,
    out_message    out varchar2)
is
   cnt integer;
   cursor c_sh (p_spid varchar2) is
      select lpid, type, parentlpid, facility
         from shippingplate
         where lpid = p_spid;
   shfound boolean := false;
   sh c_sh%rowtype;
   cursor c_lp (p_lpid varchar2) is
      select lpid, type, parentlpid, facility, status
         from plate
         where lpid = p_lpid;
   lpfound boolean := false;
   lp c_lp%rowtype;
   cursor c_full (p_fac varchar2, p_lpid varchar2) is
      select lpid, type, parentlpid, facility
         from shippingplate
         where facility = p_fac
           and fromlpid = p_lpid
           and type = 'F'
         order by lpid desc;
   cursor c_master (p_fac varchar2, p_lpid varchar2) is
      select lpid, type, parentlpid, facility
         from shippingplate
         where facility = p_fac
           and fromlpid = p_lpid
           and type in ('C','M');
begin
   out_xrefid := null;
   out_xreftype := null;
   out_parentid := null;
   out_parenttype := null;
   out_topid := null;
   out_toptype := null;
   out_message := null;

   select count(1) into cnt
      from deletedplate
      where lpid = in_lpid;
   if (cnt != 0) then
      out_lptype := 'DP';              -- deleted plate
      return;
   end if;

   open c_sh(in_lpid);
   fetch c_sh into sh;
   shfound := c_sh%found;
   close c_sh;
   if (shfound) then
      out_lptype := sh.type;
   else
      open c_lp(in_lpid);
      fetch c_lp into lp;
      lpfound := c_lp%found;
      close c_lp;
      if (not lpfound) then
         out_lptype := '?';            -- not found anywhere
         return;
      end if;
      out_lptype := lp.type;
      if (lp.type = 'XP') then         -- xref to a shippingplate
         open c_sh(lp.parentlpid);
         fetch c_sh into sh;
         shfound := c_sh%found;
         close c_sh;
      elsif ((lp.type = 'PA') and (lp.status in ('I','P'))) then
         open c_full(lp.facility, lp.lpid);
         fetch c_full into sh;
         shfound := c_full%found;
         close c_full;                 -- "xref" to a full pick
      elsif ((lp.type = 'MP') and (lp.status in ('I','P'))) then
         open c_master(lp.facility, lp.lpid);
         fetch c_master into sh;
         shfound := c_master%found;
         close c_master;               -- MP exploded via picking
      end if;
      if (shfound) then
         out_xrefid := sh.lpid;
         out_xreftype := sh.type;
      end if;
   end if;

   if (shfound) then                     -- get shippingplate ancestry
      for cnt in 0..9 loop
         exit when (sh.parentlpid is null);
         open c_sh(sh.parentlpid);
         fetch c_sh into sh;
         close c_sh;
         if (cnt = 0) then
            out_parentid := sh.lpid;
            out_parenttype := sh.type;
         end if;
         out_topid := sh.lpid;
         out_toptype := sh.type;
      end loop;
      return;
   end if;

   for cnt in 0..9 loop                -- get licenseplate ancestry
      exit when (lp.parentlpid is null);
      open c_lp(lp.parentlpid);
      fetch c_lp into lp;
      close c_lp;
      if (cnt = 0) then
         out_parentid := lp.lpid;
         out_parenttype := lp.type;
      end if;
      out_topid := lp.lpid;
      out_toptype := lp.type;
   end loop;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end identify_lp;


procedure decrease_lp
   (in_lpid      in varchar2,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_qty       in number,
    in_lotno     in varchar2,
    in_uom       in varchar2,
    in_user      in varchar2,
    in_tasktype  in varchar2,
    in_invstatus in varchar2,
    in_invclass  in varchar2,
    out_error    out varchar2,
    out_message  out varchar2)
is
   cursor c_lp (p_lp varchar2) is
      select type, quantity, parentlpid
         from plate
         where lpid = p_lp;
   lp c_lp%rowtype;
   l_weight custitem.weight%type;
   totweight plate.weight%type := 0;
   c_any_lp anylpcur;
   l anylptype;
   msg varchar2(80) := null;
   workqty number := in_qty;
   p_lpid plate.lpid%type;
begin
   out_error := 'N';
   out_message := null;

   open c_lp(in_lpid);
   fetch c_lp into lp;
   close c_lp;

   if (lp.type = 'PA') then
      l_weight := in_qty * zcwt.lp_item_weight(in_lpid, in_custid, in_item, in_uom);
--    single plate
      if (lp.quantity = in_qty) then
--       delete plate
         zlp.plate_to_deletedplate(in_lpid, in_user, in_tasktype, msg);
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
            return;
         end if;
      elsif (lp.quantity < in_qty) then
         out_message := 'Qty not avail';
         rollback;
         return;
      else
--       still some left, just update the plate
         update plate
            set quantity = nvl(quantity, 0) - in_qty,
                weight = nvl(weight, 0) - l_weight,
                lasttask = in_tasktype,
                lastoperator = in_user,
                lastuser = in_user,
                lastupdate = sysdate
            where lpid = in_lpid;
      end if;
      if (lp.parentlpid is not null) then
--       adjust parent
         zplp.decrease_parent(lp.parentlpid, in_qty, l_weight, in_user, in_tasktype, msg);
         if (msg is null) then
            zplp.balance_master(lp.parentlpid, in_tasktype, in_user, msg);
         end if;
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
         end if;
      end if;
      return;
   end if;

-- we have a parent lp - find child(ren) and update them
-- try for a single plate first
   if (in_lotno is null) then
      open c_any_lp for
         select lpid, quantity, weight
            from plate
            where parentlpid = in_lpid
              and custid = in_custid
              and item = in_item
              and quantity = in_qty
              and unitofmeasure = in_uom
              and invstatus = nvl(in_invstatus, invstatus)
              and inventoryclass = nvl(in_invclass, inventoryclass);
   else
      open c_any_lp for
         select lpid, quantity, weight
            from plate
            where parentlpid = in_lpid
              and custid = in_custid
              and item = in_item
              and lotnumber = in_lotno
              and quantity = in_qty
              and unitofmeasure = in_uom
              and invstatus = nvl(in_invstatus, invstatus)
              and inventoryclass = nvl(in_invclass, inventoryclass);
   end if;

   fetch c_any_lp into l;
   if (c_any_lp%found) then
--    found a child with item and quantity, delete it
      close c_any_lp;
      zlp.plate_to_deletedplate(l.lpid, in_user, in_tasktype, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;
      totweight := l.weight;
   else
      close c_any_lp;
--    process children with item, smallest first

      if (in_lotno is null) then
         open c_any_lp for
            select lpid, quantity, weight
               from plate
               where parentlpid = in_lpid
                 and custid = in_custid
                 and item = in_item
                 and unitofmeasure = in_uom
                 and invstatus = nvl(in_invstatus, invstatus)
                 and inventoryclass = nvl(in_invclass, inventoryclass)
            order by quantity;
      else
         open c_any_lp for
            select lpid, quantity, weight
               from plate
               where parentlpid = in_lpid
                 and custid = in_custid
                 and item = in_item
                 and lotnumber = in_lotno
                 and unitofmeasure = in_uom
                 and invstatus = nvl(in_invstatus, invstatus)
                 and inventoryclass = nvl(in_invclass, inventoryclass)
            order by quantity;
      end if;

      loop
         fetch c_any_lp into l;
         exit when c_any_lp%notfound;

         if (l.quantity <= workqty) then
            zlp.plate_to_deletedplate(l.lpid, in_user, in_tasktype, msg);
            if (msg is not null) then
               out_error := 'Y';
               out_message := msg;
               close c_any_lp;
               return;
            end if;
            workqty := workqty - l.quantity;
            totweight := totweight + l.weight;
            exit when (workqty = 0);
         else
            l_weight := workqty * zcwt.lp_item_weight(l.lpid, in_custid, in_item, in_uom);
            update plate
               set quantity = nvl(quantity, 0) - workqty,
                   weight = nvl(weight, 0) - l_weight,
                   lastoperator = in_user,
                   lasttask = in_tasktype,
                   lastuser = in_user,
                   lastupdate = sysdate
               where lpid = l.lpid;
            totweight := totweight + l_weight;
            workqty := 0;
            exit;
         end if;
      end loop;
      close c_any_lp;
      if (workqty != 0) then
         out_message := 'Qty not avail';
         rollback;
         return;
      end if;
   end if;

-- adjust parent (self)

   zplp.decrease_parent(in_lpid, in_qty, totweight, in_user, in_tasktype, msg);
   if (msg is null) then
      zplp.balance_master(in_lpid, in_tasktype, in_user, msg);
   end if;
   if (msg is not null) then
      out_error := 'Y';
      out_message := msg;
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end decrease_lp;


procedure suspend_item
   (in_facility  in varchar2,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_lotno     in varchar2,
    in_uom       in varchar2,
    in_qty       in number,
    in_user      in varchar2,
    in_invclass  in varchar2,
    in_fromlpid  in varchar2,
    out_message  out varchar2)
is
   newlpid plate.lpid%type;
   msg varchar2(80);
   l_weight plate.weight%type;
   lp plate%rowtype;
begin
   out_message := null;

   lp := null;
   begin
     select creationdate, manufacturedate, expirationdate, lastcountdate,
            fifodate, anvdate
       into lp.creationdate, lp.manufacturedate, lp.expirationdate, lp.lastcountdate,
            lp.fifodate, lp.anvdate
       from plate
      where lpid = in_fromlpid;
   exception when others then
     null;
   end;
   zrf.get_next_lpid(newlpid, msg);
   if (msg is not null) then
      out_message := msg;
   else
      l_weight := in_qty * zcwt.lp_item_weight(in_fromlpid, in_custid, in_item, in_uom);
      insert into plate
         (lpid, item, custid, facility, location, status, unitofmeasure,
          quantity, type, lotnumber, creationdate, lastoperator, lastuser,
          lastupdate, invstatus, inventoryclass,
          weight,
          parentfacility, parentitem, fromlpid, qtyentered, uomentered,
          manufacturedate, expirationdate, lastcountdate,
          fifodate, anvdate)
      values
         (newlpid, in_item, in_custid, in_facility, 'SUSPENSE', 'A', in_uom,
          in_qty, 'PA', in_lotno, sysdate, in_user, in_user,
          sysdate, 'SU', in_invclass,
          l_weight,
          in_facility, in_item, in_fromlpid, in_qty, in_uom,
          lp.manufacturedate, lp.expirationdate, lp.lastcountdate,
          lp.fifodate, lp.anvdate);
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end suspend_item;


procedure unempty_dock
   (in_dockdoor  in varchar2,
    in_facility  in varchar2,
    in_equipment in varchar2,
    in_user      in varchar2,
    io_loadno    in out number,
    out_error    out varchar2,
    out_message  out varchar2)
is
   ldno number;
   ldtype loads.loadtype%type;
   ldstatus loads.loadstatus%type;
   ldtrailer loads.trailer%type;
   ldcarrier loads.carrier%type;
   err varchar2(1);
   msg varchar2(80);
   locstatus location.status%type;
   loctype location.loctype%type;
   checkid location.checkdigit%type;
   l_cnt pls_integer;
begin
   out_error := 'N';
   out_message := null;

   zrf.verify_location(in_facility, in_dockdoor, in_equipment, locstatus, loctype,
         checkid, err, msg);
   if (err != 'N') then
      out_error := err;
      out_message := msg;
      return;
   end if;
   if (msg is not null) then
      out_message := msg;
      return;
   end if;

   begin
      select loadno
         into ldno
         from door
         where facility = in_facility
           and doorloc = in_dockdoor;
   exception
      when NO_DATA_FOUND then
         out_message := 'No load at door';
         return;
   end;

   if (io_loadno != -1 and io_loadno != ldno) then
      out_message := 'Load not here';
      return;
   end if;

   begin
      select loadstatus, loadtype, trailer, carrier
         into ldstatus, ldtype, ldtrailer, ldcarrier
         from loads
         where loadno = ldno;
   exception
      when NO_DATA_FOUND then
         out_message := 'Load not found';
         return;
   end;

   if (substr(ldtype, 1, 1) != 'I') then
      out_message := 'Not inbound';
      return;
   end if;

   if (ldstatus != 'E') then
      out_message := 'Not empty';
      return;
   end if;

   select count(1) into l_cnt
      from orderhdr
      where loadno = ldno
        and ordertype = 'U';
   if l_cnt != 0 then
      out_message := 'No owner xfer reariv';
      return;
   end if;

   update loads
      set loadstatus = 'A',
          lastuser = in_user,
          lastupdate = sysdate
      where loadno = ldno;

   io_loadno := ldno;

   begin
      update trailer
         set contents_status = 'F',
             activity_type = 'UET'
       where carrier = ldcarrier
         and trailer_number = ldtrailer
         and loadno = loadno;
   exception when others then
      null;
   end;


exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end unempty_dock;


procedure tally_lp_receipt
   (in_lpid     in varchar2,
    in_user     in varchar2,
    out_message out varchar2)
is
   cursor c_lp is
      select orderid, shipid, item, lotnumber, facility, custid,
             unitofmeasure, inventoryclass, invstatus, quantity, serialnumber,
             useritem1, useritem2, useritem3, weight, parentlpid
      from plate
      where lpid = in_lpid;
   lp c_lp%rowtype;
   lpfound boolean;
   qtygood orderdtlrcpt.qtyrcvdgood%type := 0;
   qtydmgd orderdtlrcpt.qtyrcvddmgd%type := 0;
begin
   out_message := null;

   open c_lp;
   fetch c_lp into lp;
   lpfound := c_lp%found;
   close c_lp;

   if lpfound then

      if (lp.invstatus = 'DM') then
         qtydmgd := lp.quantity;
      else
         qtygood := lp.quantity;
      end if;

      insert into orderdtlrcpt
         (orderid, shipid, orderitem, orderlot,
          facility, custid, item, lotnumber,
          uom, inventoryclass, invstatus, lpid,
          qtyrcvd, lastuser, lastupdate, qtyrcvdgood, qtyrcvddmgd,
          serialnumber, useritem1, useritem2, useritem3, weight, parentlpid)
      values (lp.orderid, lp.shipid, lp.item, lp.lotnumber,
              lp.facility, lp.custid, lp.item, lp.lotnumber,
              lp.unitofmeasure, lp.inventoryclass, lp.invstatus, in_lpid,
              lp.quantity, in_user, sysdate, qtygood, qtydmgd,
              lp.serialnumber, lp.useritem1, lp.useritem2, lp.useritem3,
              lp.weight, lp.parentlpid);
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end tally_lp_receipt;


procedure lpid_auto_charge
   (in_event    in varchar2,
    in_lpid     in varchar2,
    in_user     in varchar2,
    out_message out varchar2)
is
   itm plate.item%type;
   cust plate.custid%type;
   fac plate.facility%type;
   po plate.po%type := null;
   lotnumber plate.lotnumber%type;
   orderid plate.orderid%type;
   qty plate.quantity%type;
   uom plate.unitofmeasure%type;
   loadno plate.loadno%type;
   stopno plate.stopno%type;
   shipno plate.shipno%type;
   shipid plate.shipid%type;
   orditem shippingplate.orderitem%type := null;
   ordlot shippingplate.orderlot%type := null;
   ordtyp orderhdr.ordertype%type := null;
   comptmpl orderhdr.componenttemplate%type := null;
   rategroup custrategroup.rategroup%type;
   buom plate.unitofmeasure%type;
   rategroupfound boolean;

   cursor c_rategroup (p_cust varchar2, p_item varchar2) is
      select rategroup, baseuom
         from custitemview
         where custid = p_cust
           and item = p_item;
   cursor c_rate (p_cust varchar2, p_rate varchar2) is
      select W.activity, W.billmethod
         from custrategroup G, custactvfacilities F, custratewhen W
         where rategrouptype(W.custid,W.rategroup)
               = zbut.rategroup(p_cust,p_rate)
           and W.businessevent = in_event
           and W.automatic = 'A'
           and G.custid = W.custid
           and G.rategroup = W.rategroup
           and G.status = 'ACTV'
           and W.custid = F.custid (+)
           and W.activity = F.activity (+)
           and 0 < instr(','||nvl(F.facilities, fac)||',', ','||fac||',')
           and W.effdate =
                  (select max(effdate)
                     from custrate
                        where custid = W.custid
                          and activity = W.activity
                          and billmethod = W.billmethod
                          and rategroup = W.rategroup
                          and effdate <= trunc(sysdate));

   cursor c_order(p_orderid number, p_shipid number) is
      select orderstatus, ordertype
         from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   oh c_order%rowtype;
   ohfound boolean := false;
   errno number;
   msg varchar2(255);
   logmsg varchar2(255);
   inv_num invoicedtl.invoice%type := null;
   inv_type invoicedtl.invtype%type := 'A';
   l_weight plate.weight%type;
begin
   out_message := null;

   begin
      select P.item, P.custid, P.facility, P.po, P.lotnumber,
             nvl(P.orderid, 0), P.quantity, P.unitofmeasure,
             P.loadno, P.stopno, P.shipno, nvl(P.shipid, 0),
             H.ordertype, H.componenttemplate, P.weight
         into itm, cust, fac, po, lotnumber,
              orderid, qty, uom,
              loadno, stopno, shipno, shipid,
              ordtyp, comptmpl, l_weight
         from plate P, orderhdr H
         where P.lpid = in_lpid
           and P.type != 'XP'
           and H.orderid (+) = P.orderid
           and H.shipid (+) = P.shipid;

   exception
      when NO_DATA_FOUND then
         begin
            select S.item, S.custid, S.facility, S.lotnumber,
                   nvl(S.orderid, 0), S.quantity, S.unitofmeasure,
                   S.loadno, S.stopno, S.shipno,
                   nvl(S.shipid, 0), S.orderitem, S.orderlot,
                   H.ordertype, H.componenttemplate, S.weight
               into itm, cust, fac, lotnumber,
                    orderid, qty, uom,
                    loadno, stopno, shipno,
                    shipid, orditem, ordlot,
                    ordtyp, comptmpl, l_weight
               from shippingplate S, orderhdr H
               where S.lpid = in_lpid
                 and H.orderid (+) = S.orderid
                 and H.shipid (+) = S.shipid;
         exception
            when NO_DATA_FOUND then
               return;
         end;
   end;

   if ((itm is null) and (ordtyp = 'O') and (comptmpl is not null)) then
      itm := comptmpl;
   end if;
   open c_rategroup(cust, itm);
   fetch c_rategroup into rategroup, buom;
   rategroupfound := c_rategroup%found;
   close c_rategroup;
   if not rategroupfound then
      return;
   end if;
   if ((uom is null) and (ordtyp = 'O') and (comptmpl is not null)) then
      uom := buom;
   end if;

   if ((in_event = 'EMPT')
    or (in_event in ('RECH', 'RETH', 'RPUT') and (orderid != 0))) then
      inv_type := 'R';
   else
      if (orderid != 0) then
         open c_order(orderid, shipid);
         fetch c_order into oh;
         ohfound := c_order%found;
         close c_order;
      end if;

      if (oh.orderstatus = 'A') then
         inv_type := 'R';
      end if;
   end if;

   for w in c_rate(cust, rategroup) loop
      if inv_num is null and inv_type = 'A' and
        ((not ohfound)
                or (oh.orderstatus in ('9', 'R', 'X'))
                or (oh.ordertype = 'W'))
      then
         out_message := 'OKAY';
         zba.locate_accessorial_invoice(cust, fac, in_user, inv_num, errno, msg);
         if (errno != 0) then
            zms.log_msg('LAUTO_CHARGE', fac, cust, msg, 'E', in_user, logmsg);
            return;
         end if;
      end if;
      out_message := 'OKAY';
      insert into invoicedtl
         (billstatus, facility, custid, orderid, item,
          lotnumber, activity, activitydate, po, lpid,
          enteredqty, entereduom, lastuser, lastupdate, loadno,
          stopno, shipno,
          billmethod, shipid, orderitem, orderlot, invoice, invtype, enteredweight, businessevent)
      values
         ('0', fac, cust, orderid, itm,
          lotnumber, w.activity, sysdate, po, in_lpid,
          qty, uom, in_user, sysdate, decode(loadno, 0, null, loadno),
          decode(stopno, 0, null, stopno), decode(shipno, 0, null, shipno),
          w.billmethod, shipid, orditem, ordlot, inv_num, inv_type, l_weight, in_event);
   end loop;

   if (inv_num is not null) then
      out_message := 'OKAY';
      zba.calc_accessorial_invoice(inv_num, errno, msg);
      if (errno != 0) then
         zms.log_msg('LAUTO_CHARGE', fac, cust, msg, 'E', in_user, logmsg);
      end if;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end lpid_auto_charge;


procedure cust_auto_charge
   (in_event    in varchar2,
    in_facility in varchar2,
    in_custid   in varchar2,
    in_orderid  in number,
    in_shipid   in number,
    in_po       in varchar2,
    in_loadno   in number,
    in_stopno   in number,
    in_shipno   in number,
    in_user     in varchar2,
    out_message out varchar2)
is
   cursor c_suborders is
      select custid, orderid, shipid, po
         from orderhdr
         where wave = in_orderid
         order by orderid, shipid;
   l_msg varchar2(80);
begin
   out_message := null;

   if zcord.cons_orderid(in_orderid, in_shipid) = 0 then
      single_order_auto_charge(in_event, in_facility, in_custid, in_orderid,
            in_shipid, in_po, in_loadno, in_stopno, in_shipno, in_user,
            out_message);
      return;
   end if;

   for s in c_suborders loop
      single_order_auto_charge(in_event, in_facility, s.custid, s.orderid,
            s.shipid, s.po, in_loadno, in_stopno, in_shipno, in_user, l_msg);
      if nvl(l_msg, 'OKAY') != 'OKAY' then
         out_message := l_msg;
         return;
      end if;
      out_message := nvl(l_msg, out_message);
   end loop;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end cust_auto_charge;


procedure build_in_lp_from_qa
   (in_qalpid   in varchar2,
    in_inlpid   in varchar2,
    in_qty      in number,
    in_user     in varchar2,
    out_adj1    out varchar2,
    out_adj2    out varchar2,
    out_adj3    out varchar2,
    out_adj4    out varchar2,
    out_errno   out number,
    out_message out varchar2)
is
   cursor c_lp (p_lpid varchar2) is
      select *
         from plate
         where lpid = p_lpid;
   qalp c_lp%rowtype;
   msg varchar2(255) := null;
   errno number;
begin
   out_errno := 0;
   out_message := null;
   out_adj1 := null;
   out_adj2 := null;
   out_adj3 := null;
   out_adj4 := null;

   if (in_qalpid != in_inlpid) then       -- using a different plate

      open c_lp(in_qalpid);
      fetch c_lp into qalp;
      close c_lp;

      rfbp.dupe_lp(qalp.lpid, in_inlpid, qalp.location, qalp.status, in_qty, in_user,
            null, 'QA', null, msg);
      if (msg is not null) then
         out_message := msg;
         return;
      end if;

      zrf.tally_lp_receipt(in_inlpid, in_user, msg);
      if (msg is not null) then
         out_message := msg;
         return;
      end if;

      zia.inventory_adjustment(in_qalpid, qalp.custid, qalp.item, qalp.inventoryclass,
            qalp.invstatus, qalp.lotnumber, qalp.serialnumber, qalp.useritem1, qalp.useritem2,
            qalp.useritem3, qalp.location, qalp.expirationdate, qalp.quantity-in_qty,
            qalp.custid, qalp.item, qalp.inventoryclass, qalp.invstatus, qalp.lotnumber,
            qalp.serialnumber, qalp.useritem1, qalp.useritem2, qalp.useritem3, qalp.location,
            qalp.expirationdate, qalp.quantity, qalp.facility, 'QC', in_user, 'QA',
            (qalp.quantity-in_qty) * qalp.weight / qalp.quantity, qalp.weight,
            qalp.manufacturedate, qalp.manufacturedate,
            qalp.anvdate, qalp.anvdate,
            out_adj1, out_adj2, errno, msg);

      if (errno != 0) then
         out_errno := 1000 + errno;
         out_message := msg;
         return;
      end if;
   end if;

   zqa.change_qa_plate(in_inlpid, 'IN', in_user, out_adj3, out_adj4, errno, msg);
   if (errno != 0) then
      out_errno := errno;
      out_message := substr(msg, 1, 80);
   end if;

exception
   when OTHERS then
      out_errno := sqlcode;
      out_message := substr(sqlerrm, 1, 80);
end build_in_lp_from_qa;


procedure hold_lp_tasks
   (in_lpid      in varchar2,
    in_user      in varchar2,
    out_error    out varchar2,
    out_message  out varchar2)
is
   cnt integer;
   skip_picks varchar2(1);
begin
   out_error := 'N';
   out_message := null;

   select count(1) into cnt
      from tasks
      where lpid = in_lpid;
   if (cnt = 0) then
      select count(1) into cnt
         from subtasks
         where lpid = in_lpid;
   end if;
   if (cnt = 0) then                -- no tasks or subtasks for lp
      return;
   end if;

   select count(1) into cnt
      from tasks
      where lpid = in_lpid
        and priority = '0'
        and tasktype != 'CC';
   if (cnt = 0) then
      select count(1) into cnt
         from tasks T, subtasks S
         where S.lpid = in_lpid
           and S.taskid = T.taskid
           and T.priority = '0'
           and T.tasktype != 'CC';
   end if;
   if (cnt != 0) then
      out_message := 'LP has active tasks';
      return;
   end if;

   select count(1) into cnt
      from tasks
      where lpid = in_lpid
        and priority in ('7', '8');
   if (cnt = 0) then
      select count(1) into cnt
         from tasks T, subtasks S
         where S.lpid = in_lpid
           and S.taskid = T.taskid
           and T.priority in ('7', '8');
   end if;
   if (cnt != 0) then
      out_message := 'LP has passed picks';
      return;
   end if;

   begin
      select upper(nvl(defaultvalue, 'N')) into skip_picks
         from systemdefaults
         where defaultid = 'CC_NO_PICK_TASK_HOLD';
   exception
      when OTHERS then
         skip_picks := 'N';
   end;

   if (skip_picks = 'Y') then
      update tasks
         set priority = '9',
             prevpriority = priority,
             lastuser = in_user,
             lastupdate = sysdate
         where lpid = in_lpid
           and priority not in ('0', '7', '8', '9')
           and tasktype not in ('BP', 'PK', 'OP', 'SO');

      update tasks
         set priority = '9',
             prevpriority = priority,
             lastuser = in_user,
             lastupdate = sysdate
         where priority not in ('0', '7', '8', '9')
           and tasktype not in ('BP', 'PK', 'OP', 'SO')
           and taskid in (select distinct taskid from subtasks where
                              lpid = in_lpid);

--    let's make sure we have all the tasks
      select count(1) into cnt
         from tasks
         where lpid = in_lpid
           and priority != '9'
           and tasktype not in ('CC', 'BP', 'PK', 'OP', 'SO');
      if (cnt = 0) then
         select count(1) into cnt
            from tasks T, subtasks S
            where S.lpid = in_lpid
              and S.taskid = T.taskid
              and T.priority != '9'
              and T.tasktype not in ('CC', 'BP', 'PK', 'OP', 'SO');
      end if;
      if (0 != cnt) then
         out_message := 'LP changed - retry';
      end if;

      return;
   end if;

   update tasks
      set priority = '9',
          prevpriority = priority,
          lastuser = in_user,
          lastupdate = sysdate
      where lpid = in_lpid
        and priority not in ('0', '7', '8', '9');

   update tasks
      set priority = '9',
          prevpriority = priority,
          lastuser = in_user,
          lastupdate = sysdate
      where priority not in ('0', '7', '8', '9')
        and taskid in (select distinct taskid from subtasks where
                           lpid = in_lpid);

-- let's make sure we have all the tasks
   select count(1) into cnt
      from tasks
      where lpid = in_lpid
        and priority != '9'
        and tasktype != 'CC';
   if (cnt = 0) then
      select count(1) into cnt
         from tasks T, subtasks S
         where S.lpid = in_lpid
           and S.taskid = T.taskid
           and T.priority != '9'
           and T.tasktype != 'CC';
   end if;
   if (0 != cnt) then
      out_message := 'LP changed - retry';
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end hold_lp_tasks;


procedure process_held_lp_tasks
   (in_lpid      in varchar2,
    in_user      in varchar2,
    out_error    out varchar2,
    out_message  out varchar2)
is
   type pk_rectype is record (
      orderid subtasks.orderid%type,
      shipid subtasks.shipid%type,
      item subtasks.item%type,
      lot subtasks.orderlot%type,
      priority tasks.priority%type);
   type pk_tbltype is table of pk_rectype index by binary_integer;
   pk_tbl pk_tbltype;

   cursor c_lp is
      select facility, custid, location, item, rowid
         from plate
         where lpid = in_lpid;
   lp c_lp%rowtype;
   cursor c_tasks is
      select taskid, tasktype, fromloc, toloc, priority, prevpriority
         from tasks
         where priority = '9'
           and lpid = in_lpid
      union
      select T.taskid, T.tasktype, T.fromloc, T.toloc, T.priority, T.prevpriority
         from tasks T, subtasks S
         where T.priority = '9'
           and S.taskid = T.taskid
           and S.lpid = in_lpid;
   cursor c_subtasks (p_taskid number) is
      select orderid, shipid, item, orderlot
         from subtasks
         where taskid = p_taskid
           and lpid = in_lpid;
   msg varchar2(255);
   errmsg varchar2(255);
   errno number;
   fac facility.facility%type;
   loc location.locid%type;
   i binary_integer;
   pk_found boolean;
   skip_picks varchar2(1);
begin
   out_error := 'N';
   out_message := null;

   open c_lp;
   fetch c_lp into lp;
   close c_lp;

   begin
      select upper(nvl(defaultvalue, 'N')) into skip_picks
         from systemdefaults
         where defaultid = 'CC_NO_PICK_TASK_HOLD';
   exception
      when OTHERS then
         skip_picks := 'N';
   end;

   pk_tbl.delete;
   for t in c_tasks loop

      if (skip_picks = 'Y') and t.tasktype in ('BP', 'PK', 'OP', 'SO') then
         goto continue_loop;
      end if;

      if (t.tasktype = 'BP') then
         zms.log_msg('CYCLECOUNT', lp.facility, lp.custid, 'lpid ' || in_lpid || ': '
               || 'Held batch pick task ' || t.taskid, 'W', in_user, msg);
         commit;
         goto continue_loop;
      end if;

      if (t.tasktype = 'SO') then
         zms.log_msg('CYCLECOUNT', lp.facility, lp.custid, 'lpid ' || in_lpid || ': '
               || 'Held sortation pick task ' || t.taskid, 'W', in_user, msg);
         commit;
         goto continue_loop;
      end if;

      if (t.tasktype = 'MV') then
         delete tasks where taskid = t.taskid;
         delete subtasks where taskid = t.taskid;
         update plate
            set destfacility = null,
                destlocation = null,
                disposition = null,
                lastupdate = sysdate,
                lastuser = in_user,
                lasttask = 'CC'
            where rowid = lp.rowid;
         zms.log_msg('CYCLECOUNT', lp.facility, lp.custid, 'lpid ' || in_lpid || ': '
               || 'Deleted move task from ' || t.fromloc || ' to ' || t.toloc,
               'W', in_user, msg);
         commit;
         goto continue_loop;
      end if;

      if (t.tasktype = 'PA') then
         delete tasks where taskid = t.taskid;
         delete subtasks where taskid = t.taskid;
         update plate
            set destfacility = null,
                destlocation = null,
                disposition = null,
                lastupdate = sysdate,
                lastuser = in_user,
                lasttask = 'CC'
            where rowid = lp.rowid;
         if (lp.location = 'SUSPENSE') then
            zms.log_msg('CYCLECOUNT', lp.facility, lp.custid, 'lpid ' || in_lpid || ': '
                  || 'Deleted putaway from ' || t.fromloc || ' to ' || t.toloc,
                  'W', in_user, msg);
            commit;
         else
            zms.log_msg('CYCLECOUNT', lp.facility, lp.custid, 'lpid ' || in_lpid || ': '
                  || 'Regenerated putaway from ' || t.fromloc || ' to ' || t.toloc,
                  'W', in_user, msg);
            commit;
            zput.putaway_lp('TANR', in_lpid, lp.facility, lp.location, in_user,
               'Y', null, errmsg, fac, loc);
            if (errmsg is not null) then
               zms.log_msg('CYCLECOUNT', lp.facility, lp.custid, 'lpid ' || in_lpid || ': '
                  || 'putaway error: ' || errmsg, 'E', in_user, msg);
               commit;
            end if;
         end if;
         goto continue_loop;
      end if;

      if (t.tasktype = 'RP') then
         delete tasks where taskid = t.taskid;
         delete subtasks where taskid = t.taskid;
         zms.log_msg('CYCLECOUNT', lp.facility, lp.custid, 'lpid ' || in_lpid || ': '
               || 'Regenerated replenishment for item ' || lp.item || ' to ' || t.toloc,
               'W', in_user, msg);
         commit;
         zrp.send_replenish_msg('REPLPF', lp.facility, lp.custid, lp.item, t.toloc, in_user,
               'N', errno, errmsg);
         if (errmsg != 'OKAY') then
            zms.log_msg('CYCLECOUNT', lp.facility, lp.custid, 'lpid ' || in_lpid || ': '
               || 'replenish error: ' || errmsg, 'E', in_user, msg);
            commit;
         end if;
         goto continue_loop;
      end if;

      if (t.tasktype not in ('PK', 'OP')) then
         zms.log_msg('CYCLECOUNT', lp.facility, lp.custid, 'lpid ' || in_lpid || ': Held '
               || t.tasktype || ' task ' || t.taskid, 'W', in_user, msg);
         commit;
         goto continue_loop;
      end if;

      for s in c_subtasks(t.taskid) loop
         pk_found := false;
         for i in 1..pk_tbl.count loop
            if (pk_tbl(i).orderid = s.orderid)
            and (pk_tbl(i).shipid = s.shipid)
            and (pk_tbl(i).item = s.item)
            and (nvl(pk_tbl(i).lot, '(none)') = nvl(s.orderlot, '(none)')) then
               pk_found := true;
               exit;
            end if;
         end loop;
         if not pk_found then
            i := pk_tbl.count+1;
            pk_tbl(i).orderid := s.orderid;
            pk_tbl(i).shipid := s.shipid;
            pk_tbl(i).item := s.item;
            pk_tbl(i).lot := s.orderlot;
            pk_tbl(i).priority := t.prevpriority;
         end if;
      end loop;

   <<continue_loop>>
      null;
   end loop;

   for i in 1..pk_tbl.count loop
      zms.log_msg('CYCLECOUNT', lp.facility, lp.custid, 'lpid ' || in_lpid || ': '
            || 'Regenerated pick for order ' || pk_tbl(i).orderid || '-' || pk_tbl(i).shipid
            || ' item/lot ' || pk_tbl(i).item || '/' || nvl(pk_tbl(i).lot, '(none)'),
            'W', in_user, msg);
      zgp.pick_request('GENLIP', lp.facility, in_user, 0, pk_tbl(i).orderid,
            pk_tbl(i).shipid, pk_tbl(i).item, pk_tbl(i).lot, 0, pk_tbl(i).priority,
            null, 'N', errno, errmsg);
      if (errmsg != 'OKAY') then
         zms.log_msg('CYCLECOUNT', lp.facility, lp.custid, 'lpid ' || in_lpid || ': '
            || 'pick gen error: ' || errmsg, 'E', in_user, msg);
      end if;
   end loop;
   commit;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end process_held_lp_tasks;


procedure calc_misc_charges
   (in_facility  in varchar2,
    in_orderid   in number,
    in_shipid    in number,
    in_ordertype in varchar2,
    in_activity  in varchar2,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_qty       in number,
    in_uom       in varchar2,
    in_loadno    in number,
    in_stopno    in number,
    in_shipno    in number,
    in_user      in varchar2,
    out_message  out varchar2)
is
   cursor c_subordertot is
      select count(1) ordercnt, nvl(sum(qtyorder), 0) totordered
         from orderhdr
         where wave = in_orderid;
   st c_subordertot%rowtype;
   cursor c_suborders is
      select custid, orderid, shipid, ordertype, qtyorder
         from orderhdr
         where wave = in_orderid
         order by orderid, shipid;
   l_msg varchar2(80);
   l_qtyleft number := in_qty;
   l_qty number;
begin
   out_message := null;

   if (in_orderid = 0) or (in_orderid != zcord.cons_orderid(in_orderid, in_shipid)) then
      single_misc_charge(in_facility, in_orderid, in_shipid, in_ordertype,
         in_activity, in_custid, in_item, in_qty, in_uom, in_loadno,
         in_stopno, in_shipno, in_user, null, 0, out_message);
      return;
   end if;

   open c_subordertot;
   fetch c_subordertot into st;
   close c_subordertot;

   for s in c_suborders loop
      if st.ordercnt = 1 then
         l_qty := l_qtyleft;
      elsif st.totordered > 0 then
         l_qty := (in_qty * s.qtyorder) / st.totordered;
      else
         l_qty := 0;
      end if;

      single_misc_charge(in_facility, s.orderid, s.shipid, s.ordertype,
         in_activity, s.custid, in_item, l_qty, in_uom, in_loadno,
         in_stopno, in_shipno, in_user, null, 0, l_msg);
      if l_msg is not null then
         out_message := l_msg;
         return;
      end if;

      l_qtyleft := l_qtyleft - l_qty;
      st.ordercnt := st.ordercnt - 1;
   end loop;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end calc_misc_charges;


procedure so_lock
   (io_key in out number)
is
   l_err varchar2(80);
begin
   io_key := 0;
   zso.lock_it(l_err);
   if l_err = 'OKAY' then
      io_key := 1;
   end if;

exception
   when OTHERS then
      null;
end so_lock;


procedure so_release
   (io_key in out number)
is
   l_err varchar2(80);
begin
   if io_key != 0 then
      zso.release_it(l_err);
   end if;
   io_key := 0;

exception
   when OTHERS then
      io_key := 0;
end so_release;


procedure get_next_vlpid
   (out_vlpid   out varchar2,
    out_message out varchar2)
is
   cnt integer := 1;
   wk_vlpid plate.lpid%type;
begin
   out_message := null;

   while (cnt = 1)
   loop
      select lpad(vlpidseq.nextval, 15, '0')
         into wk_vlpid
         from dual;
      select count(1)
         into cnt
         from plate
         where lpid = wk_vlpid;
      if (cnt = 0) then
         select count(1)
            into cnt
            from deletedplate
            where lpid = wk_vlpid;
      end if;
   end loop;
   out_vlpid := wk_vlpid;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end get_next_vlpid;


procedure add_item
    (in_custid  in  varchar2,
     in_item    in  varchar2,
     in_baseuom in  varchar2,
     in_nextuom in  varchar2,
     in_nextqty in  number,
     in_workuom in  varchar2,
     in_length  in  number,
     in_width   in  number,
     in_height  in  number,
     in_weight  in  number,
     in_pickto  in  varchar2,
     in_cnttype in  varchar2,
     in_userid  in  varchar2,
     out_msg    out varchar2)
is

cursor curCI(in_custid varchar2, in_item varchar2)
is
    select *
      from custitem
     where custid = upper(in_custid)
       and item = upper(in_item);

CI curCI%rowtype;

cursor curCU(in_custid varchar2, in_item varchar2, in_baseuom varchar2,
    in_nextuom varchar2)
is
    select *
      from custitemuom
     where custid = upper(in_custid)
       and item = upper(in_item)
       and fromuom = upper(in_baseuom)
       and touom = upper(in_nextuom);

CU curCU%rowtype;


l_seq number;
l_inv integer;

begin
    out_msg := '';

    CI := null;
    open curCI(in_custid, in_item);
    fetch curCI into CI;
    close curCI;

    if nvl(CI.status, 'PEND') != 'PEND' then
        out_msg := 'Invalid Status';
        return;
    end if;

    l_inv := 0;
    select sum(quantity)
      into l_inv
     from plate
    where custid = in_custid
      and item = in_item
      and type = 'PA';

    l_inv := nvl(l_inv,0);

    if l_inv > 0 then
        if in_baseuom != ci.baseuom then
            out_msg := 'Inv Exists:No Baseuom Change';
            return;
        end if;
        if in_nextuom is not null then
            out_msg := 'Inv Exists:No uom Change';
            return;
        end if;
    end if;

    if (in_nextuom is not null) and (upper(in_workuom) = upper(in_nextuom)) then
        CI.length := in_length / power(in_nextqty,1/3);
        CI.width := in_width / power(in_nextqty,1/3);
        CI.height := in_height / power(in_nextqty,1/3);
        CI.weight := in_weight / in_nextqty;
    else
        CI.length := in_length;
        CI.width := in_width;
        CI.height := in_height;
        CI.weight := in_weight;
    end if;


    if (CI.length * CI.width * CI.height > 999999.9999) then
        out_msg := 'Cube too large:'||in_baseuom;
        return;
    end if;

    CI.cube := CI.length * CI.width * CI.height;

    if CI.custid is null then
        insert into custitem(
            custid, item, baseuom, length, width, height, weight, cube,
            picktotype, cartontype, descr, abbrev, status,
            lotrequired, serialrequired,
            user1required, user2required, user3required,
            mfgdaterequired, expdaterequired, countryrequired,
            allowsub, backorder, hazardous, invstatusind, invclassind,
            qtytype, recvinvstatus, weightcheckrequired,
            ordercheckrequired, fifowindowdays, putawayconfirmation,
            nodamaged, iskit, subslprsnrequired, lotsumreceipt,
            lotsumrenewal, lotsumbol, lotsumaccess, lotfmtaction,
            serialfmtaction, user1fmtaction, user2fmtaction, user3fmtaction,
            maxqtyof1, rategroup, serialasncapture,
            user1asncapture, user2asncapture, user3asncapture,
            needs_review_yn, use_fifo, printmsds, allow_uom_chgs,
            require_cyclecount_item, variancepct_use_default,
            use_min_units_qty, use_multiple_units_qty,
            prtlps_on_load_arrival, system_generated_lps,
            allow_component_overpicking, velocity, lastuser, lastupdate)
        values (
            upper(in_custid), upper(in_item), upper(in_baseuom), CI.length, CI.width, CI.height, CI.weight, CI.cube,
            upper(in_pickto), upper(in_cnttype), in_item, substr(in_item,1,12), 'ACTV',
            'C','C', --lotrequired, serialrequired,
            'C','C','C', -- user1required, user2required, user3required,
            'C','C','C',--mfgdaterequired, expdaterequired, countryrequired,
            'C','C','N','C','C',--allowsub, backorder, hazardous, invstatusind, invclassind,
            'C','AV','C', --qtytype, recvinvstatus, weightcheckrequired,
            'C',0,'C',--ordercheckrequired, fifowindowdays, putawayconfirmation,
            'C','N','C','N', --nodamaged, iskit, subslprsnrequired, lotsumreceipt,
            'N','N','N','C',--lotsumrenewal, lotsumbol, lotsumaccess, lotfmtaction,
            'C','C','C','C', --serialfmtaction, user1fmtaction, user2fmtaction, user3fmtaction,
            'C','C','C', --maxqtyof1, rategroup, serialasncapture,
            'C','C','C',--user1asncapture, user2asncapture, user3asncapture,
            'Y','C','N','N', --needs_review_yn, use_fifo, printmsds, allow_uom_chgs,
            'N','Y',--require_cyclecount_item, variancepct_use_default,
            'C','C',--use_min_units_qty, use_multiple_units_qty,
            'C','C',--prtlps_on_load_arrival, system_generated_lps,
            'N','B', --allow_component_overpicking, velocity
            in_userid, sysdate
        );
    else
      if l_inv = 0 then
        update custitem set
            baseuom = upper(in_baseuom),
            descr = nvl(descr, in_item),
            abbrev = nvl(abbrev, substr(in_item,1,12)),
            length = CI.length,
            width = CI.width,
            height = CI.height,
            cube = CI.cube,
            weight = CI.weight,
            picktotype = upper(in_pickto),
            cartontype = upper(in_cnttype),
            velocity = 'B',
            needs_review_yn = 'Y',
            status = 'ACTV',
            lastuser = in_userid,
            lastupdate = sysdate
        where custid = upper(in_custid)
          and item = upper(in_item);
      else
        update custitem set
            length = CI.length,
            width = CI.width,
            height = CI.height,
            cube = CI.cube,
            weight = CI.weight,
            needs_review_yn = 'Y',
            status = 'ACTV',
            lastuser = in_userid,
            lastupdate = sysdate
        where custid = upper(in_custid)
          and item = upper(in_item);
      end if;
    end if;

-- Now check for UOM Converion
    if in_nextuom is not null then
        CU := null;
        open curCU(in_custid, in_item, in_baseuom, in_nextuom);
        fetch curCU into CU;
        close curCU;

        if upper(in_workuom) = upper(in_nextuom) then
            CU.length := in_length;
            CU.width := in_width;
            CU.height := in_height;
            CU.weight := in_weight;
        else
            CU.length := in_length * power(in_nextqty,1/3);
            CU.width := in_width * power(in_nextqty,1/3);
            CU.height := in_height * power(in_nextqty,1/3);
            CU.weight := in_weight * in_nextqty;
        end if;

        if (CU.length * CU.width * CU.height > 999999.9999) then
            out_msg := 'Cube too large:'||in_nextuom;
            return;
        end if;

        CU.cube := CU.length * CU.width * CU.height;

        if CU.item is null then
            l_seq := null;
            select max(sequence)
              into l_seq
              from custitemuom
             where custid = upper(in_custid)
               and item = upper(in_item);

            insert into custitemuom (
                custid, item, sequence, qty, fromuom, touom,
                picktotype, cartontype, velocity,
                length, width, height, cube, weight,
                lastuser, lastupdate)
            values (
                upper(in_custid), upper(in_item), nvl(l_seq,0)+10, in_nextqty, in_baseuom, in_nextuom,
                upper(in_pickto), upper(in_cnttype), 'B',
                CU.length, CU.width, CU.height, CU.cube, CU.weight,
                in_userid, sysdate);
        else
            update custitemuom set
                    qty = in_nextqty,
                    fromuom = upper(in_baseuom),
                    touom = upper(in_nextuom),
                    picktotype = upper(in_pickto),
                    cartontype = upper(in_cnttype),
                    velocity = 'B',
                    length = CU.length,
                    width = CU.width,
                    height = CU.height,
                    cube = CU.cube,
                    weight = CU.weight,
                    lastuser = in_userid,
                    lastupdate = sysdate
             where custid = upper(in_custid)
               and item = upper(in_item)
               and sequence = CU.sequence;
        end if;

    end if;
exception
   when OTHERS then
      out_msg := 'zrf.ai:'||substr(sqlerrm, 1, 80);
end add_item;

procedure is_lp_overbuilt
   (in_lip       in varchar2,
    in_customer   in varchar2,
    in_item       in varchar2,
    in_entuom     in varchar2,
    in_qty        in number,
    in_baseuom    in varchar2,
    out_overbuilt out number) is
   errMsg varchar2(255);
   cursor c_ciu(p_custid varchar2, p_item varchar2) is
      select touom
         from custitemuom
         where custid = p_custid
           and item = p_item
         order by sequence desc;
   addQty number(7);
   uomQty number(7);
   highQty number(7);
   highUom varchar2(3);
   mQty number(7);
   logmsg varchar2(255);
begin

--   zms.log_autonomous_msg('OB', 'OB', in_customer, 'OVERBUILT->' || in_lip ||'<> ' ||
--                          in_customer || ' ' || in_item || ' '|| in_entuom || ' ' || in_qty, 'I', 'CUB', logmsg);

   zbut.translate_uom(in_customer, in_item, in_qty, in_entuom, in_baseuom, addQty, errMsg);
   highQty := 0;
   for ciu in c_ciu(in_customer, in_item) loop
      uomQty := zlbl.uom_qty_conv(in_customer, in_item, 1, ciu.touom, in_baseuom);
      if uomQty > highQty then
         highQty := uomQTy;
         highUom := ciu.touom;
      end if;
   end loop;
   if in_lip is not null then
      begin
         select sum(quantity) into mQty
            from plate
            where (parentlpid = in_lip or
                  (lpid = in_lip and
                   type <> 'MP'))
              and item = in_item;
      exception when no_data_found then
         mQty := 0;
      end;
   else
      mQty := 0;
   end if;
   if nvl(mQty,0) + nvl(addQty,0) > highQty then
      out_overbuilt := 1;
   else
      out_overbuilt := 0;
   end if;
end is_lp_overbuilt;

procedure check_underbuilt
   (in_lip       in varchar2,
    in_customer   in varchar2,
    in_item       in varchar2,
    in_entuom     in varchar2,
    in_qty        in number,
    in_baseuom    in varchar2,
    out_underbuilt out number) is
warnShortLP char(1);
warnShortLPQTY number(7);
rc number;
logmsg varchar2(255);
begin
--   zms.log_autonomous_msg('OB', 'OB', in_customer, 'UNDERBUILT->' || in_lip ||'<> ' ||
--                          in_customer || ' ' || in_item || ' '|| in_entuom || ' ' ||
--                          in_qty || ' ' || in_baseuom , 'I', 'CUB', logmsg);

   out_underbuilt := 0;
   begin
      select nvl(warnshortlp, 'N'), warnshortlpqty into warnShortLP, warnShortLPQty
         from custitem
         where custid = in_customer
           and item = in_item;
   exception when others then
      return;
   end;

   if warnShortLp <> 'Y' then
      return;
   end if;
   is_lp_underbuilt(in_lip, in_customer, in_item, in_entuom, in_qty,
                    in_baseuom, warnShortLPQty, rc);
   if rc > 0 then
      out_underbuilt := warnShortLPQty;
   end if;
end check_underbuilt;

procedure is_lp_underbuilt
   (in_lip       in varchar2,
    in_customer   in varchar2,
    in_item       in varchar2,
    in_entuom     in varchar2,
    in_qty        in number,
    in_baseuom    in varchar2,
    in_underqty   in number,
    out_underbuilt out number) is
   errMsg varchar2(255);
   addQty number(7);
   mQty number(7);
   logmsg varchar2(255);
begin
--   zms.log_autonomous_msg('OB', 'OB', in_customer, 'IS UNDERBUILT->' || in_lip ||'<> ' ||
--                          in_customer || ' ' || in_item || ' '|| in_entuom || ' ' ||
--                          in_qty || ' ' || in_baseuom || ' ' || in_underqty, 'I', 'CUB', logmsg);

   if nvl(in_underqty,0) = 0 then
      out_underbuilt := 0;
      return;
   end if;
   zbut.translate_uom(in_customer, in_item, in_qty, in_entuom, in_baseuom, addQty, errMsg);

   if in_lip is not null then
      begin
         select sum(quantity) into mQty
            from plate
            where (parentlpid = in_lip or
                  (lpid = in_lip and
                   type <> 'MP'))
              and item = in_item;
      exception when no_data_found then
         mQty := 0;
      end;
   else
      mQty := 0;
   end if;
--   zms.log_autonomous_msg('OB', 'OB', in_customer, 'IS UNDERBUILT QTY->' || nvl(mQty,0) || ' + ' ||
--                          nvl(addQty,0) || ' < ' || in_underqty || '?', 'I', 'CUB', logmsg);
   if nvl(mQty,0) + nvl(addQty,0) < in_underqty then
      out_underbuilt := 1;
   else
      out_underbuilt := 0;
   end if;
--   zms.log_autonomous_msg('OB', 'OB', in_customer, 'IS UNDERBUILT QTY->' || nvl(mQty,0) || ' + ' ||
--                          nvl(addQty,0) || ' < ' || in_underqty || '? ' || out_underbuilt, 'I', 'CUB', logmsg);
end is_lp_underbuilt;

procedure verify_multi_item
   (in_mlip        in varchar2,
    in_item        in varchar2,
    out_multi_item out number) is
lType plate.type%type;
lItem plate.item%type;
lCustid plate.custid%type;
lCnt number;
begin
   out_multi_item := 0;
   begin
      select type, item, custid into lType, lItem, lCustid
        from plate
        where lpid = in_mlip;
   exception when no_data_found then
      return;
   end;
   if lType = 'MP' then
      for IT in (select distinct p.custid, p.item
                   from plate p, custitemview c
                  where p.parentlpid = in_mlip
                    and c.custid = p.custid
                    and c.item = p.item
                    and nvl(nomixeditemlp, 'N') = 'Y') loop
         if IT.item <> in_item then
            out_multi_item := 1;
         end if;
      end loop;
   else
      if lItem <> in_item then
         select count(1) into lCnt
            from custitemview
            where custid = lCustid
              and (item = lItem or item = in_item)
              and nvl(nomixeditemlp, 'N') = 'Y';
         if lCnt > 0 then
            out_multi_item := 1;
         end if;
      end if;
   end if;

   return;

end verify_multi_item;

procedure rf_assume_task
   (in_facility      in  varchar2,
    in_orig_userid   in  varchar2,
    in_new_userid    in  varchar2,
    out_error        out number,
    out_message      out varchar2)
is

cursor curUH(in_nameid varchar2) is
  select nameid, facility, cleanlogout, session_id
    from userheader
   where nameid = upper(in_nameid);
orig_uh curUH%rowtype;
new_uh curUH%rowtype;
l_msg varchar2(1000);
l_cnt pls_integer;
begin
out_error := 0;
out_message := 'OKAY';
orig_uh := null;
open curUH(in_orig_userid);
fetch curUH into orig_uh;
close curUH;
if orig_uh.nameid is null then
  out_error := -1;
  out_message := 'Bad user ' || in_orig_userid;
  return;
end if;
new_uh := null;
open curUH(in_new_userid);
fetch curUH into new_uh;
close curUH;
if new_uh.nameid is null then
  out_error := -2;
  out_message := 'Bad user ' || in_new_userid;
  return;
end if;
if orig_uh.nameid = new_uh.nameid then
  out_error := -9;
  out_message := 'Must be diff. user';
  return;
end if;
if new_uh.facility != orig_uh.facility then
  out_error := -3;
  out_message := 'Wrong facility';
  return;
end if;
begin
  select count(1)
    into l_cnt
    from userhistory
   where nameid = orig_uh.nameid
     and ( (begtime > sysdate - 2/1440) or
           (endtime > sysdate - 2/1440) );
exception when others then
  l_cnt := 0;
end;
if l_cnt <> 0 then
  out_error := -4;
  out_message :=  'Has recent actvity';
  return;
end if;
if orig_uh.session_id = '((rfwhse))' then
  ztm.kill_rfwhse_user(in_facility, lower(in_orig_userid),
                       in_new_userid,out_error, out_message);
  if out_message != 'OKAY' then
    return;
  end if;
end if;
if orig_uh.cleanlogout != new_uh.cleanlogout then
  update userheader
     set cleanlogout = orig_uh.cleanlogout
   where nameid = in_new_userid;
end if;
for uhe in (select event,max(begtime) begtime
              from userhistory
             where nameid = orig_uh.nameid
               and endtime is null
               and event not in ('LGIN')
             group by event)
loop
  for uhd in (select rowid
                from userhistory
               where nameid = orig_uh.nameid
                 and event = uhe.event
                 and begtime = uhe.begtime
                 and endtime is null)
  loop
    update userhistory
       set nameid = in_new_userid
     where rowid = uhd.rowid;
  end loop;
end loop;
update userheader
   set session_id = null,
       cleanlogout = 'Y'
 where nameid = in_orig_userid;
update plate
   set location = in_new_userid
 where facility = in_facility
   and location = in_orig_userid;
update shippingplate
   set location = in_new_userid
 where facility = in_facility
   and location = in_orig_userid;
update cants
   set nameid = in_new_userid
 where nameid = in_orig_userid;
update subtasks
   set curruserid = in_new_userid
 where facility = in_facility
   and priority = '0'
   and curruserid = in_orig_userid;
update tasks
   set curruserid = in_new_userid
 where facility = in_facility
   and priority = '0'
   and curruserid = in_orig_userid;
zms.log_autonomous_msg('RFUTIL',  in_facility, null,
                       'User ' || in_new_userid ||
                       ' assumed RF user session for ' ||
                       in_orig_userid, 'I', in_new_userid, l_msg);
exception when others then
  out_error := sqlcode;
  out_message := 'rfat ' || substr(sqlerrm,1,250);
end rf_assume_task;
procedure add_rf_user_linux_login
   (in_facility        in varchar2,
    in_rf_userid       in out varchar2,
    in_rf_userid_info  in varchar2,
    in_userid          in out varchar2,
    out_error          out number,
    out_message        out varchar2)
is
l_correlation varchar2(32);
l_msg varchar2(1000);
l_status number;
l_tasktype tasks.tasktype%type;
l_assigned number;
l_cnt pls_integer;
l_instance varchar2(9);
begin
  out_error := 0;
  out_message := 'OKAY';
  in_rf_userid := lower(in_rf_userid);
  in_userid := upper(in_userid);
  l_correlation := ztm.find_correlation(in_facility);
  select sys_context('USERENV','DB_NAME')
    into l_instance
    from dual;
  l_msg := 'ADDRFUSER' || chr(9) ||
           trim(in_rf_userid) || chr(9) ||
           trim(in_rf_userid_info) || chr(9) ||
           trim(l_instance) || chr(9) ||
           trim(in_userid) || chr(9);
  l_status := zqm.send(ztm.WORK_DEFAULT_QUEUE,'MSG',l_msg,1,l_correlation);
  commit;
  if (l_status != 1) then
    out_error := -2;
    out_message := 'Send error ' || l_status;
    return;
  end if;
  ztm.work_response(in_userid, in_facility, l_assigned, l_tasktype, l_msg);
  if l_tasktype != 'OK' then
    out_error := -3;
    out_message := 'Can''t add: ' || l_tasktype;
  end if;
  zms.log_autonomous_msg('RFUTIL',  in_facility, null,
                         'User ' || in_userid ||
                         ' added RF user ' ||
                         in_rf_userid, 'I', in_userid, l_msg);
exception when others then
  out_error := sqlcode;
  out_message := 'aru ' || substr(sqlerrm,1,250);
end add_rf_user_linux_login;
procedure modify_rf_user_linux_login
   (in_facility        in varchar2,
    in_rf_userid       in out varchar2,
    in_rf_userid_info  in varchar2,
    in_userid          in out varchar2,
    out_error          out number,
    out_message        out varchar2)
is
l_correlation varchar2(32);
l_msg varchar2(1000);
l_status number;
l_tasktype tasks.tasktype%type;
l_assigned number;
l_cnt pls_integer;
l_instance varchar2(9);
begin
  out_error := 0;
  out_message := 'OKAY';
  in_rf_userid := lower(in_rf_userid);
  in_userid := upper(in_userid);
  l_correlation := ztm.find_correlation(in_facility);
  select sys_context('USERENV','DB_NAME')
    into l_instance
    from dual;
  l_msg := 'MODRFUSER' || chr(9) ||
           trim(in_rf_userid) || chr(9) ||
           trim(in_rf_userid_info) || chr(9) ||
           trim(l_instance) || chr(9) ||
           trim(in_userid) || chr(9);
  l_status := zqm.send(ztm.WORK_DEFAULT_QUEUE,'MSG',l_msg,1,l_correlation);
  commit;
  if (l_status != 1) then
    out_error := -2;
    out_message := 'Send error ' || l_status;
    return;
  end if;
  ztm.work_response(in_userid, in_facility, l_assigned, l_tasktype, l_msg);
  if l_tasktype != 'OK' then
    out_error := -3;
    out_message := 'Can''t modify: ' || l_tasktype;
  end if;
  zms.log_autonomous_msg('RFUTIL',  in_facility, null,
                         'User ' || in_userid ||
                         ' modified RF user ' ||
                         in_rf_userid, 'I', in_userid, l_msg);
exception when others then
  out_error := sqlcode;
  out_message := 'mru ' || substr(sqlerrm,1,250);
end modify_rf_user_linux_login;
procedure populate_rf_sessions
   (in_facility        in varchar2,
    in_userid          in out varchar2,
    out_error          out number,
    out_message        out varchar2)
is
l_correlation varchar2(32);
l_msg varchar2(1000);
l_status number;
l_tasktype tasks.tasktype%type;
l_assigned number;
l_cnt pls_integer;
l_instance varchar2(9);
l_sessionid number;
begin
  out_error := 0;
  out_message := 'OKAY';
  l_correlation := ztm.find_correlation(in_facility);
  select sys_context('USERENV','DB_NAME')
    into l_instance
    from dual;
  select sys_context('USERENV','SESSIONID')
    into l_sessionid
    from dual;
  l_msg := 'POPRFSESSIONS' || chr(9) ||
           trim(l_instance) || chr(9) ||
           l_sessionid || chr(9) ||
           in_userid || chr(9);
  l_status := zqm.send(ztm.WORK_DEFAULT_QUEUE,'MSG',l_msg,1,l_correlation);
  commit;
  if (l_status != 1) then
    out_error := -2;
    out_message := 'Send error ' || l_status;
    return;
  end if;
  ztm.work_response(in_userid, in_facility, l_assigned, l_tasktype, l_msg);
  if l_tasktype != 'OK' then
    out_error := -3;
    out_message := 'Can''t populate: ' || l_tasktype;
  end if;
  out_error := l_sessionid;
exception when others then
  out_error := sqlcode;
  out_message := 'prs ' || substr(sqlerrm,1,250);
end populate_rf_sessions;
procedure kill_rf_user
   (in_facility  in varchar2,
    in_rf_userid in varchar2,
    in_userid    in varchar2,
    out_error    out number,
    out_message  out varchar2)
is
cursor curUH(in_nameid varchar2) is
  select nameid, facility, cleanlogout, session_id
    from userheader
   where nameid = in_nameid;
rf_uh curUH%rowtype;
l_cnt pls_integer;
l_origin varchar2(12);
l_kilmsg varchar2(255);
l_kilmsgno pls_integer;
l_licmsg varchar2(255);
l_licmsgno pls_integer;
l_msg varchar2(255);
begin
out_error := 0;
out_message := 'OKAY';
rf_uh := null;
open curUH(upper(in_rf_userid));
fetch curUH into rf_uh;
close curUH;
if rf_uh.nameid is null then
  out_error := -1;
  out_message := 'Invalid user: ' || in_rf_userid;
  return;
end if;
begin
  select count(1)
    into l_cnt
    from userhistory
   where nameid = upper(in_rf_userid)
     and ( (begtime > sysdate - 2/1440) or
           (endtime > sysdate - 2/1440) );
exception when others then
  l_cnt := -1;
end;
if l_cnt > 0 then
  out_error := -4;
  out_message :=  in_rf_userid || ' has recent actvity.';
  return;
end if;
if rf_uh.session_id = '((rfwhse))' or
   rf_uh.session_id is null then
  l_origin := 'RF';
  ztm.kill_rfwhse_user(in_facility, lower(in_rf_userid),
                       in_userid, l_kilmsgno, l_kilmsg);
  if l_kilmsg != 'OKAY' then
    zms.log_autonomous_msg('RFUTIL',  in_facility, null,
                           'RFwhse kill for ' || in_rf_userid || ': ' || l_kilmsg,
                           'I', in_userid, l_msg);
  end if;
else
  l_origin := 'WEBRF';
end if;
zlic.logoff(in_rf_userid, in_facility, l_origin, l_licmsgno, l_licmsg);
if l_licmsgno != 0 then
  zms.log_autonomous_msg('RFUTIL',  in_facility, null,
                         'License logoff for ' || in_rf_userid || ': ' || l_licmsg,
                         'I', in_userid, l_msg);
end if;
update userheader
   set session_id = null
 where nameid = upper(in_rf_userid);
exception when others then
  out_error := sqlcode;
  out_message := 'krfu ' || substr(sqlerrm,1,250);
end kill_rf_user;

procedure is_order_international
   (in_orderid       in number,
    in_shipid        in number,
    out_international out number)
is
   cnt integer;
   countrycode orderhdr.shiptocountrycode%type;
begin
   out_international := 0;
   if in_shipid = 0 then
      select count(1) into cnt
         from orderhdr
        where wave = in_orderid
          and shipto is null
          and orderstatus <> 'X'
          and nvl(shiptocountrycode,'USA') in ('USA','US');
      if cnt > 0 then
         return;
      end if;
      select count(1) into cnt
        from orderhdr OH, consignee C
       where OH.wave = in_orderid
         and OH.shipto is not null
         and orderstatus <> 'X'
         and C.consignee = oh.shipto
         and nvl(C.countrycode,'USA') in ('USA','US');
      if cnt > 0 then
         return;
      end if;
      select count(1) into cnt
        from orderhdr OH, consignee C, customer_aux CA
       where OH.wave = in_orderid
         and OH.shipto is not null
         and orderstatus <> 'X'
         and C.consignee = oh.shipto
         and nvl(C.countrycode,'USA') not in ('USA', 'US')
         and OH.custid = CA.custid
         and nvl(international_dimensions,'N') = 'Y';
      if cnt > 0 then
      out_international := 1;
      end if;
   else
      select count(1) into cnt
         from orderhdr OH, customer_aux CA
        where OH.orderid = in_orderid
          and OH.shipid = in_shipid
          and OH.custid = CA.custid
          and nvl(CA.international_dimensions,'N') = 'Y';
      if cnt > 0 then
      select nvl(C.countrycode, nvl(OH.shiptocountrycode, 'USA')) into countrycode
        from orderhdr OH, consignee C
       where OH.orderid = in_orderid
         and oh.shipid = in_shipid
         and C.consignee (+) = nvl(OH.shipto,'(none)');
      if countrycode not in ('USA', 'US') then
         out_international := 1;
      end if;
   end if;
   end if;
end is_order_international;

procedure damage_shippingplate
   (in_lpid      in varchar2,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_qty       in number,
    in_lotno     in varchar2,
    in_uom       in varchar2,
    in_lptype    in varchar2,
    in_reason    in varchar2,
    in_fromlpid  in varchar2,
    in_user      in varchar2,
    out_error    out varchar2,
    out_message  in out varchar2)
is
   cursor c_sp(p_lp varchar2) is
      select * from shippingplate
       where lpid = p_lp;
   sp c_sp%rowtype;
   newsp c_sp%rowtype;


   cursor c_lp (p_lp varchar2) is
      select *
         from plate
         where lpid = p_lp;
   lp c_lp%rowtype;
   newlp c_lp%rowtype;

   cursor c_child_lp (p_lp varchar2) is
      select *
         from plate
         where lpid = p_lp
      union
         select *
           from deletedplate
          where lpid = p_lp;
   l_weight custitem.weight%type;
   msg varchar2(80) := null;

   l_adjrowid1 varchar2(20);
   l_adjrowid2 varchar2(20);
   l_errorno number;
   l_msg varchar2(256);
   l_err varchar2(2);
   l_debug char(1);
   l_cloneid shippingplate.lpid%type;
   l_invstatus shippingplate.invstatus%type;
   logmsg varchar2(255);

   procedure debugmsg
      (in_txt varchar2)
   is
   begin
      if l_debug = 'Y' then
         zut.prt(in_txt);
      end if;
   end debugmsg;

   procedure damage_entire_full
   is
   begin
      debugmsg('damage_entire_full');
      zia.inventory_adjustment
      (lp.lpid, lp.custid, lp.item, lp.inventoryclass, 'DM', lp.lotnumber, lp.serialnumber,
       lp.useritem1, lp.useritem2, lp.useritem3, lp.location, lp.expirationdate, lp.quantity,
       lp.custid, lp.item, lp.inventoryclass, lp.invstatus, lp.lotnumber, lp.serialnumber,
       lp.useritem1, lp.useritem2, lp.useritem3, lp.location, lp.expirationdate, lp.quantity,
       lp.facility, in_reason, in_user, 'DM', lp.weight, lp.weight, lp.manufacturedate,
       lp.manufacturedate, lp.anvdate, lp.anvdate, l_adjrowid1, l_adjrowid2, l_errorno,
       l_msg ,null ,null ,'N' ,null, null, 'Y'); --in_adjust_picked_invstatus
      if l_errorno != 0 then
         out_error := 'Y';
         out_message := l_msg;
         return;
      end if;
      update shippingplate
         set invstatus = 'DM',
             lastupdate = sysdate,
             lastuser = 'DAMAGESP'
         where lpid = in_lpid;
   exception when others then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
   end damage_entire_full;

   procedure damage_partial_full
   is
   begin
      debugmsg('damage_partial_full');

      newsp := sp;

      zsp.get_next_shippinglpid(newsp.lpid, l_msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;
      newsp.quantity := in_qty;
      newsp.weight := sp.weight /sp.quantity * in_qty;
      newsp.fromlpid := in_fromlpid;
      newsp.lastupdate := sysdate;
      newsp.lastuser := 'DAMAGESP';
      insert into shippingplate values newsp;

      update shippingplate
         set quantity = quantity - newsp.quantity,
             weight = weight - newsp.weight,
             lastupdate = sysdate,
             lastuser = 'DAMAGESP'
       where lpid = sp.lpid;

      newlp := lp;
      newlp.quantity := in_qty;
      newlp.weight := sp.weight /sp.quantity * in_qty;
      newlp.lpid := in_fromlpid;
      newlp.lastupdate := sysdate;
      newlp.condition := in_reason;
      newlp.lastuser := 'DAMAGESP';
      insert into plate values newlp;
      debugmsg('lp.invstatus ' || lp.invstatus);
      zrf.decrease_lp(sp.fromlpid, lp.custid, lp.item, in_qty, lp.lotnumber,
            lp.unitofmeasure, in_user, 'DM', lp.invstatus, lp.inventoryclass,
            l_err, msg);
      if l_err <> 'N' or msg is not null then
         out_error := 'Y';
         out_message := l_msg;
         return;
      end if;

      open c_lp(newsp.fromlpid);
      fetch c_lp into lp;
      if c_lp%notfound then
         out_error := 'Y';
         out_message := 'Inv new LP not found';
         close c_lp;
         return;
      end if;
      close c_lp;
      debugmsg('new lpid ' || lp.lpid || ' ' || lp.invstatus);

      zia.inventory_adjustment
      (lp.lpid, lp.custid, lp.item, lp.inventoryclass, 'DM', lp.lotnumber, lp.serialnumber,
       lp.useritem1, lp.useritem2, lp.useritem3, lp.location, lp.expirationdate, lp.quantity,
       lp.custid, lp.item, lp.inventoryclass, lp.invstatus, lp.lotnumber, lp.serialnumber,
       lp.useritem1, lp.useritem2, lp.useritem3, lp.location, lp.expirationdate, lp.quantity,
       lp.facility, in_reason, in_user, 'DM', lp.weight, lp.weight, lp.manufacturedate,
       lp.manufacturedate, lp.anvdate, lp.anvdate, l_adjrowid1, l_adjrowid2, l_errorno,
       l_msg ,null ,null ,'N' ,null, null, 'Y'); --in_adjust_picked_invstatus
      if l_errorno != 0 then
         out_error := 'Y';
         out_message := l_msg;
         return;
      end if;

      update shippingplate
         set invstatus = 'DM'
         where lpid = newsp.lpid;

   exception when others then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
      rollback;
   end damage_partial_full;


   procedure damage_entire_master
   is
      l_qty shippingplate.quantity%type;

      cursor c_child (p_lp varchar2) is
         select fromlpid
           from shippingplate
          where parentlpid = p_lp
            and type = 'P';
      l_lpid shippingplate.lpid%type;

   begin
      debugmsg('damage_entire_master');

      select sum(quantity) into l_qty
         from shippingplate
         where parentlpid = sp.lpid
           and invstatus = 'AV';
      for cp  in (select * from shippingplate
                            where parentlpid = sp.lpid
                              and type = 'F'
                              and invstatus = 'AV') loop
         open c_lp(cp.fromlpid);
         fetch c_lp into lp;
         if c_lp%notfound then
            out_error := 'Y';
            out_message := 'Inv C LP not found';
            close c_lp;
            return;
         end if;
         close c_lp;

         zia.inventory_adjustment
         (lp.lpid, lp.custid, lp.item, lp.inventoryclass, 'DM', lp.lotnumber, lp.serialnumber,
          lp.useritem1, lp.useritem2, lp.useritem3, lp.location, lp.expirationdate, lp.quantity,
          lp.custid, lp.item, lp.inventoryclass, lp.invstatus, lp.lotnumber, lp.serialnumber,
          lp.useritem1, lp.useritem2, lp.useritem3, lp.location, lp.expirationdate, lp.quantity,
          lp.facility, in_reason, in_user, 'DM', lp.weight, lp.weight, lp.manufacturedate,
          lp.manufacturedate, lp.anvdate, lp.anvdate, l_adjrowid1, l_adjrowid2, l_errorno,
          l_msg ,null ,null ,'N' ,null, null, 'Y'); --in_adjust_picked_invstatus
         if l_errorno != 0 then
            out_error := 'Y';
            out_message := l_msg;
            return;
         end if;
         update shippingplate
            set invstatus = 'DM',
                lastupdate = sysdate,
                lastuser = 'DAMAGESP'
            where lpid = cp.lpid;
         l_qty := l_qty - lp.quantity;
      end loop;
      /* fulls are processed, now do the partials */
      debugmsg('after fulls ' || l_qty);
      open c_child(sp.lpid);
      fetch c_child into l_lpid;
      if c_child%notfound then
         /* only fulls on a master */
         close c_child;
         return;
      end if;
      close c_child;
      debugmsg('child from lpid ' || l_lpid);
      open c_child_lp(l_lpid);
      fetch c_child_lp into lp;
      if c_child_lp%notfound then
         out_error := 'Y';
         out_message := 'Child LP not found';
         close c_child_lp;
         return;
      end if;
      close c_child_lp;

      newlp := lp;
      zrf.get_next_lpid(newlp.lpid, l_msg);
      debugmsg('new lpid ' || newlp.lpid);
      newlp.quantity := l_qty;
      newlp.weight := sp.weight /sp.quantity * l_qty;
      newlp.lastupdate := sysdate;
      newlp.lastuser := 'DAMAGESP';
      newlp.location := sp.location;
      newlp.status := 'P';
      newlp.creationdate := sysdate;
      newlp.invstatus := 'AV';
      newlp.condition := in_reason;

      insert into plate values newlp;

      zia.inventory_adjustment
      (newlp.lpid, newlp.custid, newlp.item, newlp.inventoryclass, 'DM', newlp.lotnumber, newlp.serialnumber,
       newlp.useritem1, newlp.useritem2, newlp.useritem3, newlp.location, newlp.expirationdate, newlp.quantity,
       newlp.custid, newlp.item, newlp.inventoryclass, newlp.invstatus, newlp.lotnumber, newlp.serialnumber,
       newlp.useritem1, newlp.useritem2, newlp.useritem3, newlp.location, newlp.expirationdate, newlp.quantity,
       newlp.facility, in_reason, in_user, 'DM', newlp.weight, newlp.weight, newlp.manufacturedate,
       newlp.manufacturedate, newlp.anvdate, newlp.anvdate, l_adjrowid1, l_adjrowid2, l_errorno,
       l_msg ,null ,null ,'N' ,null, null, 'Y'); --in_adjust_picked_invstatus
      if l_errorno != 0 then
         debugmsg('ia ' || l_msg);
         out_error := 'Y';
         out_message := l_msg;
         return;
      end if;

      zlp.plate_to_deletedplate(newlp.lpid, in_user, 'DM', msg);
      if (msg is not null) then
         out_message := msg;
         return;
      end if;

      update shippingplate
         set fromlpid = newlp.lpid,
             invstatus = 'DM',
             lastupdate = sysdate,
             lastuser = 'DAMAGESP'
       where parentlpid = sp.lpid
         and type = 'P'
         and invstatus = 'AV';

      update shippingplate
         set invstatus = 'DM',
             lastupdate = sysdate,
             lastuser = 'DAMAGESP'
       where lpid = sp.lpid;


   exception when others then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
   end damage_entire_master;
----------------------------------------------------------------------------
   procedure damage_partial_master
   is
      l_qty shippingplate.quantity%type;
      new_lp_created char(1);
      damaged_sp_lpid shippingplate.lpid%type;
      damaged_lp_lpid shippingplate.lpid%type;
      damaged_weight shippingplate.weight%type;
      cursor c_child_sp (p_lp varchar2) is
         select *
           from shippingplate
          where parentlpid = p_lp
            and type in ('P','F');
   begin
      select sum(quantity) into l_qty
        from shippingplate
        where parentlpid = sp.lpid
          and invstatus = 'AV';
      debugmsg('damage_partial_master');
      damaged_weight := sp.weight /sp.quantity;
      new_lp_created := 'N';
      l_qty := in_qty;
      /* look for full plates first */

      for cp  in (select * from shippingplate
                            where parentlpid = sp.lpid
                              and type = 'F'
                              and invstatus = 'AV'
                           order by quantity desc) loop
         open c_lp(cp.fromlpid);
         fetch c_lp into lp;
         if c_lp%notfound then
            out_error := 'Y';
            out_message := 'Inv CP LP not found';
            close c_lp;
            return;
         end if;
         close c_lp;
         if new_lp_created = 'N' then
            /* create a 0 qty plate and shippingplate to hold the damaged item */
            newlp := lp;
            newlp.lpid := in_fromlpid;
            newlp.quantity := 0;
            newlp.weight := 0;
            newlp.lastupdate := sysdate;
            newlp.lastuser := 'DAMAGESP';
            newlp.location := sp.location;
            newlp.status := 'P';
            newlp.creationdate := sysdate;
            newlp.invstatus := 'AV';
            newlp.condition := in_reason;
            insert into plate values newlp;


            open c_child_sp(in_lpid);
            fetch c_child_sp into newsp;
            if  c_child_sp%notfound then
               out_error := 'Y';
               out_message := 'NSP not found';
               close c_child_sp;
               return;
            end if;
            close c_child_sp;

            zsp.get_next_shippinglpid(newsp.lpid, l_msg);
            damaged_sp_lpid := newsp.lpid;
            if (msg is not null) then
               out_error := 'Y';
               out_message := msg;
               return;
            end if;
            newsp.type := 'F';
            newsp.quantity := 0;
            newsp.weight := 0;
            newsp.fromlpid := in_fromlpid;
            newsp.lastupdate := sysdate;
            newsp.lastuser := 'DAMAGESP';
            newsp.invstatus := 'DM';
            newsp.parentlpid := null;
            insert into shippingplate values newsp;
            new_lp_created := 'Y';
         end if;
         if lp.quantity > l_qty then
            update plate -- update new plate
               set quantity = quantity + l_qty,
                   weight = (quantity + l_qty) * damaged_weight,
                   lastupdate = sysdate,
                   lastuser = 'DAMAGESP'
              where lpid = in_fromlpid;
            update shippingplate -- update new shippingplate
               set quantity = quantity + l_qty,
                   weight = (quantity + l_qty) * damaged_weight,
                   lastupdate = sysdate,
                   lastuser = 'DAMAGESP'
             where lpid = damaged_sp_lpid;
            update plate -- update old plate
               set quantity = quantity - l_qty,
                   weight = (quantity - l_qty) * damaged_weight,
                   lastupdate = sysdate,
                   lastuser = 'DAMAGESP'
              where lpid = lp.lpid;
            update shippingplate --update old full shippingplate
               set quantity = quantity - l_qty,
                   weight = (quantity - l_qty) * damaged_weight,
                   lastupdate = sysdate,
                   lastuser = 'DAMAGESP'
             where lpid = cp.lpid;
            update shippingplate --update original master shippingplate
               set quantity = quantity - l_qty,
                   weight = (quantity - l_qty) * damaged_weight,
                   lastupdate = sysdate,
                   lastuser = 'DAMAGESP'
             where lpid = in_lpid;

            l_qty := 0;
            exit;
         else
            update plate -- update new plate
               set quantity = quantity + lp.quantity,
                   weight = (quantity + lp.quantity) * damaged_weight,
                   lastupdate = sysdate,
                   lastuser = 'DAMAGESP'
              where lpid = in_fromlpid;
            update shippingplate -- update new shippingplate
               set quantity = quantity + lp.quantity,
                   weight = (quantity + lp.quantity) * damaged_weight,
                   lastupdate = sysdate,
                   lastuser = 'DAMAGESP'
             where lpid = damaged_sp_lpid;
            update shippingplate --update original master shippingplate
               set quantity = quantity - lp.quantity,
                   weight = (quantity - lp.quantity) * damaged_weight,
                   lastupdate = sysdate,
                   lastuser = 'DAMAGESP'
             where lpid = in_lpid;
            delete from shippingplate
               where lpid = cp.lpid;
            zlp.plate_to_deletedplate(lp.lpid, in_user, 'DM', msg);
            if (msg is not null) then
               out_message := msg;
               return;
            end if;
            l_qty := l_qty - lp.quantity;
         end if;
 --        first pass create new plate, create new full shippingplate
 --        subsequent passes increment plate, increment shippingplate
 --        decrement master
 --        decrement/delete current full
         if l_qty = 0 then
            exit;
         end if;
      end loop;
      if l_qty <> 0 then
         for cp  in (select * from shippingplate
                               where parentlpid = sp.lpid
                                 and type = 'P'
                                 and invstatus = 'AV'
                              order by quantity desc) loop
            if new_lp_created = 'N' then
               open c_child_lp(cp.fromlpid);
               fetch c_child_lp into lp;
               if c_child_lp%notfound then
                  out_error := 'Y';
                  out_message := 'DPM Child LP not found';
                  close c_child_lp;
                  return;
               end if;
               close c_child_lp;

               /* create a 0 qty plate and shippingplate to hold the damaged item */
               newlp := lp;
               newlp.lpid := in_fromlpid;
               newlp.quantity := 0;
               newlp.weight := 0;
               newlp.lastupdate := sysdate;
               newlp.lastuser := 'DAMAGESP';
               newlp.location := sp.location;
               newlp.status := 'P';
               newlp.creationdate := sysdate;
               newlp.invstatus := 'AV';
               newlp.condition := in_reason;

               insert into plate values newlp;

               open c_child_sp(in_lpid);
               fetch c_child_sp into newsp;
               if  c_child_sp%notfound then
                  out_error := 'Y';
                  out_message := 'NSP not found';
                  close c_child_sp;
                  return;
               end if;
               close c_child_sp;

               zsp.get_next_shippinglpid(newsp.lpid, l_msg);
               damaged_sp_lpid := newsp.lpid;
               if (msg is not null) then
                  out_error := 'Y';
                  out_message := msg;
                  return;
               end if;
               newsp.type := 'F';
               newsp.quantity := 0;
               newsp.weight := 0;
               newsp.fromlpid := in_fromlpid;
               newsp.lastupdate := sysdate;
               newsp.lastuser := 'DAMAGESP';
               newsp.parentlpid := null;
               newsp.invstatus := 'DM';
               insert into shippingplate values newsp;
               new_lp_created := 'Y';
            end if;
            if cp.quantity > l_qty then
               update plate -- update new plate
                  set quantity = quantity + l_qty,
                      weight = (quantity + l_qty) * damaged_weight,
                      lastupdate = sysdate,
                      lastuser = 'DAMAGESP'
                 where lpid = in_fromlpid;
               update shippingplate -- update new shippingplate
                  set quantity = quantity + l_qty,
                      weight = (quantity + l_qty) * damaged_weight,
                      lastupdate = sysdate,
                      lastuser = 'DAMAGESP'
                where lpid = damaged_sp_lpid;
               update shippingplate --update old full shippingplate
                  set quantity = quantity - l_qty,
                      weight = (quantity - l_qty) * damaged_weight,
                      lastupdate = sysdate,
                      lastuser = 'DAMAGESP'
                where lpid = cp.lpid;
               update shippingplate --update original master shippingplate
                  set quantity = quantity - l_qty,
                      weight = (quantity - l_qty) * damaged_weight,
                      lastupdate = sysdate,
                      lastuser = 'DAMAGESP'
                where lpid = in_lpid;

               l_qty := 0;
               exit;
            else
               update plate -- update new plate
                  set quantity = quantity + cp.quantity,
                      weight = (quantity + cp.quantity) * damaged_weight
                 where lpid = in_fromlpid;
               update shippingplate -- update new shippingplate
                  set quantity = quantity + cp.quantity,
                      weight = (quantity + cp.quantity) * damaged_weight
                where lpid = damaged_sp_lpid;
               update shippingplate --update original master shippingplate
                  set quantity = quantity - cp.quantity,
                      weight = (quantity - cp.quantity) * damaged_weight
                where lpid = in_lpid;
               delete from shippingplate
                  where lpid = cp.lpid;
               l_qty := l_qty - lp.quantity;
            end if;
         end loop;
      end if;
      open c_lp(in_fromlpid);
      fetch c_lp into lp;
      if c_lp%notfound then
         out_error := 'Y';
         out_message := 'Inv CP LP not found';
         close c_lp;
         return;
      end if;
      close c_lp;
      zia.inventory_adjustment
      (lp.lpid, lp.custid, lp.item, lp.inventoryclass, 'DM', lp.lotnumber, lp.serialnumber,
       lp.useritem1, lp.useritem2, lp.useritem3, lp.location, lp.expirationdate, lp.quantity,
       lp.custid, lp.item, lp.inventoryclass, lp.invstatus, lp.lotnumber, lp.serialnumber,
       lp.useritem1, lp.useritem2, lp.useritem3, lp.location, lp.expirationdate, lp.quantity,
       lp.facility, in_reason, in_user, 'DM', lp.weight, lp.weight, lp.manufacturedate,
       lp.manufacturedate, lp.anvdate, lp.anvdate, l_adjrowid1, l_adjrowid2, l_errorno,
       l_msg ,null ,null ,'N' ,null, null, 'Y'); --in_adjust_picked_invstatus
      if l_errorno != 0 then
         out_error := 'Y';
         out_message := l_msg;
         return;
      end if;

   exception when others then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
   end damage_partial_master;


begin
   --start of damage_shippingplate

   if out_message = 'DEBUG' then
      l_debug := 'Y';
   else
      l_debug := 'N';
   end if;
   out_error := 'N';
   out_message := null;

   open c_sp(in_lpid);
   fetch c_sp into sp;
   if  c_sp%notfound then
      out_error := 'Y';
      out_message := 'SP not found';
      close c_sp;
      return;
   end if;
   close c_sp;
   debugmsg('in_lptype = ' || in_lptype || ' in_qty = ' || in_qty || ' sp quantity = ' || sp.quantity);

   zms.log_autonomous_msg('DS', 'DS', in_custid, in_lpid ||'<> ' ||
                          in_custid || ' ' || in_item || ' '||  in_qty || ' ' || in_lotno ||
                          ' ' || in_uom || ' ' || in_lptype || ' ' ||in_user, 'I', 'DSP', logmsg);


   if in_lptype = 'F' then
      open c_lp(sp.fromlpid);
      fetch c_lp into lp;
      if c_lp%notfound then
         out_error := 'Y';
         out_message := 'Inv LP not found';
         close c_lp;
         return;
      end if;
      close c_lp;
      if in_qty = sp.quantity then
         damage_entire_full;
      else
         damage_partial_full;
      end if;
   else
      if in_qty = sp.quantity then
         damage_entire_master;
      else
         damage_partial_master;
      end if;
   end if;
   if out_message is not null then
      rollback;
   end if;
exception when others then
   out_error := 'Y';
   out_message := substr(sqlerrm, 1, 80);
end damage_shippingplate;

end rf;
/

show errors package body rf;
exit;
