create or replace package body alps.rfxferorder as
--
-- $Id$
--


-- Public procedures


procedure receive_lp
   (in_lpid     in varchar2,
    in_loadno   in number,
    in_user     in varchar2,
    out_error   out varchar2,
    out_message out varchar2)
is
   msg varchar2(80);
   lptype plate.type%type;
   xrefid plate.lpid%type;
   xreftype plate.type%type;
   parentid plate.lpid%type;
   parenttype plate.type%type;
   topid plate.lpid%type;
   toptype plate.type%type;
   cursor c_lp(p_lpid varchar2) is
      select status, parentlpid, location
         from plate
         where lpid = p_lpid;
   lp c_lp%rowtype;
	cursor c_sp(p_lpid varchar2) is
		select S.loadno
			from shippingplate S, loads L
         where S.fromlpid in (select lpid from plate
											start with lpid = p_lpid
											connect by prior lpid = parentlpid)
			  and S.type = 'F'
			  and L.loadno = S.loadno
			  and substr(L.loadtype, 1, 1) = 'I'
			  and L.loadstatus in ('A', 'E');
   sp c_sp%rowtype;
	cursor c_lptree(p_lpid varchar2) is
		select P.lpid, P.invstatus, P.quantity, P.custid, P.item,
				 zcwt.lp_item_weight(P.lpid, P.custid, P.item, P.unitofmeasure) weight,
				 zci.item_cube(P.custid, P.item, P.unitofmeasure) cube,
				 S.orderitem, S.orderlot, S.orderid,
				 S.shipid, S.stopno, S.shipno, P.unitofmeasure,
             P.itementered, P.uomentered, P.facility, P.lotnumber
			from plate P, shippingplate S
			where P.lpid in (select lpid from plate
			   						where type = 'PA'
										start with lpid = p_lpid
										connect by prior lpid = parentlpid)
			  and S.fromlpid = P.lpid
			  and S.type = 'F'
			  and S.loadno = in_loadno;
   cursor c_itemview(p_custid varchar2, p_item varchar2) is
      select useramt1
         from custitemview
         where custid = p_custid
           and item = p_item;
   itv c_itemview%rowtype;
	l_qtyrcvdgood orderdtl.qtyrcvd%type;
	l_qtyrcvddmgd orderdtl.qtyrcvd%type;
	l_weightrcvdgood orderdtl.weightrcvd%type;
	l_weightrcvddmgd orderdtl.weightrcvd%type;
	l_cubercvdgood orderdtl.cubercvd%type;
	l_cubercvddmgd orderdtl.cubercvd%type;
	l_amtrcvdgood orderdtl.amtrcvd%type;
	l_amtrcvddmgd orderdtl.amtrcvd%type;
begin
   out_error := 'N';
   out_message := null;

	zrf.identify_lp(in_lpid, lptype, xrefid, xreftype, parentid, parenttype,
 			topid, toptype, msg);
   if (msg is not null) then
      out_message := msg;
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

	if (lptype not in ('PA', 'MP')) then
		out_message := 'Not inbound LP';
		return;
	end if;

   open c_lp(in_lpid);
   fetch c_lp into lp;
   close c_lp;

	if (lp.location = in_user) then
		out_message := 'Already wanded';
		return;
	end if;

	if (lp.status != 'I') then
		out_message := 'Not in-transit';
		return;
	end if;

	if (lp.parentlpid is not null) then
		out_message := 'Use parent LP';
		return;
	end if;

-- We only need to look at (any)one shippingplate bound to the tree
  	open c_sp(in_lpid);
  	fetch c_sp into sp;
  	close c_sp;

	if (sp.loadno != in_loadno) then
		out_message := 'Not for load';
		return;
	end if;

	for t in c_lptree(in_lpid) loop

		open c_itemview(t.custid, t.item);
	   fetch c_itemview into itv;
   	close c_itemview;

		if (t.invstatus = 'DM') then
	      l_qtyrcvdgood := 0;
	      l_qtyrcvddmgd := t.quantity;
	      l_weightrcvdgood := 0;
	      l_weightrcvddmgd := t.quantity * t.weight;
	      l_cubercvdgood := 0;
	      l_cubercvddmgd := t.quantity * t.cube;
	      l_amtrcvdgood := 0;
	      l_amtrcvddmgd := t.quantity * zci.item_amt(t.custid, t.orderid, t.shipid, t.orderitem, t.orderlot);
      else
	      l_qtyrcvdgood := t.quantity;
	      l_qtyrcvddmgd := 0;
	      l_weightrcvdgood := t.quantity * t.weight;
	      l_weightrcvddmgd := 0;
	      l_cubercvdgood := t.quantity * t.cube;
	      l_cubercvddmgd := 0;
	      l_amtrcvdgood := t.quantity * zci.item_amt(t.custid, t.orderid, t.shipid, t.orderitem, t.orderlot);
	      l_amtrcvddmgd := 0;
      end if;

      zrec.update_receipt_dtl
         (t.orderid, t.shipid, t.orderitem, t.orderlot, t.unitofmeasure,
          t.itementered, t.uomentered,
          t.quantity, l_qtyrcvdgood, l_qtyrcvddmgd,
          t.quantity * t.weight, l_weightrcvdgood, l_weightrcvddmgd,
          t.quantity * t.cube, l_cubercvdgood, l_cubercvddmgd,
          t.quantity * zci.item_amt(t.custid, t.orderid, t.shipid, t.orderitem, t.orderlot), l_amtrcvdgood, l_amtrcvddmgd,
          in_user, 'Automatically created by transfer order', msg);

      if msg != 'OKAY' then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;

      update loadstopship
		   set qtyrcvd = nvl(qtyrcvd, 0) + t.quantity,
		       weightrcvd = nvl(weightrcvd, 0) + (t.quantity * t.weight),
		       weightrcvd_kgs = nvl(weightrcvd_kgs, 0)
                          + nvl(zwt.from_lbs_to_kgs(t.custid,(t.quantity * t.weight)),0),
		       cubercvd = nvl(cubercvd, 0) + (t.quantity * t.cube),
		       amtrcvd = nvl(amtrcvd, 0) + (t.quantity * zci.item_amt(t.custid, t.orderid, t.shipid, t.orderitem, t.orderlot)),
             lastuser = in_user,
             lastupdate = sysdate
         where loadno = in_loadno
           and stopno = t.stopno
           and shipno = t.shipno;

	   update plate
		   set location = in_user,
		       status = 'U',
			    disposition = 'PUT',
        	    lastoperator = in_user,
        	    lastuser = in_user,
        	    lastupdate = sysdate,
             orderid = t.orderid,
             shipid = t.shipid,
             qtyrcvd = quantity
		   where lpid = t.lpid;

      zcwt.add_item_lot_catch_weight(t.facility, t.custid, t.item, t.lotnumber,
            t.quantity * t.weight, msg);
      if msg != 'OKAY' then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;

		insert into orderdtlrcpt
   		(orderid, shipid, orderitem, orderlot,
			 facility, custid, item, lotnumber,
			 uom, inventoryclass, invstatus, lpid,
			 qtyrcvd, lastuser, lastupdate, qtyrcvdgood, qtyrcvddmgd,
          serialnumber, useritem1, useritem2, useritem3, weight)
		select t.orderid, t.shipid, t.orderitem, t.orderlot,
		       P.facility, P.custid, P.item, P.lotnumber,
				 P.unitofmeasure, P.inventoryclass, P.invstatus, t.lpid,
			    P.quantity, in_user, sysdate, l_qtyrcvdgood, l_qtyrcvddmgd,
             P.serialnumber, P.useritem1, P.useritem2, P.useritem3, P.weight
    		from plate P
    		where lpid = t.lpid;

	end loop;

	update plate
		set location = in_user,
		    status = 'U',
			 disposition = 'PUT',
        	 lastoperator = in_user,
        	 lastuser = in_user,
        	 lastupdate = sysdate
		where lpid = in_lpid
        and type != 'PA';

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end receive_lp;


end rfxferorder;
/

show errors package body rfxferorder;
exit;
