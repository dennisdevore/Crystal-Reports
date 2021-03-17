create or replace package body alps.simplesort as
--
-- $Id$
--


-- Public procedures


procedure check_order
   (in_facility  in varchar2,
    in_orderid   in number,
    in_shipid    in number,
    out_stageloc out varchar2,
    out_error    out varchar2,
    out_message  out varchar2)
is
   cursor c_ord(p_orderid number, p_shipid number) is
      select OH.fromfacility,
             OH.carrier,
             OH.shiptype,
             nvl(OH.loadno, 0) as loadno,
             nvl(OH.stopno, 0) as stopno,
             nvl(OH.shipno, 0) as shipno,
             nvl(OH.stageloc, WV.stageloc) as stageloc
         from orderhdr OH, waves WV
         where OH.orderid = p_orderid
           and OH.shipid = p_shipid
           and WV.wave (+) = OH.wave;
   ord c_ord%rowtype := null;
   cursor c_cs(p_carrier varchar2, p_facility varchar2, p_shiptype varchar2) is
      select stageloc
         from carrierstageloc
         where carrier = p_carrier
           and facility = p_facility
           and shiptype = p_shiptype;
   cursor c_ld(p_loadno number, p_stopno number) is
      select nvl(LS.stageloc,L.stageloc) as stageloc,
             L.carrier,
             L.shiptype
         from loads L, loadstop LS
         where L.loadno = p_loadno
           and LS.loadno = L.loadno
           and LS.stopno = p_stopno;
   ld c_ld%rowtype := null;
   l_cnt pls_integer;
begin
   out_error := 'N';
   out_message := null;

   open c_ord(in_orderid, in_shipid);
   fetch c_ord into ord;
   close c_ord;

   if ord.fromfacility is null then
      out_message := 'Order not found';
      return;
   end if;

   if ord.fromfacility != in_facility then
      out_message := 'Not in your facility';
      return;
   end if;

   select count(1) into l_cnt
      from batchtasks
      where orderid = in_orderid
        and shipid = in_shipid;
   if l_cnt > 0 then
      out_message := 'Batch picks remain';
      return;
   end if;

   select count(1) into l_cnt
      from tasks
      where orderid = in_orderid
        and shipid = in_shipid
        and curruserid is null
        and tasktype = 'SO';
   if l_cnt = 0 then
      out_message := 'No sort picks found';
      return;
   end if;

   select count(1) into l_cnt
      from plate LP, shippingplate SP
      where SP.orderid = in_orderid
        and SP.shipid = in_shipid
        and LP.lpid = SP.fromlpid
        and LP.status = 'M';
   if l_cnt != 0 then
      out_message := 'Batch not staged';
      return;
   end if;

   for stsk in (select distinct picktotype
                  from subtasks
                  where orderid = in_orderid
                    and shipid = in_shipid
                    and tasktype = 'SO') loop

      if stsk.picktotype = 'TOTE' then
         out_message := 'No TOTE sort picks';
         return;
      end if;

      if stsk.picktotype = 'LBL' then
         out_message := 'No LBL sort picks';
         return;
      end if;
   end loop;

   /*
   for itm in (select CV.lotrequired,
                      CV.lotrftag,
                      CV.serialrequired,
                      CV.serialrftag,
                      CV.user1required,
                      CV.user1rftag,
                      CV.user2required,
                      CV.user2rftag,
                      CV.user3required,
                      CV.user3rftag
                  from subtasks ST, custitemview CV
                  where ST.orderid = in_orderid
                    and ST.shipid = in_shipid
                    and ST.tasktype = 'SO'
                    and CV.custid = ST.custid
                    and CV.item = ST.item) loop
      if itm.lotrequired = 'P' then
         out_message := 'No ' || itm.lotrftag || ' capture';
         return;
      end if;

      if itm.serialrequired = 'P' then
         out_message := 'No ' || itm.serialrftag || ' capture';
         return;
      end if;

      if itm.user1required = 'P' then
         out_message := 'No ' || itm.user1rftag || ' capture';
         return;
      end if;

      if itm.user2required = 'P' then
         out_message := 'No ' || itm.user2rftag || ' capture';
         return;
      end if;

      if itm.user3required = 'P' then
         out_message := 'No ' || itm.user3rftag || ' capture';
         return;
      end if;
   end loop;
   */

   if ord.stageloc is null then
      open c_cs(ord.carrier, in_facility, ord.shiptype);
      fetch c_cs into ord.stageloc;
      close c_cs;
   end if;

   if ord.stageloc is null
   and ord.loadno != 0
   and ord.stopno != 0 then

      open c_ld(ord.loadno, ord.stopno);
      fetch c_ld into ld;
      close c_ld;
      if ld.stageloc is null then
         open c_cs(ld.carrier, in_facility, ld.shiptype);
         fetch c_cs into ld.stageloc;
         close c_cs;
      end if;
      ord.stageloc := ld.stageloc;
   end if;

   out_stageloc := ord.stageloc;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end check_order;


procedure sort_and_stage_order
   (in_facility in varchar2,
    in_orderid  in number,
    in_shipid   in number,
    in_lpid     in varchar2,
    in_stageloc in varchar2,
    in_user     in varchar2,
    out_toplpid out varchar2,
    out_error   out varchar2,
    out_message out varchar2)
is
   cursor c_lp(p_lpid varchar2) is
      select parentlpid
         from plate
         where lpid = p_lpid;
   l_lpcount number;
   l_err varchar2(1) := 'N';
   l_msg varchar2(80) := null;
   l_is_loaded varchar2(1);
   l_packcnt pls_integer;

   procedure free_tasks
   is
   begin
      rollback;

      update tasks
         set curruserid = null,
             priority = prevpriority,
             lastuser = in_user,
             lastupdate = sysdate
         where orderid = in_orderid
           and shipid = in_shipid
           and priority = '0'
           and curruserid = in_user
           and tasktype = 'SO';

      commit;
   end free_tasks;
begin
   out_toplpid := null;
   out_error := 'N';
   out_message := null;

-- assign tasks to user
   update tasks
      set curruserid = in_user,
          prevpriority = priority,
          priority = 0
      where orderid = in_orderid
        and shipid = in_shipid
        and curruserid is null
        and tasktype = 'SO';

   if (sql%rowcount = 0) then
      out_message := 'Sort not available';
      return;
   end if;

   commit;

   select count(1) into l_packcnt
      from subtasks
      where orderid = in_orderid
        and shipid = in_shipid
        and tasktype = 'SO'
        and picktotype = 'PACK';

   for stsk in (select ST.*,
                       ST.rowid,
                       LP.lotnumber as lplotnumber
                  from subtasks ST, plate LP
                  where ST.orderid = in_orderid
                    and ST.shipid = in_shipid
                    and ST.tasktype = 'SO'
                    and LP.lpid (+) = ST.lpid) loop

      if l_packcnt > 0 and stsk.picktotype != 'PACK' then
         stsk.picktotype := 'PACK';
      end if;

      zrfpk.pick_a_plate
         (stsk.taskid,
          stsk.shippinglpid,
          in_user,
          stsk.lpid,
          stsk.lpid,
          stsk.custid,
          stsk.item,
          stsk.orderitem,
          stsk.orderlot,
          stsk.qty,
          0,
          stsk.facility,
          stsk.fromloc,
          stsk.uom,
          stsk.lplotnumber,
          in_lpid,
          stsk.shippingtype,
          stsk.tasktype,
          stsk.picktotype,
          stsk.fromloc,
          rowidtochar(stsk.rowid),
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          stsk.pickuom,
          stsk.pickqty,
          stsk.weight,
          stsk.lpid,
          l_lpcount,
          l_err,
          l_msg);

      exit when l_msg is not null;
   end loop;

   if l_msg is null then
      zrfpk.stage_a_plate
         (in_lpid,
          in_stageloc,
          in_user,
          'SO',
          'N',
          in_stageloc,
          'N',
          'N',
          l_err,
          l_msg,
          l_is_loaded);
   end if;

   if l_msg is not null then
      free_tasks;
   else
      open c_lp(in_lpid);
      fetch c_lp into out_toplpid;
      close c_lp;
   end if;

   out_error := l_err;
   out_message := l_msg;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
      free_tasks;
end sort_and_stage_order;


procedure sort_and_stage_wave
   (in_wave     in number,
    in_user     in varchar2,
    out_message out varchar2)
is
   type sorttype is record (
      orderid orderhdr.orderid%type,
      shipid orderhdr.shipid%type,
      custid orderhdr.custid%type,
      facility orderhdr.fromfacility%type,
      po orderhdr.po%type,
      loadno orderhdr.loadno%type,
      stopno orderhdr.stopno%type,
      shipno orderhdr.shipno%type,
      stageloc orderhdr.stageloc%type);
   type sorttbltype is table of sorttype index by binary_integer;
   sort_tbl sorttbltype;

   cursor c_cs(p_carrier varchar2, p_facility varchar2, p_shiptype varchar2) is
      select stageloc
         from carrierstageloc
         where carrier = p_carrier
           and facility = p_facility
           and shiptype = p_shiptype;
   cursor c_ld(p_loadno number, p_stopno number) is
      select nvl(LS.stageloc,L.stageloc) as stageloc,
             L.carrier,
             L.shiptype
         from loads L, loadstop LS
         where L.loadno = p_loadno
           and LS.loadno = L.loadno
           and LS.stopno = p_stopno;
   ld c_ld%rowtype := null;
   i binary_integer;
   l_cnt pls_integer;
   l_msg varchar2(255);
   l_cptlist varchar2(255);
   l_lpid plate.lpid%type;
   l_err varchar2(1);
   l_toplpid plate.lpid%type;

   function append_cpt
      (in_cptlist in varchar2,
       in_cpt     in varchar2)
   return varchar2
   is
   begin
      if in_cpt is not null then
         if in_cptlist is not null then
            return in_cptlist||', '||in_cpt;
         else
            return in_cpt;
         end if;
      end if;
      return in_cptlist;
   end append_cpt;
begin
   out_message := 'OKAY';

   sort_tbl.delete;
   for ord in (select OH.fromfacility,
                      OH.orderid,
                      OH.shipid,
                      OH.carrier,
                      OH.shiptype,
                      OH.custid,
                      OH.po,
                      nvl(OH.loadno, 0) as loadno,
                      nvl(OH.stopno, 0) as stopno,
                      nvl(OH.shipno, 0) as shipno,
                      nvl(OH.stageloc, WV.stageloc) as stageloc
               from orderhdr OH, waves WV
               where OH.wave = in_wave
                 and WV.wave = OH.wave) loop

      select count(1) into l_cnt
         from batchtasks
         where orderid = ord.orderid
           and shipid = ord.shipid;
      if l_cnt > 0 then
         out_message := 'Batch picks remain for order '||ord.orderid||'-'||ord.shipid;
         return;
      end if;

      select count(1) into l_cnt
         from plate LP, shippingplate SP
         where SP.orderid = ord.orderid
           and SP.shipid = ord.shipid
           and LP.lpid = SP.fromlpid
           and LP.status = 'M';
      if l_cnt != 0 then
         out_message := 'Batch picks not staged for order '||ord.orderid||'-'||ord.shipid;
         return;
      end if;

      -- ignore orders with no sort tasks
      select count(1) into l_cnt
         from tasks
         where orderid = ord.orderid
           and shipid = ord.shipid
           and curruserid is null
           and tasktype = 'SO';
      if l_cnt = 0 then
         goto continue_loop;
      end if;

      for stsk in (select distinct ST.picktotype
                     from subtasks ST, tasks TK
                     where ST.orderid = ord.orderid
                       and ST.shipid = ord.shipid
                       and TK.taskid = ST.taskid
                       and TK.curruserid is null
                       and TK.tasktype = 'SO') loop

         if stsk.picktotype = 'TOTE' then
            out_message := 'TOTE sort picks found for order '||ord.orderid||'-'||ord.shipid;
            return;
         end if;

         if stsk.picktotype = 'LBL' then
            out_message := 'LBL sort picks found for order '||ord.orderid||'-'||ord.shipid;
            return;
         end if;
      end loop;

      for itm in (select CV.item,
                         decode(CV.lotrequired,'P','Lot number',null) as lot,
                         decode(CV.serialrequired,'P','Serial number',null) as ser,
                         decode(CV.user1required,'P', 'User item 1', null) as us1,
                         decode(CV.user2required,'P', 'User item 2', null) as us2,
                         decode(CV.user3required,'P', 'User item 3', null) as us3
                     from subtasks ST, custitemview CV, tasks TK
                     where ST.orderid = ord.orderid
                       and ST.shipid = ord.shipid
                       and TK.taskid = ST.taskid
                       and TK.curruserid is null
                       and TK.tasktype = 'SO'
                       and CV.custid = ST.custid
                       and CV.item = ST.item) loop

         l_cptlist := null;
         l_cptlist := append_cpt(l_cptlist, itm.lot);
         l_cptlist := append_cpt(l_cptlist, itm.ser);
         l_cptlist := append_cpt(l_cptlist, itm.us1);
         l_cptlist := append_cpt(l_cptlist, itm.us2);
         l_cptlist := append_cpt(l_cptlist, itm.us3);

         if l_cptlist is not null then
            out_message := 'Item '||itm.item||' on order '||ord.orderid||'-'||ord.shipid
                  ||' requires capturing: '||l_cptlist;
            return;
         end if;
      end loop;

      if ord.stageloc is null then
         open c_cs(ord.carrier, ord.fromfacility, ord.shiptype);
         fetch c_cs into ord.stageloc;
         close c_cs;
      end if;

      if ord.stageloc is null
      and ord.loadno != 0
      and ord.stopno != 0 then

         open c_ld(ord.loadno, ord.stopno);
         fetch c_ld into ld;
         close c_ld;
         if ld.stageloc is null then
            open c_cs(ld.carrier, ord.fromfacility, ld.shiptype);
            fetch c_cs into ld.stageloc;
            close c_cs;
         end if;
         ord.stageloc := ld.stageloc;
      end if;

      if ord.stageloc is null then
         zms.log_autonomous_msg('PAPERSORT',
            ord.fromfacility,
            ord.custid,
            'No staging location for order '||ord.orderid||'-'||ord.shipid,
            'E',
            in_user,
            l_msg);
         out_message := 'APPMSGS';
      else
         i := sort_tbl.count+1;
         sort_tbl(i).orderid := ord.orderid;
         sort_tbl(i).shipid := ord.shipid;
         sort_tbl(i).custid := ord.custid;
         sort_tbl(i).facility := ord.fromfacility;
         sort_tbl(i).po := ord.po;
         sort_tbl(i).loadno := ord.loadno;
         sort_tbl(i).stopno := ord.stopno;
         sort_tbl(i).shipno := ord.shipno;
         sort_tbl(i).stageloc := ord.stageloc;
      end if;

   <<continue_loop>>
      null;
   end loop;

   for i in 1..sort_tbl.count loop

      zrf.get_next_lpid(l_lpid, l_msg);
      if l_msg is not null then

         zms.log_autonomous_msg('PAPERSORT',
            sort_tbl(i).facility,
            sort_tbl(i).custid,
            'Error: '||l_msg||' getting next lpid for order '
                  ||sort_tbl(i).orderid||'-'||sort_tbl(i).shipid,
            'E',
            in_user,
            l_msg);
         out_message := 'APPMSGS';

      else
         sort_and_stage_order
            (sort_tbl(i).facility,
             sort_tbl(i).orderid,
             sort_tbl(i).shipid,
             l_lpid,
             sort_tbl(i).stageloc,
             in_user,
             l_toplpid,
             l_err,
             l_msg);

         if l_msg is not null then

            zms.log_autonomous_msg('PAPERSORT',
               sort_tbl(i).facility,
               sort_tbl(i).custid,
               'Error: '||l_msg||' picking order ' ||sort_tbl(i).orderid||'-'||sort_tbl(i).shipid,
               'E',
               in_user,
               l_msg);
            out_message := 'APPMSGS';

         else

            zrf.lpid_auto_charge('PICK', l_toplpid, in_user, l_msg);
            zrf.lpid_auto_charge('PFC', l_toplpid, in_user, l_msg);
            zrf.lpid_auto_charge('TOUR', l_toplpid, in_user, l_msg);

            zrf.cust_auto_charge('PFC',
                  sort_tbl(i).facility,
                  sort_tbl(i).custid,
                  sort_tbl(i).orderid,
                  sort_tbl(i).shipid,
                  sort_tbl(i).po,
                  sort_tbl(i).loadno,
                  sort_tbl(i).stopno,
                  sort_tbl(i).shipno,
                  in_user,
                  l_msg);

            zrf.cust_auto_charge('TOUR',
                  sort_tbl(i).facility,
                  sort_tbl(i).custid,
                  sort_tbl(i).orderid,
                  sort_tbl(i).shipid,
                  sort_tbl(i).po,
                  sort_tbl(i).loadno,
                  sort_tbl(i).stopno,
                  sort_tbl(i).shipno,
                  in_user,
                  l_msg);

            commit;

         end if;
      end if;
   end loop;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end sort_and_stage_wave;


procedure sort_and_stage_sst
   (in_facility in varchar2,
    in_orderid  in number,
    in_shipid   in number,
    in_lpid     in varchar2,
    in_stageloc in varchar2,
    in_user     in varchar2,
    out_toplpid out varchar2,
    out_error   out varchar2,
    out_message out varchar2)
is
   cursor c_lp(p_lpid varchar2) is
      select parentlpid
         from plate
         where lpid = p_lpid;

   cursor c_st(in_rowid varchar2) is
      select * from subtasks
       where rowid = chartorowid(in_rowid);
   stsk c_st%rowtype;
   l_lpcount number;
   l_err varchar2(1) := 'N';
   l_msg varchar2(80) := null;
   lam_msg varchar2(80) := null;
   l_is_loaded varchar2(1);
   l_packcnt pls_integer;

   procedure free_tasks
   is
   begin
      rollback;

      update tasks
         set curruserid = null,
             priority = prevpriority,
             lastuser = in_user,
             lastupdate = sysdate
         where orderid = in_orderid
           and shipid = in_shipid
           and priority = '0'
           and curruserid = in_user
           and tasktype = 'SO';

      commit;
   end free_tasks;
begin
   out_toplpid := null;
   out_error := 'N';
   out_message := null;

-- assign tasks to user
   update tasks
      set curruserid = in_user,
          prevpriority = priority,
          priority = 0
      where orderid = in_orderid
        and shipid = in_shipid
        and curruserid is null
        and tasktype = 'SO';

   if (sql%rowcount = 0) then
      out_message := 'Sort not available';
      return;
   end if;

   commit;

   select count(1) into l_packcnt
      from subtasks
      where orderid = in_orderid
        and shipid = in_shipid
        and tasktype = 'SO'
        and picktotype = 'PACK';

   for ss in (select SST.*,
                     SST.rowid,
                     LP.lotnumber as lplotnumber
                from simplesorttasks SST, plate LP
               where SST.orderid = in_orderid
                 and SST.shipid = in_shipid
                 and LP.lpid (+) = SST.lpid) loop
      open c_st(ss.subtaskrowid);
      fetch c_st into stsk;
      close c_st;


      if l_packcnt > 0 and stsk.picktotype != 'PACK' then
         stsk.picktotype := 'PACK';
      end if;

      zrfpk.pick_a_plate
         (stsk.taskid,
          stsk.shippinglpid,
          in_user,
          stsk.lpid,
          stsk.lpid,
          stsk.custid,
          stsk.item,
          stsk.orderitem,
          stsk.orderlot,
          ss.qty,
          0,
          stsk.facility,
          stsk.fromloc,
          stsk.uom,
          ss.lplotnumber,
          in_lpid,
          stsk.shippingtype,
          stsk.tasktype,
          stsk.picktotype,
          stsk.fromloc,
          rowidtochar(ss.subtaskrowid),
          null,
          null,
          ss.lotnumber,
          ss.serialnumber,
          ss.useritem1,
          ss.useritem2,
          ss.useritem3,
          stsk.pickuom,
          stsk.pickqty,
          stsk.weight,
          stsk.lpid,
          l_lpcount,
          l_err,
          l_msg);

      exit when l_msg is not null;
   end loop;

   if l_msg is null then
      zrfpk.stage_a_plate
         (in_lpid,
          in_stageloc,
          in_user,
          'SO',
          'N',
          in_stageloc,
          'N',
          'N',
          l_err,
          l_msg,
          l_is_loaded);
   end if;

   if l_msg is not null then
      free_tasks;
   else
      open c_lp(in_lpid);
      fetch c_lp into out_toplpid;
      close c_lp;
   end if;

   out_error := l_err;
   out_message := l_msg;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
      free_tasks;
end sort_and_stage_sst;

procedure add_extra_pick
   (in_subtask_rowid in varchar2,
    in_shlpid        in varchar2,
    in_pickqty       in number,
    in_pickuom       in varchar2,
    in_user          in varchar2,
    in_pickedlp      in varchar2,
    out_lpid         out varchar2,
    out_rowid        out varchar2,
    out_message      out varchar2)
is
   cursor c_stsk is
      select subtasks.*,
             zwt.is_ordered_by_weight(orderid, shipid, orderitem, orderlot) as orderedbyweight
         from subtasks
         where rowid = chartorowid(in_subtask_rowid);
   stsk c_stsk%rowtype;
   cursor c_lp(p_lpid varchar2) is
      select P.location, L.section, L.equipprof, L.pickingseq, L.pickingzone
         from plate P, location L
         where P.lpid = p_lpid
           and L.facility = P.facility
           and L.locid = P.location;
   lp c_lp%rowtype := null;
   xtralpid plate.lpid%type := null;
   msg varchar2(80);
   rowfound boolean;
   l_key number := 0;
   l_pickqty subtasks.pickqty%type;
   l_pickuom subtasks.pickuom%type;
   l_qty_pickuom subtasks.pickqty%type;
   l_baseuom subtasks.pickuom%type;
   l_qty integer;
begin

-- adjust original subtask
   open c_stsk;
   fetch c_stsk into stsk;
   rowfound := c_stsk%found;
   close c_stsk;
   if not rowfound then
      out_message := 'Subtask not found';
      return;
   end if;
   l_qty := zlbl.uom_qty_conv(stsk.custid, stsk.item, in_pickqty, in_pickuom, stsk.uom);
   if in_pickuom != stsk.pickuom then -- multiple serial numbers, convert to base uom
      update subtasks
         set pickqty = stsk.qty,
             pickuom = stsk.uom
         where rowid = chartorowid(in_subtask_rowid);
         stsk.pickqty := stsk.qty;
         stsk.pickuom := stsk.uom;
      update shippingplate
         set pickqty = quantity,
             pickuom = unitofmeasure
         where lpid = stsk.shippinglpid;
   end if;
   if stsk.qty = l_qty then
      update subtasks
         set weight = in_pickqty * zci.item_weight(stsk.custid, stsk.item, in_pickuom),
             cube = in_pickqty * zci.item_cube(stsk.custid, stsk.item, in_pickuom),
             lastuser = in_user,
             lastupdate = sysdate
         where rowid = chartorowid(in_subtask_rowid);
   else
      update subtasks
         set qty = qty - l_qty,
             pickqty = pickqty - in_pickqty,
             weight = (pickqty - in_pickqty)* zci.item_weight(stsk.custid, stsk.item, in_pickuom),
             cube = (pickqty - in_pickqty) * zci.item_cube(stsk.custid, stsk.item, in_pickuom),
             lastuser = in_user,
             lastupdate = sysdate
         where rowid = chartorowid(in_subtask_rowid);
   end if;

-- build a new subtask
   if (in_shlpid is not null) then
      zsp.get_next_shippinglpid(xtralpid, msg);
      if (msg is not null) then
         out_message := msg;
         return;
      end if;
   end if;

-- convert baseuom qty left into pickuom qty
   l_qty_pickuom := zlbl.uom_qty_conv(stsk.custid, stsk.item, l_qty,  stsk.uom, stsk.pickuom);
-- if exact conversion use pickuom else baseuom

   if in_pickuom != stsk.pickuom then -- multiple serial numbers, convert to base uom
      l_pickqty := l_qty;
      l_pickuom := stsk.uom;
   else
      l_pickqty := in_pickqty;
      l_pickuom := stsk.pickuom;
   end if;

   if (in_pickedlp is not null) and (stsk.lpid is not null) then
      open c_lp(in_pickedlp);
      fetch c_lp into lp;
      close c_lp;

      stsk.lpid := in_pickedlp;
      stsk.fromloc := lp.location;
      stsk.fromsection := lp.section;
      stsk.fromprofile := lp.equipprof;
      stsk.locseq := lp.pickingseq;
      stsk.pickingzone := lp.pickingzone;
   end if;

   insert into subtasks
      (taskid, tasktype, facility, fromsection,
       fromloc, fromprofile, tosection, toloc,
       toprofile, touserid, custid, item,
       lpid, uom, qty, locseq,
       loadno, stopno, shipno, orderid,
       shipid, orderitem, orderlot, priority,
       prevpriority, curruserid, lastuser, lastupdate,
       pickuom, pickqty, picktotype, wave,
       pickingzone, cartontype,
       weight,
       cube,
       staffhrs, cartonseq, shippinglpid, shippingtype,
       cartongroup, qtypicked)
   values
      (stsk.taskid, stsk.tasktype, stsk.facility, stsk.fromsection,
       stsk.fromloc, stsk.fromprofile, stsk.tosection, stsk.toloc,
       stsk.toprofile, stsk.touserid, stsk.custid, stsk.item,
       stsk.lpid, stsk.uom, l_qty, stsk.locseq,
       stsk.loadno, stsk.stopno, stsk.shipno, stsk.orderid,
       stsk.shipid, stsk.orderitem, stsk.orderlot, stsk.priority,
       stsk.prevpriority, stsk.curruserid, in_user, sysdate,
       l_pickuom, l_pickqty, stsk.picktotype, stsk.wave,
       stsk.pickingzone, stsk.cartontype,
       l_pickqty*zci.item_weight(stsk.custid, stsk.item, l_pickuom),
       l_pickqty*zci.item_cube(stsk.custid, stsk.item, l_pickuom),
       null, stsk.cartonseq, xtralpid, 'P',
       stsk.cartongroup, null)
   returning rowidtochar(rowid) into out_rowid;

-- build a new shippingplate
   if (in_shlpid is not null) then
      insert into shippingplate
         (lpid, item, custid, facility, location, status,
          holdreason, unitofmeasure, quantity, type, fromlpid,
          serialnumber, lotnumber, parentlpid, useritem1, useritem2, useritem3,
          lastuser, lastupdate, invstatus, qtyentered, orderitem, uomentered,
          inventoryclass, loadno, stopno, shipno, orderid, shipid,
          weight,
          ucc128, labelformat, taskid, dropseq, orderlot, pickuom,
          pickqty, trackingno, cartonseq, checked, totelpid,
          cartontype, pickedfromloc, shippingcost, carriercodeused,
          satdeliveryused, openfacility, audited)
      select xtralpid, S.item, S.custid, S.facility, S.location, 'U',
             S.holdreason, S.unitofmeasure, l_qty, 'P', stsk.lpid,
             S.serialnumber, S.lotnumber, null, S.useritem1, S.useritem2, S.useritem3,
             in_user, sysdate, S.invstatus, S.qtyentered, S.orderitem, S.uomentered,
             S.inventoryclass, S.loadno, S.stopno, S.shipno, S.orderid, S.shipid,
             l_pickqty*zci.item_weight(S.custid, S.item, l_pickuom),
             null, null, S.taskid, S.dropseq, S.orderlot, l_pickuom,
             in_pickqty, S.trackingno, S.cartonseq, S.checked, S.totelpid,
             S.cartontype, S.pickedfromloc, S.shippingcost, S.carriercodeused,
             S.satdeliveryused, S.openfacility, S.audited
         from shippingplate S
         where S.lpid = in_shlpid;

      update shippingplate
         set quantity = quantity - l_qty,
             pickqty = pickqty - in_pickqty,
             weight = (pickqty - in_pickqty)* zci.item_weight(stsk.custid, stsk.item, in_pickuom),
             lastuser = in_user,
             lastupdate = sysdate
         where lpid = in_shlpid;
   end if;
   out_lpid := xtralpid;
exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end add_extra_pick;


end simplesort;
/

show errors package body simplesort;
exit;
