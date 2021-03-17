create or replace package body alps.rfloading as
--
-- $Id$
--


-- Private procedures


procedure tot_and_mship_mast
   (in_shipid   in varchar2,
    in_mship    in varchar2,
    in_weight   in number,
    out_message out varchar2)
is
   cursor c_parent (p_lpid varchar2) is
      select parentlpid
         from shippingplate
         where lpid = p_lpid;
   cursor c_all_groups (p_lpid varchar2) is
      select lpid
         from shippingplate
         where type not in ('F', 'P')
         start with lpid = p_lpid
         connect by prior lpid = parentlpid;
   cursor c_mlp (p_lpid varchar2) is
      select weight, fromlpid
         from shippingplate
         where lpid = p_lpid;
   mlp c_mlp%rowtype;
   cursor c_lp (p_lpid varchar2) is
      select parentlpid
         from plate
         where lpid = p_lpid;
   loopcnt integer := 0;
   mlip shippingplate.lpid%type;
   plip shippingplate.lpid%type;
   msg varchar2(80);
begin
   out_message := null;

-- this code is just to make sure that we have a shippingplate
   if (substr(in_shipid, -1, 1) = 'S') then
      mlip := in_shipid;
   else
      open c_lp(in_shipid);
      fetch c_lp into mlip;
      close c_lp;
   end if;

-- find the topmost parent
   loop
      open c_parent(mlip);
      fetch c_parent into plip;
      close c_parent;
      loopcnt := loopcnt + 1;          -- just in case
      exit when ((plip is null) or (plip = mlip) or (loopcnt > 255));
      mlip := plip;
   end loop;

-- sum all quantites and weights
   for g in c_all_groups(mlip) loop
      update shippingplate
         set (quantity, weight) =
            (select nvl(sum(quantity), 0), nvl(sum(weight), 0)
               from shippingplate
               where type in ('F', 'P')
               start with lpid = g.lpid
               connect by prior lpid = parentlpid)
         where lpid = g.lpid;
   end loop;

   if (in_mship = 'Y') then
      open c_mlp(mlip);
      fetch c_mlp into mlp;
      close c_mlp;

      if (in_weight != mlp.weight) then
         if (in_weight = 0) then
            zmn.stage_carton(mlp.fromlpid, 'split', msg);
         elsif (mlp.weight = 0) then
            delete multishipdtl
               where cartonid = mlp.fromlpid;
         else
            update multishipdtl
               set estweight = estweight - in_weight + mlp.weight
               where cartonid = mlp.fromlpid;
         end if;
      end if;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end tot_and_mship_mast;


procedure split_shippingplate
   (in_shipid     in varchar2,
    in_qty        in number,
    in_mastid     in varchar2,
    in_type       in varchar2,
    in_cartontype in varchar2,
    in_user       in varchar2,
    out_message   out varchar2)
is
   cursor c_full is
      select type, fromlpid,
             zcwt.ship_lp_item_weight(lpid, custid, item, unitofmeasure) weight,
             custid, item, lotnumber, unitofmeasure, invstatus, inventoryclass
         from shippingplate
         where lpid = in_shipid;
   f c_full%rowtype;
   cursor c_lp(p_lpid varchar2) is
      select type
         from plate
         where lpid = p_lpid;
   lp c_lp%rowtype := null;
   partid shippingplate.lpid%type;
   err varchar2(1);
   msg varchar2(80);
   builtmlip shippingplate.lpid%type;
begin
   out_message := null;

-- build the new "partial pick" shippingplate
   zsp.get_next_shippinglpid(partid, msg);
   if (msg is not null) then
      out_message := msg;
      return;
   end if;

   open c_full;
   fetch c_full into f;
   close c_full;
   insert into shippingplate
      (lpid, item, custid, facility, location,
       status, holdreason, unitofmeasure, quantity, type,
       fromlpid, serialnumber, lotnumber, parentlpid, useritem1,
       useritem2, useritem3, lastuser, lastupdate, invstatus,
       qtyentered, orderitem, uomentered, inventoryclass, loadno,
       stopno, shipno, orderid, shipid, weight,
       ucc128, labelformat, taskid, dropseq, orderlot,
       pickuom, pickqty, trackingno, cartonseq, manufacturedate,
       expirationdate)
     select partid, S.item, S.custid, S.facility, S.location,
            S.status, S.holdreason, S.unitofmeasure, in_qty, 'P',
            S.fromlpid, S.serialnumber, S.lotnumber, null, S.useritem1,
            S.useritem2, S.useritem3, in_user, sysdate, S.invstatus,
            0, S.orderitem, S.uomentered, S.inventoryclass, S.loadno,
            S.stopno, S.shipno, S.orderid, S.shipid, in_qty * f.weight,
            S.ucc128, S.labelformat, S.taskid, S.dropseq, S.orderlot,
            S.pickuom, 0, S.trackingno, S.cartonseq, S.manufacturedate,
            S.expirationdate
        from shippingplate S
        where S.lpid = in_shipid;

-- Hook the new partial onto the parent
   if in_type = 'C' then
      zrfpk.build_carton(in_mastid, partid, in_user, 'N', null, in_cartontype, msg);
   else
      zrfpk.build_mast_shlp(in_mastid, partid, in_user, null, builtmlip, msg);
   end if;
   if (msg is not null) then
      out_message := msg;
      return;
   end if;

-- Decrease split shippingplate
   update shippingplate
      set quantity = nvl(quantity, 0) - in_qty,
          weight = nvl(weight, 0) - (in_qty * f.weight),
          lastuser = in_user,
          lastupdate = sysdate
      where lpid = in_shipid;

-- If split was a full pick, decrease its plate (if it exists and is not a tote)
   if (f.type = 'F') then
      open c_lp(f.fromlpid);
      fetch c_lp into lp;
      close c_lp;
      if nvl(lp.type, 'TO') != 'TO' then
         zrf.decrease_lp(f.fromlpid, f.custid, f.item, in_qty, f.lotnumber,
               f.unitofmeasure, in_user, null, f.invstatus, f.inventoryclass, err, msg);
         out_message := msg;
      end if;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end split_shippingplate;


procedure unload_slip
   (in_slp       in varchar2,
    in_loc       in varchar2,
    in_user      in varchar2,
    out_message  out varchar2)
is
   cursor c_sh is
      select orderid, shipid, stopno, shipno, quantity, orderitem,
             orderlot, rowid, loadno, custid, weight,
             zci.item_cube(custid, orderitem, unitofmeasure) cube,
             facility
         from shippingplate
         where lpid = in_slp;
   s c_sh%rowtype;
   cursor c_itemview(p_custid varchar2, p_item varchar2) is
      select useramt1
         from custitemview
         where custid = p_custid
           and item = p_item;
   itv c_itemview%rowtype;
   oldorderstatus orderhdr.orderstatus%type;
   neworderstatus orderhdr.orderstatus%type;
   oldloadstatus loads.loadstatus%type;
   newloadstatus loads.loadstatus%type;
   msg varchar2(255);
   errorno integer;
   cnt integer;
begin
   out_message := null;

   open c_sh;
   fetch c_sh into s;
   if c_sh%notfound then
      close c_sh;
      out_message := 'SLP not found';
      return;
   end if;
   close c_sh;
   open c_itemview(s.custid, s.orderitem);
   fetch c_itemview into itv;
   close c_itemview;

-- update order detail
   update orderdtl
      set qtyship = nvl(qtyship, 0) - s.quantity,
          weightship = nvl(weightship, 0) - s.weight,
          cubeship = nvl(cubeship, 0) - (s.quantity * s.cube),
          amtship = nvl(amtship, 0) - (s.quantity * zci.item_amt(custid,orderid,shipid,item,lotnumber)),
          lastuser = in_user,
          lastupdate = sysdate
      where orderid = s.orderid
        and shipid = s.shipid
        and item = s.orderitem
        and nvl(lotnumber, '(none)') = nvl(s.orderlot, '(none)');

-- update loadstopship
   update loadstopship
      set qtyship = nvl(qtyship, 0) - s.quantity,
          weightship = nvl(weightship, 0) - s.weight,
          weightship_kgs = nvl(weightship_kgs,0)
                         - nvl(zwt.from_lbs_to_kgs(s.custid,s.weight),0),
          cubeship = nvl(cubeship, 0) - (s.quantity * s.cube),
          amtship = nvl(amtship, 0) - (s.quantity * zci.item_amt(s.custid,s.orderid,s.shipid,s.orderitem,s.orderlot)),
          lastuser = in_user,
          lastupdate = sysdate
      where loadno = s.loadno
        and stopno = s.stopno
        and shipno = s.shipno;

-- update shippingplate
   zrf.move_shippingplate(s.rowid, in_loc, 'S', in_user, null, msg);
   if (msg is not null) then
      out_message := msg;
      return;
   end if;

-- update orderhdr status
   select orderstatus, decode(qtycommit, 0, decode(qtyship, 0, zrf.ORD_PICKED, zrf.ORD_LOADING),
          zrf.ORD_PICKING)
      into oldorderstatus, neworderstatus
      from orderhdr
      where orderid = s.orderid
        and shipid = s.shipid;
   if ((neworderstatus < oldorderstatus) and (oldorderstatus != 'X')) then
      update orderhdr
         set orderstatus = neworderstatus,
             lastuser = in_user,
             lastupdate = sysdate
         where orderid = s.orderid
           and shipid = s.shipid;
   end if;

-- update loadstop status
   select loadstopstatus
      into oldloadstatus
      from loadstop
      where loadno = s.loadno
        and stopno = s.stopno;

   select max(orderstatus) into newloadstatus
      from orderhdr
      where loadno = s.loadno
        and stopno = s.stopno
        and fromfacility = s.facility;

-- if the stop doesn't change, the load won't
   if ((newloadstatus < oldloadstatus) and (oldloadstatus != 'X')) then
      update loadstop
         set loadstopstatus = newloadstatus,
             lastuser = in_user,
             lastupdate = sysdate
         where loadno = s.loadno
           and stopno = s.stopno;

      update loads
         set loadstatus = newloadstatus,
             lastuser = in_user,
             lastupdate = sysdate
         where loadno = s.loadno
           and loadstatus > newloadstatus;
   end if;

   if (oldorderstatus = 'X') then
      select count(1) into cnt
         from shippingplate
         where orderid = s.orderid
           and shipid = s.shipid
           and status = 'L';
      if (cnt = 0) then
         zld.deassign_order_from_load(s.orderid, s.shipid, s.facility, in_user,
               'N', errorno, msg);
      end if;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end unload_slip;


procedure unload_ctn_kids
   (in_ctnid    in varchar2,
    in_loc      in varchar2,
    in_user     in varchar2,
    out_message out varchar2)
is
   msg varchar2(80);
   cursor c_kids is
      select lpid
         from shippingplate
         where parentlpid = in_ctnid;
begin
   out_message := null;

   for k in c_kids loop
      unload_slip(k.lpid, in_loc, in_user, msg);
      if (msg is not null) then
         out_message := msg;
         return;
      end if;
   end loop;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end unload_ctn_kids;


-- Public procedures


procedure set_ancestor_data
   (in_lpid     in varchar2,
    out_message out varchar2)
is
   cursor c_mx is
      select max(level)-1 lvl
         from shippingplate
         start with lpid = in_lpid
         connect by prior lpid = parentlpid;
   mx c_mx%rowtype;
   cursor c_parent(p_level number) is
      select rowid, lpid, custid, item, lotnumber, orderid, shipid
         from shippingplate
         where level = p_level
         start with lpid = in_lpid
         connect by prior lpid = parentlpid;
   cursor c_child(p_lpid varchar2) is
      select custid, item, lotnumber, orderid, shipid
         from shippingplate
         where parentlpid = p_lpid;
   pa_cordid waves.wave%type;
   ch_cordid waves.wave%type;
begin
   out_message := null;

   open c_mx;
   fetch c_mx into mx;
   close c_mx;

   while (mx.lvl > 0)
   loop
      for p in c_parent(mx.lvl) loop
         for c in c_child(p.lpid) loop
            if c_child%rowcount = 1 then
               p.custid := c.custid;
               p.item := c.item;
               p.lotnumber := c.lotnumber;
               if zcord.cons_orderid(c.orderid, c.shipid) = 0 then
               p.orderid := c.orderid;
               p.shipid := c.shipid;
            end if;
            end if;

            if (nvl(p.custid, '(none)') != nvl(c.custid, '(none)')) then
               p.custid := null;
               p.item := null;
               p.lotnumber := null;
            elsif (nvl(p.item, '(none)') != nvl(c.item, '(none)')) then
               p.item := null;
               p.lotnumber := null;
            elsif (nvl(p.lotnumber, '(none)') != nvl(c.lotnumber, '(none)')) then
               p.lotnumber := null;
            end if;

            if (nvl(p.orderid, 0) != nvl(c.orderid, 0)) then
               pa_cordid := zcord.cons_orderid(p.orderid, p.shipid);
               ch_cordid := zcord.cons_orderid(c.orderid, c.shipid);
               if (pa_cordid = ch_cordid) and (pa_cordid != 0) then
                  p.orderid := pa_cordid;
               else
                  p.orderid := 0;
               end if;
               p.shipid := 0;
            elsif (nvl(p.shipid, 0) != nvl(c.shipid, 0)) then
               p.shipid := 0;
            end if;
         end loop;

         update shippingplate
            set item = p.item,
                lotnumber = p.lotnumber,
                custid = p.custid,
                orderid = p.orderid,
                shipid = p.shipid
            where rowid = p.rowid;
      end loop;
      mx.lvl := mx.lvl - 1;
   end loop;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end set_ancestor_data;


procedure start_loading
   (in_facility  in varchar2,
    in_dockdoor  in varchar2,
    in_equipment in varchar2,
    in_user      in varchar2,
    out_loadno   out number,
    out_checkid  out varchar2,
    out_overage  out varchar2,
    out_error    out varchar2,
    out_message  out varchar2)
is
   l_locstatus location.status%type;
   l_loctype location.loctype%type;
   l_err varchar2(1);
   l_msg varchar2(80);
   l_loadno loads.loadno%type;
   l_loadtype loads.loadtype%type;
   l_loadstatus loads.loadstatus%type;
   cursor c_ld is
      select sum(nvl(qtyship,0)) as qtyship,
             sum(nvl(qtypick,0)) as qtypick,
             sum(nvl(qtycommit,0)) as qtycommit,
             sum(nvl(qtyorder,0)) as qtyorder
         from orderhdr
         where loadno = l_loadno
           and fromfacility = in_facility;
   ld c_ld%rowtype;
begin
   out_error := 'N';
   out_message := null;
   out_loadno := 0;
   out_overage := 'N';

   zrf.verify_location(in_facility, in_dockdoor, in_equipment, l_locstatus, l_loctype,
         out_checkid, l_err, l_msg);
   if (l_msg is not null) then
      out_error := l_err;
      out_message := l_msg;
      return;
   end if;

   begin
      select nvl(loadno, 0) into l_loadno
         from door
         where facility = in_facility
           and doorloc = in_dockdoor;
   exception
      when NO_DATA_FOUND then
         l_loadno := 0;
   end;

   if (l_loadno = 0) then
      out_message := 'No load at door';
      return;
   end if;

   out_loadno := l_loadno;
   begin
      select loadstatus, loadtype
         into l_loadstatus, l_loadtype
         from loads
         where loadno = l_loadno;
   exception
      when NO_DATA_FOUND then
         out_message := 'Load not found';
         return;
   end;

   if (substr(l_loadtype, 1, 1) != 'O') then
      out_message := 'Not outbound';
      return;
   end if;

   open c_ld;
   fetch c_ld into ld;
   close c_ld;
   if (ld.qtypick + ld.qtycommit) > ld.qtyorder then
      out_overage := 'Y';
   end if;

   if (l_loadstatus = zrf.LOD_LOADED)
   and ((ld.qtyship != ld.qtypick) or (ld.qtycommit != 0)) then
      return;
   end if;

   if (l_loadstatus not in (zrf.LOD_PICKING, zrf.LOD_PICKED, zrf.LOD_LOADING)) then
      out_message := 'Bad load status';
      return;
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end start_loading;


procedure wand_shipplate
   (io_shlpid    in out varchar2,
    in_user      in varchar2,
    in_loadno    in number,
    in_stopno    in number,
    in_fac       in varchar2,
    in_loc       in varchar2,
    out_error    out varchar2,
    out_message  out varchar2)
is
   msg varchar2(80);
   lptype plate.type%type;
   xrefid plate.lpid%type;
   xreftype plate.type%type;
   parentid plate.lpid%type;
   parenttype plate.type%type;
   topid plate.lpid%type;
   toptype plate.type%type;
   cursor c_slp(p_slp varchar2) is
      select S.facility, S.location, S.status, nvl(S.loadno, 0) loadno, nvl(S.stopno, 0) stopno,
             S.rowid, S.fromlpid, nvl(H.ordertype, 'x') ordertype, S.custid
         from shippingplate S, orderhdr H
         where S.lpid = p_slp
           and H.orderid (+) = S.orderid
           and H.shipid (+) = S.shipid;
   cursor c_mlp(p_mlp varchar2) is
      select S.facility, S.location, S.status, nvl(S.loadno, 0) loadno, nvl(S.stopno, 0) stopno,
             S.rowid, S.fromlpid, nvl(H.ordertype, 'x') ordertype, S.custid
         from shippingplate S, orderhdr H, loads L
         where S.fromlpid in (select lpid from plate
                                 start with lpid = p_mlp
                                 connect by prior lpid = parentlpid)
           and S.type = 'F'
           and S.status = 'S'
           and H.orderid (+) = S.orderid
           and H.shipid (+) = S.shipid
           and L.loadno = S.loadno
           and L.loadstatus in (zrf.LOD_PICKING, zrf.LOD_PICKED, zrf.LOD_LOADING, zrf.LOD_LOADED);
   cursor c_auxslp(p_fac varchar2, p_loc varchar2, p_fromlpid varchar2, p_loadno number,
                   p_stopno number) is
      select S.facility, S.location, S.status, nvl(S.loadno, 0) loadno, nvl(S.stopno, 0) stopno,
             S.rowid, S.fromlpid, nvl(H.ordertype, 'x') ordertype, S.custid
         from shippingplate S, orderhdr H
         where S.facility = p_fac
           and S.location = p_loc
           and S.fromlpid = p_fromlpid
           and S.loadno = p_loadno
           and S.stopno = p_stopno
           and S.status = 'S'
           and S.type = 'F'
           and H.orderid (+) = S.orderid
           and H.shipid (+) = S.shipid;
   sp c_slp%rowtype;
   spfound boolean;
   l_elapsed_begin date;
   l_elapsed_end date;
   cntRows pls_integer;
begin
   out_error := 'N';
   out_message := null;
   l_elapsed_begin := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'begin ZRFLD.WAND_SHIPPLATE - ' ||
                    'io_shlpid: ' || io_shlpid || ', ' ||
                    'in_user: ' || in_user || ', ' ||
                    'in_loadno: ' || in_loadno || ', ' ||
                    'in_stopno: ' || in_stopno || ', ' ||
                    'in_fac: ' || in_fac || ', ' ||
                    'in_loc: ' || in_loc,
                    'T', in_user);

   zrf.identify_lp(io_shlpid, lptype, xrefid, xreftype, parentid, parenttype,
         topid, toptype, msg);
   if (msg is not null) then
      out_error := 'Y';
      out_message := msg;
      return;
   end if;

   if (lptype = 'DP') then
      out_message := 'LP is deleted';
      return;
   end if;

   if (lptype = '?') then
      out_message := 'LP not found';
      return;
   end if;

   toptype := nvl(toptype, nvl(parenttype, nvl(xreftype, lptype)));
   topid := nvl(topid, nvl(parentid, nvl(xrefid, io_shlpid)));
   if (toptype = 'MP') then
--    we only need to look at (any)one shippingplate bound to the tree
      open c_mlp(topid);
      fetch c_mlp into sp;
      spfound := c_mlp%found;
      close c_mlp;
      io_shlpid := topid;
   elsif (toptype not in ('C', 'F', 'M')) then
      out_message := 'Not outbound';
      return;
   else
      io_shlpid := topid;
      open c_slp(topid);
      fetch c_slp into sp;
      spfound := c_slp%found;
      close c_slp;
   end if;

   if not spfound then
      out_message := 'Not outbound';
      return;
   end if;

   if zcu.credit_hold(sp.custid) = 'Y' then
       out_message := 'Credit hold';
       return;
   end if;

   if (sp.loadno != in_loadno) then
      spfound := false;
      if (lptype = 'PA') and (xreftype = 'F') then
         open c_auxslp(in_fac, in_loc, io_shlpid, in_loadno, in_stopno);
         fetch c_auxslp into sp;
         spfound := c_auxslp%found;
         close c_auxslp;
      end if;
      if not spfound then
         out_message := 'Not for load';
         return;
      end if;
   end if;

   if (sp.stopno != in_stopno) then
      out_message := 'Not for stop';
      return;
   end if;

   if (sp.status = 'L') then
      out_message := 'Already loaded';
      return;
   end if;

   if (sp.location = in_user) then
      out_message := 'Already wanded';
      return;
   end if;

   if (sp.status != 'S') then
      out_message := 'Not staged';
      return;
   end if;

   if ((sp.location != in_loc) or (sp.facility != in_fac)) then
      out_message := 'Not at location';
      return;
   end if;
   zso.get_rf_lock(sp.loadno,0,0,in_user,msg);
   if substr(msg,1,4) != 'OKAY' then
     out_message := 'Can''t lock';
     return;
   end if;

   if (toptype = 'MP') then
      select count(1) into cntRows
         from shippingplate
         where loadno = in_loadno
           and stopno = in_stopno
           and fromlpid = topid
           and parentlpid is null;
      if cntRows = 0 then
         out_message := 'Not top plate';
         return;
      end if;
--    update all shippingplates
      update shippingplate
         set location = in_user,
             lastuser = in_user,
             lastupdate = sysdate
         where loadno = in_loadno
           and stopno = in_stopno
           and status = 'S'
           and fromlpid in (select lpid from plate
                              start with lpid = topid
                              connect by prior lpid = parentlpid);
--    update all plates
      update plate
         set location = in_user,
             lastoperator = in_user,
             lastuser = in_user,
             lastupdate = sysdate
         where lpid in (select lpid from plate
                                 start with lpid = topid
                                 connect by prior lpid = parentlpid);
   else
--    update the shippingplate
      zrf.move_shippingplate(sp.rowid, in_user, 'S', in_user, null, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;
   end if;
   l_elapsed_end := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'end ZRFLD.WAND_SHIPPLATE - ' ||
                    'out_error: ' || out_error || ', ' ||
                    'out_message: ' || out_message ||
                    ' (Elapsed: ' ||
                    rtrim(substr(zlb.formatted_staffhrs((l_elapsed_end - l_elapsed_begin)*24),1,12)) ||
                    ')',
                    'T', in_user);

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end wand_shipplate;


procedure load_shipplates
   (in_fac        in varchar2,
    in_user       in varchar2,
    in_loadno     in number,
    in_stopno     in number,
    in_dockdoor   in varchar2,
    out_error     out varchar2,
    out_message   out varchar2,
    out_is_loaded out varchar2)     -- 'Y' if load switched to status '8'; else 'N'
is
   cursor c_upd_dtl is
      select P.orderid, P.shipid, P.shipno, P.quantity, P.orderitem,
             P.orderlot, P.custid, P.weight,
             zci.item_cube(P.custid, P.orderitem, P.unitofmeasure) cube,
             O.xdockorderid, nvl(C.allow_overpicking,'N') as allow_overpicking
         from shippingplate P, orderhdr O, customer_aux C
         where P.facility = in_fac
           and P.location = in_user
           and P.type in ('F', 'P')
           and P.loadno = in_loadno
           and P.stopno = in_stopno
           and P.status = 'S'
           and O.orderid = P.orderid
           and O.shipid = P.shipid
           and C.custid = P.custid;
   cursor c_upd_hdr is
      select distinct P.orderid, P.shipid, O.qtypick, O.qtyship, O.orderstatus, O.qtycommit
         from shippingplate P, orderhdr O
         where P.facility = in_fac
           and P.location = in_user
           and P.type in ('F', 'P')
           and P.loadno = in_loadno
           and P.stopno = in_stopno
           and P.status = 'S'
           and O.orderid = P.orderid
           and O.shipid = P.shipid
           and O.orderstatus >= zrf.ORD_PICKING;
   cursor c_lp is
      select rowid, lpid, item, lotnumber, quantity, orderid, shipid, fromlpid, type
         from shippingplate
         where facility = in_fac
           and location = in_user
           and loadno = in_loadno
           and stopno = in_stopno
           and status = 'S'
           and parentlpid is null;
   cursor c_itemview(p_custid varchar2, p_item varchar2) is
      select useramt1
         from custitemview
         where custid = p_custid
           and item = p_item;
   itv c_itemview%rowtype;
   cursor c_ld(p_loadno number) is
      select loadstatus, carrier, trailer
         from loads
         where loadno = p_loadno;
   ld c_ld%rowtype := null;
   neworderstatus orderhdr.orderstatus%type;
   newloadstopstatus loadstop.loadstopstatus%type;
   newloadstatus loads.loadstatus%type;
   msg varchar2(80);
   l_qtyorder orderdtl.qtyorder%type;
   l_qtyship orderdtl.qtyship%type;
   l_cnt integer;
   l_elapsed_begin date;
   l_elapsed_end date;
   aType trailer.activity_type%type;
begin
   out_error := 'N';
   out_message := null;
   out_is_loaded := 'N';
   l_elapsed_begin := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'begin ZRFLD.LOAD_SHIPPLATES - ' ||
                    'in_fac: ' || in_fac || ', ' ||
                    'in_user: ' || in_user || ', ' ||
                    'in_loadno: ' || in_loadno || ', ' ||
                    'in_stopno: ' || in_stopno || ', ' ||
                    'in_dockdoor: ' || in_dockdoor,
                    'T', in_user);

-- check for credit hold
   l_cnt := 0;
   select count(1)
     into l_cnt
    from shippingplate
   where facility = in_fac
     and location = in_user
     and loadno = in_loadno
     and stopno = in_stopno
     and status = 'S'
     and parentlpid is null
     and 'Y' = zcu.credit_hold(custid);

   if nvl(l_cnt,0) > 0 then
        out_message := 'Credit Hold';
        return;
   end if;
   zso.get_rf_lock(in_loadno,0,0,in_user,msg);
   if substr(msg,1,4) != 'OKAY' then
     out_message := 'Can''t lock';
        return;
   end if;

-- update detail data first
   for d in c_upd_dtl loop
      zoc.order_check_required(d.orderid, d.shipid, out_message);
      if (out_message <> 'OKAY') then
        return;
      else
        out_message := null;
      end if;

      open c_itemview(d.custid, d.orderitem);
      fetch c_itemview into itv;
           close c_itemview;
      update orderdtl
         set qtyship = nvl(qtyship, 0) + d.quantity,
             weightship = nvl(weightship, 0) + d.weight,
             cubeship = nvl(cubeship, 0) + (d.quantity * d.cube),
             amtship = nvl(amtship, 0) + (d.quantity * zci.item_amt(custid,orderid,shipid,item,lotnumber)),
             lastuser = in_user,
             lastupdate = sysdate
         where orderid = d.orderid
           and shipid = d.shipid
           and item = d.orderitem
           and nvl(lotnumber, '(none)') = nvl(d.orderlot, '(none)')
         returning qtyorder, qtyship into l_qtyorder, l_qtyship;

      if (l_qtyship > l_qtyorder) and (d.xdockorderid is null)
      and (d.allow_overpicking != 'Y') then
         out_message := 'Exceeds ordered qty';
         return;
      end if;

      update loadstopship
         set qtyship = nvl(qtyship, 0) + d.quantity,
             weightship = nvl(weightship, 0) + d.weight,
             weightship_kgs = nvl(weightship_kgs,0)
                            + nvl(zwt.from_lbs_to_kgs(d.custid,d.weight),0),
             cubeship = nvl(cubeship, 0) + (d.quantity * d.cube),
             amtship = nvl(amtship, 0) + (d.quantity * zci.item_amt(d.custid,d.orderid,d.shipid,d.orderitem,d.orderlot)),
             lastuser = in_user,
             lastupdate = sysdate
         where loadno = in_loadno
           and stopno = in_stopno
           and shipno = d.shipno;
   end loop;

-- update order header data next
   for h in c_upd_hdr loop
      if ((h.qtyship = h.qtypick) and (h.qtycommit = 0)) then
         neworderstatus := zrf.ORD_LOADED;
      else
         neworderstatus := zrf.ORD_LOADING;
      end if;

      if (neworderstatus != h.orderstatus) then
         update orderhdr
            set orderstatus = neworderstatus,
                lastuser = in_user,
                lastupdate = sysdate
            where orderid = h.orderid
              and shipid = h.shipid;
      end if;
   end loop;

-- update the load data
   select min(orderstatus) into newloadstopstatus
      from orderhdr
      where loadno = in_loadno
        and stopno = in_stopno
        and fromfacility = in_fac;
   if (newloadstopstatus > zrf.LOD_PICKED) then
      update loadstop
         set loadstopstatus = newloadstopstatus,
             lastuser = in_user,
             lastupdate = sysdate
         where loadno = in_loadno
           and stopno = in_stopno
           and loadstopstatus < newloadstopstatus;
      select min(L.loadstopstatus) into newloadstatus
         from loadstop L
         where L.loadno = in_loadno
           and exists (select * from orderhdr O
                        where O.loadno = L.loadno
                          and O.stopno = L.stopno
                          and O.fromfacility = L.facility);

      open c_ld(in_loadno);
      fetch c_ld into ld;
      close c_ld;
      if nvl(ld.loadstatus, newloadstatus) < newloadstatus then
         update loads
            set loadstatus = newloadstatus,
                lastuser = in_user,
                lastupdate = sysdate
            where loadno = in_loadno;
         if newloadstatus = zrf.LOD_LOADING   or
            newloadstatus = zrf.LOD_LOADED then
            if newloadstatus = zrf.LOD_LOADING then
               aType := 'LDN';
            else
               aType := 'LOD';
            end if;
            begin
               update trailer
                  set activity_type = aType,
                      contents_status = newloadstatus,
                      lastuser = in_user,
                      lastupdate = sysdate
                where carrier = ld.carrier
                  and trailer_number = ld.trailer
                  and loadno = in_loadno;
            exception when no_data_found then
               null;
            end;
         end if;
         if newloadstatus = zrf.LOD_LOADED then
            out_is_loaded := 'Y';
         end if;
      end if;
   end if;

-- move the shippingplates
   for l in c_lp loop
      zrf.move_shippingplate(l.rowid, in_dockdoor, 'L', in_user, null, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;
      if nvl(l.orderid,0) != 0 then
       zoh.add_orderhistory_item(l.orderid, l.shipid,
           l.lpid, l.item, l.lotnumber, 'Load Plate',
           'Load plate Qty '||l.quantity, in_user, msg);
      end if;

--    delete any deconsolidation moves
      if l.type = 'F' then
         delete tasks
            where lpid = l.fromlpid
              and facility = in_fac
              and tasktype = 'MV';
         if sql%rowcount != 0 then
            delete subtasks
               where lpid = l.fromlpid
                 and facility = in_fac
                 and tasktype = 'MV';
         end if;
      end if;
   end loop;

-- move any return-to-vendor multi-plates
   update plate
      set location = in_dockdoor,
          lastoperator = in_user,
          lastuser = in_user,
          lastupdate = sysdate
      where facility = in_fac
        and location = in_user
        and type != 'PA';
   l_elapsed_end := sysdate;
   zms.rf_debug_msg('RFDEBUG', null, null,
                    'end ZRFLD.LOAD_SHIPPLATES - ' ||
                    'out_error: ' || out_error || ', ' ||
                    'out_message: ' || out_message || ', ' ||
                    'out_is_loaded: ' || out_is_loaded ||
                    ' (Elapsed: ' ||
                    rtrim(substr(zlb.formatted_staffhrs((l_elapsed_end - l_elapsed_begin)*24),1,12)) ||
                    ')',
                    'T', in_user);

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end load_shipplates;


procedure start_unloading
   (in_facility  in varchar2,
    in_dockdoor  in varchar2,
    in_equipment in varchar2,
    in_user      in varchar2,
    out_loadno   out number,
    out_error    out varchar2,
    out_message  out varchar2)
is
   sts location.status%type;
   typ location.loctype%type;
   ckid location.checkdigit%type;
   err varchar2(1);
   msg varchar2(80);
   ldno loads.loadno%type;
   ldtype loads.loadtype%type;
   ldstatus loads.loadstatus%type;
begin
   out_error := 'N';
   out_message := null;
   out_loadno := 0;

   zrf.verify_location(in_facility, in_dockdoor, in_equipment, sts, typ,
         ckid, err, msg);
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
      select nvl(loadno, 0) into ldno
         from door
         where facility = in_facility
           and doorloc = in_dockdoor;
   exception
      when NO_DATA_FOUND then
         ldno := 0;
   end;

   if (ldno = 0) then
      out_message := 'No load at door';
      return;
   end if;

   out_loadno := ldno;
   begin
      select loadstatus, loadtype
         into ldstatus, ldtype
         from loads
         where loadno = ldno;
   exception
      when NO_DATA_FOUND then
         out_message := 'Load not found';
         return;
   end;

   if (substr(ldtype, 1, 1) != 'O') then
      out_message := 'Not outbound';
      return;
   end if;

   if (ldstatus not in (zrf.LOD_PICKING, zrf.LOD_PICKED, zrf.LOD_LOADING, zrf.LOD_LOADED)) then
      out_message := 'Bad load status';
      return;
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end start_unloading;


procedure wand_shlp_for_unload
   (io_shlpid    in out varchar2,
    in_user      in varchar2,
    in_loadno    in number,
    in_fac       in varchar2,
    in_dock      in varchar2,
    out_error    out varchar2,
    out_message  out varchar2)
is
   msg varchar2(80);
   lptype plate.type%type;
   xrefid plate.lpid%type;
   xreftype plate.type%type;
   parentid plate.lpid%type;
   parenttype plate.type%type;
   topid plate.lpid%type;
   toptype plate.type%type;
   cursor c_slp(in_slp varchar2) is
      select facility, location, status, nvl(loadno, 0) loadno, rowid,
        orderid, shipid, lpid, item, lotnumber, quantity
         from shippingplate
         where lpid = in_slp;
   cursor c_mlp(p_mlp varchar2) is
      select S.facility, S.location, S.status, nvl(S.loadno, 0) loadno, S.rowid,
        orderid, shipid, lpid, item, lotnumber, quantity
         from shippingplate S, loads L
         where S.fromlpid in (select lpid from plate
                                 start with lpid = p_mlp
                                 connect by prior lpid = parentlpid)
           and S.type = 'F'
           and S.status = 'L'
           and L.loadno = S.loadno
           and L.loadstatus in (zrf.LOD_PICKING, zrf.LOD_PICKED, zrf.LOD_LOADING, zrf.LOD_LOADED);
   sp c_slp%rowtype;
   spfound boolean;
begin
   out_error := 'N';
   out_message := null;

   zrf.identify_lp(io_shlpid, lptype, xrefid, xreftype, parentid, parenttype,
         topid, toptype, msg);
   if (msg is not null) then
      out_error := 'Y';
      out_message := msg;
      return;
   end if;

   if (lptype = 'DP') then
      out_message := 'LP is deleted';
      return;
   end if;

   if (lptype = '?') then
      out_message := 'LP not found';
      return;
   end if;

   toptype := nvl(toptype, nvl(parenttype, nvl(xreftype, lptype)));
   topid := nvl(topid, nvl(parentid, nvl(xrefid, io_shlpid)));
   if (toptype = 'MP') then
--    we only need to look at (any)one shippingplate bound to the tree
      open c_mlp(topid);
      fetch c_mlp into sp;
      spfound := c_mlp%found;
      close c_mlp;
      io_shlpid := topid;
   elsif (toptype not in ('C', 'F', 'M')) then
      out_message := 'Not outbound';
      return;
   else
      io_shlpid := topid;
      open c_slp(topid);
      fetch c_slp into sp;
      spfound := c_slp%found;
      close c_slp;
   end if;

   if not spfound then
      out_message := 'Not outbound';
      return;
   end if;

   if (sp.loadno != in_loadno) then
      out_message := 'Not for load';
      return;
   end if;

   if (sp.location = in_user) then
      out_message := 'Already wanded';
      return;
   end if;

   if (sp.status != 'L') then
      out_message := 'Not loaded';
      return;
   end if;

   if ((sp.location != in_dock) or (sp.facility != in_fac)) then
      out_message := 'Not at dock';
      return;
   end if;

   if (toptype = 'MP') then
--    update all shippingplates
      update shippingplate
         set location = in_user,
             lastuser = in_user,
             lastupdate = sysdate
         where loadno = in_loadno
           and status = 'L'
           and fromlpid in (select lpid from plate
                              start with lpid = topid
                              connect by prior lpid = parentlpid);
--    update all plates
      update plate
         set location = in_user,
             lastoperator = in_user,
             lastuser = in_user,
             lastupdate = sysdate
         where lpid in (select lpid from plate
                           start with lpid = topid
                           connect by prior lpid = parentlpid);
   else
--    update the shippingplate
      zrf.move_shippingplate(sp.rowid, in_user, 'L', in_user, null, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;
   end if;

   if nvl(sp.orderid,0) != 0 then
      zoh.add_orderhistory_item(sp.orderid, sp.shipid,
        sp.lpid, sp.item, sp.lotnumber, 'Unload Plate',
        'Unload plate Qty '||sp.quantity, in_user, msg);
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end wand_shlp_for_unload;


procedure unload_a_plate
   (in_shlpid    in varchar2,
    in_stage_loc in varchar2,
    in_user      in varchar2,
    out_error    out varchar2,
    out_message  out varchar2)
is
   cursor c_kids (mlip varchar2) is
      select lpid, type, rowid, fromlpid
         from shippingplate
         where parentlpid = mlip;
   msg varchar2(80);
   lptype plate.type%type;
   xrefid plate.lpid%type;
   xreftype plate.type%type;
   parentid plate.lpid%type;
   parenttype plate.type%type;
   topid plate.lpid%type;
   toptype plate.type%type;
   cursor c_slp(in_slp varchar2) is
      select S.lpid, S.location, S.status, S.rowid, S.fromlpid, L.loadstatus
         from shippingplate S, loads L
         where S.lpid = in_slp
           and L.loadno = S.loadno;
   cursor c_mlp(p_mlp varchar2) is
      select S.lpid, S.location, S.status, S.rowid, S.fromlpid, L.loadstatus
         from shippingplate S, loads L
         where S.fromlpid in (select lpid from plate
                                 where type = 'PA'
                                 start with lpid = p_mlp
                                 connect by prior lpid = parentlpid)
           and S.type = 'F'
           and S.status = 'L'
           and L.loadno = S.loadno;
   sp c_slp%rowtype;
   spfound boolean;
begin
   out_error := 'N';
   out_message := null;

   zrf.identify_lp(in_shlpid, lptype, xrefid, xreftype, parentid, parenttype,
         topid, toptype, msg);
   if (msg is not null) then
      out_error := 'Y';
      out_message := msg;
      return;
   end if;

   if (lptype = 'DP') then
      out_message := 'LP is deleted';
      return;
   end if;

   if (lptype = '?') then
      out_message := 'LP not found';
      return;
   end if;

   toptype := nvl(toptype, nvl(parenttype, nvl(xreftype, lptype)));
   topid := nvl(topid, nvl(parentid, nvl(xrefid, in_shlpid)));
   if (toptype = 'MP') then
--    we only need to look at (any)one shippingplate bound to the tree
      open c_mlp(topid);
      fetch c_mlp into sp;
      spfound := c_mlp%found;
      close c_mlp;
   elsif (toptype not in ('C', 'F', 'M')) then
      out_message := 'Not outbound';
      return;
   else
      open c_slp(topid);
      fetch c_slp into sp;
      spfound := c_slp%found;
      close c_slp;
   end if;

   if (sp.loadstatus not in (zrf.LOD_PICKING, zrf.LOD_PICKED, zrf.LOD_LOADING, zrf.LOD_LOADED)) then
      out_message := 'Bad load status';
      return;
   end if;

   if not spfound then
      out_message := 'Not outbound';
      return;
   end if;

   if (sp.location = in_stage_loc) then
      out_message := 'Already unloaded';
      return;
   end if;

   if ((sp.location != in_user) or (sp.status != 'L')) then
      out_message := 'Not yours';
      return;
   end if;

   if (toptype = 'MP') then
--    unload all (full pick) shippingplates
      for s in c_mlp(topid) loop
         unload_slip(s.lpid, in_stage_loc, in_user, msg);
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
            return;
         end if;
      end loop;

--    move any return-to-vendor multi-plates
      update plate
         set location = in_stage_loc,
             lastoperator = in_user,
             lastuser = in_user,
             lastupdate = sysdate
         where lpid in (select lpid from plate
                           where type != 'PA'
                           start with lpid = topid
                           connect by prior lpid = parentlpid);
      return;
   end if;

   if (toptype in ('F', 'P')) then
      unload_slip(topid, in_stage_loc, in_user, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
      end if;
      return;
   end if;

-- just move the master pallet / carton, but DON'T use move_shippingplate
-- since that will move all it's children
   update shippingplate
      set location = in_stage_loc,
          status = 'S',
          lastuser = in_user,
          lastupdate = sysdate
      where rowid = sp.rowid;

   if (sp.fromlpid is not null) then
      update plate
         set location = in_stage_loc,
             lastoperator = in_user,
             lastuser = in_user,
             lastupdate = sysdate
         where lpid = sp.fromlpid
           and type != 'XP';
   end if;

-- process carton kids
   if (toptype = 'C') then
      unload_ctn_kids(topid, in_stage_loc, in_user, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
      end if;
      return;
   end if;

-- process master kids
   for k in c_kids(topid) loop
      if (k.type in ('F', 'P')) then
         unload_slip(k.lpid, in_stage_loc, in_user, msg);
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
            return;
         end if;
      else
         update shippingplate
            set location = in_stage_loc,
                status = 'S',
                lastuser = in_user,
                lastupdate = sysdate
            where rowid = k.rowid;
         if (k.fromlpid is not null) then
            update plate
               set location = in_stage_loc,
                   lastoperator = in_user,
                   lastuser = in_user,
                   lastupdate = sysdate
               where lpid = k.fromlpid
                 and type != 'XP';
         end if;
         unload_ctn_kids(k.lpid, in_stage_loc, in_user, msg);
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
            return;
         end if;
      end if;
   end loop;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end unload_a_plate;


procedure combine_mast
   (in_fromlp     in varchar2,
    in_tolp       in varchar2,
    in_mplp       in varchar2,
    in_user       in varchar2,
    in_use_carton in varchar2,
    out_toloc     out varchar2,
    out_cust      out varchar2,
    out_error     out varchar2,
    out_message   out varchar2)
is
   cursor c_mp (p_lpid varchar2) is
      select S.facility, S.status, nvl(S.loadno, 0) loadno, nvl(S.stopno, 0) stopno, S.rowid,
             S.location, S.type, S.fromlpid, zrf.xlate_fromlpid(S.fromlpid, S.lpid) xlpid, T.toloc,
             nvl(S.orderid, 0) orderid, nvl(S.shipid, 0) shipid, S.custid,
             nvl(X.mixed_order_shiplp_ok,'Y') mixed_order_shiplp_ok
         from shippingplate S, tasks T, customer_aux X
         where S.lpid = p_lpid
           and T.taskid (+) = S.taskid
           and X.custid (+) = S.custid;
   frp c_mp%rowtype;
   frstage orderhdr.stageloc%type;
   frslip shippingplate.lpid%type;
   top c_mp%rowtype;
   tostage orderhdr.stageloc%type;
   toslip shippingplate.lpid%type;
   mpp c_mp%rowtype := null;
   mpslip shippingplate.lpid%type;
   holdtoslip shippingplate.lpid%type;
   cursor c_kids (p_lpid varchar2) is
      select lpid
         from shippingplate
         where parentlpid = p_lpid;
   cursor c_carr (p_orderid number, p_shipid number) is
      select nvl(C.multiship, 'N') multiship, O.shiptype
         from orderhdr O, loads L, carrier C
         where O.orderid = p_orderid
           and O.shipid = p_shipid
           and L.loadno (+) = O.loadno
           and C.carrier = nvl(L.carrier, O.carrier);
   frc c_carr%rowtype;
   toc c_carr%rowtype;
   err varchar2(1);
   msg varchar2(80);
   lptype plate.type%type;
   xrefid plate.lpid%type;
   xreftype plate.type%type;
   parentid plate.lpid%type;
   parenttype plate.type%type;
   topid plate.lpid%type;
   toptype plate.type%type;
   builtmlip shippingplate.lpid%type;
   origtoxlpid shippingplate.lpid%type := null;
   origtoprowid rowid;
   l_key number := 0;
   l_usecheckids facility.use_location_checkdigit%type;
   l_cordid waves.wave%type;
   warnSplitOnly varchar2(255);
   warnSplit char(1);
begin
   out_error := 'N';
   out_message := null;

-- obvious errors
   if (in_tolp = in_fromlp) then
      out_message := 'Same LPs';
      return;
   end if;

   zrf.so_lock(l_key);
-- edit from master
   out_error := 'F';
   zrf.identify_lp(in_fromlp, lptype, xrefid, xreftype, parentid, parenttype,
         topid, toptype, msg);
   if (msg is not null) then
      out_error := 'Y';
      out_message := msg;
      return;
   end if;

   if (lptype = 'DP') then
      out_message := 'From is deleted';
      return;
   end if;

   if (lptype = '?') then
      out_message := 'From not found';
      return;
   end if;

   lptype := nvl(toptype, nvl(parenttype, nvl(xreftype, lptype)));
   if (lptype not in ('C', 'F', 'M')) then
      out_message := 'Not outbound';
      return;
   end if;

   frslip := nvl(topid, nvl(parentid, nvl(xrefid, in_fromlp)));
   if (zrf.is_plate_passed(frslip, lptype) != 0) then
      out_message := 'Resume pending';
      return;
   end if;

   open c_mp(frslip);
   fetch c_mp into frp;
   close c_mp;

   if (frp.status = 'U') then
      out_message := 'From unpicked';
      return;
   end if;

   if (frp.status = 'P') then
      out_message := 'From picked';
      return;
   end if;

   if (frp.status = 'SH') then
      out_message := 'From shipped';
      return;
   end if;

   zrf.verify_facility(frp.facility, in_user, l_usecheckids, err, msg);
   if (err != 'N') then
      out_error := err;
      out_message := msg;
      return;
   end if;
   if (msg is not null) then
      out_message := msg;
      return;
   end if;

   if zcord.cons_ordertype(frp.orderid, frp.shipid) in ('T','U') then
      out_message := 'From is for transfer';
      return;
   end if;

-- edit to master
   out_error := 'T';
   zrf.identify_lp(in_tolp, lptype, xrefid, xreftype, parentid, parenttype,
         topid, toptype, msg);
   if (msg is not null) then
      out_error := 'Y';
      out_message := msg;
      return;
   end if;

   if (lptype = 'DP') then
      out_message := 'To is deleted';
      return;
   end if;

   if (lptype = '?') then
      out_message := 'To not found';
      return;
   end if;

   lptype := nvl(toptype, nvl(parenttype, nvl(xreftype, lptype)));
   if (lptype not in ('C', 'F', 'M')) then
      out_message := 'Not outbound';
      return;
   end if;

   toslip := nvl(topid, nvl(parentid, nvl(xrefid, in_tolp)));
   if (zrf.is_plate_passed(toslip, lptype) != 0) then
      out_message := 'Resume pending';
      return;
   end if;

   open c_mp(toslip);
   fetch c_mp into top;
   close c_mp;
   origtoprowid := top.rowid;
   if (lptype != 'F') then
      origtoxlpid := top.xlpid;
   end if;

   if (top.status = 'U') then
      out_message := 'To unpicked';
      return;
   end if;

   if (top.status = 'P') then
      out_message := 'To picked';
      return;
   end if;

   if (top.status = 'SH') then
      out_message := 'To shipped';
      return;
   end if;

   if zcord.cons_ordertype(top.orderid, top.shipid) in ('T','U') then
      out_message := 'To is for transfer';
      return;
   end if;

-- cross edits
   if (frp.status != top.status) then
      out_message := 'Status mismatch';
      return;
   end if;

   if (frp.facility != top.facility) then
      out_message := 'Fac mismatch';
      return;
   end if;

   if (frp.loadno != top.loadno) then
      out_message := 'Load # mismatch';
      return;
   end if;

   if (frp.stopno != top.stopno) then
      out_message := 'Stop # mismatch';
      return;
   end if;

   if (frslip = toslip) then
      out_message := 'Same masters';
      return;
   end if;

   open c_carr(frp.orderid, frp.shipid);
   fetch c_carr into frc;
   if c_carr%notfound then
      frc.multiship := 'N';
      frc.shiptype := '?';
   end if;
   close c_carr;

   open c_carr(top.orderid, top.shipid);
   fetch c_carr into toc;
   if c_carr%notfound then
      toc.multiship := 'N';
      toc.shiptype := '?';
   end if;
   close c_carr;

   l_cordid := zcord.cons_orderid(frp.orderid, frp.shipid);
   if l_cordid != 0 then
      frp.orderid := l_cordid;
      frp.shipid := 0;
   end if;
   l_cordid := zcord.cons_orderid(top.orderid, top.shipid);
   if l_cordid != 0 then
      top.orderid := l_cordid;
      top.shipid := 0;
   end if;
   if ((frp.orderid != top.orderid) or (frp.shipid != top.shipid))
   and (((frp.loadno != top.loadno) or frp.loadno = 0)
     or (frp.mixed_order_shiplp_ok = 'N')
     or (top.mixed_order_shiplp_ok = 'N')) then
      out_message := 'Can''t mix orders';
      return;
   end if;

   if ((top.type = 'F') and (toc.multiship = 'Y') and (toc.shiptype = 'L')) then
      out_message := 'Must use master';
      return;
   end if;

   if (toc.multiship != frc.multiship) then
      out_message := 'Can''t mix multiship';
      return;
   end if;

-- don't allow for the creation of a carton on a master if the carrier is multiship
-- and the shipment is a small package
---   if ((toc.multiship = 'Y') and (toc.shiptype = 'S')
---   and ((frp.type = 'C') or (top.type = 'C'))) then
---      out_message := 'No ctn on mast';
---      return;
---   end if;

-- edit "to master LP" if supplied
   out_error := 'M';
   if in_mplp is not null then
      zrf.identify_lp(in_mplp, lptype, xrefid, xreftype, parentid, parenttype,
            topid, toptype, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;

      if lptype != '?' then
         out_message := 'Not new master';
         return;
      else
         mpp.xlpid := in_mplp;
      end if;
   end if;

   out_error := 'Y';
-- change location of from
   zrf.move_shippingplate(frp.rowid, top.location, top.status, in_user, null, msg);
   if (msg is not null) then
      out_message := msg;
      return;
   end if;

-- move the kids
   if ((toc.multiship = 'Y') and (toc.shiptype = 'S') and (top.type = 'C'))
   or (in_use_carton = 'Y' and frp.type != 'F') then
      if (frp.type = 'F') then
         zrfpk.build_carton(toslip, frslip, in_user, 'N', null, null, msg);
         if (msg is not null) then
            out_message := msg;
            return;
         end if;
      else
         for k in c_kids(frslip) loop
            zrfpk.build_carton(toslip, k.lpid, in_user, 'N', null, null, msg);
            if (msg is not null) then
               out_message := msg;
               return;
            end if;
         end loop;
      end if;
   elsif (in_use_carton = 'Y' and frp.type = 'F') then
      zrfpk.build_carton(toslip, frslip, in_user, 'N', null, null, msg);
      if (msg is not null) then
         out_message := msg;
         return;
      end if;
   else
      holdtoslip := toslip;
      toslip := nvl(mpp.xlpid, toslip);
      if (frp.type in ('C', 'F')) then
         zrfpk.build_mast_shlp(toslip, frslip, in_user, null, builtmlip, msg);
         if (msg is not null) then
            out_message := msg;
            return;
         end if;
         if (builtmlip is not null) then
            toslip := builtmlip;
         end if;
      else
         for k in c_kids(frslip) loop
            zrfpk.build_mast_shlp(toslip, k.lpid, in_user, null, builtmlip, msg);
            if (msg is not null) then
               out_message := msg;
               return;
            end if;
            if (builtmlip is not null) then
               toslip := builtmlip;
            end if;
         end loop;
      end if;
--    if the to was a full, need to attach it
      if in_mplp is not null then
         zrfpk.build_mast_shlp(toslip, holdtoslip, in_user, null, builtmlip, msg);
         if (msg is not null) then
            out_message := msg;
            return;
         end if;
         if (builtmlip is not null) then
            toslip := builtmlip;
         end if;
      end if;
   end if;

-- cleanup any multiship
-- no need to test toc.multiship since either the orders are the same
-- or neither is a multiship
   if (frc.multiship = 'Y') then
      delete multishipdtl
         where cartonid = frp.fromlpid;
      delete multishipdtl
         where cartonid = top.fromlpid;
   end if;

-- update "name" of to
   open c_mp(toslip);
   fetch c_mp into top;
   close c_mp;
   if ((top.fromlpid is null) and (origtoxlpid is not null)) then
      update shippingplate
         set fromlpid = origtoxlpid,
             lastuser = in_user,
             lastupdate = sysdate
         where lpid = toslip;
      update plate
         set parentlpid = toslip,
             lasttask = null,
             lastoperator = in_user,
             lastuser = in_user,
             lastupdate = sysdate
         where lpid = origtoxlpid;
      update shippingplate
         set fromlpid = null,
             lastuser = in_user,
             lastupdate = sysdate
         where rowid = origtoprowid;
   end if;

-- cleanup from
   if ((toc.multiship = 'Y' and toc.shiptype = 'S' and top.type = 'C') or (in_use_carton = 'Y'))
   and frp.type != 'F' then
      delete shippingplate
         where rowid = frp.rowid;
      if (frp.fromlpid is not null) then
         delete plate
            where lpid = frp.fromlpid
              and type = 'XP';
      end if;
   elsif (frp.type = 'M') and nvl(mpp.xlpid, '?') != frp.xlpid then
--    delete empty from master unless it is being reused
      delete shippingplate
         where rowid = frp.rowid;

--    delete any xref plate
      if frp.xlpid is not null then
         delete plate
            where lpid = frp.xlpid
              and type = 'XP';
      end if;
   end if;
   begin
      select nvl(defaultvalue,'N') into warnSplitOnly
         from systemdefaults
         where defaultid = 'CMBCASELBLWARNSPLITONLY';
   exception when no_data_found then
      warnSplitOnly := 'N';
   end;
   if warnSplitOnly = 'Y' then
      begin
         select nvl(a.warnsplit,'N') into warnSplit
            from customer_aux a, shippingplate s
            where s.lpid = toslip
              and s.custid = a.custid(+);
      exception when no_data_found then
         warnSplit := 'N';
      end;
   else
      warnSplit := 'N';
   end if;

   if (warnSplitOnly = 'N') or
      (warnSplitOnly = 'Y' and
       warnSplit = 'Y') then
      begin
         update caselabels
            set lpid = toslip,
                combined = 'Y'
            where lpid = frslip
              and labeltype in ('CS', 'CQ');
      exception when no_data_found then
         null;
      end;
   end if;

   if (frc.multiship = 'Y') then
      zmn.stage_carton(top.fromlpid, 'restage', msg);
      if (msg != 'OKAY') then
        out_error := 'Y';
        out_message := msg;
        return;
      end if;
   end if;

   out_error := 'N';
   out_toloc := top.location;
   out_cust := top.custid;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end combine_mast;


procedure split_mast
   (in_qty       in number,
    in_id        in varchar2,
    in_idtype    in varchar2,
    in_idlot     in varchar2,
    in_fromlp    in varchar2,
    in_fromtype  in varchar2,
    in_frommship in varchar2,
    in_tolp      in varchar2,
    in_tomship   in varchar2,
    in_user      in varchar2,
    in_cust      in varchar2,
    out_error    out varchar2,
    out_message  out varchar2)
is
   cursor c_sp(p_lpid varchar2) is
      select nvl(S.orderid,0) orderid, nvl(S.shipid,0) shipid,
             nvl(S.loadno,0) loadno, nvl(S.stopno,0) stopno,
             S.cartontype, S.type, nvl(X.mixed_order_shiplp_ok,'Y') mixed_order_shiplp_ok,
             S.quantity, S.fromlpid
         from shippingplate S, customer_aux X
         where S.lpid = p_lpid
           and X.custid (+) = S.custid;
   frsp c_sp%rowtype;
   tosp c_sp%rowtype;
   cursor c_1_part is
      select lpid
         from shippingplate
         where item = in_id
           and nvl(lotnumber, '(none)') = nvl(in_idlot, '(none)')
           and custid = in_cust
           and quantity = in_qty
           and type in ('F', 'P')
         start with lpid = in_fromlp
         connect by prior lpid = parentlpid;
   cursor c_slp is
      select lpid, type, quantity
         from shippingplate
         where item = in_id
           and nvl(lotnumber, '(none)') = nvl(in_idlot, '(none)')
           and custid = in_cust
           and type in ('F', 'P')
         start with lpid = in_fromlp
         connect by prior lpid = parentlpid
         order by type desc, quantity desc;
   cursor c_wt (p_lpid varchar2) is
      select weight
         from shippingplate
         where lpid = p_lpid;
   plip shippingplate.lpid%type;
   qtyoff shippingplate.quantity%type;
   msg varchar2(80);
   pfound boolean;
   builtmlip shippingplate.lpid%type;
   fromlp_wt shippingplate.weight%type := 0;
   tolp_wt shippingplate.weight%type := 0;
   l_key number := 0;
   l_cordid waves.wave%type;
begin
   out_error := 'N';
   out_message := null;

   zrf.so_lock(l_key);

   open c_sp(in_fromlp);
   fetch c_sp into frsp;
   close c_sp;
   open c_sp(in_tolp);
   fetch c_sp into tosp;
   if c_sp%notfound then
      tosp := frsp;
   end if;
   close c_sp;

   if frsp.loadno != tosp.loadno then
      out_message := 'Load # mismatch';
      return;
   end if;

   if frsp.stopno != tosp.stopno then
      out_message := 'stop # mismatch';
      return;
   end if;

-- orders are different and either 1 of the orders has no assigned load
-- or the orders are assigned to different loads
   l_cordid := zcord.cons_orderid(frsp.orderid, frsp.shipid);
   if l_cordid != 0 then
      frsp.orderid := l_cordid;
      frsp.shipid := 0;
   end if;
   l_cordid := zcord.cons_orderid(tosp.orderid, tosp.shipid);
   if l_cordid != 0 then
      tosp.orderid := l_cordid;
      tosp.shipid := 0;
   end if;
   if ((frsp.orderid != tosp.orderid) or (frsp.shipid != tosp.shipid))
   and (((frsp.loadno != tosp.loadno) or frsp.loadno = 0)
     or (frsp.mixed_order_shiplp_ok = 'N')
     or (tosp.mixed_order_shiplp_ok = 'N')) then
      out_message := 'Can''t mix orders';
      return;
   end if;

   if (nvl(in_frommship, 'N') = 'Y') then
      open c_wt(in_fromlp);
      fetch c_wt into fromlp_wt;
      close c_wt;
   end if;

   if (nvl(in_tomship, 'N') = 'Y') then
      open c_wt(in_tolp);
      fetch c_wt into tolp_wt;
      close c_wt;
   end if;

   if (in_idtype != 'IT') then
-- removing an entire shippingplate (plus any kids that tag along)
      if tosp.type = 'C' then
         zrfpk.build_carton(in_tolp, in_id, in_user, 'N', null, tosp.cartontype, msg);
      else
         zrfpk.build_mast_shlp(in_tolp, in_id, in_user, null, builtmlip, msg);
      end if;
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;
   elsif (in_fromtype = 'F') then
-- splitting a full pick
      split_shippingplate(in_fromlp, in_qty, in_tolp, tosp.type, tosp.cartontype, in_user, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;
   else
-- removing items
-- try for exact qty match first
      open c_1_part;
      fetch c_1_part into plip;
      pfound := c_1_part%found;
      close c_1_part;
      if pfound then
--    found 1 single partial pick
         if tosp.type = 'C' then
            zrfpk.build_carton(in_tolp, plip, in_user, 'N', null, tosp.cartontype, msg);
         else
            zrfpk.build_mast_shlp(in_tolp, plip, in_user, null, builtmlip, msg);
         end if;
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
            return;
         end if;
      else
--    need to loop thru all shippingplates
--    partials (largest first) then full picks (largest first)
         qtyoff := 0;
         for p in c_slp loop
            if ((qtyoff + p.quantity) <= in_qty) then
--             need all of the shippingplate
               if tosp.type = 'C' then
                  zrfpk.build_carton(in_tolp, p.lpid, in_user, 'N', null, tosp.cartontype, msg);
               else
                  zrfpk.build_mast_shlp(in_tolp, p.lpid, in_user, null, builtmlip, msg);
               end if;
               if (msg is not null) then
                  out_error := 'Y';
                  out_message := msg;
                  return;
               end if;
               qtyoff := qtyoff + p.quantity;
               exit when (qtyoff = in_qty);
            else
--             only need part of the shippingplate
               split_shippingplate(p.lpid, in_qty - qtyoff, in_tolp, tosp.type, tosp.cartontype,
                     in_user, msg);
               if (msg is not null) then
                  out_error := 'Y';
                  out_message := msg;
                  return;
               end if;
               exit;
            end if;
         end loop;
      end if;
   end if;

-- common cleanup
   tot_and_mship_mast(in_fromlp, in_frommship, fromlp_wt, msg);
   if (msg is null) then
      set_ancestor_data(in_fromlp, msg);
      if (msg is null) then
         tot_and_mship_mast(in_tolp, in_tomship, tolp_wt, msg);
      end if;
   end if;
   if msg is not null then
      out_error := 'Y';
   end if;
   out_message := msg;

-- cleanup from
   for sp in (select lpid, fromlpid
               from shippingplate
               where type in ('C', 'M')
                 and quantity = 0
               start with lpid = in_fromlp
               connect by prior lpid = parentlpid) loop
--    delete empty from
      delete shippingplate
         where lpid = sp.lpid;

--    delete any xref plate
      if sp.fromlpid is not null then
         delete plate
            where lpid = sp.fromlpid
              and type = 'XP';
      end if;
   end loop;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end split_mast;


procedure build_mast
   (in_master   in varchar2,
    io_mstlpid  in out varchar2,
    in_addlpid  in varchar2,
    in_user     in varchar2,
    in_facility in varchar2,
    in_location in varchar2,
    out_custid  out varchar2,
    out_error   out varchar2,
    out_message out varchar2)
is
   cursor c_sp(p_lpid varchar2) is
      select S.facility as facility,
             S.status as status,
             S.custid as custid,
             nvl(S.orderid,0) as orderid,
             nvl(S.shipid,0) as shipid,
             nvl(S.loadno,0) as loadno,
             nvl(S.stopno,0) as stopno,
             S.parentlpid,
             S.fromlpid,
             S.rowid,
             nvl(X.mixed_order_shiplp_ok,'Y') mixed_order_shiplp_ok,
             nvl(X.mixed_order_shiplp_buildmst_ok,'N') mixed_order_shiplp_buildmst_ok
         from shippingplate S, customer_aux X
         where S.lpid = p_lpid
           and X.custid (+) = S.custid;
   adsp c_sp%rowtype;
   mssp c_sp%rowtype;
   cursor c_carr (p_orderid number, p_shipid number) is
      select nvl(C.multiship, 'N') as multiship
         from orderhdr O, loads L, carrier C
         where O.orderid = p_orderid
           and O.shipid = p_shipid
           and L.loadno (+) = O.loadno
           and C.carrier = nvl(L.carrier, O.carrier);
   adca c_carr%rowtype;
   msca c_carr%rowtype;
   l_lptype plate.type%type;
   l_xrefid plate.lpid%type;
   l_xreftype plate.type%type;
   l_parentid plate.lpid%type;
   l_parenttype plate.type%type;
   l_topid plate.lpid%type;
   l_toptype plate.type%type;
   l_msg varchar2(80);
   l_found boolean;
   l_builtmlip shippingplate.lpid%type;
   l_master plate.lpid%type := in_master;
   l_cordid waves.wave%type;
   l_cross_customer_yn waves.cross_customer_yn%type;
begin
   out_error := 'N';
   out_message := null;
   out_custid := null;

   if in_addlpid is null then
      out_message := 'LP required';
      return;
   end if;

   zrf.identify_lp(in_addlpid, l_lptype, l_xrefid, l_xreftype, l_parentid, l_parenttype,
         l_topid, l_toptype, l_msg);
   if l_msg is not null then
      out_error := 'Y';
      out_message := l_msg;
      return;
   end if;

   if l_lptype = '?' then
      out_message := 'LP not found';
      return;
   end if;

   l_topid := nvl(l_xrefid, in_addlpid);
   l_toptype := nvl(l_xreftype, l_lptype);

   if l_toptype not in ('C','F','M') then
      out_message := 'Not full ctn or mast';
      return;
   end if;

   open c_sp(l_topid);
   fetch c_sp into adsp;
   l_found := c_sp%found;
   close c_sp;
   if not l_found then
      out_message := 'LP not found';
      return;
   end if;
   out_custid := adsp.custid;

   if adsp.facility != in_facility then
      out_message := 'Not in your facility';
      return;
   end if;

   if adsp.status != 'S' then
      out_message := 'LP not staged';
      return;
   end if;

   if zrf.is_plate_passed(l_topid, l_toptype) != 0 then
      out_message := 'Resume pending';
      return;
   end if;

   if adsp.parentlpid is not null then
      out_message := 'Currently a child';
      return;
   end if;

   if zcord.cons_ordertype(adsp.orderid, adsp.shipid) in ('T','U') then
      out_message := 'LP is for transfer';
      return;
   end if;

   open c_carr(adsp.orderid, adsp.shipid);
   fetch c_carr into adca;
   if c_carr%notfound then
      adca.multiship := 'N';
   end if;
   close c_carr;

   if io_mstlpid is not null then
      if io_mstlpid = l_topid then
         out_message := 'Same masters';
         return;
      end if;

      open c_sp(io_mstlpid);
      fetch c_sp into mssp;
      l_found := c_sp%found;
      close c_sp;
      if not l_found then
         out_message := 'Master not found';
         return;
      end if;

      if mssp.custid != adsp.custid then
         l_cross_customer_yn := 'N';
         if mssp.shipid = 0 then
            begin
               select nvl(cross_customer_yn,'N') into l_cross_customer_yn
                  from waves
                  where wave = mssp.orderid;
            exception when no_data_found then
               l_cross_customer_yn := 'N';
            end;
         end if;
         if l_cross_customer_yn != 'Y' then
            out_message := 'Not same customer';
            return;
         end if;
      end if;

      if mssp.loadno != adsp.loadno then
         out_message := 'Load # mismatch';
         return;
      end if;

      if mssp.stopno != adsp.stopno then
         out_message := 'Stop # mismatch';
         return;
      end if;

      open c_carr(mssp.orderid, mssp.shipid);
      fetch c_carr into msca;
      if c_carr%notfound then
         msca.multiship := 'N';
      end if;
      close c_carr;

      if (adca.multiship != msca.multiship) then
         out_message := 'Can''t mix multiship';
         return;
      end if;

      l_cordid := zcord.cons_orderid(adsp.orderid, adsp.shipid);
      if l_cordid != 0 then
         adsp.orderid := l_cordid;
         adsp.shipid := 0;
      end if;
      l_cordid := zcord.cons_orderid(mssp.orderid, mssp.shipid);
      if l_cordid != 0 then
         mssp.orderid := l_cordid;
         mssp.shipid := 0;
      end if;

      if (adca.multiship = 'N'
      and (((adsp.orderid != mssp.orderid) or (adsp.shipid != mssp.shipid))
           and ((adsp.loadno != mssp.loadno) or adsp.loadno = 0))) then
         out_message := 'Can''t mix orders';
         return;
      end if;

      if ((adsp.orderid != mssp.orderid) or (adsp.shipid != mssp.shipid))
      and ((adsp.mixed_order_shiplp_ok = 'N' and adsp.mixed_order_shiplp_buildmst_ok = 'N')
       or  (mssp.mixed_order_shiplp_ok = 'N' and mssp.mixed_order_shiplp_buildmst_ok = 'N')) then
         out_message := 'Can''t mix orders';
         return;
      end if;
   end if;

   if l_toptype = 'M' then
      for cp in (select lpid from shippingplate where parentlpid = l_topid) loop
         zrfpk.build_mast_shlp(l_master, cp.lpid, in_user, null, l_builtmlip, l_msg);
         if l_msg is not null then
            out_error := 'Y';
            out_message := l_msg;
            return;
         end if;

         if l_builtmlip is not null then
            io_mstlpid := l_builtmlip;
            l_master := l_builtmlip;
         end if;
      end loop;

      delete shippingplate
         where rowid = adsp.rowid;
      if adsp.fromlpid is not null then
         delete plate
            where lpid = adsp.fromlpid
              and type = 'XP';
      end if;
   else
      zrfpk.build_mast_shlp(in_master, l_topid, in_user, null, l_builtmlip, l_msg);
      if l_msg is not null then
         out_error := 'Y';
         out_message := l_msg;
         return;
      end if;

      if l_builtmlip is not null then
         io_mstlpid := l_builtmlip;
      end if;
   end if;

   update shippingplate
      set location = in_location
      where lpid in (select lpid from shippingplate
               start with lpid = io_mstlpid
               connect by prior lpid = parentlpid);

-- cleanup any multiship
-- no need to test msca.multiship since either the orders are the same
-- or neither is a multiship
   if (adca.multiship = 'Y') then
      delete multishipdtl
         where cartonid = adsp.fromlpid;
      delete multishipdtl
         where cartonid = in_master;
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end build_mast;


end rfloading;
/

show errors package body rfloading;
exit;
