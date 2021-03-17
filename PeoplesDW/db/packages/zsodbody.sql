create or replace package body alps.zshiporder as
--
-- $Id$
--


-- Types


type pick_rec is record (
   taskid shippingplate.taskid%type,
   fromlpid shippingplate.fromlpid%type,
   custid shippingplate.custid%type,
   item shippingplate.item%type,
   orderitem shippingplate.orderitem%type,
   orderlot shippingplate.orderlot%type,
   orderid shippingplate.orderid%type,
   shipid shippingplate.shipid%type,
   dropseq shippingplate.dropseq%type,
   facility shippingplate.facility%type,
   location shippingplate.location%type,
   uom shippingplate.unitofmeasure%type,
   type shippingplate.type%type,
   tasktype subtasks.tasktype%type,
   picktotype subtasks.picktotype%type,
   strowid varchar2(20),
   quantity shippingplate.quantity%type,
   loadno shippingplate.loadno%type,
   stopno shippingplate.stopno%type,
   receipt plate.orderid%type,
   invstatusind orderdtl.invstatusind%type,
   invstatus orderdtl.invstatus%type,
   invclassind orderdtl.invclassind%type,
   inventoryclass orderdtl.inventoryclass%type,
   pickingzone subtasks.pickingzone%type,
   lpid shippingplate.lpid%type,
   lotrequired custitem.lotrequired%type,
   pickuom shippingplate.pickuom%type,
   lotnumber plate.lotnumber%type,
   extraok customer.ok_to_pick_unreleased_ai%type,
   ordertype orderhdr.ordertype%type,
   orderedbyweight varchar2(1),
   allowoverpicking customer_aux.allow_overpicking%type);

type anylptype is record (
   lpid plate.lpid%type,
   quantity plate.quantity%type,
   weight plate.weight%type);
type anylpcur is ref cursor return anylptype;


-- Private procedures


procedure decrement_qtytasked
	(in_lpid in varchar2,
    in_qty  in number,
    out_msg out varchar2)
is
   l_qtytasked plate.qtytasked%type := 0;
begin
	out_msg := null;

   begin
      select nvl(qtytasked,0) into l_qtytasked
         from plate
         where lpid = in_lpid;
   exception when OTHERS then
      null;
   end;

   if l_qtytasked >= in_qty then
      l_qtytasked := l_qtytasked - in_qty;
   else
      l_qtytasked := null;
   end if;
   update plate
      set qtytasked = l_qtytasked
      where lpid = in_lpid;

exception
   when OTHERS then
  	   out_msg := sqlerrm;
end decrement_qtytasked;


procedure build_extra_pick
	(in_lotno	 in varchar2,
    in_receipt  in number,
    in_location in varchar2,
    in_qty		 in number,
    in_uom      in varchar2,
    in_stageloc in varchar2,
    in_user     in varchar2,
    in_facility in varchar2,
    in_custid   in varchar2,
    in_item     in varchar2,
    in_orderid  in number,
    in_shipid   in number,
    io_pr       in out pick_rec,
    out_msg     out varchar2)
is
   type cv_typ is ref cursor;
   l_cv cv_typ;
   cursor c_cu(p_custid varchar2) is
      select ok_to_pick_unreleased_ai
         from customer
         where custid = p_custid;
   cursor c_od(p_orderid number, p_shipid number, p_item varchar2, p_lotnumber varchar2) is
      select invstatusind, invstatus, invclassind, inventoryclass, lotnumber
         from orderdtl
         where orderid = p_orderid
           and shipid = p_shipid
           and item = p_item
           and nvl(lotnumber, '(none)') = nvl(p_lotnumber, '(none)');
   cursor c_ci(p_custid varchar2, p_item varchar2) is
      select lotrequired, baseuom
         from custitemview
         where custid = p_custid
           and item = p_item;
   cursor c_oh(p_orderid number, p_shipid number) is
      select loadno, stopno, shipno, wave
         from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   oh c_oh%rowtype;
   cursor c_lo(p_facility varchar2, p_locid varchar2) is
      select pickingzone, section, equipprof, pickingseq
         from location
         where facility = p_facility
           and locid = p_locid;
   frlo c_lo%rowtype;
   tolo c_lo%rowtype;
   l_sql varchar2(2000);
   l_avail number;
   l_weight plate.weight%type;
   l_cube tasks.cube%type;
   l_invstatus plate.invstatus%type;
   l_invclass plate.inventoryclass%type;
   l_found boolean;
begin
	out_msg := null;

   io_pr := null;
   open c_cu(in_custid);
   fetch c_cu into io_pr.extraok;
   close c_cu;

   if nvl(io_pr.extraok, 'N') != 'Y' then
      out_msg := 'Quantity not available';
      return;
   end if;

   open c_od(in_orderid, in_shipid, in_item, in_lotno);
   fetch c_od into io_pr.invstatusind,
                   io_pr.invstatus,
                   io_pr.invclassind,
                   io_pr.inventoryclass,
                   io_pr.orderlot;
   l_found := c_od%found;
   close c_od;
   if not l_found then
      open c_od(in_orderid, in_shipid, in_item, null);
      fetch c_od into io_pr.invstatusind,
                      io_pr.invstatus,
                      io_pr.invclassind,
                      io_pr.inventoryclass,
                      io_pr.orderlot;
      close c_od;
   end if;

   l_sql := 'select nvl(sum(qty),0) as qty from custitemtotsumavailview '
         || 'where facility = ''' || in_facility || ''''
         || '  and custid = ''' || in_custid || ''''
         || '  and item = ''' || in_item || ''''
         || '  and uom = ''' || in_uom || '''';
   if rtrim(in_lotno) is not null then
      l_sql := l_sql || ' and lotnumber = ''' || in_lotno || '''';
   end if;
   if rtrim(io_pr.invstatus) is not null then
      l_sql := l_sql || ' and invstatus '
            || zcm.in_str_clause(io_pr.invstatusind, io_pr.invstatus);
   end if;
   if rtrim(io_pr.inventoryclass) is not null then
      l_sql := l_sql || ' and inventoryclass '
            || zcm.in_str_clause(io_pr.invclassind, io_pr.inventoryclass);
   end if;

   begin
      execute immediate l_sql into l_avail;
   exception
      when OTHERS then
         l_avail := 0;
   end;

   if l_avail < in_qty then
      out_msg := 'Quantity not available';
      return;
   end if;

   l_sql := 'select lpid, quantity, invstatus, inventoryclass from plate '
         || 'where facility = ''' || in_facility || ''''
         || '  and custid = ''' || in_custid || ''''
         || '  and item = ''' || in_item || ''''
         || '  and location = ''' || in_location || ''''
         || '  and orderid = ' || in_receipt
         || '  and type = ''PA'' '
         || '  and quantity > 0 ';
   if rtrim(in_lotno) is not null then
      l_sql := l_sql || ' and lotnumber = ''' || in_lotno || '''';
   end if;
   if rtrim(io_pr.invstatus) is not null then
      l_sql := l_sql || ' and invstatus '
            || zcm.in_str_clause(io_pr.invstatusind, io_pr.invstatus);
   end if;
   if rtrim(io_pr.inventoryclass) is not null then
      l_sql := l_sql || ' and inventoryclass '
            || zcm.in_str_clause(io_pr.invclassind, io_pr.inventoryclass);
   end if;
   l_sql := l_sql || ' order by quantity ';

   open l_cv for l_sql;
   fetch l_cv into io_pr.fromlpid, io_pr.quantity, l_invstatus, l_invclass;
   if l_cv%notfound then
      io_pr.fromlpid := null;
   end if;
   close l_cv;

   io_pr.quantity := least(io_pr.quantity, in_qty);

   if io_pr.fromlpid is null then
      out_msg := 'Quantity not available';
      return;
   end if;

   zsp.get_next_shippinglpid(io_pr.lpid, out_msg);
   if out_msg is not null then
      return;
   end if;

	ztsk.get_next_taskid(io_pr.taskid, out_msg);
   if out_msg is not null then
      return;
   end if;

   open c_ci(in_custid, in_item);
   fetch c_ci into io_pr.lotrequired, io_pr.uom;
   close c_ci;

   open c_oh(in_orderid, in_shipid);
   fetch c_oh into oh;
   close c_oh;
   io_pr.loadno := oh.loadno;
   io_pr.stopno := oh.stopno;

   open c_lo(in_facility, in_location);
   fetch c_lo into frlo;
   close c_lo;
   io_pr.pickingzone := frlo.pickingzone;

   io_pr.custid := in_custid;
   io_pr.item := in_item;
   io_pr.orderitem := in_item;
   io_pr.orderid := in_orderid;
   io_pr.shipid := in_shipid;
   io_pr.dropseq := null;
   io_pr.facility := in_facility;
   io_pr.location := in_location;
   io_pr.type := 'P';
   io_pr.tasktype := 'OP';
   io_pr.picktotype := 'FULL';
   io_pr.receipt := in_receipt;
   io_pr.pickuom := io_pr.uom;
   io_pr.lotnumber := in_lotno;

   l_weight := io_pr.quantity * zcwt.lp_item_weight(io_pr.fromlpid, io_pr.custid,
         io_pr.item, io_pr.uom);
   l_cube := io_pr.quantity * zci.item_cube(io_pr.custid, io_pr.item, io_pr.uom);

   open c_lo(in_facility, in_stageloc);
   fetch c_lo into tolo;
   close c_lo;

	insert into tasks
   	(taskid, tasktype, facility, fromsection,
       fromloc, fromprofile, tosection, toloc,
       toprofile, touserid, custid, item,
       lpid, uom, qty, locseq,
       loadno, stopno, shipno, orderid,
       shipid, orderitem, orderlot, priority,
	    prevpriority, curruserid, lastuser, lastupdate,
       pickuom, pickqty, picktotype, wave,
       pickingzone, cartontype, weight, cube,
	    staffhrs, cartonseq, clusterposition, convpickloc,
       step1_complete)
   values
      (io_pr.taskid, io_pr.tasktype, io_pr.facility, frlo.section,
       io_pr.location, frlo.equipprof, tolo.section, in_stageloc,
       tolo.equipprof, '(AggInven)', io_pr.custid, null,
       null, null, io_pr.quantity, frlo.pickingseq,
  	    io_pr.loadno, io_pr.stopno, oh.shipno, io_pr.orderid,
       io_pr.shipid, null, null, '9',
       '3', null, in_user, sysdate,
       null, io_pr.quantity, null, oh.wave,
       io_pr.pickingzone, null, l_weight, l_cube,
       null, null, null, null,
       null);

   insert into subtasks
      (taskid, tasktype, facility, fromsection,
       fromloc, fromprofile, tosection, toloc,
       toprofile, touserid, custid, item,
       lpid, uom, qty, locseq,
       loadno, stopno, shipno, orderid,
       shipid, orderitem, orderlot, priority,
	    prevpriority, curruserid, lastuser, lastupdate,
       pickuom, pickqty, picktotype, wave,
       pickingzone, cartontype, weight, cube,
       staffhrs, cartonseq, shippinglpid, shippingtype,
       cartongroup, qtypicked, labeluom, step1_complete)
   values
      (io_pr.taskid, io_pr.tasktype, io_pr.facility, frlo.section,
       io_pr.location, frlo.equipprof, tolo.section, in_stageloc,
       tolo.equipprof, null, io_pr.custid, io_pr.item,
       io_pr.fromlpid, io_pr.uom, io_pr.quantity, frlo.pickingseq,
  	    io_pr.loadno, io_pr.stopno, oh.shipno, io_pr.orderid,
       io_pr.shipid, io_pr.orderitem, io_pr.orderlot, '3',
       '3', null, in_user, sysdate,
       io_pr.pickuom,  io_pr.quantity, io_pr.picktotype, oh.wave,
       io_pr.pickingzone, 'NONE', l_weight, l_cube,
       null, 1, io_pr.lpid, io_pr.type,
       null, null, null, null)
   returning rowid into io_pr.strowid;

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
       carriercodeused, satdeliveryused, openfacility, audited,
       prevlocation, fromlpidparent, rmatrackingno, actualcarrier,
       manufacturedate, expirationdate)
   values
      (io_pr.lpid, io_pr.item, io_pr.custid, io_pr.facility,
       io_pr.location, 'U', null, io_pr.uom,
       io_pr.quantity, io_pr.type, io_pr.fromlpid, null,
       io_pr.lotnumber, null, null, null,
       null, in_user, sysdate, l_invstatus,
       io_pr.quantity, io_pr.item, io_pr.uom, l_invclass,
       io_pr.loadno, io_pr.stopno, oh.shipno, io_pr.orderid,
       io_pr.shipid, l_weight, null, null,
       io_pr.taskid, io_pr.dropseq, io_pr.orderlot, io_pr.pickuom,
       io_pr.quantity, null, 1, null,
       null, null, null, null,
       null, null, io_pr.facility, null,
       null, null, null, null,
       null, null);

   begin
      insert into commitments
         (facility, custid, item, inventoryclass,
          invstatus, status, lotnumber, uom,
          qty, orderid, shipid, orderitem,
          orderlot, priority, lastuser, lastupdate)
      values
         (io_pr.facility, io_pr.custid, io_pr.item, l_invclass,
          l_invstatus, 'CM', io_pr.lotnumber, io_pr.uom,
          io_pr.quantity, io_pr.orderid, io_pr.shipid, io_pr.orderitem,
          io_pr.orderlot, 'A', in_user, sysdate);
   exception when dup_val_on_index then
      update commitments
         set qty = qty + io_pr.quantity,
             priority = 'A',
             lastuser = in_user,
             lastupdate = sysdate
         where facility = io_pr.facility
           and custid = io_pr.custid
           and item = io_pr.item
           and inventoryclass = l_invclass
           and invstatus = l_invstatus
           and status = 'CM'
           and nvl(lotnumber,'(none)') = nvl(io_pr.lotnumber,'(none)')
           and orderid = io_pr.orderid
           and shipid = io_pr.shipid
           and orderitem = io_pr.orderitem
           and nvl(orderlot,'(none)') = nvl(io_pr.orderlot,'(none)');
   end;

	out_msg := 'OKAY';

exception
   when OTHERS then
  	   out_msg := sqlerrm;
end build_extra_pick;


procedure build_outbound_load
	(in_loadno       in number,
    in_orderid      in number,
	 in_shipid       in number,
	 in_carrier      in varchar2,
	 in_trailer      in varchar2,
	 in_seal         in varchar2,
	 in_billoflading in varchar2,
 	 in_stageloc     in varchar2,
	 in_doorloc      in varchar2,
	 in_user         in varchar2,
	 io_stopno       in out number,
	 io_shipno       in out number,
	 out_msg         out varchar2)
is
	cursor c_oh is
  		select nvl(orderstatus,'?') as orderstatus,
             nvl(ordertype,'?') as ordertype,
             nvl(fromfacility,' ') as fromfacility,
             nvl(qtyorder,0) as qtyorder,
             nvl(weightorder,0) as weightorder,
             nvl(cubeorder,0) as cubeorder,
             nvl(amtorder,0) as amtorder,
             nvl(qtyship,0) as qtyship,
             nvl(weightship,0) as weightship,
             nvl(cubeship,0) as cubeship,
             nvl(amtship,0) as amtship,
             nvl(weight_entered_lbs,0) as weight_entered_lbs,
             nvl(weight_entered_kgs,0) as weight_entered_kgs,
             carrier
    		from orderhdr
   		where orderid = in_orderid
     		  and shipid = in_shipid;
	oh c_oh%rowtype;

   l_found boolean;
	newloadstatus varchar2(2);
begin
	out_msg := '';

	open c_oh;
	fetch c_oh into oh;
   l_found := c_oh%found;
   close c_oh;
	if not l_found then
  		out_msg := 'Order header not found: ' || in_orderid || '-' || in_shipid;
  		return;
	end if;

  	io_stopno := 1;
  	io_shipno := 1;

  	insert into loads
   	(loadno, entrydate, loadstatus, trailer, seal, facility,
       doorloc, stageloc, carrier, statususer, statusupdate,
       lastuser, lastupdate, billoflading, loadtype)
  	values
   	(in_loadno, sysdate, '2', in_trailer, in_seal, oh.fromfacility,
    	 in_doorloc, in_stageloc, in_carrier, in_user, sysdate,
    	 in_user, sysdate, in_billoflading,
       decode(oh.ordertype, 'T', 'OUTT', 'U', 'OUTT', 'OUTC'));


  	insert into loadstop
   	(loadno, stopno, entrydate, loadstopstatus, statususer, statusupdate,
    	 lastuser,lastupdate)
  	values
   	(in_loadno, io_stopno, sysdate, '2', in_user, sysdate,
    	 in_user, sysdate);

  	insert into loadstopship
   	(loadno, stopno, shipno, entrydate, qtyorder, weightorder,
    	 cubeorder, amtorder, qtyship, weightship, cubeship,
       amtship, lastuser, lastupdate, weight_entered_lbs, weight_entered_kgs)
  	values
   	(in_loadno, io_stopno, io_shipno, sysdate, oh.qtyorder, oh.weightorder,
    	 oh.cubeorder, oh.amtorder, oh.qtyship, oh.weightship, oh.cubeship,
       oh.amtship, in_user, sysdate, oh.weight_entered_lbs, oh.weight_entered_kgs);

  	update orderhdr
   	set loadno = in_loadno,
          stopno = io_stopno,
          shipno = io_shipno,
          carrier = nvl(rtrim(in_carrier), oh.carrier),
          lastuser = in_user,
          lastupdate = sysdate
   	where orderid = in_orderid
     	 and shipid = in_shipid;

   update shippingplate
      set loadno = in_loadno,
          stopno = io_stopno,
          shipno = io_shipno,
          lastuser = in_user,
          lastupdate = sysdate
    where orderid = in_orderid
      and shipid = in_shipid;

   update subtasks
      set loadno = in_loadno,
          stopno = io_stopno,
          shipno = io_shipno,
          lastuser = in_user,
          lastupdate = sysdate
    where orderid = in_orderid
      and shipid = in_shipid;

   update tasks
      set loadno = in_loadno,
          stopno = io_stopno,
          shipno = io_shipno,
          lastuser = in_user,
          lastupdate = sysdate
    where orderid = in_orderid
      and shipid = in_shipid;

	if oh.orderstatus > '3' then
  		if oh.orderstatus > '4' then
    		newloadstatus := '5';
  		else
    		newloadstatus := '3';
  		end if;
  		zld.min_load_status(in_loadno, oh.fromfacility, newloadstatus, in_user);
  		zld.min_loadstop_status(in_loadno, io_stopno, oh.fromfacility, newloadstatus, in_user);
	end if;

	zoh.add_orderhistory(in_orderid, in_shipid,
  			'Order To Load',
     		'Order Assigned to Load '||in_loadno||'/'||io_stopno||'/'||io_shipno,
     		in_user, out_msg);

	out_msg := 'OKAY';

exception
   when OTHERS then
  	   out_msg := sqlerrm;
end build_outbound_load;


-- Public procedures


procedure pick_shippingplate
	(in_lpid         in varchar2,
	 in_lotno	     in varchar2,
    in_receipt      in number,
    in_location     in varchar2,
    in_qty		     in number,
    in_uom          in varchar2,
    in_weight       in number,
    in_stageloc     in varchar2,
    in_user         in varchar2,
    in_pickfororder in varchar2,
    in_facility     in varchar2,
    in_custid       in varchar2,
    in_item         in varchar2,
    in_orderid      in number,
    in_shipid       in number,
    out_errmsg      out varchar2)
is
	cursor c_pk_lpid is
   	select SP.taskid,
      		 SP.fromlpid,
             SP.custid,
             SP.item,
             SP.orderitem,
             SP.orderlot,
             SP.orderid,
             SP.shipid,
             SP.dropseq,
             SP.facility,
             SP.location,
             SP.unitofmeasure,
             SP.type,
             ST.tasktype,
             ST.picktotype,
             rowidtochar(ST.rowid),
             SP.quantity,
             SP.loadno,
             SP.stopno,
             P.orderid,
             OD.invstatusind,
             OD.invstatus,
             OD.invclassind,
             OD.inventoryclass,
             ST.pickingzone,
             SP.lpid,
             CV.lotrequired,
             SP.pickuom,
             P.lotnumber,
             CU.ok_to_pick_unreleased_ai,
             OH.ordertype,
             zwt.is_ordered_by_weight(SP.orderid, SP.shipid, SP.orderitem, SP.orderlot),
             nvl(CX.allow_overpicking,'N')
      	from shippingplate SP, subtasks ST, plate P, orderdtl OD, custitemview CV,
              customer CU, orderhdr OH, customer_aux CX
         where SP.lpid = in_lpid
           and ST.taskid = SP.taskid
           and ST.shippinglpid = SP.lpid
           and P.lpid (+) = SP.fromlpid
           and OD.orderid = SP.orderid
           and OD.shipid = SP.shipid
           and OD.item = SP.orderitem
           and nvl(OD.lotnumber, '(none)') = nvl(SP.orderlot, '(none)')
           and CV.custid = SP.custid
           and CV.item = SP.item
           and CU.custid = SP.custid
           and OH.orderid = SP.orderid
           and OH.shipid = SP.shipid
           and CX.custid = SP.custid;
	cursor c_pk_item is
   	select SP.taskid,
      		 SP.fromlpid,
             SP.custid,
             SP.item,
             SP.orderitem,
             SP.orderlot,
             SP.orderid,
             SP.shipid,
             SP.dropseq,
             SP.facility,
             ST.fromloc,
             SP.unitofmeasure,
             SP.type,
             ST.tasktype,
             ST.picktotype,
             rowidtochar(ST.rowid),
             ST.qty-nvl(ST.qtypicked,0),
             SP.loadno,
             SP.stopno,
             P.orderid,
             OD.invstatusind,
             OD.invstatus,
             OD.invclassind,
             OD.inventoryclass,
             ST.pickingzone,
             SP.lpid,
             CV.lotrequired,
             SP.pickuom,
             P.lotnumber,
             CU.ok_to_pick_unreleased_ai,
             OH.ordertype,
             zwt.is_ordered_by_weight(SP.orderid, SP.shipid, SP.orderitem, SP.orderlot),
             nvl(CX.allow_overpicking,'N')
      	from shippingplate SP, subtasks ST, plate P, orderdtl OD, custitemview CV,
              customer CU, orderhdr OH, customer_aux CX
         where SP.facility = in_facility
           and SP.custid = in_custid
           and SP.item = in_item
           and nvl(SP.lotnumber,'(none)') = nvl(in_lotno,'(none)')
           and SP.orderid = in_orderid
           and SP.shipid = in_shipid
           and ST.taskid = SP.taskid
           and ST.shippinglpid = SP.lpid
           and P.lpid (+) = SP.fromlpid
           and OD.orderid = SP.orderid
           and OD.shipid = SP.shipid
           and OD.item = SP.orderitem
           and nvl(OD.lotnumber, '(none)') = nvl(SP.orderlot, '(none)')
           and CV.custid = SP.custid
           and CV.item = SP.item
           and CU.custid = SP.custid
           and OH.orderid = SP.orderid
           and OH.shipid = SP.shipid
           and CX.custid = SP.custid;
  	pk pick_rec;
   l_found boolean := false;
   l_key number := 0;
   l_msg varchar2(255);
   l_err varchar2(1);
   l_qty shippingplate.quantity%type;
   l_qtyremain shippingplate.quantity%type := in_qty;
   l_weight shippingplate.weight%type;
   l_weightremain shippingplate.weight%type := in_weight;
	l_is_loaded varchar2(1);

   procedure pick_it
      (p_lpid     in varchar2,
       p_qty      in number,
       p_weight   in number,
       out_errmsg out varchar2)
   is
      c_any_lp anylpcur;
      l anylptype;
      l_qtyneeded shippingplate.quantity%type;
      l_orig_pickqty shippingplate.quantity%type;
      l_lpid shippingplate.lpid%type;
      l_msg varchar2(255);
      l_mlip plate.lpid%type;
      l_invstatus plate.invstatus%type;
      l_invclass plate.inventoryclass%type;
      l_qtypicked shippingplate.quantity%type;
      l_pickqty shippingplate.quantity%type;
      l_lpcount number;
      l_err varchar2(1);
      l_strowid varchar2(20);
      l_weightneeded shippingplate.weight%type := p_weight;
      l_weightpicked shippingplate.weight%type;
   begin
	   out_errmsg := 'OKAY';

		l_qtyneeded := zlbl.uom_qty_conv(pk.custid, pk.item, p_qty, in_uom, pk.uom);
		l_orig_pickqty := zlbl.uom_qty_conv(pk.custid, pk.item, l_qtyneeded, pk.uom, pk.pickuom);
		if p_lpid = '(none)' then
	   	zsp.get_next_shippinglpid(l_lpid, l_msg);
	   	if l_msg is not null then
 				out_errmsg := 'No next shippinglpid: ' || l_msg;
	         return;
		   end if;

	      insert into subtasks
   	      (taskid, tasktype, facility, fromsection, fromloc, fromprofile, tosection,
      	    toloc, toprofile, touserid, custid, item, lpid, uom, qty, locseq,
         	 loadno, stopno, shipno, orderid, shipid, orderitem, orderlot, priority,
	          prevpriority, curruserid, lastuser, lastupdate, pickuom, pickqty, picktotype,
   	       wave, pickingzone, cartontype,
      	    weight,
         	 cube,
	          staffhrs, cartonseq, shippinglpid, shippingtype,
   	       cartongroup, qtypicked)
			select taskid, tasktype, facility, fromsection, fromloc, fromprofile, tosection,
	             toloc, toprofile, touserid, custid, item, lpid, uom, l_qtyneeded, locseq,
   	          loadno, stopno, shipno, orderid, shipid, orderitem, orderlot, priority,
      	 		 prevpriority, curruserid, in_user, sysdate, pickuom, l_orig_pickqty, picktotype,
         	    wave, pickingzone, cartontype,
					 p_qty*zcwt.lp_item_weight(lpid, custid, item, in_uom),
	       		 p_qty*zci.item_cube(custid, item, in_uom),
   	    		 null, cartonseq, l_lpid, shippingtype,
      	       cartongroup, null
				from subtasks
	   		where rowid = chartorowid(pk.strowid);

      	select rowidtochar(rowid) into l_strowid
         	from subtasks
            where taskid = pk.taskid
              and shippinglpid = l_lpid;

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
	      select l_lpid, item, custid, facility, location, 'U',
   	          holdreason, unitofmeasure, l_qtyneeded, type, fromlpid,
      	       serialnumber, lotnumber, null, useritem1, useritem2, useritem3,
         	    in_user, sysdate, invstatus, qtyentered, orderitem, uomentered,
	             inventoryclass, loadno, stopno, shipno, orderid, shipid,
   	          p_qty*zcwt.lp_item_weight(fromlpid, custid, item, in_uom),
      	       null, null, taskid, dropseq, orderlot, pickuom,
	             l_orig_pickqty, trackingno, cartonseq, checked, totelpid,
   	          cartontype, pickedfromloc, shippingcost, carriercodeused,
	             satdeliveryused, openfacility, audited, manufacturedate,
                expirationdate
   	      from shippingplate
	         where lpid = pk.lpid;

			pk.lpid := l_lpid;
	   end if;

      if pk.ordertype = 'U' then
         l_mlip := null;
      else
	      zrf.get_next_lpid(l_mlip, l_msg);
   	   if l_msg is not null then
 			   out_errmsg := 'No next lpid: ' || l_msg;
	         return;
   	   end if;
      end if;

      if pk.ordertype != 'O' then
         open c_any_lp for
            select pk.fromlpid, pk.quantity, p_weight
               from dual;
	 	elsif pk.lotrequired in ('N','P') then
	 		open c_any_lp for
   	   	select lpid, quantity, weight
      	   	from plate
         	   where facility = pk.facility
            	  and location = in_location
	              and custid = pk.custid
   	           and item = pk.item
      	        and type = 'PA'
         	     and status = 'A'
            	  and orderid = in_receipt
	         	order by manufacturedate, creationdate;
		else
	   	open c_any_lp for
   	    	select lpid, quantity, weight
      	   	from plate
         	   where facility = pk.facility
            	  and location = in_location
	              and custid = pk.custid
   	           and item = pk.item
      	        and lotnumber = nvl(rtrim(in_lotno),lotnumber)
         	     and type = 'PA'
            	  and status = 'A'
	              and orderid = in_receipt
   	   		order by manufacturedate, creationdate;
	  	end if;

  		loop
	    	fetch c_any_lp into l;
   	   exit when c_any_lp%notfound;

         if pk.ordertype = 'U' then
            l_msg := null;
         else
			   zrfpk.check_pick_fifo(pk.fromlpid, pk.pickuom, l_orig_pickqty, pk.pickingzone, l.lpid,
   	   		   pk.custid, pk.item, rtrim(in_lotno), l_invstatus, l_invclass, l_msg);
         end if;

			if (l_msg is null)
	      and (zrfpk.is_attrib_ok(pk.invstatusind, pk.invstatus, l_invstatus))
   	   and (zrfpk.is_attrib_ok(pk.invclassind, pk.inventoryclass, l_invclass)) then

				l_qtypicked := least(l.quantity, l_qtyneeded);
				l_pickqty := zlbl.uom_qty_conv(pk.custid, pk.item, l_qtypicked, pk.uom, pk.pickuom);

 				l_qtyneeded := l_qtyneeded - l_qtypicked;

		      if p_lpid = '(none)' then
               update subtasks
                  set lpid = l.lpid
                  where rowid = chartorowid(l_strowid);
               pk.fromlpid := l.lpid;
            end if;

-- 			there is more to pick, so we need to create a new shippingplate and subtask
	      	if l_qtyneeded != 0 then

					zrfpk.adjust_for_extra_pick(pk.strowid, pk.lpid, l_pickqty, pk.pickuom, l_qtypicked,
      	      		in_user, l.lpid, l_strowid, l_msg);
		   	   if l_msg is not null then
	   				close c_any_lp;
 					   out_errmsg := l_msg;
      			   return;
	      		end if;

               l_weightpicked := least(l.weight, l_weightneeded);
            else
               l_weightpicked := l_weightneeded;
   			end if;
 				l_weightneeded := l_weightneeded - l_weightpicked;

			   zrfpk.pick_a_plate(pk.taskid, pk.lpid, in_user, pk.fromlpid, l.lpid,
					   pk.custid, pk.item, pk.orderitem, pk.orderlot,
      		      l_qtypicked, pk.dropseq, pk.facility, in_location, pk.uom, pk.orderlot,
         	      l_mlip, pk.type, pk.tasktype, pk.picktotype, pk.location, pk.strowid,
            		null, null, rtrim(in_lotno), null, null, null, null, pk.pickuom, l_pickqty,
	            	l_weightpicked, pk.fromlpid, l_lpcount, l_err, l_msg);
   	   	if l_msg is not null then
   				close c_any_lp;
   	   		out_errmsg := l_msg;
         		return;
		   	end if;

	      	if l_qtyneeded != 0 then
	            pk.strowid := l_strowid;
      			select shippinglpid into pk.lpid
         			from subtasks
         			where rowid = chartorowid(pk.strowid);
				end if;
   		end if;

	      exit when (l_qtyneeded = 0);
   	end loop;
   	close c_any_lp;

	   if (l_qtyneeded != 0) then
   		out_errmsg := 'Quantity not available';
      	return;
	   end if;

   exception
      when OTHERS then
         out_errmsg := sqlerrm;
   end pick_it;

begin
	out_errmsg := 'OKAY';

    if zcu.credit_hold(in_custid) = 'Y' then
      out_errmsg := 'Cannot load plate-- Customer '||in_custid||' is on credit hold';
      return;
    end if;

	zrf.so_lock(l_key);

	if in_lpid != '(none)' then
		open c_pk_lpid;
	   fetch c_pk_lpid into pk;
   	l_found := c_pk_lpid%found;
   	close c_pk_lpid;
      if l_found then
--       undo existing qtytasked
         if pk.ordertype = 'O' then
            deplete_shippinglpid_qtytasked(in_lpid, l_msg);
         else
            decrement_qtytasked(pk.fromlpid, pk.quantity, l_msg);
         end if;
         if l_msg is not null then
            out_errmsg := l_msg;
            return;
         end if;

         if (pk.orderedbyweight = 'N') and (pk.allowoverpicking = 'N') then
            l_qtyremain := least(l_qtyremain, pk.quantity);
         end if;
         if l_qtyremain != in_qty then
            l_weightremain := l_weightremain * (l_qtyremain / in_qty);
         end if;
         if l_qtyremain != 0 then
            savepoint pre_pick_it;
            pick_it(in_lpid, l_qtyremain, l_weightremain, l_msg);
            if l_msg not in ('OKAY', 'Quantity not available') then
   	         out_errmsg := l_msg;
               return;
  	         end if;
            if l_msg = 'OKAY' then
               l_qtyremain := in_qty - l_qtyremain;
               l_weightremain := in_weight - l_weightremain;
            else
               rollback to pre_pick_it;
            end if;
         end if;
      end if;
   end if;

   if not l_found then
      if in_qty = 0 then
         pk.orderid := in_orderid;
         pk.shipid := in_shipid;
         pk.tasktype := 'OP';
         select loadno, stopno into pk.loadno, pk.stopno
            from orderhdr
            where orderid = in_orderid
              and shipid = in_shipid;
      else
         l_qty := l_qtyremain;
         l_weight := l_weightremain;
		   open c_pk_item;
         loop
   	      fetch c_pk_item into pk;   -- need to perform 1st fetch for later sql updates
            exit when (c_pk_item%notfound) or (l_qtyremain <= 0);

            if (pk.orderedbyweight = 'N') and (pk.allowoverpicking = 'N') then
               l_qty := least(l_qtyremain, pk.quantity);
            end if;
            if l_qty > 0 then
               if l_qty = l_qtyremain then
                  l_weight := l_weightremain;
               else
                  l_weight := l_weightremain * (l_qty / l_qtyremain);
               end if;
               savepoint pre_pick_it;
               pick_it('(none)', l_qty, l_weight, l_msg);
               if l_msg not in ('OKAY', 'Quantity not available') then
   	            out_errmsg := l_msg;
   	            close c_pk_item;
                  return;
  	            end if;
               if l_msg = 'OKAY' then
                  l_qtyremain := l_qtyremain - l_qty;
                  l_weightremain := l_weightremain - l_weight;
               else
                  rollback to pre_pick_it;
               end if;
            end if;
         end loop;
   	   close c_pk_item;
      end if;
	end if;

   while l_qtyremain > 0 loop
      pk := null;
      build_extra_pick(rtrim(in_lotno), in_receipt, in_location, l_qtyremain, in_uom,
            in_stageloc, in_user, in_facility, in_custid, in_item, in_orderid,
            in_shipid, pk, l_msg);
      if l_msg = 'OKAY' then
         if l_qtyremain = least(l_qtyremain, pk.quantity) then
            l_weight := l_weightremain;
         else
            l_weight := l_weightremain * (least(l_qtyremain, pk.quantity) / l_qtyremain);
         end if;
         pick_it('(none)', least(l_qtyremain, pk.quantity), l_weight, l_msg);
      end if;
      if l_msg != 'OKAY' then
         out_errmsg := l_msg;
         return;
      end if;
      l_qtyremain := l_qtyremain - least(l_qtyremain, pk.quantity);
      l_weightremain := l_weightremain - l_weight;
   end loop;

-- stage picks and cleanup any leftover data from short picks
	if in_pickfororder in ('L','O') then

      for fix in (select ST.rowid, SP.quantity
                     from subtasks ST, shippingplate SP
                     where ST.orderid = pk.orderid
                       and ST.shipid = pk.shipid
                       and ST.tasktype = 'OP'
                       and SP.lpid = ST.shippinglpid
                       and ST.qty != SP.quantity) loop
         update subtasks
            set qty = fix.quantity
            where rowid = fix.rowid;
      end loop;
		for s in (select lpid, fromlpid from shippingplate
   				where location = in_user
      	        and orderid = pk.orderid
         	     and shipid = pk.shipid
                 and parentlpid is null) loop

			zrfpk.stage_a_plate(s.lpid, in_stageloc, in_user, pk.tasktype, 'N',
					in_stageloc, 'N', 'N', l_err, l_msg, l_is_loaded);
			if l_msg is not null then
				out_errmsg := l_msg;
				return;
			end if;
		end loop;

  		delete commitments
      	where orderid = pk.orderid
           and shipid = pk.shipid;

		delete subtasks
   		where orderid = pk.orderid
           and shipid = pk.shipid
           and tasktype = 'OP';

		delete tasks
   		where orderid = pk.orderid
           and shipid = pk.shipid
           and tasktype = 'OP';

		delete shippingplate
   		where orderid = pk.orderid
           and shipid = pk.shipid
           and status = 'U';

	   update orderhdr
   	   set orderstatus = zrf.ORD_PICKED,
      	    lastuser = in_user,
         	 lastupdate = sysdate
	      where orderid = pk.orderid
   	     and shipid = pk.shipid
      	  and orderstatus < zrf.ORD_PICKED;

	   if (sql%rowcount != 0) and (pk.loadno is not null) then
	      update loadstop
   	      set loadstopstatus = zrf.LOD_PICKED,
      	       lastuser = in_user,
         	    lastupdate = sysdate
	         where loadno = pk.loadno
   	        and stopno = pk.stopno
      	     and loadstopstatus < zrf.LOD_PICKED;
	      update loads
   	      set loadstatus = zrf.LOD_PICKED,
      	       lastuser = in_user,
         	    lastupdate = sysdate
	         where loadno = pk.loadno
	           and loadstatus < zrf.LOD_PICKED;
   	end if;
	end if;

exception
   when OTHERS then
      out_errmsg := sqlerrm;
end pick_shippingplate;


procedure load_shippingplate
	(in_lpid         in varchar2,
	 in_lotno	     in varchar2,
    in_receipt      in number,
    in_location     in varchar2,
	 in_qty		     in number,
    in_uom          in varchar2,
    in_weight       in number,
    in_stageloc     in varchar2,
    in_user         in varchar2,
    in_pickfororder in varchar2,
	 in_facility	  in varchar2,
    in_custid       in varchar2,
    in_item         in varchar2,
    in_orderid      in number,
    in_shipid       in number,
	 in_doorloc      in varchar2,
	 in_carrier      in varchar2,
	 in_billoflading in varchar2,
	 in_trailer      in varchar2,
	 in_seal         in varchar2,
    in_loadno       in number,
    in_nosetemp     in number,
    in_middletemp   in number,
    in_tailtemp     in number,
    out_errmsg  	  out varchar2)
is
	cursor c_sp_lpid is
   	select status,
      		 nvl(loadno, 0) as loadno,
             nvl(stopno, 0) as stopno,
             nvl(shipno, 0) as shipno,
             orderid,
             shipid
      	from shippingplate
         where lpid = in_lpid;
	cursor c_sp_item is
   	select 'U',
      		 nvl(loadno, 0) as loadno,
             nvl(stopno, 0) as stopno,
             nvl(shipno, 0) as shipno,
             orderid,
             shipid
      	from shippingplate
         where facility = in_facility
           and custid = in_custid
           and item = in_item
           and orderid = in_orderid
           and shipid = in_shipid;
  	sp c_sp_lpid%rowtype;
   cursor c_oh is
      select loadno,
             stopno,
             shipno
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
   l_found boolean := false;
   l_msg varchar2(255) := null;
   l_err varchar2(1);
   l_key number := 0;
	l_is_loaded varchar2(1);
begin
	out_errmsg := 'OKAY';

	zrf.so_lock(l_key);

	if in_lpid != '(none)' then
		open c_sp_lpid;
	   fetch c_sp_lpid into sp;
   	l_found := c_sp_lpid%found;
   	close c_sp_lpid;
	end if;

   if not l_found then
		open c_sp_item;
   	fetch c_sp_item into sp;
   	if c_sp_item%notfound then
         sp.status := 'U';
         sp.orderid := in_orderid;
         sp.shipid := in_shipid;
         open c_oh;
         fetch c_oh into sp.loadno, sp.stopno, sp.shipno;
         close c_oh;
      end if;
   	close c_sp_item;
	end if;

	if sp.status in ('U', 'P') then
		pick_shippingplate(in_lpid, in_lotno, in_receipt, in_location, in_qty, in_uom,
    			in_weight, in_stageloc, in_user, in_pickfororder, in_facility, in_custid,
    			in_item, in_orderid, in_shipid, l_msg);
  		if substr(l_msg, 1, 4) != 'OKAY' then
      	out_errmsg := l_msg;
         return;
     	end if;
  		if (in_qty = 0) and (in_pickfororder not in ('L','O')) then
     		return;
    	end if;
	end if;

	if sp.loadno = 0 then
		build_outbound_load(in_loadno, sp.orderid, sp.shipid, in_carrier, in_trailer,
      		in_seal, in_billoflading, in_stageloc, in_doorloc, in_user, sp.stopno,
				sp.shipno, l_msg);
		sp.loadno := in_loadno;
  		if substr(l_msg, 1, 4) != 'OKAY' then
      	out_errmsg := l_msg;
         return;
     	end if;
	end if;

	if in_pickfororder in ('L','O') then
		for s in (select lpid from shippingplate
   				where loadno = sp.loadno
                 and parentlpid is null) loop

			zrfld.wand_shipplate(s.lpid, in_user, sp.loadno, sp.stopno, in_facility,
					in_stageloc, l_err, l_msg);
			if l_msg is null then
				zrfld.load_shipplates(in_facility, in_user, sp.loadno, sp.stopno, in_doorloc,
						l_err, l_msg, l_is_loaded);
			end if;
			if l_msg is not null then
				out_errmsg := l_msg;
            return;
			end if;
		end loop;

      if l_is_loaded = 'Y' then
         update orderhdr
            set trailernosetemp = in_nosetemp,
                trailermiddletemp = in_middletemp,
                trailertailtemp = in_tailtemp,
                lastuser = in_user,
                lastupdate = sysdate
            where orderid = in_orderid
              and shipid = in_shipid;
      end if;
	end if;

exception
   when OTHERS then
      out_errmsg := sqlerrm;
end load_shippingplate;


procedure force_ship_order(
    in_orderid      in number,
    in_shipid       in number,
    in_userid       in varchar2,
    out_errmsg      out varchar2)
IS
CURSOR C_ORD(in_orderid number, in_shipid number)
IS
SELECT *
  FROM orderhdr
 WHERE orderid = in_orderid
   AND shipid = in_shipid;

ORD orderhdr%rowtype;

datestamp date;
errmsg varchar2(255);

BEGIN
    out_errmsg := 'OKAY';

    ORD := null;
    OPEN C_ORD(in_orderid, in_shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if ORD.orderid is null then
        out_errmsg := 'Invalid Order';
        return;
    end if;


    if ORD.orderstatus != '1' then
        out_errmsg := 'Order status must be Entered';
        return;
    end if;

    if nvl(ORD.loadno,0) != 0 then
        out_errmsg := 'Order cannot be part of a load.';
        return;
    end if;

    if nvl(ORD.wave,0) != 0 then
        out_errmsg := 'Order cannot be part of a wave.';
        return;
    end if;

    datestamp := sysdate;

    delete from commitments
     where orderid = in_orderid
       and shipid = in_shipid;

    delete from orderlabor
     where orderid = in_orderid
       and shipid = in_shipid;

    update orderhdr
       set orderstatus = '9',
           statusupdate = datestamp,
           statususer = in_userid,
           dateshipped = datestamp,
           lastuser = in_userid,
           lastupdate = datestamp
     where orderid = in_orderid
       and shipid = in_shipid;


-- zba.calc_outbound_order(null,null,in_orderid, in_shipid, in_userid, errmsg);

  zoh.add_orderhistory(in_orderid, in_shipid,
     'Order Closed',
     'Order Forced Closed without shipping',
     in_userid, errmsg);

EXCEPTION WHEN OTHERS THEN
  out_errmsg := sqlerrm;

END force_ship_order;


procedure deplete_shippinglpid_qtytasked
   (in_lpid in varchar2,
    out_msg out varchar2)
is
   l_qtytasked plate.qtytasked%type;
begin
   out_msg := null;

   for sp in (select lpid, qty from agginvtasks
               where shippinglpid = in_lpid) loop

      begin
         select nvl(qtytasked,0) into l_qtytasked
            from plate
            where lpid = sp.lpid;
      exception when others then
         l_qtytasked := 0;
      end;

      if l_qtytasked >= sp.qty then
         l_qtytasked := l_qtytasked - sp.qty;
      else
         l_qtytasked := null;
      end if;
      update plate
         set qtytasked = l_qtytasked
         where lpid = sp.lpid;

   end loop;

   delete agginvtasks where shippinglpid = in_lpid;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end deplete_shippinglpid_qtytasked;


procedure check_overpick
   (in_qtypick   in number,
    in_orderid   in number,
    in_shipid    in number,
    in_orderitem in varchar2,
    in_orderlot  in varchar2,
    out_message  out varchar2)
is
   cursor c_od(p_orderid number, p_shipid number, p_item varchar2, p_lotnumber varchar2) is
      select decode(nvl(variancepct_use_default,'Y'),'N',
                    nvl(variancepct,0),zci.variancepct(custid,item)) as variancepct,
             decode(nvl(variancepct_use_default,'Y'),'N',
                    nvl(variancepct_overage,0),zci.variancepct_overage(custid,item))
                    as variancepct_overage,
             nvl(qtytype,'E') as qtytype,
             qtyorder
         from orderdtl
         where orderid = p_orderid
           and shipid = p_shipid
           and item = p_item
           and nvl(lotnumber, '(none)') = nvl(p_lotnumber, '(none)');
	od c_od%rowtype := null;
   l_lower number;
   l_upper number;
begin
   out_message := 'OKAY';

   if zcord.cons_orderid(in_orderid, in_shipid) != 0 then
      out_message := 'No overpicks for consolidated orders';
      return;
   end if;

   open c_od(in_orderid, in_shipid, in_orderitem, in_orderlot);
   fetch c_od into od;
   close c_od;

   if in_qtypick > od.qtyorder then
      if od.qtytype = 'E' then                     -- exact
         out_message := 'Quantity for item larger than ordered.';
      else                                         -- approximate
         l_lower := (od.variancepct/100) * od.qtyorder;
         l_upper := (od.variancepct_overage/100) * od.qtyorder;
         if in_qtypick between l_lower and l_upper then
            out_message := 'OVER';
         else
            out_message := 'Quantity for item must be between '||l_lower||' and '||l_upper||'.';
         end if;
      end if;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end check_overpick;

procedure close_matissue_workorder(
    in_orderid      in number,
    in_shipid       in number,
    in_facility     in varchar2,
    in_userid       in varchar2,
    out_errmsg      out varchar2)
as
  v_orderhdr orderhdr%rowtype;
  v_credithold varchar2(20);
  v_count number;
  out_msg varchar2(255);
  aux_msg varchar2(255);
begin
  out_errmsg := 'OKAY';
  
  begin
    select * into v_orderhdr
    from orderhdr
    where orderid = in_orderid and shipid = in_shipid;
  exception
    when others then
      out_errmsg := 'Could not find order';
      return;
  end;
  
  if (v_orderhdr.fromfacility <> in_facility) then
    out_msg := 'Order not at your facility: ' || v_orderhdr.fromfacility;
    return;
  end if;
  
  select nvl(zcu.credit_hold(v_orderhdr.custid),'N') into v_credithold from dual;
  
  if (v_credithold = 'Y') then
    out_msg := 'Cannot close--Customer ' || v_orderhdr.custid || ' is on credit hold';
    return;
  end if;
  
  if (v_orderhdr.orderstatus in ('1','2','3')) then
    out_msg := 'Cannot close--Order is unreleased';
    return;
  end if;
  
  select count(1) into v_count
  from shippingplate sp
  where orderid = in_orderid and shipid = in_shipid
    and type in ('F','P')
    and status in ('SH')
    and exists
       (select *
          from orderdtl od
         where sp.orderid = od.orderid
           and sp.shipid = od.shipid
           and sp.orderitem = od.item
           and nvl(sp.orderlot,'(none)') = nvl(od.lotnumber,'(none)')
           and od.linestatus = 'X');

  if (v_count != 0) then
    out_msg := 'Cannot close--Shipped plate for cancelled order line';
    return;
  end if;
  
  select count(1) into v_count
  from tasks
  where orderid = in_orderid and shipid = in_shipid
    and priority = '0';
    
  if v_count != 0 then
    out_msg := 'There are active tasks for this order';
    return;
  end if;
  
  select count(1) into v_count
  from subtasks
  where orderid = in_orderid and shipid = in_shipid
    and priority = '0';
    
  if v_count != 0 then
    out_msg := 'There are active subtasks for this order';
    return;
  end if;
  
  select count(1) into v_count
  from orderhdr OH, orderdtl OD, customer_aux CX
  where OH.orderid = in_orderid and OH.shipid = in_shipid and OH.xdockorderid is null
    and OD.orderid = OH.orderid and OD.shipid = OH.shipid
    and nvl(OD.qtyship,0) > nvl(OD.qtyorder,0)
    and CX.custid = OH.custid
    and nvl(CX.allow_overpicking,'N') = 'N';
   
  if v_count != 0 then
    out_msg := 'Cannot close--quantity shipped would exceed quantity ordered';
    return;
  end if;
  
  ztk.delete_subtasks_by_order(in_orderid,in_shipid,in_userid,out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
  zms.log_msg('OrderClose', v_orderhdr.fromfacility, '',
       'Delete subtask: ' || out_msg,
       'E', in_userid, aux_msg);
  end if;
  
  update orderhdr
     set orderstatus = '9',
         stageloc = null,
         lastuser = in_userid,
         lastupdate = sysdate,
         dateshipped = sysdate
   where orderid = in_orderid and shipid = in_shipid
     and orderstatus < '9';
     
  zoh.add_orderhistory(in_orderid, in_shipid,
     'Order Closed',
     'Order Closed',
     in_userid, out_msg);
     
  for cwt in (select SP.custid, SP.item, SP.lotnumber, SP.weight
               from shippingplate SP, custitemview CI
               where SP.orderid = in_orderid and SP.shipid = in_shipid
                 and SP.type in ('P','F')
                 and CI.custid = SP.custid
                 and CI.item = SP.item
                 and CI.use_catch_weights = 'Y') loop
   zcwt.add_item_lot_catch_weight(v_orderhdr.fromfacility, cwt.custid, cwt.item, cwt.lotnumber, -cwt.weight, out_msg);
end loop;
  
end close_matissue_workorder;

procedure close_production_order(
    in_orderid      in number,
    in_shipid       in number,
    in_facility     in varchar2,
    in_userid       in varchar2,
    out_errmsg      out varchar2)
as
  v_orderhdr orderhdr%rowtype;
  v_customer customer%rowtype;
  v_credithold varchar2(20);
  v_count number;
  out_msg varchar2(255);
  aux_msg varchar2(255);
  int_errno number;
  v_asn_var number;
begin
  out_errmsg := 'OKAY';
   
  begin
    select * into v_orderhdr
    from orderhdr
    where orderid = in_orderid and shipid = in_shipid;
  exception
    when others then
      out_errmsg := 'Could not find order';
      return;
  end;
  
  if (v_orderhdr.tofacility <> in_facility) then
    out_errmsg := 'Order not at your facility: ' || v_orderhdr.tofacility;
    return;
  end if;
  
  if v_orderhdr.orderstatus != 'A' then
    out_errmsg := 'Invalid order status for close: ' || v_orderhdr.orderstatus;
    return;
  end if;
  
  begin
    select * into v_customer
    from customer
    where custid = v_orderhdr.custid;
  exception
    when others then
      out_errmsg := 'Could not find customer';
      return;
  end;
  
  if v_customer.recv_line_check_yn = 'Y' then
    for od in (select item, lotnumber
               from orderdtl
               where orderid = in_orderid and shipid = in_shipid
                and linestatus != 'X')
    loop
      zrec.check_line_qty(v_customer.custid,in_orderid,in_shipid,od.item,od.lotnumber,0,int_errno,out_errmsg);
      if int_errno != 0 then
        out_errmsg := 'Order ' || in_orderid || '-' ||
          in_shipid || ' Item ' || od.item || ' Lot ' ||
          nvl(od.lotnumber,'(none)') || ': Line number quantity exceeded';
        return;
      end if;
    end loop;
  end if;
  
  update orderhdr
  set orderstatus = 'R',
    lastuser = in_userid,
    lastupdate = sysdate
  where orderid = in_orderid and shipid = in_shipid
    and orderstatus = 'A'
    and ordertype = 'P';
    
  select count(1) into v_count
  from asncartondtl
  where orderid = in_orderid and shipid = in_shipid
    and trackingno is not null;
    
  if (v_count > 0) then
    v_asn_var := 0;
    for od in (select item, lotnumber
               from orderdtl
               where orderid = in_orderid and shipid = in_shipid
                and linestatus != 'X')
    loop
      select count(1) into v_count
      from asnreceiptview
      where orderid = in_orderid and shipid = in_shipid
         and item = od.item and nvl(lotnumber,'x') = nvl(od.lotnumber,'x')
         and asnqtyorder = 0;
         
      if (v_count > 0) then
        update orderdtl
        set asnvariance = 'Y'
        where orderid = in_orderid and shipid = in_shipid
          and item = od.item and nvl(lotnumber,'x') = nvl(od.lotnumber,'x');
          
        v_asn_var := v_asn_var + 1;
      end if;
    end loop;
    
    if (v_asn_var > 0) then
      update orderhdr
      set asnvariance = 'Y'
      where orderid = in_orderid and shipid = in_shipid;
    end if;
  end if;
  
  zoh.add_orderhistory(in_orderid, in_shipid, 'Order Closed', 'Order Closed', in_userid, out_errmsg);
  zbill.receipt_prodorder_add_asof(in_orderid, in_shipid, in_userid, out_errmsg);
  if out_errmsg != 'OKAY' then
    return;
  end if;

  out_msg := 'OKAY';
  
end close_production_order;

procedure prod_order_export_req(
    in_orderid      in number,
    in_shipid       in number,
    in_facility     in varchar2,
    in_userid       in varchar2,
    out_errmsg      out varchar2)
as
  v_custid orderhdr.custid%type;
  v_orderstatus orderhdr.orderstatus%type;
  v_map customer_aux.outproductionordermap%type;
  v_facility orderhdr.tofacility%type;
  out_errorno number;
  v_message varchar2(255);
begin
  out_errmsg := 'OKAY';
  
  begin
    select custid, tofacility, orderstatus 
    into v_custid, v_facility, v_orderstatus
    from orderhdr
    where orderid = in_orderid and shipid = in_shipid;
  exception
    when others then
      out_errmsg := 'Could not find customer';
      return;
  end;
  
  if (nvl(v_orderstatus,'X') <> 'R') then
    out_errmsg := 'Order not received';
    return;
  end if;
  
  begin
    select outproductionordermap into v_map
    from customer_aux
    where custid = v_custid;
  exception
    when others then
      out_errmsg := 'Could not find export map';
      return;
  end;
  
  if (v_map is null) then
    out_errmsg := 'Could not find export map';
    return;
  end if;
      
  ziem.impexp_request(
    'E', -- reqtype
    null, -- facility
    v_custid, -- custid
    v_map, -- formatid
    null, -- importfilepath
    'NOW', -- when
    null, -- loadno
    in_orderid, -- orderid
    in_shipid, -- shipid
    in_userid, --userid
    null, -- tablename
    null,  --columnname
    null, --filtercolumnname
    null, -- company
    null, -- warehouse
    null, -- begindatestr
    null, -- enddatestr
    out_errorno,
    out_errmsg);

  if out_errorno != 0 then
    zms.log_msg('ImpExp', v_facility, v_custid, 'Request Export: ' || out_errmsg,'E', 'IMPEXP', v_message);
  end if;      
  
end prod_order_export_req;

end zshiporder;
/

show errors package body zshiporder;
exit;
