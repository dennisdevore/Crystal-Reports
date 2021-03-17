create or replace package body alps.rfpicking as
--
-- $Id$
--


-- Types


type anylptype is record (
   lpid plate.lpid%type,
   quantity plate.quantity%type,
   invstatus plate.invstatus%type,
   invclass plate.inventoryclass%type,
   serialnumber plate.serialnumber%type,
   useritem1 plate.useritem1%type,
   useritem2 plate.useritem2%type,
   useritem3 plate.useritem3%type,
   parentlpid plate.parentlpid%type,
   weight plate.weight%type,
   manufacturedate plate.manufacturedate%type,
   expirationdate plate.expirationdate%type);
type anylpcur is ref cursor return anylptype;

type anysubtasktype is record (
   rid rowid);
type anysubtaskcur is ref cursor return anysubtasktype;

type anytasktype is record (
   taskid tasks.taskid%type,
   tasktype tasks.tasktype%type,
   picktotype tasks.picktotype%type);
type anytaskcur is ref cursor return anytasktype;

type tidtbltype is table of tasks.taskid%type index by binary_integer;

type ordrectype is record (
   orderid orderhdr.orderid%type,
   shipid orderhdr.shipid%type);
type ordtbltype is table of ordrectype index by binary_integer;

type cworectype is record (
   custid shippingplate.custid%type,
   item shippingplate.item%type,
   qty shippingplate.quantity%type);
type cwotbltype is table of cworectype index by binary_integer;


-- Global variables


tid_tbl tidtbltype;
ord_tbl ordtbltype;
cwo_tbl cwotbltype;


-- Private procedures


procedure add_cwo_to_tbl
   (in_custid in varchar2,
    in_item   in varchar2,
    in_qty    in number)
is
   i binary_integer;
begin
   for i in 1..cwo_tbl.count loop
      if ((cwo_tbl(i).custid = in_custid) and (cwo_tbl(i).item = in_item)) then
         cwo_tbl(i).qty := cwo_tbl(i).qty + in_qty;
         return;
      end if;
   end loop;
   i := cwo_tbl.count+1;
   cwo_tbl(i).custid := in_custid;
   cwo_tbl(i).item := in_item;
   cwo_tbl(i).qty := in_qty;
end add_cwo_to_tbl;


procedure add_tid_to_tbl
   (in_taskid in varchar2)
is
   i binary_integer;
begin
   for i in 1..tid_tbl.count loop
      if (tid_tbl(i) = in_taskid) then
         return;
      end if;
   end loop;
   tid_tbl(tid_tbl.count+1) := in_taskid;
end add_tid_to_tbl;


procedure add_ord_to_tbl
   (in_orderid in number,
    in_shipid  in number)
is
   i binary_integer;
begin
   if (nvl(in_orderid, 0) != 0) then
      for i in 1..ord_tbl.count loop
         if ((ord_tbl(i).orderid = in_orderid) and (ord_tbl(i).shipid = in_shipid)) then
            return;
         end if;
      end loop;
      i := ord_tbl.count+1;
      ord_tbl(i).orderid := in_orderid;
      ord_tbl(i).shipid := in_shipid;
   end if;
end add_ord_to_tbl;


procedure add_ctn_to_tbls
   (in_ctnid in varchar2)
is
   cursor c_kids is
      select taskid, orderid, shipid
         from shippingplate
         where parentlpid = in_ctnid;
begin
   for k in c_kids loop
      add_tid_to_tbl(k.taskid);
      add_ord_to_tbl(k.orderid, k.shipid);
   end loop;
end add_ctn_to_tbls;


procedure check_all_picked
   (in_orderid  in number,
    in_shipid   in number,
    in_user     in varchar2,
    out_message out varchar2)
is
   cursor c_oh(p_orderid number, p_shipid number) is
      select ordertype, parentorderid, parentshipid, loadno, stopno, fromfacility
         from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   oh c_oh%rowtype := null;
   poh c_oh%rowtype := null;
   cnt integer;
begin
   out_message := null;

   open c_oh(in_orderid, in_shipid);
   fetch c_oh into oh;
   close c_oh;
   if (oh.parentorderid is not null) and (oh.parentshipid is not null) then
      open c_oh(oh.parentorderid, oh.parentshipid);
      fetch c_oh into poh;
      close c_oh;
   end if;

   update orderhdr
      set orderstatus = zrf.ORD_PICKED,
          lastuser = in_user,
          lastupdate = sysdate
      where orderid = in_orderid
        and shipid = in_shipid
        and orderstatus < zrf.ORD_PICKED
        and qtycommit = 0;

   if (sql%rowcount != 0) then
      if ((oh.parentorderid is not null) and (oh.parentshipid is not null)
      and (poh.ordertype = 'W')) then
         update orderhdr
            set orderstatus = zrf.ORD_PICKED,
                lastuser = in_user,
                lastupdate = sysdate
            where orderid = oh.parentorderid
              and shipid = oh.parentshipid
              and orderstatus < zrf.ORD_PICKED;
      end if;
      if (oh.loadno is not null) then
         select count(1) into cnt
            from orderhdr
            where loadno = oh.loadno
              and stopno = oh.stopno
              and fromfacility = oh.fromfacility
              and orderstatus < zrf.ORD_PICKED;
         if (cnt = 0) then
            update loadstop
               set loadstopstatus = zrf.LOD_PICKED,
                   lastuser = in_user,
                   lastupdate = sysdate
               where loadno = oh.loadno
                 and stopno = oh.stopno
                 and loadstopstatus < zrf.LOD_PICKED;
            select count(1) into cnt
               from loadstop
               where loadno = oh.loadno
                 and loadstopstatus < zrf.LOD_PICKED;
            if (cnt = 0) then
               update loads
                  set loadstatus = zrf.LOD_PICKED,
                      lastuser = in_user,
                      lastupdate = sysdate
                  where loadno = oh.loadno
                    and loadstatus < zrf.LOD_PICKED;
            end if;
         end if;
      end if;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end check_all_picked;


procedure bld_kit_partial
   (in_shiplp   in varchar2,
    in_pickedlp in varchar2,
    in_kitlp    in varchar2,
    in_qty      in number,
    in_user     in varchar2,
    in_tasktype in varchar2,
    in_taskid   in number,
    in_pickfac  in varchar2,
    in_pickloc  in varchar2,
    in_custid   in varchar2,
    in_item     in varchar2,
    in_lot      in varchar2,
    in_uom      in varchar2,
    in_orderid  in number,
    in_shipid   in number,
    out_error   out varchar2,
    out_message out varchar2)
is
   msg varchar2(80) := null;
   c_any_lp anylpcur;
   l anylptype;
   rowfound boolean;
   cursor c_lp (p_lp varchar2) is
      select P.lpid, P.type, P.item, P.custid, P.unitofmeasure, P.serialnumber, P.lotnumber,
             P.quantity, P.expirationdate, P.useritem1, P.useritem2, P.useritem3, P.invstatus,
             P.inventoryclass, nvl(S.orderid,0) orderid, nvl(S.shipid,0) shipid,
             P.anvdate
         from plate P, shippingplate S
         where P.lpid = p_lp
           and S.fromlpid (+) = P.lpid
           and S.facility (+) = P.facility;
   plp c_lp%rowtype;
   klp c_lp%rowtype;
   cursor c_kid is
      select lpid
         from plate
         where custid = plp.custid
           and item = plp.item
           and type = 'PA'
           and invstatus = plp.invstatus
           and inventoryclass = plp.inventoryclass
           and unitofmeasure = plp.unitofmeasure
           and expirationdate = plp.expirationdate
           and nvl(serialnumber, '(none)') = nvl(plp.serialnumber, '(none)')
           and nvl(lotnumber, '(none)') = nvl(plp.lotnumber, '(none)')
           and nvl(useritem1, '(none)') = nvl(plp.useritem1, '(none)')
           and nvl(useritem2, '(none)') = nvl(plp.useritem2, '(none)')
           and nvl(useritem3, '(none)') = nvl(plp.useritem3, '(none)')
         start with lpid = in_kitlp
         connect by prior lpid = parentlpid;
   kid c_kid%rowtype;
   cursor c_itemview is
     select serialrequired, serialasncapture, user1required, user1asncapture,
            user2required, user2asncapture, user3required, user3asncapture
      from custitemview
      where custid = in_custid
        and item = in_item;
   itv c_itemview%rowtype;
   newlpid plate.lpid%type;
begin
   out_error := 'N';
   out_message := null;

   if (in_pickedlp is not null) then
      open c_lp(in_pickedlp);
      fetch c_lp into plp;
      close c_lp;
      if (plp.type = 'PA') then

--       taking from a plate - use it
         if (in_qty > plp.quantity) then
            out_message := 'Qty not avail';
            return;
         end if;
         l.lpid := in_pickedlp;

      else

--       taking from a multi-plate - find a child to use
         if (in_lot is null) then
            open c_any_lp for
               select lpid, quantity, invstatus, inventoryclass, serialnumber,
                      useritem1, useritem2, useritem3, parentlpid, weight,
                      manufacturedate, expirationdate
                  from plate
                  where custid = in_custid
                    and item = in_item
                    and unitofmeasure = in_uom
                    and type = 'PA'
                  start with lpid = in_pickedlp
                  connect by prior lpid = parentlpid
                  order by manufacturedate, creationdate;
         else
            open c_any_lp for
               select lpid, quantity, invstatus, inventoryclass, serialnumber,
                      useritem1, useritem2, useritem3, parentlpid, weight,
                      manufacturedate, expirationdate
                  from plate
                  where custid = in_custid
                    and item = in_item
                    and lotnumber = in_lot
                    and unitofmeasure = in_uom
                    and type = 'PA'
                  start with lpid = in_pickedlp
                  connect by prior lpid = parentlpid
                  order by manufacturedate, creationdate;
         end if;
         fetch c_any_lp into l;
         rowfound := c_any_lp%found;
         close c_any_lp;

         if not rowfound then
            out_message := 'Qty not avail';
            return;
         end if;
      end if;
   else

--    taking from a pick front - find an lp to use
      if (in_lot is null) then
         open c_any_lp for
            select lpid, quantity, invstatus, inventoryclass, serialnumber,
                   useritem1, useritem2, useritem3, parentlpid, weight,
                   manufacturedate, expirationdate
               from plate
               where facility = in_pickfac
                 and location = in_pickloc
                 and custid = in_custid
                 and item = in_item
                 and unitofmeasure = in_uom
                 and type = 'PA'
                 and status = 'A'
               order by manufacturedate, creationdate;
      else
         open c_any_lp for
            select lpid, quantity, invstatus, inventoryclass, serialnumber,
                   useritem1, useritem2, useritem3, parentlpid, weight,
                   manufacturedate, expirationdate
               from plate
               where facility = in_pickfac
                 and location = in_pickloc
                 and custid = in_custid
                 and item = in_item
                 and lotnumber = in_lot
                 and unitofmeasure = in_uom
                 and type = 'PA'
                 and status = 'A'
               order by manufacturedate, creationdate;
      end if;

      open c_itemview;
      fetch c_itemview into itv;
      close c_itemview;

      loop
         fetch c_any_lp into l;
         rowfound := c_any_lp%found;
         exit when not rowfound;

         if ((l.serialnumber is not null
               and itv.serialrequired != 'Y' and itv.serialasncapture = 'Y')
         or  (l.useritem1 is not null
               and itv.user1required != 'Y' and itv.user1asncapture = 'Y')
         or  (l.useritem2 is not null
               and itv.user2required != 'Y' and itv.user2asncapture = 'Y')
         or  (l.useritem3 is not null
               and itv.user3required != 'Y' and itv.user3asncapture = 'Y')
         or  (zrf.any_tasks_for_lp(l.lpid, l.parentlpid))) then
            goto continue_loop;
         end if;

         exit;

      <<continue_loop>>
         null;
      end loop;
      close c_any_lp;

      if not rowfound then
         out_message := 'Qty not avail';
         return;
      end if;
   end if;

-- get all info for selected plate
   open c_lp(l.lpid);
   fetch c_lp into plp;
   close c_lp;

   open c_lp(in_kitlp);
   fetch c_lp into klp;
   if c_lp%notfound then
      klp.type := '?';
   end if;
   close c_lp;

   if (klp.type = '?') then

--    adding to a new plate
      rfbp.dupe_lp(zplp.type_pa_lpid(plp.lpid, in_custid, in_item, in_lot), in_kitlp,
            in_user, 'P', in_qty, in_user, null, in_tasktype, in_taskid, msg);

   else

      if (klp.orderid != in_orderid) or (klp.shipid != in_shipid) then
         out_message := 'Not for order';
         return;
      end if;

--    adding to an existing plate
      if (klp.type = 'PA') then

--       compatible - just update qty
         if ((klp.item = plp.item)
         and (klp.custid = plp.custid)
         and (klp.invstatus = plp.invstatus)
         and (klp.inventoryclass = plp.inventoryclass)
         and (klp.unitofmeasure = plp.unitofmeasure)
         and (klp.expirationdate = plp.expirationdate)
         and (nvl(klp.anvdate,sysdate) = nvl(plp.anvdate,sysdate))
         and (nvl(klp.serialnumber, '(none)') = nvl(plp.serialnumber, '(none)'))
         and (nvl(klp.lotnumber, '(none)') = nvl(plp.lotnumber, '(none)'))
         and (nvl(klp.useritem1, '(none)') = nvl(plp.useritem1, '(none)'))
         and (nvl(klp.useritem2, '(none)') = nvl(plp.useritem2, '(none)'))
         and (nvl(klp.useritem3, '(none)') = nvl(plp.useritem3, '(none)'))) then

            update plate
               set quantity = quantity + in_qty
               where lpid = in_kitlp;

            plp.lpid := null;
         else
--       plate is not a multi - make it so...
            zplp.morph_lp_to_multi(in_kitlp, in_user, msg);
         end if;

      else
--       try to find compatible child on multi

         open c_kid;
         fetch c_kid into kid;
         rowfound := c_kid%found;
         close c_kid;

         if rowfound then
--          found one - use it

            update plate
               set quantity = quantity + in_qty
               where lpid = kid.lpid;

            plp.lpid := null;
         end if;
      end if;

      if ((msg is null) and (plp.lpid is not null)) then
         zrf.get_next_lpid(newlpid, msg);
         if (msg is null) then
            rfbp.dupe_lp(zplp.type_pa_lpid(plp.lpid, in_custid, in_item, in_lot), newlpid,
                  in_user, 'P', in_qty, in_user, null, in_tasktype, in_taskid, msg);
            if (msg is null) then
               zplp.attach_child_plate(in_kitlp, newlpid, in_user, 'P', in_user, msg);
            end if;
         end if;
      end if;
   end if;

   if (msg is not null) then
      out_error := 'Y';
      out_message := msg;
      return;
   end if;

   update shippingplate
      set fromlpid = in_kitlp
      where lpid = in_shiplp;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end bld_kit_partial;


procedure explode_multi_lp
   (in_shiplp     in varchar2,
    in_mastlp     in varchar2,
    in_multilp    in varchar2,
    in_user       in varchar2,
    in_picktotype in varchar2,
    out_message   out varchar2)
is
   cursor c_ship is
      select *
         from shippingplate
         where lpid = in_shiplp;
   s c_ship%rowtype;
   cursor c_lps is
      select lpid, quantity, weight, serialnumber, lotnumber, useritem1,
             useritem2, useritem3, manufacturedate, expirationdate
         from plate
         where type = 'PA'
         start with lpid = in_multilp
         connect by prior lpid = parentlpid;
   msg varchar2(80) := null;
   clip shippingplate.lpid%type;
   parentlp shippingplate.parentlpid%type := nvl(in_mastlp, in_shiplp);
   v_count number;
begin
   out_message := null;

   if (in_shiplp is null) then
      return;
   end if;

   open c_ship;
   fetch c_ship into s;
   close c_ship;

-- build a child shippingplate for each child of the multi
   for p in c_lps loop
      if ((c_lps%rowcount = 1) and (in_mastlp is not null)) then

--       (re)use the original shippingplate
         update shippingplate
            set quantity = p.quantity,
                fromlpid = p.lpid,
                serialnumber = p.serialnumber,
                parentlpid = in_mastlp,
                lastuser = in_user,
                lastupdate = sysdate,
                qtyentered = p.quantity,
                weight = p.weight,
                pickqty = p.quantity,
                lotnumber = p.lotnumber,
                useritem1 = p.useritem1,
                useritem2 = p.useritem2,
                useritem3 = p.useritem3,
                manufacturedate = p.manufacturedate,
                expirationdate = p.expirationdate
            where lpid = in_shiplp;
      else
         if (c_lps%rowcount = 1) then

--          convert original shippingplate to a "parent"
            update shippingplate
               set type = decode(in_picktotype, 'PACK', 'C', 'M'),
                   lastuser = in_user,
                   lastupdate = sysdate,
                   fromlpidparent = null
               where lpid = in_shiplp;

            select count(distinct lotnumber)
			  into v_count
              from plate
             where lotnumber is not null
             start with lpid = in_multilp
            connect by parentlpid = prior lpid;
            
            if (v_count > 1) then
              update shippingplate
              set lotnumber = null
              where lpid = in_shiplp;
            end if;
			   
         end if;

--       build a new shippingplate
         zsp.get_next_shippinglpid(clip, msg);
         if (msg is not null) then
            out_message := msg;
            return;
         end if;

         insert into shippingplate
            (lpid, item, custid, facility, location, status,
             holdreason, unitofmeasure, quantity, type, fromlpid, serialnumber,
             lotnumber, parentlpid, useritem1, useritem2, useritem3, lastuser,
             lastupdate, invstatus, qtyentered, orderitem, uomentered, inventoryclass,
             loadno, stopno, shipno, orderid, shipid, weight,
             ucc128, labelformat, taskid, dropseq, orderlot, pickuom,
             pickqty, trackingno, cartonseq, checked, totelpid, cartontype,
             pickedfromloc, shippingcost, carriercodeused, satdeliveryused,
             openfacility, fromlpidparent, manufacturedate, expirationdate)
         values
            (clip, s.item, s.custid, s.facility, s.location, s.status,
             s.holdreason, s.unitofmeasure, p.quantity, s.type, p.lpid, p.serialnumber,
             p.lotnumber, parentlp, p.useritem1, p.useritem2, p.useritem3, in_user,
             sysdate, s.invstatus, p.quantity, s.orderitem, s.uomentered, s.inventoryclass,
             s.loadno, s.stopno, s.shipno, s.orderid, s.shipid, p.weight,
             s.ucc128, s.labelformat, s.taskid, s.dropseq, s.orderlot, s.pickuom,
             p.quantity, s.trackingno, s.cartonseq, s.checked, s.totelpid, s.cartontype,
             s.pickedfromloc, s.shippingcost, s.carriercodeused, s.satdeliveryused,
             s.openfacility, in_multilp, p.manufacturedate, p.expirationdate);
      end if;
   end loop;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end explode_multi_lp;


procedure trace_msg
   (in_author   in varchar2,
    in_facility in varchar2,
    in_custid   in varchar2,
    in_user     in varchar2,
    in_msg      in varchar2)
is
   msg varchar2(255);
   pragma autonomous_transaction;
begin
   zms.log_msg(in_author, in_facility, in_custid, in_msg, 'T', in_user, msg);
   commit;
exception
   when others then
      rollback;
end trace_msg;


procedure adjust_subtask_tree
   (in_taskid    in number,
    in_facility  in varchar2,
    in_drop_loc  in varchar2,
    in_stage_loc in varchar2,
    in_user      in varchar2,
    out_message  out varchar2)
is
   cursor c_loc(p_facility varchar2, p_locid varchar2) is
      select loctype, section, equipprof, pickingseq
         from location
         where facility = p_facility
           and locid = p_locid;
   drp c_loc%rowtype;
   stg c_loc%rowtype;
   cursor c_tsk(p_taskid number) is
      select *
         from tasks
         where taskid = p_taskid;
   tsk c_tsk%rowtype;
   i binary_integer;
   l_cnt pls_integer;
   l_cntall pls_integer;
   l_msg varchar2(80);
begin
   out_message := null;

   select count(1) into l_cnt
      from subtasks
      where taskid = in_taskid
        and nvl(step1_complete,'N') = 'Y';
   if l_cnt = 0 then
      return;
   end if;

   open c_loc(in_facility, in_drop_loc);
   fetch c_loc into drp;
   close c_loc;

   open c_loc(in_facility, in_stage_loc);
   fetch c_loc into stg;
   close c_loc;

   select count(1) into l_cntall
      from subtasks
      where taskid = in_taskid;

   if l_cnt = l_cntall then         -- can re-use task and all subtasks
      update subtasks
         set priority = decode(drp.loctype, 'PND', prevpriority, '5'),
             curruserid = null,
             touserid = null,
             fromsection = drp.section,
             fromloc = in_drop_loc,
             fromprofile = drp.equipprof,
             tosection = stg.section,
             toloc = in_stage_loc,
             toprofile = stg.equipprof,
             locseq = nvl(stg.pickingseq,0),
             lastuser = in_user,
             lastupdate = sysdate
         where taskid = in_taskid;
      update tasks
         set priority = decode(drp.loctype, 'PND', prevpriority, '5'),
             curruserid = null,
             touserid = null,
             fromsection = drp.section,
             fromloc = in_drop_loc,
             fromprofile = drp.equipprof,
             tosection = stg.section,
             toloc = in_stage_loc,
             toprofile = stg.equipprof,
             locseq = nvl(stg.pickingseq,0),
             lastuser = in_user,
             lastupdate = sysdate,
             step1_complete = 'Y'
         where taskid = in_taskid;
      return;
   end if;

   open c_tsk(in_taskid);
   fetch c_tsk into tsk;
   close c_tsk;

   ztsk.get_next_taskid(tsk.taskid, l_msg);
   l_cnt := 0;

   for st in (select qty, weight, pickqty, cube, staffhrs, rowid, item, uom,
                     orderid, shipid, orderitem, orderlot, pickuom, lpid,
                     shippinglpid
               from subtasks
               where taskid = in_taskid
                 and nvl(step1_complete,'N') = 'Y') loop
      update subtasks
         set taskid = tsk.taskid,
             priority = decode(drp.loctype, 'PND', prevpriority, '5'),
             curruserid = null,
             touserid = null,
             fromsection = drp.section,
             fromloc = in_drop_loc,
             fromprofile = drp.equipprof,
             tosection = stg.section,
             toloc = in_stage_loc,
             toprofile = stg.equipprof,
             locseq = nvl(stg.pickingseq,0),
             lastuser = in_user,
             lastupdate = sysdate
         where rowid = st.rowid;

      update tasks
         set qty = qty - st.qty,
             weight = weight - st.weight,
             pickqty = pickqty - st.pickqty,
             cube = cube - st.cube,
             staffhrs = staffhrs - st.staffhrs,
             lastuser = in_user,
             lastupdate = sysdate
         where taskid = in_taskid;

      update shippingplate
         set taskid = tsk.taskid,
             lastuser = in_user,
             lastupdate = sysdate
         where lpid in (select lpid from shippingplate
                  start with lpid = st.shippinglpid
                  connect by prior parentlpid = lpid);

      l_cnt := l_cnt + 1;
      if l_cnt = 1 then
         tsk.item := st.item;
         tsk.lpid := st.lpid;
         tsk.uom := st.uom;
         tsk.qty := st.qty;
         tsk.orderid := st.orderid;
         tsk.shipid := st.shipid;
         tsk.orderitem := st.orderitem;
         tsk.orderlot := st.orderlot;
         tsk.pickuom := st.pickuom;
         tsk.pickqty := st.pickqty;
         tsk.weight := st.weight;
         tsk.cube := st.cube;
         tsk.staffhrs := st.staffhrs;
      else
         tsk.qty := tsk.qty + st.qty;
         tsk.pickqty := tsk.pickqty + st.pickqty;
         tsk.weight := tsk.weight + st.weight;
         tsk.cube := tsk.cube + st.cube;
         tsk.staffhrs := tsk.staffhrs + st.staffhrs;

         if tsk.item != st.item then
            tsk.item := null;
         end if;
         if tsk.uom != st.uom then
            tsk.uom := null;
         end if;
         if tsk.lpid != st.lpid then
            tsk.lpid := null;
         end if;
         if tsk.orderitem != st.orderitem then
            tsk.orderitem := null;
         end if;
         if tsk.orderlot != st.orderlot then
            tsk.orderlot := null;
         end if;
         if tsk.pickuom != st.pickuom then
            tsk.pickuom := null;
         end if;

         if tsk.orderid != st.orderid then
            tsk.orderid := null;
            tsk.shipid := null;
         elsif tsk.shipid != st.shipid then
            tsk.shipid := null;
         end if;
      end if;
   end loop;

   insert into tasks
      (taskid, tasktype, facility, fromsection, fromloc,
       fromprofile, tosection, toloc, toprofile, touserid,
       custid, item, lpid, uom, qty,
       locseq, loadno, stopno, shipno, orderid,
       shipid, orderitem, orderlot,
       priority, prevpriority, curruserid,
       lastuser, lastupdate, pickuom, pickqty, picktotype,
       wave, pickingzone, cartontype, weight, cube,
       staffhrs, cartonseq, clusterposition, convpickloc, step1_complete)
   values
      (tsk.taskid, tsk.tasktype, tsk.facility, drp.section, in_drop_loc,
       drp.equipprof, stg.section, in_stage_loc, stg.equipprof, null,
       tsk.custid, tsk.item, tsk.lpid, tsk.uom, tsk.qty,
       nvl(stg.pickingseq,0), tsk.loadno, tsk.stopno,  tsk.shipno, tsk.orderid,
       tsk.shipid, tsk.orderitem, tsk.orderlot,
       decode(drp.loctype, 'PND', tsk.prevpriority, '5'), tsk.prevpriority, null,
       in_user, sysdate, tsk.pickuom, tsk.pickqty, tsk.picktotype,
       tsk.wave, tsk.pickingzone, tsk.cartontype, tsk.weight, tsk.cube,
       tsk.staffhrs, tsk.cartonseq, tsk.clusterposition, tsk.convpickloc, 'Y');

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end adjust_subtask_tree;


procedure check_mlip
   (in_mlip       in varchar2,
    in_custid     in varchar2,
    in_orderid    in number,
    in_shipid     in number,
    in_loadno     in number,
    in_stopno     in number,
    in_picktotype in varchar2,
    in_ordertype  in varchar2,
    in_mixed_ok   in varchar2,
    out_error     out varchar2,
    out_message   out varchar2)
is
   cursor c_sp(p_lpid varchar2) is
      select nvl(orderid,0) as orderid, nvl(shipid,0) as shipid,
             nvl(loadno,0) as loadno, nvl(stopno,0) as stopno
         from shippingplate
         where lpid = p_lpid;
   sp c_sp%rowtype;
   l_lptype plate.type%type;
   l_xrefid plate.lpid%type;
   l_xreftype plate.type%type;
   l_parentid plate.lpid%type;
   l_parenttype plate.type%type;
   l_topid plate.lpid%type;
   l_toptype plate.type%type;
   l_slip shippingplate.lpid%type;
   l_msg varchar2(80);
   l_cnt integer;
begin
-- checks that were done in syspick() and syspick2() are now performed here in
-- case the order was split

   out_error := 'N';
   out_message := null;

   if in_ordertype = 'K' then
      return;           -- kit order checks done elsewhere
   end if;

   zrf.identify_lp(in_mlip, l_lptype, l_xrefid, l_xreftype, l_parentid, l_parenttype,
         l_topid, l_toptype, l_msg);

   if l_msg is not null then
      out_error := 'Y';
      out_message := l_msg;
      return;
   end if;

   if l_lptype = 'DP' then
      out_message := 'LP is deleted';
      return;
   end if;

   if l_lptype = '?' then
      return;           -- new mlip no checks needed
   end if;

   l_slip := nvl(l_topid, nvl(l_parentid, nvl(l_xrefid, in_mlip)));

   open c_sp(l_slip);
   fetch c_sp into sp;
   close c_sp;

   if sp.loadno != in_loadno then
      out_message := 'Not for load';
      return;
   end if;

   if sp.stopno != in_stopno then
      out_message := 'Not for stop';
      return;
   end if;

   if nvl(in_picktotype,'??') = 'TOTE' then
    -- Verify we are not mixing customers in the tote
        l_cnt := 0;
        select count(1)
          into l_cnt
          from plate
         where parentlpid = in_mlip
           and custid != in_custid;
        if nvl(l_cnt, 0) > 0 then
            out_message := 'Can''t mix customers';
        end if;
      return;           -- no further checks for tote
   end if;

   if (sp.orderid = in_orderid) and (sp.shipid = in_shipid) then
      return;           -- same orders, OK to mix
   elsif in_mixed_ok = 'N' then
      out_message := 'Can''t mix orders';
      return;
   end if;

   if (sp.loadno = in_loadno) and (sp.loadno != 0) then
      return;           -- same assigned load, OK to mix
   end if;

-- orders are different and either 1 of the orders has no assigned load
-- or the orders are assigned to different loads

   out_message := 'Can''t mix orders';

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end check_mlip;

procedure check_mlip_cons
   (in_mlip       in varchar2,
    in_custid     in varchar2,
    in_orderid    in number,
    in_shipid     in number,
    in_loadno     in number,
    in_stopno     in number,
    in_picktotype in varchar2,
    in_ordertype  in varchar2,
    in_consorderid in varchar2,
    out_error     out varchar2,
    out_message   out varchar2)
is
   cursor c_sp(p_lpid varchar2) is
      select nvl(orderid,0) as orderid, nvl(shipid,0) as shipid,
             nvl(loadno,0) as loadno, nvl(stopno,0) as stopno
         from shippingplate
         where lpid = p_lpid;
   sp c_sp%rowtype;
   l_lptype plate.type%type;
   l_xrefid plate.lpid%type;
   l_xreftype plate.type%type;
   l_parentid plate.lpid%type;
   l_parenttype plate.type%type;
   l_topid plate.lpid%type;
   l_toptype plate.type%type;
   l_slip shippingplate.lpid%type;
   l_msg varchar2(80);
   l_cnt integer;
begin

   out_error := 'N';
   out_message := null;
   if nvl(in_consorderid,0) <> 0 then
       select count(1) into l_cnt
          from orderhdr where
          original_wave_before_combine = in_consorderid;
      if l_cnt = 0 then
         return;
      end if;
   end if;

   if in_ordertype = 'K' then
      return;           -- kit order checks done elsewhere
   end if;

   zrf.identify_lp(in_mlip, l_lptype, l_xrefid, l_xreftype, l_parentid, l_parenttype,
         l_topid, l_toptype, l_msg);

   if l_msg is not null then
      out_error := 'Y';
      out_message := l_msg;
      return;
   end if;

   if l_lptype = 'DP' then
      out_message := 'LP is deleted';
      return;
   end if;

   if l_lptype = '?' then
      return;           -- new mlip no checks needed
   end if;

   l_slip := nvl(l_topid, nvl(l_parentid, nvl(l_xrefid, in_mlip)));

   open c_sp(l_slip);
   fetch c_sp into sp;
   close c_sp;

   if sp.loadno != in_loadno then
      out_message := 'Not for load';
      return;
   end if;

   if sp.stopno != in_stopno then
      out_message := 'Not for stop';
      return;
   end if;

   out_message := 'Can''t mix orders';

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end check_mlip_cons;

procedure track_pf_lp
   (in_iteration     in number,
    in_shlpid        in varchar2,
    in_lpid          in varchar2,
    in_quantity      in number,
    in_weight        in number,
    in_pkd_lotno     in varchar2,
    in_pkd_serialno  in varchar2,
    in_pkd_user1     in varchar2,
    in_pkd_user2     in varchar2,
    in_pkd_user3     in varchar2,
    out_message      out varchar2)
is
   cursor c_sp(p_lpid varchar2) is
      select *
         from shippingplate
         where lpid = p_lpid;
   sp c_sp%rowtype := null;
   cursor c_lp(p_lpid varchar2) is
      select lotnumber, serialnumber, useritem1, useritem2, useritem3,
             inventoryclass, invstatus, parentlpid, manufacturedate,
             expirationdate
         from plate
         where lpid = p_lpid;
   lp c_lp%rowtype := null;
   l_lpid shippingplate.lpid%type;
   l_msg varchar2(80);
   l_pickqty subtasks.pickqty%type;
   l_pickuom subtasks.pickuom%type;
   l_qty_pickuom subtasks.pickqty%type;
   l_child_lots number;
   l_child_weight number;
begin
   out_message := null;

   open c_lp(in_lpid);
   fetch c_lp into lp;
   close c_lp;

   open c_sp(in_shlpid);
   fetch c_sp into sp;
   close c_sp;

-- convert baseuom qty into pickuom qty
   l_qty_pickuom := zlbl.uom_qty_conv(sp.custid, sp.item, in_quantity,
         sp.unitofmeasure, sp.pickuom);
-- if exact conversion use pickuom else baseuom
   if in_quantity = zlbl.uom_qty_conv(sp.custid, sp.item, l_qty_pickuom,
         sp.pickuom, sp.unitofmeasure) then
      l_pickqty := l_qty_pickuom;
      l_pickuom := sp.pickuom;
   else
      l_pickqty := in_quantity;
      l_pickuom := sp.unitofmeasure;
   end if;

-- first plate from pf, just update original shippingplate
   if in_iteration = 1 then
      update shippingplate
         set quantity = in_quantity,
             fromlpid = in_lpid,
             serialnumber = nvl(in_pkd_serialno, lp.serialnumber),
             lotnumber = nvl(in_pkd_lotno, lp.lotnumber),
             useritem1 = nvl(in_pkd_user1, lp.useritem1),
             useritem2 = nvl(in_pkd_user2, lp.useritem2),
             useritem3 = nvl(in_pkd_user3, lp.useritem3),
             invstatus = lp.invstatus,
             qtyentered = in_quantity,
             uomentered = unitofmeasure,
             inventoryclass = lp.inventoryclass,
             weight = in_weight,
             pickuom = l_pickuom,
             pickqty = l_pickqty,
             fromlpidparent = lp.parentlpid,
             manufacturedate = lp.manufacturedate,
             expirationdate = lp.expirationdate
         where lpid = in_shlpid;
   else
      zsp.get_next_shippinglpid(l_lpid, l_msg);
      if l_msg is not null then
         out_message := l_msg;
      else
         insert into shippingplate
            (lpid, item, custid, facility, location,
             status, holdreason, unitofmeasure, quantity, type,
             fromlpid, serialnumber, lotnumber,
             parentlpid, useritem1, useritem2,
             useritem3, lastuser, lastupdate, invstatus,
             qtyentered, orderitem, uomentered, inventoryclass, loadno,
             stopno, shipno, orderid, shipid, weight,
             ucc128, labelformat, taskid, dropseq, orderlot,
             pickuom, pickqty, trackingno, cartonseq, checked,
             totelpid, cartontype, pickedfromloc, shippingcost, carriercodeused,
             satdeliveryused, openfacility, audited, prevlocation, fromlpidparent,
             rmatrackingno, actualcarrier, manufacturedate, expirationdate)
         values
            (l_lpid, sp.item, sp.custid, sp.facility, sp.location,
             sp.status, sp.holdreason, sp.unitofmeasure, in_quantity, sp.type,
             in_lpid, nvl(in_pkd_serialno, lp.serialnumber), nvl(in_pkd_lotno, lp.lotnumber),
             sp.parentlpid, nvl(in_pkd_user1, lp.useritem1), nvl(in_pkd_user2, lp.useritem2),
             nvl(in_pkd_user3, lp.useritem3), sp.lastuser, sysdate, lp.invstatus,
             in_quantity, sp.orderitem, sp.unitofmeasure, lp.inventoryclass, sp.loadno,
             sp.stopno, sp.shipno, sp.orderid, sp.shipid, in_weight,
             sp.ucc128, sp.labelformat, sp.taskid, sp.dropseq, sp.orderlot,
             l_pickuom, l_pickqty, sp.trackingno, sp.cartonseq, sp.checked,
             sp.totelpid, sp.cartontype, sp.pickedfromloc, sp.shippingcost, sp.carriercodeused,
             sp.satdeliveryused, sp.openfacility, sp.audited, sp.prevlocation, lp.parentlpid,
             sp.rmatrackingno, sp.actualcarrier, lp.manufacturedate, lp.expirationdate);
      end if;

      if (sp.parentlpid is not null) then
        select count(distinct lotnumber), sum(weight) into l_child_lots, l_child_weight
        from shippingplate
        where type in ('P','F')
        start with lpid = sp.parentlpid
        connect by parentlpid = prior lpid;

        update shippingplate
        set weight = l_child_weight, lotnumber = decode(nvl(l_child_lots,0),1,lotnumber,null)
        where lpid = sp.parentlpid;
      end if;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end track_pf_lp;


procedure putaway_flex_item
   (in_wave     in number,
    in_custid   in varchar2,
    in_item     in varchar2,
    in_facility in varchar2,
    in_location in varchar2)
is
   l_cnt pls_integer := 0;
begin
   select count(1) into l_cnt
      from orderhdr OH, shippingplate SP
      where OH.wave = in_wave
        and SP.orderid = OH.orderid
        and SP.shipid = OH.shipid
        and SP.custid = in_custid
        and SP.item = in_item
        and SP.status = 'U';
   if l_cnt = 0 then
      -- the putaway tasks will be generated by the location trigger

      update location
         set flex_pick_front_wave = null,
             flex_pick_front_item = null
         where facility = in_facility
           and locid = in_location;
   end if;
end putaway_flex_item;

-- Public functions


function is_attrib_ok
   (in_ind    in varchar2,
    in_list   in varchar2,
    in_attrib in varchar2)
return boolean
is
   apos pls_integer;
begin

   if ((in_ind is null) or (in_list is null) or (in_attrib is null)) then
      return true;
   end if;

   apos := instr(','||in_list||',', ','||in_attrib||',');

   if ((in_ind = 'I') and (apos = 0)) then
      return false;
   end if;

   if ((in_ind = 'E') and (apos != 0)) then
      return false;
   end if;

   return true;

exception
   when OTHERS then
      return false;
end is_attrib_ok;


function any_vlp_batch_work
   (in_lpid       in varchar2)
return boolean
is
   l_cnt pls_integer;
begin

   select count(1) into l_cnt
      from shippingplate
      where fromlpid = in_lpid
        and location is null
        and status = 'U'
        and taskid = 0;

   if l_cnt != 0 then
      return true;      -- vlp has a sort pending
   end if;

   return false;

exception
   when OTHERS then
      return FALSE;
end any_vlp_batch_work;


-- Public procedures


procedure build_carton
   (in_clip         in varchar2,
    in_shlpid       in varchar2,
    in_user         in varchar2,
    in_need_master  in varchar2,
    in_tasktype     in varchar2,
    in_cartontype   in varchar2,
    out_message     out varchar2)
is
   msg varchar2(80);
   addclp boolean := true;
   xlip plate.lpid%type := null;
   lptype plate.type%type;
   xrefid plate.lpid%type;
   xreftype plate.type%type;
   parentid plate.lpid%type;
   parenttype plate.type%type;
   topid plate.lpid%type;
   toptype plate.type%type;
   clip shippingplate.lpid%type := null;
   cursor c_slp(p_lpid varchar2) is
      select type, facility, location, status, quantity, weight,
             taskid, dropseq, item, custid, loadno, stopno, shipno,
             orderid, shipid, lotnumber
         from shippingplate
         where lpid = p_lpid;
   sp c_slp%rowtype;
   cp c_slp%rowtype;
   cursor c_cartons(p_mlip varchar2) is
      select lpid
         from shippingplate
         where type = 'C'
         start with lpid = p_mlip
         connect by prior lpid = parentlpid;
   builtmlip shippingplate.lpid%type;
   pa_cordid waves.wave%type;
   ch_cordid waves.wave%type;
begin
   out_message := null;

   if (in_clip is null) then
      zsp.get_next_shippinglpid(clip, msg);
      if (msg is not null) then
         out_message := msg;
         return;
      end if;
   else
      zrf.identify_lp(in_clip, lptype, xrefid, xreftype, parentid, parenttype,
            topid, toptype, msg);
      if (msg is not null) then
         out_message := msg;
         return;
      end if;
      if (lptype = 'C') then
         clip := in_clip;                       -- input was a carton
         addclp := false;
      elsif (nvl(xreftype, '?') = 'C') then
         clip := xrefid;                        -- input was xref to a carton
         addclp := false;
      elsif (nvl(parenttype, '?') = 'C') then
         clip := parentid;
         addclp := false;                       -- input has a carton
      elsif (lptype = '?') then
         ch_cordid := zcord.cons_orderid(sp.orderid, sp.shipid);
         if (substr(in_clip, -1, 1) = 'S') then -- kludge !!!
            clip := in_clip;                    -- use input as new id
         else
            zsp.get_next_shippinglpid(clip, msg);  -- get new id
            if (msg is not null) then
               out_message := msg;
               return;
            end if;
            xlip := in_clip;
         end if;
      else
         if (nvl(toptype, '?') = 'M') then      -- input has a master, any carton?
            open c_cartons(topid);
            fetch c_cartons into clip;
            if c_cartons%notfound then
               clip := null;
            end if;
            close c_cartons;
         end if;
         if (clip is not null) then
            addclp := false;                    -- master had carton, use it
         else
            zsp.get_next_shippinglpid(clip, msg);  -- get new id
            if (msg is not null) then
               out_message := msg;
               return;
            end if;
            xlip := in_clip;
         end if;
      end if;
   end if;

   open c_slp(in_shlpid);
   fetch c_slp into sp;
   close c_slp;

   if (addclp) then
      insert into shippingplate
         (lpid, facility, location, status, quantity, type,
          lastuser, lastupdate, weight, taskid, dropseq, item, custid,
          loadno, stopno, shipno, orderid, shipid,
          fromlpid, cartontype, lotnumber)
      values
         (clip, sp.facility, sp.location, sp.status, sp.quantity, 'C',
          in_user, sysdate, sp.weight, sp.taskid, sp.dropseq, sp.item, sp.custid,
          sp.loadno, sp.stopno, sp.shipno, sp.orderid, sp.shipid,
          decode(in_need_master, 'N', xlip), in_cartontype, sp.lotnumber);

      if (in_need_master = 'Y') then
         build_mast_shlp(xlip, clip, in_user, in_tasktype, builtmlip, msg);
         if (msg is not null) then
            out_message := msg;
            return;
         end if;
      elsif (xlip is not null) then
         insert into plate
            (lpid, type, parentlpid, lastuser, lastupdate, lasttask, lastoperator, custid, facility)
         values
            (xlip, 'XP', clip, in_user, sysdate, in_tasktype, in_user, sp.custid, sp.facility);
      end if;
   else
      open c_slp(clip);
      fetch c_slp into cp;
      close c_slp;
      if (nvl(sp.custid, '(none)') != nvl(cp.custid, '(none)')) then
         sp.custid := null;
         sp.item := null;
         sp.lotnumber := null;
      elsif (nvl(sp.item, '(none)') != nvl(cp.item, '(none)')) then
         sp.item := null;
         sp.lotnumber := null;
      elsif (nvl(sp.lotnumber, '(none)') != nvl(cp.lotnumber, '(none)')) then
         sp.lotnumber := null;
      end if;

      if (nvl(sp.orderid, 0) != nvl(cp.orderid, 0)) then
         pa_cordid := zcord.cons_orderid(cp.orderid, cp.shipid);
         ch_cordid := zcord.cons_orderid(sp.orderid, sp.shipid);
         if (pa_cordid = ch_cordid) and (pa_cordid != 0) then
            sp.orderid := pa_cordid;
         else
            sp.orderid := 0;
         end if;
         sp.shipid := 0;
      elsif (nvl(sp.shipid, 0) != nvl(cp.shipid, 0)) then
         sp.shipid := 0;
      end if;

      update shippingplate
         set item = sp.item,
             custid = sp.custid,
             orderid = sp.orderid,
             shipid = sp.shipid,
             quantity = nvl(quantity, 0) + sp.quantity,
             weight = nvl(weight, 0) + sp.weight,
             lastuser = in_user,
             lastupdate = sysdate,
             lotnumber = sp.lotnumber
         where lpid = clip;

   end if;

   update shippingplate
      set parentlpid = clip,
          lastuser = in_user,
          lastupdate = sysdate
      where lpid = in_shlpid;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end build_carton;


procedure build_mast_shlp
   (in_mlip       in varchar2,
    in_shlpid     in varchar2,
    in_user       in varchar2,
    in_tasktype   in varchar2,
    out_builtmlip out varchar2,
    out_message   out varchar2)
is
   msg varchar2(80);
   addmlp boolean := true;
   xlip plate.lpid%type := null;
   lptype plate.type%type;
   xrefid plate.lpid%type;
   xreftype plate.type%type;
   parentid plate.lpid%type;
   parenttype plate.type%type;
   topid plate.lpid%type;
   toptype plate.type%type;
   mlip shippingplate.lpid%type;
   cursor c_mlp(p_lpid varchar2) is
      select type, facility, location, status, quantity, weight,
             taskid, dropseq, item, custid, loadno, stopno, shipno,
             orderid, shipid, lotnumber
         from shippingplate
         where lpid = p_lpid;
   mp c_mlp%rowtype;
   sp c_mlp%rowtype;
   pa_cordid waves.wave%type;
   ch_cordid waves.wave%type;
begin
   out_message := null;
   out_builtmlip := null;

   open c_mlp(in_shlpid);
   fetch c_mlp into sp;
   close c_mlp;
   if (in_mlip is null) then
      zsp.get_next_shippinglpid(mlip, msg);
      if (msg is not null) then
         out_message := msg;
         return;
      end if;
   else
      zrf.identify_lp(in_mlip, lptype, xrefid, xreftype, parentid, parenttype,
            topid, toptype, msg);
      if (msg is not null) then
         out_message := msg;
         return;
      end if;
      if (lptype = 'M') then
         mlip := in_mlip;                       -- input was a master
         addmlp := false;
      elsif (nvl(xreftype, '?') = 'M') then
         mlip := xrefid;                        -- input was an xref to a master
         addmlp := false;
      elsif (nvl(toptype, '?') = 'M') then
         mlip := topid;
         addmlp := false;                       -- input has a master
      elsif (lptype = '?') then
         ch_cordid := zcord.cons_orderid(sp.orderid, sp.shipid);
         if ch_cordid <> 0 then
            sp.orderid := ch_cordid;
            sp.shipid := 0;
         end if;
         if (substr(in_mlip, -1, 1) = 'S') then -- kludge !!!
            mlip := in_mlip;                    -- use input as new id
         else
            zsp.get_next_shippinglpid(mlip, msg);  -- get new id
            if (msg is not null) then
               out_message := msg;
               return;
            end if;
            xlip := in_mlip;
         end if;
      else
         zsp.get_next_shippinglpid(mlip, msg);  -- get new id
         if (msg is not null) then
            out_message := msg;
            return;
         end if;
         update shippingplate                   -- link (parent of) input to new id
            set parentlpid = mlip,
                lastuser = in_user,
                lastupdate = sysdate
            where lpid = nvl(topid, nvl(xrefid, in_mlip))
            returning custid, item, orderid, shipid, quantity, weight
               into mp.custid, mp.item, mp.orderid, mp.shipid, mp.quantity, mp.weight;

         -- update data for insert
         if (nvl(sp.custid, '(none)') != nvl(mp.custid, '(none)')) then
            sp.custid := null;
            sp.item := null;
            sp.lotnumber := null;
         elsif (nvl(sp.item, '(none)') != nvl(mp.item, '(none)')) then
            sp.item := null;
            sp.lotnumber := null;
         elsif (nvl(sp.lotnumber, '(none)') != nvl(mp.lotnumber, '(none)')) then
            sp.lotnumber := null;
         end if;

         if (nvl(sp.orderid, 0) != nvl(mp.orderid, 0)) then
            pa_cordid := zcord.cons_orderid(mp.orderid, mp.shipid);
            ch_cordid := zcord.cons_orderid(sp.orderid, sp.shipid);
            if (pa_cordid = ch_cordid) and (pa_cordid != 0) then
               sp.orderid := pa_cordid;
            else
               sp.orderid := 0;
            end if;
            sp.shipid := 0;
         elsif (nvl(sp.shipid, 0) != nvl(mp.shipid, 0)) then
            sp.shipid := 0;
         end if;

         sp.quantity := sp.quantity + nvl(mp.quantity, 0);
         sp.weight := sp.weight + nvl(mp.weight, 0);
      end if;
   end if;

   if (addmlp) then
      if ch_cordid <> 0 and
         sp.orderid <> 0  then
         sp.orderid := ch_cordid;
         sp.shipid := 0;
      end if;

      insert into shippingplate
         (lpid, facility, location, status, quantity, type, parentlpid,
          lastuser, lastupdate, weight, taskid, dropseq, item, custid,
          loadno, stopno, shipno, orderid, shipid, fromlpid, lotnumber)
      values
         (mlip, sp.facility, sp.location, sp.status, sp.quantity, 'M', null,
          in_user, sysdate, sp.weight, sp.taskid, sp.dropseq, sp.item, sp.custid,
          sp.loadno, sp.stopno, sp.shipno, sp.orderid, sp.shipid, xlip, sp.lotnumber);

      if (xlip is not null) then
         insert into plate
            (lpid, type, parentlpid, lastuser, lastupdate, lasttask, lastoperator, custid, facility)
         values
            (xlip, 'XP', mlip, in_user, sysdate, in_tasktype, in_user, sp.custid, sp.facility);
      end if;
      out_builtmlip := mlip;
   else
      open c_mlp(mlip);
      fetch c_mlp into mp;
      close c_mlp;
      if (nvl(sp.custid, '(none)') != nvl(mp.custid, '(none)')) then
         sp.custid := null;
         sp.item := null;
         sp.lotnumber := null;
      elsif (nvl(sp.item, '(none)') != nvl(mp.item, '(none)')) then
         sp.item := null;
         sp.lotnumber := null;
      elsif (nvl(sp.lotnumber, '(none)') != nvl(mp.lotnumber, '(none)')) then
         sp.lotnumber := null;
      end if;

      if (nvl(sp.orderid, 0) != nvl(mp.orderid, 0)) then
         pa_cordid := zcord.cons_orderid(mp.orderid, mp.shipid);
         ch_cordid := zcord.cons_orderid(sp.orderid, sp.shipid);
         if (pa_cordid = ch_cordid) and (pa_cordid != 0) then
            sp.orderid := pa_cordid;
         else
            sp.orderid := 0;
         end if;
         sp.shipid := 0;
      elsif (nvl(sp.shipid, 0) != nvl(mp.shipid, 0)) then
         sp.shipid := 0;
      end if;

      update shippingplate
         set item = sp.item,
             lotnumber = sp.lotnumber,
             custid = sp.custid,
             orderid = sp.orderid,
             shipid = sp.shipid,
             quantity = nvl(quantity, 0) + sp.quantity,
             weight = nvl(weight, 0) + sp.weight,
             lastuser = in_user,
             lastupdate = sysdate
         where lpid = mlip;
   end if;

   update shippingplate
      set parentlpid = mlip,
          lastuser = in_user,
          lastupdate = sysdate
      where lpid = in_shlpid;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end build_mast_shlp;


procedure pick_a_plate
   (in_taskid          in number,
    in_shlpid          in varchar2,
    in_user            in varchar2,
    in_plannedlp       in varchar2,
    in_pickedlp        in varchar2,
    in_custid          in varchar2,
    in_item            in varchar2,
    in_orderitem       in varchar2,
    in_lotno           in varchar2,
    in_qty             in number,
    in_dropseq         in number,
    in_pickfac         in varchar2,
    in_pickloc         in varchar2,
    in_uom             in varchar2,
    in_lplotno         in varchar2,
    in_mlip            in varchar2,
    in_picktype        in varchar2,
    in_tasktype        in varchar2,
    in_picktotype      in varchar2,
    in_fromloc         in varchar2,
    in_subtask_rowid   in varchar2,
    in_extra_process   in varchar2,
    in_picked_child    in varchar2,
    in_pkd_lotno       in varchar2,
    in_pkd_serialno    in varchar2,
    in_pkd_user1       in varchar2,
    in_pkd_user2       in varchar2,
    in_pkd_user3       in varchar2,
    in_pickuom         in varchar2,
    in_pickqty         in number,
    in_weight          in number,
    in_taskedlp        in varchar2,
    out_lpcount        out number,
    out_error          out varchar2,
    out_message        out varchar2)
is
   cursor c_lp(p_lpid varchar2) is
      select P.location, P.quantity, L.section, L.equipprof, P.parentlpid,
             P.lotnumber, P.useritem1, P.useritem2, P.useritem3, P.serialnumber, P.type,
             L.pickingseq, L.pickingzone, P.inventoryclass, P.invstatus, P.weight,
             P.status, P.virtuallp, P.manufacturedate, P.expirationdate, L.loctype,
             nvl(P.qtytasked,0) qtytasked, P.lpid, P.qtyrcvd,
         P.length, P.width, P.height, P.pallet_weight
         from plate P, location L
         where P.lpid = p_lpid
           and L.facility = P.facility
           and L.locid = P.location;
   cursor c_loc is
      select locid, in_qty, section, equipprof, null,
             null, null, null, null, null, '?',
             pickingseq, pickingzone, null, null, null,
             null, null, null, null, loctype,
             0, null, null, null, null, null, null
         from location
         where facility = in_pickfac
           and locid = in_pickloc;
   pik c_lp%rowtype := null;
   pln c_lp%rowtype := null;
   swappedlp c_lp%rowtype := null;
   c_any_lp anylpcur;
   l anylptype;
   l_uom plate.unitofmeasure%type := in_uom;
   l_pickuom plate.unitofmeasure%type := in_pickuom;
   cursor c_itemview(p_item varchar2) is
      select useramt1, lotrequired, serialrequired, user1required, user2required,
             user3required, serialasncapture, user1asncapture, user2asncapture,
             user3asncapture, nvl(ordercheckrequired, 'N') checkreqd,
             zci.item_cube(in_custid, p_item, l_pickuom) cube, baseuom,
             nvl(catch_weight_out_cap_type, ' ') captype,
             nvl(use_catch_weights, 'N') use_catch_weights, track_picked_pf_lps,
             nvl(restrict_lot_sub,'N') restrict_lot_sub
         from custitemview
         where custid = in_custid
           and item = p_item;
   itv c_itemview%rowtype;
   remqty commitments.qty%type;
   invclass shippingplate.inventoryclass%type;
   invstats shippingplate.invstatus%type;
   err varchar2(1);
   msg varchar2(80);
   errmsg varchar2(200);
   cnt integer;
   pdfac plate.destfacility%type;
   pdloc plate.destlocation%type;
   builtmlip shippingplate.lpid%type;
   itemlot plate.lotnumber%type;
   pickedlot plate.lotnumber%type;
   packqty orderdtl.qty2pack%type;
   packamtqty orderdtl.qty2pack%type;
   checkqty orderdtl.qty2check%type;
   checkamtqty orderdtl.qty2check%type;
   cursor c_stsk is
      select S.cartontype,
             S.wave,
             nvl(S.step1_complete,'N') as step1_complete,
             nvl(S.orderid,0) as orderid,
             nvl(S.shipid,0) as shipid,
             nvl(S.loadno,0) as loadno,
             nvl(S.stopno,0) as stopno,
             nvl(S.weight,0) as weight,
             nvl(W.use_flex_pick_fronts_yn,'N') as useflex,
             S.orderlot,
             nvl(S.qty,0) as qty,
             nvl(S.shippingtype,'P') as picktype
         from subtasks S, waves W
         where S.rowid = chartorowid(in_subtask_rowid)
           and W.wave (+) = S.wave;
   stsk c_stsk%rowtype := null;
   cursor c_commit is
      select qty, rowid
         from commitments
         where orderid = stsk.orderid
           and shipid = stsk.shipid
           and orderitem = in_orderitem
           and nvl(orderlot, '(none)') = nvl(in_lotno, '(none)')
           and item = in_item
           and inventoryclass = invclass
           and invstatus = invstats
           and status = 'CM'
         order by qty;
   qtytouncommit commitments.qty%type;
   l_rowid rowid;
   cursor c_oh(p_orderid number, p_shipid number) is
      select orderstatus, ordertype, parentorderid, parentshipid,
             componenttemplate, loadno, stopno
         from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   oh c_oh%rowtype := null;
   poh c_oh%rowtype := null;
   cursor c_swap is
      select S.rowid strowid, T.rowid tkrowid, T.lpid tklpid, T.taskid
         from subtasks S, tasks T
         where T.facility = in_pickfac
           and T.tasktype in ('PK', 'OP', 'BP', 'RP')
           and (T.priority in ('1', '2', '3', '4', '9')
             or (T.priority = '0' and T.curruserid = in_user and nvl(S.qtypicked,0) = 0))
           and S.taskid = T.taskid
           and nvl(S.shippingtype, 'P') = 'F'
           and S.lpid in
               (select lpid from plate
                  start with lpid = in_pickedlp
                  connect by prior lpid = parentlpid);
   swp c_swap%rowtype;
   cursor c_task is
      select rowid, lpid
         from tasks
         where taskid = in_taskid;
   tsk c_task%rowtype;
   cursor c_slp is
      select nvl(P.parentlpid, P.lpid)
         from plate P, shippingplate S
         where S.lpid = in_shlpid
           and P.lpid = S.fromlpid;
   cursor c_smp(p_lotnumber varchar2) is
      select lpid
         from plate
         where lpid in (select lpid from plate
                           start with lpid = in_pickedlp
                           connect by prior lpid = parentlpid)
           and custid = in_custid
           and item = in_item
           and nvl(lotnumber, '(none)') = nvl(p_lotnumber, '(none)')
           and quantity = in_qty;
   cursor c_od(p_orderid number, p_shipid number, p_item varchar2, p_lotnumber varchar2) is
      select nvl(qtyorder, 0)-nvl(qtycommit, 0) qtytocommit, uom, priority, nvl(unrestrict_lot_sub,'N') unrestrict_lot_sub
         from orderdtl
         where orderid = p_orderid
           and shipid = p_shipid
           and item = p_item
           and nvl(lotnumber, '(none)') = nvl(p_lotnumber, '(none)');
   od c_od%rowtype;
   cursor c_cus(p_custid varchar2) is
      select nvl(X.allow_overpicking, 'N') allow_overpicking,
             nvl(X.mixed_order_shiplp_ok, 'Y') mixed_order_shiplp_ok,
             nvl(C.paperbased, 'N') paperbased
         from customer C, customer_aux X
         where C.custid = p_custid
           and X.custid = C.custid;
   cus c_cus%rowtype;
   cursor c_flex(p_facility varchar2, p_location varchar2) is
      select loctype,
             nvl(flex_pick_front_wave,-1) as flexwave
         from location
         where facility = p_facility
           and locid = p_location;
   flex c_flex%rowtype := null;
   cursor c_kid(p_lpid varchar2, p_custid varchar2, p_item varchar2) is
      select lotnumber, useritem1, useritem2, useritem3, serialnumber,
             inventoryclass, invstatus
         from plate
         where parentlpid = p_lpid
           and custid = p_custid
           and item = p_item;
   kid c_kid%rowtype;
   pickedlp plate.lpid%type;
   invstind orderdtl.invstatusind%type := null;
   invstlist orderdtl.invstatus%type := null;
   invclind orderdtl.invclassind%type := null;
   invcllist orderdtl.inventoryclass%type := null;
   cordid waves.wave%type;
   l_key number := 0;
   l_batchswaplp plate.lpid%type := null;
   l_batchswaploc plate.location%type := null;
   orderedqty orderdtl.qtyorder%type;
   pickedqty orderdtl.qtypick%type;
   l_weight number;
   l_picktype shippingplate.type%type := in_picktype;
   l_picktype_2 shippingplate.type%type := in_picktype;
   l_weight2check orderdtl.weight2check%type;
   l_weight2pack orderdtl.weight2pack%type;
   l_picked_weight number;
   l_iteration number;
   l_picked_qty number;
   auxmsg varchar2(80);
   l_flexpick boolean := false;
   l_btqty batchtasks.qty%type;
   l_splitfact number;
   l_partmpcpt boolean := false;
   l_lpid plate.lpid%type;
   v_manual_picks varchar2(1);
   v_shlpid_lotno plate.lotnumber%type := null;
   v_update_fromlpid number;
   l_elapsed_begin date;
   l_elapsed_end date;
   lpParentlpid shippingplate.parentlpid%type;
   lpType shippingplate.type%type;
   lpQty plate.quantity%type;

   procedure add_workorderpick
      (p_lpid in varchar2,
       p_qty  in number)
   is
   begin
      insert into workorderpicks
         (orderid,
          shipid,
          custid,
          item,
          lpid,
          serialnumber,
          lotnumber,
          manufacturedate,
          expirationdate,
          countryof,
          useritem1,
          useritem2,
          useritem3,
          invstatus,
          inventoryclass,
          quantity,
          pickedon,
          pickedby)
      select stsk.orderid,
          stsk.shipid,
          custid,
          item,
          lpid,
          nvl(in_pkd_serialno, serialnumber),
          nvl(in_pkd_lotno, lotnumber),
          manufacturedate,
          expirationdate,
          countryof,
          nvl(in_pkd_user1, useritem1),
          nvl(in_pkd_user2, useritem2),
          nvl(in_pkd_user3, useritem3),
          invstatus,
          inventoryclass,
          p_qty,
          sysdate,
          in_user
      from plate
      where lpid = p_lpid;

   end add_workorderpick;
begin
   l_elapsed_begin := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'begin ZRFPK.PICK_A_PLATE - ' ||
                    'TASKID: ' || in_taskid || ',' ||
                    'SHLPID: ' || in_shlpid || ',' ||
                    'USER: ' || in_user || ',' ||
                    'PLANNEDLP: ' || in_plannedlp || ',' ||
                    'PICKEDLP: ' || in_pickedlp || ',' ||
                    'CUSTID: ' || in_custid || ',' ||
                    'ITEM: ' || in_item || ',' ||
                    'ORDERITEM: ' || in_orderitem || ',' ||
                    'LOTNO: ' || in_lotno || ',' ||
                    'QTY: ' || in_qty || ',' ||
                    'DROPSEQ: ' || in_dropseq || ',' ||
                    'PICKFAC: ' || in_pickfac || ',' ||
                    'PICKLOC: ' || in_pickloc || ',' ||
                    'UOM: ' || in_uom || ',' ||
                    'LPLOTNO: ' || in_lplotno || ',' ||
                    'MLIP: ' || in_mlip || ',' ||
                    'PICKTYPE: ' || in_picktype || ',' ||
                    'TASKTYPE: ' || in_tasktype || ',' ||
                    'PICKTOTYPE: ' || in_picktotype || ',' ||
                    'FROMLOC: ' || in_fromloc || ',' ||
                    'STROWID: ' || in_subtask_rowid || ',' ||
                    'EXTRAPROCESS: ' || in_extra_process || ',' ||
                    'PICKEDCHILD: ' || in_picked_child || ',' ||
                    'PKDLOTNO: ' || in_pkd_lotno || ',' ||
                    'PKDSERIALNO: ' || in_pkd_serialno || ',' ||
                    'PKDUSER1: ' || in_pkd_user1 || ',' ||
                    'PKDUSER2: ' || in_pkd_user2 || ',' ||
                    'PKDUSER3: ' || in_pkd_user3 || ',' ||
                    'PICKUOM: ' || in_pickuom || ',' ||
                    'PICKQTY: ' || in_pickqty || ',' ||
                    'WEIGHT: ' || in_weight || ',' ||
                    'TASKEDLP: ' || in_taskedlp,
                    'T', in_user);
   out_error := 'N';
   out_message := null;

   zrf.so_lock(l_key);

   open c_cus(in_custid);
   fetch c_cus into cus;
   close c_cus;

   open c_stsk;
   fetch c_stsk into stsk;
   if not c_stsk%found then
      stsk.cartontype := null;
      stsk.step1_complete := 'N';
      stsk.weight := 0;
      stsk.wave := -2;
   end if;
   close c_stsk;

   if (stsk.picktype = 'P' and stsk.picktype != in_picktype and in_pickedlp is not null) then
      begin
        select quantity into lpQty
        from plate
        where lpid = in_pickedlp;
      exception
        when others then
          lpQty := null;
      end;

      if (lpQty > stsk.qty) then
        l_picktype := 'P';
      end if;
   end if;

   zso.get_rf_lock(stsk.loadno,stsk.orderid,stsk.shipid,in_user,msg);
   if substr(msg,1,4) != 'OKAY' then
     out_message := substr(msg,1,80);
     return;
   end if;

   open c_flex(in_pickfac, in_fromloc);
   fetch c_flex into flex;
   close c_flex;

   if stsk.useflex = 'Y' and stsk.wave = flex.flexwave then
      if in_pickloc != in_fromloc then
         out_message := 'Must use Flex PF';
         rollback;
         return;
      end if;
      l_flexpick := true;
   else
      open c_flex(in_pickfac, in_pickloc);
      fetch c_flex into flex;
      close c_flex;

      if 'FPF' = flex.loctype then
         out_message := 'Cannot use Flex PF';
         rollback;
         return;
      end if;
   end if;

   if cus.allow_overpicking = 'Y' and
      in_taskedlp is not null then
      if in_picktype = 'P' then
         select quantity into lpQty
            from plate
            where lpid = in_taskedlp;
      end if;
      if lpQty = in_pickqty then
         l_picktype := 'F';
      end if;
   end if;

    if in_picktype = 'P' and in_pickedlp is not null then
      begin
        select quantity into lpQty
        from plate
        where lpid = in_pickedlp;
      exception
        when others then
          lpQty := null;
      end;

      if lpQty = in_qty then
        l_picktype_2 := 'F';
      end if;
    end if;

   if l_uom is null then
      open c_itemview(in_item);
      fetch c_itemview into itv;
      close c_itemview;
      l_uom := itv.baseuom;
   end if;
   if l_pickuom is null then
      l_pickuom := l_uom;
   end if;

   open c_itemview(in_orderitem);
   fetch c_itemview into itv;
   close c_itemview;
   
   open c_lp(in_pickedlp);
   fetch c_lp into pik;
   close c_lp;
   
   open c_lp(in_plannedlp);
   fetch c_lp into pln;
   close c_lp;

   cordid := zcord.cons_orderid(stsk.orderid, stsk.shipid);
   if cordid <> 0  and
      in_mlip is not null then
      check_mlip_cons(in_mlip, in_custid, stsk.orderid, stsk.shipid, stsk.loadno, stsk.stopno,
         in_picktotype, 'O', cordid, err, msg);
      if (msg is not null) then
         out_message := msg;
         rollback;
         return;
      end if;
   end if;
   if (stsk.orderid != 0) and (cordid = 0) then
      open c_oh(stsk.orderid, stsk.shipid);
      fetch c_oh into oh;
      close c_oh;

      if (stsk.orderlot is null and nvl(itv.lotrequired,'N') = 'S' and itv.restrict_lot_sub = 'Y'
            and in_pickedlp is not null and in_plannedlp is not null and in_pickedlp <> in_plannedlp) then
        open c_od(stsk.orderid, stsk.shipid, in_orderitem, stsk.orderlot);
        fetch c_od into od;
        close c_od;
        
        if (od.unrestrict_lot_sub = 'N' and nvl(pik.lotnumber,'(none)') <> nvl(pln.lotnumber,'(none)')) then
          out_message := 'Wrong Lot';
          rollback;
          return;
        end if;
      end if;

      if (oh.parentorderid is not null) and (oh.parentshipid is not null) then
         open c_oh(oh.parentorderid, oh.parentshipid);
         fetch c_oh into poh;
         close c_oh;
      end if;
   else
      oh.orderstatus := '?';
      oh.ordertype := '?';
   end if;

   if in_weight > 0 then
      l_weight := in_weight;
   elsif in_pickedlp is not null then
      l_weight := in_pickqty * zcwt.lp_item_weight(in_pickedlp, in_custid, in_item, in_pickuom);
   elsif in_plannedlp is not null then
      l_weight := in_pickqty*zcwt.lp_item_weight(in_plannedlp, in_custid, in_item, in_pickuom);
   else
      l_weight := in_pickqty*zci.item_weight(in_custid, in_item, in_pickuom);
   end if;
   if l_weight <= 0 then
      out_message := 'Weight must be > 0';
      rollback;
      return;
   end if;
   if itv.use_catch_weights = 'Y' and itv.captype = 'N' then
      l_weight := l_weight + (in_pickqty*zci.item_tareweight(in_custid, in_item, in_pickuom));
   end if;

   if (stsk.orderid != 0) and (cordid = 0) then
--    update the order header
      update orderhdr
         set orderstatus = zrf.ORD_PICKING,
             lastuser = in_user,
             lastupdate = sysdate
         where orderid = stsk.orderid
           and shipid = stsk.shipid
           and orderstatus < zrf.ORD_PICKING;

      if ((oh.parentorderid is not null) and (oh.parentshipid is not null)
      and (poh.ordertype = 'W')) then
         update orderhdr
            set orderstatus = zrf.ORD_PICKING,
                lastuser = in_user,
                lastupdate = sysdate
            where orderid = oh.parentorderid
              and shipid = oh.parentshipid
              and orderstatus < zrf.ORD_PICKING;
      end if;

      if (oh.loadno is not null) then
         update loadstop
            set loadstopstatus = zrf.LOD_PICKING,
                lastuser = in_user,
                lastupdate = sysdate
            where loadno = oh.loadno
              and stopno = oh.stopno
              and loadstopstatus < zrf.LOD_PICKING;
         update loads
            set loadstatus = zrf.LOD_PICKING,
                lastuser = in_user,
                lastupdate = sysdate
            where loadno = oh.loadno
              and loadstatus < zrf.LOD_PICKING;
      end if;

--    update the order detail
      if (stsk.step1_complete = 'N') then
         if (in_tasktype = 'SO') then
            if ((itv.checkreqd = 'Y') and (oh.ordertype != 'K')) then
               checkqty := in_pickqty;
               checkamtqty := in_qty;
               l_weight2check := l_weight;
            else
               checkqty := 0;
               checkamtqty := 0;
               l_weight2check := 0;
            end if;

            update orderdtl
               set qtypick = nvl(qtyPick, 0) + in_qty,
                   weightpick = nvl(weightpick, 0) + l_weight,
                   cubepick = nvl(cubepick, 0) + (itv.cube * in_qty),
                   amtpick = nvl(amtpick, 0) + (zci.item_amt(custid,orderid,shipid,item,lotnumber) * in_qty),
                   qty2sort = nvl(qty2sort, 0) - in_qty,
                   weight2sort = nvl(weight2sort, 0) - l_weight,
                   cube2sort = nvl(cube2sort, 0) - (in_pickqty * itv.cube),
                   amt2sort = nvl(amt2sort, 0) - (in_qty * zci.item_amt(custid,orderid,shipid,item,lotnumber)),
                   qty2check = nvl(qty2check, 0) + checkamtqty,
                   weight2check = nvl(weight2check, 0) + l_weight2check,
                   cube2check = nvl(cube2check, 0) + (checkqty * itv.cube),
                   amt2check = nvl(amt2check, 0) + (checkamtqty * zci.item_amt(custid,orderid,shipid,item,lotnumber)),
                   lastuser = in_user,
                   lastupdate = sysdate
               where orderid = stsk.orderid
                 and shipid = stsk.shipid
                 and item = in_orderitem
                 and nvl(lotnumber, '(none)') = nvl(in_lotno, '(none)')
               returning invstatusind, invstatus, invclassind, inventoryclass
               into invstind, invstlist, invclind, invcllist;
         else
            packqty := 0;
            packamtqty := 0;
            checkqty := 0;
            checkamtqty := 0;
            l_weight2check := 0;
            l_weight2pack := 0;

            if ((nvl(in_picktotype,'??') = 'TOTE') and (oh.ordertype != 'K')) then
               packqty := in_pickqty;
               packamtqty := in_qty;
               l_weight2pack := l_weight;
            elsif ((itv.checkreqd = 'Y') and (oh.ordertype != 'K')) then
               checkqty := in_pickqty;
               checkamtqty := in_qty;
               l_weight2check := l_weight;
            end if;

            update orderdtl
               set qtypick = nvl(qtypick, 0) + in_qty,
                   weightpick = nvl(weightpick, 0) + l_weight,
                   cubepick = nvl(cubepick, 0) + (in_pickqty * itv.cube),
                   amtpick = nvl(amtpick, 0) + (in_qty * zci.item_amt(custid,orderid,shipid,item,lotnumber)),
                   qty2pack = nvl(qty2pack, 0) + packamtqty,
                   weight2pack = nvl(weight2pack, 0) + l_weight2pack,
                   cube2pack = nvl(cube2pack, 0) + (packqty * itv.cube),
                   amt2pack = nvl(amt2pack, 0) + (packamtqty * zci.item_amt(custid,orderid,shipid,item,lotnumber)),
                   qty2check = nvl(qty2check, 0) + checkamtqty,
                   weight2check = nvl(weight2check, 0) + l_weight2check,
                   cube2check = nvl(cube2check, 0) + (checkqty * itv.cube),
                   amt2check = nvl(amt2check, 0) + (checkamtqty * zci.item_amt(custid,orderid,shipid,item,lotnumber)),
                   lastuser = in_user,
                   lastupdate = sysdate
               where orderid = stsk.orderid
                 and shipid = stsk.shipid
                 and item = in_orderitem
                 and nvl(lotnumber, '(none)') = nvl(in_lotno, '(none)')
               returning invstatusind, invstatus, invclassind, inventoryclass, qtyorder,
                         qtypick, rowid
               into invstind, invstlist, invclind, invcllist, orderedqty,
                    pickedqty, l_rowid;

            if (pickedqty > orderedqty) and (cus.allow_overpicking != 'Y') then
               if zwt.is_ordered_by_weight(stsk.orderid, stsk.shipid, in_orderitem,
                     in_lotno) = 'N' then
                  out_message := 'Pick > Order';
                  rollback;
                  return;
               end if;

               update orderdtl
                  set qtyorder = pickedqty,
                      cubeorder = pickedqty*itv.cube,
                      amtorder = pickedqty*zci.item_amt(custid,orderid,shipid,item,lotnumber),
                      lastuser = in_user,
                      lastupdate = sysdate
                  where rowid = l_rowid;
            end if;
         end if;
      else
         select invstatusind, invstatus, invclassind, inventoryclass
            into invstind, invstlist, invclind, invcllist
            from orderdtl
            where orderid = stsk.orderid
              and shipid = stsk.shipid
              and item = in_orderitem
              and nvl(lotnumber, '(none)') = nvl(in_lotno, '(none)');
      end if;
   end if;


   if (in_tasktype = 'SO') and (nvl(pln.virtuallp,'N') = 'Y') then
      l_picktype := 'F';
   end if;

   if ((in_plannedlp is not null) and (in_pickedlp is not null)
   and (in_plannedlp != in_pickedlp)) then

      if ((in_picktype = 'F') or (nvl(pik.quantity,0) = in_qty) or (stsk.picktype = 'F' and stsk.qty = in_qty)) then
         select count(1) into cnt
            from subtasks S, tasks T
         where S.taskid = T.taskid
           and T.facility = in_pickfac
           and T.priority = '0' and T.curruserid <> in_user
           and S.lpid in
            (select lpid from plate
               start with lpid = in_pickedlp
               connect by prior lpid = parentlpid);

         if (cnt > 0) then
           out_message := 'LP unavailable';
           rollback;
           return;
         end if;

         select count(1) into cnt
            from subtasks S, tasks T
         where S.taskid = T.taskid
          and nvl(S.shippingtype, 'P') = 'F'
          and S.orderlot is not null
          and nvl(S.orderlot,'(none)') <> nvl(pln.lotnumber,'(none)')
          and S.lpid in
            (select lpid from plate
               start with lpid = in_pickedlp
               connect by prior lpid = parentlpid);
               
        if (cnt > 0) then
           out_message := 'LP unavailable';
           rollback;
           return;
        end if;

         select count(1) into cnt
            from subtasks S, tasks T
            where T.facility = in_pickfac
              and T.tasktype in ('PK', 'OP', 'BP', 'RP')
              and (T.priority in ('1', '2', '3', '4', '9')
                or (T.priority = '0' and T.curruserid = in_user and nvl(S.qtypicked,0) = 0))
              and S.taskid = T.taskid
              and nvl(S.shippingtype, 'P') = 'F'
              and S.lpid in
                  (select lpid from plate
                     start with lpid = in_pickedlp
                     connect by prior lpid = parentlpid);

         if (cnt = 1) then
            open c_swap;
            fetch c_swap into swp;
            close c_swap;

            open c_lp(in_pickedlp);
            fetch c_lp into swappedlp;
            close c_lp;

--          swap plates with another subtask(s)/task(s)
            update subtasks
               set fromsection = pln.section,
                   fromloc = pln.location,
                   fromprofile = pln.equipprof,
                   lpid = in_plannedlp,
                   lastuser = in_user,
                   lastupdate = sysdate,
                   locseq = pln.pickingseq,
                   pickingzone = pln.pickingzone,
                   shippingtype = decode(pik.quantity, pln.quantity, shippingtype, 'P')
               where rowid = swp.strowid;

            if (swp.tklpid is not null) then
               swp.tklpid := in_plannedlp;
            end if;
            update tasks
               set fromsection = pln.section,
                   fromloc = pln.location,
                   fromprofile = pln.equipprof,
                   lpid = swp.tklpid,
                   lastuser = in_user,
                   lastupdate = sysdate,
                   locseq = pln.pickingseq,
                   pickingzone = pln.pickingzone
               where rowid = swp.tkrowid
                 and lpid = in_pickedlp;

            update batchtasks
               set lpid = '((switching))',
                   lastuser = in_user,
                   lastupdate = sysdate
               where taskid = in_taskid
                 and lpid = in_plannedlp;

            update batchtasks
               set fromsection = pln.section,
                   fromloc = pln.location,
                   fromprofile = pln.equipprof,
                   lpid = in_plannedlp,
                   lastuser = in_user,
                   lastupdate = sysdate,
                   locseq = pln.pickingseq,
                   pickingzone = pln.pickingzone
               where taskid = swp.taskid
                 and lpid = in_pickedlp;

            update batchtasks
               set fromsection = pik.section,
                   fromloc = pik.location,
                   fromprofile = pik.equipprof,
                   lpid = in_pickedlp,
                   lastuser = in_user,
                   lastupdate = sysdate,
                   locseq = pik.pickingseq,
                   pickingzone = pik.pickingzone
               where taskid = in_taskid
                 and lpid = '((switching))';

            l_batchswaplp := in_pickedlp;
            l_batchswaploc := pik.location;

            update shippingplate
               set location = pln.location,
                   fromlpid = in_plannedlp,
                   lotnumber = pln.lotnumber,
                   lastuser = in_user,
                   lastupdate = sysdate,
                   type = decode(pik.quantity, pln.quantity, type, 'P')
               where fromlpid = in_pickedlp
                 and status = 'U';

            update plate
               set (destfacility, destlocation) =
                   (select destfacility, destlocation
                        from plate
                        where lpid = in_pickedlp),
                   lasttask = in_tasktype,
                   lastuser = in_user,
                   lastoperator = in_user,
                   lastupdate = sysdate
               where lpid = in_plannedlp
               returning destfacility, destlocation into pdfac, pdloc;
         elsif (cnt = 0) then
            update plate
               set destfacility = null,
                   destlocation = null,
                   lasttask = in_tasktype,
                   lastuser = in_user,
                   lastoperator = in_user,
                   lastupdate = sysdate
               where lpid = in_plannedlp
               returning destfacility, destlocation into pdfac, pdloc;

            select count(1) into cnt
               from subtasks
               where taskid = in_taskid
                 and nvl(shippingtype, 'P') = 'F'
                 and lpid in
                     (select lpid from plate
                        start with lpid = in_pickedlp
                        connect by prior lpid = parentlpid);
            if cnt = 1 then      -- we are swapping within the batch pick list
               update batchtasks
                  set lpid = '((switching))',
                      lastuser = in_user,
                      lastupdate = sysdate
                  where taskid = in_taskid
                    and lpid = in_plannedlp;

               update batchtasks
                  set fromsection = pln.section,
                      fromloc = pln.location,
                      fromprofile = pln.equipprof,
                      lpid = in_plannedlp,
                      lastuser = in_user,
                      lastupdate = sysdate,
                      locseq = pln.pickingseq,
                      pickingzone = pln.pickingzone
                  where taskid = in_taskid
                    and lpid = in_pickedlp;

               update batchtasks
                  set fromsection = pik.section,
                      fromloc = pik.location,
                      fromprofile = pik.equipprof,
                      lpid = in_pickedlp,
                      lastuser = in_user,
                      lastupdate = sysdate,
                      locseq = pik.pickingseq,
                      pickingzone = pik.pickingzone
                  where taskid = in_taskid
                    and lpid = '((switching))';

               l_batchswaplp := in_pickedlp;
               l_batchswaploc := pik.location;
            else
               -- only update picked qty of batchtasks splitting if necessary
               -- try for a single batchtask first
               l_btqty := in_qty;
               for bt in (select rowid, batchtasks.* from batchtasks
                           where taskid = in_taskid
                             and lpid = in_plannedlp
                             and qty = in_qty) loop
               update batchtasks
                  set fromsection = pik.section,
                      fromloc = pik.location,
                      fromprofile = pik.equipprof,
                      lpid = in_pickedlp,
                      lastuser = in_user,
                      lastupdate = sysdate,
                      locseq = pik.pickingseq,
                      pickingzone = pik.pickingzone
                     where rowid = bt.rowid;
                  l_btqty := 0;
                  exit;
               end loop;

               -- single not found, loop thru all applicable batchtasks
               if l_btqty > 0 then
                  for bt in (select rowid, batchtasks.* from batchtasks
                  where taskid = in_taskid
                                and lpid = in_plannedlp) loop

                     if bt.qty <= l_btqty then
                        update batchtasks
                           set fromsection = pik.section,
                               fromloc = pik.location,
                               fromprofile = pik.equipprof,
                               lpid = in_pickedlp,
                               lastuser = in_user,
                               lastupdate = sysdate,
                               locseq = pik.pickingseq,
                               pickingzone = pik.pickingzone
                           where rowid = bt.rowid;
                        l_btqty := l_btqty - bt.qty;
                        exit when l_btqty = 0;
                     else
                        -- split the batchtask
                        l_splitfact := l_btqty / bt.qty;
                        insert into batchtasks
                           (taskid, tasktype, facility, fromsection, fromloc,
                            fromprofile, tosection, toloc, toprofile, touserid,
                            custid, item, lpid, uom, qty,
                            locseq, loadno, stopno, shipno, orderid,
                            shipid, orderitem, orderlot, priority, prevpriority,
                            curruserid, lastuser, lastupdate, pickuom, pickqty,
                            picktotype, wave, pickingzone, cartontype,
                            weight, cube, staffhrs,
                            cartonseq, shippinglpid, shippingtype,
                            invstatus, inventoryclass, qtytype, lotnumber)
                        values
                           (bt.taskid, bt.tasktype, bt.facility, pik.section, pik.location,
                            pik.equipprof, bt.tosection, bt.toloc, bt.toprofile, bt.touserid,
                            bt.custid, bt.item, in_pickedlp, bt.uom, l_btqty,
                            pik.pickingseq, bt.loadno, bt.stopno, bt.shipno, bt.orderid,
                            bt.shipid, bt.orderitem, bt.orderlot, bt.priority, bt.prevpriority,
                            bt.curruserid, in_user, sysdate, bt.pickuom, l_btqty,
                            bt.picktotype, bt.wave, pik.pickingzone, bt.cartontype,
                            l_splitfact * bt.weight, l_splitfact * bt.cube, l_splitfact * bt.staffhrs,
                            bt.cartonseq, bt.shippinglpid, bt.shippingtype,
                            bt.invstatus, bt.inventoryclass, bt.qtytype, bt.lotnumber);

                        update batchtasks
                           set qty = bt.qty - l_btqty,
                               pickqty = bt.qty - l_btqty,
                               weight = bt.weight - (l_splitfact * bt.weight),
                               cube = bt.cube - (l_splitfact * bt.cube),
                               staffhrs = bt.staffhrs - (l_splitfact * bt.staffhrs),
                               lastuser = in_user,
                               lastupdate = sysdate
                           where rowid = bt.rowid;

                        exit;
                     end if;
                  end loop;
               end if;

               l_batchswaplp := in_pickedlp;
               l_batchswaploc := pik.location;
            end if;
         end if;
         update plate
            set destfacility = pdfac,
                destlocation = pdloc,
                lasttask = in_tasktype,
                lastuser = in_user,
                lastoperator = in_user,
                lastupdate = sysdate
            where lpid = in_pickedlp;
      else
         -- only update picked qty of batchtasks splitting if necessary
         -- try for a single batchtask first
         l_btqty := in_qty;
         for bt in (select rowid, batchtasks.* from batchtasks
                     where taskid = in_taskid
                       and lpid = in_plannedlp
                       and qty = in_qty) loop
            update batchtasks
               set fromsection = pik.section,
                   fromloc = pik.location,
                   fromprofile = pik.equipprof,
                   lpid = in_pickedlp,
                   lastuser = in_user,
                   lastupdate = sysdate,
                   locseq = pik.pickingseq,
                   pickingzone = pik.pickingzone
               where rowid = bt.rowid;
            l_btqty := 0;
            exit;
         end loop;

         -- single not found, loop thru all applicable batchtasks
         if l_btqty > 0 then
            for bt in (select rowid, batchtasks.* from batchtasks
                        where taskid = in_taskid
                          and lpid = in_plannedlp) loop

               if bt.qty <= l_btqty then
                  update batchtasks
                     set fromsection = pik.section,
                         fromloc = pik.location,
                         fromprofile = pik.equipprof,
                         lpid = in_pickedlp,
                         lastuser = in_user,
                         lastupdate = sysdate,
                         locseq = pik.pickingseq,
                         pickingzone = pik.pickingzone
                     where rowid = bt.rowid;
                  l_btqty := l_btqty - bt.qty;
                  exit when l_btqty = 0;
               else
                  -- split the batchtask
                  l_splitfact := l_btqty / bt.qty;
                  insert into batchtasks
                     (taskid, tasktype, facility, fromsection, fromloc,
                      fromprofile, tosection, toloc, toprofile, touserid,
                      custid, item, lpid, uom, qty,
                      locseq, loadno, stopno, shipno, orderid,
                      shipid, orderitem, orderlot, priority, prevpriority,
                      curruserid, lastuser, lastupdate, pickuom, pickqty,
                      picktotype, wave, pickingzone, cartontype,
                      weight, cube, staffhrs,
                      cartonseq, shippinglpid, shippingtype,
                      invstatus, inventoryclass, qtytype, lotnumber)
                  values
                     (bt.taskid, bt.tasktype, bt.facility, pik.section, pik.location,
                      pik.equipprof, bt.tosection, bt.toloc, bt.toprofile, bt.touserid,
                      bt.custid, bt.item, in_pickedlp, bt.uom, l_btqty,
                      pik.pickingseq, bt.loadno, bt.stopno, bt.shipno, bt.orderid,
                      bt.shipid, bt.orderitem, bt.orderlot, bt.priority, bt.prevpriority,
                      bt.curruserid, in_user, sysdate, bt.pickuom, l_btqty,
                      bt.picktotype, bt.wave, pik.pickingzone, bt.cartontype,
                      l_splitfact * bt.weight, l_splitfact * bt.cube, l_splitfact * bt.staffhrs,
                      bt.cartonseq, bt.shippinglpid, bt.shippingtype,
                      bt.invstatus, bt.inventoryclass, bt.qtytype, bt.lotnumber);

                  update batchtasks
                     set qty = bt.qty - l_btqty,
                         pickqty = bt.qty - l_btqty,
                         weight = bt.weight - (l_splitfact * bt.weight),
                         cube = bt.cube - (l_splitfact * bt.cube),
                         staffhrs = bt.staffhrs - (l_splitfact * bt.staffhrs),
                         lastuser = in_user,
                         lastupdate = sysdate
                     where rowid = bt.rowid;

                  exit;
               end if;
            end loop;
         end if;

         l_batchswaplp := in_pickedlp;
         l_batchswaploc := pik.location;
      end if;

--    update the original task data

      open c_task;
      fetch c_task into tsk;
      close c_task;
      if (tsk.lpid is not null) then
         tsk.lpid := in_pickedlp;
      end if;

      update subtasks
         set fromsection = pik.section,
             fromloc = pik.location,
             fromprofile = pik.equipprof,
             lpid = in_pickedlp,
             lastuser = in_user,
             lastupdate = sysdate,
             locseq = pik.pickingseq,
             pickingzone = pik.pickingzone
         where rowid = chartorowid(in_subtask_rowid);

      update tasks
         set fromsection = pik.section,
             fromloc = pik.location,
             fromprofile = pik.equipprof,
             lpid = tsk.lpid,
             lastuser = in_user,
             lastupdate = sysdate,
             locseq = pik.pickingseq,
             pickingzone = pik.pickingzone
         where rowid = tsk.rowid;
   end if;

   if (in_tasktype != 'SO') then
      pik := null;
      open c_lp(in_pickedlp);
      fetch c_lp into pik;
      close c_lp;
      if nvl(pik.status, '?') not in ('A', '?') then
         out_message := 'LP unavailable';
         rollback;
         return;
      end if;
   end if;

   if (in_tasktype = 'SO' and in_shlpid is not null)
   then
    select lotnumber
    into v_shlpid_lotno
    from shippingplate
    where lpid = in_shlpid;
   end if;

   if (cordid != 0) then
      zcord.cons_plate_pick(in_taskid, in_user, nvl(l_batchswaplp, in_plannedlp), in_pickedlp,
            in_custid, in_item, in_orderitem, in_lotno, stsk.orderid, stsk.shipid,
            in_qty, in_dropseq, in_pickfac, in_pickloc, nvl(v_shlpid_lotno, in_lplotno), in_mlip,
            in_tasktype, in_picktotype, nvl(l_batchswaploc, in_fromloc), in_subtask_rowid,
            in_extra_process, in_picked_child, in_pkd_lotno, in_pkd_serialno,
            in_pkd_user1, in_pkd_user2, in_pkd_user3, out_lpcount, out_error, msg);
      out_message := msg;

     if cus.paperbased = 'N' then
         if swappedlp.lpid is not null then
            pln := swappedlp;
         else
            open c_lp(in_taskedlp);
            fetch c_lp into pln;
            close c_lp;
         end if;

         if pln.lpid is not null
            and pln.type in ('PA','MP')
            and pln.parentlpid is null
            and pln.loctype = 'STO' then
            if pln.qtytasked > in_qty then
               pln.qtytasked := pln.qtytasked - in_qty;
            else
               pln.qtytasked := null;
            end if;

            update plate
               set qtytasked = pln.qtytasked
             where lpid = pln.lpid;
         end if;
      end if;

      if (msg is not null) then
         rollback;
      end if;
      return;
   end if;

   if (nvl(in_extra_process, '?') in ('1', '2')) then
      pickedlp := in_picked_child;
   elsif (in_tasktype = 'SO') and (nvl(pln.virtuallp,'N') != 'Y') then
      open c_slp;
      fetch c_slp into pickedlp;
      if c_slp%notfound then
         open c_smp(nvl(v_shlpid_lotno, in_lplotno));
         fetch c_smp into pickedlp;
         if c_smp%notfound then
            pickedlp := in_pickedlp;
         end if;
         close c_smp;
      end if;
      close c_slp;
   else
      pickedlp := in_pickedlp;
   end if;
   pickedlot := nvl(v_shlpid_lotno, in_lplotno);
   if (pickedlp is not null) then
      open c_lp(pickedlp);
      fetch c_lp into pik;
      close c_lp;
      -- if multi-plate then need columns from any child for the item
      if pik.type in ('MP','TO')
      and nvl(itv.track_picked_pf_lps,'N') = 'N' then
         open c_kid(pickedlp, in_custid, in_item);
         fetch c_kid into kid;
         close c_kid;
         pik.lotnumber := kid.lotnumber;
         pik.useritem1 := kid.useritem1;
         pik.useritem2 := kid.useritem2;
         pik.useritem3 := kid.useritem3;
         pik.serialnumber := kid.serialnumber;
         pik.inventoryclass := kid.inventoryclass;
         pik.invstatus := kid.invstatus;
      end if;
      if ((nvl(v_shlpid_lotno, in_lplotno) is null) and (pik.lotnumber is not null)) then
         pickedlot := pik.lotnumber;
      end if;
   else
      open c_loc;
      fetch c_loc into pik;
      close c_loc;
   end if;

   if (in_lotno is not null) then
   itemlot := nvl(pickedlot, in_lotno);
   else
    itemlot := null;
   end if;

   if (stsk.orderid != 0) and (cordid = 0) then
      zoh.add_orderhistory_item(stsk.orderid, stsk.shipid,
            in_shlpid, in_item, nvl(in_pkd_lotno, pickedlot),
            'Pick Plate',
            'Pick Qty:'||in_qty||' from LP:'||pickedlp,
            in_user, errmsg);
   end if;

-- update the shipping plate
   open c_itemview(in_item);
   fetch c_itemview into itv;
   close c_itemview;
   if (in_shlpid is not null) then
      begin
         select inventoryclass, invstatus
            into invclass, invstats
            from shippingplate
         where lpid = in_shlpid;
      exception
         when NO_DATA_FOUND then
            invclass := null;
            invstats := null;
      end;

     select count(1)
     into v_update_fromlpid
     from plate
     where lpid = pickedlp and type = 'TO';

    if (l_picktype = 'P' and in_tasktype in ('OP','PK','BP') and in_mlip is null) then
      out_message := 'master lip is required';
      return;
    end if;

      update shippingplate
         set location = in_user,
             status = 'P',
             fromlpid = case when v_update_fromlpid > 0 then fromlpid else pickedlp end,
             serialnumber = nvl(in_pkd_serialno, decode(pickedlp,
                  null, nvl(pik.serialnumber, serialnumber), pik.serialnumber)),
             lastuser = in_user,
             lastupdate = sysdate,
             dropseq = in_dropseq,
             lotnumber = nvl(in_pkd_lotno, decode(pickedlp,
                  null, nvl(pickedlot, lotnumber), pickedlot)),
             quantity = in_qty,
             weight = decode(stsk.step1_complete, 'Y', weight, l_weight),
             pickedfromloc = in_pickloc,
             useritem1 = nvl(in_pkd_user1, decode(pickedlp,
                  null, nvl(pik.useritem1, useritem1), pik.useritem1)),
             useritem2 = nvl(in_pkd_user2, decode(pickedlp,
                  null, nvl(pik.useritem2, useritem2), pik.useritem2)),
             useritem3 = nvl(in_pkd_user3, decode(pickedlp,
                  null, nvl(pik.useritem3, useritem3), pik.useritem3)),
             fromlpidparent = pik.parentlpid,
             inventoryclass = nvl(pik.inventoryclass, inventoryclass),
             invstatus = nvl(pik.invstatus, invstatus),
             type = l_picktype,
             pickqty = in_pickqty,
             pickuom = l_pickuom,
             totelpid = decode(in_picktotype, 'TOTE', in_mlip, null),
             unitofmeasure = nvl(unitofmeasure, l_uom),
             manufacturedate = pik.manufacturedate,
             expirationdate = pik.expirationdate,
             origfromlpqty = decode(in_tasktype,'OP',pik.qtyrcvd,'PK',pik.qtyrcvd,null),
             length = decode(l_picktype,'F',pik.length,length),
             width = decode(l_picktype,'F',pik.width,width),
             height = decode(l_picktype,'F',pik.height,height),
             pallet_weight = decode(l_picktype,'F',pik.pallet_weight,pallet_weight)
         where lpid = in_shlpid;
   end if;

   err := 'N';
   msg := null;
   if (in_tasktype = 'BP') then
--    special batch pick processing
      zplp.build_batchpick_parentlp(in_mlip, in_picktotype, in_pickfac, in_user,
            in_qty, in_user, in_taskid, in_dropseq, in_custid, in_item,
            itemlot, pickedlp, in_picktype, in_pickloc, l_uom, in_orderitem,
            in_lotno, nvl(l_batchswaplp, in_plannedlp), nvl(l_batchswaploc, in_fromloc),
            in_subtask_rowid, err, msg);
   elsif (in_mlip is not null) then
      check_mlip(in_mlip, in_custid, stsk.orderid, stsk.shipid, stsk.loadno, stsk.stopno,
         in_picktotype, oh.ordertype, cus.mixed_order_shiplp_ok, err, msg);
      if msg is null then
         if (nvl(in_picktotype,'??') = 'TOTE') then
--          tote handling
            zplp.build_tote_from_shippingplate(in_mlip, in_shlpid, in_user,
                  in_tasktype, in_taskid, in_dropseq, in_pickloc, err, msg);
         elsif (oh.ordertype = 'K') then
--          kit handling
            bld_kit_partial(in_shlpid, pickedlp, in_mlip, in_qty, in_user,
                  in_tasktype, in_taskid, in_pickfac, in_pickloc, in_custid, in_item,
                  itemlot, l_uom, stsk.orderid, stsk.shipid, err, msg);
         elsif (nvl(in_picktotype,'??') = 'PACK') then
--          carton handling
            build_carton(in_mlip, in_shlpid, in_user, 'N', in_tasktype, stsk.cartontype, msg);
            if (msg is not null) then
               err := 'Y';
            end if;
         else
--          master shippingplate handling
            build_mast_shlp(in_mlip, in_shlpid, in_user, in_tasktype, builtmlip, msg);
            if (msg is not null) then
               err := 'Y';
            end if;
         end if;
      end if;
   end if;
   if (msg is not null) then
      out_error := err;
      out_message := msg;
      rollback;
      return;
   end if;

   if (in_tasktype != 'BP') then
      if stsk.orderid != 0 then

--       add any component commitments not to exceed ordered qty
         if ((oh.ordertype = 'K') and (poh.componenttemplate is not null)) then
            open c_od(oh.parentorderid, oh.parentshipid, in_item, in_lotno);
            fetch c_od into od;
            close c_od;

            if (od.qtytocommit > 0) then
               od.qtytocommit := least(od.qtytocommit, in_qty);

               update commitments
                  set qty = qty + od.qtytocommit,
                      lastuser = in_user,
                      lastupdate = sysdate
                  where orderid = oh.parentorderid
                    and shipid = oh.parentshipid
                    and orderitem = in_orderitem
                    and nvl(orderlot, '(none)') = nvl(in_lotno, '(none)')
                    and item = in_item
                    and nvl(lotnumber, '(none)') = nvl(in_lotno, '(none)')
                    and inventoryclass = invclass
                    and invstatus = invstats
                    and status = 'CM';
               if (sql%rowcount = 0) then
                  insert into commitments
                     (facility, custid, item, inventoryclass, invstatus, status,
                      lotnumber, uom, qty, orderid,
                      shipid, orderitem, priority, lastuser, lastupdate,
                      orderlot)
                  values
                     (in_pickfac, in_custid, in_item, invclass, invstats, 'CM',
                      in_lotno, od.uom, od.qtytocommit, oh.parentorderid,
                      oh.parentshipid, in_orderitem, od.priority, in_user, sysdate,
                      in_lotno);
               end if;
            end if;
         end if;

--       update commitments
         update commitments
            set qty = qty - in_qty,
                lastuser = in_user,
                lastupdate = sysdate
            where orderid = stsk.orderid
              and shipid = stsk.shipid
              and orderitem = in_orderitem
              and nvl(orderlot, '(none)') = nvl(in_lotno, '(none)')
              and item = in_item
              and nvl(lotnumber, '(none)') = nvl(in_lotno, '(none)')
              and inventoryclass = invclass
              and invstatus = invstats
              and status = 'CM'
            returning qty, rowid into remqty, l_rowid;
         if (sql%rowcount != 0) then
            if (remqty <= 0) then
               delete commitments
                   where rowid = l_rowid;
               if (remqty < 0) and (cus.allow_overpicking != 'Y') then
                      auxmsg := null;
                      zms.log_msg('PICK_A_PLATE', in_pickfac, in_custid,
                        'orderid=' || stsk.orderid || ' shipid=' || stsk.shipid
                        || ' orderitem=' || in_orderitem || ' item=' || in_item
                        || ' lot=' || in_lotno || ' class=' || invclass
                        || ' status=' || invstats || ' remqty=' || remqty, 'W', in_user, auxmsg);
               end if;
            end if;
         elsif (oh.orderstatus != 'X') then

--          order has *NOT* been cancelled
            if (in_plannedlp is not null) and (cus.allow_overpicking != 'Y') then
               auxmsg := null;
               zms.log_msg('PICK_A_PLATE', in_pickfac, in_custid,
                     'No commitments: orderid=' || stsk.orderid || ' shipid=' || stsk.shipid
                     || ' orderitem=' || in_orderitem || ' item=' || in_item
                     || ' lot=' || in_lotno || ' class=' || invclass
                     || ' status=' || invstats, 'W', in_user, auxmsg);
            else
--
--             no commitments were updated and we're picking from a pickfront,
--             so there could be something screwy with the picked lot (the
--             ordered lot should be OK), so let's give it a try...
--
               qtytouncommit := in_qty;
               for com in c_commit loop
                  if (com.qty <= qtytouncommit) then
                     delete commitments
                        where rowid = com.rowid;
                     qtytouncommit := qtytouncommit - com.qty;
                  else
                     update commitments
                        set qty = qty - qtytouncommit,
                            lastuser = in_user,
                            lastupdate = sysdate
                        where rowid = com.rowid;
                     qtytouncommit := 0;
                  end if;
                  exit when (qtytouncommit = 0);
               end loop;
               if (qtytouncommit != 0) and (cus.allow_overpicking != 'Y') then
                  auxmsg := null;
                  zms.log_msg('PICK_A_PLATE', in_pickfac, in_custid,
                        'Uncommitments left: orderid=' || stsk.orderid || ' shipid=' || stsk.shipid
                        || ' orderitem=' || in_orderitem || ' item=' || in_item
                        || ' lot=' || in_lotno || ' class=' || invclass || ' status=' || invstats
                        || ' qtyleft=' || qtytouncommit, 'W', in_user, auxmsg);
               end if;
            end if;
         end if;
      end if;

      if (nvl(in_picktotype,'??') != 'TOTE') then
         if pik.type = 'MP'
         and (in_picktype != 'F')
         and (itv.lotrequired in ('Y','O','S')
           or (itv.serialrequired = 'Y' and itv.serialasncapture != 'Y')
           or (itv.user1required = 'Y' and itv.user1asncapture != 'Y')
           or (itv.user2required = 'Y' and itv.user2asncapture != 'Y')
           or (itv.user3required = 'Y' and itv.user3asncapture != 'Y')) then
            l_partmpcpt := true;
         end if;

         if (pickedlp is not null)
          and (not l_partmpcpt)
          and (nvl(itv.track_picked_pf_lps,'N') = 'N'
            or in_tasktype != 'SO'
            or pik.type not in ('MP','TO')) then
--          update picked plate(s)

            if oh.ordertype = 'K' then
               add_workorderpick(pickedlp, in_qty);
            end if;

            if (l_picktype = 'F' and pik.type != 'TO') then
               if (in_qty > pik.quantity) then
                  out_message := 'Qty not avail';
                  rollback;
                  return;
               end if;

               if (nvl(in_extra_process, '?') != '2') then
                  update plate
                     set status = 'P',
                         location = in_user,
                         lasttask = in_tasktype,
                         taskid = in_taskid,
                         lastoperator = in_user,
                         lastuser = in_user,
                         lastupdate = sysdate
                     where lpid in (select lpid from plate
                                       start with lpid = pickedlp
                                       connect by prior lpid = parentlpid);
                  if (pik.parentlpid is not null) then
                     zplp.detach_child_plate(pik.parentlpid, pickedlp, in_user, null,
                           null, 'P', in_user, in_tasktype, msg);
                  end if;
                  if msg is null then
                     zcwt.process_weight_difference(pickedlp, l_weight, pik.weight,
                           in_user, 'F', msg);
                  end if;
                  if (msg is not null) then
                     out_error := 'Y';
                     out_message := msg;
                     rollback;
                     return;
                  end if;
               end if;
            else
               -- if MP or TO, need to find a child plate for weight difference processing
               if pik.type in ('MP','TO') then
                  if (itemlot is null) then
                     select lpid into l_lpid
                        from plate
                        where custid = in_custid
                          and item = in_item
                          and unitofmeasure = l_uom
                          and type = 'PA'
                          and parentlpid = pickedlp
                          and rownum = 1;
                  else
                     select lpid into l_lpid
                        from plate
                        where custid = in_custid
                          and item = in_item
                          and lotnumber = itemlot
                          and unitofmeasure = l_uom
                          and type = 'PA'
                          and parentlpid = pickedlp
                          and rownum = 1;
                  end if;
               else
                  l_lpid := pickedlp;
               end if;

               zrf.decrease_lp(pickedlp, in_custid, in_item, in_qty, itemlot,
                     l_uom, in_user, in_tasktype, invstats, invclass, err, msg);
               if (err = 'N') and (msg is null) then
                  zcwt.process_weight_difference(l_lpid, l_weight, pik.weight, in_user, 'P', msg);
                  if msg is not null then
                     err := 'Y';
                  end if;
               end if;
               if (err != 'N') or (msg is not null) then
                  out_error := err;
                  out_message := msg;
                  rollback;
                  return;
               end if;
            end if;
         else
--       update 'required' plates that have item

            if ((nvl(itv.track_picked_pf_lps,'N') = 'Y'
             and in_tasktype = 'SO'
             and pik.type in ('MP','TO'))
            or l_partmpcpt) then
               pik.quantity := in_qty;
               if (itemlot is null) then
                  open c_any_lp for
                     select lpid, quantity, invstatus, inventoryclass, serialnumber,
                            useritem1, useritem2, useritem3, parentlpid, weight,
                            manufacturedate, expirationdate
                        from plate
                        where custid = in_custid
                          and item = in_item
                          and unitofmeasure = l_uom
                          and type = 'PA'
                        start with lpid = pickedlp
                        connect by prior lpid = parentlpid
                        order by manufacturedate, creationdate;
               else
                  open c_any_lp for
                     select lpid, quantity, invstatus, inventoryclass, serialnumber,
                            useritem1, useritem2, useritem3, parentlpid, weight,
                            manufacturedate, expirationdate
                        from plate
                        where custid = in_custid
                          and item = in_item
                          and unitofmeasure = l_uom
                          and lotnumber = itemlot
                          and type = 'PA'
                        start with lpid = pickedlp
                        connect by prior lpid = parentlpid
                        order by manufacturedate, creationdate;
               end if;
            else
               if (itemlot is null) then
                  open c_any_lp for
                     select lpid, quantity, invstatus, inventoryclass, serialnumber,
                            useritem1, useritem2, useritem3, parentlpid, weight,
                            manufacturedate, expirationdate
                        from plate
                        where facility = in_pickfac
                          and location = in_pickloc
                          and custid = in_custid
                          and item = in_item
                          and unitofmeasure = l_uom
                          and type = 'PA'
                          and status = 'A'
                          and quantity > 0
                        order by manufacturedate, creationdate;
               else
                  open c_any_lp for
                     select lpid, quantity, invstatus, inventoryclass, serialnumber,
                            useritem1, useritem2, useritem3, parentlpid, weight,
                            manufacturedate, expirationdate
                        from plate
                        where facility = in_pickfac
                          and location = in_pickloc
                          and custid = in_custid
                          and item = in_item
                          and lotnumber = itemlot
                          and unitofmeasure = l_uom
                          and type = 'PA'
                          and status = 'A'
                          and quantity > 0
                        order by manufacturedate, creationdate;
               end if;
            end if;

            pik.weight := l_weight;
            l_iteration := 1;
            loop
               fetch c_any_lp into l;
               exit when c_any_lp%notfound;

               if ((nvl(itv.track_picked_pf_lps,'N') = 'N'
                or in_tasktype != 'SO'
                or pik.type not in ('MP','TO'))
               and not l_partmpcpt) then
                  if ((l.serialnumber is not null
                        and itv.serialrequired != 'Y' and itv.serialasncapture = 'Y')
                  or  (l.useritem1 is not null
                        and itv.user1required != 'Y' and itv.user1asncapture = 'Y')
                  or  (l.useritem2 is not null
                        and itv.user2required != 'Y' and itv.user2asncapture = 'Y')
                  or  (l.useritem3 is not null
                        and itv.user3required != 'Y' and itv.user3asncapture = 'Y')
                  or  (zrf.any_tasks_for_lp(l.lpid, l.parentlpid))
                  or  (not is_attrib_ok(invstind, invstlist, l.invstatus))
                  or  (not is_attrib_ok(invclind, invcllist, l.invclass))) then
                     goto continue_loop;
                  end if;
               end if;

               l_picked_qty := least(l.quantity, pik.quantity);
               if (nvl(l.quantity,0) > 0) then
                l_picked_weight := (l_picked_qty/l.quantity) * l.weight;
               else
                l_picked_weight := 0;
               end if;

               if oh.ordertype = 'K' then
                  add_workorderpick(l.lpid, l_picked_qty);
               end if;

               if (in_shlpid is not null) then
                  if nvl(itv.track_picked_pf_lps,'N') = 'N'
                  and not l_partmpcpt then
                     update shippingplate
                        set fromlpid = nvl(fromlpid, l.lpid),
                            inventoryclass = nvl(l.invclass, inventoryclass),
                            invstatus = nvl(l.invstatus, invstatus),
                            manufacturedate = l.manufacturedate,
                            expirationdate = l.expirationdate
                        where lpid = in_shlpid;
                  else
                     track_pf_lp(l_iteration, in_shlpid, l.lpid, l_picked_qty,
                           l_picked_weight, in_pkd_lotno, in_pkd_serialno,
                           in_pkd_user1, in_pkd_user2, in_pkd_user3, msg);
                     if msg is not null then
                        out_error := 'Y';
                        out_message := msg;
                        close c_any_lp;
                        rollback;
                        return;
                     end if;
                  end if;
               end if;

               zrf.decrease_lp(l.lpid, in_custid, in_item, l_picked_qty,
                     itemlot, l_uom, in_user, in_tasktype, l.invstatus, l.invclass,
                     err, msg);
               if ((err != 'N') or (msg is not null)) then
                  out_error := err;
                  out_message := msg;
                  close c_any_lp;
                  rollback;
                  return;
               end if;

               zcwt.process_weight_difference(l.lpid, l_picked_weight, l.weight,
                     in_user, 'P', msg);
               if msg is not null then
                  out_error := 'Y';
                  out_message := msg;
                  close c_any_lp;
                  rollback;
                  return;
               end if;

               pik.quantity := pik.quantity - l_picked_qty;
               pik.weight := pik.weight - l_picked_weight;
               l_iteration := l_iteration + 1;

               exit when (pik.quantity = 0);
            <<continue_loop>>
               null;
            end loop;
            close c_any_lp;
            if (pik.quantity != 0) then
               out_message := 'Qty not avail';
               rollback;
               return;
            end if;
         end if;
      end if;
   end if;

-- explode the multi if a full pick was requested and the item is "serialized"
   if ((pik.type = 'MP') and (in_picktype = 'F')
   and (itv.lotrequired in ('Y','O','S') or itv.serialrequired = 'Y' or itv.user1required = 'Y'
        or itv.user2required = 'Y' or itv.user3required = 'Y')) then
      explode_multi_lp(in_shlpid, in_mlip, pickedlp, in_user, in_picktotype, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
         rollback;
         return;
      end if;
   end if;

-- update pick counts
   update location
      set pickcount = nvl(pickcount, 0) + 1,
          lastpickedfrom = sysdate
      where facility = in_pickfac
        and locid = in_pickloc;

   update itempickfronts
      set lastpickeddate = sysdate
      where facility = in_pickfac
        and pickfront = in_pickloc;

   select count(1) into out_lpcount
      from plate
      where facility = in_pickfac
        and location = in_pickloc
        and type = 'PA'
        and status != 'P';

   update subtasks
      set qtypicked = nvl(qtypicked, 0) + in_qty
         where rowid = chartorowid(in_subtask_rowid);

   if l_flexpick then
      putaway_flex_item(stsk.wave, in_custid, in_item, in_pickfac, in_pickloc);
      out_lpcount := 0;
   else
      select count(1) into out_lpcount
         from plate
         where facility = in_pickfac
           and location = in_pickloc
           and type = 'PA'
           and status != 'P';
   end if;

   if cus.paperbased = 'N' then
      if swappedlp.lpid is not null then
         pln := swappedlp;
      else
         open c_lp(in_taskedlp);
         fetch c_lp into pln;
         close c_lp;
      end if;

      begin
        select nvl(manual_picks_yn, 'N')
        into v_manual_picks
        from orderhdr a, subtasks b
        where b.rowid = in_subtask_rowid
          and a.orderid = b.orderid and a.shipid = b.shipid;
      exception
        when others then
          v_manual_picks := 'N';
      end;

      if pln.lpid is not null and ((pln.type in ('PA','MP') and pln.parentlpid is null and pln.loctype in ('STO','CD','STG')) or v_manual_picks = 'Y') then
         if pln.qtytasked > in_qty then
            pln.qtytasked := pln.qtytasked - in_qty;
         else
            pln.qtytasked := null;
         end if;

         update plate
            set qtytasked = pln.qtytasked
            where lpid = pln.lpid;
      end if;
   end if;

   bump_custitemcount(in_custid, in_item, 'PICK', l_uom, in_qty, in_user, err, msg);

   if (cus.allow_overpicking = 'Y') then
      begin
         select parentlpid, type into lpParentlpid, lpType
            from shippingplate
            where lpid = in_shlpid;
      exception when no_data_found then
         lpType := 'F';
      end;
      if lpParentlpid is null and
         nvl(lpType,'F') <> 'F' then
            update shippingplate
               set type ='F'
               where lpid = in_shlpid;
      end if;
   end if;


   out_error := err;
   out_message := msg;

   l_elapsed_end := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'end ZRFPK.PICK_A_PLATE - ' ||
                    'out_error: ' || out_error || ', ' ||
                    'out_message: ' || out_message ||
                    'out_lpcount ' || out_lpcount ||
                    ' (Elapsed: ' ||
                    rtrim(substr(zlb.formatted_staffhrs((l_elapsed_end - l_elapsed_begin)*24),1,12)) ||
                    ')',
                    'T', in_user);
exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end pick_a_plate;


procedure stage_a_plate
   (in_shlpid        in varchar2,
    in_drop_loc      in varchar2,
    in_user          in varchar2,
    in_tasktype      in varchar2,
    in_pass          in varchar2,
    in_stage_loc     in varchar2,
    in_mass_manifest in varchar2,
    in_deconsolidate in varchar2,
    out_error        out varchar2,
    out_message      out varchar2,
    out_is_loaded    out varchar2)     -- 'Y' if load switched to status '8'; else 'N'
is
   msg varchar2(255);
   auxmsg varchar2(255);
   lptype plate.type%type;
   xrefid plate.lpid%type;
   xreftype plate.type%type;
   parentid plate.lpid%type;
   parenttype plate.type%type;
   topid plate.lpid%type;
   toptype plate.type%type;
   slip shippingplate.lpid%type;
   cursor c_slp(p_slp varchar2) is
      select rowid, taskid, orderid, shipid, fromlpid, facility,
             custid, loadno, stopno, 'N' as virtuallp
         from shippingplate
         where lpid = p_slp;
   sp c_slp%rowtype;
   cursor c_lp(p_lp varchar2) is
      select rowid, taskid, orderid, shipid, fromlpid, facility,
             custid, loadno, stopno, nvl(virtuallp, 'N') as virtuallp
         from plate
         where lpid = p_lp;
   cursor c_kid_slp (p_slp varchar2) is
      select type, taskid, lpid, orderid, shipid
         from shippingplate
         where parentlpid = p_slp;
   cursor c_kid_lp (p_lp varchar2) is
      select P.taskid, S.orderid, S.shipid
         from plate P, shippingplate S
         where P.lpid in (select lpid from plate
               start with lpid = p_lp
               connect by prior lpid = parentlpid)
           and S.lpid (+) = P.fromshippinglpid;
   cursor c_tsk (p_taskid number) is
      select priority
         from tasks
         where taskid = p_taskid;
   tsk c_tsk%rowtype;
   cursor c_sub (p_taskid number) is
      select fromsection, fromloc, fromprofile, locseq, pickingzone
         from subtasks
         where taskid = p_taskid
               order by locseq nulls last;
   sub c_sub%rowtype;
   cursor c_loc(p_facility varchar2, p_locid varchar2) is
      select loctype, section, equipprof, putawayseq, pickingseq
         from location
         where facility = p_facility
           and locid = p_locid;
   drp c_loc%rowtype := null;
   cursor c_stklp(p_lpid varchar2) is
      select wave
         from subtasks
         where lpid = p_lpid;
   stklp c_stklp%rowtype := null;
   cursor c_vlp(p_lpid varchar2) is
      select type, virtuallp, location, status
         from plate
         where lpid = p_lpid;
   vlp c_vlp%rowtype := null;
   c_anysubtask anysubtaskcur;
   st anysubtasktype;
   i binary_integer;
   notstaged integer;
   l_found boolean;
   l_passing varchar2(1) := nvl(in_pass, 'N');
   l_key number := 0;
   l_errno number;
   l_elapsed_begin date;
   l_elapsed_end date;
   v_count number;
   v_force_pick_pass varchar2(1) := 'N';
begin
   l_elapsed_begin := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'begin ZRFPK.STAGE_A_PLATE - ' ||
                    'in_shlpid: ' || in_shlpid || ', ' ||
                    'in_drop_loc: ' || in_drop_loc || ', ' ||
                    'in_user: ' || in_user || ', ' ||
                    'in_tasktype: ' || in_tasktype || ', ' ||
                    'in_pass: ' || in_pass || ', ' ||
                    'in_stage_loc: ' || in_stage_loc || ', ' ||
                    'in_mass_manifest: ' || in_mass_manifest || ', ' ||
                    'in_deconsolidate: ' || in_deconsolidate,
                    'T', in_user);
   out_error := 'N';
   out_message := null;
   out_is_loaded := 'N';

   zrf.identify_lp(in_shlpid, lptype, xrefid, xreftype, parentid, parenttype,
         topid, toptype, msg);
   if (msg is not null) then
      out_error := 'Y';
      out_message := substr(msg, 1, 80);
      return;
   end if;

   if (lptype = 'DP') then
      out_message := 'LP is deleted';
      return;
   end if;

   if (lptype = '?') then
      out_message := 'Plate not found';
      return;
   end if;

-- find highest parent to work with
   if (in_tasktype = 'BP') then
      slip := nvl(topid, nvl(parentid, in_shlpid));
      lptype := nvl(toptype, nvl(parenttype, lptype));
   else
      slip := nvl(topid, nvl(parentid, nvl(xrefid, in_shlpid)));
      lptype := nvl(toptype, nvl(parenttype, nvl(xreftype, lptype)));
   end if;

   zrf.so_lock(l_key);
   if (lptype in ('C', 'F', 'M', 'P')) then
      open c_slp(slip);
      fetch c_slp into sp;
      close c_slp;
   else
      open c_lp(slip);
      fetch c_lp into sp;
      close c_lp;
   end if;

   open c_loc(sp.facility, in_drop_loc);
   fetch c_loc into drp;
   l_found := c_loc%found;
   close c_loc;
   if not l_found then
      out_message := 'Drop loc not found';
      zrf.so_release(l_key);
      return;
   end if;

   if (drp.loctype = 'PND' and l_passing = 'N') then
    begin
      select nvl(allowpickpassing,'N') into v_force_pick_pass
      from customer
      where custid = sp.custid;
    exception
      when others then
        null;
    end;
   end if;

   zso.get_rf_lock(sp.loadno,sp.orderid,sp.shipid,in_user,msg);
   if substr(msg,1,4) != 'OKAY' then
     out_message := substr(msg,1,80);
     return;
   end if;
   tid_tbl.delete;
   ord_tbl.delete;
   if (lptype in ('C', 'F', 'M', 'P')) then

--    update the shipping plate

      if (lptype = 'F') then
         update plate
            set status = decode(in_deconsolidate, 'Y', 'A', 'P')
            where lpid = sp.fromlpid;
      end if;

--    insure load id set correctly for consolidated order
      if sp.orderid != 0 then
         update shippingplate
            set loadno = zcord.cons_loadno(sp.orderid, sp.shipid),
                stopno = zcord.cons_stopno(sp.orderid, sp.shipid),
                shipno = zcord.cons_shipno(sp.orderid, sp.shipid)
            where lpid in (select lpid from shippingplate
                     start with rowid = sp.rowid
                     connect by prior lpid = parentlpid);
      end if;

      zrf.move_shippingplate(sp.rowid, in_drop_loc, 'S', in_user, in_tasktype, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := substr(msg, 1, 80);
         return;
      end if;

      add_tid_to_tbl(sp.taskid);
      add_ord_to_tbl(sp.orderid, sp.shipid);
      if (lptype = 'C') then
         add_ctn_to_tbls(slip);
      else
         for sk in c_kid_slp(slip) loop
            if (sk.type = 'C') then
               add_ctn_to_tbls(sk.lpid);
            else
               add_tid_to_tbl(sk.taskid);
               add_ord_to_tbl(sk.orderid, sk.shipid);
            end if;
         end loop;
      end if;

      if (l_passing = 'N') then
         if drp.loctype not in ('PND','XFR') then
            zmn.stage_carton(slip, 'stage', msg);
            if (msg != 'OKAY') and (msg != 'Not a MultiShip Carrier') then
               auxmsg := null;
               zms.log_autonomous_msg('MULTISHIP', sp.facility, sp.custid,
                     msg || ' on LP ' || slip, 'W', in_user, auxmsg);
            end if;
         end if;
      else
         update shippingplate
            set dropseq = -abs(dropseq)
            where lpid in (select lpid from shippingplate
                     start with rowid = sp.rowid
                     connect by prior lpid = parentlpid);
      end if;
   else

--    update plates
      update plate
         set location = in_drop_loc,
             status = decode(in_tasktype, 'BP', 'A', 'P'),
             lasttask = in_tasktype,
             lastoperator = in_user,
             lastuser = in_user,
             lastupdate = sysdate,
             dropseq = decode(l_passing, 'N', decode(v_force_pick_pass,'F',-abs(dropseq),abs(dropseq)), -abs(dropseq))
         where lpid in (select lpid from plate
                           start with rowid = sp.rowid
                           connect by prior lpid = parentlpid);

--    need to remember wave in virtual for putaway after wave complete
      if (lptype = 'MP') and (in_tasktype = 'BP') and (sp.virtuallp = 'Y') then
         open c_stklp(slip);
         fetch c_stklp into stklp;
         close c_stklp;

         update plate
            set virtualwave = stklp.wave
            where rowid = sp.rowid;
      end if;

--    update any shippingplates
      update shippingplate
         set location = in_drop_loc,
             status = decode(in_tasktype, 'BP', 'P', 'S'),
             lastuser = in_user,
             lastupdate = sysdate,
             dropseq = decode(l_passing, 'N', decode(v_force_pick_pass,'F',-abs(dropseq),abs(dropseq)), -abs(dropseq))
         where lpid in (select fromshippinglpid from plate
                           start with rowid = sp.rowid
                           connect by prior lpid = parentlpid);

      for lk in c_kid_lp(slip) loop
         add_tid_to_tbl(lk.taskid);
         if (in_tasktype != 'BP') then
            add_ord_to_tbl(lk.orderid, lk.shipid);
         end if;
      end loop;
   end if;

-- cleanup subtask(s) and task(s)
   for i in 1..tid_tbl.count loop
      update subtasks
         set step1_complete = null
         where taskid = tid_tbl(i);

      if (lptype in ('C', 'F', 'M', 'P')) then
         open c_anysubtask for
            select rowid
               from subtasks T
               where T.taskid = tid_tbl(i)
                 and T.shippinglpid is not null
                 and not exists (select * from shippingplate S
                     where S.taskid = tid_tbl(i)
                       and S.lpid = T.shippinglpid
                       and S.status in ('U', 'P'));
      elsif (in_tasktype = 'BP') then
         open c_anysubtask for
            select rowid
               from subtasks T
               where T.taskid = tid_tbl(i)
                 and T.shippinglpid in (select lpid from plate
                                          start with rowid = sp.rowid
                                          connect by prior lpid = parentlpid);
      elsif ((lptype = 'TO') and (in_tasktype != 'SO')) then
         open c_anysubtask for
            select rowid
               from subtasks T
               where T.taskid = tid_tbl(i)
                 and exists (select * from plate P
                     where P.fromshippinglpid = T.shippinglpid
                       and P.taskid = tid_tbl(i)
                       and P.status = 'P');
      else
         open c_anysubtask for
            select rowid
               from subtasks T
               where T.taskid = tid_tbl(i)
                 and exists (select * from plate P
                     where P.fromshippinglpid = T.shippinglpid
                       and P.taskid = tid_tbl(i)
                       and P.status in ('A','P'));
      end if;

      loop
         fetch c_anysubtask into st;
         exit when c_anysubtask%notfound;
         if (drp.loctype not in ('PND','XFR')) or (l_passing = 'Y') then
            zdep.del_pick_subtask(st.rid, in_user, msg);
            if (msg is not null) then
               out_error := 'Y';
               out_message := msg;
               return;
            end if;
         else
            update subtasks
               set step1_complete = 'Y'
               where rowid = st.rid;
         end if;
      end loop;
      close c_anysubtask;
   end loop;

   for i in 1..tid_tbl.count loop
      if (drp.loctype in ('PND','XFR')) and (l_passing = 'N') then
         adjust_subtask_tree(tid_tbl(i), sp.facility, in_drop_loc, in_stage_loc, in_user, msg);
         if (msg is not null) then
            out_error := 'Y';
            out_message := substr(msg, 1, 80);
            return;
         end if;
      end if;

      delete tasks T
         where T.taskid = tid_tbl(i)
           and not exists (select * from subtasks S
               where S.taskid = tid_tbl(i));

      if (drp.loctype in ('PND','XFR')) and (l_passing = 'N') then
         if (lptype in ('C', 'F', 'M', 'P')) then
            update shippingplate
               set status = 'P'
               where lpid in (select lpid from shippingplate
                                 start with rowid = sp.rowid
                                 connect by prior lpid = parentlpid);
         end if;

         if (v_force_pick_pass = 'F') then
            update tasks
               set curruserid = null,
                   clusterposition = null,
                   priority = '8',
                   lastuser = in_user,
                   lastupdate = sysdate
             where taskid = tid_tbl(i);

         if (sql%rowcount = 0) then
          -- no tasks, so set the dropseq positive so can ship
             update plate
                set dropseq = abs(dropseq)
              where taskid = tid_tbl(i);

             update shippingplate
                set dropseq = abs(dropseq)
              where taskid = tid_tbl(i);
         end if;
      end if;
      elsif ((sql%rowcount = 0) and (in_tasktype != 'BP')) then
--       no task was deleted and we're not doing a batch pick, so check for pick passing

         open c_tsk(tid_tbl(i));
         fetch c_tsk into tsk;
         close c_tsk;

         if ((tsk.priority = '7') or (l_passing = 'Y')) then
--          either the task is marked as "pass pending" or the pick is to be passed
--          count number of unstaged picks

            if (lptype in ('C', 'F', 'M', 'P')) then
               select count(1) into notstaged
                  from shippingplate
                  where taskid = tid_tbl(i)
                    and status = 'P'
                    and location = in_user;
            else
               select count(1) into notstaged
                  from plate
                  where fromshippinglpid in (select lpid from shippingplate
                                                where taskid = tid_tbl(i))
                                                  and status = 'M';
            end if;

            if (notstaged = 0) then
--             everything staged

               open c_sub(tid_tbl(i));
               fetch c_sub into sub;
               close c_sub;
               update tasks
                  set fromloc = sub.fromloc,
                      curruserid = null,
                      clusterposition = null,
                      priority = '8',
                      lastuser = in_user,
                      lastupdate = sysdate,
                      fromsection = sub.fromsection,
                      fromprofile = sub.fromprofile,
                      locseq = sub.locseq,
                      pickingzone = sub.pickingzone,
                      convpickloc = null,
                      touserid = null
                  where taskid = tid_tbl(i);
            elsif (l_passing = 'Y') then
--             pass requested, but user still has more to stage
--             we need to mark the task as "pass pending" since we don't know what
--             the user will do with the last plate and we need to remember to pass
--             this task eventually

               update tasks
                  set priority = '7'
                  where taskid = tid_tbl(i);
            end if;
         end if;
      end if;
   end loop;

   if drp.loctype in ('PND','XFR') then
      return;
   end if;

-- update table(s) if all picks staged
   for i in 1..ord_tbl.count loop
      check_all_picked(ord_tbl(i).orderid, ord_tbl(i).shipid, in_user, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;
   end loop;

   if drp.loctype = 'DOR' then
      zms.rf_debug_msg('RFDEBUG', null, null,
                      'stage_a_plate -- door updates for shippingplate',
                      'T', in_user);
      update shippingplate
         set location = in_user
         where lpid in (select lpid from shippingplate
               start with rowid = sp.rowid
               connect by prior lpid = parentlpid);

      zrfld.load_shipplates(sp.facility, in_user, sp.loadno, sp.stopno, in_drop_loc,
            out_error, msg, out_is_loaded);
      if msg is not null then
         out_error := 'Y';
         out_message := substr(msg, 1, 80);
         return;
      end if;
   end if;

   if in_mass_manifest = 'Y' then
      zms.rf_debug_msg('RFDEBUG', null, null,
                      'stage_a_plate - call build_mass_manifest',
                      'T', in_user);
      zplp.build_mass_manifest(in_shlpid, sp.taskid, in_user, out_error, msg);
      if msg is not null then
        out_error := 'Y';
        out_message := substr(msg,1,80);
        return;
      end if;
   end if;

   if in_deconsolidate = 'Y' then
      zms.rf_debug_msg('RFDEBUG', null, null,
                      'stage_a_plate - call zgt.move_request',
                      'T', in_user);
      zgt.move_request(sp.facility, sp.fromlpid, '3', in_stage_loc, in_user, l_errno, msg, 'MV');
      if nvl(msg,'OKAY') = 'OKAY' then
         update plate
            set status = 'P'
            where lpid = sp.fromlpid;
      elsif l_errno = -1 then
         out_message := 'Move LP not found';
      elsif l_errno = -2 then
         out_message := 'Bad move LP status';
      elsif l_errno = -3 then
         out_message := 'Bad move LP type';
      elsif l_errno = -4 then
         out_message := 'Bad move LP facility';
      elsif l_errno = -22 then
         out_message := 'Move LP has parent';
      elsif l_errno = -5 then
         out_message := 'Invalid move to loc';
      elsif l_errno = -6 then
         out_message := 'No door for to loc';
      elsif l_errno = -7 then
         out_message := 'No door for from loc';
      elsif l_errno = -8 then
         out_message := 'Move LP has tasks';
      elsif l_errno = -9 then
         out_message := 'No taskid for move';
      else
         out_message := msg;
         out_error := 'Y';
      end if;
   elsif lptype = 'F' then
      open c_vlp(sp.fromlpid);
      fetch c_vlp into vlp;
      close c_vlp;
      if (nvl(vlp.type,'x') = 'MP') and (nvl(vlp.virtuallp,'N') = 'Y') then
         stage_full_virtual(in_shlpid, in_user, in_tasktype, msg);
         if msg is not null then
           out_message := substr(msg,1,80);
           out_error := 'Y';
         end if;
      end if;
   end if;

   l_elapsed_end := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'end ZRFPK.STAGE_A_PLATE - ' ||
                    'out_error: ' || out_error || ', ' ||
                    'out_message: ' || out_message ||
                    ' (Elapsed: ' ||
                    rtrim(substr(zlb.formatted_staffhrs((l_elapsed_end - l_elapsed_begin)*24),1,12)) ||
                    ')',
                    'T', in_user);

   if (lptype in ('C', 'F', 'M', 'P')) then
    select count(1) into v_count
    from orderhdr
    where orderid = sp.orderid and shipid = sp.shipid
      and ordertype = 'W' and workordertype = 'M';

    if (v_count > 0) then
      ship_matissue_lp(slip, in_user, out_error, out_message);
      if (out_error = 'Y') then
        return;
      end if;
    end if;
  end if;

exception
   when OTHERS then
      zms.log_autonomous_msg(in_user, null, null,
        '(ZRFPK.STAGE_A_PLATE) - ' ||
        'in_shlpid: ' || in_shlpid || ', ' ||
        'in_drop_loc: ' || in_drop_loc || ', ' ||
        'in_user: ' || in_user || ', ' ||
        'in_tasktype: ' || in_tasktype || ', ' ||
        'in_pass: ' || in_pass || ', ' ||
        'in_stage_loc: ' || in_stage_loc || ', ' ||
        'in_mass_manifest: ' || in_mass_manifest || ', ' ||
        'in_deconsolidate: ' || in_deconsolidate,
        'I', in_user, auxmsg);
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end stage_a_plate;


procedure stage_for_kitting
   (in_lpid            in varchar2,
    in_facility        in varchar2,
    in_drop_loc        in varchar2,
    in_user            in varchar2,
    in_tasktype        in varchar2,
    in_workorderseq    in number,
    in_workordersubseq in number,
    in_stage_loc       in varchar2,
    out_error          out varchar2,
    out_message        out varchar2)
is
   msg varchar2(80);
   parentseq custworkorderinstructions.parent%type;
   sseq custworkorderinstructions.subseq%type;
   cursor c_kid is
      select rowid, taskid, orderid, shipid, type, quantity, item, custid
         from shippingplate
         where facility = in_facility
           and location = in_user
           and status = 'P'
           and fromlpid in (select lpid from plate
                         start with lpid = in_lpid
                         connect by prior lpid = parentlpid);
   cursor c_subtasks(p_taskid number) is
      select rowid
         from subtasks T
         where T.taskid = p_taskid
           and not exists (select * from shippingplate S
               where S.taskid = p_taskid
                 and S.lpid = T.shippinglpid
                 and S.status in ('U', 'P'));
   cursor c_itemlist (p_custid varchar2, p_item varchar2) is
      select p_item item, -1 seq
         from dual
      union
      select item, seq
         from custitemsubs
         where custid = p_custid
           and itemsub = p_item
      order by 2, 1;
   i binary_integer;
   cursor c_loc(p_facility varchar2, p_locid varchar2) is
      select loctype, section, equipprof, putawayseq, pickingseq
         from location
         where facility = p_facility
           and locid = p_locid;
   drp c_loc%rowtype := null;
   cursor c_cwo(p_seq number) is
      select status
         from custworkorder
         where seq = p_seq;
   cwo c_cwo%rowtype := null;
   l_found boolean;
   l_key number := 0;
   l_fac plate.facility%type;
   l_loc plate.location%type;
begin
   out_error := 'N';
   out_message := null;

   open c_loc(in_facility, in_drop_loc);
   fetch c_loc into drp;
   l_found := c_loc%found;
   close c_loc;
   if not l_found then
      out_message := 'Drop loc not found';
      return;
   end if;

   open c_cwo(in_workorderseq);
   fetch c_cwo into cwo;
   close c_cwo;

   tid_tbl.delete;
   ord_tbl.delete;
   cwo_tbl.delete;
   zrf.so_lock(l_key);
   for l in c_kid loop
      if (l.type in ('F', 'P')) then
         add_cwo_to_tbl(l.custid, l.item, l.quantity);
      end if;
      add_tid_to_tbl(l.taskid);
      add_ord_to_tbl(l.orderid, l.shipid);
      if drp.loctype not in ('PND','XFR') then
         delete shippingplate
            where rowid = l.rowid;
      end if;
   end loop;

   update plate
      set location = in_drop_loc,
          status = decode(cwo.status, 'C', 'A', decode(drp.loctype,'PND','P','XFR','P','K')),
          lasttask = in_tasktype,
          lastoperator = in_user,
          lastuser = in_user,
          lastupdate = sysdate,
          workorderseq = decode(cwo.status, 'C', null, in_workorderseq),
          workordersubseq = decode(cwo.status, 'C', null, in_workordersubseq)
      where lpid in (select lpid from plate
                        start with lpid = in_lpid
                        connect by prior lpid = parentlpid);

-- cleanup subtask(s) and task(s)
   for i in 1..tid_tbl.count loop
      update subtasks
         set step1_complete = null
         where taskid = tid_tbl(i);

      for st in c_subtasks(tid_tbl(i)) loop
         if drp.loctype not in ('PND','XFR') then
            zdep.del_pick_subtask(st.rowid, in_user, msg);
            if (msg is not null) then
               out_error := 'Y';
               out_message := msg;
               return;
            end if;
         else
            update subtasks
               set step1_complete = 'Y'
               where rowid = st.rowid;
         end if;
      end loop;

      delete tasks T
         where T.taskid = tid_tbl(i)
           and not exists (select * from subtasks S
               where S.taskid = tid_tbl(i)
                 and nvl(step1_complete,'N') = 'N');
   end loop;

   if drp.loctype in ('PND','XFR') then
      return;
   end if;

-- update table(s) if all picks staged
   for i in 1..ord_tbl.count loop
      check_all_picked(ord_tbl(i).orderid, ord_tbl(i).shipid, in_user, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;
   end loop;

   if cwo.status = 'C' then
--    kit was closed, putaway the plate
      zput.putaway_lp('TANR', in_lpid, in_facility, in_drop_loc, in_user, 'Y',
            null, msg, l_fac, l_loc);
      if msg is not null then
         out_error := 'Y';
         out_message := msg;
      end if;
   else
--    update all movement 'first' subseq's and adjust subseq of plates
      zkit.load_custworkorder(in_workorderseq, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;
      for i in 1..cwo_tbl.count loop
         for il in c_itemlist(cwo_tbl(i).custid, cwo_tbl(i).item) loop
            sseq := zkit.first_subseq(il.item, in_facility);
            if (sseq != 0) then
               update custworkorderinstructions
                  set completedqty = nvl(completedqty, 0) + cwo_tbl(i).qty
                  where seq = in_workorderseq
                    and subseq = sseq
                    and action = 'MV'
                  returning parent into parentseq;

               if ((sql%rowcount != 0) and (nvl(parentseq, 0) != 0)) then
                  sseq := parentseq;
               end if;

               if (sseq != in_workordersubseq) then
                  update plate
                     set workordersubseq = sseq
                     where lpid in (select lpid from plate
                                       start with lpid = in_lpid
                                       connect by prior lpid = parentlpid)
                       and item = cwo_tbl(i).item;
               end if;
               exit;
            end if;
         end loop;
      end loop;
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end stage_for_kitting;


procedure add_loc_cycle_count
   (in_location     in varchar2,
    in_facility     in varchar2,
    in_reason       in varchar2,
    in_pickpriority in varchar2,
    in_user         in varchar2,
    out_message     out varchar2)
is
   tkid tasks.taskid%type;
   tkpri tasks.priority%type;
   msg varchar2(80);
   cnt integer;
   cursor c_loc(fac varchar2, loc varchar2) is
      select section, equipprof
      from location
      where facility = fac
        and locid = loc;
   fr c_loc%rowtype;
begin
   out_message := null;

   begin
      select defaultvalue into tkpri
         from systemdefaults
         where defaultid = 'CC_'||in_reason||'_PRIORITY';
   exception
      when OTHERS then
         tkpri := '9';
   end;

   if (upper(tkpri) = 'T') then
      tkpri := in_pickpriority;
   end if;

   if (tkpri not in ('1','2','3','4','9')) then
      tkpri := '9';
   end if;

   select count(1) into cnt
      from tasks
      where tasktype = 'CC'
        and facility = in_facility
        and fromloc = in_location
        and item is null;

   if (cnt = 0) then
      ztsk.get_next_taskid(tkid, msg);
      if (msg is not null) then
         out_message := msg;
      else
         open c_loc(in_facility, in_location);
         fetch c_loc into fr;
         close c_loc;

         insert into tasks
            (taskid, tasktype, facility, fromsection, fromloc,
             fromprofile, qty, priority, prevpriority, lastuser, lastupdate)
         values
            (tkid, 'CC', in_facility, fr.section, in_location,
             fr.equipprof, 1, tkpri, tkpri, in_user ,sysdate);

         insert into subtasks
            (taskid, tasktype, facility, fromsection, fromloc,
             fromprofile, qty, priority, lastuser, lastupdate)
         values
            (tkid, 'CC', in_facility, fr.section, in_location,
             fr.equipprof, 1, tkpri, in_user ,sysdate);
      end if;
   else
      update tasks
         set priority = tkpri,
             prevpriority = priority
         where tasktype = 'CC'
           and facility = in_facility
           and fromloc = in_location
           and item is null
           and priority > tkpri;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end add_loc_cycle_count;


procedure bump_custitemcount
   (in_custid    in varchar2,
    in_item      in varchar2,
    in_type      in varchar2,
    in_uom       in varchar2,
    in_cnt       in number,
    in_user      in varchar2,
    out_error    out varchar2,
    out_message  out varchar2)
is
begin
   out_error := 'N';
   out_message := null;

   if (in_custid is not null) and (in_item is not null)
   and (in_type is not null) then
      update custitemcount
         set cnt = nvl(cnt, 0) + in_cnt,
             lastuser = in_user,
             lastupdate = sysdate
         where custid = in_custid
           and item = in_item
           and type = in_type
           and uom = in_uom;
      if (sql%rowcount = 0) then
         insert into custitemcount
            (custid, item, type, uom, cnt, lastuser, lastupdate)
         values
            (in_custid, in_item, in_type, in_uom, in_cnt, in_user, sysdate);
      end if;
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end bump_custitemcount;


procedure check_pick_fifo
   (in_plannedlp  in varchar2,
    in_uom        in varchar2,
    in_qty        in number,
    in_zone       in varchar2,
    in_pickedlp   in varchar2,
    in_custid     in varchar2,
    in_item       in varchar2,
    in_lotno      in varchar2,
    out_invstatus out varchar2,
    out_invclass  out varchar2,
    out_message   out varchar2)
is
   cursor c_lp(p_lpid varchar2) is
      select type, facility,
             least(trunc(creationdate),nvl(trunc(anvdate),trunc(creationdate))) receiptdate,
             manufacturedate, expirationdate, invstatus, inventoryclass,
             item, lotnumber
         from plate
         where lpid = p_lpid;
   cursor c_mp_nolot(p_lpid varchar2) is
      select type, facility,
             least(trunc(creationdate),nvl(trunc(anvdate),trunc(creationdate))) receiptdate,
             manufacturedate, expirationdate, invstatus, inventoryclass,
             item, lotnumber
         from plate
         where parentlpid = p_lpid
           and custid = in_custid
           and item = in_item
         order by receiptdate;
   cursor c_mp_lot(p_lpid varchar2) is
      select type, facility,
             least(trunc(creationdate),nvl(trunc(anvdate),trunc(creationdate))) receiptdate,
             manufacturedate, expirationdate, invstatus, inventoryclass,
             item, lotnumber
         from plate
         where parentlpid = p_lpid
           and custid = in_custid
           and item = in_item
           and lotnumber = in_lotno
         order by receiptdate;
   pln c_lp%rowtype;
   pik c_lp%rowtype;
   cursor c_itm is
      select allocrule
         from custitemfacilityview
         where custid = in_custid
           and item = in_item
           and facility = pln.facility;
   itm c_itm%rowtype;
   cursor c_itv is
      select fifowindowdays
         from custitemview
         where custid = in_custid
           and item = in_item;
   itv c_itv%rowtype;
   cursor c_adtl is
      select nvl(datetype, 'M') as datetype
         from allocrulesdtl
         where facility = pln.facility
           and allocrule = itm.allocrule
           and nvl(invstatus, pln.invstatus) = pln.invstatus
           and nvl(inventoryclass, pln.inventoryclass) = pln.inventoryclass
           and uom = in_uom
           and in_qty between nvl(qtymin, 1) and nvl(qtymax, 9999999)
           and (nvl(pickingzone, in_zone) = in_zone or in_zone is null)
         order by priority;
   ad c_adtl%rowtype;
   rowfound boolean;
   bdate date;
   pdate date;
   l_elapsed_begin date;
   l_elapsed_end date;
begin
   l_elapsed_begin := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'begin ZRFPK.CHECK_PICK_FIFO' ||
                    'in_plannedlp: ' || in_plannedlp || ', ' ||
                    'in_uom: ' || in_uom || ', ' ||
                    'in_qty: ' || in_qty || ', ' ||
                    'in_zone: ' || in_zone || ', ' ||
                    'in_pickedlp: ' || in_pickedlp || ', ' ||
                    'in_custid: ' || in_custid || ', ' ||
                    'in_item: ' || in_item || ', ' ||
                    'in_lotno: ' || in_lotno,
                    'T', 'CHECKFIFO');
   out_message := null;

   open c_lp(in_pickedlp);
   fetch c_lp into pik;
   rowfound := c_lp%found;
   close c_lp;
   if not rowfound then
      out_message := 'Pik not found';
      return;
   end if;
   if (pik.type != 'PA') then
      if (in_lotno is null) then
         open c_mp_nolot(in_pickedlp);
         fetch c_mp_nolot into pik;
         rowfound := c_mp_nolot%found;
         close c_mp_nolot;
      else
         open c_mp_lot(in_pickedlp);
         fetch c_mp_lot into pik;
         rowfound := c_mp_lot%found;
         close c_mp_lot;
      end if;
      if not rowfound then
         out_message := 'No pik child';
         return;
      end if;
   end if;
   out_invstatus := pik.invstatus;
   out_invclass := pik.inventoryclass;

   open c_lp(in_plannedlp);
   fetch c_lp into pln;
   rowfound := c_lp%found;
   close c_lp;
   if not rowfound then    /* nothing planned, must be OK */
      return;
   end if;
   if (pln.type != 'PA') then
      if (in_lotno is null) then
         open c_mp_nolot(in_plannedlp);
         fetch c_mp_nolot into pln;
         rowfound := c_mp_nolot%found;
         close c_mp_nolot;
      else
         open c_mp_lot(in_plannedlp);
         fetch c_mp_lot into pln;
         rowfound := c_mp_lot%found;
         close c_mp_lot;
      end if;
      if not rowfound then
         out_message := 'No pln child';
         return;
      end if;
   end if;

   open c_itm;
   fetch c_itm into itm;
   rowfound := c_itm%found;
   close c_itm;
   if not rowfound then
      out_message := 'Item not found';
      return;
   end if;
   open c_itv;
   fetch c_itv into itv;
   close c_itv;

   if itm.allocrule is null then
      return;
   end if;

   open c_adtl;
   fetch c_adtl into ad;
   rowfound := c_adtl%found;
   close c_adtl;
   if not rowfound then
      return;
   end if;

   if (ad.datetype = 'L') then
      if (pln.item != pik.item)
      or (nvl(pln.lotnumber,'(none)') != nvl(pik.lotnumber,'(none)')) then
         out_message := 'Not within FIFO';
      end if;
      return;
   end if;

   if itv.fifowindowdays is null then
      return;
   end if;

   if (ad.datetype = 'E') then
      bdate := pln.expirationdate;
      pdate := pik.expirationdate;
   elsif (ad.datetype = 'M') then
      bdate := pln.manufacturedate;
      pdate := pik.manufacturedate;
   else
      bdate := pln.receiptdate;
      pdate := pik.receiptdate;
   end if;

   if to_date(pdate) not between to_date(bdate-itv.fifowindowdays)
         and to_date(bdate+itv.fifowindowdays) then
      out_message := 'Not within FIFO';
   end if;

   l_elapsed_end := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'end ZRFPK.CHECK_PICK_FIFO - ' ||
                    'out_invstatus: ' || out_invstatus || ', ' ||
                    'out_invclass: ' || out_invclass || ', ' ||
                    'out_message: ' || out_message ||
                    ' (Elapsed: ' ||
                    rtrim(substr(zlb.formatted_staffhrs((l_elapsed_end - l_elapsed_begin)*24),1,12)) ||
                    ')',
                    'T', 'CHECKFIFO');
exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end check_pick_fifo;


procedure resume_passed_pick
   (in_lpid      in varchar2,
    in_lptype    in varchar2,
    in_user      in varchar2,
    out_tasktype out varchar2,
    out_message  out varchar2)
is
   cursor c_slp is
      select facility, location
         from shippingplate
         where lpid = in_lpid;
   pl c_slp%rowtype;
   cursor c_lp is
      select facility, location
         from plate
         where lpid = in_lpid;
   c_any_task anytaskcur;
   t anytasktype;
begin
   out_message := null;
   out_tasktype := null;

   if (in_lptype in ('C', 'F', 'M', 'P')) then
      open c_slp;
      fetch c_slp into pl;
      close c_slp;

      open c_any_task for
         select distinct taskid, tasktype, picktotype
            from tasks
            where taskid in (select taskid from shippingplate
                              start with lpid = in_lpid
                              connect by prior lpid = parentlpid)
              and priority = '8';
   else
      open c_lp;
      fetch c_lp into pl;
      close c_lp;

      open c_any_task for
         select distinct taskid, tasktype, picktotype
            from tasks
            where taskid in (select taskid from plate
                              start with lpid = in_lpid
                              connect by prior lpid = parentlpid)
              and priority = '8';
   end if;

   loop
      fetch c_any_task into t;
      exit when c_any_task%notfound;

      out_tasktype := t.tasktype;

--    get all tasks
      update tasks
         set curruserid = in_user,
             prevpriority = priority,
             priority = '0'
         where taskid = t.taskid;

      if (t.tasktype = 'BP') then
--       batch picking (only) plates to consider
         update plate
            set location = in_user,
                status = 'M',
                lastuser = in_user,
                lastupdate = sysdate,
                dropseq = abs(dropseq)
            where facility = pl.facility
              and location = pl.location
              and taskid = t.taskid
              and status = 'P'
              and dropseq < 0;
      else
--       non-batch picking
--       do all shippingplates
         update shippingplate
            set location = in_user,
                status = 'P',
                lastuser = in_user,
                lastupdate = sysdate,
                dropseq = abs(dropseq)
            where facility||'' = pl.facility
              and location||'' = pl.location
              and taskid = t.taskid
              and dropseq < 0
              and status = 'S';

--       do all plates for full picks
         update plate
            set location = in_user,
                status = 'P',
                lastuser = in_user,
                lastupdate = sysdate,
                dropseq = abs(dropseq)
            where lpid in (select fromlpid from shippingplate
                              where facility||'' = pl.facility
                                and location||'' = in_user
                                and taskid = t.taskid
                                and dropseq < 0
                                and status = 'S'
                                and type = 'F');

--       do any leftovers - e.g. TOTE
         update plate
            set location = in_user,
                status = 'M',
                lastuser = in_user,
                lastupdate = sysdate,
                dropseq = abs(dropseq)
            where facility = pl.facility
              and location = pl.location
              and taskid = t.taskid
              and status = 'P'
              and dropseq < 0;
      end if;
   end loop;
   close c_any_task;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end resume_passed_pick;


procedure reinstate_task
   (in_taskid   in number,
    in_user     in varchar2,
    out_message out varchar2)
is
   cursor c_sub is
      select fromsection, fromloc, fromprofile, locseq, pickingzone
         from subtasks
         where taskid = in_taskid
         order by locseq nulls last;
   sub c_sub%rowtype;
   cnt integer;
   l_step1 tasks.step1_complete%type;
   v_any_pass_plates number;
begin
   out_message := null;

   select count(1) into cnt
      from subtasks
      where taskid = in_taskid
        and nvl(step1_complete,'N') = 'Y';
   if cnt = 0 then
      l_step1 := null;
   else
      l_step1 := 'Y';
   end if;

   select count(1) into cnt
      from tasks T, subtasks S
      where T.taskid = in_taskid
        and S.taskid = T.taskid
        and S.fromloc = T.fromloc;

   begin
     select any_pass_plates_for_task(a.taskid) into v_any_pass_plates
     from tasks a
     where taskid = in_taskid;
   exception
     when others then
      v_any_pass_plates := 0;
   end;

   if (cnt != 0) then
-- there is at least one subtask with the same fromloc, so don't change task

      update tasks
         set curruserid = null,
             clusterposition = null,
             priority = case when prevpriority = '8' and v_any_pass_plates = 0 and nvl(l_step1,'N') != 'Y' then '3' else prevpriority end,
             lastuser = in_user,
             lastupdate = sysdate,
             convpickloc = null,
             step1_complete = l_step1
         where taskid = in_taskid;
   else
-- need to change "from stuff" in task

      open c_sub;
      fetch c_sub into sub;
      close c_sub;
      update tasks
         set curruserid = null,
             clusterposition = null,
             priority = case when prevpriority = '8' and v_any_pass_plates = 0 and nvl(l_step1,'N') != 'Y' then '3' else prevpriority end,
             lastuser = in_user,
             lastupdate = sysdate,
             fromloc = sub.fromloc,
             fromsection = sub.fromsection,
             fromprofile = sub.fromprofile,
             locseq = sub.locseq,
             pickingzone = sub.pickingzone,
             convpickloc = null,
             step1_complete = l_step1
         where taskid = in_taskid;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end reinstate_task;


procedure serial_pick
   (in_taskid          in number,
    in_shlpid          in varchar2,
    in_user            in varchar2,
    in_plannedlp       in varchar2,
    in_pickedlp        in varchar2,
    in_custid          in varchar2,
    in_item            in varchar2,
    in_orderitem       in varchar2,
    in_lotno           in varchar2,
    in_dropseq         in number,
    in_pickfac         in varchar2,
    in_pickloc         in varchar2,
    in_baseuom         in varchar2,
    in_lplotno         in varchar2,
    in_mlip            in varchar2,
    in_picktype        in varchar2,
    in_tasktype        in varchar2,
    in_picktotype      in varchar2,
    in_fromloc         in varchar2,
    in_subtask_rowid   in varchar2,
    in_remaining       in number,
    in_pkd_lotno       in varchar2,
    in_pkd_serialno    in varchar2,
    in_pkd_user1       in varchar2,
    in_pkd_user2       in varchar2,
    in_pkd_user3       in varchar2,
    in_requested       in number,
    in_pickuom         in varchar2,
    in_unit_weight     in number,
    in_partmpcpt       in number,
    in_taskedlp        in varchar2,
    io_multi           in out varchar2,
    out_clip           out varchar2,
    out_lpcount        out number,
    out_error          out varchar2,
    out_message        out varchar2)
is
   cursor c_lp is
      select *
         from plate
         where lpid = in_pickedlp;
   lp c_lp%rowtype;
   cursor c_slp(p_lpid varchar2) is
      select *
         from shippingplate
         where parentlpid = p_lpid
           and custid = in_custid
           and item = in_item;
   slp c_slp%rowtype;
   cursor c_mlp is
      select fromlpid
         from shippingplate
         where lpid = in_shlpid;
   cursor c_loc is
      select loctype, zdpf.is_dynamicpf(in_pickfac, in_custid, in_item, in_fromloc) as isdpf
         from location
         where facility = in_pickfac
           and locid = in_fromloc;
   loc c_loc%rowtype;
   cursor c_stsk is
      select labeluom
         from subtasks
         where rowid = in_subtask_rowid;
   stsk c_stsk%rowtype;
   cursor c_cus is
      select nvl(pick_by_line_number_yn, 'N') pickbyline
         from customer
         where custid = in_custid;
   cus c_cus%rowtype;
   cursor c_itm(p_custid varchar2, p_item varchar2) is
      select nvl(capture_pickuom,'N') as capture_pickuom, labeluom
         from custitemview
         where custid = p_custid
           and item = p_item;
   itm c_itm%rowtype;
   clip shippingplate.lpid%type := in_shlpid;
   childlpid plate.lpid%type;
   baseqty shippingplate.quantity%type;
   toplpid shippingplate.lpid%type;
   rowfound boolean;
   msg varchar2(255);
   err varchar2(1);
   cnt integer;
   l_key number := 0;
   l_workqty number;
   l_picktype shippingplate.type%type;
   l_pickedlp plate.lpid%type;
   l_sql varchar2(2000);
   l_pickuom shippingplate.pickuom%type := in_pickuom;
   l_shiptype orderhdr.shiptype%type;
   l_elapsed_begin date;
   l_elapsed_end date;
   v_is_xp_plate number := 0;
   v_consolidated_wave number;
begin
   l_elapsed_begin := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'begin ZRFPK.SERIAL_PICK ',
                    'T', in_user);
   out_error := 'N';
   out_message := null;

   zrf.so_lock(l_key);
   if (in_requested > 0) then

--    the operator has been requested to pick a quantity > 1 from a normal
--    plate and some type of capture (lot, sn, user1, user2, user3) is
--    required upon pick - we must divy up our plate

      open c_lp;
      fetch c_lp into lp;
      rowfound := c_lp%found;
      close c_lp;

      if not rowfound then
         out_message := 'Qty not avail';
         rollback;
         return;
      end if;

      zrf.get_next_lpid(childlpid, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;

      zsp.get_next_shippinglpid(clip, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;

      if (in_mlip is null) then
         toplpid := in_shlpid;
      else
         begin
            select parentlpid
               into toplpid
               from plate
               where lpid = in_mlip;
         exception
            when NO_DATA_FOUND then
               toplpid := in_shlpid;
         end;
      end if;

      begin
        select count(1) into v_consolidated_wave
        from waves
        where wave in (select wave from tasks where taskid = in_taskid)
          and nvl(consolidated,'N') = 'Y';
      exception
        when others then
          v_consolidated_wave := 0;
      end;

      if (v_consolidated_wave = 0) then
      if (in_requested = in_remaining) then

--       first pass
--       build the needed MP
         zplp.build_empty_parent(io_multi, in_pickfac, in_user, 'A', 'MP', in_user, null,
               in_custid, null, null, null, null, null, null, null, null, null, msg);

         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
            return;
         end if;

--       change shippingplate to a parent
         update shippingplate
            set location = in_user,
                type = decode(in_picktotype, 'PACK', 'C', 'M'),
                status = 'P',
                fromlpid = io_multi,
                quantity = decode(in_mlip, null, 1, 0),
                qtyentered = decode(in_mlip, null, 1, 0),
                weight = 0,
                dropseq = in_dropseq,
                pickedfromloc = location,
                lastuser = in_user,
                lastupdate = sysdate
            where lpid = in_shlpid;

         if (toplpid = in_shlpid) and (in_mlip is not null) then
            insert into plate
               (lpid, type, parentlpid, lastuser, lastupdate, lasttask, lastoperator,
                custid, facility)
            values
               (in_mlip, 'XP', in_shlpid, in_user, sysdate, in_tasktype, in_user,
                in_custid, in_pickfac);
         end if;

--       create new shippingplate and (optionally) attach to master
         insert into shippingplate
            (lpid, item, custid, facility, location, status,
             holdreason, unitofmeasure, quantity, type, fromlpid, serialnumber,
             lotnumber, parentlpid, useritem1, useritem2, useritem3,
             lastuser, lastupdate, invstatus, qtyentered, orderitem, uomentered, inventoryclass,
             loadno, stopno, shipno, orderid, shipid, weight,
             ucc128, labelformat, taskid, dropseq, orderlot, pickuom,
             pickqty, trackingno, cartonseq, checked, totelpid, cartontype,
             pickedfromloc, shippingcost, carriercodeused, satdeliveryused, openfacility,
             manufacturedate, expirationdate)
         select clip, S.item, S.custid, S.facility, S.location, S.status,
                S.holdreason, in_baseuom, 1, 'F', childlpid, S.serialnumber,
                S.lotnumber, decode(in_mlip, null, toplpid, null), S.useritem1, S.useritem2, S.useritem3,
                in_user, sysdate, S.invstatus, 1, S.orderitem, S.uomentered, S.inventoryclass,
                S.loadno, S.stopno, S.shipno, S.orderid, S.shipid, 0,
                S.ucc128, S.labelformat, S.taskid, S.dropseq, S.orderlot, in_baseuom,
                1, S.trackingno, S.cartonseq, S.checked, S.totelpid, S.cartontype,
                S.pickedfromloc, S.shippingcost, S.carriercodeused, S.satdeliveryused, S.openfacility,
                S.manufacturedate, S.expirationdate
           from shippingplate S
           where S.lpid = in_shlpid;

      else

         if (io_multi is null) then

--          we're in recovery
            open c_mlp;
            fetch c_mlp into io_multi;
            close c_mlp;
         end if;

--       start with any child shippingplate, duplicate it and (optionally) attach to master
         open c_slp(toplpid);
         fetch c_slp into slp;
         close c_slp;

         insert into shippingplate
            (lpid, item, custid, facility, location, status,
             holdreason, unitofmeasure, quantity, type, fromlpid,
             serialnumber, lotnumber, parentlpid,
             useritem1, useritem2, useritem3, lastuser, lastupdate, invstatus,
             qtyentered, orderitem,
             uomentered, inventoryclass, loadno, stopno, shipno,
             orderid, shipid, weight, ucc128, labelformat, taskid,
             dropseq, orderlot, pickuom, pickqty, trackingno,
             cartonseq, checked, totelpid, cartontype, pickedfromloc,
             shippingcost, carriercodeused, satdeliveryused, openfacility,
             manufacturedate, expirationdate)
         values
            (clip, slp.item, slp.custid, slp.facility, slp.location, slp.status,
             slp.holdreason, slp.unitofmeasure, slp.quantity, slp.type, childlpid,
             slp.serialnumber, slp.lotnumber, decode(in_mlip, null, slp.parentlpid, null),
             slp.useritem1, slp.useritem2, slp.useritem3, in_user, sysdate, slp.invstatus,
             slp.qtyentered, slp.orderitem,
             slp.uomentered, slp.inventoryclass, slp.loadno, slp.stopno, slp.shipno,
             slp.orderid, slp.shipid, 0, slp.ucc128, slp.labelformat, slp.taskid,
             slp.dropseq, slp.orderlot, slp.pickuom, slp.pickqty, slp.trackingno,
             slp.cartonseq, slp.checked, slp.totelpid, slp.cartontype, slp.pickedfromloc,
             slp.shippingcost, slp.carriercodeused, slp.satdeliveryused, slp.openfacility,
             slp.manufacturedate, slp.expirationdate);

         if in_mlip is null then
            update shippingplate
               set quantity = quantity + 1,
                   qtyentered = qtyentered + 1,
                   lastuser = in_user,
                   lastupdate = sysdate
               where lpid = in_shlpid;
         end if;

      end if;
      end if;

--    build a child plate based upon the picked lp and attach to the multi
      insert into plate
         (lpid, item, custid, facility, location, status,
          holdreason, unitofmeasure, quantity, type, serialnumber,
          lotnumber, creationdate, manufacturedate, expirationdate, expiryaction,
          lastcountdate, po, recmethod, condition, lastoperator, lasttask,
          fifodate, destlocation, destfacility, countryof, parentlpid,
          useritem1, useritem2, useritem3, lastuser, lastupdate, invstatus,
          inventoryclass, loadno, stopno, shipno, orderid, shipid,
          weight, adjreason,
          controlnumber, qcdisposition, fromlpid, taskid, dropseq, fromshippinglpid,
          workorderseq, workordersubseq, qtyentered, uomentered)
      values
         (childlpid, lp.item, lp.custid, lp.facility, lp.location, lp.status,
          lp.holdreason, lp.unitofmeasure, 1, 'PA', in_pkd_serialno,
          lp.lotnumber, sysdate, lp.manufacturedate, lp.expirationdate, lp.expiryaction,
          lp.lastcountdate, lp.po, lp.recmethod, lp.condition, in_user, in_tasktype,
          lp.fifodate, lp.destlocation, lp.destfacility, lp.countryof, null,
          in_pkd_user1, in_pkd_user2, in_pkd_user3, in_user, sysdate, lp.invstatus,
          lp.inventoryclass, lp.loadno, lp.stopno, lp.shipno, lp.orderid, lp.shipid,
          0, lp.adjreason,
          lp.controlnumber, lp.qcdisposition, io_multi, lp.taskid, lp.dropseq, clip,
          lp.workorderseq, lp.workordersubseq, 1, lp.unitofmeasure);

      zplp.attach_child_plate(io_multi, childlpid, in_user, 'P', in_user, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;

--    decrease original LP
      zrf.decrease_lp(in_pickedlp, in_custid, in_item, 1, in_lplotno, in_baseuom,
            in_user, in_tasktype, lp.invstatus, lp.inventoryclass, err, msg);
      if (err = 'N') and (msg is null) then
         zcwt.process_weight_difference(in_pickedlp, in_unit_weight, lp.weight, in_user, 'P', msg);
         if msg is not null then
            err := 'Y';
         end if;
      end if;
      if (msg is not null) then
         out_error := err;
         out_message := msg;
         rollback;
         return;
      end if;

--    do the pick
      pick_a_plate(in_taskid, clip, in_user, in_plannedlp, in_pickedlp, in_custid, in_item,
            in_orderitem, in_lotno, 1, in_dropseq, in_pickfac, in_pickloc,
            in_baseuom, in_lplotno, in_mlip, in_picktype, in_tasktype, in_picktotype, in_fromloc,
            in_subtask_rowid, '2', childlpid, in_pkd_lotno, in_pkd_serialno, in_pkd_user1,
            in_pkd_user2, in_pkd_user3, in_baseuom, 1, in_unit_weight, in_taskedlp,
            out_lpcount, err, msg);

--    if last pick and original plate is gone, reuse it
      if ((msg is null) and (in_remaining = 1)) then
         select count(1) into cnt
            from plate
            where lpid = in_pickedlp;

         if (cnt = 0) then
            begin
               select shiptype into l_shiptype
                  from orderhdr
                  where (orderid,shipid) = (select orderid, shipid from shippingplate
                                             where lpid = in_shlpid);
            exception when no_data_found then
               l_shiptype := 'z';
            end;

         select count(1)
         into v_is_xp_plate
         from plate
         where lpid = in_mlip and type = 'XP';

            if l_shiptype = 'S' and v_is_xp_plate = 0 then
               io_multi := in_mlip;
            end if;
            if l_shiptype = 'S' then
               update shippingplate
                  set fromlpid = nvl(in_mlip,in_pickedlp),
                      lastuser = in_user,
                      lastupdate = sysdate
                  where lpid = in_shlpid;

            else
               update shippingplate
                  set fromlpid = in_pickedlp,
                      lastuser = in_user,
                      lastupdate = sysdate
                  where lpid = in_shlpid;
            end if;

            delete deletedplate
               where lpid = in_pickedlp;

            update plate
               set lpid = in_pickedlp,
                   lasttask = in_tasktype,
                   lastoperator = in_user,
                   lastuser = in_user,
                   lastupdate = sysdate
               where lpid = io_multi;

            update plate
               set parentlpid = in_pickedlp,
                   fromlpid = in_pickedlp,
                   lasttask = in_tasktype,
                   lastoperator = in_user,
                   lastuser = in_user,
                   lastupdate = sysdate
               where parentlpid = io_multi;
         end if;

--       cleanup "unneeded" parent
         if (toplpid != in_shlpid) then
            delete shippingplate
               where lpid = in_shlpid;
         end if;
      end if;
   else

      baseqty := 1;
      open c_itm(in_custid, in_item);
      fetch c_itm into itm;
      close c_itm;
      if in_picktotype = 'LBL' then
         open c_loc;
         fetch c_loc into loc;
         close c_loc;
         open c_stsk;
         fetch c_stsk into stsk;
         close c_stsk;
         if ((loc.loctype = 'PF') or (loc.isdpf = 'Y') or (stsk.labeluom is not null))
         and (in_pkd_lotno is null) and (in_pkd_serialno is null)
         and (in_pkd_user1 is null) and (in_pkd_user2 is null)
         and (in_pkd_user3 is null) then
            open c_cus;
            fetch c_cus into cus;
            close c_cus;
            if cus.pickbyline = 'Y' then
               zbut.translate_uom(in_custid, in_item, 1, stsk.labeluom, in_pickuom,
                     l_workqty, msg);
               baseqty := ceil(l_workqty);
            else
               zbut.translate_uom(in_custid, in_item, 1, in_pickuom, in_baseuom,
                     baseqty, msg);
            end if;
            if (substr(msg, 1, 4) != 'OKAY') then
               baseqty := 1;
            end if;
         else
            zbut.translate_uom(in_custid, in_item, 1, nvl(stsk.labeluom, nvl(itm.labeluom, in_baseuom)), in_baseuom,
                  l_workqty, msg);
            baseqty := ceil(l_workqty);
         end if;
      elsif itm.capture_pickuom = 'Y' then
         zbut.translate_uom(in_custid, in_item, 1, in_pickuom, in_baseuom,
               baseqty, msg);
         if (substr(msg, 1, 4) != 'OKAY') then
            baseqty := 1;
         end if;
      end if;

      l_picktype := 'P';

      if (in_remaining = 1) then

--       last serial number, use the original shipping plate
         update shippingplate
            set quantity = baseqty,
                unitofmeasure = in_baseuom,
                lastuser = in_user,
                lastupdate = sysdate,
                qtyentered = 1,
                weight = 0,
                pickuom = l_pickuom,
                pickqty = 1
             where lpid = in_shlpid;

         open c_lp;
         fetch c_lp into lp;
         close c_lp;

         if lp.quantity = baseqty then
            l_picktype := 'F';
         end if;
      else

--       make a new copy of the shippingplate
         zsp.get_next_shippinglpid(clip, msg);
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
            return;
         end if;

         insert into shippingplate
            (lpid, item, custid, facility, location, status,
             holdreason, unitofmeasure, quantity, type, fromlpid, serialnumber,
             lotnumber, parentlpid, useritem1, useritem2, useritem3, lastuser,
             lastupdate, invstatus, qtyentered, orderitem, uomentered, inventoryclass,
             loadno, stopno, shipno, orderid, shipid, weight,
             ucc128, labelformat, taskid, dropseq, orderlot, pickuom,
             pickqty, trackingno, cartonseq, checked, totelpid, cartontype,
             pickedfromloc, shippingcost, carriercodeused, satdeliveryused, openfacility,
             manufacturedate, expirationdate)
         select clip, S.item, S.custid, S.facility, S.location, S.status,
                S.holdreason, in_baseuom, baseqty, 'P', S.fromlpid, S.serialnumber,
                S.lotnumber, S.parentlpid, S.useritem1, S.useritem2, S.useritem3, in_user,
                sysdate, S.invstatus, 1, S.orderitem, S.uomentered, S.inventoryclass,
                S.loadno, S.stopno, S.shipno, S.orderid, S.shipid, 0,
                S.ucc128, S.labelformat, S.taskid, S.dropseq, S.orderlot, l_pickuom,
                1, S.trackingno, S.cartonseq, S.checked, S.totelpid, S.cartontype,
                S.pickedfromloc, S.shippingcost, S.carriercodeused, S.satdeliveryused, S.openfacility,
                S.manufacturedate, S.expirationdate
            from shippingplate S
            where S.lpid = in_shlpid;
      end if;

      if in_partmpcpt > 0 then
         l_sql := 'select lpid from plate where parentlpid = ''' || in_pickedlp || ''''
               || ' and type = ''PA'''
               || ' and custid = ''' || in_custid || ''''
               || ' and item = ''' || in_item || '''';
         if in_lotno is not null then
            l_sql := l_sql || ' and lotnumber = ''' || in_lotno || '''';
         else
            l_sql := l_sql || ' and lotnumber is null';
         end if;
         if in_pkd_serialno is not null then
            l_sql := l_sql || ' and serialnumber = ''' || in_pkd_serialno || '''';
         end if;
         if in_pkd_user1 is not null then
            l_sql := l_sql || ' and useritem1 = ''' || in_pkd_user1 || '''';
         end if;
         if in_pkd_user2 is not null then
            l_sql := l_sql || ' and useritem2 = ''' || in_pkd_user2 || '''';
         end if;
         if in_pkd_user3 is not null then
            l_sql := l_sql || ' and useritem3 = ''' || in_pkd_user3 || '''';
         end if;
         l_sql := l_sql || ' and rownum = 1';

         begin
            execute immediate l_sql into l_pickedlp;
         exception
            when OTHERS then
               l_pickedlp := null;
         end;

         if l_pickedlp is null then
            out_message := 'Qty not avail';
            rollback;
            return;
         end if;
      else
         l_pickedlp := in_pickedlp;
      end if;

--    do the pick
      pick_a_plate(in_taskid, clip, in_user, in_plannedlp, l_pickedlp, in_custid, in_item,
            in_orderitem, in_lotno, baseqty, in_dropseq, in_pickfac,
            in_pickloc, in_baseuom, in_lplotno, in_mlip, l_picktype, in_tasktype, in_picktotype,
            in_fromloc, in_subtask_rowid, null, null, in_pkd_lotno, in_pkd_serialno, in_pkd_user1,
            in_pkd_user2, in_pkd_user3, l_pickuom, 1, baseqty*in_unit_weight, in_taskedlp,
            out_lpcount, err, msg);
   end if;

   if ((err = 'Y') or (msg is not null)) then
      out_error := err;
      out_message := msg;
      rollback;
      return;
   end if;

   out_clip := clip;
   l_elapsed_end := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'end ZRFPK.SERIAL_PICK' ||
                    'out_error: ' || out_error || ', ' ||
                    'out_message: ' || out_message ||
                    'out_clip: ' || out_clip ||
                    ' (Elapsed: ' ||
                    rtrim(substr(zlb.formatted_staffhrs((l_elapsed_end - l_elapsed_begin)*24),1,12)) ||
                    ')',
                    'T', in_user);

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end serial_pick;


procedure linepick_multi
   (in_taskid   in number,
    in_tasktype in varchar2,
    in_dropseq  in number,
    in_user     in varchar2,
    in_lpid     in varchar2,
    in_pickfac  in varchar2,
    in_pickloc  in varchar2,
    out_lpcount out number,
    out_error   out varchar2,
    out_message out varchar2)
is
   cursor c_tsk is
      select orderid, shipid, loadno
         from tasks
         where taskid = in_taskid;
   tsk c_tsk%rowtype;
   cursor c_shlp is
      select rowid, custid, item, unitofmeasure, quantity, orderitem, orderlot,
             lotnumber, inventoryclass, invstatus, pickuom, pickqty, weight
         from shippingplate
         where taskid = in_taskid
           and orderid = tsk.orderid
           and shipid = tsk.shipid;
   cursor c_itemview(p_custid varchar2, p_item varchar2, p_uom varchar2) is
      select useramt1, nvl(ordercheckrequired, 'N') checkreqd,
             zci.item_cube(p_custid, p_item, p_uom) cube
         from custitemview
         where custid = p_custid
           and item = p_item;
   itv c_itemview%rowtype;
   cursor c_lp is
      select parentlpid
         from plate
         where lpid = in_lpid;
   lp c_lp%rowtype;
   cursor c_oh(p_orderid number, p_shipid number) is
      select orderstatus, ordertype, parentorderid, parentshipid, loadno, stopno
         from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   oh c_oh%rowtype := null;
   poh c_oh%rowtype := null;
   checkqty orderdtl.qty2check%type;
   checkamtqty orderdtl.qty2check%type;
   remqty commitments.qty%type;
   l_rowid rowid;
   err varchar2(1);
   msg varchar2(80);
   l_key number := 0;
   auxmsg varchar2(80);
   l_elapsed_begin date;
   l_elapsed_end date;
begin
   l_elapsed_begin := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'begin ZRFPK.LINEPICK_MULTI - ' ||
                    'in_taskid: ' || in_taskid || ', ' ||
                    'in_tasktype: ' || in_tasktype || ', ' ||
                    'in_dropseq: ' || in_dropseq || ', ' ||
                    'in_user: ' || in_user || ', ' ||
                    'in_lpid: ' || in_lpid || ', ' ||
                    'in_pickfac: ' || in_pickfac || ', ' ||
                    'in_pickloc: ' || in_pickloc,
                    'T', in_user);
   out_error := 'N';
   out_message := null;

   zrf.so_lock(l_key);
   open c_tsk;
   fetch c_tsk into tsk;
   close c_tsk;

   zso.get_rf_lock(tsk.loadno,tsk.orderid,tsk.shipid,in_user,msg);
   if substr(msg,1,4) != 'OKAY' then
     out_message := substr(msg,1,80);
     return;
   end if;
   open c_oh(tsk.orderid, tsk.shipid);
   fetch c_oh into oh;
   close c_oh;
   if (oh.parentorderid is not null) and (oh.parentshipid is not null) then
      open c_oh(oh.parentorderid, oh.parentshipid);
      fetch c_oh into poh;
      close c_oh;
   end if;

   for sh in c_shlp loop
      open c_itemview(sh.custid, sh.item, sh.pickuom);
      fetch c_itemview into itv;
      close c_itemview;

--    update the order detail
      if (itv.checkreqd = 'Y') then
         checkqty := sh.pickqty;
         checkamtqty := sh.quantity;
      else
         checkqty := 0;
         checkamtqty := 0;
      end if;

--    update the shipping plate
      update shippingplate
         set location = in_user,
             status = 'P',
             lastuser = in_user,
             lastupdate = sysdate,
             dropseq = in_dropseq,
             pickedfromloc = location,
             fromlpidparent = in_lpid
         where rowid = sh.rowid;

--    update commitments
      update commitments
         set qty = qty - sh.quantity,
             lastuser = in_user,
             lastupdate = sysdate
         where orderid = tsk.orderid
           and shipid = tsk.shipid
           and orderitem = sh.orderitem
           and nvl(orderlot, '(none)') = nvl(sh.orderlot, '(none)')
           and item = sh.item
           and nvl(lotnumber, '(none)') = nvl(sh.orderlot, '(none)')
           and inventoryclass = sh.inventoryclass
           and invstatus = sh.invstatus
           and status = 'CM'
         returning qty, rowid into remqty, l_rowid;

      if (sql%rowcount = 0) then
         if (oh.orderstatus != 'X') then

--          order has *NOT* been cancelled
            auxmsg := null;
            zms.log_msg('LINEPICK_MUL', in_pickfac, sh.custid,
                  'No commitments: orderid=' || tsk.orderid || ' shipid=' || tsk.shipid
                  || ' orderitem=' || sh.orderitem || ' item=' || sh.item
                  || ' lot=' || sh.orderlot || ' class=' || sh.inventoryclass
                  || ' status=' || sh.invstatus, 'W', in_user, auxmsg);
         end if;
      elsif (remqty <= 0) then
         delete commitments
            where rowid = l_rowid;
         if (remqty < 0) then
            auxmsg := null;
            zms.log_msg('LINEPICK_MUL', in_pickfac, sh.custid,
               'orderid=' || tsk.orderid || ' shipid=' || tsk.shipid
               || ' orderitem=' || sh.orderitem || ' item=' || sh.item
               || ' lot=' || sh.orderlot || ' class=' || sh.inventoryclass
               || ' status=' || sh.invstatus || ' remqty=' || remqty, 'W', in_user, auxmsg);
         end if;
      end if;

      update orderdtl
         set qtypick = nvl(qtypick, 0) + sh.quantity,
             weightpick = nvl(weightpick, 0) + sh.weight,
             cubepick = nvl(cubepick, 0) + (sh.pickqty * itv.cube),
             amtpick = nvl(amtpick, 0) + (sh.quantity * zci.item_amt(custid,orderid,shipid,item,lotnumber)),
             qty2check = nvl(qty2check, 0) + checkamtqty,
             weight2check = nvl(weight2check, 0) + sh.weight,
             cube2check = nvl(cube2check, 0) + (checkqty * itv.cube),
             amt2check = nvl(amt2check, 0) + (checkamtqty * zci.item_amt(custid,orderid,shipid,item,lotnumber)),
             lastuser = in_user,
             lastupdate = sysdate
         where orderid = tsk.orderid
           and shipid = tsk.shipid
           and item = sh.orderitem
           and nvl(lotnumber, '(none)') = nvl(sh.orderlot, '(none)');

      update subtasks
         set qtypicked = qty
         where taskid = in_taskid
           and orderid = tsk.orderid
           and shipid = tsk.shipid;

      bump_custitemcount(sh.custid, sh.item, 'PICK', sh.unitofmeasure, sh.quantity,
            in_user, err, msg);
      if (err != 'N') then
         out_error := err;
         out_message := msg;
         return;
      end if;
   end loop;

-- update the order header
   update orderhdr
      set orderstatus = zrf.ORD_PICKING,
          lastuser = in_user,
          lastupdate = sysdate
      where orderid = tsk.orderid
        and shipid = tsk.shipid
        and orderstatus < zrf.ORD_PICKING;

   if ((oh.parentorderid is not null) and (oh.parentshipid is not null)
   and (poh.ordertype = 'W')) then
      update orderhdr
         set orderstatus = zrf.ORD_PICKING,
             lastuser = in_user,
             lastupdate = sysdate
         where orderid = oh.parentorderid
           and shipid = oh.parentshipid
           and orderstatus < zrf.ORD_PICKING;
   end if;

   if (oh.loadno is not null) then
      update loadstop
         set loadstopstatus = zrf.LOD_PICKING,
             lastuser = in_user,
             lastupdate = sysdate
         where loadno = oh.loadno
           and stopno = oh.stopno
           and loadstopstatus < zrf.LOD_PICKING;
      update loads
         set loadstatus = zrf.LOD_PICKING,
             lastuser = in_user,
             lastupdate = sysdate
         where loadno = oh.loadno
           and loadstatus < zrf.LOD_PICKING;
   end if;

-- update all plates
   update plate
      set status = 'P',
          location = in_user,
          lasttask = in_tasktype,
          lastoperator = in_user,
          lastuser = in_user,
          lastupdate = sysdate
      where lpid in (select lpid from plate
                        start with lpid = in_lpid
                        connect by prior lpid = parentlpid);

   open c_lp;
   fetch c_lp into lp;
   close c_lp;
   if (lp.parentlpid is not null) then
      zplp.detach_child_plate(lp.parentlpid, in_lpid, in_user, null,
            null, 'P', in_user, in_tasktype, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;
   end if;

-- update pick counts
   update location
      set pickcount = nvl(pickcount, 0) + 1,
          lastpickedfrom = sysdate
      where facility = in_pickfac
        and locid = in_pickloc;

   update itempickfronts
      set lastpickeddate = sysdate
      where facility = in_pickfac
        and pickfront = in_pickloc;

   select count(1) into out_lpcount
      from plate
      where facility = in_pickfac
        and location = in_pickloc
        and type = 'PA'
        and status != 'P';

   zoh.add_orderhistory_item(tsk.orderid, tsk.shipid,
      in_lpid, null, null,
      'Pick MultiPlate',
      'Picked from: '||in_pickfac||'/'||in_pickloc,
      in_user, msg);

   l_elapsed_end := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'end ZRFPK.LINEPICK_MULTI - ' ||
                    'out_error: ' || out_error || ', ' ||
                    'out_message: ' || out_message ||
                    'out_lpcount: ' || out_lpcount ||
                    ' (Elapsed: ' ||
                    rtrim(substr(zlb.formatted_staffhrs((l_elapsed_end - l_elapsed_begin)*24),1,12)) ||
                    ')',
                    'T', in_user);
exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end linepick_multi;


procedure stage_multi
   (in_lpid      in varchar2,
    in_facility  in varchar2,
    in_drop_loc  in varchar2,
    in_user      in varchar2,
    in_tasktype  in varchar2,
    in_stage_loc in varchar2,
    out_error    out varchar2,
    out_message  out varchar2)
is
   cursor c_mlp is
      select custid
         from plate
         where lpid = in_lpid;
   mlp c_mlp%rowtype;
   cursor c_shlp is
      select rowid, taskid
         from shippingplate
         where facility = in_facility
           and location = in_user
           and fromlpid in (select lpid from plate
                              start with lpid = in_lpid
                              connect by prior lpid = parentlpid);
   cursor c_subtasks(p_taskid number) is
      select rowid, orderid, shipid
         from subtasks
         where taskid = p_taskid;
   cursor c_loc(p_facility varchar2, p_locid varchar2) is
      select loctype, section, equipprof, putawayseq, pickingseq
         from location
         where facility = p_facility
           and locid = p_locid;
   drp c_loc%rowtype := null;
   msg varchar2(255);
   auxmsg varchar2(80);
   i binary_integer;
   l_found boolean;
   l_orderid orderhdr.orderid%type := null;
   l_shipid orderhdr.shipid%type := null;
   l_key number := 0;
begin
   out_error := 'N';
   out_message := null;

   open c_loc(in_facility, in_drop_loc);
   fetch c_loc into drp;
   l_found := c_loc%found;
   close c_loc;
   if not l_found then
      out_message := 'Drop loc not found';
      return;
   end if;

   zrf.so_lock(l_key);
   tid_tbl.delete;
   for sh in c_shlp loop
      update shippingplate
         set location = in_drop_loc,
             status = decode(drp.loctype,'PND','P','XFR','P','S'),
             lastuser = in_user,
             lastupdate = sysdate
         where rowid = sh.rowid;

      add_tid_to_tbl(sh.taskid);
   end loop;

   for i in 1..tid_tbl.count loop
      update subtasks
         set step1_complete = null
         where taskid = tid_tbl(i);

--    cleanup subtask(s)
      for st in c_subtasks(tid_tbl(i)) loop
         l_orderid := st.orderid;
         l_shipid := st.shipid;
         if drp.loctype not in ('PND','XFR') then
            zdep.del_pick_subtask(st.rowid, in_user, msg);
            if (msg is not null) then
               out_error := 'Y';
               out_message := msg;
               return;
            end if;
         else
            update subtasks
               set step1_complete = 'Y'
               where rowid = st.rowid;
         end if;
      end loop;

      if drp.loctype in ('PND','XFR') then
         adjust_subtask_tree(tid_tbl(i), in_facility, in_drop_loc, in_stage_loc, in_user, msg);
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
            return;
         end if;
      end if;

--    cleanup task
      delete tasks T
         where T.taskid = tid_tbl(i)
           and not exists (select * from subtasks S
               where S.taskid = tid_tbl(i));
   end loop;

-- update all plates
   update plate
      set location = in_drop_loc,
          lasttask = in_tasktype,
          lastoperator = in_user,
          lastuser = in_user,
          lastupdate = sysdate
      where lpid in (select lpid from plate
                        start with lpid = in_lpid
                        connect by prior lpid = parentlpid);

-- update table(s) if all picks staged
   if drp.loctype not in ('PND','XFR') then
      check_all_picked(l_orderid, l_shipid, in_user, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;

      zmn.stage_carton(in_lpid, 'stage', msg);
      if ((msg != 'OKAY') and (msg != 'Not a MultiShip Carrier')) then
         auxmsg := null;
         open c_mlp;
         fetch c_mlp into mlp;
         close c_mlp;
         zms.log_autonomous_msg('MULTISHIP', in_facility, mlp.custid,
               msg || ' on LP ' || in_lpid, 'W', in_user, auxmsg);
      end if;
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end stage_multi;


procedure pick_1_sn_from_mp
   (in_taskid          in number,
    in_shlpid          in varchar2,
    in_user            in varchar2,
    in_plannedlp       in varchar2,
    in_pickedlp        in varchar2,
    in_custid          in varchar2,
    in_item            in varchar2,
    in_orderitem       in varchar2,
    in_lotno           in varchar2,
    in_dropseq         in number,
    in_pickfac         in varchar2,
    in_pickloc         in varchar2,
    in_baseuom         in varchar2,
    in_lplotno         in varchar2,
    in_mlip            in varchar2,
    in_picktype        in varchar2,
    in_tasktype        in varchar2,
    in_picktotype      in varchar2,
    in_fromloc         in varchar2,
    in_subtask_rowid   in varchar2,
    in_remaining       in number,
    in_picked_child    in varchar2,
    in_pkd_lotno       in varchar2,
    in_pkd_serialno    in varchar2,
    in_pkd_user1       in varchar2,
    in_pkd_user2       in varchar2,
    in_pkd_user3       in varchar2,
    in_pickuom         in varchar2,
    in_unit_weight     in number,
    in_taskedlp        in varchar2,
    out_clip           out varchar2,
    out_lpcount        out number,
    out_error          out varchar2,
    out_message        out varchar2)
is
   cursor c_child is
      select P.serialnumber, P.lotnumber, P.useritem1, P.useritem2,
             P.useritem3, P.quantity, nvl(M.virtuallp, 'N') virtuallp,
             P.manufacturedate, P.expirationdate
         from plate P, plate M
         where P.lpid = in_picked_child
           and M.lpid (+) = P.parentlpid;
   c c_child%rowtype;
   clip shippingplate.lpid%type := in_shlpid;
   msg varchar2(80);
   err varchar2(1);
   l_key number := 0;
   l_quantity shippingplate.quantity%type;
   l_pickqty shippingplate.pickqty%type;
   v_orderid pls_integer;
   v_shipid pls_integer;
   v_loadno pls_integer;
   l_elapsed_begin date;
   l_elapsed_end date;
begin
   l_elapsed_begin := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'begin ZRFPK.PICK_1_SN_FROM_MP',
                    'T', in_user);
   out_error := 'N';
   out_message := null;

   zrf.so_lock(l_key);
   begin
    select orderid, shipid, loadno
      into v_orderid, v_shipid, v_loadno
      from shippingplate
     where lpid = in_shlpid;
    zso.get_rf_lock(v_loadno, v_orderid, v_shipid, in_user, msg);
    if substr(msg,1,4) != 'OKAY' then
      out_message := substr(msg,1,80);
      return;
    end if;
   exception
    when others then
      -- above shouldn't fail if the shipping plate exists, so here just don't do anything
      -- if it does fail, then probably a lock is not needed, and just let the procedure do what it would have done normally
      null;
   end;
   open c_child;
   fetch c_child into c;
   close c_child;

   if c.virtuallp = 'Y' then
      l_quantity := c.quantity;
      l_pickqty := c.quantity;
   else
      l_quantity := zlbl.uom_qty_conv(in_custid, in_item, 1, in_pickuom, in_baseuom);
      l_pickqty := 1;
   end if;

   if (in_remaining = 1) then
--    last child, use the original shipping plate

      update shippingplate
         set unitofmeasure = in_baseuom,
             quantity = l_quantity,
             type = 'F',
             fromlpid = in_picked_child,
             serialnumber = c.serialnumber,
             parentlpid = in_mlip,
             lastuser = in_user,
             lastupdate = sysdate,
             qtyentered = l_quantity,
             pickuom = in_pickuom,
             pickqty = l_pickqty,
             lotnumber = c.lotnumber,
             useritem1 = c.useritem1,
             useritem2 = c.useritem2,
             useritem3 = c.useritem3,
             manufacturedate = c.manufacturedate,
             expirationdate = c.expirationdate
         where lpid = in_shlpid;
   else
--    make a new copy of the shippingplate

      zsp.get_next_shippinglpid(clip, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;

      insert into shippingplate
         (lpid, item, custid, facility, location, status,
          holdreason, unitofmeasure, quantity, type, fromlpid, serialnumber,
          lotnumber, parentlpid, useritem1, useritem2, useritem3, lastuser,
          lastupdate, invstatus, qtyentered, orderitem, uomentered, inventoryclass,
          loadno, stopno, shipno, orderid, shipid,
          ucc128, labelformat, taskid, dropseq, orderlot, pickuom,
          pickqty, trackingno, cartonseq, checked, totelpid, cartontype,
          pickedfromloc, shippingcost, carriercodeused, satdeliveryused,
          openfacility, manufacturedate, expirationdate)
      select clip, S.item, S.custid, S.facility, S.location, S.status,
             S.holdreason, in_baseuom, l_quantity, 'F', in_picked_child, c.serialnumber,
             c.lotnumber, in_mlip, c.useritem1, c.useritem2, c.useritem3, in_user,
             sysdate, S.invstatus, l_quantity, S.orderitem, S.uomentered, S.inventoryclass,
             S.loadno, S.stopno, S.shipno, S.orderid, S.shipid,
             S.ucc128, S.labelformat, S.taskid, S.dropseq, S.orderlot, in_pickuom,
             l_pickqty, S.trackingno, S.cartonseq, S.checked, S.totelpid, S.cartontype,
             S.pickedfromloc, S.shippingcost, S.carriercodeused, S.satdeliveryused,
             S.openfacility, c.manufacturedate, c.expirationdate
         from shippingplate S
         where S.lpid = in_shlpid;
   end if;

-- do the pick

   pick_a_plate(in_taskid, clip, in_user, in_plannedlp, in_pickedlp, in_custid, in_item,
         in_orderitem, in_lotno, l_quantity, in_dropseq, in_pickfac,
         in_pickloc, in_baseuom, in_lplotno, in_mlip, 'F', in_tasktype, in_picktotype, in_fromloc,
         in_subtask_rowid, '1', in_picked_child, in_pkd_lotno, in_pkd_serialno,
         in_pkd_user1, in_pkd_user2, in_pkd_user3, in_pickuom, l_pickqty, l_pickqty*in_unit_weight,
         in_taskedlp, out_lpcount, err, msg);
   if ((err = 'Y') or (msg is not null)) then
      out_error := err;
      out_message := msg;
      rollback;
      return;
   end if;

   out_clip := clip;
   l_elapsed_end := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'end ZRFPK.PICK_1_SN_FROM_MP ' ||
                    'out_clip: ' || out_clip || ', ' ||
                    'out_lpcount: ' || out_lpcount || ', ' ||
                    ' (Elapsed: ' ||
                    rtrim(substr(zlb.formatted_staffhrs((l_elapsed_end - l_elapsed_begin)*24),1,12)) ||
                    ')',
                    'T', in_user);

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end pick_1_sn_from_mp;


procedure adjust_for_extra_pick
   (in_subtask_rowid in varchar2,
    in_shlpid        in varchar2,
    in_pickqty       in number,
    in_pickuom       in varchar2,
    in_qty           in number,
    in_user          in varchar2,
    in_pickedlp      in varchar2,
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
   l_elapsed_begin date;
   l_elapsed_end date;
begin
   l_elapsed_begin := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'begin ZRFPK.ADJUST_FOR_EXTRA_PICK - ' ||
                    'in_subtask_rowid: ' || in_subtask_rowid || ', ' ||
                    'in_shlpid: ' || in_shlpid || ', ' ||
                    'in_pickqty: ' || in_pickqty || ', ' ||
                    'in_pickuom: ' || in_pickuom || ', ' ||
                    'in_qty: ' || in_qty || ', ' ||
                    'in_user: ' || in_user || ', ' ||
                    'in_pickedlp: ' || in_pickedlp,
                    'T', in_user);
   out_message := null;
   out_rowid := null;

   zrf.so_lock(l_key);
-- adjust original subtask
   open c_stsk;
   fetch c_stsk into stsk;
   rowfound := c_stsk%found;
   close c_stsk;

   if not rowfound then
      out_message := 'Subtask not found';
      return;
   end if;

   if (stsk.qty <= in_qty) and (stsk.orderedbyweight = 'N') then
      trace_msg('ADJXPICK', stsk.facility, stsk.custid, in_user,
            'order=' || stsk.orderid || '-' || stsk.shipid
            || ' ttype=' || stsk.tasktype || ' loc=' || stsk.fromloc
            || ' item=' || stsk.item || ' lpid=' || stsk.lpid
            || ' uom=' || stsk.uom || ' qty=' || stsk.qty);
      trace_msg('ADJXPICK', stsk.facility, stsk.custid, in_user,
            'puom=' || stsk.pickuom || ' pqty=' || stsk.pickqty
            || ' ptype=' || stsk.picktotype || ' pzone=' || stsk.pickingzone
            || ' ctn=' || stsk.cartontype || ' slpid=' || stsk.shippinglpid
            || ' stype=' || stsk.shippingtype || ' cgroup=' || stsk.cartongroup);
      trace_msg('ADJXPICK', stsk.facility, stsk.custid, in_user,
            'wave=' || stsk.wave || ' qtypkd' || stsk.qtypicked
            || ' luom=' || stsk.labeluom || ' in_qty=' || in_qty
            || ' in_pqty=' || in_pickqty || ' in_shlpid=' || in_shlpid);
      zrf.so_release(l_key);
      return;
   end if;

   update subtasks
      set qty = in_qty,
          pickqty = in_pickqty,
          pickuom = in_pickuom,
          weight = in_pickqty * zci.item_weight(stsk.custid, stsk.item, in_pickuom),
          cube = in_pickqty * zci.item_cube(stsk.custid, stsk.item, in_pickuom),
          lastuser = in_user,
          lastupdate = sysdate
      where rowid = chartorowid(in_subtask_rowid);

-- build a new subtask
   if (in_shlpid is not null) then
      zsp.get_next_shippinglpid(xtralpid, msg);
      if (msg is not null) then
         out_message := msg;
         return;
      end if;
   end if;

-- convert baseuom qty left into pickuom qty
   l_qty_pickuom := zlbl.uom_qty_conv(stsk.custid, stsk.item, stsk.qty-in_qty,
         stsk.uom, stsk.pickuom);
-- if exact conversion use pickuom else baseuom
   if stsk.qty-in_qty = zlbl.uom_qty_conv(stsk.custid, stsk.item, l_qty_pickuom,
         stsk.pickuom, stsk.uom) then
      l_pickqty := l_qty_pickuom;
      l_pickuom := stsk.pickuom;
   else
      l_pickqty := stsk.qty-in_qty;
      l_pickuom := stsk.uom;
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
       stsk.lpid, stsk.uom, stsk.qty-in_qty, stsk.locseq,
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
          satdeliveryused, openfacility, audited, manufacturedate,
          expirationdate)
      select xtralpid, S.item, S.custid, S.facility, S.location, 'U',
             S.holdreason, S.unitofmeasure, S.quantity-in_qty, 'P', stsk.lpid,
             S.serialnumber, S.lotnumber, null, S.useritem1, S.useritem2, S.useritem3,
             in_user, sysdate, S.invstatus, S.qtyentered, S.orderitem, S.uomentered,
             S.inventoryclass, S.loadno, S.stopno, S.shipno, S.orderid, S.shipid,
             l_pickqty*zci.item_weight(S.custid, S.item, l_pickuom),
             null, null, S.taskid, S.dropseq, S.orderlot, l_pickuom,
             l_pickqty, S.trackingno, S.cartonseq, S.checked, S.totelpid,
             S.cartontype, S.pickedfromloc, S.shippingcost, S.carriercodeused,
             S.satdeliveryused, S.openfacility, S.audited, S.manufacturedate,
             S.expirationdate
         from shippingplate S
         where S.lpid = in_shlpid;
   end if;

   l_elapsed_end := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'end ZRFPK.ADJUST_FOR_EXTRA_PICK - ' ||
                    'out_rowid: ' || out_rowid || ', ' ||
                    'out_message: ' || out_message ||
                    ' (Elapsed: ' ||
                    rtrim(substr(zlb.formatted_staffhrs((l_elapsed_end - l_elapsed_begin)*24),1,12)) ||
                    ')',
                    'T', in_user);
exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end adjust_for_extra_pick;


procedure get_alternate_pick
   (in_subtask_rowid in varchar2,
    in_user          in varchar2,
    in_equipment     in varchar2,
    out_lpid         out varchar2,
    out_location     out varchar2,
    out_message      out varchar2)
is
   cursor c_st is
      select *
         from subtasks
         where rowid = chartorowid(in_subtask_rowid);
   st c_st%rowtype;
   cursor c_lp is
      select plate.*,
             least(trunc(creationdate),nvl(trunc(anvdate),trunc(creationdate))) receiptdate
         from plate
         where lpid = st.lpid;
   ilp c_lp%rowtype;
   olp c_lp%rowtype;
   cursor c_itm is
      select allocrule
         from custitemfacilityview
         where custid = ilp.custid
           and item = ilp.item
           and facility = ilp.facility;
   itm c_itm%rowtype;
   cursor c_itv is
      select fifowindowdays, nvl(lotrequired,'N') lotrequired, nvl(restrict_lot_sub,'N') restrict_lot_sub
         from custitemview
         where custid = ilp.custid
           and item = ilp.item;
   itv c_itv%rowtype;
   cursor c_adtl is
      select nvl(datetype, 'M') as datetype
         from allocrulesdtl
         where facility = ilp.facility
           and allocrule = itm.allocrule
           and nvl(invstatus, ilp.invstatus) = ilp.invstatus
           and nvl(inventoryclass, ilp.inventoryclass) = ilp.inventoryclass
           and uom = st.pickuom
           and st.pickqty between nvl(qtymin, 1) and nvl(qtymax, 9999999)
           and (nvl(pickingzone, st.pickingzone) = st.pickingzone or st.pickingzone is null)
         order by priority;
   ad c_adtl%rowtype;
   cursor c_od is
      select invstatusind, invstatus, invclassind, inventoryclass, nvl(unrestrict_lot_sub,'N') unrestrict_lot_sub
         from orderdtl
         where orderid = st.orderid
           and shipid = st.shipid
           and item = st.orderitem
           and nvl(lotnumber, '(none)') = nvl(st.orderlot, '(none)');
   od c_od%rowtype;
   cursor c_loc is
      select equipprof
         from location
         where facility = ilp.facility
           and locid = olp.location;
   loc c_loc%rowtype;
   rowfound boolean;
   c_altpick integer;
   cntrows integer;
   cmdsql varchar2(2000);
   v_shippingtype subtasks.shippingtype%type;
begin
   out_lpid := null;
   out_location := null;
   out_message := null;

   open c_st;
   fetch c_st into st;
   close c_st;

   open c_lp;
   fetch c_lp into ilp;
   close c_lp;

   open c_itm;
   fetch c_itm into itm;
   close c_itm;

   open c_itv;
   fetch c_itv into itv;
   close c_itv;

   v_shippingtype := st.shippingtype;
   if (st.qty = ilp.quantity and st.uom = ilp.unitofmeasure) then
    v_shippingtype := 'F';
   end if;

   cmdsql := 'select lpid, location from availstatusclassview'
            || ' where facility = ''' || nvl(ilp.facility,'x') || ''''
            ||   ' and custid = ''' || nvl(ilp.custid,'x') || ''''
            ||   ' and item = ''' || nvl(ilp.item,'x') || '''';

   if (st.orderlot is not null) then
      cmdsql := cmdsql || ' and lotnumber = ''' || st.orderlot || '''';
   end if;

   if ((nvl(st.orderid, 0) != 0) and (nvl(st.shipid, 0) != 0)) then
      open c_od;
      fetch c_od into od;
      close c_od;
      
      if (st.orderlot is null) then
        if (itv.lotrequired = 'S' and itv.restrict_lot_sub = 'Y' and od.unrestrict_lot_sub = 'N'
              and ilp.lotnumber is not null) then
          cmdsql := cmdsql || ' and lotnumber = ''' || ilp.lotnumber || '''';
        end if;
      end if;
      
      if rtrim(od.invstatus) is not null then
         cmdsql := cmdsql || ' and invstatus '
                  || zcm.in_str_clause(od.invstatusind, od.invstatus);
      end if;
      if rtrim(od.inventoryclass) is not null then
         cmdsql := cmdsql || ' and inventoryclass '
                  || zcm.in_str_clause(od.invclassind, od.inventoryclass);
      end if;
   end if;

   if (itm.allocrule is not null) and (itv.fifowindowdays is not null) then
      open c_adtl;
      fetch c_adtl into ad;
      rowfound := c_adtl%found;
      close c_adtl;
      if rowfound then
         if (ad.datetype = 'E') then
            cmdsql := cmdsql || ' and to_date(expirationdate) between '''
                             || to_date(ilp.expirationdate-itv.fifowindowdays) || ''' and '''
                             || to_date(ilp.expirationdate+itv.fifowindowdays) || '''';
         elsif (ad.datetype = 'M') then
            cmdsql := cmdsql || ' and to_date(manufacturedate) between '''
                             || to_date(ilp.manufacturedate-itv.fifowindowdays) || ''' and '''
                             || to_date(ilp.manufacturedate+itv.fifowindowdays) || '''';
         else
            cmdsql := cmdsql || ' and to_date(least(trunc(creationdate),nvl(trunc(anvdate),trunc(creationdate)))) between '''
                             || to_date(ilp.receiptdate-itv.fifowindowdays) || ''' and '''
                             || to_date(ilp.receiptdate+itv.fifowindowdays) || '''';
         end if;
      end if;
   end if;

   if (v_shippingtype = 'F') then
      cmdsql := cmdsql || ' and nvl(qtytasked, 0) = 0'
                       || ' and quantity = ' || ilp.quantity;
   else
      cmdsql := cmdsql || ' and quantity >= ' || st.pickqty
                       || ' - nvl(qtytasked,0)';
   end if;

   -- mod to consider all picking zones
   /*
   if (st.pickingzone is not null) then
      cmdsql := cmdsql || ' and pickingzone = ''' || st.pickingzone || '''';
   end if;
   */

   cmdsql := cmdsql || ' and location not in (select location from nixedpickloc'
            || ' where facility = ''' || nvl(ilp.facility,'x') || ''''
            ||   ' and nameid = ''' || in_user || ''')';

   -- include all picking zones, but look in the current one first
   if (st.pickingzone is not null) then
      cmdsql := cmdsql || ' order by case when nvl(pickingzone,''' || st.pickingzone || ''')  = ''' || st.pickingzone || ''' then 1 else 2 end';
   end if;

   begin
      c_altpick := dbms_sql.open_cursor;
      dbms_sql.parse(c_altpick, cmdsql, dbms_sql.native);
      dbms_sql.define_column(c_altpick, 1, olp.lpid, 15);
      dbms_sql.define_column(c_altpick, 2, olp.location, 10);
      cntrows := dbms_sql.execute(c_altpick);
      while (1=1)
      loop
         cntrows := dbms_sql.fetch_rows(c_altpick);
         exit when (cntrows <= 0);
         dbms_sql.column_value(c_altpick, 1, olp.lpid);
         dbms_sql.column_value(c_altpick, 2, olp.location);

         open c_loc;
         fetch c_loc into loc;
         close c_loc;

         if (loc.equipprof is not null) then
            select count(1) into cntrows
               from equipprofequip
               where profid = loc.equipprof
                 and equipid = in_equipment;

            if (cntrows = 0) then
               goto continue_loop;
            end if;
         end if;

         out_lpid := olp.lpid;
         out_location := olp.location;
         exit;

      <<continue_loop>>
         null;

      end loop;
      dbms_sql.close_cursor(c_altpick);
   exception
      when NO_DATA_FOUND then
         dbms_sql.close_cursor(c_altpick);
   end;

exception
   when OTHERS then
      declare
         error_code number := sqlcode;
         cnt integer := 1;
         msg varchar2(255);
      begin
         if (sqlcode = -936) then
            trace_msg('ALTPICK', st.facility, st.custid, in_user,
                  'order=' || st.orderid || '-' || st.shipid
                  || ' lp=' || st.lpid || ' item=' || st.orderitem
                  || ' lot=' || st.orderlot || ' uom=' || st.pickuom
                  || ' qty=' || st.pickqty || ' zone=' || st.pickingzone);
            while (cnt * 60) < (length(cmdsql)+60)
            loop
               trace_msg('ALTPICK', st.facility, st.custid, in_user,
                     substr(cmdsql,((cnt-1)*60)+1,60));
               cnt := cnt + 1;
            end loop;
         end if;
         out_message := substr(sqlerrm, 1, 80);
      end;
end get_alternate_pick;


procedure assign_step2_plates
   (in_taskid   in number,
    in_fromloc  in varchar2,
    in_user     in varchar2,
    out_message out varchar2)
is
   cursor c_tsk(p_taskid number) is
      select tasktype
         from tasks
         where taskid = p_taskid;
   tsk c_tsk%rowtype;
   l_found boolean;
begin
   out_message := null;

   open c_tsk(in_taskid);
   fetch c_tsk into tsk;
   l_found := c_tsk%found;
   close c_tsk;
   if not l_found then
      return;
   end if;

   if tsk.tasktype in ('MV','PA') then
      for st in (select lpid from subtasks where taskid = in_taskid) loop
         update plate
            set location = in_user,
                prevlocation = in_fromloc,
                status = decode(status,'P','P','M'),
                lasttask = tsk.tasktype,
                taskid = in_taskid,
                lastoperator = in_user,
                lastuser = in_user,
                lastupdate = sysdate
            where lpid in (select lpid from plate
                     start with lpid = st.lpid
                     connect by prior lpid = parentlpid);
      end loop;
      return;
   end if;

   if tsk.tasktype in ('BP','OP','PK','SO') then
      for st in (select shippinglpid, shippingtype, picktotype
               from subtasks where taskid = in_taskid) loop
         if st.shippingtype = 'F' then
            update plate
               set location = in_user,
                   prevlocation = in_fromloc,
                   lasttask = tsk.tasktype,
                   taskid = in_taskid,
                   lastoperator = in_user,
                   lastuser = in_user,
                   lastupdate = sysdate
               where lpid in (select fromlpid from shippingplate
                        where lpid = st.shippinglpid)
                 and status = 'P';
         end if;
         -- for batch picks the lp is in the plate table and there is no
         -- shipping plate
         if tsk.tasktype = 'BP' then
            update plate
               set location = in_user,
                   prevlocation = in_fromloc,
                   status = 'M',
                   lasttask = tsk.tasktype,
                   taskid = in_taskid,
                   lastoperator = in_user,
                   lastuser = in_user,
                   lastupdate = sysdate
             where lpid = st.shippinglpid
               and status = 'A';
         end if;
         update shippingplate
            set location = in_user,
                prevlocation = in_fromloc,
                taskid = in_taskid,
                lastuser = in_user,
                lastupdate = sysdate
            where lpid in (select lpid from shippingplate
                     start with lpid = st.shippinglpid
                     connect by prior parentlpid = lpid)
              and status = 'P';

         if st.picktotype = 'TOTE' then
            update plate
               set location = in_user,
                   prevlocation = in_fromloc,
                   lasttask = tsk.tasktype,
                   taskid = in_taskid,
                   lastoperator = in_user,
                   lastuser = in_user,
                   lastupdate = sysdate
               where lpid in (select totelpid from shippingplate
                        where lpid = st.shippinglpid)
                 and status = 'P';
         end if;
      end loop;
      return;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end assign_step2_plates;


procedure take_item
   (in_facility     in varchar2,
    in_orderid      in number,
    in_shipid       in number,
    in_custid       in varchar2,
    in_item         in varchar2,
    in_qty          in number,
    in_uom          in varchar2,
    in_lpid         in varchar2,
    in_loc          in varchar2,
    in_shiplpid     in varchar2,
    in_user         in varchar2,
    out_errorno     out number,
    out_message     out varchar2,
    out_loaded_load out varchar2)   -- non-zero if load switched to status '8'; else 0
is
   cursor c_oh(p_orderid number, p_shipid number) is
      select OH.ordertype, OH.orderstatus, OH.fromfacility, OH.custid, OH.loadno,
             OH.stopno, OH.shipno, nvl(LD.doorloc,'(none)') as doorloc
      from orderhdr OH, loads LD
      where OH.orderid = p_orderid
        and OH.shipid = p_shipid
        and LD.loadno (+) = OH.loadno;
   oh c_oh%rowtype;

   cursor c_od(p_orderid number, p_shipid number, p_item varchar2) is
      select uom, qtyorder, nvl(qtypick,0) as qtypick, invstatusind, invstatus,
             invclassind, inventoryclass, itementered, lotnumber, rowid
         from orderdtl
         where orderid = p_orderid
           and shipid = p_shipid
           and item = p_item;
   od c_od%rowtype;

   cursor c_lp(p_lpid varchar2) is
      select type, status, facility, custid, item, quantity, invstatus, inventoryclass,
             holdreason, serialnumber, lotnumber, useritem1, useritem2, useritem3,
             location, parentlpid, rowid, weight, manufacturedate, expirationdate
         from plate
         where lpid = p_lpid;
   lp c_lp%rowtype;

   l_found boolean;
   l_msg varchar2(255);
   l_err varchar2(1);
   l_baseqty shippingplate.quantity%type;
   l_qtytopick shippingplate.quantity%type;
   l_shlpid shippingplate.lpid%type;
   l_cnt pls_integer;
   l_builtmlip shippingplate.lpid%type := null;
   l_key number := 0;
   l_is_loaded varchar2(1);
begin
   out_errorno := 0;
   out_message := null;
   out_loaded_load := 0;

   zrf.so_lock(l_key);
   open c_oh(in_orderid, in_shipid);
   fetch c_oh into oh;
   l_found := c_oh%found;
   close c_oh;
   if not l_found then
      out_errorno := 1;
      out_message := 'Order not found';
      return;
   end if;
   if oh.ordertype != 'O' then
      out_errorno := 2;
      out_message := 'Not outbound order';
      return;
   end if;
   if oh.orderstatus not in ('4','5','6','7','8') then
      out_errorno := 3;
      out_message := 'Invalid order status';
      return;
   end if;
   if oh.fromfacility != in_facility then
      out_errorno := 4;
      out_message := 'Other order facility';
      return;
   end if;
   if oh.custid != in_custid then
      out_errorno := 5;
      out_message := 'Not customer''s order';
      return;
   end if;

   open c_od(in_orderid, in_shipid, in_item);
   fetch c_od into od;
   l_found := c_od%found;
   close c_od;
   if not l_found then
      out_errorno := 6;
      out_message := 'Item not for order';
      return;
   end if;

   open c_lp(in_lpid);
   fetch c_lp into lp;
   l_found := c_lp%found;
   close c_lp;
   if not l_found then
      out_errorno := 7;
      out_message := 'LP not found';
      return;
   end if;
   if lp.type != 'PA' then
      out_errorno := 8;
      out_message := 'Single LP only';
      return;
   end if;
   if lp.status != 'A' then
      out_errorno := 9;
      out_message := 'LP not available';
      return;
   end if;
   if lp.facility != in_facility then
      out_errorno := 10;
      out_message := 'Other LP facility';
      return;
   end if;
   if lp.custid != oh.custid then
      out_errorno := 11;
      out_message := 'LP not for customer';
      return;
   end if;
   if lp.item != in_item then
      out_errorno := 12;
      out_message := 'Item not on LP';
      return;
   end if;
   if not zrfpk.is_attrib_ok(od.invstatusind, od.invstatus, lp.invstatus) then
      out_errorno := 13;
      out_message := 'Wrong LP inv status';
      return;
   end if;
   if not zrfpk.is_attrib_ok(od.invclassind, od.inventoryclass, lp.inventoryclass) then
      out_errorno := 14;
      out_message := 'Wrong LP inv class';
      return;
   end if;

   zbut.translate_uom(oh.custid, in_item, in_qty, in_uom, od.uom, l_baseqty, l_msg);
   if substr(l_msg, 1, 4) != 'OKAY' then
      out_errorno := 15;
      out_message := 'Not item''s uom';
      return;
   end if;

   select nvl(sum(quantity), 0) into l_qtytopick
      from shippingplate
      where orderid = in_orderid
        and shipid = in_shipid
        and item = in_item
        and status = 'U';

   if (od.qtypick + l_baseqty + l_qtytopick) > od.qtyorder then
      out_errorno := 16;
      out_message := 'Qty exceeds ordered';
      return;
   end if;
   if lp.quantity < l_baseqty then
      out_errorno := 17;
      out_message := 'Qty not on LP';
      return;
   end if;

   zsp.get_next_shippinglpid(l_shlpid, l_msg);
   if l_msg is not null then
      out_errorno := 18;
      out_message := l_msg;
      return;
   end if;

   insert into shippingplate
      (lpid, item, custid, facility, location,
       status, holdreason, unitofmeasure, quantity,
       type, fromlpid, serialnumber,
       lotnumber, parentlpid, useritem1, useritem2, useritem3,
       lastuser, lastupdate, invstatus, qtyentered, orderitem, uomentered,
       inventoryclass, loadno, stopno, shipno, orderid,
       shipid, weight,
       ucc128, labelformat, taskid, dropseq, orderlot, pickuom, pickqty,
       trackingno, cartonseq, checked, totelpid, cartontype, pickedfromloc,
       shippingcost, carriercodeused, satdeliveryused, openfacility, audited,
       prevlocation, fromlpidparent, rmatrackingno, actualcarrier,
       manufacturedate, expirationdate)
   values
      (l_shlpid, in_item, lp.custid, in_facility, in_loc,
       'S', lp.holdreason, od.uom, l_baseqty,
       decode(l_baseqty, lp.quantity, 'F', 'P'), in_lpid, lp.serialnumber,
       lp.lotnumber, null, lp.useritem1, lp.useritem2, lp.useritem3,
       in_user, sysdate, lp.invstatus, in_qty, od.itementered, in_uom,
       lp.inventoryclass, oh.loadno, oh.stopno, oh.shipno, in_orderid,
       in_shipid, l_baseqty*lp.weight/lp.quantity,
       null, null, null, null, od.lotnumber, in_uom, in_qty,
       null, null, null, null, null, lp.location,
       null, null, null, null, null,
       null, lp.parentlpid, null, null,
       lp.manufacturedate, lp.expirationdate);

   if lp.quantity = l_baseqty then     -- full pick
      if (in_shiplpid is not null) and (in_shiplpid != in_lpid) then
         out_errorno := 19;
         out_message := 'To LP not valid';
         return;
      end if;

      update plate
         set location = in_loc,
             status = 'P',
             lasttask = 'PK',
             lastoperator = in_user,
             lastuser = in_user,
             lastupdate = sysdate
         where rowid = lp.rowid;
   else                                -- partial pick
      if in_shiplpid is null then
         out_errorno := 20;
         out_message := 'To LP required';
         return;
      end if;

      select count(1) into l_cnt
         from plate
         where lpid = in_shiplpid;
      if l_cnt != 0 then
         out_errorno := 21;
         out_message := 'To LP exists';
         return;
      end if;

      zrfpk.build_mast_shlp(in_shiplpid, l_shlpid, in_user, 'PK', l_builtmlip, l_msg);
      if l_msg is not null then
         out_errorno := 22;
         out_message := l_msg;
         return;
      end if;
      l_shlpid := l_builtmlip;

      zrf.decrease_lp(in_lpid, lp.custid, in_item, l_baseqty, lp.lotnumber,
            od.uom, in_user, 'PK', lp.invstatus, lp.inventoryclass, l_err, l_msg);
      if l_msg is not null then
         out_errorno := 23;
         out_message := l_msg;
         return;
      end if;
   end if;

   update orderdtl
      set qtypick = nvl(qtypick, 0) + l_baseqty,
          weightpick = nvl(weightpick, 0) + l_baseqty*lp.weight/lp.quantity,
          cubepick = nvl(cubepick, 0)
               + (in_qty*zci.item_cube(lp.custid, in_item, in_uom)),
          amtpick = nvl(amtpick, 0) + (l_baseqty*zci.item_amt(lp.custid, in_orderid, in_shipid, in_item, lotnumber)), --prn 25133
          lastuser = in_user,
          lastupdate = sysdate
      where rowid = od.rowid;

   update orderhdr
      set orderstatus = zrf.ORD_PICKING,
          lastuser = in_user,
          lastupdate = sysdate
      where orderid = in_orderid
        and shipid = in_shipid
        and orderstatus < zrf.ORD_PICKING;

   if oh.loadno is not null then
      update loadstop
         set loadstopstatus = zrf.LOD_PICKING,
             lastuser = in_user,
             lastupdate = sysdate
         where loadno = oh.loadno
           and stopno = oh.stopno
           and loadstopstatus < zrf.LOD_PICKING;
      update loads
         set loadstatus = zrf.LOD_PICKING,
             lastuser = in_user,
             lastupdate = sysdate
         where loadno = oh.loadno
           and loadstatus < zrf.LOD_PICKING;
   end if;

   zoh.add_orderhistory_item(in_orderid, in_shipid, l_shlpid, in_item, lp.lotnumber,
         'Pick Plate', 'Pick Qty:'||in_qty||' from LP:'||in_lpid, in_user, l_msg);

   update location
      set pickcount = nvl(pickcount, 0) + 1,
          lastpickedfrom = sysdate
      where facility = in_facility
        and locid = in_loc;

   update itempickfronts
      set lastpickeddate = sysdate
      where facility = in_facility
        and pickfront = in_loc;

   bump_custitemcount(lp.custid, in_item, 'PICK', in_uom, in_qty, in_user, l_err, l_msg);
   if l_msg is not null then
      out_errorno := 24;
      out_message := l_msg;
      return;
   end if;

   check_all_picked(in_orderid, in_shipid, in_user, l_msg);
   if l_msg is not null then
      out_errorno := 25;
      out_message := l_msg;
      return;
   end if;

   if (oh.orderstatus in ('7','8')) and (in_loc = OH.doorloc) then
      update shippingplate
         set location = in_user
         where lpid in (select lpid from shippingplate
               start with lpid = l_shlpid
               connect by prior lpid = parentlpid);

      zrfld.load_shipplates(in_facility, in_user, oh.loadno, oh.stopno, in_loc,
         l_err, l_msg, l_is_loaded);
      if l_msg is not null then
         out_errorno := 26;
         out_message := l_msg;
         return;
      end if;

      if l_is_loaded = 'Y' then
         out_loaded_load := oh.loadno;
      end if;
   end if;

exception when others then
  out_errorno := sqlcode;
  out_message := sqlerrm;

end take_item;


procedure any_after_pick_counting
   (in_facility     in varchar2,
    in_location     in varchar2,
    in_lpid         in varchar2,
    in_user         in varchar2,
    out_taskid      out number,
    out_message     out varchar2)
is
   cursor c_loc(p_facility varchar2, p_locid varchar2) is
      select L.section, L.equipprof,
             decode(nvl(L.count_after_pick,'Z'),
               'Z', nvl(Z.count_after_pick,'N'),
                    nvl(L.count_after_pick,'N')) as count_after_pick,
             nvl(countback_sv_override,'N') as sv_override
      from location L, zone Z, facility F
      where L.facility = p_facility
        and L.locid = p_locid
        and Z.facility (+) = L.facility
        and Z.zoneid (+) = L.pickingzone
        and F.facility = L.facility;
   loc c_loc%rowtype;
   l_cnt pls_integer;
   l_taskid tasks.taskid%type;
   l_msg varchar2(80);
   l_custid plate.custid%type := null;
   l_item plate.item%type := null;
   l_plate_count number;
begin
   out_message := null;
   out_taskid := 0;

   open c_loc(in_facility, in_location);
   fetch c_loc into loc;
   if c_loc%notfound then
      loc.count_after_pick := 'N';
   end if;
   close c_loc;
   if loc.count_after_pick = 'N' then     -- no cycle count after pick
      return;
   end if;

   select count(1) into l_cnt
      from tasks
      where tasktype = 'CC'
        and facility = in_facility
        and fromloc = in_location
        and item is null;
   if l_cnt != 0 then                     -- task already exists
      return;
   end if;

   if (loc.count_after_pick = 'L') then
    select count(1) into l_plate_count
    from plate
    where lpid = in_lpid and status = 'A' and nvl(quantity,0) > 0 and type = 'PA';

    if (l_plate_count = 0) then
      return;
    end if;

    begin
      select custid, item into l_custid, l_item
      from plate
      where lpid = in_lpid;
    exception
      when others then
        l_custid := null;
        l_item := null;
    end;
   end if;

   ztsk.get_next_taskid(l_taskid, l_msg);
   if l_msg is not null then
      out_message := l_msg;
   else
      insert into tasks
         (taskid, tasktype, facility, fromsection, fromloc,
          fromprofile, qty, priority, prevpriority, lastuser,
          lastupdate, curruserid, toloc,
          lpid, loadno, custid, item)
      values
         (l_taskid, 'CC', in_facility, loc.section, in_location,
          loc.equipprof, 1, '0', decode(loc.sv_override,'N','3','1'), in_user,
          sysdate, in_user, '(aft pick)',
          decode(loc.count_after_pick,'L',in_lpid,null), decode(loc.count_after_pick,'L',-1,null),
          l_custid, l_item);

      insert into subtasks
         (taskid, tasktype, facility, fromsection, fromloc,
          fromprofile, qty, priority, lastuser, lastupdate, lpid)
      values
         (l_taskid, 'CC', in_facility, loc.section, in_location,
          loc.equipprof, 1, '3', in_user, sysdate, decode(loc.count_after_pick,'L',in_lpid,null));

      out_taskid := l_taskid;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end any_after_pick_counting;


procedure putaway_virtual
   (in_lpid     in varchar2,
    in_user     in varchar2,
    out_message out varchar2)
is
   cursor c_lp(p_lpid varchar2) is
      select facility, location
         from plate
         where lpid = p_lpid
           and status = 'A'
           and nvl(virtuallp,'N') = 'Y';
   lp c_lp%rowtype := null;
   l_msg varchar2(80) := null;
   l_fac plate.facility%type;
   l_loc plate.location%type;
begin
   out_message := null;

   open c_lp(in_lpid);
   fetch c_lp into lp;
   close c_lp;
   if lp.facility is not null then     -- plate still exists
      if not zrf.any_tasks_for_lp(in_lpid, null) then  -- no tasks remaining
         if not any_vlp_batch_work(in_lpid) then   -- no sorts pending
            zput.putaway_lp('TANR', in_lpid, lp.facility, lp.location, in_user, 'Y',
                  null, l_msg, l_fac, l_loc);
         end if;
      end if;
   end if;

   out_message := l_msg;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end putaway_virtual;


procedure stage_full_virtual
   (in_lpid     in varchar2,
    in_user     in varchar2,
    in_tasktype in varchar2,
    out_message out varchar2)
is
   cursor c_sp(p_lpid varchar2) is
      select *
         from shippingplate
         where lpid = p_lpid;
   sp c_sp%rowtype := null;
   cursor c_cp(p_lpid varchar2) is
      select lpid, quantity, unitofmeasure, weight, serialnumber, lotnumber, useritem1,
             useritem2, useritem3, invstatus, inventoryclass, manufacturedate,
             expirationdate
         from plate
         where parentlpid = p_lpid;
   l_msg varchar2(255) := null;
   l_qty_pickuom shippingplate.pickqty%type;
   l_pickqty shippingplate.pickqty%type;
   l_pickuom shippingplate.pickuom%type;
   l_elapsed_begin date;
   l_elapsed_end date;
begin
   l_elapsed_begin := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'begin ZRFPK.STAGE_FULL_PARTIAL - ' ||
                    'in_lpid: ' || in_lpid || ', ' ||
                    'in_user: ' || in_user || ', ' ||
                    'in_tasktype: ' || in_tasktype,
                    'T', in_user);
   out_message := null;

   open c_sp(in_lpid);
   fetch c_sp into sp;
   close c_sp;

   for cp in c_cp(sp.fromlpid) loop

      zsp.get_next_shippinglpid(sp.lpid, l_msg);
      if l_msg is null then

         zplp.detach_child_plate(sp.fromlpid, cp.lpid, sp.location, null,
               null, 'P', in_user, in_tasktype, l_msg);
         if l_msg is null then

--          convert baseuom qty into pickuom qty
            l_qty_pickuom := zlbl.uom_qty_conv(sp.custid, sp.item, cp.quantity,
                  cp.unitofmeasure, sp.pickuom);
--          if exact conversion use pickuom else baseuom
            if cp.quantity = zlbl.uom_qty_conv(sp.custid, sp.item, l_qty_pickuom,
                  sp.pickuom, sp.unitofmeasure) then
               l_pickqty := l_qty_pickuom;
               l_pickuom := sp.pickuom;
            else
               l_pickqty := cp.quantity;
               l_pickuom := cp.unitofmeasure;
            end if;

            insert into shippingplate
               (lpid, item, custid, facility,
                location, status, holdreason, unitofmeasure,
                quantity, type, fromlpid, serialnumber,
                lotnumber, parentlpid, useritem1, useritem2,
                useritem3, lastuser, lastupdate, invstatus,
                qtyentered, orderitem, uomentered, inventoryclass,
                loadno, stopno, shipno, orderid,
                shipid, weight, ucc128, labelformat,
                taskid, dropseq, orderlot, pickuom,
                pickqty, trackingno, cartonseq, checked,
                totelpid, cartontype, pickedfromloc, shippingcost,
                carriercodeused, satdeliveryused, openfacility, fromlpidparent,
                manufacturedate, expirationdate)
            values
               (sp.lpid, sp.item, sp.custid, sp.facility,
                sp.location, sp.status, sp.holdreason, cp.unitofmeasure,
                cp.quantity, 'F', cp.lpid, cp.serialnumber,
                cp.lotnumber, null, cp.useritem1, cp.useritem2,
                cp.useritem3, in_user, sysdate, cp.invstatus,
                cp.quantity, sp.orderitem, cp.unitofmeasure, cp.inventoryclass,
                sp.loadno, sp.stopno, sp.shipno, sp.orderid,
                sp.shipid, cp.weight, sp.ucc128, sp.labelformat,
                sp.taskid, sp.dropseq, sp.orderlot, l_pickuom,
                l_pickqty, sp.trackingno, sp.cartonseq, sp.checked,
                sp.totelpid, sp.cartontype, sp.pickedfromloc, sp.shippingcost,
                sp.carriercodeused, sp.satdeliveryused, sp.openfacility, sp.fromlpid,
                cp.manufacturedate, cp.expirationdate);
         end if;
      end if;

      out_message := substr(l_msg,1,80);
      exit when l_msg is not null;
   end loop;

   if l_msg is null then
      delete shippingplate where lpid = in_lpid;
   end if;
   l_elapsed_end := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'end ZRFPK.STAGE_FULL_VIRTUAL - ' ||
                    'out_message: ' || out_message ||
                    ' (Elapsed: ' ||
                    rtrim(substr(zlb.formatted_staffhrs((l_elapsed_end - l_elapsed_begin)*24),1,12)) ||
                    ')',
                    'T', in_user);

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end stage_full_virtual;


procedure check_overpick
   (in_pickqty       in number,
    in_item          in varchar2,
    in_pickuom       in varchar2,
    in_subtask_rowid in varchar2,
    out_lower        out number,
    out_upper        out number,
    out_errorno      out number,
    out_message      out varchar2)
is
   cursor c_pk(p_subtask_rowid varchar2) is
      select ST.orderid,
             ST.shipid,
             ST.custid,
             ST.orderitem,
             ST.orderlot,
             ST.tasktype,
             ST.uom,
             decode(nvl(OD.variancepct_use_default,'Y'),'N',
                    nvl(OD.variancepct,0),zci.variancepct(OD.custid,OD.item)) as variancepct,
             decode(nvl(OD.variancepct_use_default,'Y'),'N',
                    nvl(OD.variancepct_overage,0),zci.variancepct_overage(OD.custid,OD.item))
                    as variancepct_overage,
             nvl(OD.qtytype,'E') as qtytype,
             OD.qtyorder,
             nvl(OD.qtypick,0) as qtypick
         from subtasks ST, orderdtl OD
         where ST.rowid = chartorowid(p_subtask_rowid)
          and OD.orderid = ST.orderid
          and OD.shipid = ST.shipid
          and OD.item = ST.orderitem
          and nvl(OD.lotnumber,'x') = nvl(ST.orderlot,'x');
   pk c_pk%rowtype := null;
   l_picks_todo pls_integer := 0;
   l_quantity number := 0;
begin
   out_lower := 0;
   out_upper := 0;
   out_errorno := 0;
   out_message := 'OKAY';

   open c_pk(in_subtask_rowid);
   fetch c_pk into pk;
   close c_pk;
   if pk.custid is null then
      out_errorno := 1;
      out_message := 'Pick not found';
      return;
   end if;

   if pk.tasktype = 'BP' then
      out_errorno := 2;
      out_message := 'No batch overpick';
      return;
   end if;

   if pk.tasktype = 'SO' then
      out_errorno := 3;
      out_message := 'No sort overpick';
      return;
   end if;

   if zcord.cons_orderid(pk.orderid, pk.shipid) != 0 then
      out_errorno := 4;
      out_message := 'No cons overpick';
      return;
   end if;

   select count(1) into l_picks_todo
      from shippingplate
      where orderid = pk.orderid
        and shipid = pk.shipid
        and orderitem = pk.orderitem
        and nvl(orderlot,'x') = nvl(pk.orderlot,'x')
        and status = 'U';

   if l_picks_todo != 0 then
      l_quantity := zlbl.uom_qty_conv(pk.custid, in_item, in_pickqty, in_pickuom, pk.uom);
   end if;
   l_quantity := l_quantity + pk.qtypick;

   if pk.qtytype = 'E' then                     -- exact
      out_lower := pk.qtyorder;
      out_upper := pk.qtyorder;
      if l_picks_todo = 1 then                  -- last pick
         if l_quantity = pk.qtyorder then
            return;
         end if;
      else                                      -- not last, no overage
         if l_quantity < pk.qtyorder then
            return;
         end if;
      end if;
   else                                         -- approximate
      out_lower := (pk.variancepct/100) * pk.qtyorder;
      out_upper := (pk.variancepct_overage/100) * pk.qtyorder;
      if l_picks_todo = 1 then                  -- last pick
         if l_quantity between out_lower and out_upper then
            return;
         end if;
      else                                      -- not last, no overage
         if l_quantity < out_upper then
            return;
         end if;
      end if;
   end if;
   out_errorno := 5;
   out_message := 'Not in qty range';

exception
   when OTHERS then
      out_errorno := -1;
      out_message := substr(sqlerrm, 1, 80);
end check_overpick;


procedure pick_an_mp_child
   (in_taskid          in number,
    in_shlpid          in varchar2,
    in_user            in varchar2,
    in_plannedlp       in varchar2,
    in_pickedlp        in varchar2,
    in_custid          in varchar2,
    in_item            in varchar2,
    in_orderitem       in varchar2,
    in_lotno           in varchar2,
    in_dropseq         in number,
    in_pickfac         in varchar2,
    in_pickloc         in varchar2,
    in_baseuom         in varchar2,
    in_lplotno         in varchar2,
    in_mlip            in varchar2,
    in_picktype        in varchar2,
    in_tasktype        in varchar2,
    in_picktotype      in varchar2,
    in_fromloc         in varchar2,
    in_subtask_rowid   in varchar2,
    in_picked_child    in varchar2,
    in_pkd_lotno       in varchar2,
    in_pkd_serialno    in varchar2,
    in_pkd_user1       in varchar2,
    in_pkd_user2       in varchar2,
    in_pkd_user3       in varchar2,
    in_pickuom         in varchar2,
    in_unit_weight     in number,
    in_needed          in number,
    in_taskedlp        in varchar2,
    out_clip           out varchar2,
    out_lpcount        out number,
    out_error          out varchar2,
    out_message        out varchar2,
    out_picked         out varchar2)
is
   cursor c_child(p_lpid varchar2) is
      select serialnumber, lotnumber, useritem1, useritem2,
             useritem3, quantity, manufacturedate, expirationdate,
             item, unitofmeasure
         from plate
         where lpid = p_lpid;
   c c_child%rowtype := null;
   l_key number := 0;
   l_qty shippingplate.quantity%type;
   l_pickqty shippingplate.pickqty%type;
   l_pickuom shippingplate.pickuom%type;
   l_qty_pickuom shippingplate.pickqty%type;
   l_type shippingplate.type%type;
   l_clip shippingplate.lpid%type := in_shlpid;
   l_msg varchar2(80);
   l_err varchar2(1);
   l_elapsed_begin date;
   l_elapsed_end date;
   v_subtask_row subtasks%rowtype;
   v_new_subtask_rid varchar2(50);
   v_item orderdtl.item%type;
   v_lot orderdtl.lotnumber%type;
begin
   l_elapsed_begin := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'begin ZRFPK.PICK_AN_MP_CHILD',
                    'T', in_user);
   out_error := 'N';
   out_message := null;

   zrf.so_lock(l_key);
   open c_child(in_picked_child);
   fetch c_child into c;
   close c_child;

   if in_needed < c.quantity then
      l_type := 'P';
      l_qty := in_needed;
   else
      l_type := 'F';
      l_qty := c.quantity;
   end if;

-- convert baseuom qty into pickuom qty
   l_qty_pickuom := zlbl.uom_qty_conv(in_custid, in_item, l_qty, in_baseuom, in_pickuom);
-- if exact conversion use pickuom else baseuom
   if l_qty = zlbl.uom_qty_conv(in_custid, in_item, l_qty_pickuom, in_pickuom, in_baseuom) then
      l_pickqty := l_qty_pickuom;
      l_pickuom := in_pickuom;
   else
      l_pickqty := l_qty;
      l_pickuom := in_baseuom;
   end if;

   if (in_needed <= c.quantity) and (in_shlpid is not null) then
--    last child, use the original shipping plate

      update shippingplate
         set unitofmeasure = in_baseuom,
             quantity = l_qty,
             type = l_type,
             fromlpid = in_picked_child,
             serialnumber = c.serialnumber,
             parentlpid = in_mlip,
             lastuser = in_user,
             lastupdate = sysdate,
             qtyentered = l_qty,
             pickuom = l_pickuom,
             pickqty = l_pickqty,
             lotnumber = c.lotnumber,
             useritem1 = c.useritem1,
             useritem2 = c.useritem2,
             useritem3 = c.useritem3,
             manufacturedate = c.manufacturedate,
             expirationdate = c.expirationdate
         where lpid = in_shlpid;
   elsif (in_shlpid is not null) then
--    make a new copy of the shippingplate

      zsp.get_next_shippinglpid(l_clip, l_msg);
      if l_msg is not null then
         out_error := 'Y';
         out_message := l_msg;
         return;
      end if;

      insert into shippingplate
         (lpid, item, custid, facility, location, status,
          holdreason, unitofmeasure, quantity, type, fromlpid, serialnumber,
          lotnumber, parentlpid, useritem1, useritem2, useritem3, lastuser,
          lastupdate, invstatus, qtyentered, orderitem, uomentered, inventoryclass,
          loadno, stopno, shipno, orderid, shipid,
          ucc128, labelformat, taskid, dropseq, orderlot, pickuom,
          pickqty, trackingno, cartonseq, checked, totelpid, cartontype,
          pickedfromloc, shippingcost, carriercodeused, satdeliveryused,
          openfacility, manufacturedate, expirationdate)
      select l_clip, S.item, S.custid, S.facility, S.location, S.status,
             S.holdreason, in_baseuom, l_qty, l_type, in_picked_child, c.serialnumber,
             c.lotnumber, in_mlip, c.useritem1, c.useritem2, c.useritem3, in_user,
             sysdate, S.invstatus, l_qty, S.orderitem, S.uomentered, S.inventoryclass,
             S.loadno, S.stopno, S.shipno, S.orderid, S.shipid,
             S.ucc128, S.labelformat, S.taskid, S.dropseq, S.orderlot, l_pickuom,
             l_pickqty, S.trackingno, S.cartonseq, S.checked, S.totelpid, S.cartontype,
             S.pickedfromloc, S.shippingcost, S.carriercodeused, S.satdeliveryused,
             S.openfacility, c.expirationdate, c.expirationdate
         from shippingplate S
         where S.lpid = in_shlpid;
   else
    -- try to find the correct shipping plate, the subtask didn't have one

    begin
      select lpid
      into l_clip
      from shippingplate
      where orderid = (select orderid from tasks where taskid = in_taskid)
        and type = 'F'
        and fromlpid = in_picked_child;
    exception
      when others then
        l_clip := null;
    end;

    if (l_clip is not null) then
      select *
      into v_subtask_row
      from subtasks
      where rowid = chartorowid(in_subtask_rowid);

      v_item := c.item;
      -- get the right orderdtl lot (null or populated) to populate the subtask with
      begin
        select lotnumber
        into v_lot
        from orderdtl
        where orderid = v_subtask_row.orderid and shipid = v_subtask_row.shipid
          and item = c.item and nvl(lotnumber,c.lotnumber) = c.lotnumber;
      exception
        when others then
          v_lot := null;
      end;

      if ((v_subtask_row.lpid != in_picked_child) and (in_needed <= c.quantity)) then
        -- update the subtask row
        update subtasks
        set lpid = in_picked_child,
          qty = in_needed,
          uom = c.unitofmeasure,
          pickqty = in_needed,
          pickuom = c.unitofmeasure,
          shippingtype = l_type,
          shippinglpid = l_clip,
          item = c.item,
          orderitem = c.item,
          orderlot = v_lot
        where rowid = chartorowid(in_subtask_rowid);

      elsif (v_subtask_row.lpid != in_picked_child) then
        -- split the subtask
        v_subtask_row.lpid := in_picked_child;
        v_subtask_row.qty := c.quantity;
        v_subtask_row.uom := c.unitofmeasure;
        v_subtask_row.pickqty := c.quantity;
        v_subtask_row.pickuom := c.unitofmeasure;
        v_subtask_row.shippingtype := 'F';
        v_subtask_row.shippinglpid := l_clip;
        v_subtask_row.item := c.item;
        v_subtask_row.orderitem := c.item;
        v_subtask_row.orderlot := v_lot;
        insert into subtasks values v_subtask_row;

        select rowid
        into v_new_subtask_rid
        from subtasks
        where taskid = v_subtask_row.taskid and lpid = in_picked_child;
      end if;
    end if;
   end if;

-- do the pick

   pick_a_plate(in_taskid, l_clip, in_user, in_plannedlp, in_pickedlp, in_custid,
         nvl(v_item, in_item), nvl(v_item, in_orderitem), nvl(v_lot, in_lotno), l_qty, in_dropseq, in_pickfac, in_pickloc,
         in_baseuom, in_lplotno, in_mlip, l_type, in_tasktype, in_picktotype, in_fromloc,
         nvl(v_new_subtask_rid, in_subtask_rowid), '1', in_picked_child, nvl(in_pkd_lotno, c.lotnumber), in_pkd_serialno,
         in_pkd_user1, in_pkd_user2, in_pkd_user3, l_pickuom, l_pickqty,
         l_pickqty*in_unit_weight, in_taskedlp, out_lpcount, l_err, l_msg);
   if (l_err = 'Y') or (l_msg is not null) then
      out_error := l_err;
      out_message := l_msg;
      rollback;
      return;
   end if;

   out_clip := l_clip;
   out_picked := l_qty;

   l_elapsed_end := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'end ZRFPK.PICK_AN_MP_CHILD' ||
                    'out_clip: ' || out_clip || ', ' ||
                    'out_picked: ' || out_picked ||
                    ' (Elapsed: ' ||
                    rtrim(substr(zlb.formatted_staffhrs((l_elapsed_end - l_elapsed_begin)*24),1,12)) ||
                    ')',
                    'T', in_user);
exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end pick_an_mp_child;


procedure pick_1_full
   (in_taskid          in number,
    in_shlpid          in varchar2,
    in_user            in varchar2,
    in_pickedlp        in varchar2,
    in_orderitem       in varchar2,
    in_lotno           in varchar2,
    in_dropseq         in number,
    in_pickuom         in varchar2,
    in_tasktype        in varchar2,
    in_picktotype      in varchar2,
    in_subtask_rowid   in varchar2,
    in_remaining       in number,
    out_clip           out varchar2,
    out_lpcount        out number,
    out_error          out varchar2,
    out_message        out varchar2)
is
   cursor c_lp(p_lpid varchar2) is
      select *
         from plate
         where lpid = p_lpid;
   lp c_lp%rowtype;
   l_key number := 0;
   l_baseqty shippingplate.quantity%type;
   l_lpid shippingplate.lpid%type := in_shlpid;
   l_elapsed_begin date;
   l_elapsed_end date;
begin
   l_elapsed_begin := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'begin ZRFPK.PICK_1_FULL - ' ||
                    'in_shlpid: ' || in_shlpid || ', ' ||
                    'in_pickedlp: ' || in_pickedlp,
                    'T', in_user);
   out_error := 'N';
   out_message := null;

   zrf.so_lock(l_key);

   open c_lp(in_pickedlp);
   fetch c_lp into lp;
   close c_lp;

   l_baseqty := zlbl.uom_qty_conv(lp.custid, lp.item, 1, in_pickuom, lp.unitofmeasure);

   if (in_remaining = 1) then

--   last, use the original shipping plate
      update shippingplate
         set quantity = l_baseqty,
             unitofmeasure = lp.unitofmeasure,
             lastuser = in_user,
             lastupdate = sysdate,
             qtyentered = 1,
             weight = lp.weight,
             pickuom = in_pickuom,
             pickqty = 1,
             type = 'F'
          where lpid = in_shlpid;
   else

--    make a new copy of the shippingplate
      zsp.get_next_shippinglpid(l_lpid, out_message);
      if out_message is not null then
         out_error := 'Y';
         return;
      end if;

      insert into shippingplate
         (lpid, item, custid, facility, location, status,
          holdreason, unitofmeasure, quantity, type, fromlpid, serialnumber,
          lotnumber, parentlpid, useritem1, useritem2, useritem3, lastuser,
          lastupdate, invstatus, qtyentered, orderitem, uomentered, inventoryclass,
          loadno, stopno, shipno, orderid, shipid, weight,
          ucc128, labelformat, taskid, dropseq, orderlot, pickuom,
          pickqty, trackingno, cartonseq, checked, totelpid, cartontype,
          pickedfromloc, shippingcost, carriercodeused, satdeliveryused, openfacility,
          manufacturedate, expirationdate)
      select l_lpid, S.item, S.custid, S.facility, S.location, S.status,
             S.holdreason, S.unitofmeasure, l_baseqty, 'F', S.fromlpid, S.serialnumber,
             S.lotnumber, S.parentlpid, S.useritem1, S.useritem2, S.useritem3, in_user,
             sysdate, S.invstatus, 1, S.orderitem, S.uomentered, S.inventoryclass,
             S.loadno, S.stopno, S.shipno, S.orderid, S.shipid, 0,
             S.ucc128, S.labelformat, S.taskid, S.dropseq, S.orderlot, in_pickuom,
             1, S.trackingno, S.cartonseq, S.checked, S.totelpid, S.cartontype,
             S.pickedfromloc, S.shippingcost, S.carriercodeused, S.satdeliveryused, S.openfacility,
             S.manufacturedate, S.expirationdate
         from shippingplate S
         where S.lpid = in_shlpid;
   end if;

-- do the pick
   pick_a_plate(in_taskid, l_lpid, in_user, null, in_pickedlp, lp.custid, lp.item,
         in_orderitem, in_lotno, l_baseqty, in_dropseq, lp.facility,
         lp.location, lp.unitofmeasure, lp.lotnumber, null, 'F', in_tasktype, in_picktotype,
         lp.location, in_subtask_rowid, null, null, null, null, null,
         null, null, in_pickuom, 1, lp.weight, null, out_lpcount, out_error, out_message);
   if (out_error = 'Y') or (out_message is not null) then
      rollback;
   end if;

   out_clip := l_lpid;
   l_elapsed_end := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'end ZRFPK.PICK_1_FULL - ' ||
                    'out_clip: ' || out_clip || ', ' ||
                    'out_message: ' || out_message ||
                    ' (Elapsed: ' ||
                    rtrim(substr(zlb.formatted_staffhrs((l_elapsed_end - l_elapsed_begin)*24),1,12)) ||
                    ')',
                    'T', in_user);

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end pick_1_full;

procedure is_auto_stage_loc_mixed
   (in_orderid in number,
    in_shipid in number,
    in_user in varchar2,
    out_mixed out varchar2
    )
is PRAGMA AUTONOMOUS_TRANSACTION;
is_mixed char(1);
cnt integer;
begin
   begin
     select autostagemixzone_yn into is_mixed
        from orderhdr
        where orderid = in_orderid
          and shipid = in_shipid;
   exception when no_data_found then
      is_mixed := 'Y';
   end;

   if is_mixed is not null then
      out_mixed := is_mixed;
      rollback;
      return;
   end if;
   select count(1) into cnt
      from orderhdr
      where orderid = in_orderid
        and shipid = in_shipid;
   select count(distinct Z.auto_stage_location) into cnt
    from subtasks S, zone Z
   where S.orderid = in_orderid
     and S.shipid = in_shipid
     and Z.facility = S.facility
     and Z.zoneid = S.pickingzone
     and nvl(Z.auto_stage_yn,'N') != 'N';
   if cnt > 1 then
      out_mixed := 'Y';
   else
      out_mixed := 'N';
   end if;
   update orderhdr
      set autostagemixzone_yn = out_mixed,
          lastupdate = sysdate,
          lastuser = in_user
      where orderid = in_orderid
        and shipid = in_shipid;
   commit;
   return;

exception when others then
  out_mixed := 'N';
  rollback;
end is_auto_stage_loc_mixed;


procedure is_print_at_pick_ok
   (in_facility      in varchar2,
    in_custid        in varchar2,
    in_enteredlpid   in varchar2,
    out_ok           out varchar2)
is
pSTOok char(1);
lLocid location.locid%type;
lLoctype location.loctype%type;
begin
   out_ok := 'Y';
   select nvl(pick_labels_sto_only_yn, 'N') into pSTOok
         from customer_aux
         where custid = in_custid;
   if pSTOok <> 'Y' then
      return;
   end if;
   begin
      select locid
         into lLocid
         from location
         where facility = in_facility
           and locid = (select location from plate where lpid = in_enteredlpid);
   exception when no_data_found then
      lLocid := null;
   end;
   if lLocid is null then
      begin
         select locid
            into lLocid
            from location
            where facility = in_facility
              and locid = (select location from deletedplate where lpid = in_enteredlpid);
      exception when no_data_found then
         lLocid := null;
      end;
   end if;
   if lLocid is null then
      return;
   end if;
   select loctype
      into lLoctype
      from location
     where facility = in_facility
       and locid = lLocid;
   if lLoctype <> 'STO' then
      out_ok := 'N';
   end if;
exception when others then
   out_ok := 'Y';
end is_print_at_pick_ok;

procedure ship_matissue_lp
  (in_shlpid        in varchar2,
   in_user          in varchar2,
   out_error        out varchar2,
   out_message      out varchar2)
as
  v_outmsg varchar2(255);
  v_rowid varchar2(20);
  v_map customer_aux.outmatissueplatemap%type;
  v_custid customer_aux.custid%type;
  v_facility shippingplate.facility%type;
  v_message varchar2(255);
  out_errorno integer;
begin

  out_error := 'N';

  for rec in (select a.orderid, a.shipid, a.orderitem, a.orderlot, a.item, a.lotnumber, a.quantity, a.unitofmeasure,
                a.weight, zci.item_cube(a.custid, a.orderitem, a.unitofmeasure) as cube,
                nvl(b.useramt1,0) as useramt1, b.lotrequired, a.inventoryclass, a.invstatus, a.fromlpid, a.facility, a.custid
              from shippingplate a, custitemview b
              where type in ('F','P') and a.custid = b.custid and a.orderitem = b.item
                and lpid in (select lpid from shippingplate
                             start with lpid = in_shlpid
                             connect by prior lpid = parentlpid))
  loop

    -- update the order details
    update orderdtl
    set qtyship = nvl(qtyship, 0) + rec.quantity,
        weightship = nvl(weightship, 0) + rec.weight,
        cubeship = nvl(cubeship, 0) + (rec.quantity * rec.cube),
        amtship = nvl(amtship, 0) + (rec.quantity * rec.useramt1),
        lastuser = in_user,
        lastupdate = sysdate
    where orderid = rec.orderid
        and shipid = rec.shipid
        and item = rec.orderitem
        and nvl(lotnumber, '(none)') = nvl(rec.orderlot, '(none)');

    if (rec.lotrequired = 'P') then
      rec.lotnumber := null;
    end if;
    -- update the asof inventory
    zbill.add_asof_inventory(
           rec.facility,
           rec.custid,
           rec.item,
           rec.lotnumber,
           rec.unitofmeasure,
           trunc(sysdate),
           - rec.quantity,
           - rec.weight,
           'Shipped',
           'SH',
           rec.inventoryclass,
           rec.invstatus,
           rec.orderid,
           rec.shipid,
           rec.fromlpid,
           in_user,
           out_message
       );

    if(out_message <> 'OKAY') then
      zms.log_msg('add_asof_old', rec.facility, rec.custid,
         out_message, 'E', in_user, v_outmsg);
      out_error := 'Y';
      return;
    end if;

  end loop;

  -- update shipping plates to shipped
  update shippingplate
  set status = 'SH',
      lastuser = in_user,
      lastupdate = sysdate
  where status = 'S' and lpid in (select lpid
                                  from shippingplate
                                  start with lpid = in_shlpid
                                  connect by prior lpid = parentlpid);

  -- plates to delete
  for rec in (select lpid, parentlpid, quantity, weight
              from plate
              where lpid in (select distinct fromlpid
                             from shippingplate
                             where type = 'F' and status in ('L','SH')
                             start with lpid = in_shlpid
                             connect by prior lpid = parentlpid)
                and status = 'P')
  loop
    zlp.plate_to_deletedplate(rec.lpid,in_user,'LC',v_outmsg);
    if (rec.parentlpid is not null) then
      zplp.decrease_parent(rec.parentlpid, rec.quantity, rec.weight, in_user, 'LC', v_outmsg);
    end if;
    for rec2 in (select lpid
                 from plate
                 where parentlpid = rec.lpid and status = 'P')
    loop
      zlp.plate_to_deletedplate(rec2.lpid,in_user,'LC',v_outmsg);
    end loop;
  end loop;

  select a.rowid, outmatissueplatemap, b.custid, a.facility
  into v_rowid, v_map, v_custid, v_facility
  from shippingplate a, customer_aux b
  where a.custid = b.custid and lpid = in_shlpid;

  if (v_rowid is not null and v_map is not null) then
    ziem.impexp_request(
      'E', -- reqtype
      null, -- facility
      v_custid, -- custid
      v_map, -- formatid
      null, -- importfilepath
      'NOW', -- when
      null, -- loadno
      null, -- orderid
      null, -- shipid
      v_rowid, --userid
      null, -- tablename
      null,  --columnname
      null, --filtercolumnname
      null, -- company
      null, -- warehouse
      null, -- begindatestr
      null, -- enddatestr
      out_errorno,
      out_message);

    if out_errorno != 0 then
      zms.log_msg('ImpExp', v_facility, v_custid, 'Request Export: ' || out_message,'E', 'IMPEXP', v_message);
    end if;
  elsif (v_map is null) then
    out_message := 'Map not set';
    out_error := 'Y';
    return;
  elsif (v_rowid is null) then
    out_message := 'Plate not found';
    out_error := 'Y';
    return;
  end if;

  out_message := null;
end ship_matissue_lp;

function valid_pass_pick_task(
  v_taskid in tasks.taskid%type)
return number
as
  v_custid customer.custid%type;
  v_tasktype tasks.tasktype%type;
  v_force_pass_picks customer.allowpickpassing%type;
  v_count number;
begin
  select custid, tasktype into v_custid, v_tasktype
  from tasks
  where taskid = v_taskid;

  if (v_tasktype in ('BP')) then
    return 0;
  end if;

  select allowpickpassing into v_force_pass_picks
  from customer
  where custid = v_custid;

  if (nvl(v_force_pass_picks,'N') <> 'F') then
     return 0;
  end if;

  select count(1) into v_count
  from subtasks
  where taskid = v_taskid and nvl(qty,0) > nvl(qtypicked,0);

  if (v_count > 0) then
    return 1;
  end if;

  return 0;
exception
  when others then
    return 0;
end;

function any_force_pass_picks
  (in_user              in varchar2,
   in_facility          in varchar2)
return varchar2
as
  v_custid customer.custid%type;
  v_force_pass_picks customer.allowpickpassing%type;
  v_tasktype tasks.tasktype%type;
  v_count number;
  v_auxmsg varchar2(255);
begin

  for rec in (select distinct taskid
              from shippingplate
              where facility = in_facility and location = in_user and status = 'P'
                and parentlpid is null and totelpid is null
                and nvl(zcord.cons_ordertype(orderid, shipid),'?') not in ('K','V','T','U')
                and zcord.cons_componenttemplate(orderid, shipid) is null
              union
              select distinct taskid
              from plate
              where facility = in_facility and location = in_user and status = 'M'
                and parentlpid is null and type = 'TO'
                and zcord.cons_componenttemplate(orderid, shipid) is null)
  loop
    select custid, tasktype into v_custid, v_tasktype
    from tasks
    where taskid = rec.taskid;

    if (v_tasktype in ('BP')) then
      goto continue_loop;
    end if;

    select allowpickpassing into v_force_pass_picks
    from customer
    where custid = v_custid;

    if (nvl(v_force_pass_picks,'N') <> 'F') then
       goto continue_loop;
    end if;

    select count(1) into v_count
    from subtasks
    where taskid = rec.taskid and nvl(qty,0) > nvl(qtypicked,0);

    if (v_count > 0) then
      return 'Y';
    end if;

    <<continue_loop>>
       null;
  end loop;

  return 'N';

exception
  when others then
    zms.log_msg('PASS_PICKS', in_facility, v_custid, sqlerrm(sqlcode), 'W', in_user, v_auxmsg);
    return 'N';
end any_force_pass_picks;

procedure get_force_pass_pick_locs
  (in_user              in varchar2,
   in_facility          in varchar2,
   out_cursor           out cursor_pnd_locs)
as
  v_location userheader.lastlocation%type;
begin

  open out_cursor for
  select distinct get_pnd_loc_for_task(taskid, facility, fromloc)
  from tasks
  where taskid in (
    select a.taskid
    from shippingplate a, tasks b, waves c
    where a.facility = in_facility and a.location = in_user and a.status = 'P'
      and parentlpid is null and totelpid is null
      and nvl(zcord.cons_ordertype(a.orderid, a.shipid),'?') not in ('K','V','T','U')
      and zcord.cons_componenttemplate(a.orderid, a.shipid) is null
      and valid_pass_pick_task(a.taskid) = 1
      and a.taskid = b.taskid and b.wave = c.wave(+)
      and b.tasktype not in ('BP','SO')
    union
    select a.taskid
    from plate a, tasks b, waves c
    where a.facility = in_facility and a.location = in_user and a.status = 'M'
      and parentlpid is null and a.type = 'TO'
      and zcord.cons_componenttemplate(a.orderid, a.shipid) is null
      and valid_pass_pick_task(a.taskid) = 1
      and a.taskid = b.taskid and b.wave = c.wave(+)
      and b.tasktype not in ('BP','SO'));

end get_force_pass_pick_locs;

procedure get_force_pass_picks
  (in_user              in varchar2,
   in_facility          in varchar2,
   in_pndloc            in varchar2,
   out_cursor           out cursor_pass_picks)
as
begin

  open out_cursor for
  select a.lpid, a.orderid, a.shipid, a.taskid, b.tasktype, nvl(c.mass_manifest,'N') as mass_manifest
  from shippingplate a, tasks b, waves c
  where a.facility = in_facility and a.location = in_user and a.status = 'P'
    and parentlpid is null and totelpid is null
    and nvl(zcord.cons_ordertype(a.orderid, a.shipid),'?') not in ('K','V','T','U')
    and zcord.cons_componenttemplate(a.orderid, a.shipid) is null
    and valid_pass_pick_task(a.taskid) = 1
    and a.taskid = b.taskid and b.wave = c.wave(+)
    and b.tasktype not in ('BP','SO')
    and get_pnd_loc_for_task(b.taskid, b.facility, b.fromloc) = in_pndloc
  union
  select a.lpid, a.orderid, a.shipid, a.taskid, b.tasktype, nvl(c.mass_manifest,'N') as mass_manifest
  from plate a, tasks b, waves c
  where a.facility = in_facility and a.location = in_user and a.status = 'M'
    and parentlpid is null and a.type = 'TO'
    and zcord.cons_componenttemplate(a.orderid, a.shipid) is null
    and valid_pass_pick_task(a.taskid) = 1
    and a.taskid = b.taskid and b.wave = c.wave(+)
    and b.tasktype not in ('BP','SO')
    and get_pnd_loc_for_task(b.taskid, b.facility, b.fromloc) = in_pndloc;

end get_force_pass_picks;

function any_pass_plates_for_task
  (in_taskid            in varchar2)
return number
as
  v_count number := 0;
begin

  select count(1) into v_count
  from shippingplate
  where taskid = in_taskid and status = 'S' and parentlpid is null and totelpid is null and dropseq < 0;

  if (v_count > 0) then
    return v_count;
  end if;

  select count(1) into v_count
  from plate a
  where taskid = in_taskid and status = 'P' and type in ('MP','TO') and parentlpid is null and dropseq < 0;

  return v_count;

end any_pass_plates_for_task;

function get_pnd_loc_for_task
  (in_taskid            in varchar2,
   in_facility          in varchar2,
   in_location          in varchar2)
return varchar2
as
  cursor c_nextloc is
    select facility, fromloc
    from subtasks
    where taskid = in_taskid and nvl(qtypicked,0) < qty
    order by locseq nulls last;

  nl c_nextloc%rowtype := null;
  v_pnd zone.panddlocation%type;
begin

  open c_nextloc;
  fetch c_nextloc into nl;
  if c_nextloc%notfound then
    nl.fromloc := null;
  end if;
  close c_nextloc;

  if (nl.fromloc is not null) then
    begin
      select b.panddlocation into v_pnd
      from location a, zone b
      where a.facility = nl.facility and a.locid = nl.fromloc
        and a.facility = b.facility and a.pickingzone = b.zoneid;
    exception
      when others then
        v_pnd := null;
    end;
  end if;

  if (v_pnd is not null) then
    return v_pnd;
  end if;

  return get_pnd_location(in_facility, in_location);
end;

function get_pnd_location
  ( in_facility          in varchar2,
    in_location          in varchar2)
return varchar2
as
  v_loctype location.loctype%type;
  v_pand_loc zone.panddlocation%type;
  v_section location.section%type;
begin

  if (in_facility is null) then
    raise_application_error(-20001, 'No facility given');
  end if;

  if (in_location is not null) then
    begin
      select a.loctype, a.section, b.panddlocation into v_loctype, v_section, v_pand_loc
      from location a, zone b
      where a.facility = in_facility and a.locid = in_location
        and a.facility = b.facility(+) and a.pickingzone = b.zoneid(+);
    exception
      when others then
        v_loctype := null;
        v_section := null;
        v_pand_loc := null;
    end;
  end if;

  if (v_loctype = 'PND') then
    return in_location;
  elsif (v_pand_loc is not null) then
    return v_pand_loc;
  end if;

  if (v_section is not null) then
    begin
      select locid into v_pand_loc
      from location
      where facility = in_facility and section = v_section
        and loctype = 'PND' and rownum = 1;
    exception
      when others then
        v_pand_loc := null;
    end;
  end if;

  if (v_pand_loc is null) then
    begin
      select locid into v_pand_loc
      from location
      where facility = in_facility and loctype = 'PND'
        and rownum = 1;
    exception
      when others then
        v_pand_loc := null;
    end;
  end if;

  return v_pand_loc;

end get_pnd_location;

procedure get_pass_picks_in_loc
  (in_facility          in varchar2,
   in_location          in varchar2,
   in_equipment         in varchar2,
   out_cursor           out cursor_pass_picks,
   out_message          out varchar2)
as
  v_count number;
begin
  out_message := 'OKAY';

  open out_cursor for
  select lpid, orderid, shipid, taskid, tasktype, mass_manifest
  from
  (
    select zrf.xlate_fromlpid(fromlpid, lpid) as lpid, orderid, shipid,
      taskid, null as tasktype, null as mass_manifest
    from shippingplate a
    where facility = in_facility and location = in_location
      and status = 'S' and parentlpid is null and totelpid is null and dropseq < 0
      and exists (select 1 from tasks where taskid = a.taskid and priority = 8)
      and in_equipment in (select equipid from equipprofequip where profid in
                             (select fromprofile from tasks where taskid = a.taskid))
    union
    select lpid, orderid, shipid, taskid, null as tasktype, null as mass_manifest
    from plate a
    where facility = in_facility and location = in_location
      and status = 'P' and type in ('MP','TO') and parentlpid is null and dropseq < 0
      and exists (select 1 from tasks where taskid = a.taskid and priority = 8)
      and in_equipment in (select equipid from equipprofequip where profid in
                             (select fromprofile from tasks where taskid = a.taskid))
  ) order by orderid, lpid;

exception
  when others then
    out_message := substr(sqlerrm(sqlcode),0,80);
end get_pass_picks_in_loc;

procedure validate_pass_plate
  (in_facility          in varchar2,
   in_location          in varchar2,
   in_lpid              in varchar2,
   in_equipment         in varchar2,
   out_taskid           out number,
   out_orderid          out number,
   out_shipid           out number,
   out_message          out varchar2)
as
  v_found boolean := false;
  v_facility plate.facility%type;
  v_location plate.location%type;
  v_type varchar2(2);
  v_equipprofile tasks.fromprofile%type;
  v_count number;
begin
  out_message := 'OKAY';

  begin
    select facility, location into v_facility, v_location
    from plate
    where lpid = in_lpid;

    v_type := 'PL';
    v_found := true;
  exception
    when others then
      v_found := false;
  end;

  if (not v_found) then
    begin
      select facility, location into v_facility, v_location
      from shippingplate
      where lpid = in_lpid;

      v_type := 'SP';
    exception
      when others then
        out_message := 'Invalid plate';
        return;
    end;
  end if;

  if (v_facility <> in_facility) then
    out_message := 'not in fac';
    return;
  end if;

  if (v_location <> in_location) then
    out_message := 'not in loc';
    return;
  end if;

  if (v_type = 'PL') then
    begin
      select distinct taskid into out_taskid
      from tasks
      where taskid in (select taskid from plate
                       start with lpid = in_lpid
                       connect by prior lpid = parentlpid)
        and priority = '8';
    exception
      when others then
        out_message := 'no task';
        return;
    end;
  elsif (v_type = 'SP') then
    begin
      select distinct taskid into out_taskid
      from tasks
      where taskid in (select taskid from shippingplate
                       start with lpid = in_lpid
                       connect by prior lpid = parentlpid)
        and priority = '8';
    exception
      when others then
        out_message := 'no task';
        return;
    end;
  end if;

  if (nvl(out_taskid,0) = 0) then
    out_message := 'no task';
    return;
  end if;

  select fromprofile into v_equipprofile
  from tasks
  where taskid = out_taskid;

  select count(1) into v_count
  from equipprofequip
  where profid = v_equipprofile and equipid = in_equipment;

  if (v_count = 0) then
    out_message := 'wrong equip';
    return;
  end if;

  select orderid, shipid into out_orderid, out_shipid
  from tasks
  where taskid = out_taskid;

end validate_pass_plate;

procedure cluster_resume_pass_pick
  (in_taskid            in number,
   in_facility          in varchar2,
   in_location          in varchar2,
   in_position          in number,
   in_user              in varchar2,
   io_tasktype          in out varchar2,
   out_message          out varchar2)
as
  v_orderid orderhdr.orderid%type;
  v_shipid orderhdr.shipid%type;
  v_tasktype tasks.tasktype%type;
begin

  out_message := 'OKAY';

  begin
    select orderid, shipid, tasktype into v_orderid, v_shipid, v_tasktype
    from tasks
    where taskid = in_taskid and priority = '8';
  exception
  when others then
    out_message := 'Task not passed';
    return;
  end;

  if (v_tasktype in ('BP')) then
    out_message := 'Invalid tasktype';
    return;
  end if;

  if (io_tasktype is null) then
    io_tasktype := v_tasktype;
  elsif (io_tasktype <> v_tasktype) then
    out_message := 'Mixed tasktypes';
    return;
  end if;

  update tasks
  set curruserid = in_user,
    prevpriority = priority,
    priority = '0',
    clusterposition = in_position
  where taskid = in_taskid;

  if (v_tasktype = 'BP') then
    update plate
    set location = in_user,
        status = 'M',
        lastuser = in_user,
        lastupdate = sysdate,
        dropseq = abs(dropseq)
    where facility = in_facility
      and location = in_location
      and taskid = in_taskid
      and status = 'P'
      and dropseq < 0;
  else
    update shippingplate
    set location = in_user,
        status = 'P',
        lastuser = in_user,
        lastupdate = sysdate,
        dropseq = abs(dropseq)
    where facility||'' = in_facility
      and location||'' = in_location
      and taskid = in_taskid
      and dropseq < 0
      and status = 'S';

    update plate
    set location = in_user,
        status = 'P',
        lastuser = in_user,
        lastupdate = sysdate,
        dropseq = abs(dropseq)
    where lpid in (select fromlpid from shippingplate
                    where facility||'' = in_facility
                      and location||'' = in_user
                      and taskid = in_taskid
                      and dropseq < 0
                      and status = 'S'
                      and type = 'F');

    update plate
    set location = in_user,
        status = 'M',
        lastuser = in_user,
        lastupdate = sysdate,
        dropseq = abs(dropseq)
    where facility = in_facility
      and location = in_location
      and taskid = in_taskid
      and status = 'P'
      and dropseq < 0;
  end if;

exception
  when others then
    out_message := 'Error resuming task';
    return;
end cluster_resume_pass_pick;

function can_equip_pick_subtask
  (in_equipment         in varchar2,
   in_subtask_rowid     in varchar2)
return varchar2
as
  v_subtask subtasks%rowtype;
  v_allowpickpassing customer.allowpickpassing%type;
  v_count number;
begin

  select * into v_subtask
  from subtasks
  where rowid = chartorowid(in_subtask_rowid);

  if (v_subtask.custid is null) then
    return 'Y';
  end if;

  select nvl(allowpickpassing,'N') into v_allowpickpassing
  from customer
  where custid = v_subtask.custid;

  if (v_allowpickpassing <> 'F') then
    return 'Y';
  end if;

  select count(1) into v_count
  from equipprofequip
  where profid = v_subtask.fromprofile and equipid = in_equipment;

  if (v_count > 0) then
    return 'Y';
  end if;

  return 'N';

exception
  when others then
    return 'Y';
end can_equip_pick_subtask;

procedure move_orders_to_picked
  (in_included_rowids IN clob
  ,in_facility IN varchar2
  ,in_userid IN varchar2
  ,out_errorno IN OUT number
  ,out_msg  IN OUT varchar2
  ,out_warning_count IN OUT number
  ,out_error_count IN OUT number
  ,out_picked_count IN OUT number
)
as
  type cur_type is ref cursor;
  l_cur cur_type;
  l_orderid orderhdr.orderid%type;
  l_shipid orderhdr.shipid%type;
  l_custid customer.custid%type;
  l_sql varchar2(4000);
  l_errorno pls_integer;
  l_warning pls_integer;
  l_msg varchar2(255);
  l_userid userheader.nameid%type;
  l_ordertype orderhdr.ordertype%type;
  i pls_integer;
  l_loop_count pls_integer;
  l_rowid_length pls_integer := 18;
  l_log_msg appmsgs.msgtext%type;
  l_wavetemplate customer.wavetemplate%type;

begin

  out_errorno := 0;
  out_msg := 'OKAY';
  out_warning_count := 0;
  out_error_count := 0;
  out_picked_count := 0;

  l_loop_count := length(in_included_rowids) - length(replace(in_included_rowids, ',', ''));

  i := 1;
  while (i <= l_loop_count)
  loop

    l_sql := 'select orderid, shipid, custid, ordertype ' ||
             'from orderhdr ' ||
             'where rowid in (';

    while length(l_sql) < 3975 -- 4000 character limit for open cursor command
    loop
      l_sql := l_sql || '''' || substr(in_included_rowids,((i-1)*l_rowid_length)+i+1,l_rowid_length) || '''';
      i := i + 1;
      if (i <= l_loop_count) and (length(l_sql) < 3975) then
        l_sql := l_sql || ',';
      else
        exit;
      end if;
    end loop;

    l_sql := l_sql || ')';

    open l_cur for l_sql;
    loop

      fetch l_cur into l_orderid, l_shipid, l_custid, l_ordertype;
      exit when l_cur%notfound;

      order_to_picked(l_orderid,l_shipid,in_facility,in_userid,l_warning,l_errorno,l_msg);
      if l_errorno >= 0 then
        commit;
        if l_errorno > 0 then
          out_error_count := out_error_count + 1;
        end if;
        if l_warning != 0 then
          out_warning_count := out_warning_count + 1;
        end if;
        if l_errorno = 0 then
          out_picked_count := out_picked_count + 1;
        end if;
      else
        rollback;
        out_error_count := out_error_count + 1;
      end if;

    end loop;

    close l_cur;

  end loop;

exception when others then
  out_errorno := sqlcode;
  out_msg := sqlerrm;
end move_orders_to_picked;

PROCEDURE order_to_picked
  (in_orderid IN number
  ,in_shipid IN number
  ,in_facility IN varchar2
  ,in_userid IN varchar2
  ,out_warning IN OUT number
  ,out_errorno IN OUT number
  ,out_msg  IN OUT varchar2
)
as
  cursor curOrderHdr(in_orderid IN number, in_shipid IN number) is
    select *
    from orderhdr
    where orderid = in_orderid and shipid = in_shipid;
  oh curOrderHdr%rowtype;

  cursor curSubTasks(in_orderid IN number, in_shipid IN number) is
    select st.rowid, st.facility, st.custid, st.taskid, st.lpid
    from subtasks st
    where orderid = in_orderid
      and shipid = in_shipid
      and priority <> '0'
      and not exists(
        select 1
        from tasks
        where taskid = st.taskid
          and priority = '0');
  st curSubTasks%rowtype;

  cursor curBatchTasks(in_orderid IN number, in_shipid IN number) is
    select bt.rowid, bt.taskid, bt.lpid, bt.tasktype, bt.qty
    from batchtasks bt
    where orderid = in_orderid
      and shipid = in_shipid
      and priority <> '0'
      and not exists(
        select 1
        from subtasks
        where taskid = bt.taskid
          and priority = '0')
      and not exists(
        select 1
        from tasks
        where taskid = bt.taskid
          and priority = '0');
  bt curBatchTasks%rowtype;

  cursor curTaskCount(in_orderid IN number, in_shipid IN number) is
    select count(1) as task_count
    from (
      select 1
      from tasks
      where orderid = in_orderid
        and shipid = in_shipid
      union all
      select 1
      from subtasks
      where orderid = in_orderid
        and shipid = in_shipid
      union all
      select 1
      from batchtasks
      where orderid = in_orderid
        and shipid = in_shipid);
  tc curTaskCount%rowtype;

  v_log_msg varchar2(255);
begin
  out_msg := '';
  out_errorno := 0;
  out_warning := 0;

  open curOrderHdr(in_orderid, in_shipid);
  fetch curOrderHdr into oh;
  if curOrderHdr%notfound then
    close curOrderHdr;
    out_msg := 'Order ' || in_orderid || '-' || in_shipid || ' not found';
    zms.log_msg('FORCEPICKED', in_facility, null, out_msg, 'E', in_userid, v_log_msg);
    out_errorno := 1;
    return;
  end if;
  close curOrderHdr;

  if (oh.orderstatus = '6') then
    out_msg := 'Order ' || in_orderid || '-' || in_shipid || ' already picked';
    zms.log_msg('FORCEPICKED', in_facility, null, out_msg, 'W', in_userid, v_log_msg);
    out_warning := 1;
    return;
  elsif (oh.orderstatus <> '5') then
    out_msg := 'Order ' || in_orderid || '-' || in_shipid || ' not in picking status';
    zms.log_msg('FORCEPICKED', in_facility, null, out_msg, 'E', in_userid, v_log_msg);
    out_errorno := 1;
    return;
  end if;

  if (oh.ordertype <> 'O') then
    out_msg := 'Order ' || in_orderid || '-' || in_shipid || ' not ordertype ''O''';
    zms.log_msg('FORCEPICKED', in_facility, null, out_msg, 'E', in_userid, v_log_msg);
    out_errorno := 1;
    return;
  end if;

  if (oh.fromfacility <> in_facility) then
    out_msg := 'Order ' || in_orderid || '-' || in_shipid || ' not in facility ' || in_facility;
    zms.log_msg('FORCEPICKED', in_facility, null, out_msg, 'E', in_userid, v_log_msg);
    out_errorno := 1;
    return;
  end if;

  for st in curSubTasks(oh.orderid,oh.shipid) loop
    ztk.subtask_no_pick(st.rowid,st.facility,st.custid,st.taskid,st.lpid,in_userid,'Y',out_msg);
    if (out_msg <> 'OKAY') then
      rollback;
      out_msg := 'Order ' || in_orderid || '-' || in_shipid || ' subtask_no_pick => ' || out_msg;
      zms.log_msg('FORCEPICKED', in_facility, null, out_msg, 'E', in_userid, v_log_msg);
      out_errorno := 1;
      return;
    end if;
  end loop;

  for bt in curBatchTasks(oh.orderid,oh.shipid) loop
    delete from batchtasks
    where rowid = bt.rowid;

    delete from subtasks
    where taskid = bt.taskid
      and tasktype = bt.tasktype
      and not exists(
        select 1
        from batchtasks
        where taskid = bt.taskid);

    delete from subtasks
     where taskid = bt.taskid
       and tasktype = bt.tasktype
       and qty <= 0;

    delete from tasks tk
    where taskid = bt.taskid
      and tasktype = bt.tasktype
      and not exists(
        select 1
        from subtasks
        where taskid = bt.taskid);

    update subtasks
    set qty = qty - bt.qty,
      lastuser = in_userid,
      lastupdate = sysdate
    where taskid = bt.taskid
      and lpid = bt.lpid
      and tasktype = bt.tasktype;

    update plate
    set qtytasked =
      (select sum(qty-nvl(qtypicked,0))
         from subtasks
        where lpid = bt.lpid
          and tasktype in ('RP','PK','OP','BP','SO')),
      lastuser = in_userid,
      lastupdate = sysdate
    where lpid = bt.lpid;
  end loop;

  delete from batchtasks bt
  where orderid = oh.orderid
    and shipid = oh.shipid
    and not exists(
      select 1
      from subtasks
      where taskid = bt.taskid);

  delete from subtasks st
  where orderid = oh.orderid
    and shipid = oh.shipid
    and not exists(
      select 1
      from tasks
      where taskid = st.taskid);

  delete from tasks tk
  where orderid = oh.orderid
    and shipid = oh.shipid
    and not exists(
      select 1
      from subtasks
      where taskid = tk.taskid);

  open curTaskCount(oh.orderid,oh.shipid);
  fetch curTaskCount into tc;
  close curTaskCount;

  if (tc.task_count < 1) then
    update orderhdr
    set orderstatus = '6',
      lastuser = in_userid,
      lastupdate = sysdate
    where orderid = oh.orderid and shipid = oh.shipid;

    out_msg := 'OKAY';
  else
    out_msg := 'Unable to update order ' || in_orderid || '-' || in_shipid || ' because tasks exist.';
    zms.log_msg('FORCEPICKED', in_facility, null, out_msg, 'E', in_userid, v_log_msg);
    out_errorno := 1;
    return;
  end if;

exception when others then
  out_errorno := sqlcode;
  out_msg := sqlerrm;
end order_to_picked;

end rfpicking;
/

show errors package body rfpicking;
exit;
