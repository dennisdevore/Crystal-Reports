create or replace package body alps.kitting as
--
-- $Id$
--


-- Constants


OP_INSERT   CONSTANT    number := 0;
OP_UPDATE   CONSTANT    number := 1;
OP_UNDELETE CONSTANT    number := 2;
OP_MIX      CONSTANT    number := 3;
OP_ATTACH   CONSTANT    number := 4;


-- Cursors


cursor c_cus_wkord(p_seq number) is
	select distinct subseq, level, action, nvl(parent, 0) parent, component, qty, destfacility,
          destlocation, destloctype
		from custworkorderinstructionsview
		where seq = p_seq
		start with subseq in
				(select subseq
					from custworkorderinstructions
               where seq = p_seq
					  and nvl(parent, 0) = 0)
		connect by seq = p_seq and prior subseq = parent;


-- Types


type cus_wkord_tbl is table of c_cus_wkord%rowtype
	index by binary_integer;

type item_typ is record
	(custid plate.custid%type,
    item plate.item%type
	);
type itemcur_typ is ref cursor return item_typ;


-- Globals


cwo_tbl cus_wkord_tbl;
cwo_maxlevel pls_integer;


-- Private procedures


procedure complete_subseq_item
   (in_custid       in varchar2,
    in_kititem      in varchar2,
    in_component    in varchar2,
    in_facility     in varchar2,
    in_location     in varchar2,
    in_seq          in number,
    in_subseq       in number,
    in_qtydone      in number,
    in_newloc       in varchar2,
    in_newsubseq    in number,
	 in_user         in varchar2,
    in_kitted_class in varchar2,
    out_error       out varchar2,
    out_message     out varchar2)
is
   cursor c_woc is
      select qty
         from workordercomponents
         where custid = in_custid
           and item = in_kititem
           and kitted_class = in_kitted_class
           and component = in_component;
   woc c_woc%rowtype := null;
   qtyneeded number;
   cursor c_1lp (p_item varchar2) is
      select rowid, parentlpid, lpid, nvl(in_newloc, location) newloc, status,
             lotnumber, unitofmeasure, quantity, inventoryclass, invstatus, weight,
             orderid, shipid
         from plate
         where facility = in_facility
           and location = in_location
           and custid = in_custid
           and item = p_item
           and workorderseq = in_seq
           and workordersubseq = in_subseq
           and quantity = qtyneeded
           and type = 'PA';
   lp c_1lp%rowtype;
   cursor c_lps (p_item varchar2) is
      select rowid, parentlpid, lpid, nvl(in_newloc, location) newloc, status,
             lotnumber, unitofmeasure, quantity, inventoryclass, invstatus, weight,
             orderid, shipid
         from plate
         where facility = in_facility
           and location = in_location
           and custid = in_custid
           and item = p_item
           and workorderseq = in_seq
           and workordersubseq = in_subseq
           and type = 'PA'
         order by quantity;
   cursor c_itemlist is
      select in_component item, -1 seq
         from dual
      union
      select itemsub, seq
         from custitemsubs
         where custid = in_custid
           and item = in_component
      order by 2, 1;
   rowfound boolean;
	err varchar2(1) := null;
   msg varchar2(80) := null;
	newlpid plate.lpid%type;
begin
   out_error := 'N';
   out_message := null;

   open c_woc;
   fetch c_woc into woc;
   close c_woc;
   if (nvl(woc.qty, 0) = 0) then
      woc.qty := 1;
   end if;

   qtyneeded := in_qtydone * woc.qty;

   for il in c_itemlist loop
      open c_1lp(il.item);
      fetch c_1lp into lp;
   	rowfound := c_1lp%found;
      close c_1lp;

   	if rowfound then
         if (lp.parentlpid is not null) then
            zplp.detach_child_plate(lp.parentlpid, lp.lpid, lp.newloc, null, null,
                  lp.status, in_user, null, msg);
            if (msg is not null) then
               out_error := 'Y';
               out_message := msg;
               return;
            end if;
         end if;

         if (in_newsubseq = 0) then
            zlp.plate_to_deletedplate(lp.lpid, in_user, null, msg);
            if (msg is null) then
               zbill.add_asof_inventory(in_facility, in_custid, il.item, lp.lotnumber,
                     lp.unitofmeasure, sysdate, -lp.quantity, -lp.weight, 'KitIn', 'AD',
                     lp.inventoryclass, lp.invstatus, lp.orderid, lp.shipid, lp.lpid,
                     in_user, msg);
               if (msg = 'OKAY') then
                  msg := null;
               end if;
            end if;
            if (msg is not null) then
               out_error := 'Y';
               out_message := msg;
            end if;
         else
            update plate
               set workordersubseq = in_newsubseq,
                   location = lp.newloc,
                   lastoperator = in_user,
                   lastuser = in_user,
                   lastupdate = sysdate
               where rowid = lp.rowid;
         end if;
         return;
      end if;

      for l in c_lps(il.item) loop
         if (l.quantity <= qtyneeded) then
            if (l.parentlpid is not null) then
               zplp.detach_child_plate(l.parentlpid, l.lpid, l.newloc, null, null,
                     l.status, in_user, null, msg);
               if (msg is not null) then
                  out_error := 'Y';
                  out_message := msg;
                  return;
               end if;
            end if;
            if (in_newsubseq = 0) then
               zlp.plate_to_deletedplate(l.lpid, in_user, null, msg);
               if (msg is not null) then
                  out_error := 'Y';
                  out_message := msg;
                  return;
               end if;
            else
               update plate
                  set workordersubseq = in_newsubseq,
                      location = l.newloc,
                      lastoperator = in_user,
                      lastuser = in_user,
                      lastupdate = sysdate
                  where rowid = l.rowid;
            end if;
            qtyneeded := qtyneeded - l.quantity;
         else
            if (in_newsubseq != 0) then
   	   		zrf.get_next_lpid(newlpid, msg);
   	   		if (msg is null) then
	   	   	   rfbp.dupe_lp(l.lpid, newlpid, l.newloc, l.status, qtyneeded, in_user, null,
                        null, null, msg);
			         if (msg is null) then
                     update plate
                        set workordersubseq = in_newsubseq
                        where lpid = newlpid;
                  end if;
               end if;
               if (msg is not null) then
                  out_error := 'Y';
                  out_message := msg;
                  return;
               end if;
            end if;
            zrf.decrease_lp(l.lpid, in_custid, il.item, qtyneeded, l.lotnumber,
                  l.unitofmeasure, in_user, null, l.invstatus, l.inventoryclass, err, msg);
            if (msg is not null) then
               out_error := err;
               out_message := msg;
               return;
            end if;
            l.quantity := qtyneeded;
            qtyneeded := 0;
         end if;
         if (in_newsubseq = 0) then
            zbill.add_asof_inventory(in_facility, in_custid, il.item, l.lotnumber,
                  l.unitofmeasure, sysdate, -l.quantity, -l.weight, 'KitIn', 'AD',
                  l.inventoryclass, l.invstatus, l.orderid, l.shipid, l.lpid,
                  in_user, msg);
            if (msg = 'OKAY') then
               msg := null;
            else
               out_error := 'Y';
               out_message := msg;
               return;
            end if;
         end if;
         exit when (qtyneeded = 0);
      end loop;
   end loop;

   if (qtyneeded != 0) then
      out_message := 'Qty not avail';
      rollback;
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end complete_subseq_item;


-- Public functions


function is_subseq_ready
   (in_seq      in number,
    in_subseq   in number,
    in_facility in varchar2,
    in_location in varchar2)
return number
is
   cursor c_inst is
      select I.component, O.custid
         from custworkorderinstructions I, custworkorder O
         where I.seq = in_seq
           and I.subseq = in_subseq
           and O.seq = in_seq;
   inst c_inst%rowtype;
   cursor c_comps is
      select distinct component
         from custworkorderinstructions
         where seq = in_seq
           and component is not null
         start with subseq = in_subseq
		   connect by seq = in_seq and prior subseq = parent;
   cursor c_itemlist (p_custid varchar2, p_item varchar2) is
      select p_item item, -1 seq
         from dual
      union
      select itemsub, seq
         from custitemsubs
         where custid = p_custid
           and item = p_item
      order by 2, 1;
   rowfound boolean;
   lpcount number := 0;
begin

   open c_inst;
   fetch c_inst into inst;
	rowfound := c_inst%found;
   close c_inst;

	if rowfound then
      if (inst.component is not null) then
         for il in c_itemlist(inst.custid, inst.component) loop
            select count(1) into lpcount
               from plate
               where facility = in_facility
                 and location = in_location
                 and custid = inst.custid
                 and item = il.item
                 and workorderseq = in_seq
                 and workordersubseq = in_subseq;
            exit when (lpcount != 0);
         end loop;
      else
         for c in c_comps loop
            for il in c_itemlist(inst.custid, c.component) loop
               select count(1) into lpcount
                  from plate
                  where facility = in_facility
                    and location = in_location
                    and custid = inst.custid
                    and item = il.item
                    and workorderseq = in_seq
                    and workordersubseq = in_subseq;
               exit when (lpcount != 0);
            end loop;
            exit when (lpcount = 0);
         end loop;
      end if;
   end if;

   return lpcount;

exception
   when OTHERS then
      return 0;
end is_subseq_ready;


function any_subseq_ready
   (in_seq      in number,
    in_facility in varchar2,
    in_location in varchar2)
return number
is
   cursor c_subseqs is
      select distinct workordersubseq
         from plate
         where facility = in_facility
           and location = in_location
           and workorderseq = in_seq
           and nvl(workordersubseq, 0) != 0;
   cnt number := 0;
begin

   for s in c_subseqs loop
      cnt := is_subseq_ready(in_seq, s.workordersubseq, in_facility, in_location);
      exit when (cnt != 0);
   end loop;

   return cnt;

exception
   when OTHERS then
      return 0;
end any_subseq_ready;


function first_subseq		-- assumes load_custworkorder has been called
	(in_component in varchar2,
	 in_facility  in varchar2)
return custworkorderinstructions.subseq%type
is
	first custworkorderinstructions.subseq%type := 0;
	cur_lvl pls_integer := cwo_maxlevel;
   cx binary_integer;
begin

	if (cwo_tbl.count <= 0) then
		return first;
	end if;

	loop
      cx := cwo_tbl.first;
      while cx is not null loop
			if ((cwo_tbl(cx).level = cur_lvl)
			and (nvl(cwo_tbl(cx).component, '(none)') = in_component)
			and (nvl(cwo_tbl(cx).destfacility, in_facility) = in_facility)
			and ((cwo_tbl(cx).destlocation is not null)
			 or  (cwo_tbl(cx).destloctype is not null))) then
				first := cwo_tbl(cx).subseq;
				exit;
			end if;
         cx := cwo_tbl.next(cx);
		end loop;
		cur_lvl := cur_lvl - 1;
		exit when ((cur_lvl <= 0) or (first > 0));
	end loop;

   if (first = 0) then
	   cur_lvl := cwo_maxlevel;
	   loop
         cx := cwo_tbl.first;
         while cx is not null loop
			   if ((cwo_tbl(cx).level = cur_lvl)
			   and (nvl(cwo_tbl(cx).component, '(none)') = in_component)
			   and (nvl(cwo_tbl(cx).destfacility, in_facility) = in_facility)) then
				   first := cwo_tbl(cx).subseq;
				   exit;
			   end if;
            cx := cwo_tbl.next(cx);
		   end loop;
		   cur_lvl := cur_lvl - 1;
		   exit when ((cur_lvl <= 0) or (first > 0));
	   end loop;
   end if;

	return first;

exception
   when OTHERS then
      return 0;
end first_subseq;


function is_kit_closeable
   (in_orderid   in number,
    in_shipid    in number,
    in_item      in varchar2,
    in_lotnumber in varchar2)
return varchar2
is
   cursor c_od(p_orderid number, p_shipid number, p_item varchar2, p_lotnumber varchar2) is
      select CW.status
         from orderdtl OD, orderhdr OH, custworkorder CW
         where OD.orderid = p_orderid
           and OD.shipid = p_shipid
           and OD.item = p_item
           and nvl(OD.lotnumber, '(none)') = nvl(p_lotnumber, '(none)')
           and OH.orderid = OD.childorderid
           and OH.shipid = OD.childshipid
           and CW.seq (+) = OH.workorderseq;
	od c_od%rowtype := null;
   l_retval varchar2(1) := 'N';
begin
   open c_od(in_orderid, in_shipid, in_item, in_lotnumber);
   fetch c_od into od;
   close c_od;

   if nvl(od.status,'x') = 'P' then
      l_retval := 'Y';
   end if;

   return l_retval;

exception
   when OTHERS then
      return 'N';
end is_kit_closeable;


-- Public procedures


-- This procedure does *NOT* recurse into sub-kits
procedure load_custworkorder
	(in_seq	    in number,
	 out_message out varchar2)
is
begin
   out_message := null;
	cwo_maxlevel := 0;

   cwo_tbl.delete;
	for w in c_cus_wkord(in_seq) loop
		cwo_tbl(w.subseq) := w;
		cwo_maxlevel := greatest(cwo_maxlevel, w.level);
	end loop;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end load_custworkorder;


procedure show_cwo
	(in_seq	     in number,
	 in_facility  in varchar2,
	 in_component in varchar2 := null)
is
   msg varchar2(80);
   cx binary_integer;
begin
	dbms_output.enable(1000000);

	load_custworkorder(in_seq, msg);
	if (msg is not null) then
   	dbms_output.put_line('results: ' || msg);
	elsif (cwo_tbl.count > 0) then
		dbms_output.put_line('Act  Component  Qty  Fac    Location Type   Pa');
      cx := cwo_tbl.first;
      while cx is not null loop
			dbms_output.put_line(lpad(cwo_tbl(cx).action, 2)
				|| lpad(nvl(cwo_tbl(cx).component, ' '), 12)
				|| lpad(nvl(to_char(cwo_tbl(cx).qty), ' '), 5)
				|| lpad(nvl(cwo_tbl(cx).destfacility, ' '), 5)
				|| lpad(nvl(cwo_tbl(cx).destlocation, ' '), 12)
				|| lpad(nvl(cwo_tbl(cx).destloctype, ' '), 5)
				|| lpad(to_char(cwo_tbl(cx).parent), 5)
			   || lpad(' ', 3*(cwo_tbl(cx).level-1))
				|| lpad(to_char(cwo_tbl(cx).subseq), 5));
         cx := cwo_tbl.next(cx);
		end loop;
   	dbms_output.put_line(chr(10) || 'maxlevel: ' || cwo_maxlevel);
		if (in_component is not null) then
   		dbms_output.put_line(chr(10) || 'first: ' || first_subseq(in_component, in_facility));
		end if;
	end if;

end show_cwo;


procedure find_pick_stage_loc
	(in_seq 			 	in number,
	 in_lpid 		 	in varchar2,
	 in_facility	 	in varchar2,
	 out_stage_loc	 	out varchar2,
	 out_stage_type 	out varchar2,
	 out_stage_abbrev out varchar2,
	 out_subseq       out number,
    out_error      	out varchar2,
    out_message    	out varchar2)
is
   lptype plate.type%type;
   xrefid plate.lpid%type;
   xreftype plate.type%type;
   parentid plate.lpid%type;
   parenttype plate.type%type;
   topid plate.lpid%type;
   toptype plate.type%type;
   msg varchar2(80);
	rowfound boolean;
   c_item itemcur_typ;
   item_rec c_item%rowtype;
	cx custworkorderinstructions.subseq%type;
	cursor c_loctype (p_code varchar2) is
		select abbrev
			from locationtypes
			where code = p_code;
	loctype_rec c_loctype%rowtype;
   cursor c_itemlist (p_custid varchar2, p_item varchar2) is
      select p_item item, -1 seq
         from dual
      union
      select item, seq
         from custitemsubs
         where custid = p_custid
           and itemsub = p_item
      order by 2, 1;
begin
   out_error := 'N';
   out_message := null;
	out_stage_loc := null;
	out_stage_type := null;
	out_stage_abbrev := null;
	out_subseq := 0;

-- verify lp and find highest parent to work with
   zrf.identify_lp(in_lpid, lptype, xrefid, xreftype, parentid, parenttype,
 			topid, toptype, msg);
   if (msg is not null) then
      out_error := 'Y';
      out_message := msg;
      return;
   end if;
   topid := nvl(topid, nvl(parentid, nvl(xrefid, in_lpid)));
   toptype := nvl(toptype, nvl(parenttype, nvl(xreftype, lptype)));

-- only consider one (the "first") item being staged
	if (toptype in ('C', 'F', 'M', 'P')) then
		open c_item for
			select distinct custid, item from
            (select custid, item
				   from shippingplate
				   where type in ('F', 'P')
				   start with lpid = topid
				   connect by prior lpid = parentlpid);
	elsif (toptype in ('PA', 'MP', 'TO')) then
		open c_item for
			select distinct custid, item
				from plate
				where type = 'PA'
				start with lpid = topid
				connect by prior lpid = parentlpid;
	else
		out_message := 'Invalid LP';	-- this shouldn't happen
		return;
	end if;

	fetch c_item into item_rec;
	rowfound := c_item%found;
	close c_item;

	if not rowfound then
		out_message := 'No item';		-- this shouldn't happen
		return;
	end if;

-- find a suitable location for item
	load_custworkorder(in_seq, msg);
   if (msg is not null) then
      out_error := 'Y';
      out_message := msg;
      return;
   end if;

   for il in c_itemlist(item_rec.custid, item_rec.item) loop
   	cx := first_subseq(il.item, in_facility);
   	if (cx != 0) then
	   	out_stage_loc := cwo_tbl(cx).destlocation;
		   out_stage_type := cwo_tbl(cx).destloctype;
		   out_subseq := cwo_tbl(cx).subseq;
		   if (cwo_tbl(cx).destloctype is not null) then
      	   open c_loctype(cwo_tbl(cx).destloctype);
      	   fetch c_loctype into loctype_rec;
      	   if c_loctype%found then
				   out_stage_abbrev := loctype_rec.abbrev;
      	   end if;
      	   close c_loctype;
		   end if;
         exit;
	   end if;
   end loop;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end find_pick_stage_loc;


procedure start_workorder
	(in_orderid 	in number,
	 in_shipid     in number,
	 in_user       in varchar2,
	 out_seq 		out number,
	 out_custid		out varchar2,
    out_error     out varchar2,
    out_message   out varchar2)
is
	err varchar2(1);
   msg varchar2(80);
	rowfound boolean;
   cnt number;
	cursor c_ord is
		select custid, ordertype, workorderseq, componenttemplate, orderstatus
			from orderhdr
			where orderid = in_orderid
			  and shipid = in_shipid;
	ord_rec c_ord%rowtype;
	cursor c_parent is
		select custid, ordertype, workorderseq, componenttemplate, orderstatus
			from orderhdr
			where ordertype = 'K'
			  and parentorderid = in_orderid;
	cursor c_wkord is
		select status
			from custworkorder
			where seq = ord_rec.workorderseq;
	wkord_rec c_wkord%rowtype;
begin
	out_seq := 0;
	out_custid := null;
   out_error := 'N';
   out_message := null;

	open c_ord;
	fetch c_ord into ord_rec;
	rowfound := c_ord%found;
	close c_ord;

	if not rowfound then
		out_message := 'Order not found';
		return;
	end if;

	if (ord_rec.ordertype != 'K') then
   	if ord_rec.orderstatus = '9' then
      	out_message := 'Order is shipped';
         return;
		end if;
		open c_parent;
		fetch c_parent into ord_rec;
		rowfound := c_parent%found;
		close c_parent;
		if not rowfound then
			out_message := 'No kit in order';
			return;
		end if;
	end if;

	zrf.verify_customer(ord_rec.custid, in_user, err, msg);
   if (msg is not null) then
      out_error := err;
      out_message := msg;
      return;
   end if;

	open c_wkord;
	fetch c_wkord into wkord_rec;
	rowfound := c_wkord%found;
	close c_wkord;
	if not rowfound then
		out_message := 'No Workorder';
		return;
	end if;
	if (wkord_rec.status in ('C','D')) then
      select count(1) into cnt
         from plate
         where workorderseq = ord_rec.workorderseq
           and status = 'K';

      if (cnt = 0) then
   		out_message := 'Workorder done';
	   	return;
      end if;
	end if;

	out_seq := ord_rec.workorderseq;
	out_custid := ord_rec.custid;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end start_workorder;


procedure get_topmost_order
   (in_seq                in number,
    out_orderid           out number,
    out_shipid            out number,
    out_ordertype         out varchar2,
    out_qtyorder          out number,
    out_componenttemplate out varchar2,
    out_stageloc          out varchar2,
    out_message           out varchar2)
is
   cursor c_ord is
      select orderid, shipid, parentorderid, parentshipid, ordertype,
             componenttemplate
         from orderhdr
         where workorderseq = in_seq;
   ord c_ord%rowtype;
   cursor c_parent (p_orderid number, p_shipid number) is
      select orderid, shipid, parentorderid, parentshipid, ordertype,
             componenttemplate
         from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   cursor c_ohv is
      select stageloc
         from orderhdrview
         where orderid = ord.orderid
           and shipid = ord.shipid;
   cursor c_odtl is
      select min(qtyorder)
         from orderdtl
         where orderid = ord.orderid
           and shipid = ord.shipid;
	rowfound boolean;
   loopcount pls_integer := 0;
begin
   out_message := null;
   out_orderid := null;
   out_shipid := null;
   out_ordertype := null;
   out_qtyorder := 0;
   out_componenttemplate := null;
   out_stageloc := null;

   open c_ord;
   fetch c_ord into ord;
   rowfound := c_ord%found;
   close c_ord;

   loop
      exit when ((loopcount > 256) or not rowfound);

      if (ord.ordertype != 'K') then
         select max(shipid) into ord.shipid
            from orderhdr
            where orderid = ord.orderid;
         out_orderid := ord.orderid;
         out_ordertype := ord.ordertype;
         out_shipid := ord.shipid;
         open c_odtl;
         fetch c_odtl into out_qtyorder;
         close c_odtl;
         out_componenttemplate := ord.componenttemplate;
         open c_ohv;
         fetch c_ohv into out_stageloc;
         close c_ohv;
         exit;
      end if;

      open c_parent(ord.parentorderid, ord.parentshipid);
      fetch c_parent into ord;
	   rowfound := c_parent%found;
      close c_parent;

      loopcount := loopcount + 1;
   end loop;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end get_topmost_order;


procedure complete_subseq
   (in_facility in varchar2,
    in_location in varchar2,
    in_seq      in number,
    in_subseq   in number,
    in_qtydone  in number,
    in_newloc   in varchar2,
	 in_user     in varchar2,
    in_qtycheck in varchar2,
    out_seqdone out varchar2,
    out_error   out varchar2,
    out_message out varchar2)
is
   cursor c_wo is
      select nvl(I.parent, 0) parent, I.action, nvl(I.qty, 0) qty, I.component, I.rowid,
             O.custid, O.item, O.requestedqty, nvl(O.completedqty, 0) completedqty,
             O.status, O.kitted_class
         from custworkorderinstructions I, custworkorder O
         where I.seq = in_seq
           and I.subseq = in_subseq
           and O.seq = in_seq;
   wo c_wo%rowtype;
   cursor c_comps is
      select distinct component
         from custworkorderinstructions
         where seq = in_seq
           and component is not null
         start with subseq = in_subseq
		   connect by seq = in_seq and prior subseq = parent;
   rowfound boolean;
	err varchar2(1) := null;
   msg varchar2(80) := null;
   ordid orderhdr.orderid%type;
   shpid orderhdr.shipid%type;
   ordtyp orderhdr.ordertype%type;
   qtyord orderhdr.qtyorder%type;
   comptmpl orderhdr.componenttemplate%type;
   stgloc orderhdr.stageloc%type;
begin
   out_seqdone := 'N';
   out_error := 'N';
   out_message := null;

   open c_wo;
   fetch c_wo into wo;
	rowfound := c_wo%found;
   close c_wo;

	if not rowfound then
		out_message := 'Inst not found';
      out_error := 'Y';
		return;
	end if;

   if ((wo.qty != 0) and (in_qtydone > wo.qty)) then
      out_message := 'Too big for inst';
      return;
   end if;

   if (wo.action = 'KR') then
      if ((in_qtydone + wo.completedqty) > wo.requestedqty) then
         out_message := 'Too big for work';
         return;
      else
         get_topmost_order(in_seq, ordid, shpid, ordtyp, qtyord, comptmpl, stgloc, msg);
         if (msg is not null) then
		      out_message := msg;
            out_error := 'Y';
		      return;
         end if;
         if ((comptmpl is not null) and ((in_qtydone + wo.completedqty) > qtyord)) then
            out_message := 'More than ordered';
            return;
         end if;
      end if;
   end if;

   if (in_qtycheck = 'Y') then
      return;
   end if;

   if (wo.component is not null) then
      complete_subseq_item(wo.custid, wo.item, wo.component, in_facility, in_location,
            in_seq, in_subseq, in_qtydone, in_newloc, wo.parent, in_user, wo.kitted_class,
            err, msg);
   else
      for c in c_comps loop
         complete_subseq_item(wo.custid, wo.item, c.component, in_facility, in_location,
               in_seq, in_subseq, in_qtydone, in_newloc, wo.parent, in_user, wo.kitted_class,
               err, msg);
         exit when (msg is not null);
      end loop;
   end if;

   if (msg is not null) then
      out_error := err;
      out_message := msg;
      return;
   end if;

   update custworkorderinstructions
      set completedqty = nvl(completedqty, 0) + in_qtydone
      where rowid = wo.rowid;

   if (wo.action != 'KR') then
      return;
   end if;

   if (((in_qtydone + wo.completedqty) = wo.requestedqty)
   or  ((comptmpl is not null) and ((in_qtydone + wo.completedqty) = qtyord)))
   and (wo.status = 'P') then
      wo.status := 'D';
   end if;
   update custworkorder
      set completedqty = nvl(completedqty, 0) + in_qtydone,
          status = wo.status
      where seq = in_seq;

   if (wo.status in ('C','D')) then
      out_seqdone := 'Y';

      update orderhdr
         set orderstatus = '9',
             lastuser = in_user,
             lastupdate = sysdate
         where workorderseq = in_seq
           and ordertype = 'K';
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end complete_subseq;


procedure scrap_component
   (in_facility  in varchar2,
    in_seq       in number,
    in_custid    in varchar2,
    in_component in varchar2,
    in_qty       in number,
	 in_user      in varchar2,
    out_error    out varchar2,
    out_message  out varchar2)
is
   cursor c_anylps is
      select parentlpid, lpid, location, lotnumber, unitofmeasure, quantity,
             inventoryclass, invstatus, status, weight, orderid, shipid
         from plate
         where facility = in_facility
           and workorderseq = in_seq
           and custid = in_custid
           and item = in_component
           and type = 'PA';
   qtyneeded number := in_qty;
	err varchar2(1) := null;
   msg varchar2(80) := null;
begin
   out_error := 'N';
   out_message := null;

   for l in c_anylps loop
      if (l.quantity <= qtyneeded) then
         if (l.parentlpid is not null) then
            zplp.detach_child_plate(l.parentlpid, l.lpid, l.location, null, null,
                  l.status, in_user, null, msg);
         end if;
         if (msg is null) then
            zlp.plate_to_deletedplate(l.lpid, in_user, null, msg);
            qtyneeded := qtyneeded - l.quantity;
         end if;
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
            return;
         end if;
      else
         l.weight := qtyneeded * l.weight / l.quantity;
         l.quantity := qtyneeded;
         zrf.decrease_lp(l.lpid, in_custid, in_component, l.quantity, l.lotnumber,
               l.unitofmeasure, in_user, null, l.invstatus, l.inventoryclass, err, msg);
         if (msg is not null) then
            out_error := err;
            out_message := msg;
            return;
         end if;
         qtyneeded := 0;
      end if;
      zbill.add_asof_inventory(in_facility, in_custid, in_component, l.lotnumber,
            l.unitofmeasure, sysdate, -l.quantity, -l.weight, 'KScrapIn', 'AD',
            l.inventoryclass, l.invstatus, l.orderid, l.shipid, l.lpid,
            in_user, msg);
      if (msg = 'OKAY') then
         msg := null;
      else
         out_error := 'Y';
         out_message := msg;
         return;
      end if;
      exit when (qtyneeded = 0);
   end loop;

   if (qtyneeded != 0) then
      out_message := 'Qty not avail';
      rollback;
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end scrap_component;


procedure finishup_seq
   (in_facility  in varchar2,
    in_seq       in number,
    in_custid    in varchar2,
	 in_user      in varchar2,
    out_message  out varchar2)
is
   cursor c_anylps is
      select parentlpid, lpid, location, lotnumber, unitofmeasure, quantity,
             inventoryclass, invstatus, item, status, weight, orderid, shipid
         from plate
         where facility = in_facility
           and workorderseq = in_seq
           and custid = in_custid
           and type = 'PA';
   msg varchar2(80) := null;
begin
   out_message := null;

   for l in c_anylps loop
      if (l.parentlpid is not null) then
         zplp.detach_child_plate(l.parentlpid, l.lpid, l.location, null, null,
               l.status, in_user, null, msg);
      end if;
      if (msg is null) then
         zlp.plate_to_deletedplate(l.lpid, in_user, null, msg);
         if (msg is null) then
            zbill.add_asof_inventory(in_facility, in_custid, l.item, l.lotnumber,
               l.unitofmeasure, sysdate, -l.quantity, -l.weight, 'KitIn', 'AD',
               l.inventoryclass, l.invstatus, l.orderid, l.shipid, l.lpid,
               in_user, msg);
            if (msg = 'OKAY') then
               msg := null;
            end if;
         end if;
      end if;
      exit when (msg is not null);
   end loop;

   if (msg is null) then
      update custworkorderinstructions
         set status ='D'
         where seq = in_seq;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end finishup_seq;


procedure test_lp_dekit
   (in_lpid       in varchar2,
    in_facility   in varchar2,
	 out_custid    out varchar2,
    out_item      out varchar2,
    out_location  out varchar2,
    out_msgno     out number,
    out_message   out varchar2)
is
   cursor c_lp is
      select P.item, P.custid, P.type, P.facility, nvl(I.iskit, 'N') iskit,
             P.location, P.status, P.inventoryclass, I.unkitted_class
         from plate P, custitem I
         where P.lpid = in_lpid
           and I.custid (+) = P.custid
           and I.item (+) = P.item;
   lp c_lp%rowtype;
   cursor c_comp is
      select component
         from workordercomponents
         where custid = lp.custid
           and item = lp.item
           and decode(kitted_class, 'no', lp.inventoryclass, kitted_class)
               = lp.inventoryclass;
   cursor c_itemview(p_item varchar2) is
      select lotrequired, serialrequired, user1required, user2required,
             user3required, mfgdaterequired, expdaterequired, countryrequired
         from custitemview
         where custid = lp.custid
           and item = p_item;
   itv c_itemview%rowtype;
   cursor c_work is
      select tasktype
         from tasks
         where lpid in
            (select lpid from plate
               start with lpid = in_lpid
               connect by prior lpid = parentlpid)
      union
      select tasktype
         from subtasks
         where lpid in
            (select lpid from plate
               start with lpid = in_lpid
               connect by prior lpid = parentlpid);
   w c_work%rowtype;
   rowfound boolean;
begin
	out_msgno := 0;
   out_message := null;

   open c_lp;
   fetch c_lp into lp;
	rowfound := c_lp%found;
   close c_lp;

	if not rowfound then
		out_msgno := 1;
		out_message := 'LP not found';
      return;
   end if;

   out_custid := lp.custid;
   out_item := lp.item;
   out_location := lp.location;

   if (lp.type != 'PA') then
		out_msgno := 3;
		out_message := 'Single LP only';
      return;
   end if;

   if (lp.iskit != 'K') and (lp.iskit != 'I' or lp.inventoryclass = lp.unkitted_class) then
		out_msgno := 4;
		out_message := 'Item not a kit';
      return;
	end if;

   if (lp.facility != in_facility) then
		out_msgno := 6;
		out_message := 'LP not in fac';
      return;
	end if;

   if (lp.status != 'A') then
		out_msgno := 7;
		out_message := 'LP not avail';
      return;
	end if;

   for c in c_comp loop
      open c_itemview(c.component);
      fetch c_itemview into itv;
  	   close c_itemview;

      if (itv.lotrequired not in ('N', 'P')
      or  itv.serialrequired not in ('N', 'P')
      or  itv.user1required not in ('N', 'P')
      or  itv.user2required not in ('N', 'P')
      or  itv.user3required not in ('N', 'P')
      or  itv.mfgdaterequired not in ('N', 'P')
      or  itv.expdaterequired not in ('N', 'P')
      or  itv.countryrequired not in ('N', 'P')) then
   		out_msgno := 5;
	   	out_message := 'Needs detail';
         return;
	   end if;
   end loop;

   open c_work;
   fetch c_work into w;
   rowfound := c_work%found;
   close c_work;

   if rowfound then
  		out_msgno := 2;
      out_message := w.tasktype || ' task pending';
      return;
   end if;

exception
   when OTHERS then
   	out_msgno := sqlcode;
   	out_message := substr(sqlerrm, 1, 80);
end test_lp_dekit;


procedure dekit_lp
   (in_lpid       in varchar2,
	 in_user       in varchar2,
    out_msgno     out number,
    out_message   out varchar2)
is
   cursor c_lp is
      select item, custid, facility, lotnumber, unitofmeasure, quantity,
             inventoryclass, invstatus, weight, orderid, shipid
         from plate
         where lpid = in_lpid;
   lp c_lp%rowtype;
   cursor c_all_lps is
      select lpid
         from plate
         start with lpid = in_lpid
         connect by prior lpid = parentlpid;
   cursor c_comp is
      select component, qty
         from workordercomponents
         where custid = lp.custid
           and item = lp.item
           and decode(kitted_class, 'no', lp.inventoryclass, kitted_class)
               = lp.inventoryclass;
   cursor c_itemview(p_custid varchar2, p_item varchar2) is
      select baseuom, unkitted_class
         from custitemview
         where custid = p_custid
           and item = p_item;
   itv c_itemview%rowtype;
   rowfound boolean;
   msg varchar2(80) := null;
   mlip plate.lpid%type := in_lpid;
   clip plate.lpid%type;
   l_class plate.inventoryclass%type;
begin
	out_msgno := 0;
   out_message := null;

   open c_lp;
   fetch c_lp into lp;
	rowfound := c_lp%found;
   close c_lp;

	if not rowfound then
		out_msgno := 1;
		out_message := 'LP not found';
      return;
   end if;

-- delete kit inventory
   zbill.add_asof_inventory(lp.facility, lp.custid, lp.item, lp.lotnumber,
         lp.unitofmeasure, sysdate, -lp.quantity, -lp.weight, 'DeKitOut', 'AD',
         lp.inventoryclass, lp.invstatus, lp.orderid, lp.shipid, in_lpid,
         in_user, msg);
   if (msg != 'OKAY') then
		out_msgno := 2;
      out_message := msg;
      return;
   end if;

-- delete plate and all children
   for a in c_all_lps loop
      zlp.plate_to_deletedplate(a.lpid, in_user, null, msg);
      if (msg is not null) then
         out_msgno := 3;
         out_message := msg;
         return;
      end if;
   end loop;

-- remove plate from deleted table since we are going to "reuse" the lpid
   delete from deletedplate
      where lpid = in_lpid;

-- create the multi
   zplp.build_empty_parent(mlip, lp.facility, in_user, 'U', 'MP', in_user,
         'PUT', lp.custid, null, null, null, null, null, null, null, null, null, msg);
   if (msg is not null) then
      out_msgno := 4;
      out_message := msg;
      return;
   end if;

-- loop thru each kit component
   for c in c_comp loop
      open c_itemview(lp.custid, c.component);
      fetch c_itemview into itv;
  	   close c_itemview;
      if c.component = lp.item then
         l_class := itv.unkitted_class;
      else
         l_class := 'RG';
      end if;

--    build child plate
      zrf.get_next_lpid(clip, msg);
      if (msg is not null) then
         out_msgno := 5;
         out_message := msg;
         return;
      end if;
      insert into plate
         (lpid, item, custid, facility, location, status,
          unitofmeasure, quantity, type, creationdate, lastoperator, disposition,
          lastuser, lastupdate, invstatus, inventoryclass,
          weight,
          fromlpid, parentfacility, parentitem, qtyentered, uomentered)
      values
         (clip, c.component, lp.custid, lp.facility, in_user, 'U',
          itv.baseuom, c.qty*lp.quantity, 'PA', sysdate, in_user, 'PUT',
          in_user, sysdate, 'AV', l_class,
          zci.item_weight(lp.custid, c.component, itv.baseuom)*c.qty*lp.quantity,
          in_lpid, lp.facility, c.component, c.qty*lp.quantity, itv.baseuom);

--    attach it
      zplp.attach_child_plate(mlip, clip, in_user, 'U', in_user, msg);
      if (msg is not null) then
         out_msgno := 6;
         out_message := msg;
         return;
      end if;

--    add component inventory
      zbill.add_asof_inventory(lp.facility, lp.custid, c.component, null, itv.baseuom,
            sysdate, c.qty*lp.quantity,
            zci.item_weight(lp.custid, c.component, itv.baseuom)*c.qty*lp.quantity,
            'DeKitIn', 'AD', l_class, 'AV', lp.orderid, lp.shipid, clip, in_user, msg);
      if (msg != 'OKAY') then
		   out_msgno := 7;
         out_message := msg;
         return;
      end if;
   end loop;

exception
   when OTHERS then
   	out_msgno := sqlcode;
   	out_message := substr(sqlerrm, 1, 80);
end dekit_lp;


procedure restore_comp_lp
   (in_lpid       in varchar2,
    in_facility   in varchar2,
    in_qty        in number,
	 in_user       in varchar2,
    in_mlip       in varchar2,
    in_klip       in varchar2,
    out_error     out varchar2,
    out_msgno     out number,
    out_message   out varchar2)
is
   cursor c_lp is
      select custid, item, unitofmeasure, lotnumber, inventoryclass,
             invstatus, orderid, shipid,
             zcwt.lp_item_weight(lpid, custid, item, unitofmeasure) as unitweight
         from deletedplate
         where lpid = in_lpid;
   lp c_lp%rowtype;
   cursor c_itemview(p_custid varchar2, p_item varchar2) is
      select nvl(maxqtyof1, 'N') maxqtyof1
         from custitemview
         where custid = p_custid
           and item = p_item;
   itv c_itemview%rowtype;
   cursor c_kp is
      select custid, item, quantity, inventoryclass
         from plate
         where lpid = in_klip;
   kp c_kp%rowtype;
   cursor c_cmp(p_custid varchar2, p_item varchar2, p_comp varchar2, p_kitted_class varchar2) is
   select qty
      from workordercomponents
      where custid = p_custid
        and item = p_item
        and decode(kitted_class, 'no', p_kitted_class, kitted_class) = p_kitted_class
        and component = p_comp;
   cmp c_cmp%rowtype;
   dekittedqty plate.quantity%type;
   rowfound boolean;
   cnt pls_integer := 0;
   msg varchar2(80) := null;
begin
   out_error := 'N';
	out_msgno := 0;
   out_message := null;

   select count(1) into cnt
      from plate
      where lpid = in_lpid;
   if (cnt != 0) then
      out_msgno := 1;
      out_message := 'LP is active';
      return;
   end if;

   open c_lp;
   fetch c_lp into lp;
	rowfound := c_lp%found;
   close c_lp;
	if not rowfound then
		out_msgno := 2;
		out_message := 'LP not deleted';
      return;
   end if;
   open c_itemview(lp.custid, lp.item);
   fetch c_itemview into itv;
  	close c_itemview;

   open c_kp;
   fetch c_kp into kp;
	rowfound := c_kp%found;
   close c_kp;
	if not rowfound then
		out_msgno := 3;
		out_message := 'KitLP not found';
      return;
   end if;

   open c_cmp(lp.custid, kp.item, lp.item, kp.inventoryclass);
   fetch c_cmp into cmp;
   rowfound := c_cmp%found;
   close c_cmp;
   if (not rowfound or (lp.custid != kp.custid)) then
		out_msgno := 4;
		out_message := 'Not a component';
      return;
   end if;

   select nvl(sum(quantity), 0)
      into dekittedqty
      from plate
      where custid = lp.custid
        and item = lp.item
        and fromlpid = in_klip;

   if ((dekittedqty + (in_qty * cmp.qty)) > kp.quantity) then
		out_msgno := 8;
		out_message := 'Qty too large';
      return;
   end if;

   if ((in_qty > 1) and (itv.maxqtyof1 = 'Y')) then
		out_msgno := 5;
		out_message := 'Max qty of 1';
      return;
   end if;

   insert into plate
      select *
         from deletedplate
         where lpid = in_lpid;

-- remove plate from deleted table since we are going to "reuse" the lpid
   delete from deletedplate
      where lpid = in_lpid;

   update plate
      set facility = in_facility,
          location = in_user,
          status = 'U',
          quantity = in_qty,
          lastoperator = in_user,
          disposition = 'PUT',
          lastuser = in_user,
          lastupdate = sysdate,
          lasttask = 'DK',
          weight = in_qty * lp.unitweight,
          fromlpid = in_klip,
          parentfacility = in_facility,
          parentitem = lp.item,
          parentlpid = null,
          childfacility = null,
          childitem = null
      where lpid = in_lpid;

   if (in_mlip is not null) then
      zplp.attach_child_plate(in_mlip, in_lpid, in_user, 'U', in_user, msg);
      if (msg is not null) then
         out_error := 'Y';
         out_msgno := 6;
         out_message := msg;
         return;
      end if;
   end if;

-- add component inventory
   zbill.add_asof_inventory(in_facility, lp.custid, lp.item, lp.lotnumber,
         lp.unitofmeasure, sysdate, in_qty, in_qty * lp.unitweight,
         'DeKitIn', 'AD', lp.inventoryclass, lp.invstatus, lp.orderid, lp.shipid,
         in_lpid, in_user, msg);
   if (msg != 'OKAY') then
      out_error := 'Y';
      out_msgno := 7;
      out_message := msg;
   end if;

exception
   when OTHERS then
      out_error := 'Y';
   	out_msgno := sqlcode;
   	out_message := substr(sqlerrm, 1, 80);
end restore_comp_lp;


procedure finish_noauto_dekit
   (in_lpid       in varchar2,
    in_qty        in number,
	 in_user       in varchar2,
    out_message   out varchar2)
is
   cursor c_lp is
      select item, custid, facility, lotnumber, unitofmeasure, quantity,
             inventoryclass, invstatus, weight, orderid, shipid
         from plate
         where lpid = in_lpid;
   lp c_lp%rowtype;
   cursor c_comp is
      select item, lotnumber, unitofmeasure, quantity, inventoryclass,
             invstatus, weight, orderid, shipid, lpid
         from plate
         where facility = lp.facility
           and location = in_user
           and status = 'U'
           and custid = lp.custid
           and type = 'PA';
   rowfound boolean;
   msg varchar2(80) := null;
   l_err varchar2(1);
begin
   out_message := null;

   open c_lp;
   fetch c_lp into lp;
	rowfound := c_lp%found;
   close c_lp;

	if not rowfound then
		out_message := 'LP not found';
      return;
   end if;

-- delete kit inventory
   zbill.add_asof_inventory(lp.facility, lp.custid, lp.item, lp.lotnumber,
         lp.unitofmeasure, sysdate, -in_qty,
         -(in_qty * zcwt.lp_item_weight(in_lpid, lp.custid, lp.item, lp.unitofmeasure)),
         'DeKitOut', 'AD',
         lp.inventoryclass, lp.invstatus, lp.orderid, lp.shipid, in_lpid,
         in_user, msg);
   if (msg != 'OKAY') then
      out_message := msg;
      return;
   end if;

-- loop thru each component LP
   for c in c_comp loop

--    add component inventory
      zbill.add_asof_inventory(lp.facility, lp.custid, c.item, c.lotnumber,
            c.unitofmeasure, sysdate, c.quantity, c.weight, 'DeKitIn', 'AD',
            c.inventoryclass, c.invstatus, c.orderid, c.shipid, c.lpid,
            in_user, msg);
      if (msg != 'OKAY') then
         out_message := msg;
         return;
      end if;
   end loop;

---delete/update original kit plate
   zrf.decrease_lp(in_lpid, lp.custid, lp.item, in_qty, lp.lotnumber,
         lp.unitofmeasure, in_user, 'DK', lp.invstatus, lp.inventoryclass, l_err, msg);
   out_message := msg;

exception
   when OTHERS then
   	out_message := substr(sqlerrm, 1, 80);
end finish_noauto_dekit;


procedure finish_comp_cleanup
   (in_facility   in varchar2,
    in_seq        in number,
    in_item       in varchar2,
    in_user       in varchar2,
    in_lpid       in varchar2,
    in_lpqty      in number,
    in_putfromloc in varchar2,
    in_opcode     in number,
    in_spoiled    in varchar2,
    out_error     out varchar2,
    out_msgno     out number,
    out_message   out varchar2)
is
   cursor c_lps is
      select * from plate
         where workorderseq = in_seq
           and item = in_item
           and type = 'PA'
           and status = 'K';
   plt c_lps%rowtype;
   rowfound boolean;
   adjreason varchar2(12);
   adjrowid1 varchar2(20);
   adjrowid2 varchar2(20);
   errorno number;
   msg varchar2(80);
   adjqty number;
   dummyequip userheader.equipment%type := 'XX';
   dummyfac facility.facility%type;
   dummyloc location.locid%type;
   l_key number := 0;
begin
   out_error := 'N';
	out_msgno := 0;
   out_message := null;

   begin
      select defaultvalue into adjreason
         from systemdefaults
         where defaultid = 'SPOILAGEREASON';
   exception
      when OTHERS then
         out_message := 'No spoilage reason';
         return;
   end;

	zrf.so_lock(l_key);
   for lp in c_lps loop

      if ((in_lpid is not null) and (in_opcode = OP_INSERT) and (c_lps%rowcount = 1)) then
         insert into plate
            (lpid, item, custid, facility, location, status,
             holdreason, unitofmeasure, quantity, type, serialnumber,
             lotnumber, creationdate, manufacturedate, expirationdate,
             expiryaction, lastcountdate, po, recmethod, condition, lastoperator,
             lasttask, fifodate, destlocation, destfacility, countryof,
             parentlpid, useritem1, useritem2, useritem3, disposition,
             lastuser, lastupdate, invstatus, qtyentered, itementered, uomentered,
             inventoryclass, loadno, stopno, shipno, orderid, shipid,
             weight, adjreason, qtyrcvd, controlnumber, qcdisposition, fromlpid,
             taskid, dropseq, fromshippinglpid, workorderseq, workordersubseq,
             parentfacility, parentitem, anvdate)
         values
            (in_lpid, lp.item, lp.custid, in_facility, in_putfromloc, 'A',
             null, lp.unitofmeasure, 0, 'PA', lp.serialnumber,
             lp.lotnumber, sysdate, lp.manufacturedate, lp.expirationdate,
             lp.expiryaction, null, null, null, null, in_user,
             'KC', null, null, null, lp.countryof,
             null, lp.useritem1, lp.useritem2, lp.useritem3, 'PUT',
             in_user, sysdate, lp.invstatus, in_lpqty, lp.itementered, lp.unitofmeasure,
             lp.inventoryclass, null, null, null, null, null,
             0, lp.adjreason, null, null, null, lp.lpid,
             null, null, null, lp.workorderseq, 0,
             in_facility, lp.item, lp.anvdate);

         zia.inventory_adjustment(in_lpid, lp.custid, lp.item, lp.inventoryclass,
               lp.invstatus, lp.lotnumber, lp.serialnumber, lp.useritem1,
               lp.useritem2, lp.useritem3, in_putfromloc, lp.expirationdate,
               in_lpqty, lp.custid, lp.item, lp.inventoryclass, lp.invstatus,
               lp.lotnumber, lp.serialnumber, lp.useritem1, lp.useritem2,
               lp.useritem3, in_putfromloc, lp.expirationdate, 0,
               lp.facility, adjreason, in_user, 'KC', lp.weight, 0,
               lp.manufacturedate, lp.manufacturedate,
               lp.anvdate, lp.anvdate,
               adjrowid1, adjrowid2, errorno, msg);

         if (errorno != 0) then
            out_error := 'I';
            out_msgno := errorno;
            out_message := msg;
            return;
         end if;
      end if;

      if (lp.lpid != nvl(in_lpid, '(none)')) then
         adjqty := 0;

         update plate
            set status = 'A',
                lastuser = in_user,
                lastoperator = in_user,
                lastupdate = sysdate,
                lasttask = 'KC'
            where lpid = lp.lpid;

      else
         adjqty := in_lpqty;
         lp.location := in_putfromloc;

         update plate
            set status = 'A',
                location = in_putfromloc,
                disposition = 'PUT',
                lastuser = in_user,
                lastoperator = in_user,
                lastupdate = sysdate,
                lasttask = 'KC'
            where lpid = lp.lpid;

      end if;

      if (adjqty != lp.quantity) then
         zia.inventory_adjustment(lp.lpid, lp.custid, lp.item, lp.inventoryclass,
               lp.invstatus, lp.lotnumber, lp.serialnumber, lp.useritem1,
               lp.useritem2, lp.useritem3, lp.location, lp.expirationdate,
               adjqty, lp.custid, lp.item, lp.inventoryclass, lp.invstatus,
               lp.lotnumber, lp.serialnumber, lp.useritem1, lp.useritem2,
               lp.useritem3, lp.location, lp.expirationdate, lp.quantity,
               lp.facility, adjreason, in_user, 'KC', adjqty * lp.weight / lp.quantity,
               lp.weight, lp.manufacturedate, lp.manufacturedate,
               lp.anvdate, lp.anvdate,
               adjrowid1, adjrowid2, errorno, msg);

         if (errorno != 0) then
            out_error := 'I';
            out_msgno := errorno;
            out_message := msg;
            return;
         end if;
      end if;
   end loop;

   if ((in_lpid is not null) and (in_opcode = OP_UNDELETE)) then
      select * into plt
         from deletedplate
         where lpid = in_lpid;

      delete from deletedplate where lpid = in_lpid;

      insert into plate
         (lpid, item, custid, facility, location, status,
          holdreason, unitofmeasure, quantity, type, serialnumber,
          lotnumber, creationdate, manufacturedate, expirationdate,
          expiryaction, lastcountdate, po, recmethod, condition, lastoperator,
          lasttask, fifodate, destlocation, destfacility, countryof,
          parentlpid, useritem1, useritem2, useritem3, disposition,
          lastuser, lastupdate, invstatus, qtyentered, itementered, uomentered,
          inventoryclass, loadno, stopno, shipno, orderid, shipid,
          weight,
          adjreason, qtyrcvd, controlnumber, qcdisposition, fromlpid,
          taskid, dropseq, fromshippinglpid, workorderseq, workordersubseq,
          parentfacility, parentitem, anvdate)
      values
         (in_lpid, plt.item, plt.custid, in_facility, in_putfromloc, 'A',
          plt.holdreason, plt.unitofmeasure, 0, 'PA', plt.serialnumber,
          plt.lotnumber, plt.creationdate, plt.manufacturedate, plt.expirationdate,
          plt.expiryaction, plt.lastcountdate, plt.po, plt.recmethod, plt.condition, in_user,
          'KC', plt.fifodate, plt.destlocation, plt.destfacility, plt.countryof,
          null, plt.useritem1, plt.useritem2, plt.useritem3, 'PUT',
          in_user, sysdate, plt.invstatus, plt.qtyentered, plt.itementered, plt.uomentered,
          plt.inventoryclass, plt.loadno, plt.stopno, plt.shipno, plt.orderid, plt.shipid,
          in_lpqty * zci.item_weight(plt.custid, plt.item, plt.unitofmeasure),
          plt.adjreason, plt.qtyrcvd, plt.controlnumber, plt.qcdisposition, plt.fromlpid,
          plt.taskid, plt.dropseq, plt.fromshippinglpid, plt.workorderseq, 0,
          in_facility, plt.item, plt.anvdate);

      zia.inventory_adjustment(in_lpid, plt.custid, plt.item, plt.inventoryclass,
            plt.invstatus, plt.lotnumber, plt.serialnumber, plt.useritem1,
            plt.useritem2, plt.useritem3, in_putfromloc, plt.expirationdate,
            in_lpqty, plt.custid, plt.item, plt.inventoryclass, plt.invstatus,
            plt.lotnumber, plt.serialnumber, plt.useritem1, plt.useritem2,
            plt.useritem3, in_putfromloc, plt.expirationdate, 0,
            plt.facility, adjreason, in_user, 'KC',
            in_lpqty * zci.item_weight(plt.custid, plt.item, plt.unitofmeasure),
            0, plt.manufacturedate, plt.manufacturedate,
            plt.anvdate, plt.anvdate,
            adjrowid1, adjrowid2, errorno, msg);

      if (errorno != 0) then
         out_error := 'I';
         out_msgno := errorno;
         out_message := msg;
         return;
      end if;
   end if;

   update custworkorderinstructions
      set status ='D'
      where seq = in_seq;
   commit;
   if (in_lpid is not null) then
      zput.putaway_lp('TANR', in_lpid, in_facility, in_putfromloc, in_user,
            'N', dummyequip, msg, dummyfac, dummyloc);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
      end if;
   end if;

exception
   when OTHERS then
      out_error := 'Y';
   	out_message := substr(sqlerrm, 1, 80);
end finish_comp_cleanup;


procedure package_component
   (in_facility     in varchar2,
    in_opcode       in number,
    in_seq          in number,
    in_lpid         in varchar2,
    in_custid       in varchar2,
    in_item         in varchar2,
    in_invstatus    in varchar2,
    in_invclass     in varchar2,
    in_lotnumber    in varchar2,
    in_serialnumber in varchar2,
    in_useritem1    in varchar2,
    in_useritem2    in varchar2,
    in_useritem3    in varchar2,
    in_qty          in number,
    in_uom          in varchar2,
    in_user         in varchar2,
    in_weight       in number,
    out_done        out varchar2,
    out_error       out varchar2,
    out_message     out varchar2)
is
   cursor c_itemview is
      select baseuom, expiryaction
         from custitemview
         where custid = in_custid
           and item = in_item;
   itv c_itemview%rowtype;

   cursor c_mp_child is
      select lpid
         from plate
         where parentlpid = in_lpid
           and custid = in_custid
           and item = in_item
           and invstatus = in_invstatus
           and inventoryclass = in_invclass
           and nvl(lotnumber, '(none)') = nvl(in_lotnumber, '(none)')
           and nvl(serialnumber, '(none)') = nvl(in_serialnumber, '(none)')
           and nvl(useritem1, '(none)') = nvl(in_useritem1, '(none)')
           and nvl(useritem2, '(none)') = nvl(in_useritem2, '(none)')
           and nvl(useritem3, '(none)') = nvl(in_useritem3, '(none)');

   cursor c_lps is
      select parentlpid, lpid, location, status, lotnumber, unitofmeasure, quantity
         from plate
         where workorderseq = in_seq
           and type = 'PA'
           and status = 'K'
           and custid = in_custid
           and item = in_item
           and invstatus = in_invstatus
           and inventoryclass = in_invclass
           and nvl(lotnumber, '(none)') = nvl(in_lotnumber, '(none)')
           and nvl(serialnumber, '(none)') = nvl(in_serialnumber, '(none)')
           and nvl(useritem1, '(none)') = nvl(in_useritem1, '(none)')
           and nvl(useritem2, '(none)') = nvl(in_useritem2, '(none)')
           and nvl(useritem3, '(none)') = nvl(in_useritem3, '(none)')
         order by quantity;

   qtyavail plate.quantity%type;
   qtyneeded plate.quantity%type;
   qtyleft plate.quantity%type;
	err varchar2(1) := null;
   msg varchar2(80) := null;
   newlpid plate.lpid%type;
   rowfound boolean;

procedure build_pkg_plate
   (p_lpid in varchar2)
is
begin
   insert into plate
      (lpid, item, custid, facility, location, status,
       holdreason, unitofmeasure, quantity, type, serialnumber,
       lotnumber, creationdate, manufacturedate, expirationdate,
       expiryaction, lastcountdate, po, recmethod, condition, lastoperator,
       lasttask, fifodate, destlocation, destfacility, countryof,
       parentlpid, useritem1, useritem2, useritem3, disposition,
       lastuser, lastupdate, invstatus, qtyentered, itementered, uomentered,
       inventoryclass, loadno, stopno, shipno, orderid, shipid, weight,
       adjreason, qtyrcvd, controlnumber, qcdisposition, fromlpid,
       taskid, dropseq, fromshippinglpid, workorderseq, workordersubseq,
       parentfacility, parentitem)
   values
      (p_lpid, in_item, in_custid, in_facility, in_user, 'U',
       null, itv.baseuom, qtyneeded, 'PA', in_serialnumber,
       in_lotnumber, sysdate, null, null,
       itv.expiryaction, null, null, null, null, in_user,
       'KC', null, null, null, null,
       null, in_useritem1, in_useritem2, in_useritem3, null,
       in_user, sysdate, in_invstatus, qtyneeded, in_item, itv.baseuom,
       in_invclass, null, null, null, null, null, in_weight,
       null, null, null, null, null,
       null, null, null, in_seq, 0,
       in_facility, in_item);
end;

begin
   out_done := 'N';
   out_error := 'N';
   out_message := null;

   select nvl(sum(quantity), 0) into qtyavail
      from plate
      where workorderseq = in_seq
        and type = 'PA'
        and status = 'K'
        and custid = in_custid
        and item = in_item
        and invstatus = in_invstatus
        and inventoryclass = in_invclass
        and nvl(lotnumber, '(none)') = nvl(in_lotnumber, '(none)')
        and nvl(serialnumber, '(none)') = nvl(in_serialnumber, '(none)')
        and nvl(useritem1, '(none)') = nvl(in_useritem1, '(none)')
        and nvl(useritem2, '(none)') = nvl(in_useritem2, '(none)')
        and nvl(useritem3, '(none)') = nvl(in_useritem3, '(none)');

   open c_itemview;
   fetch c_itemview into itv;
  	close c_itemview;

   zbut.translate_uom(in_custid, in_item, in_qty, in_uom, itv.baseuom, qtyneeded, msg);
   if substr(msg, 1, 4) != 'OKAY' then
      out_message := 'No uom conversion';
      return;
   end if;

   if qtyneeded > qtyavail then
      out_message := 'Qty not available';
      return;
   end if;

   if in_opcode = OP_INSERT then
      build_pkg_plate(in_lpid);
   elsif in_opcode = OP_UPDATE then
      update plate
         set quantity = quantity + qtyneeded,
             lastoperator = in_user,
             lasttask = 'KC',
             lastuser = in_user,
             lastupdate = sysdate,
             qtyentered = qtyentered + qtyneeded,
             weight = weight + in_weight
         where lpid = in_lpid;
   elsif in_opcode = OP_UNDELETE then
      delete
         from deletedplate
         where lpid = in_lpid;
      build_pkg_plate(in_lpid);
   elsif in_opcode = OP_MIX then
      zplp.morph_lp_to_multi(in_lpid, in_user, msg);
      if msg is null then
         zrf.get_next_lpid(newlpid, msg);
         if msg is null then
            build_pkg_plate(newlpid);
            zplp.attach_child_plate(in_lpid, newlpid, in_user, 'U', in_user, msg);
         end if;
      end if;
      if msg is not null then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;
   else
      open c_mp_child;
      fetch c_mp_child into newlpid;
   	rowfound := c_mp_child%found;
      close c_mp_child;

      if rowfound then     -- try to just update an existing child
         update plate
            set quantity = quantity + qtyneeded,
                lastoperator = in_user,
                lasttask = 'KC',
                lastuser = in_user,
                lastupdate = sysdate,
                qtyentered = qtyentered + qtyneeded,
                weight = weight + in_weight
            where lpid = newlpid;

         update plate
            set quantity = quantity + qtyneeded,
                lastoperator = in_user,
                lasttask = 'KC',
                lastuser = in_user,
                lastupdate = sysdate,
                weight = weight + in_weight
            where lpid = in_lpid;

      else
         zrf.get_next_lpid(newlpid, msg);
         if msg is null then
            build_pkg_plate(newlpid);
            zplp.attach_child_plate(in_lpid, newlpid, in_user, 'U', in_user, msg);
         end if;
         if msg is not null then
            out_error := 'Y';
            out_message := msg;
            return;
         end if;
      end if;
   end if;

   qtyleft := qtyneeded;
   for l in c_lps loop
      if l.quantity <= qtyleft then
         if l.parentlpid is not null then
            zplp.detach_child_plate(l.parentlpid, l.lpid, l.location, null, null,
                  l.status, in_user, null, msg);
            if msg is not null then
               out_error := 'Y';
               out_message := msg;
               return;
            end if;
         end if;
         zlp.plate_to_deletedplate(l.lpid, in_user, null, msg);
         if msg is not null then
            out_error := 'Y';
            out_message := msg;
            return;
         end if;
         qtyleft := qtyleft - l.quantity;
      else
         zrf.decrease_lp(l.lpid, in_custid, in_item, qtyleft, l.lotnumber,
               l.unitofmeasure, in_user, null, in_invstatus, in_invclass, err, msg);
         if msg is not null then
            out_error := err;
            out_message := msg;
            return;
         end if;
         qtyleft := 0;
      end if;
      exit when qtyleft = 0;
   end loop;

   if qtyleft != 0 then
      out_message := 'Qty not available';
      rollback;
      return;
   end if;

   select nvl(sum(quantity), 0) into qtyleft
      from plate
      where workorderseq = in_seq
        and type = 'PA'
        and status = 'K';

   update custworkorderinstructions
      set completedqty = nvl(completedqty, 0) + qtyneeded,
          status = decode(qtyleft, 0, 'D', status)
      where seq = in_seq
        and action = 'KR';

   update custworkorder
      set completedqty = nvl(completedqty, 0) + qtyneeded,
          status = decode(qtyleft, 0, decode(status, 'P', 'D', status), status)
      where seq = in_seq;

   if qtyleft = 0 then
      out_done := 'Y';
   end if;

exception
   when OTHERS then
      out_error := 'Y';
   	out_message := substr(sqlerrm, 1, 80);
end package_component;

procedure complete_kit_wave
(in_wave IN number
,in_userid IN varchar2
,out_errmsg IN OUT varchar2
)
IS
cnt integer;

CURSOR C_WV(in_wave number)
IS
SELECT *
  FROM waves
 WHERE wave = in_wave;

WV waves%rowtype;

BEGIN
    out_errmsg := 'OKAY';

-- Verify wave
    WV := null;
    OPEN C_WV(in_wave);
    FETCH C_WV into WV;
    CLOSE C_WV;

    if WV.wave is null then
        out_errmsg := 'Not a valid wave.';
        return;
    end if;

    if WV.wavestatus = '4' then
        out_errmsg := 'Wave already completed.';
        return;
    end if;

-- verify the wave only consists of kit work orders (all 'W' & 'K')
    cnt := 0;
    select count(1)
      into cnt
      from orderhdr
     where wave = in_wave
       and ordertype not in ('W','K');
    if nvl(cnt,0) > 0 then
        out_errmsg := 'Not a work order only wave.';
        return;
    end if;

-- Verify all orders are status >= '6' or in ('6','X')
    cnt := 0;
    select count(1)
      into cnt
      from orderhdr
     where wave = in_wave
       and orderstatus < '6';
    if nvl(cnt,0) > 0 then
        out_errmsg := 'Not all orders complete';
        return;
    end if;

-- update wave to status '4'
    update waves
       set wavestatus = '4',
           lastuser = in_userid,
           lastupdate = sysdate
     where wave = in_wave;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := sqlerrm;
end complete_kit_wave;


procedure closeout_kit
   (in_orderid   in number,
    in_shipid    in number,
    in_item      in varchar2,
    in_lotnumber in varchar2,
	 in_user      in varchar2,
    out_message  out varchar2)
is
   cursor c_od(p_orderid number, p_shipid number, p_item varchar2, p_lotnumber varchar2) is
      select OD.childorderid,
             OD.childshipid,
             OH.workorderseq,
             CW.status
         from orderdtl OD, orderhdr OH, custworkorder CW
         where OD.orderid = p_orderid
           and OD.shipid = p_shipid
           and OD.item = p_item
           and nvl(OD.lotnumber, '(none)') = nvl(p_lotnumber, '(none)')
           and OH.orderid = OD.childorderid
           and OH.shipid = OD.childshipid
           and CW.seq (+) = OH.workorderseq;
	od c_od%rowtype := null;
   cursor c_st(p_orderid number, p_shipid number) is
      select ST.rowid,
             ST.taskid,
             ST.custid,
             ST.facility,
             ST.lpid
         from subtasks ST, tasks TK
         where ST.orderid = p_orderid
          and ST.shipid = p_shipid
          and TK.taskid = ST.taskid
          and TK.priority != '0';
   cursor c_lp(p_workorderseq number) is
      select lpid,
             facility,
             location,
             item,
             workordersubseq,
             rowid
         from plate
         where workorderseq = p_workorderseq
           and parentlpid is null
           and status = 'K';
	cx custworkorderinstructions.subseq%type;
   l_msg varchar2(255);
   l_fac plate.facility%type;
   l_loc plate.location%type;
   l_orderstatus orderhdr.orderstatus%type;
   l_cnt pls_integer;
begin
   out_message := 'OKAY';

   open c_od(in_orderid, in_shipid, in_item, in_lotnumber);
   fetch c_od into od;
   close c_od;

   if od.workorderseq is null then
      out_message := 'Work order not found';
      return;
   end if;

   if od.status != 'P' then
      out_message := 'Work order not active';
      return;
   end if;

-- cleanup non-active tasks (also commitments, subtasks, batchtasks and shippingplates)
   for st in c_st(od.childorderid, od.childshipid) loop
      ztk.subtask_no_pick(st.rowid, st.facility, st.custid, st.taskid, st.lpid,
            in_user, 'Y', l_msg);
      if substr(l_msg,1,4) != 'OKAY' then
         out_message := l_msg;
         return;
      end if;
   end loop;

-- mark workorder as closed
   update custworkorder
      set status = 'C'
      where seq = od.workorderseq;

-- generate putaway tasks for any plates which have not had any kitting
-- steps performed against them
   load_custworkorder(od.workorderseq, l_msg);
   if l_msg is not null then
      out_message := l_msg;
      return;
   end if;

   select count(1) into l_cnt
      from subtasks
      where orderid = od.childorderid
        and shipid = od.childshipid;
   if l_cnt = 0 then
      l_orderstatus := '9';
   else
      l_orderstatus := '6';
   end if;

   for lp in c_lp(od.workorderseq) loop
   	cx := first_subseq(lp.item, lp.facility);
   	if (cx != 0) then
         if cwo_tbl(cx).parent = lp.workordersubseq then
            update plate
               set status = 'A',
                   lasttask = 'KC',
                   lastoperator = in_user,
                   disposition = 'PUT',
                   lastuser = in_user,
                   lastupdate = sysdate,
                   workorderseq = null,
                   workordersubseq = null
               where rowid = lp.rowid;

            zput.putaway_lp('TANR', lp.lpid, lp.facility, lp.location, in_user, 'Y',
                  null, l_msg, l_fac, l_loc);
         else
            l_orderstatus := '6';
         end if;
      end if;
   end loop;

   update orderhdr
      set orderstatus = l_orderstatus,
          lastuser = in_user,
          lastupdate = sysdate
      where workorderseq = od.workorderseq
        and orderstatus < l_orderstatus;

exception
   when OTHERS then
      out_message := sqlerrm;
end closeout_kit;


procedure purge_closed_kit_subtask
   (in_rowid    in varchar2,
	 in_user     in varchar2,
    out_results out varchar2,
    out_message out varchar2)
is
   cursor c_st(p_rowid varchar2) is
		select taskid,
             facility,
             custid,
             lpid,
             zcord.cons_workorderseq(orderid, shipid) as workorderseq
			from subtasks
         where rowid = chartorowid(p_rowid);
   st c_st%rowtype := null;
   cursor c_cwo(p_seq number) is
      select status
         from custworkorder
         where seq = p_seq;
   cwo c_cwo%rowtype := null;
   l_msg varchar2(255);
   l_cnt pls_integer;
begin
   out_results := 'N';        -- nothing deleted and no errors
   out_message := null;

   open c_st(in_rowid);
   fetch c_st into st;
   close c_st;

   if st.workorderseq is not null then
      open c_cwo(st.workorderseq);
      fetch c_cwo into cwo;
      close c_cwo;

      if nvl(cwo.status,'x') = 'C' then
         update tasks            -- otherwise subtask_no_pick will throw an error
            set priority = '9'
            where taskid = st.taskid;
         ztk.subtask_no_pick(chartorowid(in_rowid), st.facility, st.custid, st.taskid,
               st.lpid, in_user, 'Y', l_msg);
         if substr(l_msg,1,4) != 'OKAY' then
            out_results := 'E';
            out_message := substr(l_msg,1,80);
         else
            update tasks
               set priority = '0'
               where taskid = st.taskid;
            out_results := 'S';  -- subtask cleaned-up
            select count(1) into l_cnt
               from subtasks
               where (orderid, shipid) in
                     (select orderid, shipid from orderhdr
                        where workorderseq = st.workorderseq);
            if l_cnt = 0 then
               update orderhdr
                  set orderstatus = '9',
                      lastuser = in_user,
                      lastupdate = sysdate
                  where workorderseq = st.workorderseq
                    and orderstatus < '9';
            end if;
         end if;
      end if;
   end if;

exception
   when OTHERS then
      out_results := 'E';
   	out_message := substr(sqlerrm, 1, 80);
end purge_closed_kit_subtask;


end kitting;
/

show errors package body kitting;
exit;
