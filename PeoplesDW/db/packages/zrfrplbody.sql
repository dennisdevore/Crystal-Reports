create or replace package body alps.rfreplenishment as
--
-- $Id$
--


-- Private procedures


procedure make_lp_copy
   (in_fromlpid  in varchar2,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_tolpid    in varchar2,
    in_quantity  in number,
    in_weight    in number,
    in_user      in varchar2,
    in_taskid    in number,
    in_dropseq   in number,
    in_plannedlp in varchar2,
    out_message  out varchar2)
is
   cursor c_lp is
      select lpid
         from plate
         where custid = in_custid
           and item = in_item
           and type = 'PA'
			start with lpid = in_fromlpid
         connect by prior lpid = parentlpid;
	lp c_lp%rowtype;
   l_opcode varchar2(1) := 'U';
   l_msg varchar2(80);
   l_tolpid plate.lpid%type := in_tolpid;
begin
   out_message := null;

   if (l_tolpid is null) then
      zrf.get_next_lpid(l_tolpid, l_msg);
      if (l_msg is not null) then
         out_message := l_msg;
         return;
      end if;
      l_opcode := 'I';
   end if;

   if (l_opcode = 'U') then
      update plate
         set quantity = nvl(quantity, 0) + in_quantity,
             weight = nvl(weight, 0) + in_weight,
             lastoperator = in_user,
             lastuser = in_user,
             lastupdate = sysdate
         where lpid = l_tolpid;

      if (sql%rowcount = 0) then
         l_opcode := 'I';
      end if;
   end if;

   if (l_opcode = 'I') then
   	open c_lp;
      fetch c_lp into lp;
      close c_lp;

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
          qtytasked, childfacility, childitem, parentfacility, parentitem,
          anvdate)
      select l_tolpid, P.item, P.custid, P.facility, in_user, 'M', P.holdreason,
          P.unitofmeasure, in_quantity, P.type, P.serialnumber, P.lotnumber, sysdate,
          P.manufacturedate, P.expirationdate, P.expiryaction, P.lastcountdate, P.po,
          P.recmethod, P.condition, in_user, 'RP', P.fifodate, P.destlocation,
          P.destfacility, P.countryof, null, P.useritem1, P.useritem2, P.useritem3,
          P.disposition, in_user, sysdate, P.invstatus, in_quantity, P.itementered,
          P.uomentered, P.inventoryclass, P.loadno, P.stopno, P.shipno, P.orderid, P.shipid,
          in_weight, P.adjreason, 0, P.controlnumber, P.qcdisposition, in_fromlpid,
          in_taskid, in_dropseq, null, workorderseq, workordersubseq,
          null, P.childfacility, P.childitem, P.parentfacility, P.parentitem,
          P.anvdate
         from plate P
         where P.lpid = lp.lpid;
   end if;

   /*
   update subtasks
      set lpid = l_tolpid
      where taskid = in_taskid
        and lpid = in_plannedlp;
   update tasks
      set lpid = l_tolpid
      where taskid = in_taskid
        and lpid = in_plannedlp;
   */

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end make_lp_copy;


-- Public procedures


procedure pick_a_repl
   (in_taskid        in number,
    in_user          in varchar2,
    in_plannedlp     in varchar2,
    in_pickedlp      in varchar2,
    in_custid        in varchar2,
    in_item          in varchar2,
    in_qty           in number,
    in_pickfac       in varchar2,
    in_pickloc       in varchar2,
    in_uom           in varchar2,
    in_picktype      in varchar2,
    in_dropseq       in number,
    in_pickqty       in number,
    in_picked_child  in varchar2,
    in_subtask_rowid in varchar2,
    in_picked_to_lp  in varchar2,
    out_lpcount      out number,
    out_error        out varchar2,
    out_message      out varchar2)
is
   cursor c_lp(p_lpid varchar2) is
      select P.location, P.quantity, L.section, L.equipprof, P.parentlpid,
             L.pickingseq, L.pickingzone, P.invstatus, P.inventoryclass,
             P.type, L.loctype, nvl(P.qtytasked,0) qtytasked, P.lpid
         from plate P, location L
         where P.lpid = p_lpid
           and L.facility = P.facility
           and L.locid = P.location;
   cursor c_loc is
      select locid, in_qty, section, equipprof, null,
             pickingseq, pickingzone, null, null,
             null, loctype, 0, null
         from location
         where facility = in_pickfac
           and locid = in_pickloc;
   pik c_lp%rowtype := null;
   pln c_lp%rowtype := null;
   swappedlp c_lp%rowtype := null;
   cursor c_swap is
      select S.rowid strowid, T.rowid tkrowid, T.lpid tklpid, T.taskid
         from subtasks S, tasks T
         where T.facility = in_pickfac
           and T.tasktype in ('PK', 'OP', 'BP', 'RP', 'SO')
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
   cursor c_any_lp is
      select lpid, quantity, parentlpid, serialnumber, useritem1, useritem2,
             useritem3, invstatus, inventoryclass
         from plate
         where facility = in_pickfac
           and location = in_pickloc
           and custid = in_custid
           and item = in_item
           and unitofmeasure = in_uom
           and type = 'PA'
           and status = 'A'
         order by manufacturedate, creationdate;
   cursor c_itemview is
     select serialrequired, serialasncapture, user1required, user1asncapture,
            user2required, user2asncapture, user3required, user3asncapture
      from custitemview
      where custid = in_custid
        and item = in_item;
   itv c_itemview%rowtype;
   err varchar2(1);
   msg varchar2(80);
   cnt integer;
   pdfac plate.destfacility%type;
   pdloc plate.destlocation%type;
   pickedlp plate.lpid%type;
   lptype plate.type%type;
begin
   out_error := 'N';
   out_message := null;

   if in_plannedlp is not null then
      open c_lp(in_plannedlp);
      fetch c_lp into pln;
      close c_lp;
   end if;

   if ((in_plannedlp is not null) and (in_pickedlp is not null)
   and (in_plannedlp != in_pickedlp)) then
      if (in_picktype = 'F') then
         select count(1) into cnt
            from subtasks S, tasks T
            where T.facility = in_pickfac
              and T.tasktype in ('PK', 'OP', 'BP', 'RP', 'SO')
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
            update batchtasks
               set lpid = '((switching))'
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

            update subtasks
               set fromsection = pln.section,
                   fromloc = pln.location,
                   fromprofile = pln.equipprof,
                   lpid = in_plannedlp,
                   lastuser = in_user,
                   lastupdate = sysdate,
                   locseq = pln.pickingseq,
                   pickingzone = pln.pickingzone
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

            update shippingplate
               set location = pln.location,
                   fromlpid = in_plannedlp
               where fromlpid = in_pickedlp
                 and status = 'U';

            update plate
               set (destfacility, destlocation) =
                   (select destfacility, destlocation
                        from plate
                        where lpid = in_pickedlp)
               where lpid = in_plannedlp
               returning destfacility, destlocation into pdfac, pdloc;
         elsif (cnt = 0) then
            update plate
               set destfacility = null,
                   destlocation = null
               where lpid = in_plannedlp
               returning destfacility, destlocation into pdfac, pdloc;
         end if;
         update plate
            set destfacility = pdfac,
                destlocation = pdloc
            where lpid = in_pickedlp;
      end if;

--    update the original task data

      open c_task;
      fetch c_task into tsk;
      close c_task;
      if (tsk.lpid is not null) then
         tsk.lpid := in_pickedlp;
      end if;

      if (in_pickedlp is not null) then
         open c_lp(in_pickedlp);
         fetch c_lp into pik;
         close c_lp;
      else
         open c_loc;
         fetch c_loc into pik;
         close c_loc;
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

   pickedlp := nvl(in_picked_child, in_pickedlp);
   if (pickedlp is not null) then
      open c_lp(pickedlp);
      fetch c_lp into pik;
      close c_lp;
   else
      open c_loc;
      fetch c_loc into pik;
      close c_loc;
   end if;

   if (pickedlp is not null) then
--    update plate
      if ((in_picktype = 'F') or (in_qty = pik.quantity)) then
--       use entire plate
         update plate
            set location = in_user,
                status = 'M',
                dropseq = in_dropseq,
                taskid = in_taskid,
                lasttask = 'RP',
                lastoperator = in_user,
                lastuser = in_user,
                lastupdate = sysdate
            where lpid = pickedlp
            returning type into lptype;
         if (lptype in ('MP','TO')) then
            update plate
               set location = in_user,
                   status = 'M',
                   lasttask = 'RP',
                   lastoperator = in_user,
                   lastuser = in_user,
                   lastupdate = sysdate
               where lpid in (select lpid from plate
                                 where lpid != pickedlp
                                 start with lpid = pickedlp
                                 connect by prior lpid = parentlpid);
         end if;

         if (pik.parentlpid is not null) then
            zplp.detach_child_plate(pik.parentlpid, pickedlp, in_user, null,
                  null, 'M', in_user, 'RP', msg);
            if (msg is not null) then
               out_error := 'Y';
               out_message := msg;
               return;
            end if;
         end if;
      else
--       use part of plate
         make_lp_copy(pickedlp, in_custid, in_item, in_picked_to_lp, in_qty,
   				zcwt.lp_item_weight(pickedlp, in_custid, in_item, in_uom) * in_qty,
         		in_user, in_taskid, in_dropseq, in_plannedlp, msg);
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
            return;
         end if;
         zrf.decrease_lp(pickedlp, in_custid, in_item, in_qty, null,
               in_uom, in_user, 'RP', pik.invstatus, pik.inventoryclass, err, msg);
         if ((err != 'N') or (msg is not null)) then
            out_error := err;
            out_message := msg;
            rollback;
            return;
         end if;
      end if;
   else
--    update plates containing item
      open c_itemview;
      fetch c_itemview into itv;
  	   close c_itemview;

      for l in c_any_lp loop

         if ((l.serialnumber is not null
               and itv.serialrequired != 'Y' and itv.serialasncapture = 'Y')
         or  (l.useritem1 is not null
               and itv.user1required != 'Y' and itv.user1asncapture = 'Y')
         or  (l.useritem2 is not null
               and itv.user2required != 'Y' and itv.user2asncapture = 'Y')
         or  (l.useritem3 is not null
               and itv.user3required != 'Y' and itv.user3asncapture = 'Y')) then
            goto continue_loop;
         end if;

         if (l.quantity <= pik.quantity) then
--          use entire plate
            update plate
               set location = in_user,
                   status = 'M',
                   dropseq = in_dropseq,
                   taskid = in_taskid,
                   lasttask = 'RP',
                   lastoperator = in_user,
                   lastuser = in_user,
                   lastupdate = sysdate
               where lpid = l.lpid;
            if (l.parentlpid is not null) then
               zplp.detach_child_plate(l.parentlpid, l.lpid, in_user, null,
                     null, 'M', in_user, 'RP', msg);
               if (msg is not null) then
                  out_error := 'Y';
                  out_message := msg;
                  return;
               end if;
            end if;
            pik.quantity := pik.quantity - l.quantity;
            exit when (pik.quantity = 0);
         else
--          use part of plate
            make_lp_copy(l.lpid, in_custid, in_item, in_picked_to_lp, pik.quantity,
   					zcwt.lp_item_weight(l.lpid, in_custid, in_item, in_uom) * pik.quantity,
            		in_user, in_taskid, in_dropseq, in_plannedlp, msg);
            if (msg is not null) then
               out_error := 'Y';
               out_message := msg;
               return;
            end if;
            zrf.decrease_lp(l.lpid, in_custid, in_item, pik.quantity, null,
                  in_uom, in_user, 'RP', l.invstatus, l.inventoryclass, err, msg);
            if ((err != 'N') or (msg is not null)) then
               out_error := err;
               out_message := msg;
               rollback;
               return;
            end if;
            pik.quantity := 0;
            exit;
         end if;
      <<continue_loop>>
         null;
      end loop;
      if (pik.quantity != 0) then
         out_message := 'Qty not avail';
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

   select count(1) into out_lpcount
      from plate
      where facility = in_pickfac
        and location = in_pickloc
        and type = 'PA'
        and status != 'P';

   update subtasks
   set qtypicked = nvl(qtypicked, 0) + in_qty
         where rowid = chartorowid(in_subtask_rowid);

   if swappedlp.lpid is not null then
      pln := swappedlp;
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

   zrfpk.bump_custitemcount(in_custid, in_item, 'REPL', in_uom, in_qty, in_user, err, msg);
   out_error := err;
   out_message := msg;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end pick_a_repl;


procedure drop_a_repl
   (in_taskid    in number,
    in_facility  in varchar2,
    in_drop_loc  in varchar2,
    in_user      in varchar2,
    out_message  out varchar2)
is
   cursor c_drops is
      select rowid, type
         from plate
         where facility = in_facility
           and location = in_user
           and taskid = in_taskid;
   cursor c_subtasks is
      select rowid
         from subtasks
         where taskid = in_taskid;
	cursor c_loc(p_facility varchar2, p_locid varchar2) is
   	select loctype, section, equipprof
      	from location
         where facility = p_facility
           and locid = p_locid;
	loc c_loc%rowtype := null;
   l_msg varchar2(80) := null;
   l_found boolean;
begin
   out_message := null;

   open c_loc(in_facility, in_drop_loc);
   fetch c_loc into loc;
   l_found := c_loc%found;
   close c_loc;
   if not l_found then
   	out_message := 'Drop loc not found';
      return;
	end if;

-- update plates
   for d in c_drops loop
      if (d.type in ('MP','TO')) then
         update plate
            set location = in_drop_loc,
                status = 'A',
                lasttask = 'RP',
                lastoperator = in_user,
                lastuser = in_user,
                lastupdate = sysdate
            where lpid in
                  (select lpid from plate
                     start with rowid = d.rowid
                     connect by prior lpid = parentlpid);
      else
         update plate
            set location = in_drop_loc,
                status = 'A',
                lasttask = 'RP',
                lastoperator = in_user,
                lastuser = in_user,
                lastupdate = sysdate
            where rowid = d.rowid;
      end if;
   end loop;

   if loc.loctype in ('PND','XFR') then
--    intermediate loc, just update tasks/subtasks
      update tasks
         set priority = decode(loc.loctype, 'PND', prevpriority, '5'),
             curruserid = null,
             touserid = null,
             fromsection = loc.section,
             fromloc = in_drop_loc,
             fromprofile = loc.equipprof,
             lastuser = in_user,
             lastupdate = sysdate
         where taskid = in_taskid;

      update subtasks
         set priority = decode(loc.loctype, 'PND', prevpriority, '5'),
             curruserid = null,
             touserid = null,
             fromsection = loc.section,
             fromloc = in_drop_loc,
             fromprofile = loc.equipprof,
             lastuser = in_user,
             lastupdate = sysdate
         where taskid = in_taskid;
   else
--    cleanup subtask(s)
      for st in c_subtasks loop
         zdep.del_pick_subtask(st.rowid, in_user, l_msg);
         exit when (l_msg is not null);
      end loop;

--    cleanup task
      if l_msg is null then
         delete tasks
            where taskid = in_taskid;
      else
         out_message := l_msg;
      end if;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end drop_a_repl;


procedure purge_item_repls
   (in_facility   in varchar2,
    in_location   in varchar2,
    in_lpid       in varchar2,
    in_user       in varchar2,
    out_overpurge out varchar2,
    out_message   out varchar2)
is
   cursor c_lp is
      select custid, item, quantity, unitofmeasure, location, status
         from plate
         where type = 'PA'
         start with lpid = in_lpid
         connect by prior lpid = parentlpid;
   cursor c_pf(p_custid varchar2, p_item varchar2) is
      select maxqty, maxuom
         from itempickfronts
         where facility = in_facility
           and custid = p_custid
           and item = p_item
           and pickfront = in_location
           and nvl(dynamic,'N') = 'N';
   pf c_pf%rowtype;
   cursor c_rp(p_custid varchar2, p_item varchar2, p_qty number) is
      select S.rowid, S.qty, S.taskid, S.lpid
         from subtasks S, tasks T
         where S.tasktype = 'RP'
           and S.facility = in_facility
           and S.toloc = in_location
           and S.custid = p_custid
           and S.item = p_item
           and S.qty <= p_qty
           and T.taskid = S.taskid
           and T.priority != '0'
         order by S.qty desc;
   cursor c_rp_last(p_custid varchar2, p_item varchar2) is
      select S.rowid, S.qty, S.taskid, S.lpid
         from subtasks S, tasks T
         where S.tasktype = 'RP'
           and S.facility = in_facility
           and S.toloc = in_location
           and S.custid = p_custid
           and S.item = p_item
           and T.taskid = S.taskid
           and T.priority != '0'
         order by S.qty;
   rp c_rp%rowtype;
   rowfound boolean;
   msg varchar2(255);
   qtytasked subtasks.qty%type;
   qtyhere plate.quantity%type;
   qtymax itempickfronts.maxqty%type;
   qtyover plate.quantity%type;
begin
   out_overpurge := 'N';
   out_message := null;

   for lp in c_lp loop
      open c_pf(lp.custid, lp.item);
      fetch c_pf into pf;
      rowfound := c_pf%found;
      close c_pf;
      if not rowfound then
         goto continue_loop;              -- not a pickfront for the item
      end if;

      select nvl(sum(qty), 0) into qtytasked
         from subtasks
         where tasktype = 'RP'
           and facility = in_facility
           and toloc = in_location
           and custid = lp.custid
           and item = lp.item;

      if (qtytasked = 0) then
         goto continue_loop;              -- no repl tasks pending
      end if;

      select nvl(sum(quantity), 0) into qtyhere
         from plate
         where facility = in_facility
           and location = in_location
           and custid = lp.custid
           and item = lp.item
           and type = 'PA'
           and status = 'A';

      zbut.translate_uom(lp.custid, lp.item, pf.maxqty, pf.maxuom, lp.unitofmeasure,
            qtymax, msg);
      if (substr(msg, 1, 4) != 'OKAY') then
         out_message := 'UOM convert err';
         return;
      end if;

      if ((lp.location = in_location) and (lp.status = 'A')) then
         qtyover := qtyhere + qtytasked - qtymax;
      else
         qtyover := qtyhere + lp.quantity + qtytasked - qtymax;
      end if;

      if (qtyover <= 0) then
         goto continue_loop;              -- capacity not exceeded
      end if;

      loop
         open c_rp(lp.custid, lp.item, qtyover);
         fetch c_rp into rp;
         rowfound := c_rp%found;
         close c_rp;

--       we may not have come out even, and it's better to take down an extra
--       repl task than overfill the location
         if not rowfound then
            open c_rp_last(lp.custid, lp.item);
            fetch c_rp_last into rp;
            rowfound := c_rp_last%found;
            close c_rp_last;
            if rowfound then
               out_overpurge := 'Y';
            end if;
         end if;

         if rowfound then
            ztk.subtask_no_pick(rp.rowid, in_facility, lp.custid, rp.taskid, rp.lpid,
                  in_user, 'N', msg);
            qtyover := qtyover - rp.qty;
         end if;

         exit when ((not rowfound) or (qtyover <= 0) or (substr(msg, 1, 4) != 'OKAY'));
      end loop;

      if (substr(msg, 1, 4) != 'OKAY') then
         out_message := 'Task delete err';
         return;
      end if;

   <<continue_loop>>
      null;
   end loop;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end purge_item_repls;


end rfreplenishment;
/

show errors package body rfreplenishment;
exit;
