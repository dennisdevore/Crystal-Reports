create or replace package body alps.rfbldpallet as
--
-- $Id$
--


-- Private procedures


procedure verify_pallet_limit
   (in_lpid     in varchar2,
    out_error   out varchar2,
    out_message out varchar2)
is
   cursor c_ci(p_lpid varchar2) is
      select distinct custid, item
         from plate
         where custid is not null
           and item is not null
         start with lpid = p_lpid
         connect by prior lpid = parentlpid;
   ci c_ci%rowtype := null;
   cursor c_it(p_custid varchar2, p_item varchar2) is
      select pallet_qty, pallet_uom, limit_pallet_to_qty_yn, baseuom
         from custitem
         where custid = p_custid
           and item = p_item;
   it c_it%rowtype := null;
   cursor c_lp(p_lpid varchar2) is
      select quantity
         from plate
         where lpid = p_lpid;
   lp c_lp%rowtype;
begin
   out_error := 'N';
   out_message := null;

   open c_ci(in_lpid);
   loop
      fetch c_ci into ci;
      exit when c_ci%notfound;
      if c_ci%rowcount > 1 then        -- mixture, ignore limits
         close c_ci;
         return;
      end if;
   end loop;
   close c_ci;

   open c_it(ci.custid, ci.item);
   fetch c_it into it;
   close c_it;

   if nvl(it.limit_pallet_to_qty_yn,'N') = 'N' then   -- no limits or item not found
      return;
   end if;

   open c_lp(in_lpid);
   fetch c_lp into lp;
   close c_lp;

   if zlbl.uom_qty_conv(ci.custid, ci.item, it.pallet_qty, it.pallet_uom, it.baseuom)
         < lp.quantity then
      out_message := 'Exceeds pallet limit';
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end verify_pallet_limit;


-- Public procedures


procedure dupe_lp
   (in_fromlpid    in varchar2,
    in_tolpid      in varchar2,
    in_location    in varchar2,
    in_status      in varchar2,
    in_quantity    in number,
    in_user        in varchar2,
    in_disposition in varchar2,
    in_lasttask    in varchar2,
    in_taskid      in number,
    out_message    out varchar2)
is
   cursor c_lp is
      select custid, item, unitofmeasure, qtyentered,
             nvl(uomentered, unitofmeasure) as uomentered,
             zcwt.lp_item_weight(lpid, custid, item, unitofmeasure) as unitweight
         from plate
         where lpid = in_fromlpid;
   lp c_lp%rowtype;
begin
   out_message := null;

   open c_lp;
   fetch c_lp into lp;
   close c_lp;

-- convert baseuom qty into uomentered qty
   lp.qtyentered := zlbl.uom_qty_conv(lp.custid, lp.item, in_quantity, lp.unitofmeasure,
         lp.uomentered);
-- if exact conversion use uomentered else unitofmeasure
   if in_quantity != zlbl.uom_qty_conv(lp.custid, lp.item, lp.qtyentered, lp.uomentered,
         lp.unitofmeasure) then
      lp.qtyentered := in_quantity;
      lp.uomentered := lp.unitofmeasure;
   end if;

   insert into plate
      (lpid, item, custid, facility, location, status, holdreason,
       unitofmeasure, quantity, type, serialnumber, lotnumber, creationdate,
       manufacturedate, expirationdate, expiryaction, lastcountdate, po,
       condition, lastoperator, lasttask, fifodate, destlocation,
       destfacility, countryof, parentlpid, useritem1, useritem2, useritem3,
       disposition, lastuser, lastupdate, invstatus, qtyentered, itementered,
       uomentered, inventoryclass, loadno, stopno, shipno, orderid, shipid,
       weight, adjreason,
       controlnumber, qcdisposition, fromlpid, taskid, dropseq,
       fromshippinglpid, workorderseq, workordersubseq,
       parentfacility, parentitem, childfacility, childitem, recmethod,
       anvdate)
   select in_tolpid, P.item, P.custid, P.facility, in_location, in_status, P.holdreason,
       P.unitofmeasure, in_quantity, P.type, P.serialnumber, P.lotnumber, sysdate,
       P.manufacturedate, P.expirationdate, P.expiryaction, P.lastcountdate, P.po,
       P.condition, in_user, in_lasttask, P.fifodate, P.destlocation,
       P.destfacility, P.countryof, null, P.useritem1, P.useritem2, P.useritem3,
       in_disposition, in_user, sysdate, P.invstatus, lp.qtyentered, P.itementered,
       lp.uomentered, P.inventoryclass, P.loadno, P.stopno, P.shipno, P.orderid, P.shipid,
       in_quantity * lp.unitweight, P.adjreason,
       P.controlnumber, P.qcdisposition, in_fromlpid, in_taskid, P.dropseq,
       P.fromshippinglpid, P.workorderseq, P.workordersubseq,
       P.facility, P.item, null, null, P.recmethod,
       P.anvdate
      from plate P
      where P.lpid = in_fromlpid;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end dupe_lp;


procedure bld_pallet
   (in_tolpid      in varchar2,
    in_location    in varchar2,
    in_disposition in varchar2,
    in_bldop       in varchar2,
    in_fromid      in varchar2,
    in_fromtype    in varchar2,
    in_quantity    in number,
    in_uom         in varchar2,
    in_custid      in varchar2,
    in_id          in varchar2,
    in_id_is_lp    in varchar2,
    in_lotnumber   in varchar2,
    in_user        in varchar2,
    in_facility    in varchar2,
    in_invstatus   in varchar2,
    in_invclass    in varchar2,
    out_error      out varchar2,
    out_message    out varchar2)
is
   cursor c_lp(p_lpid varchar2) is
      select nvl(uomentered, unitofmeasure) as uomentered,
             zcwt.lp_item_weight(lpid, custid, item, unitofmeasure) as weight,
             parentlpid, quantity, custid, item, lotnumber,
             unitofmeasure, orderid, shipid, loadno, stopno, shipno,
             invstatus, inventoryclass, status, lpid, facility, location
         from plate
         where lpid = p_lpid;
   lp c_lp%rowtype;
   id c_lp%rowtype;
   rowfound boolean;
   cursor c_kids is
      select lpid, quantity, parentlpid, orderid, shipid, loadno,
             zcwt.lp_item_weight(lpid, custid, item, unitofmeasure) as weight,
             stopno, shipno, invstatus, inventoryclass, status,
             custid, item, lotnumber, unitofmeasure, facility, location
         from plate
         where custid = in_custid
           and item = in_id
           and nvl(lotnumber, 'x') = nvl(in_lotnumber, 'x')
           and unitofmeasure = in_uom
           and type = 'PA'
           and invstatus = in_invstatus
           and inventoryclass = in_invclass
         start with lpid = in_fromid
         connect by prior lpid = parentlpid
         order by quantity;
   cursor c_pkfr is
      select lpid, quantity, parentlpid, orderid, shipid, loadno, stopno, shipno,
             zcwt.lp_item_weight(lpid, custid, item, unitofmeasure) as weight, invstatus,
             inventoryclass, custid, item, lotnumber, unitofmeasure, facility, location
         from plate
         where facility = in_facility
           and location = in_fromid
           and custid = in_custid
           and item = in_id
           and nvl(lotnumber, 'x') = nvl(in_lotnumber, 'x')
           and unitofmeasure = in_uom
           and type = 'PA'
           and status = 'A'
           and invstatus = in_invstatus
           and inventoryclass = in_invclass
         order by quantity;
   err varchar(1);
   msg varchar(80);
   enteredqty plate.qtyentered%type;
   qtyneeded number := in_quantity;
   newlpid plate.lpid%type;
   palpid plate.lpid%type := in_tolpid;
   itemweight custitem.weight%type;
   v_facility plate.facility%type;
   v_location plate.location%type;
begin
   out_error := 'N';
   out_message := null;

   open c_lp(in_tolpid);
   fetch c_lp into lp;
   rowfound := c_lp%found;
   close c_lp;

   if (in_bldop in (OP_INSERT, OP_MULTI, OP_UNDELMP)) then
      if rowfound then
         out_message := 'To already used';
         return;
      end if;
   else
      if not rowfound then
         out_message := 'To not found';
         return;
      end if;
      if (lp.status != 'A') and (zlbl.is_lp_unprocessed_autogen(in_tolpid) = 'N') then
         out_message := 'To not avail';
         return;
      end if;
   end if;

-- Taking from a pick front - ID must be an item
-- Since LPs are "not visible" in a pick front, there is no need to preserve them
   if (in_fromtype = 'PF') then
      for p in c_pkfr loop
         v_facility := p.facility;
         v_location := p.location;
         if (c_pkfr%rowcount = 1) then

--          Building a plate, use 1st plate to build new plate
            if (in_bldop = OP_INSERT) then
               dupe_lp(p.lpid, in_tolpid, in_location, 'A', in_quantity, in_user,
                     in_disposition, 'BL', null, msg);
               if (msg is not null) then
                  out_error := 'Y';
                  out_message := msg;
                  return;
               end if;

               open c_lp(in_tolpid);
               fetch c_lp into lp;
               close c_lp;

               update plate
                  set quantity = 0,
                      weight = 0
                  where lpid = in_tolpid;

--          Updating a plate, only update existing plate once
            elsif (in_bldop = OP_UPDATE) then
               zbut.translate_uom(in_custid, in_id, in_quantity, in_uom, lp.uomentered,
                     enteredqty, msg);
               if (substr(msg, 1, 4) != 'OKAY') then
                  enteredqty := in_quantity;
               end if;

               update plate
                  set qtyentered = nvl(qtyentered, 0) + enteredqty,
                      lasttask = 'BL'
                  where lpid = in_tolpid;

--          Either mixing on a plate, attaching to a parent or building a new multi
            else
               msg := null;
--             Mixing on a plate
               if (in_bldop = OP_MIX) then
                  zplp.morph_lp_to_multi(in_tolpid, in_user, msg);

--             Building a new multi
               elsif (in_bldop in (OP_MULTI, OP_UNDELMP)) then
                  if in_bldop = OP_UNDELMP then
                     delete from deletedplate
                        where lpid = palpid;
                  end if;
                  zplp.build_empty_parent(palpid, in_facility, in_location, 'A',
                        'MP', in_user, in_disposition, in_custid, in_id, p.orderid,
                        p.shipid, p.loadno, p.stopno, p.shipno, in_lotnumber,
                        p.invstatus, p.inventoryclass, msg);
               end if;

--             Any case
               if (msg is null) then
                  zrf.get_next_lpid(newlpid, msg);
                  if (msg is null) then
                     dupe_lp(p.lpid, newlpid, in_location, 'A', 0, in_user,
                           in_disposition, 'BL', null, msg);
                     if (msg is null) then
                        zplp.attach_child_plate(palpid, newlpid, in_location, 'A',
                              in_user, msg);
                     end if;
                  end if;
               end if;
               if (msg is not null) then
                  out_error := 'Y';
                  out_message := msg;
                  return;
               end if;
            end if;
         end if;

         itemweight := zcwt.lp_item_weight(p.lpid, p.custid, p.item, p.unitofmeasure);

         update plate
            set quantity = nvl(quantity, 0) + least(qtyneeded, p.quantity),
                weight = nvl(weight, 0) + (least(qtyneeded, p.quantity) * itemweight),
                lastoperator = in_user,
                lastuser = in_user,
                lasttask = 'BL',
                lastupdate = sysdate
            where lpid = in_tolpid;

         if lp.parentlpid is not null then
            update plate
               set quantity = nvl(quantity, 0) + least(qtyneeded, p.quantity),
                   weight = nvl(weight, 0) + (least(qtyneeded, p.quantity) * itemweight),
                   lastoperator = in_user,
                   lastuser = in_user,
                   lastupdate = sysdate
               where lpid = lp.parentlpid;
         end if;

         zrf.decrease_lp(p.lpid, in_custid, in_id, least(qtyneeded, p.quantity),
               in_lotnumber, in_uom, in_user, 'BL', p.invstatus, p.inventoryclass, err, msg);
         if (msg is not null) then
            out_error := err;
            out_message := msg;
            return;
         end if;

         if ((nvl(p.lotnumber,'(none)') != nvl(lp.lotnumber,'(none)')) or
             (nvl(p.invstatus,'(none)') != nvl(lp.invstatus,'(none)')) or
             (nvl(p.inventoryclass,'(none)') != nvl(lp.inventoryclass,'(none)'))) then
            zbill.add_asof_inventory(in_facility, lp.custid, lp.item, lp.lotnumber, lp.unitofmeasure,
                  trunc(sysdate), least(qtyneeded, p.quantity), least(qtyneeded, p.quantity) * itemweight, 'Bld Pallet', 'AD', lp.inventoryclass,
                  lp.invstatus, lp.orderid, lp.shipid, lp.lpid, in_user, msg);
            zbill.add_asof_inventory(in_facility, p.custid, p.item, p.lotnumber, p.unitofmeasure,
                  trunc(sysdate), least(qtyneeded, p.quantity) * -1, (least(qtyneeded, p.quantity) * itemweight) * -1, 'Bld Pallet', 'AD', p.inventoryclass,
                  p.invstatus, p.orderid, p.shipid, p.lpid, in_user, msg);
         end if;

         qtyneeded := qtyneeded - least(qtyneeded, p.quantity);
         exit when (qtyneeded = 0);
      end loop;

      if (qtyneeded != 0) then
         out_message := 'Qty not avail';
      else
         verify_pallet_limit(palpid, out_error, out_message);
      end if;
      if (v_facility is not null and v_location is not null) then
        zloc.reset_location_status(v_facility, v_location, out_error, out_message);
      end if;
      open c_lp(in_tolpid);
      fetch c_lp into lp;
      rowfound := c_lp%found;
      close c_lp;
      if (rowfound) then
        zloc.reset_location_status(lp.facility, lp.location, out_error, out_message);
      end if;
      return;
   end if;

-- ID is an LP
   if (in_id_is_lp = 'Y') then
      open c_lp(in_id);
      fetch c_lp into id;
      rowfound := c_lp%found;
      close c_lp;

      if not rowfound then
         out_message := 'From not found';
         return;
      end if;
      if (id.status != 'A') and (zlbl.is_lp_unprocessed_autogen(in_id) = 'N') then
         out_message := 'From not avail';
         return;
      end if;

--    Building a plate
      if (in_bldop = OP_INSERT) then
         dupe_lp(in_id, in_tolpid, in_location, id.status, id.quantity, in_user,
               in_disposition, 'BL', null, msg);
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
         else
            zrf.decrease_lp(in_id, id.custid, id.item, id.quantity, id.lotnumber,
                  id.unitofmeasure, in_user, 'BL', id.invstatus, id.inventoryclass,
                  out_error, out_message);
         end if;

         open c_lp(in_tolpid);
         fetch c_lp into lp;
         close c_lp;

--    Updating a plate
      elsif (in_bldop = OP_UPDATE) then
         zbut.translate_uom(id.custid, id.item, id.quantity, id.unitofmeasure,
               lp.uomentered, enteredqty, msg);
         if (substr(msg, 1, 4) != 'OKAY') then
            enteredqty := id.quantity;
         end if;

         update plate
            set quantity = nvl(quantity, 0) + id.quantity,
                qtyentered = nvl(qtyentered, 0) + enteredqty,
                weight = nvl(weight, 0) + (id.weight * id.quantity),
                lastoperator = in_user,
                lastuser = in_user,
                lasttask = 'BL',
                lastupdate = sysdate
            where lpid = in_tolpid;

         if (lp.parentlpid is not null) then
            update plate
               set quantity = nvl(quantity, 0) + id.quantity,
                   weight = nvl(weight, 0) + (id.weight * id.quantity),
                   lastoperator = in_user,
                   lastuser = in_user,
                   lastupdate = sysdate
               where lpid = lp.parentlpid;
         end if;

         zrf.decrease_lp(in_id, id.custid, id.item, id.quantity, id.lotnumber,
               id.unitofmeasure, in_user, 'BL', id.invstatus, id.inventoryclass,
               out_error, out_message);

         if ((nvl(id.lotnumber,'(none)') != nvl(lp.lotnumber,'(none)')) or
             (nvl(id.invstatus,'(none)') != nvl(lp.invstatus,'(none)')) or
             (nvl(id.inventoryclass,'(none)') != nvl(lp.inventoryclass,'(none)'))) then
            zbill.add_asof_inventory(in_facility, lp.custid, lp.item, lp.lotnumber, lp.unitofmeasure,
                  trunc(sysdate), id.quantity, id.weight * id.quantity, 'Bld Pallet', 'AD', lp.inventoryclass,
                  lp.invstatus, lp.orderid, lp.shipid, lp.lpid, in_user, msg);
            zbill.add_asof_inventory(in_facility, id.custid, id.item, id.lotnumber, id.unitofmeasure,
                  trunc(sysdate), id.quantity * -1, (id.weight * id.quantity) * -1, 'Bld Pallet', 'AD', id.inventoryclass,
                  id.invstatus, id.orderid, id.shipid, id.lpid, in_user, msg);
         end if;
--    Attaching to a parent
      elsif (in_bldop = OP_ATTACH) then
         zplp.attach_child_plate(in_tolpid, in_id, null, null, in_user, msg);
         if ((msg is null) and (id.parentlpid is not null)) then
            zplp.decrease_parent(id.parentlpid, id.quantity, id.weight * id.quantity,
            		in_user, null, msg);
				if (msg is null) then
            	zplp.balance_master(id.parentlpid, null, in_user, msg);
            end if;
         end if;
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
         end if;

--    Mixing on a plate
      elsif (in_bldop = OP_MIX) then
         zplp.morph_lp_to_multi(in_tolpid, in_user, msg);
         if (msg is null) then
            zplp.attach_child_plate(in_tolpid, in_id, null, null, in_user, msg);
            if ((msg is null) and (id.parentlpid is not null)) then
               zplp.decrease_parent(id.parentlpid, id.quantity, id.weight * id.quantity,
               		in_user, null, msg);
				   if (msg is null) then
            	   zplp.balance_master(id.parentlpid, null, in_user, msg);
               end if;
            end if;
         end if;
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
         end if;

--    Building a new multi or undeleting an existing multi
      else
         if in_bldop = OP_UNDELMP then
            delete from deletedplate
               where lpid = palpid;
         end if;
         zplp.build_empty_parent(palpid, in_facility, in_location, id.status, 'MP',
               in_user, in_disposition, id.custid, id.item, id.orderid,
               id.shipid, id.loadno, id.stopno, id.shipno, id.lotnumber, id.invstatus,
               id.inventoryclass, msg);
         if (msg is null) then
            zplp.attach_child_plate(palpid, in_id, null, null, in_user, msg);
            if ((msg is null) and (id.parentlpid is not null)) then
               zplp.decrease_parent(id.parentlpid, id.quantity, id.weight * id.quantity,
               		in_user, null, msg);
				   if (msg is null) then
            	   zplp.balance_master(id.parentlpid, null, in_user, msg);
               end if;
            end if;
         end if;
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
         end if;
      end if;
      verify_pallet_limit(palpid, out_error, out_message);
      zloc.reset_location_status(id.facility, id.location, out_error, out_message);
      open c_lp(in_tolpid);
      fetch c_lp into lp;
      rowfound := c_lp%found;
      close c_lp;
      if (rowfound) then
        zloc.reset_location_status(lp.facility, lp.location, out_error, out_message);
      end if;
      return;
   end if;

-- ID is an item
-- Building a plate
   if (in_bldop = OP_INSERT) then
      for k in c_kids loop
         v_facility := k.facility;
         v_location := k.location;

--       Use 1st plate to build new plate
         if (c_kids%rowcount = 1) then
            dupe_lp(k.lpid, in_tolpid, in_location, k.status, in_quantity, in_user,
                  in_disposition, 'BL', null, msg);
            if (msg is not null) then
               out_error := 'Y';
               out_message := msg;
               return;
            end if;

            open c_lp(in_tolpid);
            fetch c_lp into lp;
            close c_lp;

            update plate
               set quantity = 0,
                   weight = 0
               where lpid = in_tolpid;
         end if;

         itemweight := zcwt.lp_item_weight(k.lpid, k.custid, k.item, k.unitofmeasure);

         update plate
            set quantity = nvl(quantity, 0) + least(qtyneeded, k.quantity),
                weight = nvl(weight, 0) + (least(qtyneeded, k.quantity) * itemweight),
                lastoperator = in_user,
                lastuser = in_user,
                lasttask = 'BL',
                lastupdate = sysdate
            where lpid = in_tolpid;

         zrf.decrease_lp(k.lpid, in_custid, in_id, least(qtyneeded, k.quantity),
               in_lotnumber, in_uom, in_user, 'BL', k.invstatus, k.inventoryclass, err, msg);
         if (msg is not null) then
            out_error := err;
            out_message := msg;
            return;
         end if;
         qtyneeded := qtyneeded - least(qtyneeded, k.quantity);
         exit when (qtyneeded = 0);
      end loop;
      if (qtyneeded != 0) then
         out_message := 'Qty not avail';
      else
         verify_pallet_limit(palpid, out_error, out_message);
      end if;
      if (v_facility is not null and v_location is not null) then
        zloc.reset_location_status(v_facility, v_location, out_error, out_message);
      end if;
      open c_lp(in_tolpid);
      fetch c_lp into lp;
      rowfound := c_lp%found;
      close c_lp;
      if (rowfound) then
        zloc.reset_location_status(lp.facility, lp.location, out_error, out_message);
      end if;
      return;
   end if;

-- Updating a plate
   if (in_bldop = OP_UPDATE) then
      zbut.translate_uom(in_custid, in_id, in_quantity, in_uom, lp.uomentered,
            enteredqty, msg);
      if (substr(msg, 1, 4) != 'OKAY') then
         enteredqty := in_quantity;
      end if;

      update plate
         set qtyentered = nvl(qtyentered, 0) + enteredqty,
             lasttask = 'BL'
         where lpid = in_tolpid;

      for k in c_kids loop
         v_facility := k.facility;
         v_location := k.location;
         itemweight := zcwt.lp_item_weight(k.lpid, k.custid, k.item, k.unitofmeasure);

         update plate
            set quantity = nvl(quantity, 0) + least(qtyneeded, k.quantity),
                weight = nvl(weight, 0) + (itemweight * least(qtyneeded, k.quantity)),
                lastoperator = in_user,
                lastuser = in_user,
                lasttask = 'BL',
                lastupdate = sysdate
            where lpid = in_tolpid;

         zrf.decrease_lp(k.lpid, in_custid, in_id, least(qtyneeded, k.quantity),
               in_lotnumber, in_uom, in_user, 'BL', k.invstatus, k.inventoryclass, err, msg);
         if (msg is not null) then
            out_error := err;
            out_message := msg;
            return;
         end if;

         if (lp.parentlpid is not null) then
            update plate
               set quantity = nvl(quantity, 0) + least(qtyneeded, k.quantity),
                   weight = nvl(weight, 0) + (itemweight * least(qtyneeded, k.quantity)),
                   lastoperator = in_user,
                   lastuser = in_user,
                   lastupdate = sysdate
               where lpid = lp.parentlpid;
         end if;

         if ((nvl(k.lotnumber,'(none)') != nvl(lp.lotnumber,'(none)')) or
             (nvl(k.invstatus,'(none)') != nvl(lp.invstatus,'(none)')) or
             (nvl(k.inventoryclass,'(none)') != nvl(lp.inventoryclass,'(none)'))) then
            zbill.add_asof_inventory(in_facility, lp.custid, lp.item, lp.lotnumber, lp.unitofmeasure,
                  trunc(sysdate), least(qtyneeded, k.quantity), itemweight * least(qtyneeded, k.quantity), 'Bld Pallet', 'AD', lp.inventoryclass,
                  lp.invstatus, lp.orderid, lp.shipid, lp.lpid, in_user, msg);
            zbill.add_asof_inventory(in_facility, k.custid, k.item, k.lotnumber, k.unitofmeasure,
                  trunc(sysdate), least(qtyneeded, k.quantity) * -1, (itemweight * least(qtyneeded, k.quantity)) * -1, 'Bld Pallet', 'AD', k.inventoryclass,
                  k.invstatus, k.orderid, k.shipid, k.lpid, in_user, msg);
         end if;

         qtyneeded := qtyneeded - least(qtyneeded, k.quantity);
         exit when (qtyneeded = 0);
      end loop;
      if (qtyneeded != 0) then
         out_message := 'Qty not avail';
      else
         verify_pallet_limit(palpid, out_error, out_message);
      end if;
      if (v_facility is not null and v_location is not null) then
        zloc.reset_location_status(v_facility, v_location, out_error, out_message);
      end if;
      open c_lp(in_tolpid);
      fetch c_lp into lp;
      rowfound := c_lp%found;
      close c_lp;
      if (rowfound) then
        zloc.reset_location_status(lp.facility, lp.location, out_error, out_message);
      end if;
      return;
   end if;

-- Either mixing on a plate, attaching to a parent or building a new multi.
-- LPs are "visible" so this will be very similar to the pick front processing
-- with the addition that LPs will be preserved as much as possible

   for k in c_kids loop

      v_facility := k.facility;
      v_location := k.location;
--    Use 1st plate to build new plate
      if (c_kids%rowcount = 1) then
         msg := null;
--       Mixing on a plate
         if (in_bldop = OP_MIX) then
            zplp.morph_lp_to_multi(in_tolpid, in_user, msg);

--       Building a new multi
         elsif (in_bldop in (OP_MULTI, OP_UNDELMP)) then
            if in_bldop = OP_UNDELMP then
               delete from deletedplate
                  where lpid = palpid;
            end if;
            zplp.build_empty_parent(palpid, in_facility, in_location, k.status, 'MP',
                  in_user, in_disposition, in_custid, in_id, k.orderid,
                  k.shipid, k.loadno, k.stopno, k.shipno, in_lotnumber,
                  k.invstatus, k.inventoryclass, msg);
         end if;
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
            return;
         end if;
      end if;

--    Use all of child
      if (k.quantity <= qtyneeded) then

         zplp.attach_child_plate(palpid, k.lpid, in_location, k.status, in_user, msg);
         if ((msg is null) and (k.parentlpid is not null)) then
            zplp.decrease_parent(k.parentlpid, k.quantity, k.quantity * k.weight,
                  in_user, null, msg);
				if (msg is null) then
            	zplp.balance_master(k.parentlpid, null, in_user, msg);
            end if;
         end if;
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
            return;
         end if;
         qtyneeded := qtyneeded - k.quantity;

--    Only use part of child
      else
         zrf.get_next_lpid(newlpid, msg);
         if (msg is null) then
            dupe_lp(k.lpid, newlpid, in_location, k.status, qtyneeded, in_user,
                  in_disposition, 'BL', null, msg);
            if (msg is null) then
               zplp.attach_child_plate(palpid, newlpid, in_location, k.status, in_user, msg);
            end if;
         end if;
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
            return;
         end if;
         zrf.decrease_lp(k.lpid, in_custid, in_id, qtyneeded, in_lotnumber,
               in_uom, in_user, 'BL', k.invstatus, k.inventoryclass, err, msg);
         if (msg is not null) then
            out_error := err;
            out_message := msg;
            return;
         end if;
         qtyneeded := 0;
      end if;
      exit when (qtyneeded = 0);
   end loop;
   if (qtyneeded != 0) then
      out_message := 'Qty not avail';
   else
      verify_pallet_limit(palpid, out_error, out_message);
   end if;
   if (v_facility is not null and v_location is not null) then
    zloc.reset_location_status(v_facility, v_location, out_error, out_message);
   end if;
   open c_lp(in_tolpid);
   fetch c_lp into lp;
   rowfound := c_lp%found;
   close c_lp;
   if (rowfound) then
     zloc.reset_location_status(lp.facility, lp.location, out_error, out_message);
   end if;
   return;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end bld_pallet;


end rfbldpallet;
/

show errors package body rfbldpallet;
exit;
