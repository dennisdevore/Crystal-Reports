create or replace package body alps.depicking as
--
-- $Id$
--


-- Private procedures


procedure uncommit_del_pick
   (in_orderid    in number,
    in_shipid     in number,
    in_orderitem  in varchar2,
    in_orderlot   in varchar2,
    in_item       in varchar2,
    in_lot        in varchar2,
    in_class      in varchar2,
    in_status     in varchar2,
    in_qty        in number,
    in_user       in varchar2,
    out_message   out varchar2)
is
   remqty commitments.qty%type;
	comrowid rowid;
begin
   out_message := null;

   update commitments
      set qty = qty - in_qty,
          lastuser = in_user,
          lastupdate = sysdate
      where orderid = in_orderid
        and shipid = in_shipid
        and orderitem = in_orderitem
        and nvl(orderlot, '(none)') = nvl(in_orderlot, '(none)')
        and item = in_item
        and nvl(lotnumber, '(none)') = nvl(in_lot, '(none)')
        and inventoryclass = in_class
        and invstatus = in_status
      returning qty, rowid into remqty, comrowid;
   if ((sql%rowcount != 0) and (remqty <= 0)) then
      delete commitments
     	   where rowid = comrowid;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end uncommit_del_pick;


procedure decrement_picked
   (in_orderid        in number,
    in_shipid         in number,
    in_custid         in varchar2,
    in_orderitem      in varchar2,
    in_orderlot       in varchar2,
    in_qty            in number,
    in_uom            in varchar2,
    in_pickqty        in number,
    in_pickuom        in varchar2,
    in_status         in varchar2,
    in_user           in varchar2,
    in_weight         in number,
    in_inventoryclass in varchar2,
    in_invstatus      in varchar2,
    in_item           in varchar2,
    in_lotnumber      in varchar2,
    out_message       out varchar2)
is
   cursor c_orderhdr is
      select nvl(loadno, 0) loadno, stopno, shipno, orderstatus, dateshipped,
             fromfacility
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
   oh c_orderhdr%rowtype;
   cursor c_itm(p_custid varchar2, p_item varchar2) is
      select lotrequired
         from custitemview
         where custid = p_custid
           and item = p_item;
   itm c_itm%rowtype;
   l_lot asofinventory.lotnumber%type;
   l_msg varchar2(255);
   out_logmsg varchar2(1000);
begin
   out_message := null;

   open c_orderhdr;
   fetch c_orderhdr into oh;
   close c_orderhdr;

   if (in_status = 'SH') or ((in_status = 'L') and (oh.orderstatus != '9')) then
	   update orderdtl
		   set qtypick = nvl(qtypick, 0) - in_qty,
			    weightpick = nvl(weightpick, 0) - in_weight,
             cubepick = nvl(cubepick, 0)
             		- (zci.item_cube(in_custid, in_orderitem, in_pickuom) * in_pickqty),
             amtpick = nvl(amtpick, 0) - (zci.item_amt(in_custid, in_orderid, in_shipid, in_orderitem, in_orderlot) * in_qty), --prn 25133
		       qtyship = nvl(qtyship, 0) - in_qty,
			    weightship = nvl(weightship, 0) - in_weight,
             cubeship = nvl(cubeship, 0)
             		- (zci.item_cube(in_custid, in_orderitem, in_pickuom) * in_pickqty),
             amtship = nvl(amtship, 0) - (zci.item_amt(in_custid, in_orderid, in_shipid, in_orderitem, in_orderlot) * in_qty), --prn 25133
             lastuser = in_user,
             lastupdate = sysdate
      where orderid = in_orderid
        and shipid = in_shipid
        and item = in_orderitem
        and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)');

      if (oh.loadno != 0) then
         update loadstopship
            set qtyship = nvl(qtyship, 0) - in_qty,
                weightship = nvl(weightship, 0) - in_weight,
                weightship_kgs = nvl(weightship_kgs,0)
                               - nvl(zwt.from_lbs_to_kgs(in_custid, in_weight),0),
                cubeship = nvl(cubeship, 0)
             			- (zci.item_cube(in_custid, in_orderitem, in_pickuom) * in_pickqty),
                amtship = nvl(amtship, 0) - (zci.item_amt(in_custid, in_orderid, in_shipid, in_orderitem, in_orderlot) * in_qty), --prn 25133
                lastuser = in_user,
                lastupdate = sysdate
            where loadno = oh.loadno
              and stopno = oh.stopno
              and shipno = oh.shipno;
      end if;
   else
	   update orderdtl
		   set qtypick = nvl(qtypick, 0) - in_qty,
			    weightpick = nvl(weightpick, 0) - in_weight,
             cubepick = nvl(cubepick, 0)
             		- (zci.item_cube(in_custid, in_orderitem, in_pickuom) * in_pickqty),
             amtpick = nvl(amtpick, 0) - (zci.item_amt(in_custid, in_orderid, in_shipid, in_orderitem, in_orderlot) * in_qty), --prn 25133
             lastuser = in_user,
             lastupdate = sysdate
      where orderid = in_orderid
        and shipid = in_shipid
        and item = in_orderitem
        and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)');
   end if;

   if in_status = 'SH' then
      open c_itm(in_custid, in_item);
	   fetch c_itm into itm;
   	close c_itm;
      if itm.lotrequired = 'P' then
         l_lot := null;
      else
         l_lot := in_lotnumber;
      end if;

      zbill.add_asof_inventory(oh.fromfacility, in_custid, in_item, l_lot, in_uom,
            oh.dateshipped, in_qty, in_weight, 'Depicked', 'AD', in_inventoryclass,
            in_invstatus, in_orderid, in_shipid, null, in_user, l_msg);
	  if l_msg != 'OKAY' then
		out_message := l_msg;
		zms.log_msg('DEPICK', oh.fromfacility, in_custid, l_msg, 'E','DEPICK', out_logmsg);
	  end if;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end decrement_picked;


procedure cancel_lp_order
   (in_orderid  in number,
    in_shipid   in number,
    in_taskid   in number,
    in_user     in varchar2,
    out_message out varchar2)
is
   cursor c_shippingplate is
      select status, rowid, orderitem, orderlot, item, lotnumber, inventoryclass, invstatus,
             quantity
         from shippingplate
         where orderid = in_orderid
           and shipid = in_shipid;
   cursor c_subtask is
		select rowid
			from subtasks
         where taskid = in_taskid;
   cursor c_orderhdr is
      select orderstatus, fromfacility, loadno
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
   oh c_orderhdr%rowtype;
   msg varchar2(255) := null;
   errorno integer;
   cnt integer;
begin
   out_message := null;

   for sp in c_shippingplate loop
      if (sp.status = 'U') then
         delete shippingplate
            where rowid = sp.rowid;
      end if;

      uncommit_del_pick(in_orderid, in_shipid, sp.orderitem, sp.orderlot, sp.item,
            sp.lotnumber, sp.inventoryclass, sp.invstatus, sp.quantity, in_user, msg);
      exit when (msg is not null);
   end loop;

   if (msg is null) then
      for st in c_subtask loop
         del_pick_subtask(st.rowid, in_user, msg);
         exit when (msg is not null);
      end loop;
   end if;

   if (msg is null) then
      delete tasks
         where taskid = in_taskid;

      open c_orderhdr;
      fetch c_orderhdr into oh;
      close c_orderhdr;

      if ((oh.orderstatus = 'X') and (oh.loadno != 0)) then
         select count(1) into cnt
            from shippingplate
            where orderid = in_orderid
              and shipid = in_shipid
              and status = 'L';
         if (cnt = 0) then
            zld.deassign_order_from_load(in_orderid, in_shipid, oh.fromfacility, in_user,
                  'N', errorno, msg);
            if (errorno < 0) then
               out_message := msg;
            end if;
         end if;
      end if;
   else
      out_message := msg;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end cancel_lp_order;


procedure upd_depicked_inventory
   (in_shlpid   in varchar2,
    in_lpid     in varchar2,
    in_loc	    in varchar2,
    in_qty      in number,
    in_user     in varchar2,
    in_weight   in number,
    out_error   out varchar2,
    out_message out varchar2)
is
   cursor c_sp is
      select custid, item, lotnumber, facility, invstatus, inventoryclass,
      		 unitofmeasure, orderid, shipid, serialnumber, useritem1,
             useritem2, useritem3, parentlpid, fromlpid
         from shippingplate
         where lpid = in_shlpid;
   sp c_sp%rowtype;
   cursor c_lp is
      select custid, item, lotnumber, invstatus, inventoryclass, rowid,
             facility, location, qtytasked, type, status, serialnumber,
             useritem1, useritem2, useritem3, unitofmeasure, parentlpid
         from plate
         where lpid = in_lpid;
   lp c_lp%rowtype;
   cursor c_kid is
      select lpid
         from plate
         where custid = sp.custid
           and item = sp.item
           and type = 'PA'
           and invstatus = sp.invstatus
           and inventoryclass = sp.inventoryclass
           and unitofmeasure = sp.unitofmeasure
           and nvl(serialnumber, '(none)') = nvl(sp.serialnumber, '(none)')
           and nvl(lotnumber, '(none)') = nvl(sp.lotnumber, '(none)')
           and nvl(useritem1, '(none)') = nvl(sp.useritem1, '(none)')
           and nvl(useritem2, '(none)') = nvl(sp.useritem2, '(none)')
           and nvl(useritem3, '(none)') = nvl(sp.useritem3, '(none)')
         start with lpid = in_lpid
         connect by prior lpid = parentlpid;
   kid c_kid%rowtype;
   cursor c_loc is
      select rowid, lpid, parentlpid
         from plate
         where facility = sp.facility
           and location = in_loc
           and custid = sp.custid
           and item = sp.item
           and type = 'PA'
           and invstatus = sp.invstatus
           and inventoryclass = sp.inventoryclass
           and unitofmeasure = sp.unitofmeasure
           and nvl(serialnumber, '(none)') = nvl(sp.serialnumber, '(none)')
           and nvl(lotnumber, '(none)') = nvl(sp.lotnumber, '(none)')
           and nvl(useritem1, '(none)') = nvl(sp.useritem1, '(none)')
           and nvl(useritem2, '(none)') = nvl(sp.useritem2, '(none)')
           and nvl(useritem3, '(none)') = nvl(sp.useritem3, '(none)')
           and status = 'A'
           and qtytasked is null;
   loc c_loc%rowtype;
   cursor c_flp(p_lpid varchar2) is
      select manufacturedate, expirationdate, anvdate, creationdate, loadno
         from plate
         where lpid = p_lpid;
   cursor c_fdlp(p_lpid varchar2) is
      select manufacturedate, expirationdate, anvdate, creationdate, loadno
         from deletedplate
         where lpid = p_lpid;
   flp c_flp%rowtype;
   l_msg varchar2(80);
   l_inslpid plate.lpid%type := null;
   l_rowfound boolean;
   l_parentlpid plate.lpid%type := null;
   l_parentloc plate.location%type;
   l_ship_lp plate.lpid%type;
   v_dp_orderid plate.orderid%type := null;
   v_dp_shipid plate.shipid%type := null;
   v_dp_po plate.po%type := null;
begin
	out_message := null;
   out_error := 'N';

   open c_sp;
   fetch c_sp into sp;
   close c_sp;

   open c_flp(sp.fromlpid);
   fetch c_flp into flp;
   if c_flp%notfound then
      open c_fdlp(sp.fromlpid);
      fetch c_fdlp into flp;
      close c_fdlp;
   end if;
   close c_flp;

   begin
      select lpid
         into l_ship_lp
         from plate
         where parentlpid = sp.parentlpid
           and type = 'XP'
           and rownum = 1;
   exception
      when NO_DATA_FOUND then
       	l_ship_lp := sp.parentlpid;
   end;

	if (in_lpid is not null) then
      open c_lp;
      fetch c_lp into lp;
      l_rowfound := c_lp%found;
      close c_lp;

      if not l_rowfound then								-- adding a new plate

         l_inslpid := in_lpid;

         begin
          select orderid, shipid, po
          into v_dp_orderid, v_dp_shipid, v_dp_po
          from deletedplate
          where lpid = in_lpid;
         exception
          when others then
            v_dp_orderid := null;
            v_dp_shipid := null;
            v_dp_po := null;
         end;

         delete from deletedplate						-- if LP is in deletedplate, clean it out
    			where lpid = in_lpid;
		else
         if sp.facility != lp.facility then
            out_message := 'LP not in facility';
            return;
         end if;
         if nvl(lp.qtytasked, 0) != 0 then
            out_message := 'LP has picks';
            return;
         end if;
         if lp.status != 'A' then
            out_message := 'LP not available';
            return;
         end if;

      	if lp.type = 'MP' then							-- attaching to an MP
           	l_parentlpid := in_lpid;

--				try to find compatible child on multi
	         open c_kid;
   	      fetch c_kid into kid;
      	   l_rowfound := c_kid%found;
         	close c_kid;

         	if l_rowfound then

--          	found one - use it
               update plate
                  set quantity = nvl(quantity, 0) + in_qty,
                      weight = nvl(weight, 0) + in_weight,
                      lastoperator = in_user,
                      lastuser = in_user,
                      lastupdate = sysdate,
                      lasttask = 'DP'
                  where lpid = kid.lpid;
				else

--					need to create later
        		   zrf.get_next_lpid(l_inslpid, l_msg);
               if l_msg is not null then
                  out_message := l_msg;
   					out_error := 'Y';
                  return;
               end if;
				end if;
      	elsif lp.type != 'PA' then
            out_message := 'LP is outbound';
            return;
         else

            if ((lp.item = sp.item)						-- compatible - just update plate
            and (lp.custid = sp.custid)
            and (lp.invstatus = sp.invstatus)
            and (lp.inventoryclass = sp.inventoryclass)
            and (lp.unitofmeasure = sp.unitofmeasure)
            and (nvl(lp.serialnumber, '(none)') = nvl(sp.serialnumber, '(none)'))
            and (nvl(lp.lotnumber, '(none)') = nvl(sp.lotnumber, '(none)'))
            and (nvl(lp.useritem1, '(none)') = nvl(sp.useritem1, '(none)'))
            and (nvl(lp.useritem2, '(none)') = nvl(sp.useritem2, '(none)'))
            and (nvl(lp.useritem3, '(none)') = nvl(sp.useritem3, '(none)'))) then

               update plate
                  set quantity = nvl(quantity, 0) + in_qty,
                      weight = nvl(weight, 0) + in_weight,
                      lastoperator = in_user,
                      lastuser = in_user,
                      lastupdate = sysdate,
    						 location = in_loc,
                      lasttask = 'DP'
                  where rowid = lp.rowid;

            	l_parentlpid := lp.parentlpid;
			   else

--       		plate is not a multi - make it so...
               zplp.morph_lp_to_multi(in_lpid, in_user, l_msg);
         	   if l_msg is null then
         		   zrf.get_next_lpid(l_inslpid, l_msg);
           	   end if;
               if l_msg is not null then
                  out_message := l_msg;
   					out_error := 'Y';
                  return;
               end if;
				   l_parentlpid := in_lpid;
            end if;
         end if;
      end if;

      zoh.add_orderhistory_item(sp.orderid, sp.shipid, l_ship_lp, sp.item,
  				sp.lotnumber, 'De-pick Plate', 'Qty:' || in_qty || ' to LP:' || in_lpid,
            in_user, l_msg);

   else													-- in a pickfront try to find a plate
      open c_loc;
      fetch c_loc into loc;
      l_rowfound := c_loc%found;
      close c_loc;
      if l_rowfound then

--			use it
         update plate
            set quantity = nvl(quantity, 0) + in_qty,
                weight = nvl(weight, 0) + in_weight,
                lastoperator = in_user,
                lastuser = in_user,
                lastupdate = sysdate,
                lasttask = 'DP'
            where rowid = loc.rowid;
         zoh.add_orderhistory_item(sp.orderid, sp.shipid, l_ship_lp, sp.item,
         		sp.lotnumber, 'De-pick Plate', 'Qty:' || in_qty || ' to LP:' || loc.lpid,
               in_user, l_msg);
        	l_parentlpid := loc.parentlpid;
      else

--			none found, make new
         zrf.get_next_lpid(l_inslpid, l_msg);
         if (l_msg is not null) then
            out_message := l_msg;
				out_error := 'Y';
            return;
         end if;
         zoh.add_orderhistory_item(sp.orderid, sp.shipid, l_ship_lp, sp.item,
         		sp.lotnumber, 'De-pick Plate', 'Qty:' || in_qty || ' to LP:' || l_inslpid,
               in_user, l_msg);
      end if;
   end if;

   if l_inslpid is not null then
      if flp.anvdate is null then
        if nvl(flp.loadno,0) = 0 then
            flp.anvdate := flp.creationdate;
        end if;
      end if;

      insert into plate
         (lpid, item, custid, facility, location, status, unitofmeasure,
          quantity, type, lotnumber, creationdate, lastoperator, lastuser,
          lastupdate, lasttask, invstatus, inventoryclass, weight,
          parentfacility, parentitem, qtyentered, uomentered, serialnumber,
          useritem1, useritem2, useritem3, manufacturedate, expirationdate,
          anvdate, loadno, orderid, shipid, po, fromlpid)
      values
         (l_inslpid, sp.item, sp.custid, sp.facility, in_loc, 'A', sp.unitofmeasure,
          in_qty, 'PA', sp.lotnumber, sysdate, in_user, in_user,
          sysdate, 'DP', sp.invstatus, sp.inventoryclass, in_weight,
          sp.facility, sp.item, in_qty, sp.unitofmeasure, sp.serialnumber,
          sp.useritem1, sp.useritem2, sp.useritem3, flp.manufacturedate,
          flp.expirationdate, flp.anvdate, flp.loadno, v_dp_orderid, v_dp_shipid, v_dp_po, sp.fromlpid);

		if l_parentlpid is not null then
   		zplp.attach_child_plate(l_parentlpid, l_inslpid, in_loc, 'A', in_user, out_message);
		end if;
	elsif l_parentlpid is not null then
      update plate
         set quantity = nvl(quantity, 0) + in_qty,
             weight = nvl(weight, 0) + in_weight,
             lastoperator = in_user,
             lastuser = in_user,
             lastupdate = sysdate,
             lasttask = 'DP'
         where lpid = l_parentlpid
      	returning location into l_parentloc;
		if l_parentloc != in_loc then
      	update plate
         	set location = in_loc,
                lastoperator = in_user,
                lastuser = in_user,
                lastupdate = sysdate,
                lasttask = 'DP'
            where lpid in (select lpid from plate
                              start with lpid = l_parentlpid
                              connect by prior lpid = parentlpid);
		end if;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
   	out_error := 'Y';
end upd_depicked_inventory;


-- Public procedures


procedure adjust_order_and_load
   (in_orderid    in number,
    in_shipid     in number,
    in_facility   in varchar2,
    in_user       in varchar2,
    in_depick     in varchar2,
    out_message   out varchar2)
is
   cursor c_orderhdr is
      select orderstatus, qtycommit, qtyship, qtypick, rowid, loadno, stopno,
             custid
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
   oh c_orderhdr%rowtype;
   cnt integer;
   errno integer;
   soumsg varchar2(255);
   logmsg varchar2(255);
   neworderstatus orderhdr.orderstatus%type;
   newloadstopstatus loadstop.loadstopstatus%type;
   newloadstatus loads.loadstatus%type;
begin
   out_message := null;

   open c_orderhdr;
   fetch c_orderhdr into oh;
   close c_orderhdr;

   if (oh.orderstatus = 'X') then
     return;
   end if;

   if ((oh.orderstatus = '9') and (in_depick = 'Y')) then
     return;
   end if;

   if (oh.qtycommit > 0)
   or (oh.orderstatus = zrf.ORD_LOADING and nvl(oh.loadno,0) = 0) then
      neworderstatus := oh.orderstatus;      -- don't change the status
   else
      select count(1) into cnt
         from shippingplate
         where orderid = in_orderid
           and shipid = in_shipid
           and status = 'L';
      if (cnt = 0) then
         neworderstatus := zrf.ORD_PICKED;
      elsif ((oh.qtyship = oh.qtypick) and (in_depick = 'N')) then
         neworderstatus := zrf.ORD_LOADED;
      else
         neworderstatus := zrf.ORD_LOADING;
      end if;
   end if;

   if (neworderstatus != oh.orderstatus) then
      update orderhdr
         set orderstatus = neworderstatus,
             lastuser = in_user,
             lastupdate = sysdate
         where rowid = oh.rowid;

      if (nvl(oh.loadno, 0) != 0) then
         select min(orderstatus) into newloadstopstatus
            from orderhdr
            where loadno = oh.loadno
              and stopno = oh.stopno;
         update loadstop
            set loadstopstatus = newloadstopstatus,
                lastuser = in_user,
                lastupdate = sysdate
            where loadno = oh.loadno
              and stopno = oh.stopno
              and loadstopstatus != newloadstopstatus;

         select min(loadstopstatus) into newloadstatus
            from loadstop
            where loadno = oh.loadno;
         update loads
            set loadstatus = newloadstatus,
                lastuser = in_user,
                lastupdate = sysdate
            where loadno = oh.loadno
              and loadstatus != newloadstatus;
      end if;
   end if;

   if (nvl(oh.loadno, 0) = 0) then
      if (zmn.order_is_shipped(in_orderid, in_shipid) = 'Y') then
         zmn.shipped_order_updates(in_orderid, in_shipid, in_user, errno, soumsg);
         if (errno != 0) then
            zms.log_msg('ShipOrdUpdts', in_facility, oh.custid, soumsg, 'W', in_user, logmsg);
         end if;
      end if;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end adjust_order_and_load;


procedure depick_lp
   (in_spid         in varchar2,
    in_location     in varchar2,
    in_lpid         in varchar2,
    in_user         in varchar2,
    out_error       out varchar2,
    out_message     out varchar2)
is
   cursor c_sp(p_lpid varchar2) is
      select type, custid, item, lotnumber, quantity, fromlpid, rowid,
             facility, weight, unitofmeasure, orderid, shipid, orderitem,
             orderlot, parentlpid, lpid, status, location, pickqty, pickuom,
             inventoryclass, invstatus, totelpid
         from shippingplate
         where lpid = p_lpid;
   sp c_sp%rowtype;
   cursor c_lp(p_lpid varchar2) is
      select parentlpid, quantity, type
         from plate
         where lpid = p_lpid;
   lp c_lp%rowtype;
   cursor c_tch(p_toteid varchar2, p_spid varchar2) is
      select lpid, location, status
         from plate
         where parentlpid = p_toteid
           and fromshippinglpid = p_spid;
   tch c_tch%rowtype := null;
   rowfound boolean;
   msg varchar2(80);
   qtyrem shippingplate.quantity%type;
   l_err varchar2(1);
   l_key number := 0;
   l_qty plate.quantity%type;
	l_parentlpid shippingplate.parentlpid%type;

	function picked_qty
   	(in_lpid in varchar2)
	return number
	is
   	cursor c_his(p_lpid varchar2) is
      	select quantity
         	from platehistory
         	where lpid = p_lpid
           	  and status = 'P';
   	his c_his%rowtype := null;
	begin
   	open c_his(in_lpid);
   	fetch c_his into his;
   	close c_his;

   	return his.quantity;

	end picked_qty;
begin
   out_error := 'N';
   out_message := null;

	zrf.so_lock(l_key);
   open c_sp(in_spid);
   fetch c_sp into sp;
   rowfound := c_sp%found;
   close c_sp;

   if not rowfound then
      out_message := 'LP not found';
      return;
   end if;

   if (sp.status != 'SH')
   and ((sp.status not in ('P', 'S', 'L'))
     or (zrf.is_location_physical(sp.facility, sp.location) = 'N')) then
      out_message := 'Not de-pickable';
      return;
   end if;

   if (sp.type = 'F') then
      open c_lp(sp.fromlpid);
      fetch c_lp into lp;
      rowfound := c_lp%found;
      close c_lp;

      if not rowfound then
         insert into plate
            select * from deletedplate
            where lpid = sp.fromlpid;
         delete deletedplate
            where lpid = sp.fromlpid;
         open c_lp(sp.fromlpid);
         fetch c_lp into lp;
         rowfound := c_lp%found;
         close c_lp;
         if not rowfound then
            out_message := 'From LP not found';
            return;
         end if;
         lp.parentlpid := null;
         lp.quantity := sp.quantity;
         if lp.type = 'MP' then
				insert into plate
					select * from deletedplate
					where parentlpid = sp.fromlpid;
				delete deletedplate
					where parentlpid = sp.fromlpid;
         end if;
      end if;

      if (lp.parentlpid is not null) then
         zplp.detach_child_plate(lp.parentlpid, sp.fromlpid, in_location, null, null,
               'A', in_user, 'DP', msg);
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
            return;
         end if;

         update plate
            set qtytasked = null
            where lpid in (select lpid from plate
                              start with lpid = sp.fromlpid
                              connect by prior lpid = parentlpid);
      else
         update plate
            set status = 'A',
                location = in_location,
                lastoperator = in_user,
                lastuser = in_user,
                lastupdate = sysdate,
                qtytasked = null,
                lasttask = 'DP',
                quantity = lp.quantity
            where lpid = sp.fromlpid;

         if lp.type = 'MP' then
         	for cp in (select lpid from plate where parentlpid = sp.fromlpid) loop
   				l_qty := picked_qty(cp.lpid);

					update plate
						set status = 'A',
							 location = in_location,
							 lastoperator = in_user,
							 lastuser = in_user,
							 lastupdate = sysdate,
							 qtytasked = null,
							 lasttask = 'DP',
							 quantity = l_qty
						where lpid = cp.lpid;
				end loop;
			end if;
      end if;

      zoh.add_orderhistory_item(sp.orderid, sp.shipid, sp.fromlpid, sp.item, sp.lotnumber,
			   'De-pick Plate', 'Qty:' || sp.quantity, in_user, msg);

   else        -- must be a 'P' partial
		upd_depicked_inventory(in_spid, in_lpid, in_location, sp.quantity, in_user, sp.weight,
      		l_err, msg);
      if msg is not null then
         out_error := l_err;
         out_message := msg;
         return;
      end if;
   end if;

   if sp.totelpid is not null then
      open c_tch(sp.totelpid, in_spid);
      fetch c_tch into tch;
      close c_tch;
      if tch.lpid is not null then
         zplp.detach_child_plate(sp.totelpid, tch.lpid, tch.location, null, null,
               tch.status, in_user, 'DP', msg);
         if msg is null then
            zlp.plate_to_deletedplate(tch.lpid, in_user, 'DP', msg);
         end if;
         if msg is not null then
            out_error := 'Y';
            out_message := msg;
            return;
         end if;
      end if;
   end if;

   while (sp.lpid is not null)
   loop

      delete multishipdtl
         where cartonid = sp.lpid;

      if (sp.type = 'F') then
         delete multishipdtl
            where cartonid = sp.fromlpid;
      else
         delete multishipdtl
            where cartonid in
                  (select lpid from plate
                     where parentlpid = sp.lpid
                       and type = 'XP');
      end if;

      delete shippingplate
         where rowid = sp.rowid;

      delete plate
         where parentlpid = sp.lpid
           and type = 'XP';

      if (sp.type in ('F','P')) then
         decrement_picked(sp.orderid, sp.shipid, sp.custid, sp.orderitem, sp.orderlot,
               sp.quantity, sp.unitofmeasure, sp.pickqty, sp.pickuom, sp.status,
               in_user, sp.weight, sp.inventoryclass, sp.invstatus, sp.item, sp.lotnumber, msg);
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
            return;
         end if;
      end if;

      sp.lpid := null;
      if (sp.parentlpid is not null) then
         update shippingplate
            set quantity = quantity - sp.quantity,
                weight = weight - sp.weight
            where lpid = sp.parentlpid
            returning quantity, parentlpid into qtyrem, l_parentlpid;
         if l_parentlpid is not null then
            update shippingplate
               set quantity = quantity - sp.quantity,
                   weight = weight - sp.weight
               where lpid = l_parentlpid;
         end if;
         if (qtyrem = 0) then
            open c_sp(sp.parentlpid);
            fetch c_sp into sp;
            close c_sp;
         end if;
      end if;
   end loop;

   adjust_order_and_load(sp.orderid, sp.shipid, sp.facility, in_user, 'Y', msg);
   if (msg is not null) then
      out_error := 'Y';
      out_message := msg;
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end depick_lp;


procedure depick_multi
   (in_lpid     in varchar2,
    in_location in varchar2,
    in_user     in varchar2,
    out_error   out varchar2,
    out_message out varchar2)
is
   cursor c_sp is
      select rowid, custid, orderitem, orderlot, quantity, facility, type,
             weight, unitofmeasure, status, location, pickqty, pickuom, orderid,
             shipid, inventoryclass, invstatus, item, lotnumber
         from shippingplate
         where fromlpid in (select lpid from plate
                              start with lpid = in_lpid
                              connect by prior lpid = parentlpid);
   cursor c_mp is
      select custid, item, quantity, weight, facility, lotnumber
         from plate
         where lpid = in_lpid;
   mp c_mp%rowtype;
   cursor c_itm(p_custid varchar2, p_item varchar2) is
      select lotrequired, serialrequired, user1required, user2required,
             user3required, serialasncapture, user1asncapture, user2asncapture,
             user3asncapture
         from custitemview
         where custid = p_custid
           and item = p_item;
   itm c_itm%rowtype;
   cursor c_kids is
      select lpid
         from plate
         where type = 'PA'
         start with lpid = in_lpid
         connect by prior lpid = parentlpid
         order by lpid;
   msg varchar2(80) := null;
   clones integer;
   kids integer;
   firstlp plate.lpid%type;
   capsn varchar2(1);
   capu1 varchar2(1);
   capu2 varchar2(1);
   capu3 varchar2(1);
   l_orderid orderhdr.orderid%type;
   l_shipid orderhdr.shipid%type;
   l_key number := 0;
begin
   out_error := 'N';
   out_message := null;

	zrf.so_lock(l_key);
   update plate
      set status = 'A',
        location = in_location,
        lastoperator = in_user,
        lastuser = in_user,
        lastupdate = sysdate,
        qtytasked = null,
        lasttask = 'DP'
      where lpid in (select lpid from plate
                        start with lpid = in_lpid
                        connect by prior lpid = parentlpid);

   for sp in c_sp loop
   	l_orderid := sp.orderid;
      l_shipid := sp.shipid;

      if (sp.status != 'SH')
      and ((sp.status not in ('P', 'S', 'L'))
        or (zrf.is_location_physical(sp.facility, sp.location) = 'N')) then
         rollback;
         out_message := 'Not de-pickable';
         return;
      end if;

      delete shippingplate
         where rowid = sp.rowid;

      if (sp.type in ('F','P')) then
         decrement_picked(sp.orderid, sp.shipid, sp.custid, sp.orderitem, sp.orderlot,
               sp.quantity, sp.unitofmeasure, sp.pickqty, sp.pickuom, sp.status,
               in_user, sp.weight, sp.inventoryclass, sp.invstatus, sp.item, sp.lotnumber, msg);
      end if;
      if (msg is null) then
         adjust_order_and_load(sp.orderid, sp.shipid, sp.facility, in_user, 'Y', msg);
      end if;
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;
   end loop;

   delete multishipdtl
      where cartonid in
            (select lpid from plate
               start with lpid = in_lpid
               connect by prior lpid = parentlpid);

-- check to see if we have a collapsible Multi
   open c_mp;
   fetch c_mp into mp;
   close c_mp;
   if ((mp.custid is not null) and (mp.item is not null)) then
      select count(1) into kids
         from plate
         where type = 'PA'
         start with lpid = in_lpid
         connect by prior lpid = parentlpid;

      select count(1) into clones
         from plate
         where type = 'PA'
           and custid = mp.custid
           and item = mp.item
           and fromlpid = in_lpid
         start with lpid = in_lpid
         connect by prior lpid = parentlpid;

      if (kids = clones) then
         open c_itm(mp.custid, mp.item);
	      fetch c_itm into itm;
   	   close c_itm;

         if (nvl(itm.serialrequired, 'N') != 'Y' and nvl(itm.serialasncapture, 'N') = 'Y') then
            capsn := 'Y';
         else
            capsn := 'N';
         end if;

         if (nvl(itm.user1required, 'N') != 'Y' and nvl(itm.user1asncapture, 'N') = 'Y') then
            capu1 := 'Y';
         else
            capu1 := 'N';
         end if;

         if (nvl(itm.user2required, 'N') != 'Y' and nvl(itm.user2asncapture, 'N') = 'Y') then
            capu2 := 'Y';
         else
            capu2 := 'N';
         end if;

         if (nvl(itm.user3required, 'N') != 'Y' and nvl(itm.user3asncapture, 'N') = 'Y') then
            capu3 := 'Y';
         else
            capu3 := 'N';
         end if;

         if (((nvl(itm.lotrequired, 'N') in ('N','P'))
          and (nvl(itm.serialrequired, 'N') in ('N','P'))
          and (nvl(itm.user1required, 'N') in ('N','P'))
          and (nvl(itm.user2required, 'N') in ('N','P'))
          and (nvl(itm.user3required, 'N') in ('N','P')))
         or (capsn = 'Y') or (capu1 = 'Y') or (capu2 = 'Y') or (capu3 = 'Y')) then

--          collapse it - delete all but first child
            for k in c_kids loop
               if (c_kids%rowcount = 1) then
                  firstlp := k.lpid;
               else
                  zlp.plate_to_deletedplate(k.lpid, in_user, 'DP', msg);
                  if (msg is not null) then
                     out_error := 'Y';
                     out_message := msg;
                     return;
                  end if;
               end if;
            end loop;

--          delete Multi
            delete from plate
               where lpid = in_lpid;

--          rename and update first child
            update plate
               set lpid = in_lpid,
                   quantity = mp.quantity,
                   weight = mp.weight,
                   parentlpid = null,
                   serialnumber = decode(capsn, 'N', serialnumber),
                   useritem1 = decode(capu1, 'N', useritem1),
                   useritem2 = decode(capu2, 'N', useritem2),
                   useritem3 = decode(capu3, 'N', useritem3),
                   lastoperator = in_user,
                   lastuser = in_user,
                   lastupdate = sysdate,
                   lasttask = 'DP'
               where lpid = firstlp;

         end if;
      end if;
   end if;

   zoh.add_orderhistory_item(l_orderid, l_shipid, in_lpid, mp.item, mp.lotnumber,
  			'De-pick MultiPlate', 'To : ' || mp.facility || '/' || in_location, in_user, msg);

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end depick_multi;


procedure del_pick_subtask
   (in_rowid    in rowid,
    in_user     in varchar2,
    out_message out varchar2)
is
   cursor c_subtask is
      select lpid, qty, orderid, shipid, orderitem, orderlot, custid,
             tasktype, facility, qtypicked
         from subtasks
         where rowid = in_rowid;
   st c_subtask%rowtype;
   cursor c_suborders is
      select OH.orderid, OH.shipid
         from orderdtl OD, orderhdr OH
         where OH.wave = st.orderid
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
           and OD.itementered = st.orderitem
           and nvl(OD.lotnumber, '(none)') = nvl(st.orderlot, '(none)')
         order by OH.orderid, OH.shipid;
   cursor c_plate is
         select rowid, nvl(qtytasked,0) qtytasked
            from plate
            where lpid = st.lpid;
   lp c_plate%rowtype;
   cursor c_cus(p_custid varchar2) is
      select nvl(paperbased, 'N') paperbased
         from customer
         where custid = p_custid;
   cus c_cus%rowtype;
   cursor c_cusaux(p_custid varchar2) is
      select nvl(X.allow_overpicking, 'N') allow_overpicking
         from customer_aux X
         where X.custid = p_custid;
   cusaux c_cusaux%rowtype;
   lpfound boolean;
   laberrno number := 0;
   labmsg varchar2(255) := null;
   logmsg varchar2(255);
begin
   out_message := null;

   open c_subtask;
   fetch c_subtask into st;
   close c_subtask;

   open c_cusaux(st.custid);
   fetch c_cusaux into cusaux;
   close c_cusaux;

   if (st.lpid is not null) then
      open c_cus(st.custid);
      fetch c_cus into cus;
      close c_cus;

      if cus.paperbased != 'Y' then
         open c_plate;
         fetch c_plate into lp;
         lpfound := c_plate%found;
         close c_plate;

         if lpfound then
            -- qtytaksed should be cleared after Over Picked
            if cusaux.allow_overpicking = 'Y' and
             (nvl(lp.qtytasked, 0) = 0 and st.qty < st.qtypicked) then
                lp.qtytasked := null;
            else
              if lp.qtytasked > (st.qty - st.qtypicked) then
                 lp.qtytasked := lp.qtytasked - (st.qty - st.qtypicked);
              else
                 lp.qtytasked := null;
              end if;
            end if;

            update plate
               set qtytasked = lp.qtytasked
               where rowid = lp.rowid;

         end if;
      end if;
   end if;

   delete subtasks
      where rowid = in_rowid;

   if (st.orderid != 0) and (st.orderitem is not null) then
		if zcord.cons_orderid(st.orderid, st.shipid) = 0 then
         zlb.compute_line_labor(st.orderid, st.shipid, st.orderitem, st.orderlot,
               in_user, st.tasktype, st.facility, 'Y', laberrno, labmsg);
         if (nvl(labmsg, 'OKAY') != 'OKAY') then
            zms.log_msg('LABORCALC', st.facility, st.custid, labmsg, 'E', in_user, logmsg);
         end if;
		else
   		for sub in c_suborders loop
           zlb.compute_line_labor(sub.orderid, sub.shipid, st.orderitem, st.orderlot,
                 in_user, st.tasktype, st.facility, 'Y', laberrno, labmsg);
           if (nvl(labmsg, 'OKAY') != 'OKAY') then
              zms.log_msg('LABORCALC', st.facility, st.custid, labmsg, 'E', in_user, logmsg);
           end if;
       	end loop;
      end if;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end del_pick_subtask;


procedure purge_cxld_pick_task
   (in_taskid   in varchar2,
    in_user     in varchar2,
    out_message out varchar2)
is
   cursor c_subtasks is
      select rowid, orderid, shipid, orderitem, orderlot, qty, shippinglpid, item
         from subtasks
         where taskid = in_taskid;
   cursor c_shippingplate (p_lpid varchar2) is
      select lotnumber, inventoryclass, invstatus, status, rowid
         from shippingplate
         where lpid = p_lpid;
   sp c_shippingplate%rowtype;
   cursor c_orderhdr (p_orderid number, p_shipid number) is
      select orderstatus, fromfacility, loadno
         from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   oh c_orderhdr%rowtype;
   ordid orderhdr.orderid%type;
   shpid orderhdr.shipid%type;
   msg varchar2(255) := null;
   errorno integer;
   cnt integer;
begin
   out_message := null;

   for st in c_subtasks loop

      if (st.shippinglpid is null) then
         cancel_lp_order(st.orderid, st.shipid, in_taskid, in_user, msg);
         out_message := msg;
         return;
      end if;

      open c_shippingplate(st.shippinglpid);
      fetch c_shippingplate into sp;
      close c_shippingplate;

      if (sp.status = 'U') then
         delete shippingplate
            where rowid = sp.rowid;
      end if;

      del_pick_subtask(st.rowid, in_user, msg);
      if (msg is null) then
         uncommit_del_pick(st.orderid, st.shipid, st.orderitem, st.orderlot, st.item,
               sp.lotnumber, sp.inventoryclass, sp.invstatus, st.qty, in_user, msg);
      end if;
      exit when (msg is not null);
   end loop;

   if (msg is null) then
      delete tasks
         where taskid = in_taskid
         returning orderid, shipid into ordid, shpid;

      open c_orderhdr(ordid, shpid);
      fetch c_orderhdr into oh;
      close c_orderhdr;

      if ((oh.orderstatus = 'X') and (oh.loadno != 0)) then
         select count(1) into cnt
            from shippingplate
            where orderid = ordid
              and shipid = shpid
              and status = 'L';
         if (cnt = 0) then
            zld.deassign_order_from_load(ordid, shpid, oh.fromfacility, in_user,
                  'N', errorno, msg);
            if (errorno < 0) then
               out_message := msg;
            end if;
         end if;
      end if;
   else
      out_message := msg;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end purge_cxld_pick_task;


procedure purge_cxld_pick_subtask
   (in_subtask_rowid in varchar2,
    in_user          in varchar2,
    out_results      out varchar2,
    out_message      out varchar2)
is
   cursor c_subtask is
		select orderid, shipid, orderitem, orderlot, taskid, facility, custid, qty,
             shippinglpid, item, lpid
			from subtasks
         where rowid = chartorowid(in_subtask_rowid);
   st c_subtask%rowtype;
   cursor c_orderhdr (p_orderid number, p_shipid number) is
      select orderstatus, fromfacility, loadno
         from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   oh c_orderhdr%rowtype;
   cursor c_shippingplate (p_lpid varchar2) is
      select lotnumber, inventoryclass, invstatus, status, rowid
         from shippingplate
         where lpid = p_lpid;
   sp c_shippingplate%rowtype;
   msg varchar2(255) := null;
   errorno integer;
   cnt integer;
   rowfound boolean;
begin
   out_results := 'N';        -- nothing deleted and no errors
   out_message := null;

   open c_subtask;
   fetch c_subtask into st;
   close c_subtask;

   open c_orderhdr(st.orderid, st.shipid);
   fetch c_orderhdr into oh;
   rowfound := c_orderhdr%found;
   close c_orderhdr;

   if not rowfound then
      return;
   end if;

   if (oh.orderstatus != 'X') then
      select count(1) into cnt
		   from orderdtl
     	   where orderid = st.orderid
		     and shipid = st.shipid
           and item = st.orderitem
           and nvl(lotnumber, '(none)') = nvl(st.orderlot, '(none)')
			  and linestatus = 'X';

      if (cnt = 0) then
         return;                 -- nothing cancelled
      end if;
   end if;

   if (st.shippinglpid is null) then
      cancel_lp_order(st.orderid, st.shipid, st.taskid, in_user, msg);
      if (msg is not null) then
         out_results := 'E';
         out_message := msg;
      else
         out_results := 'T';
      end if;
      return;
   end if;

   open c_shippingplate(st.shippinglpid);
   fetch c_shippingplate into sp;
   close c_shippingplate;

   if (sp.status = 'U') then
      delete shippingplate
         where rowid = sp.rowid;
   end if;

   del_pick_subtask(chartorowid(in_subtask_rowid), in_user, msg);
   if (msg is null) then
      uncommit_del_pick(st.orderid, st.shipid, st.orderitem, st.orderlot, st.item,
            sp.lotnumber, sp.inventoryclass, sp.invstatus, st.qty, in_user, msg);
   end if;
   if (msg is not null) then
      out_results := 'E';
      out_message := msg;
      return;
   end if;
   out_results := 'S';        -- subtask deleted

   delete tasks
      where taskid = st.taskid
        and not exists (select * from subtasks
               where taskid = st.taskid);
 	if (sql%rowcount != 0) then
      out_results := 'T';     -- task deleted

      if ((oh.orderstatus = 'X') and (oh.loadno != 0)) then
         select count(1) into cnt
            from shippingplate
            where orderid = st.orderid
              and shipid = st.shipid
              and status = 'L';
         if (cnt = 0) then
            zld.deassign_order_from_load(st.orderid, st.shipid, oh.fromfacility, in_user,
                  'N', errorno, msg);
            if (errorno < 0) then
               out_message := msg;
            end if;

         end if;
      end if;
   end if;

   if ((oh.orderstatus != 'X') and (nvl(st.orderid, 0) != 0)) then

--    line item cancellation specifics...
      adjust_order_and_load(st.orderid, st.shipid, st.facility, in_user, 'N', msg);
      if (msg is not null) then
         out_results := 'E';
         out_message := msg;
      end if;
   end if;

exception
   when OTHERS then
      out_results := 'E';
      out_message := substr(sqlerrm, 1, 80);
end purge_cxld_pick_subtask;


procedure depick_item
   (in_orderid      in number,
    in_shipid       in number,
    in_fromlpid     in varchar2,
    in_fromistote   in varchar2,
    in_custid       in varchar2,
    in_item         in varchar2,
    in_lotnumber    in varchar2,
    in_dpkqty       in number,
    in_dpkuom       in varchar2,
    in_baseuom		  in varchar2,
    in_serialnumber in varchar2,
    in_useritem1    in varchar2,
    in_useritem2    in varchar2,
    in_useritem3    in varchar2,
    in_toloc        in varchar2,
    in_tolpid       in varchar2,
    in_user         in varchar2,
    out_error       out varchar2,
    out_message     out varchar2)
is
   type depick_item_type is record (
		lpid shippingplate.lpid%type,
		quantity shippingplate.quantity%type,
		type shippingplate.type%type,
		fromlpid shippingplate.fromlpid%type,
		rid rowid,
		orderid shippingplate.orderid%type,
		shipid shippingplate.shipid%type,
		orderitem shippingplate.orderitem%type,
		orderlot shippingplate.orderlot%type,
		status shippingplate.status%type,
		parentlpid shippingplate.parentlpid%type,
		facility shippingplate.facility%type,
      totechild plate.lpid%type,
      pickuom shippingplate.pickuom%type,
      inventoryclass shippingplate.inventoryclass%type,
      invstatus shippingplate.invstatus%type,
      unitweight shippingplate.weight%type);
	type depick_item_cur is ref cursor return depick_item_type;
	c_ship_kids depick_item_cur;
   k depick_item_type;
   cursor c_sp(p_lpid varchar2, p_uom varchar2) is
      select SP.lpid, SP.quantity, SP.type, SP.fromlpid, SP.rowid, SP.orderid,
             SP.shipid, SP.orderitem, SP.orderlot, SP.status, SP.parentlpid,
             SP.facility, LP.lpid totechild, SP.pickuom,
             SP.inventoryclass, SP.invstatus,
             zcwt.ship_lp_item_weight(SP.lpid, SP.custid, SP.item, p_uom) as unitweight
         from shippingplate SP, plate LP
         where SP.lpid = p_lpid
           and LP.fromshippinglpid (+) = SP.lpid;
   sp c_sp%rowtype;
   cursor c_lp(p_lpid varchar2) is
      select parentlpid
         from plate
         where lpid = p_lpid;
   lp c_lp%rowtype;
   l_qtyrem shippingplate.quantity%type;
	l_qty shippingplate.quantity%type;
   l_qtydpk shippingplate.pickqty%type;
	l_remaining shippingplate.quantity%type;
   l_err varchar2(1);
   l_msg varchar2(80);
   l_shlpid shippingplate.lpid%type;
   l_kidprocessed boolean;
   l_lptype plate.type%type;
   l_xrefid plate.lpid%type;
   l_xreftype plate.type%type;
   l_parentid plate.lpid%type;
   l_parenttype plate.type%type;
   l_topid plate.lpid%type;
   l_toptype plate.type%type;
begin
   out_error := 'N';
   out_message := null;
	l_remaining := zlbl.uom_qty_conv(in_custid, in_item, in_dpkqty, in_dpkuom, in_baseuom);

	if in_fromistote != 'Y' then
      zrf.identify_lp(in_fromlpid, l_lptype, l_xrefid, l_xreftype, l_parentid, l_parenttype,
         	l_topid, l_toptype, l_msg);
		l_shlpid := nvl(l_topid, nvl(l_parentid, nvl(l_xrefid, in_fromlpid)));
		if in_shipid != 0 then
      	open c_ship_kids for
            select SP.lpid, SP.quantity, SP.type, SP.fromlpid, SP.rowid, SP.orderid,
                   SP.shipid, SP.orderitem, SP.orderlot, SP.status, SP.parentlpid,
                   SP.facility, null, SP.pickuom, SP.inventoryclass,
                   SP.invstatus,
                   zcwt.ship_lp_item_weight(SP.lpid, SP.custid, SP.item, in_dpkuom)
               from shippingplate SP
               where SP.custid = in_custid
                 and SP.item = in_item
                 and SP.unitofmeasure = in_baseuom
                 and SP.type in ('F','P')
                 and nvl(SP.serialnumber, '(none)') = nvl(in_serialnumber, '(none)')
                 and nvl(SP.lotnumber, '(none)') = nvl(in_lotnumber, '(none)')
                 and nvl(SP.useritem1, '(none)') = nvl(in_useritem1, '(none)')
                 and nvl(SP.useritem2, '(none)') = nvl(in_useritem2, '(none)')
                 and nvl(SP.useritem3, '(none)') = nvl(in_useritem3, '(none)')
                 and SP.orderid = in_orderid
                 and SP.shipid = in_shipid
         	     and SP.lpid in (select S2.lpid from shippingplate S2
            				start with S2.lpid = l_shlpid
            				connect by prior S2.lpid = S2.parentlpid)
					order by decode(SP.fromlpid, in_tolpid, 0, 1), SP.type;
		else
      	open c_ship_kids for
            select SP.lpid, SP.quantity, SP.type, SP.fromlpid, SP.rowid, SP.orderid,
                   SP.shipid, SP.orderitem, SP.orderlot, SP.status, SP.parentlpid,
                   SP.facility, null, SP.pickuom, SP.inventoryclass,
                   SP.invstatus,
                   zcwt.ship_lp_item_weight(SP.lpid, SP.custid, SP.item, in_dpkuom)
               from shippingplate SP, orderhdr OH
               where SP.custid = in_custid
                 and SP.item = in_item
                 and SP.unitofmeasure = in_baseuom
                 and SP.type in ('F','P')
                 and nvl(SP.serialnumber, '(none)') = nvl(in_serialnumber, '(none)')
                 and nvl(SP.lotnumber, '(none)') = nvl(in_lotnumber, '(none)')
                 and nvl(SP.useritem1, '(none)') = nvl(in_useritem1, '(none)')
                 and nvl(SP.useritem2, '(none)') = nvl(in_useritem2, '(none)')
                 and nvl(SP.useritem3, '(none)') = nvl(in_useritem3, '(none)')
                 and OH.wave = in_orderid
                 and SP.orderid = OH.orderid
                 and SP.shipid = OH.shipid
         	     and SP.lpid in (select S2.lpid from shippingplate S2
            				start with S2.lpid = l_shlpid
            				connect by prior S2.lpid = S2.parentlpid)
					order by decode(SP.fromlpid, in_tolpid, 0, 1), SP.type;
		end if;
	else											-- tote depicking
		if in_shipid != 0 then
   	   open c_ship_kids for
      	   select SP.lpid, SP.quantity, SP.type, SP.fromlpid, SP.rowid, SP.orderid,
         	       SP.shipid, SP.orderitem, SP.orderlot, SP.status, SP.parentlpid,
            	    SP.facility, LP.lpid, SP.pickuom, SP.inventoryclass,
                   SP.invstatus,
                   zcwt.ship_lp_item_weight(SP.lpid, SP.custid, SP.item, in_dpkuom)
	            from shippingplate SP, plate LP
   	         where SP.custid = in_custid
      	        and SP.item = in_item
         	     and SP.unitofmeasure = in_baseuom
            	  and SP.type in ('F','P')
	              and nvl(SP.serialnumber, '(none)') = nvl(in_serialnumber, '(none)')
   	           and nvl(SP.lotnumber, '(none)') = nvl(in_lotnumber, '(none)')
      	        and nvl(SP.useritem1, '(none)') = nvl(in_useritem1, '(none)')
         	     and nvl(SP.useritem2, '(none)') = nvl(in_useritem2, '(none)')
            	  and nvl(SP.useritem3, '(none)') = nvl(in_useritem3, '(none)')
	              and SP.orderid = in_orderid
   	           and SP.shipid = in_shipid
      	        and SP.lpid = LP.fromshippinglpid
         	     and LP.lpid in (select P2.lpid from plate P2
	              			start with P2.lpid = in_fromlpid
   	         			connect by prior P2.lpid = P2.parentlpid)
					order by decode(SP.fromlpid, in_tolpid, 0, 1), SP.type;
		else
	      open c_ship_kids for
   	      select SP.lpid, SP.quantity, SP.type, SP.fromlpid, SP.rowid, SP.orderid,
      	          SP.shipid, SP.orderitem, SP.orderlot, SP.status, SP.parentlpid,
         	       SP.facility, LP.lpid, SP.pickuom, SP.inventoryclass,
                   SP.invstatus,
                   zcwt.ship_lp_item_weight(SP.lpid, SP.custid, SP.item, in_dpkuom)
            	from shippingplate SP, orderhdr OH, plate LP
	            where SP.custid = in_custid
   	           and SP.item = in_item
      	        and SP.unitofmeasure = in_baseuom
         	     and SP.type in ('F','P')
            	  and nvl(SP.serialnumber, '(none)') = nvl(in_serialnumber, '(none)')
	              and nvl(SP.lotnumber, '(none)') = nvl(in_lotnumber, '(none)')
   	           and nvl(SP.useritem1, '(none)') = nvl(in_useritem1, '(none)')
      	        and nvl(SP.useritem2, '(none)') = nvl(in_useritem2, '(none)')
         	     and nvl(SP.useritem3, '(none)') = nvl(in_useritem3, '(none)')
            	  and OH.wave = in_orderid
	              and SP.orderid = OH.orderid
   	           and SP.shipid = OH.shipid
      	        and SP.lpid = LP.fromshippinglpid
         	     and LP.lpid in (select P2.lpid from plate P2
            	  			start with P2.lpid = in_fromlpid
            				connect by prior P2.lpid = P2.parentlpid)
					order by decode(SP.fromlpid, in_tolpid, 0, 1), SP.type;
		end if;
	end if;

	loop
     	fetch c_ship_kids into k;
      exit when c_ship_kids%notfound;

  		l_qty := least(k.quantity, l_remaining);
		l_qtydpk := zlbl.uom_qty_conv(in_custid, in_item, l_qty, in_baseuom, in_dpkuom);

      l_kidprocessed := false;
   	if (k.type = 'F') and (k.quantity = l_qty)
      and ((k.fromlpid = in_tolpid) or (in_tolpid is null)) then
	      open c_lp(k.fromlpid);
      	fetch c_lp into lp;
         l_kidprocessed := c_lp%found;
      	close c_lp;

         if l_kidprocessed then
      	   if lp.parentlpid is not null then
         	   zplp.detach_child_plate(lp.parentlpid, k.fromlpid, in_toloc, null, null,
               	   'A', in_user, 'DP', l_msg);
         	   if l_msg is not null then
	               out_error := 'Y';
   	            out_message := l_msg;
      	         return;
         	   end if;

	            update plate
   	            set qtytasked = null
      	         where lpid in (select lpid from plate
         	                        start with lpid = k.fromlpid
            	                     connect by prior lpid = parentlpid);
      	   else
         	   update plate
            	   set status = 'A',
	                   location = in_toloc,
                	    lastoperator = in_user,
                	    lastuser = in_user,
                	    lastupdate = sysdate,
                	    qtytasked = null,
                	    lasttask = 'DP'
            	   where lpid in (select lpid from plate
                              	   start with lpid = k.fromlpid
                              	   connect by prior lpid = parentlpid);
      	   end if;

	         zoh.add_orderhistory_item(k.orderid, k.shipid, k.fromlpid, in_item, in_lotnumber,
			   	   'De-pick Plate', 'Qty:' || k.quantity, in_user, l_msg);
         end if;
      end if;

      if not l_kidprocessed then
			upd_depicked_inventory(k.lpid, in_tolpid, in_toloc, l_qty, in_user,
					l_qtydpk * k.unitweight, l_err, l_msg);
   	   if l_msg is not null then
  	   	   out_error := l_err;
        		out_message := l_msg;
	         return;
   	  	end if;

		   if in_fromistote = 'Y' then
            if (k.type = 'F') and (k.fromlpid != nvl(k.totechild, '(none)')) then
			      zrf.decrease_lp(k.fromlpid, in_custid, in_item, l_qty, in_lotnumber,
    				      in_baseuom, in_user, 'DP', k.invstatus, k.inventoryclass, l_err, l_msg);
               if l_msg is not null then
  	               out_error := l_err;
        	         out_message := l_msg;
                  return;
     	         end if;
		      end if;

		      if k.totechild is not null then
			      zrf.decrease_lp(k.totechild, in_custid, in_item, l_qty, in_lotnumber,
    				      in_baseuom, in_user, 'DP', k.invstatus, k.inventoryclass, l_err, l_msg);
               if l_msg is not null then
  	               out_error := l_err;
        	         out_message := l_msg;
                  return;
     	         end if;
		      end if;
         end if;
		end if;

		sp := k;
  		while sp.lpid is not null
  		loop

  			if l_qty = sp.quantity then
            delete multishipdtl
               where cartonid = sp.lpid;

            if sp.type = 'F' then
               delete multishipdtl
                  where cartonid = sp.fromlpid;
               if sp.fromlpid != in_tolpid then
                  delete from plate
                  where lpid = sp.fromlpid;
               end if;
            else
               delete multishipdtl
                  where cartonid in (select lpid from plate
                  		where parentlpid = sp.lpid
                          and type = 'XP');
            end if;

            delete shippingplate
               where rowid = sp.rowid;

            delete plate
               where parentlpid = sp.lpid
                 and type = 'XP';
			else
				if in_dpkuom = k.pickuom then
               update shippingplate
  	               set quantity = quantity - l_qty,
        	             weight = weight - (l_qtydpk * sp.unitweight),
  	               	 pickqty = pickqty - l_qtydpk,
           	          lastuser = in_user,
              	       lastupdate = sysdate
              	   where rowid = sp.rowid;
         	else
               update shippingplate
  	               set quantity = quantity - l_qty,
        	             weight = weight - (l_qtydpk * sp.unitweight),
  	               	 pickqty = quantity - l_qty,
                      pickuom = unitofmeasure,
           	          lastuser = in_user,
              	       lastupdate = sysdate
              	   where rowid = sp.rowid;
          	end if;
         end if;

			if sp.type in ('F','P') then
	        	decrement_picked(sp.orderid, sp.shipid, in_custid, sp.orderitem, sp.orderlot,
   	           	l_qty, in_baseuom, l_qtydpk, in_dpkuom, sp.status, in_user,
						l_qtydpk * sp.unitweight,
                  sp.inventoryclass, sp.invstatus, in_item, in_lotnumber, l_msg);
      	   if l_msg is not null then
         	   out_error := 'Y';
            	out_message := l_msg;
	            return;
   	      end if;
			end if;

    		sp.lpid := null;
     		if sp.parentlpid is not null then
           	open c_sp(sp.parentlpid, in_dpkuom);
           	fetch c_sp into sp;
           	close c_sp;
     		end if;
  		end loop;

  		adjust_order_and_load(k.orderid, k.shipid, k.facility, in_user, 'Y', l_msg);
  		if l_msg is not null then
     		out_error := 'Y';
     		out_message := l_msg;
         return;
  		end if;

  		l_remaining := l_remaining - l_qty;
     	exit when l_remaining = 0;
   end loop;
  	close c_ship_kids;

   if l_remaining != 0 then
   	out_message := 'Quantity not avail';
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end depick_item;


procedure depick_qty_from_shipplate
	(in_lpid         in varchar2,
	 in_qty		     in number,
    in_uom          in varchar2,
    in_location     in varchar2,
    in_user         in varchar2,
    out_errmsg  	  out varchar2)
is
	cursor c_sp(p_lpid varchar2, p_uom varchar2) is
   	select rowid, custid, item, unitofmeasure, quantity, type, fromlpid, orderid,
      		 shipid, lotnumber, orderitem, orderlot, status, facility, parentlpid,
             inventoryclass, invstatus, ucc128,
             zcwt.ship_lp_item_weight(lpid, custid, item, p_uom) as unitweight
      	from shippingplate
         where lpid = p_lpid;
	sp c_sp%rowtype;
	cursor c_lp(p_lpid varchar2) is
   	select quantity, location,
             zcwt.lp_item_weight(lpid, custid, item, unitofmeasure) as unitweight
      	from plate
         where lpid = p_lpid;
	lp c_lp%rowtype;
   l_found boolean;
   l_baseqty shippingplate.quantity%type;
   l_lpid plate.lpid%type;
   l_msg varchar2(255);
   l_qtyrem shippingplate.quantity%type;
   l_xreflpid plate.lpid%type;
   l_ucc128 shippingplate.ucc128%type;

   procedure void_ai_labels
      (in_barcode in varchar2)
   is
      l_auxtable caselabels.auxtable%type;
      l_auxkey caselabels.auxkey%type;
   begin
      if in_barcode is not null then
         delete multishipdtl
            where cartonid = in_barcode;
         delete caselabels
            where barcode = in_barcode
            returning auxtable, auxkey into l_auxtable, l_auxkey;
         if sql%rowcount != 0
         and l_auxtable is not null
         and l_auxkey is not null then
            execute immediate 'delete ' || l_auxtable
                  || ' where ' || l_auxkey || ' = '''
                  || in_barcode || '''';
         end if;
      end if;
   end void_ai_labels;
begin
	out_errmsg := 'OKAY';

	open c_sp(in_lpid, in_uom);
 	fetch c_sp into sp;
  	l_found := c_sp%found;
  	close c_sp;

   if not l_found then
   	out_errmsg := 'Shippingplate for pick not found.';
      return;
  	end if;

	l_baseqty := zlbl.uom_qty_conv(sp.custid, sp.item, in_qty, in_uom, sp.unitofmeasure);
	if l_baseqty > sp.quantity then
   	out_errmsg := 'Requested quantity larger than depickable amount';
      return;
   end if;

	open c_lp(sp.fromlpid);
 	fetch c_lp into lp;
  	l_found := c_lp%found;
  	close c_lp;

   l_lpid := sp.fromlpid;
   if not l_found then
      insert into plate
         select * from deletedplate
         where lpid = sp.fromlpid;
      delete deletedplate
         where lpid = sp.fromlpid;
      open c_lp(sp.fromlpid);
      fetch c_lp into lp;
      close c_lp;
      lp.quantity := 0;
   elsif lp.location != in_location then
      zrf.get_next_lpid(l_lpid, l_msg);
      if l_msg is not null then
 		   out_errmsg := 'Error getting next lpid: ' || l_msg;
         return;
      end if;

		rfbp.dupe_lp(sp.fromlpid, l_lpid, in_location, 'A', l_baseqty, in_user, null, 'DP',
            null, l_msg);
      if l_msg is not null then
 		   out_errmsg := 'Error building lp: ' || l_msg;
         return;
      end if;
      lp.quantity := 0;
   elsif sp.type = 'F' then
      lp.quantity := 0;
   end if;

   update plate
      set location = in_location,
          status = 'A',
          quantity = lp.quantity + l_baseqty,
          lastoperator = in_user,
          lasttask = 'DP',
          lastuser = in_user,
          lastupdate = sysdate,
          weight = (lp.quantity + l_baseqty) * lp.unitweight,
          qtytasked = null
		where lpid = l_lpid;

   update shippingplate
      set quantity = quantity - l_baseqty,
          weight = weight - (in_qty * sp.unitweight),
  	       pickqty = quantity - l_baseqty,
          pickuom = unitofmeasure
      where rowid = sp.rowid
  		returning quantity into l_qtyrem;
	if l_qtyrem = 0 then
      delete shippingplate
      	where rowid = sp.rowid;
      delete multishipdtl
         where cartonid = in_lpid;
      if sp.type = 'F' then
         delete multishipdtl
            where cartonid = sp.fromlpid;
      end if;
      void_ai_labels(sp.ucc128);
	end if;

   if sp.parentlpid is not null then
      update shippingplate
      	set quantity = quantity - l_baseqty,
         	 weight = weight - (in_qty * sp.unitweight)
      	where lpid = sp.parentlpid
         returning quantity, fromlpid, ucc128
            into l_qtyrem, l_xreflpid, l_ucc128;
		if l_qtyrem = 0 then
         delete multishipdtl
            where cartonid = sp.parentlpid;
         delete multishipdtl
				where cartonid = l_xreflpid;
         delete shippingplate
            where lpid = sp.parentlpid;
			delete plate
				where lpid = l_xreflpid;
         void_ai_labels(l_ucc128);
      end if;
   end if;

	zoh.add_orderhistory_item(sp.orderid, sp.shipid, l_lpid, sp.item, sp.lotnumber,
			'De-pick Plate', 'Qty:' || l_baseqty, in_user, l_msg);

	decrement_picked(sp.orderid, sp.shipid, sp.custid, sp.orderitem, sp.orderlot,
   	   l_baseqty, sp.unitofmeasure, in_qty, in_uom, sp.status, in_user,
			in_qty * sp.unitweight,
         sp.inventoryclass, sp.invstatus, sp.item, sp.lotnumber, l_msg);
   if l_msg is null then
  		adjust_order_and_load(sp.orderid, sp.shipid, sp.facility, in_user, 'Y', l_msg);
   end if;
  	if l_msg is not null then
	   out_errmsg := 'Error updating order: ' || l_msg;
  	end if;

exception when others then
  out_errmsg := sqlerrm;

end depick_qty_from_shipplate;


end depicking;
/

show errors package body depicking;
exit;
