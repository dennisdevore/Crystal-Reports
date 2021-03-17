create or replace package body alps.parentlp as
--
-- $Id$
--


-- Types


type anylptype is record (
   lpid plate.lpid%type,
   quantity plate.quantity%type,
   weight plate.weight%type,
   serialnumber plate.serialnumber%type,
   useritem1 plate.useritem1%type,
   useritem2 plate.useritem2%type,
   useritem3 plate.useritem3%type,
   parentlpid plate.parentlpid%type,
   invstatus plate.invstatus%type,
   inventoryclass plate.inventoryclass%type);
type anylpcur is ref cursor return anylptype;


-- Private procedures


procedure batch_pick_update_order
   (in_subtaskid     in number,   -- f
    in_facility      in varchar2, -- r  s
    in_custid        in varchar2, -- o  u
    in_orderitem     in varchar2, -- m  b
    in_orderlot      in varchar2, --    t
    in_item          in varchar2, --    a
    in_lpid          in varchar2, --    s
    in_fromloc       in varchar2, --    k
    in_actual_lpid   in varchar2, -- lp to be picked
    in_actual_qty    in number,   -- qty picked
    in_userid        in varchar2,
    in_picktotype    in varchar2,
    out_message      OUT varchar2)
is
-- the task creation logic ensures that the subtasks picks
-- correlate to the following batchtasks picks
   cursor curBatchTaskDtl is
      select BT.qty, BT.pickuom, BT.uom, BT.pickqty, BT.orderid, BT.shipid, BT.orderitem, BT.item,
             BT.lotnumber, BT.inventoryclass, BT.invstatus, BT.custid, BT.orderlot, BT.facility,
             BT.loadno, BT.stopno, BT.shipno, BT.rowid, nvl(WV.mass_manifest,'N') as mass_manifest
         from batchtasks BT, waves WV
         where BT.taskid = in_subtaskid
           and BT.custid = in_custid
           and BT.orderitem = in_orderitem
           and nvl(BT.orderlot,'(none)') = nvl(in_orderlot,'(none)')
           and BT.item = in_item
           and nvl(BT.lpid,'(none)') = nvl(in_lpid,'(none)')
           and nvl(BT.fromloc,'(none)') = nvl(in_fromloc,'(none)')
           and WV.wave = BT.wave
         order by BT.qty desc, BT.orderid, BT.shipid;
   bt2 curBatchTaskDtl%rowtype;

   sp ShippingPlate%rowtype;
   qtyActual subtasks.qty%type;
   totPicked subtasks.qty%type;
   odQtyEntered orderdtl.qtyEntered%type;

   cursor curPlate(in_lpid varchar2) is
      select quantity, holdreason, unitofmeasure, serialnumber, lotnumber,
             useritem1, useritem2, useritem3, inventoryclass, manufacturedate,
             expirationdate
         from plate
         where lpid = in_lpid;
   lp curPlate%rowtype;
   msg varchar2(80);
   cursor c_oh(p_orderid number, p_shipid number) is
      select orderstatus, ordertype, parentorderid, parentshipid,
             componenttemplate, loadno, stopno
         from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   oh c_oh%rowtype := null;
   poh c_oh%rowtype := null;
   cursor c_od(p_orderid number, p_shipid number, p_item varchar2, p_lotnumber varchar2) is
      select nvl(qtyorder, 0)-nvl(qtycommit, 0) qtytocommit, uom, priority
         from orderdtl
         where orderid = p_orderid
           and shipid = p_shipid
           and item = p_item
           and nvl(lotnumber, '(none)') = nvl(p_lotnumber, '(none)');
   od c_od%rowtype;
   cursor c_uh(p_nameid varchar2) is
      select equipment
         from userheader
         where nameid = p_nameid;
   uh c_uh%rowtype;

   cursor c_pkzn(p_facility varchar2, p_location varchar2) is
      select ZN.deconsolidation
         from location LO, zone ZN
         where LO.facility = p_facility
           and LO.locid = p_location
           and ZN.facility (+) = LO.facility
           and ZN.zoneid (+) = LO.pickingzone;
   pkzn c_pkzn%rowtype := null;
   l_commitqty commitments.qty%type;
   l_rowid rowid;
begin
   out_message := null;

   totPicked := in_actual_qty;

   open c_uh(in_userid);
   fetch c_uh into uh;
   close c_uh;

   open c_pkzn(in_facility, in_fromloc);
   fetch c_pkzn into pkzn;
   close c_pkzn;
   pkzn.deconsolidation := nvl(pkzn.deconsolidation,'N');

   for bt in curBatchTaskDtl loop
      if totPicked >= bt.qty then
         totPicked := totPicked - bt.qty;
         qtyActual := bt.qty;
      else
         qtyActual := totPicked;
         totPicked := 0;
      end if;

      -- if not using entire pick, reduce pickuom/qty to base
      -- the pickuom will be recalced upon creation of sortation tasks
      if bt.qty != in_actual_qty then
         bt.pickuom := bt.uom;
         bt.pickqty := bt.qty;
      end if;
      if qtyActual != 0 then

         poh := null;
         open c_oh(bt.orderid, bt.shipid);
         fetch c_oh into oh;
         close c_oh;
         if (oh.parentorderid is not null) and (oh.parentshipid is not null) then
            open c_oh(oh.parentorderid, oh.parentshipid);
            fetch c_oh into poh;
            close c_oh;
         end if;

--       add any component commitments not to exceed ordered qty
         if ((oh.ordertype = 'K') and (poh.componenttemplate is not null)) then
            open c_od(oh.parentorderid, oh.parentshipid, bt.item, in_orderlot);
            fetch c_od into od;
            close c_od;

            if (od.qtytocommit > 0) then
               od.qtytocommit := least(od.qtytocommit, qtyActual);

               update commitments
                  set qty = qty + od.qtytocommit,
                      lastuser = in_userid,
                      lastupdate = sysdate
                  where orderid = oh.parentorderid
                    and shipid = oh.parentshipid
                    and orderitem = bt.orderitem
                    and nvl(orderlot, '(none)') = nvl(in_orderlot, '(none)')
                    and item = bt.item
                    and nvl(lotnumber, '(none)') = nvl(in_orderlot, '(none)')
                    and inventoryclass = bt.inventoryclass
                    and invstatus = bt.invstatus
                    and status = 'CM';
               if (sql%rowcount = 0) then
                  insert into commitments
                     (facility, custid, item, inventoryclass, invstatus,
                      status, lotnumber, uom, qty, orderid,
                      shipid, orderitem, priority, lastuser, lastupdate,
                      orderlot)
                  values
                     (in_facility, in_custid, bt.item, bt.inventoryclass, bt.invstatus,
                      'CM', in_orderlot, od.uom, od.qtytocommit, oh.parentorderid,
                      oh.parentshipid, bt.orderitem, od.priority, in_userid, sysdate,
                      in_orderlot);
               end if;
            end if;
         end if;

         if bt.mass_manifest = 'Y' then
            update commitments
               set qty = qty - qtyActual,
                   lastuser = in_userid,
                   lastupdate = sysdate
               where orderid = bt.orderid
                 and shipid = bt.shipid
                 and orderitem = bt.orderitem
                 and nvl(orderlot, '(none)') = nvl(in_orderlot, '(none)')
                 and item = bt.item
                 and nvl(lotnumber, '(none)') = nvl(in_orderlot, '(none)')
                 and inventoryclass = bt.inventoryclass
                 and invstatus = bt.invstatus
                 and status = 'CM'
               returning qty, rowid into l_commitqty, l_rowid;
            if (sql%rowcount != 0) and (l_commitqty <= 0) then
               delete commitments
                  where rowid = l_rowid;
            end if;
         end if;

         update orderdtl
            set --qtypick = nvl(qtyPick, 0) + qtyActual,
                --weightpick = nvl(weightpick, 0)
                --     + (zcwt.lp_item_weight(in_actual_lpid, bt.custid, bt.item, bt.uom) * qtyActual),
                --cubepick = nvl(cubepick, 0)
                --     + (zci.item_cube(bt.custid, bt.item, bt.uom) * qtyActual),
                --amtpick = nvl(amtpick, 0) + (zci.item_amt(bt.custid, bt.orderid, bt.shipid, bt.item, bt.orderlot) * qtyActual),  --prn 25133
                qty2sort = nvl(qty2sort, 0) + qtyActual,
                weight2sort = nvl(weight2sort, 0)
                     + (zcwt.lp_item_weight(in_actual_lpid, bt.custid, bt.item, bt.uom) * qtyActual),
                cube2sort = nvl(cube2sort, 0)
                     + (zci.item_cube(bt.custid, bt.item, bt.uom) * qtyActual),
                amt2sort = nvl(amt2sort, 0) + (zci.item_amt(bt.custid, bt.orderid, bt.shipid, bt.item, bt.orderlot) * qtyActual) --prn 25133
            where orderid = bt.orderid
              and shipid = bt.shipid
              and item = bt.orderitem
              and nvl(lotnumber,'(none)') = nvl(bt.orderlot,'(none)')
            returning qtyEntered into odQtyEntered;

         update orderhdr
            set orderstatus = zrf.ORD_PICKING,
                lastuser = in_userid,
                lastupdate = sysdate
          where orderid = bt.orderid
            and shipid = bt.shipid
            and orderstatus < zrf.ORD_PICKING;
              
         open curPlate(in_actual_lpid);
         fetch curPlate into lp;
         close curPlate;
         if lp.quantity = bt.qty then
            sp.type := 'F';
         else
            sp.type := 'P';
         end if;

         zsp.get_next_shippinglpid(sp.lpid, msg);
         if (msg is not null) then
            out_message := msg;
            return;
         end if;
         insert into shippingplate
            (lpid, item, custid, facility, location, status, holdreason,
             unitofmeasure, quantity, type, fromlpid, serialnumber,
             lotnumber, parentlpid, useritem1, useritem2, useritem3,
             lastuser, lastupdate, invstatus, qtyentered, orderitem,
             uomentered, inventoryclass, loadno, stopno, shipno,
             orderid, shipid,
             weight,
             ucc128, labelformat, taskid, orderlot, pickuom, pickqty, cartonseq,
             manufacturedate, expirationdate)
         values
            (sp.lpid, bt.item, bt.custid, bt.facility, null, 'U', lp.holdreason,
             lp.unitofmeasure, qtyActual, sp.type, in_actual_lpid, lp.serialnumber,
             lp.lotnumber, null, lp.useritem1, lp.useritem2, lp.useritem3,
             in_userid, sysdate, bt.invstatus, odQtyEntered, bt.orderitem,
             lp.unitofmeasure, lp.inventoryclass, bt.loadno, bt.stopno, bt.shipno,
             bt.orderid, bt.shipid,
             zcwt.lp_item_weight(in_actual_lpid, bt.custid, bt.item, bt.pickuom) * bt.pickqty,
             null, null, 0, in_orderlot, bt.pickuom, bt.pickqty, null,
             lp.manufacturedate, lp.expirationdate);

         insert into userhistory
            (nameid, begtime, endtime, facility, custid,
             equipment, event, units, etc, orderid,
             shipid, location, lpid, item, uom,
             baseuom, baseunits,
             cube,
             weight)
         values
            (in_userid, sysdate, sysdate, bt.facility, bt.custid,
             uh.equipment, 'BADT', bt.pickqty, null, bt.orderid,
             bt.shipid, in_fromloc, in_lpid, bt.item, bt.pickuom,
             lp.unitofmeasure, qtyActual,
             bt.pickqty*zci.item_cube(bt.custid, bt.item, bt.pickuom),
             bt.pickqty*zcwt.lp_item_weight(in_actual_lpid, bt.custid, bt.item, bt.pickuom));

      end if;

      -- the deletion/update of the batch task must occur within the same trans
      -- as the insert of the shippingplate record because of wave release
      -- requirements (as in how to figure out how many picks remain when
      -- shortages occur)
      if qtyActual = bt.qty then
         delete from batchtasks
            where rowid = bt.rowid;
      else
         update batchtasks
            set qty = bt.qty - qtyActual,
                pickuom = bt.uom,
                pickqty = bt.qty - qtyActual
            where rowid = bt.rowid;
      end if;
   end loop;

   --log a msg if entire pick quantity was not applied
   if (totPicked != 0) and (pkzn.deconsolidation = 'N') then
      zms.log_msg('BATCHPICK', in_facility, in_custid,
         'Batch pick not applied ' || in_item || ' ' || totPicked,
         'E', in_userid, msg);
      if (msg != 'OKAY') then
         out_message := msg;
      end if;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end batch_pick_update_order;


-- Public functions


function type_pa_lpid
   (in_lpid   in varchar2,
    in_custid in varchar2,
    in_item   in varchar2,
    in_lotno  in varchar2)
return varchar2
is
   cursor c_lp(p_lpid varchar2) is
      select type
         from plate
         where lpid = p_lpid;
   lp c_lp%rowtype;
   cursor c_kids(p_lpid varchar2, p_custid varchar2, p_item varchar2, p_lotno varchar2) is
      select lpid
         from plate
         where custid = p_custid
           and item = p_item
           and nvl(lotnumber, '(none)') = nvl(p_lotno, '(none)')
           and type = 'PA'
         start with lpid = p_lpid
         connect by prior lpid = parentlpid;
   kids c_kids%rowtype;
   l_lpid plate.lpid%type := in_lpid;
begin
   open c_lp(in_lpid);
   fetch c_lp into lp;
   if c_lp%found and (lp.type = 'MP') then
      open c_kids(in_lpid, in_custid, in_item, in_lotno);
      fetch c_kids into kids;
      if c_kids%found then
         l_lpid := kids.lpid;
      end if;
      close c_kids;
   end if;
   close c_lp;

   return l_lpid;

exception when others then
   return in_lpid;
end type_pa_lpid;


-- Public procedures


procedure build_tote_from_shippingplate
   (in_tlpid    in varchar2,
    in_slpid    in varchar2,
    in_user     in varchar2,
    in_tasktype in varchar2,
    in_taskid   in number,
    in_dropseq  in number,
    in_pickloc  in varchar2,
    out_error   out varchar2,
    out_message out varchar2)
is
   err varchar2(1);
   msg varchar2(80);
   addtlp boolean := true;
   tlpid plate.lpid%type;
   cursor c_lp(p_lpid varchar2) is
      select type, status, orderid, shipid, location, loadno, stopno, shipno,
             custid, item, quantity, parentlpid, lotnumber, unitofmeasure, weight,
             invstatus, inventoryclass
         from plate
         where lpid = p_lpid;
   tp c_lp%rowtype := null;
   fp c_lp%rowtype;
   cursor c_slp is
      select facility, location, quantity, weight, type, fromlpid, item,
             unitofmeasure, orderid, shipid, custid, lotnumber, loadno,
             stopno, shipno
         from shippingplate
         where lpid = in_slpid;
   sp c_slp%rowtype;
   c_any_lp anylpcur;
   l anylptype;
   cursor c_itemview(p_custid varchar2, p_item varchar2) is
     select serialrequired, serialasncapture, user1required, user1asncapture,
            user2required, user2asncapture, user3required, user3asncapture,
            track_picked_pf_lps
      from custitemview
      where custid = p_custid
        and item = p_item;
   itv c_itemview%rowtype;
   cloneid plate.lpid%type;
	pa_cordid waves.wave%type;
   ch_cordid waves.wave%type;
   l_picked_weight number;
   l_iteration integer;
   l_quantity plate.quantity%type;
   l_weight plate.weight%type;
begin
   out_error := 'N';
   out_message := null;

   if (in_tlpid is null) then
      zrf.get_next_lpid(tlpid, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;
   else
      open c_lp(in_tlpid);
      fetch c_lp into tp;
      addtlp := c_lp%notfound;
      close c_lp;
      if ((not addtlp) and (tp.type != 'TO')) then
         out_message := 'LP not a Tote';
         return;
      end if;
      tlpid := in_tlpid;
   end if;

   open c_slp;
   fetch c_slp into sp;
   close c_slp;

   open c_itemview(sp.custid, sp.item);
   fetch c_itemview into itv;
  	close c_itemview;

   if nvl(itv.track_picked_pf_lps,'N') = 'Y' and sp.fromlpid is null then
      l_quantity := 0;
      l_weight := 0;
   else
      l_quantity := sp.quantity;
      l_weight := sp.weight;
   end if;

-- build or update the parent
   if (addtlp) then                          -- build new
      insert into plate
         (lpid, facility, location, status, quantity, type,
          creationdate, lastoperator, lasttask, lastuser, lastupdate,
          weight,
          taskid, dropseq, orderid, shipid, loadno, stopno,
          shipno, custid, item)
      values
         (tlpid, sp.facility, sp.location, 'M', l_quantity, 'TO',
          sysdate, in_user, in_tasktype, in_user, sysdate,
          l_weight,
          in_taskid, in_dropseq, sp.orderid, sp.shipid, sp.loadno, sp.stopno,
          sp.shipno, sp.custid, sp.item);
      tp.orderid := sp.orderid;
      tp.shipid := sp.shipid;
   elsif (tp.status = 'A') then              -- reuse existing
      update plate
         set facility = sp.facility,
             location = sp.location,
             status = 'M',
             quantity = l_quantity,
             lastoperator = in_user,
             lasttask = in_tasktype,
             lastuser = in_user,
             lastupdate = sysdate,
             weight = l_weight,
             taskid = in_taskid,
             dropseq = in_dropseq,
             orderid = sp.orderid,
             shipid = sp.shipid,
             loadno = sp.loadno,
             stopno = sp.stopno,
             shipno = sp.shipno,
             custid = sp.custid,
             item = sp.item
         where lpid = tlpid;
      tp.orderid := sp.orderid;
      tp.shipid := sp.shipid;
   elsif ((tp.status != 'M') or (tp.location != in_user)) then
      out_message := 'Tote not avail';
      return;
   else                                      -- add to existing
      if (nvl(sp.custid, '(none)') != nvl(tp.custid, '(none)')) then
         tp.custid := null;
         tp.item := null;
      elsif (nvl(sp.item, '(none)') != nvl(tp.item, '(none)')) then
         tp.item := null;
      end if;

      if (nvl(sp.orderid, 0) != nvl(tp.orderid, 0)) then
			pa_cordid := zcord.cons_orderid(tp.orderid, tp.shipid);
			ch_cordid := zcord.cons_orderid(sp.orderid, sp.shipid);
         if (pa_cordid = ch_cordid) and (pa_cordid != 0) then
            tp.orderid := pa_cordid;
			else
            tp.orderid := 0;
			end if;
         tp.shipid := 0;
      elsif (nvl(sp.shipid, 0) != nvl(tp.shipid, 0)) then
         tp.shipid := 0;
      end if;

      if (nvl(sp.loadno, 0) != nvl(tp.loadno, 0)) then
         tp.loadno := 0;
         tp.stopno := 0;
         tp.shipno := 0;
      elsif (nvl(sp.stopno, 0) != nvl(tp.stopno, 0)) then
         tp.stopno := 0;
         tp.shipno := 0;
      elsif (nvl(sp.shipno, 0) != nvl(tp.shipno, 0)) then
         tp.shipno := 0;
      end if;

      update plate
         set quantity = nvl(quantity, 0) + nvl(l_quantity, 0),
             lastoperator = in_user,
             lasttask = in_tasktype,
             lastuser = in_user,
             lastupdate = sysdate,
             weight = nvl(weight, 0) + l_weight,
             orderid = tp.orderid,
             shipid = tp.shipid,
             loadno = tp.loadno,
             stopno = tp.stopno,
             shipno = tp.shipno,
             custid = tp.custid,
             item = tp.item
         where lpid = tlpid;
   end if;

   if (sp.fromlpid is null) then
      fp.type := '?';
   else
      open c_lp(sp.fromlpid);
      fetch c_lp into fp;
      close c_lp;

      if (sp.quantity > fp.quantity) then
         out_message := 'Qty not avail';
         return;
      end if;

      if (fp.type = 'PA') then
         if ((sp.type = 'F') or (sp.quantity = fp.quantity)) then
--          full (or all) pick, use the existing plate

            if (fp.parentlpid is not null) then
               zplp.detach_child_plate(fp.parentlpid, sp.fromlpid, fp.location, null,
                     null, 'M', in_user, in_tasktype, msg);
               if (msg is not null) then
                  out_error := 'Y';
                  out_message := msg;
                  return;
               end if;
            end if;

            update plate
               set parentlpid = tlpid,
                   status = 'M',
                   location = sp.location,
                   lastoperator = in_user,
                   lasttask = in_tasktype,
                   lastuser = in_user,
                   lastupdate = sysdate,
                   taskid = in_taskid,
                   fromshippinglpid = in_slpid
               where lpid = sp.fromlpid;

            zcwt.process_weight_difference(sp.fromlpid, sp.weight, fp.weight, in_user, 'F', msg);
            if (msg is not null) then
               out_error := 'Y';
               out_message := msg;
            end if;

            return;
         end if;

--       build new plate
         zplp.clone_lp(sp.fromlpid, sp.location, 'M', sp.quantity, sp.weight, in_user,
               in_tasktype, tlpid, in_taskid, in_slpid, 0, cloneid, msg);
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
            return;
         end if;

--       decrease existing plate
         zrf.decrease_lp(sp.fromlpid, fp.custid, fp.item, sp.quantity, fp.lotnumber,
               fp.unitofmeasure, in_user, in_tasktype, fp.invstatus, fp.inventoryclass,
               err, msg);
         if (err = 'N') and (msg is null) then
            zcwt.process_weight_difference(sp.fromlpid, sp.weight, fp.weight, in_user, 'P', msg);
            if msg is not null then
               err := 'Y';
            end if;
         end if;
         if (msg is not null) then
            out_error := err;
            out_message := msg;
         end if;
         return;
      end if;
   end if;

-- update 'required' plates containing item

   if (fp.type = '?') then
      if (sp.lotnumber is null) then
         open c_any_lp for
            select lpid, quantity, weight, serialnumber, useritem1, useritem2, useritem3,
                   parentlpid, invstatus, inventoryclass
               from plate
               where facility = sp.facility
                 and location = in_pickloc
                 and custid = sp.custid
                 and item = sp.item
                 and unitofmeasure = sp.unitofmeasure
                 and type = 'PA'
                 and status = 'A'
               order by manufacturedate, creationdate;
      else
         open c_any_lp for
            select lpid, quantity, weight, serialnumber, useritem1, useritem2, useritem3,
                   parentlpid, invstatus, inventoryclass
               from plate
               where facility = sp.facility
                 and location = in_pickloc
                 and custid = sp.custid
                 and item = sp.item
                 and lotnumber = sp.lotnumber
                 and unitofmeasure = sp.unitofmeasure
                 and type = 'PA'
                 and status = 'A'
               order by manufacturedate, creationdate;
      end if;
   else
      if (sp.lotnumber is null) then
         open c_any_lp for
            select lpid, quantity, weight, serialnumber, useritem1, useritem2, useritem3,
                   parentlpid, invstatus, inventoryclass
               from plate
               where custid = sp.custid
                 and item = sp.item
                 and unitofmeasure = sp.unitofmeasure
                 and type = 'PA'
               start with lpid = sp.fromlpid
               connect by prior lpid = parentlpid
               order by manufacturedate, creationdate;
      else
         open c_any_lp for
            select lpid, quantity, weight, serialnumber, useritem1, useritem2, useritem3,
                   parentlpid, invstatus, inventoryclass
               from plate
               where custid = sp.custid
                 and item = sp.item
                 and lotnumber = sp.lotnumber
                 and unitofmeasure = sp.unitofmeasure
                 and type = 'PA'
               start with lpid = sp.fromlpid
               connect by prior lpid = parentlpid
               order by manufacturedate, creationdate;
      end if;
   end if;

   l_iteration := 1;
   loop
      fetch c_any_lp into l;
      exit when c_any_lp%notfound;

      if ((l.serialnumber is not null
            and itv.serialrequired != 'Y' and itv.serialasncapture = 'Y')
      or  (l.useritem1 is not null
            and itv.user1required != 'Y' and itv.user1asncapture = 'Y')
      or  (l.useritem2 is not null
            and itv.user2required != 'Y' and itv.user2asncapture = 'Y')
      or  (l.useritem3 is not null
            and itv.user3required != 'Y' and itv.user3asncapture = 'Y')
      or  (zrf.any_tasks_for_lp(l.lpid, l.parentlpid) and (fp.type = '?'))) then
         goto continue_loop;
      end if;

      if nvl(itv.track_picked_pf_lps,'N') = 'Y' and fp.type = '?' then
         if l.quantity > sp.quantity then
--          only need part of plate
            l_quantity := l.quantity - sp.quantity;
            l_weight := l_quantity * (l.weight/l.quantity);
            zplp.clone_lp(l.lpid, sp.location, 'M', l_quantity, l_weight,
                  in_user, in_tasktype, tlpid, in_taskid, in_slpid, 0, cloneid, msg);
            if msg is null then
               zrf.decrease_lp(l.lpid, sp.custid, sp.item, l_quantity,
                     sp.lotnumber, sp.unitofmeasure, in_user, in_tasktype,
                     l.invstatus, l.inventoryclass, err, msg);
            end if;
         else
            cloneid := l.lpid;
         end if;

         if msg is null then
            attach_child_plate(tlpid, cloneid, sp.location, 'M', in_user, msg);
         end if;
         if msg is not null then
            out_error := 'Y';
            out_message := msg;
            close c_any_lp;
            return;
         end if;
      else
         if (l_iteration = 1) then
--          use 1st plate to build new plate
            zplp.clone_lp(l.lpid, sp.location, 'M', sp.quantity, sp.weight, in_user,
                  in_tasktype, tlpid, in_taskid, in_slpid, 0, cloneid, msg);
            if (msg is not null) then
               out_error := 'Y';
               out_message := msg;
               close c_any_lp;
               return;
            end if;
         end if;

         zrf.decrease_lp(l.lpid, sp.custid, sp.item, least(l.quantity, sp.quantity),
               sp.lotnumber, sp.unitofmeasure, in_user, in_tasktype, l.invstatus,
               l.inventoryclass, err, msg);
         if ((err != 'N') or (msg is not null)) then
            out_error := err;
            out_message := msg;
            close c_any_lp;
            return;
         end if;
      end if;

      sp.quantity := sp.quantity - least(l.quantity, sp.quantity);

      if sp.quantity = 0 then
         l_picked_weight := sp.weight;       /* use whatever weight is left */
      else
         l_picked_weight := least(l.weight, sp.weight);
      end if;

      zcwt.process_weight_difference(l.lpid, l_picked_weight, l.weight, in_user, 'P', msg);
      if msg is not null then
         out_error := 'Y';
         out_message := msg;
         close c_any_lp;
         rollback;
         return;
      end if;
      sp.weight := sp.weight - l_picked_weight;

      l_iteration := l_iteration + 1;
      exit when (sp.quantity = 0);
   <<continue_loop>>
      null;
   end loop;
   close c_any_lp;
   if (sp.quantity != 0) then
      out_message := 'Qty not avail';
   elsif nvl(itv.track_picked_pf_lps,'N') = 'Y' and fp.type = '?' then
      update plate
         set orderid = tp.orderid,
             shipid = tp.shipid
         where lpid = tlpid;
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end build_tote_from_shippingplate;


procedure build_batchpick_parentlp
   (in_plpid           in varchar2,
    in_picktotype      in varchar2,
    in_facility        in varchar2,
    in_location        in varchar2,
    in_quantity        in varchar2,
    in_user            in varchar2,
    in_taskid          in number,
    in_dropseq         in number,
    in_custid          in varchar2,
    in_item            in varchar2,
    in_lotno           in varchar2,
    in_fromlpid        in varchar2,
    in_picktype        in varchar2,
    in_pickloc         in varchar2,
    in_uom             in varchar2,
    in_orderitem       in varchar2,
    in_orderlot        in varchar2,
    in_plannedlp       in varchar2,
    in_fromloc         in varchar2,
    in_subtask_rowid   in varchar2,
    out_error          out varchar2,
    out_message        out varchar2)
is
   err varchar2(1);
   msg varchar2(80);
   addplp boolean := true;
   cursor c_lp(p_lpid varchar2) is
      select type, status, orderid, shipid, location, parentlpid, quantity,
             custid, item, lotnumber, weight, invstatus, inventoryclass
         from plate
         where lpid = p_lpid;
   pp c_lp%rowtype;
   fp c_lp%rowtype;
   c_any_lp anylpcur;
   l anylptype;
   cursor c_itemview is
     select serialrequired, serialasncapture, user1required, user1asncapture,
            user2required, user2asncapture, user3required, user3asncapture,
            track_picked_pf_lps
      from custitemview
      where custid = in_custid
        and item = in_item;
   itv c_itemview%rowtype;
   cursor c_tlp_nolot is
      select lpid
         from plate
         where facility = in_facility
           and location = in_pickloc
           and custid = in_custid
           and item = in_item
           and unitofmeasure = in_uom
           and type = 'PA'
           and status = 'A';
   cursor c_tlp_lot is
      select lpid
         from plate
         where facility = in_facility
           and location = in_pickloc
           and custid = in_custid
           and item = in_item
           and lotnumber = in_lotno
           and unitofmeasure = in_uom
           and type = 'PA'
           and status = 'A';
   tlp c_tlp_nolot%rowtype;
   tlpfound boolean;
   workqty number := in_quantity;
   pickedlp plate.lpid%type := in_fromlpid;
   l_weight plate.weight%type;
   l_iteration integer;
   l_clpid plate.lpid%type;
   l_quantity plate.quantity%type;
begin
   out_error := 'N';
   out_message := null;

   if (in_plpid is null) then
--    must have been a full pick
      open c_lp(in_fromlpid);
      fetch c_lp into fp;
      close c_lp;

      if (in_quantity > fp.quantity) then
         out_message := 'Qty not avail';
         return;
      end if;

      update plate
         set status = 'M',
             location = in_location,
             lastoperator = in_user,
             lasttask = 'BP',
             lastuser = in_user,
             lastupdate = sysdate,
             taskid = in_taskid
         where lpid in (select lpid from plate
                           start with lpid = in_fromlpid
                           connect by prior lpid = parentlpid);
      if (fp.parentlpid is not null) then
         zplp.detach_child_plate(fp.parentlpid, in_fromlpid, in_location, null,
               null, 'M', in_user, 'BP', msg);
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
            return;
         end if;
      end if;

      update subtasks
         set shippinglpid = in_fromlpid
         where rowid = chartorowid(in_subtask_rowid);

      batch_pick_update_order(in_taskid, in_facility, in_custid, in_orderitem,
            in_orderlot, in_item, in_plannedlp, in_fromloc, in_fromlpid,
            in_quantity, in_user, in_picktotype, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
      end if;
      return;
   end if;

   open c_itemview;
   fetch c_itemview into itv;
   close c_itemview;

   open c_lp(in_plpid);
   fetch c_lp into pp;
   addplp := c_lp%notfound;
   close c_lp;
   l_weight := in_quantity * zci.item_weight(in_custid, in_item, in_uom);

   if (in_picktotype = 'TOTE') then
      if nvl(itv.track_picked_pf_lps,'N') = 'Y' and in_fromlpid is null then
         pickedlp := in_plpid;
         l_quantity := 0;
         l_weight := 0;
      else
         l_quantity := in_quantity;
      end if;
      if (addplp) then                          -- build new tote
         insert into plate
            (lpid, facility, location, status, quantity, type,
             creationdate, lastoperator, lasttask, lastuser, lastupdate, weight,
             taskid, dropseq)
         values
            (in_plpid, in_facility, in_location, 'M', l_quantity, 'TO',
             sysdate, in_user, 'BP', in_user, sysdate, l_weight,
             in_taskid, in_dropseq);
      else
         if (pp.type != 'TO') then
            out_message := 'LP not a Tote';
            return;
         end if;

         if (pp.status = 'A') then              -- reuse existing tote
            update plate
               set facility = in_facility,
                   location = in_location,
                   status = 'M',
                   quantity = l_quantity,
                   lastoperator = in_user,
                   lasttask = 'BP',
                   lastuser = in_user,
                   lastupdate = sysdate,
                   weight = l_weight,
                   taskid = in_taskid,
                   dropseq = in_dropseq
               where lpid = in_plpid;
         elsif ((pp.status != 'M') or (pp.location != in_user)) then
            out_message := 'Not available';
            return;
         else                                      -- add to existing tote
            update plate
               set quantity = nvl(quantity, 0) + l_quantity,
                   lastoperator = in_user,
                   lasttask = 'BP',
                   lastuser = in_user,
                   lastupdate = sysdate,
                   weight = nvl(weight, 0) + l_weight
               where lpid = in_plpid;
         end if;
      end if;
   else
      pickedlp := in_plpid;
      if (addplp) then                          -- build new plate
         if (in_fromlpid is not null) then      -- use from as template
            rfbp.dupe_lp(type_pa_lpid(in_fromlpid, in_custid, in_item, in_lotno),
                  in_plpid, in_location, 'M', in_quantity, in_user, null, 'BP', in_taskid, msg);
            if (msg is not null) then
               out_error := 'Y';
               out_message := msg;
               return;
            end if;
         else                                   -- find LP in pickloc and use it
            if (in_lotno is null) then
               open c_tlp_nolot;
               fetch c_tlp_nolot into tlp;
               tlpfound := c_tlp_nolot%found;
               close c_tlp_nolot;
            else
               open c_tlp_lot;
               fetch c_tlp_lot into tlp;
               tlpfound := c_tlp_lot%found;
               close c_tlp_lot;
            end if;

            if (not tlpfound) then
               out_message := 'Qty not avail';
               return;
            end if;

            rfbp.dupe_lp(tlp.lpid, in_plpid, in_location, 'M', in_quantity, in_user,
                  null, 'BP', in_taskid, msg);
            if (msg is not null) then
               out_error := 'Y';
               out_message := msg;
               return;
            end if;
         end if;
      else
         if nvl(itv.track_picked_pf_lps,'N') = 'N' and pp.type != 'PA' then
            out_message := 'Not single LP';
            return;
         end if;
         if (pp.custid != in_custid) then
            out_message := 'Wrong customer';
            return;
         end if;
         if (pp.item != in_item) then
            out_message := 'Wrong item';
            return;
         end if;
         if (nvl(in_lotno, '(none)') != nvl(pp.lotnumber, '(none)')) then
            out_message := 'Wrong lot';
            return;
         end if;
         if ((pp.status != 'M') or (pp.location != in_user)) then
            out_message := 'Not yours';
            return;
         end if;

         if nvl(itv.track_picked_pf_lps,'N') = 'N' then
            update plate                           -- add to existing LP
               set quantity = nvl(quantity, 0) + in_quantity,
                   lastoperator = in_user,
                   lasttask = 'BP',
                   lastuser = in_user,
                   lastupdate = sysdate,
                   weight = nvl(weight, 0) + l_weight
               where lpid = in_plpid;
         end if;
      end if;
   end if;

   update subtasks
      set shippinglpid = in_plpid
      where rowid = chartorowid(in_subtask_rowid);

   if (in_fromlpid is null) then
      fp.type := '?';
   else
      open c_lp(in_fromlpid);
      fetch c_lp into fp;
      close c_lp;

      if (in_quantity > fp.quantity) then
         out_message := 'Qty not avail';
         return;
      end if;

     	l_weight := in_quantity * (fp.weight/fp.quantity);
      if (fp.type = 'PA') then
         if (in_picktotype != 'TOTE') then
            zrf.decrease_lp(in_fromlpid, in_custid, in_item, in_quantity, in_lotno,
                  in_uom, in_user, 'BP', fp.invstatus, fp.inventoryclass, err, msg);
            if (msg is not null) then
               out_error := err;
               out_message := msg;
               return;
            end if;
         else
            if ((in_picktype = 'F') or (in_quantity = fp.quantity)) then
--             full (or all) pick, use the existing plate

               if (fp.parentlpid is not null) then
                  zplp.detach_child_plate(fp.parentlpid, in_fromlpid, in_location, null,
                        null, 'M', in_user, 'BP', msg);
                  if (msg is not null) then
                     out_error := 'Y';
                     out_message := msg;
                     return;
                  end if;
               end if;

               update plate
                  set parentlpid = in_plpid,
                      status = 'M',
                      location = in_location,
                      lastoperator = in_user,
                      lasttask = 'BP',
                      lastuser = in_user,
                      lastupdate = sysdate,
                      taskid = in_taskid
                  where lpid = in_fromlpid;
            else
--             build new plate
               zplp.clone_lp(in_fromlpid, in_location, 'M', in_quantity, l_weight,
                     in_user, 'BP', in_plpid, in_taskid, null, 0, pickedlp, msg);
               if (msg is not null) then
                  out_error := 'Y';
                  out_message := msg;
                  return;
               end if;
               zrf.decrease_lp(in_fromlpid, in_custid, in_item, in_quantity, in_lotno,
                     in_uom, in_user, 'BP', fp.invstatus, fp.inventoryclass, err, msg);
               if (msg is not null) then
                  out_error := err;
                  out_message := msg;
                  return;
               end if;
            end if;
         end if;
         batch_pick_update_order(in_taskid, in_facility, in_custid, in_orderitem,
               in_orderlot, in_item, in_plannedlp, in_fromloc, pickedlp, in_quantity,
               in_user, in_picktotype, msg);
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
         end if;
         return;
      end if;
   end if;

-- update 'required' plates with item

   if (fp.type = '?') then
      if (in_lotno is null) then
         open c_any_lp for
            select lpid, quantity, weight, serialnumber, useritem1, useritem2, useritem3,
                   parentlpid, invstatus, inventoryclass
               from plate
               where facility = in_facility
                 and location = in_pickloc
                 and custid = in_custid
                 and item = in_item
                 and unitofmeasure = in_uom
                 and type = 'PA'
                 and status = 'A'
               order by manufacturedate, creationdate;
      else
         open c_any_lp for
            select lpid, quantity, weight, serialnumber, useritem1, useritem2, useritem3,
                   parentlpid, invstatus, inventoryclass
               from plate
               where facility = in_facility
                 and location = in_pickloc
                 and custid = in_custid
                 and item = in_item
                 and lotnumber = in_lotno
                 and unitofmeasure = in_uom
                 and type = 'PA'
                 and status = 'A'
               order by manufacturedate, creationdate;
      end if;
   else
      if (in_lotno is null) then
         open c_any_lp for
            select lpid, quantity, weight, serialnumber, useritem1, useritem2, useritem3,
                   parentlpid, invstatus, inventoryclass
               from plate
               where custid = in_custid
                 and item = in_item
                 and unitofmeasure = in_uom
                 and type = 'PA'
               start with lpid = in_fromlpid
               connect by prior lpid = parentlpid
               order by manufacturedate, creationdate;
      else
         open c_any_lp for
            select lpid, quantity, weight, serialnumber, useritem1, useritem2, useritem3,
                   parentlpid, invstatus, inventoryclass
               from plate
               where custid = in_custid
                 and item = in_item
                 and lotnumber = in_lotno
                 and unitofmeasure = in_uom
                 and type = 'PA'
               start with lpid = in_fromlpid
               connect by prior lpid = parentlpid
               order by manufacturedate, creationdate;
      end if;
   end if;

   l_iteration := 1;
   loop
      fetch c_any_lp into l;
      exit when c_any_lp%notfound;

      if ((l.serialnumber is not null
            and itv.serialrequired != 'Y' and itv.serialasncapture = 'Y')
      or  (l.useritem1 is not null
            and itv.user1required != 'Y' and itv.user1asncapture = 'Y')
      or  (l.useritem2 is not null
            and itv.user2required != 'Y' and itv.user2asncapture = 'Y')
      or  (l.useritem3 is not null
            and itv.user3required != 'Y' and itv.user3asncapture = 'Y')
      or  (zrf.any_tasks_for_lp(l.lpid, l.parentlpid) and (fp.type = '?'))) then
         goto continue_loop;
      end if;

      if nvl(itv.track_picked_pf_lps,'N') = 'Y' then
         if (in_picktotype != 'TOTE')
         and (fp.type = '?')
         and (l_iteration = 1) then
               update plate
                  set type = 'MP',
                     quantity = 0,
                     weight = 0
                  where lpid = in_plpid;
         end if;

         msg := null;
         if l.quantity > workqty then
--          only need part of plate
            l_quantity := l.quantity - workqty;
            l_weight := l_quantity * (l.weight/l.quantity);
            zplp.clone_lp(l.lpid, in_location, 'M', l_quantity, l_weight,
                  in_user, 'BP', null, in_taskid, null, 0, l_clpid, msg);
            if msg is null then
               zrf.decrease_lp(l.lpid, in_custid, in_item, l_quantity,
                     in_lotno, in_uom, in_user, 'BP', l.invstatus, l.inventoryclass, err, msg);
            end if;
         else
            l_clpid := l.lpid;
         end if;

         if msg is null then
            attach_child_plate(in_plpid, l_clpid, in_location, 'M', in_user, msg);
         end if;
         if msg is not null then
            out_error := 'Y';
            out_message := msg;
            close c_any_lp;
            return;
         end if;
      else
         if ((l_iteration = 1) and (in_picktotype = 'TOTE')) then
--          use 1st plate to build new plate

            l_weight := least(l.quantity, workqty) * (l.weight/l.quantity);

            zplp.clone_lp(l.lpid, in_location, 'M', in_quantity, l_weight,
                  in_user, 'BP', in_plpid, in_taskid, null, 0, pickedlp, msg);
            if (msg is not null) then
               out_error := 'Y';
               out_message := msg;
               close c_any_lp;
               return;
            end if;
         end if;

         zrf.decrease_lp(l.lpid, in_custid, in_item, least(l.quantity, workqty),
               in_lotno, in_uom, in_user, 'BP', l.invstatus, l.inventoryclass, err, msg);
         if ((err != 'N') or (msg is not null)) then
            out_error := err;
            out_message := msg;
            close c_any_lp;
            return;
         end if;
      end if;
      workqty := workqty - least(l.quantity, workqty);
      l_iteration := l_iteration + 1;
      exit when (workqty = 0);
   <<continue_loop>>
      null;
   end loop;
   close c_any_lp;
   if (workqty != 0) then
      out_message := 'Qty not avail';
      return;
   end if;
   batch_pick_update_order(in_taskid, in_facility, in_custid, in_orderitem,
         in_orderlot, in_item, in_plannedlp, in_fromloc, pickedlp,
         in_quantity, in_user, in_picktotype, msg);
   if (msg is not null) then
      out_error := 'Y';
      out_message := msg;
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end build_batchpick_parentlp;


procedure clone_lp
   (in_lpid          in varchar2,
    in_location 	   in varchar2,
    in_status        in varchar2,
    in_quantity 	   in number,
    in_weight        in number,
    in_user     	   in varchar2,
    in_tasktype   	in varchar2,
    in_parentlpid 	in varchar2,
    in_taskid        in number,
    in_shippinglpid  in varchar2,
    in_dropseq       in number,
    out_cloneid      out varchar2,
    out_message      out varchar2)
is
   msg varchar2(80);
   cloneid plate.lpid%type;
begin
   out_message := null;

   zrf.get_next_lpid(cloneid, msg);
   if (msg is not null) then
      out_message := msg;
      return;
   end if;
   out_cloneid := cloneid;

   insert into plate
      (lpid, item, custid, facility, location, status, holdreason,
       unitofmeasure, quantity, type, serialnumber, lotnumber, creationdate,
       manufacturedate, expirationdate, expiryaction, lastcountdate, po,
       recmethod, condition, lastoperator, lasttask, fifodate, destlocation,
       destfacility, countryof, parentlpid, useritem1, useritem2, useritem3,
       disposition, lastuser, lastupdate, invstatus, qtyentered, itementered,
       uomentered, inventoryclass, loadno, stopno, shipno, orderid, shipid,
       weight, adjreason, qtyrcvd, controlnumber, qcdisposition, fromlpid,
       taskid, dropseq, fromshippinglpid, workorderseq, workordersubseq,
       parentfacility, parentitem, childfacility, childitem, anvdate)
   select cloneid, P.item, P.custid, P.facility, in_location, in_status, P.holdreason,
       P.unitofmeasure, in_quantity, P.type, P.serialnumber, P.lotnumber, sysdate,
       P.manufacturedate, P.expirationdate, P.expiryaction, P.lastcountdate, P.po,
       P.recmethod, P.condition, in_user, in_tasktype, P.fifodate, P.destlocation,
       P.destfacility, P.countryof, in_parentlpid, P.useritem1, P.useritem2, P.useritem3,
       P.disposition, in_user, sysdate, P.invstatus, in_quantity, P.itementered,
       P.uomentered, P.inventoryclass, P.loadno, P.stopno, P.shipno, P.orderid, P.shipid,
       in_weight, P.adjreason, 0, P.controlnumber, P.qcdisposition, in_lpid,
       in_taskid, in_dropseq, in_shippinglpid, workorderseq, workordersubseq,
       P.parentfacility, P.parentitem, P.childfacility, P.childitem, P.anvdate
      from plate P
      where P.lpid = in_lpid;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end clone_lp;


procedure build_empty_parent
   (io_lpid        in out varchar2,
    in_facility    in varchar2,
    in_location    in varchar2,
    in_status      in varchar2,
    in_type        in varchar2,
    in_user        in varchar2,
    in_disposition in varchar2,
	 in_custid 	    in varchar2,
	 in_item		    in varchar2,
	 in_orderid	    in number,
	 in_shipid 	    in number,
	 in_loadno 	    in number,
	 in_stopno 	    in number,
	 in_shipno 	    in number,
    in_lotnumber   in varchar2,
    in_invstatus   in varchar2,
    in_invclass    in varchar2,
    out_message    out varchar2)
is
   msg varchar2(80);
   l_parentlpid plate.parentlpid%type;
begin
   out_message := null;

   if (io_lpid is null) then
      zrf.get_next_lpid(io_lpid, msg);
      if (msg is not null) then
         out_message := msg;
         return;
      end if;
   else
      delete from deletedplate where lpid = io_lpid;
      if sql%rowcount = 0 then
         delete plate where lpid = io_lpid and type = 'XP'
            returning parentlpid into l_parentlpid;
         if sql%rowcount != 0 then
            update shippingplate
               set fromlpid = null
               where lpid = l_parentlpid;
         end if;
      end if;
   end if;

   insert into plate
      (lpid, facility, location, status, quantity, type,
       creationdate, lastoperator, lastuser, lastupdate, weight,
       disposition, custid, item, orderid, shipid,
		 loadno, stopno, shipno, lotnumber, invstatus, inventoryclass)
   values
      (io_lpid, in_facility, in_location, in_status, 0, in_type,
       sysdate, in_user, in_user, sysdate, 0,
       in_disposition, in_custid, in_item, in_orderid, in_shipid,
		 in_loadno, in_stopno, in_shipno, in_lotnumber, in_invstatus, in_invclass);

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end build_empty_parent;


procedure attach_child_plate
   (in_parentlpid in varchar2,
    in_childlpid  in varchar2,
    in_location   in varchar2,
    in_status     in varchar2,
    in_user       in varchar2,
    out_message   out varchar2)
is
   cursor c_lp(p_lpid varchar2) is
      select quantity, weight, custid, loadno, stopno, shipno,
             nvl(orderid, 0) orderid, nvl(shipid, 0) shipid, location,
             status, item, facility, lotnumber, invstatus, inventoryclass,
             unitofmeasure
         from plate
         where lpid = p_lpid;
   pp c_lp%rowtype;
   cp c_lp%rowtype;
   kids varchar2(1) := 'S';
   cordid waves.wave%type;
	 pa_cordid waves.wave%type;
   ch_cordid waves.wave%type;
   l_msg varchar2(80);
begin
   out_message := null;

   open c_lp(in_childlpid);
   fetch c_lp into cp;
   close c_lp;

   open c_lp(in_parentlpid);
   fetch c_lp into pp;
   close c_lp;
   cordid := zcord.cons_orderid(pp.orderid, pp.shipid);

   if ((pp.status = 'A') and (pp.quantity = 0)) then
      update plate
         set facility = cp.facility,
             location = nvl(in_location, location),
             status = nvl(in_status, status),
             quantity = nvl(cp.quantity, 0),
             lastoperator = in_user,
             lastuser = in_user,
             lastupdate = sysdate,
             weight = nvl(cp.weight, 0),
             taskid = decode(cordid, 0, 0, taskid),
             custid = cp.custid,
             orderid = decode(cordid, 0, cp.orderid, orderid),
             shipid = decode(cordid, 0, cp.shipid, shipid),
             loadno = cp.loadno,
             stopno = cp.stopno,
             shipno = cp.shipno,
             item = cp.item,
             lotnumber = cp.lotnumber,
             invstatus = cp.invstatus,
             inventoryclass = cp.inventoryclass,
             qtytasked = null,
             childfacility = null,
             childitem = null,
             parentfacility = cp.facility,
             parentitem = cp.item
         where lpid = in_parentlpid;
   else
      if (nvl(cp.custid, '(none)') != nvl(pp.custid, '(none)')) then
         cp.custid := null;
         cp.item := null;
         cp.lotnumber := null;
         kids := 'M';
      elsif (nvl(cp.item, '(none)') != nvl(pp.item, '(none)')) then
         cp.item := null;
         cp.lotnumber := null;
         kids := 'M';
      elsif (nvl(cp.lotnumber, '(none)') != nvl(pp.lotnumber, '(none)')) then
         cp.lotnumber := null;
      end if;

      if (nvl(cp.invstatus, '(none)') != nvl(pp.invstatus, '(none)')) then
         cp.invstatus := null;
      end if;

      if (nvl(cp.inventoryclass, '(none)') != nvl(pp.inventoryclass, '(none)')) then
         cp.inventoryclass := null;
      end if;

		if (cordid != 0) then
      	cp.orderid := pp.orderid;
         cp.shipid := pp.shipid;
      elsif (nvl(cp.orderid, 0) != nvl(pp.orderid, 0)) then
			pa_cordid := zcord.cons_orderid(pp.orderid, pp.shipid);
			ch_cordid := zcord.cons_orderid(cp.orderid, cp.shipid);
         if (pa_cordid = ch_cordid) and (pa_cordid != 0) then
            cp.orderid := pa_cordid;
			else
            cp.orderid := 0;
			end if;
         cp.shipid := 0;
      elsif (nvl(cp.shipid, 0) != nvl(pp.shipid, 0)) then
         cp.shipid := 0;
      end if;

      if (nvl(cp.loadno, 0) != nvl(pp.loadno, 0)) then
         cp.loadno := 0;
         cp.stopno := 0;
         cp.shipno := 0;
      elsif (nvl(cp.stopno, 0) != nvl(pp.stopno, 0)) then
         cp.stopno := 0;
         cp.shipno := 0;
      elsif (nvl(cp.shipno, 0) != nvl(pp.shipno, 0)) then
         cp.shipno := 0;
      end if;

      update plate
         set status = nvl(in_status, status),
             location = nvl(in_location, location),
             quantity = nvl(quantity, 0) + nvl(cp.quantity, 0),
             weight = nvl(weight, 0) + nvl(cp.weight, 0),
             lastoperator = in_user,
             lastuser = in_user,
             lastupdate = sysdate,
             custid = cp.custid,
             orderid = cp.orderid,
             shipid = cp.shipid,
             loadno = cp.loadno,
             stopno = cp.stopno,
             shipno = cp.shipno,
             item = cp.item,
             lotnumber = cp.lotnumber,
             invstatus = cp.invstatus,
             inventoryclass = cp.inventoryclass,
             childfacility = null,
             childitem = null,
             parentfacility = decode(kids, 'S', cp.facility),
             parentitem = decode(kids, 'S', cp.item)
         where lpid = in_parentlpid;

      if ((nvl(cp.custid,'(none)') != nvl(pp.custid,'(none)')) or
          (nvl(cp.item,'(none)') != nvl(pp.item,'(none)')) or
          (nvl(cp.lotnumber,'(none)') != nvl(pp.lotnumber,'(none)')) or
          (nvl(cp.invstatus,'(none)') != nvl(pp.invstatus,'(none)')) or
          (nvl(cp.inventoryclass,'(none)') != nvl(pp.inventoryclass,'(none)'))) then
         zbill.add_asof_inventory(pp.facility, pp.custid, pp.item, pp.lotnumber, pp.unitofmeasure,
               trunc(sysdate), pp.quantity * -1, pp.weight * -1, 'Adjust MP', 'AD', pp.inventoryclass,
               pp.invstatus, pp.orderid, pp.shipid, in_parentlpid, in_user, l_msg);

         zbill.add_asof_inventory(pp.facility, cp.custid, cp.item, cp.lotnumber, pp.unitofmeasure,
               trunc(sysdate), pp.quantity, pp.weight, 'Adjust MP', 'AD', cp.inventoryclass,
               cp.invstatus, cp.orderid, cp.shipid, in_parentlpid, in_user, l_msg);
      end if;

   end if;

   if (kids = 'S') then
      update plate
         set parentlpid = in_parentlpid,
             status = nvl(in_status, pp.status),
             location = nvl(in_location, pp.location),
             lastoperator = in_user,
             lastuser = in_user,
             lastupdate = sysdate,
             childfacility = null,
             childitem = null,
             parentfacility = null,
             parentitem = null
         where lpid = in_childlpid;
   else
      update plate
         set parentlpid = in_parentlpid,
             status = nvl(in_status, pp.status),
             location = nvl(in_location, pp.location),
             lastoperator = in_user,
             lastuser = in_user,
             lastupdate = sysdate
         where lpid = in_childlpid;
      update plate
         set childfacility = facility,
             childitem = item,
             parentfacility = null,
             parentitem = null
         where parentlpid = in_parentlpid
           and (parentfacility is not null
                or parentitem is not null
                or nvl(childfacility,'x') != facility
                or nvl(childitem,'x') != item);
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end attach_child_plate;


procedure morph_lp_to_multi
   (in_lpid     in varchar2,
    in_user     in varchar2,
    out_message out varchar2)
is
   msg varchar2(80);
   clpid plate.lpid%type;
begin
   out_message := null;

   zrf.get_next_lpid(clpid, msg);
   if (msg is not null) then
      out_message := msg;
      return;
   end if;

   update plate
      set lpid = clpid,
          parentlpid = in_lpid,
          lastoperator = in_user,
          lastuser = in_user,
          lastupdate = sysdate,
          childfacility = null,
          childitem = null,
          parentfacility = null,
          parentitem = null
      where lpid = in_lpid;

   insert into plate
      (lpid, facility, location, status, quantity, type,
       creationdate, disposition, lastoperator, lastuser, lastupdate, weight,
       custid, orderid, shipid, loadno, stopno, shipno, item,
       parentfacility, parentitem, lotnumber, invstatus, inventoryclass)
   select in_lpid, P.facility, P.location, P.status, P.quantity, 'MP',
       sysdate, P.disposition, in_user, in_user, sysdate, P.weight,
       P.custid, P.orderid, P.shipid, P.loadno, P.stopno, P.shipno, P.item,
       P.facility, P.item, P.lotnumber, P.invstatus, P.inventoryclass
      from plate P
      where P.lpid = clpid;

   update orderdtlrcpt
      set lpid = clpid
      where lpid = in_lpid;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end morph_lp_to_multi;


procedure detach_child_plate
   (in_parentlpid   in varchar2,
    in_childlpid    in varchar2,
    in_location     in varchar2,
    in_destfacility in varchar2,
    in_destlocation in varchar2,
    in_status       in varchar2,
    in_user         in varchar2,
    in_tasktype     in varchar2,
    out_message     out varchar2)
is
   cursor c_ch is
      select parentlpid
         from plate
         where lpid = in_childlpid;
   ch c_ch%rowtype;
   cursor c_lp is
      select distinct custid, item, lotnumber, invstatus, inventoryclass,
             orderid, shipid, loadno, stopno, shipno
         from plate
         where type = 'PA'
         start with lpid = ch.parentlpid
         connect by prior lpid = parentlpid;
   pa c_lp%rowtype;
   lpquantity plate.quantity%type;
   lpweight plate.weight%type;
   msg varchar2(255);
   kids varchar2(1) := 'S';
	pa_cordid waves.wave%type;
   ch_cordid waves.wave%type;
   l_elapsed_begin date;
   l_elapsed_end date;
begin
   out_message := null;
   l_elapsed_begin := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'begin ZPLP.DETACH_CHILD_PLATE - ' ||
                    'in_parentlpid: ' || in_parentlpid || ', ' || 
                    'in_childlpid: ' || in_childlpid || ', ' ||
                    'in_location: ' || in_location || ', ' ||
                    'in_destfacility: ' || in_destfacility || ', ' ||
                    'in_destlocation: ' || in_destlocation || ', ' ||
                    'in_status: ' || in_status || ', ' ||
                    'in_user: ' || in_user || ', ' ||
                    'in_tasktype: ' || in_tasktype,
                    'T', in_user);

	if (in_parentlpid is null) then
   	open c_ch;
   	fetch c_ch into ch;
   	close c_ch;
	else
		ch.parentlpid := in_parentlpid;
	end if;

   update plate
      set parentlpid = null,
          destfacility = nvl(in_destfacility, destfacility),
          destlocation = nvl(in_destlocation, destlocation),
          status = in_status,
          location = in_location,
          lasttask = in_tasktype,
          lastoperator = in_user,
          lastuser = in_user,
          lastupdate = sysdate,
          childfacility = null,
          childitem = null,
          parentfacility = facility,
          parentitem = item
      where lpid = in_childlpid
      returning quantity, weight into lpquantity, lpweight;

   zplp.decrease_parent(ch.parentlpid, lpquantity, lpweight, in_user, in_tasktype, msg);
   if (msg is not null) then
      out_message := substr(msg,1,80);
      return;
   end if;

-- check for mixed MP versus single MP

   for k in c_lp loop
      if (c_lp%rowcount = 1) then
         pa := k;
      else
         if (nvl(pa.custid, '(none)') != nvl(k.custid, '(none)')) then
            pa.custid := null;
            pa.item := null;
            pa.lotnumber := null;
            kids := 'M';
         elsif (nvl(pa.item, '(none)') != nvl(k.item, '(none)')) then
            pa.item := null;
            pa.lotnumber := null;
            kids := 'M';
         elsif (nvl(pa.lotnumber, '(none)') != nvl(k.lotnumber, '(none)')) then
            pa.lotnumber := null;
         end if;

         if (nvl(pa.invstatus, '(none)') != nvl(k.invstatus, '(none)')) then
            pa.invstatus := null;
         end if;

         if (nvl(pa.inventoryclass, '(none)') != nvl(k.inventoryclass, '(none)')) then
            pa.inventoryclass := null;
         end if;

         if (nvl(pa.orderid, 0) != nvl(k.orderid, 0)) then
				pa_cordid := zcord.cons_orderid(pa.orderid, pa.shipid);
				ch_cordid := zcord.cons_orderid(k.orderid, k.shipid);
            if (pa_cordid = ch_cordid) and (pa_cordid != 0) then
               pa.orderid := pa_cordid;
				else
               pa.orderid := 0;
				end if;
            pa.shipid := 0;
         elsif (nvl(pa.shipid, 0) != nvl(k.shipid, 0)) then
            pa.shipid := 0;
         end if;

         if (nvl(pa.loadno, 0) != nvl(k.loadno, 0)) then
            pa.loadno := 0;
            pa.stopno := 0;
            pa.shipno := 0;
         elsif (nvl(pa.stopno, 0) != nvl(k.stopno, 0)) then
            pa.stopno := 0;
            pa.shipno := 0;
         elsif (nvl(pa.shipno, 0) != nvl(k.shipno, 0)) then
            pa.shipno := 0;
         end if;
      end if;
   end loop;

   if (kids = 'M') then             -- mixed MP
      update plate
         set lastoperator = in_user,
             lastuser = in_user,
             lastupdate = sysdate,
             lasttask = in_tasktype,
             custid = pa.custid,
             item = pa.item,
             lotnumber = pa.lotnumber,
             invstatus = pa.invstatus,
             inventoryclass = pa.inventoryclass,
             orderid = pa.orderid,
             shipid = pa.shipid,
             loadno = pa.loadno,
             stopno = pa.stopno,
             shipno = pa.shipno,
             parentfacility = null,
             parentitem = null,
             childfacility = null,
             childitem = null
         where lpid = ch.parentlpid;
      update plate
         set childfacility = facility,
             childitem = item,
             parentfacility = null,
             parentitem = null
         where parentlpid = ch.parentlpid
           and (parentfacility is not null
                or parentitem is not null
                or nvl(childfacility,'x') != facility
                or nvl(childitem,'x') != item);
   else                             -- single MP
      update plate
         set lastoperator = in_user,
             lastuser = in_user,
             lastupdate = sysdate,
             lasttask = in_tasktype,
             custid = pa.custid,
             item = pa.item,
             lotnumber = pa.lotnumber,
             invstatus = pa.invstatus,
             inventoryclass = pa.inventoryclass,
             orderid = pa.orderid,
             shipid = pa.shipid,
             loadno = pa.loadno,
             stopno = pa.stopno,
             shipno = pa.shipno,
             childfacility = null,
             childitem = null,
             parentfacility = facility,
             parentitem = pa.item
         where lpid = ch.parentlpid;
      update plate
         set childfacility = null,
             childitem = null,
             parentfacility = null,
             parentitem = null
         where parentlpid = ch.parentlpid
           and (parentfacility is not null
                or parentitem is not null
                or childfacility is not null
                or childitem is not null);
   end if;
   l_elapsed_end := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'end ZPLP.DETACH_CHILD_PLATE - ' ||
                    'out_message: ' || out_message || 
                    ' (Elapsed: ' ||
                    rtrim(substr(zlb.formatted_staffhrs((l_elapsed_end - l_elapsed_begin)*24),1,12)) ||
                    ')',
                    'T', in_user);

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end detach_child_plate;


procedure decrease_parent
   (in_parentlpid in varchar2,
    in_quantity   in number,
    in_weight     in varchar2,
    in_user       in varchar2,
    in_tasktype   in varchar2,
    out_message   out varchar2)
is
   cursor c_lp (p_lp varchar2) is
      select type, quantity, parentlpid
         from plate
         where lpid = p_lp;
   pp c_lp%rowtype;
   msg varchar2(255) := null;
begin
   out_message := null;

   open c_lp(in_parentlpid);
   fetch c_lp into pp;
   close c_lp;

   if (pp.quantity = in_quantity) then
      if (pp.type = 'TO') then
--       mark tote as empty/available
         update plate
            set quantity = 0,
                weight = 0,
                status = 'A',
                lasttask = in_tasktype,
                lastoperator = in_user,
                lastuser = in_user,
                lastupdate = sysdate
            where lpid = in_parentlpid;
      else
--       delete plate
         zlp.plate_to_deletedplate(in_parentlpid, in_user, in_tasktype, msg);
         if (msg is not null) then
            out_message := substr(msg,1,80);
            return;
         end if;
      end if;
   else
--    still some left, just update the plate
      update plate
         set quantity = nvl(quantity, 0) - in_quantity,
             weight = nvl(weight, 0) - in_weight,
             lasttask = in_tasktype,
             lastoperator = in_user,
             lastuser = in_user,
             lastupdate = sysdate
         where lpid = in_parentlpid;
   end if;

   if (pp.parentlpid is not null) then
      zplp.decrease_parent(pp.parentlpid, in_quantity, in_weight, in_user,
         in_tasktype, msg);
      out_message := substr(msg,1,80);
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end decrease_parent;


procedure balance_master
   (in_lpid     in varchar2,
    in_tasktype in varchar2,
    in_user     in varchar2,
    out_message out varchar2)
is
   cursor curChildrenSum(p_status varchar2) is
      select custid, item, lotnumber, invstatus, inventoryclass,
             sum(quantity) as quantity
         from plate
         where parentlpid = in_lpid
           and status = p_status
           and type = 'PA'
         group by custid, item, lotnumber, invstatus, inventoryclass
         order by custid, item, lotnumber, invstatus, inventoryclass;
   parent plate%rowtype := null;
   cntItem integer := 0;
   cntLotNumber integer := 0;
   cntInvStatus integer := 0;
   cntInventoryClass integer := 0;
   l_status plate.status%type := 'A';
begin
   out_message := null;

   if zlbl.is_lp_unprocessed_autogen(in_lpid) = 'Y' then
      l_status := 'U';
   end if;

   for cs in curChildrenSum(l_status) loop
      parent.custid := cs.custid;
      if nvl(parent.item, 'x') <> cs.item then
         cntItem := cntItem + 1;
      end if;
      parent.item := cs.item;
      if nvl(parent.lotnumber, 'x') <> nvl(cs.lotnumber, 'x') then
         cntlotnumber := cntlotnumber + 1;
      end if;
      parent.lotnumber := cs.lotnumber;
      if nvl(parent.invstatus, 'x') <> cs.invstatus then
         cntinvstatus := cntinvstatus + 1;
      end if;
      parent.invstatus := cs.invstatus;
      if nvl(parent.inventoryclass, 'x') <> cs.inventoryclass then
         cntinventoryclass := cntinventoryclass + 1;
      end if;
      parent.inventoryclass := cs.inventoryclass;
   end loop;

   if cntItem = 1 then -- "single-item" multi
      update plate
         set parentfacility = facility,
             parentitem = parent.item,
             childfacility = null,
             childitem = null,
             custid = parent.custid,
             item = parent.item,
             lotnumber = parent.lotnumber,
             invstatus = parent.invstatus,
             inventoryclass = parent.inventoryclass,
             lasttask = in_tasktype,
             lastuser = in_user,
             lastupdate = sysdate
         where lpid = in_lpid
           and (nvl(parentfacility, 'x') != facility or
                nvl(parentitem, 'x') != parent.item or
                childfacility is not null or
                childitem is not null or
                nvl(custid, 'x') != parent.custid or
                nvl(item, 'x') != parent.item or
                nvl(lotnumber, 'x') != nvl(parent.lotnumber, 'x') or
                nvl(invstatus, 'x') != nvl(parent.invstatus, 'x') or
                nvl(inventoryclass, 'x') != nvl(parent.inventoryclass, 'x'));
        update plate
           set parentfacility = null,
               parentitem = null,
               childfacility = null,
               childitem = null
         where parentlpid = in_lpid
           and (parentfacility is not null or
                parentitem is not null or
                childfacility is not null or
                childitem is not null);
   else                      -- "multiple-item" multi
      if cntItem > 1 then
         parent.item := null;
         parent.lotnumber := null;
      end if;
      if cntLotNumber > 1 then
         parent.lotnumber := null;
      end if;
      if cntInvStatus > 1 then
         parent.invstatus := null;
      end if;
      if cntInventoryClass > 1 then
         parent.inventoryclass := null;
      end if;
      update plate
         set parentfacility = null,
             parentitem = null,
             childfacility = null,
             childitem = null,
             item = parent.item,
             lotnumber = parent.lotnumber,
             invstatus = parent.invstatus,
             inventoryclass = parent.inventoryclass,
             lasttask = in_tasktype,
             lastuser = in_user,
             lastupdate = sysdate
         where lpid = in_lpid
           and (parentfacility is not null or
                parentitem is not null or
                childfacility is not null or
                childitem is not null or
                nvl(item, 'x') <> nvl(parent.item, 'x') or
                nvl(lotnumber, 'x') <> nvl(parent.lotnumber, 'x') or
                nvl(invstatus, 'x') <> nvl(parent.invstatus, 'x') or
                nvl(inventoryclass, 'x') <> nvl(parent.inventoryclass, 'x'));
        update plate
           set parentfacility = null,
               parentitem = null,
               childfacility = facility,
               childitem = item
         where parentlpid = in_lpid
           and (parentfacility is not null or
                parentitem is not null or
                nvl(childfacility, 'x') != facility or
                nvl(childitem, 'x') != item);
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end balance_master;


procedure build_mass_manifest
   (in_lpid     in varchar2,
    in_taskid   in number,
    in_user     in varchar2,
    out_error   out varchar2,
    out_message out varchar2)
is
   cursor c_slp(p_lpid varchar2) is
      select *
         from shippingplate
         where fromlpid in (select lpid from plate
                              start with lpid = p_lpid
                              connect by prior lpid = parentlpid)
           and location is null
           and status = 'U'
           and taskid = 0;
   slp c_slp%rowtype;
   cursor c_lp(p_lpid varchar2) is
      select P.location, I.labeluom, P.parentlpid
         from plate P, custitem I
         where P.lpid = p_lpid
           and I.custid = P.custid
           and I.item = P.item;
   lp c_lp%rowtype;
   cursor c_ptl(p_orderid number, p_shipid number, p_orderitem varchar2,
                 p_orderlot varchar2, p_qty number) is
      select lpid, parentlpid, quantity
         from shippingplate
         where orderid = p_orderid
           and shipid = p_shipid
           and orderitem = p_orderitem
           and nvl(orderlot,'(none)') = nvl(p_orderlot,'(none)')
           and type = 'P'
           and status = 'S'
           and location is not null
           and quantity < p_qty;
   ptl c_ptl%rowtype;
   cursor c_ctn(p_orderid number, p_shipid number, p_item varchar2) is
      select ctnid, rowid
         from mass_manifest_ctn
         where orderid = p_orderid
           and shipid = p_shipid
           and item = p_item
           and used = 'N';
   ctn c_ctn%rowtype;
   l_lblqty number;
   l_err varchar2(1);
   l_msg varchar2(80);
   l_found boolean;
   l_qty number;
   l_weight number;
   l_lpid shippingplate.lpid%type;
   l_ctnlpid shippingplate.lpid%type;
   l_termid multishipterminal.termid%type;
   l_fac tasks.facility%type;
begin
   out_error := 'N';
   out_message := null;

-- Find Facility from plate
   l_fac := null;
  begin
    select facility
      into l_fac
      from plate
     where lpid = in_lpid;
  exception when others then
    l_fac := null;
  end;

-- Locate first multiship terminal for the facility
  l_termid := null;

  begin
    select min(termid)
      into l_termid
      from multishipterminal
     where facility = l_fac;
  exception when others then
    l_termid := null;
  end;
  if l_termid is null then
     zms.log_msg('MASSMAN', '', '',
       'Task:'||in_taskid||' for mass manifest but facility '||l_fac||' does not have a Malvern terminal',
       'E', in_user, l_msg);
  end if;


   for slp in c_slp(in_lpid) loop

      open c_lp(slp.fromlpid);
      fetch c_lp into lp;
      close c_lp;

      zrf.get_baseuom_factor(slp.custid, slp.item, slp.unitofmeasure, lp.labeluom,
            l_lblqty, l_err, l_msg);

--    try for a partial first
      open c_ptl(slp.orderid, slp.shipid, slp.orderitem, slp.orderlot, l_lblqty);
      fetch c_ptl into ptl;
      l_found := c_ptl%found;
      close c_ptl;
      if l_found then
         l_qty := least(slp.quantity, l_lblqty-ptl.quantity);
         l_weight := l_qty * zcwt.lp_item_weight(slp.fromlpid, slp.custid, slp.item,
               slp.unitofmeasure);

         update shippingplate
            set quantity = quantity + l_qty,
                weight = weight + l_weight
            where lpid = ptl.lpid;

         update shippingplate
            set quantity = quantity + l_qty,
                weight = weight + l_weight
            where lpid = ptl.parentlpid;

         zrf.decrease_lp(slp.fromlpid, slp.custid, slp.item, l_qty, slp.lotnumber,
               slp.unitofmeasure, in_user, 'BP', slp.invstatus, slp.inventoryclass,
               l_err, l_msg);
         if l_msg is not null then
            out_error := l_err;
            out_message := l_msg;
            return;
         end if;

         slp.quantity := slp.quantity - l_qty;
      end if;

--    build new labeluom shippingplates
      loop
         exit when slp.quantity <= 0;

         l_qty := least(slp.quantity, l_lblqty);
         l_weight := l_qty * zcwt.lp_item_weight(slp.fromlpid, slp.custid, slp.item,
               slp.unitofmeasure);

	      zsp.get_next_shippinglpid(l_ctnlpid, l_msg);
	      if l_msg is not null then
            out_error := 'Y';
 		      out_message := l_msg;
	         return;
	      end if;

         open c_ctn(slp.orderid, slp.shipid, slp.item);
         fetch c_ctn into ctn;
         if c_ctn%found then
            update mass_manifest_ctn
               set used = 'Y'
               where rowid = ctn.rowid;
            insert into plate
               (lpid, type, parentlpid, lastuser, lastupdate,
                lasttask, lastoperator, custid, facility)
            values
               (ctn.ctnid, 'XP', l_ctnlpid, in_user, sysdate,
                'BP', in_user, slp.custid, slp.facility);
         else
            ctn.ctnid := null;
         end if;
         close c_ctn;

         insert into shippingplate
            (lpid, facility, location, status, quantity,
             type, lastuser, lastupdate, weight, taskid,
             item, custid, loadno, stopno, shipno,
             orderid, shipid, lotnumber, fromlpid)
         values
            (l_ctnlpid, slp.facility, lp.location, 'S', l_qty,
             'C', in_user, sysdate, l_weight, in_taskid,
             slp.item, slp.custid, slp.loadno, slp.stopno, slp.shipno,
             slp.orderid, slp.shipid, slp.lotnumber, ctn.ctnid);

	      zsp.get_next_shippinglpid(l_lpid, l_msg);
	      if l_msg is not null then
            out_error := 'Y';
 		      out_message := l_msg;
	         return;
	      end if;
	      insert into shippingplate
		      (lpid, item, custid, facility, location,
             status, holdreason, unitofmeasure, quantity, type,
             fromlpid, serialnumber, lotnumber, parentlpid, useritem1,
             useritem2, useritem3, lastuser, lastupdate, invstatus,
             qtyentered, orderitem, uomentered, inventoryclass, loadno,
             stopno, shipno, orderid, shipid, weight,
             ucc128, labelformat, taskid, dropseq, orderlot,
             pickuom, pickqty, trackingno, cartonseq, checked,
             totelpid, cartontype, pickedfromloc, shippingcost, carriercodeused,
             satdeliveryused, openfacility, audited, prevlocation, fromlpidparent,
             rmatrackingno, actualcarrier, manufacturedate, expirationdate)
 	      values
		      (l_lpid, slp.item, slp.custid, slp.facility, lp.location,
             'S', slp.holdreason, slp.unitofmeasure, l_qty, 'P',
             slp.fromlpid, slp.serialnumber, slp.lotnumber, l_ctnlpid, slp.useritem1,
             slp.useritem2, slp.useritem3, in_user, sysdate, slp.invstatus,
             l_lblqty, slp.orderitem, slp.uomentered, slp.inventoryclass, slp.loadno,
             slp.stopno, slp.shipno, slp.orderid, slp.shipid, l_weight,
             slp.ucc128, slp.labelformat, in_taskid, null, slp.orderlot,
             lp.labeluom, 1, null, null, null,
             null, null, lp.location, null, null,
             null, null, null, null, lp.parentlpid,
             null, null, slp.manufacturedate, slp.expirationdate);

         zrf.decrease_lp(slp.fromlpid, slp.custid, slp.item, l_qty, slp.lotnumber,
               slp.unitofmeasure, in_user, 'BP', slp.invstatus, slp.inventoryclass,
               l_err, l_msg);
         if l_msg is not null then
            out_error := l_err;
            out_message := l_msg;
            return;
         end if;

         zoh.add_orderhistory_item(slp.orderid, slp.shipid,
               l_ctnlpid, slp.item, slp.lotnumber,
               'Pick Plate',
               'Pick Qty:'||l_qty||' from LP:'||slp.fromlpid,
               in_user, l_msg);

         slp.quantity := slp.quantity - l_qty;

         if ctn.ctnid is not null and l_termid is not null then
            zmn.send_staged_carton_trigger(l_fac, slp.custid,
                l_termid, ctn.ctnid, in_user, l_msg);
         end if;

      end loop;

      update orderhdr
         set orderstatus = decode(qtycommit, 0, zrf.ORD_PICKED, zrf.ORD_PICKING),
             lastuser = in_user,
             lastupdate = sysdate
         where orderid = slp.orderid
           and shipid = slp.shipid
           and orderstatus < decode(qtycommit, 0, zrf.ORD_PICKED, zrf.ORD_PICKING);

      delete shippingplate where lpid = slp.lpid;

   end loop;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end build_mass_manifest;


end parentlp;
/

show errors package body parentlp;
exit;
