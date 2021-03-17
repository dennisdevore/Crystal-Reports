create or replace package body alps.zrecorder as
--
-- $Id$
--


-- Private procedures


procedure build_load
	(in_receiptdate  in  date,
    in_trailer		  in  varchar2,
    in_seal		     in  varchar2,
	 in_facility     in  varchar2,
    in_doorloc		  in  varchar2,
    in_carrier		  in  varchar2,
    in_billoflading in  varchar2,
    in_user         in  varchar2,
    io_loadno		  in out number,
    out_errmsg      out varchar2)
is
   l_msg varchar2(255);
begin
	out_errmsg := 'OKAY';

	zld.get_next_loadno(io_loadno, l_msg);
	if l_msg != 'OKAY' then
     	out_errmsg := 'No next loadno: ' || l_msg;
      return;
  	end if;

	insert into loads
		(loadno, entrydate, rcvddate, loadstatus, trailer,
   	 seal, facility, doorloc, carrier,
   	 statususer, statusupdate, lastuser, lastupdate, billoflading,
   	 loadtype)
	values
     	(io_loadno, sysdate, nvl(in_receiptdate, sysdate), 'A', in_trailer,
       in_seal, in_facility, in_doorloc, in_carrier,
       in_user, sysdate, in_user, sysdate, in_billoflading,
       'INC');

	insert into loadstop
		(loadno, stopno, entrydate, loadstopstatus,
   	 statususer, statusupdate, lastuser, lastupdate, facility)
	values
     	(io_loadno, 1, sysdate, 'A',
		 in_user, sysdate, in_user, sysdate, in_facility);

	insert into loadstopship
		(loadno, stopno, shipno, entrydate,
       qtyorder, weightorder, cubeorder, amtorder,
   	 qtyship, weightship, cubeship, amtship,
   	 qtyrcvd, weightrcvd, cubercvd, amtrcvd,
   	 lastuser, lastupdate, weight_entered_lbs, weight_entered_kgs)
	values
     	(io_loadno, 1, 1, sysdate,
       0, 0, 0, 0,
       0, 0, 0, 0,
       0, 0, 0, 0,
		 in_user, sysdate, 0, 0);

exception when others then
  out_errmsg := sqlerrm;

end build_load;


-- Public procedures


procedure receive_item
	 (in_facility     in  varchar2,
    in_orderid      in  number,
    in_shipid       in  number,
    in_custid       in  varchar2,
    in_po		        in  varchar2,
    in_reference    in  varchar2,
    in_billoflading in  varchar2,
    in_shipper	    in  varchar2,
    in_carrier		  in  varchar2,
    in_trailer		  in  varchar2,
    in_seal		      in  varchar2,
    in_doorloc		  in  varchar2,
    in_receiptdate  in  date,
    in_itementered  in  varchar2,
    in_item         in  varchar2,
    in_lot          in  varchar2,
    in_qty          in  number,
    in_uom          in  varchar2,
    in_location     in  varchar2,
    in_invstatus    in  varchar2,
    in_invclass     in  varchar2,
    in_handtype     in  varchar2,
    in_serial       in  varchar2,
    in_useritem1    in  varchar2,
    in_useritem2    in  varchar2,
    in_useritem3    in  varchar2,
    in_countryof    in  varchar2,
    in_expdate      in  date,
    in_mfgdate      in  date,
    in_user         in  varchar2,
    in_weight       in  number,
    in_nosetemp     in  number,
    in_middletemp   in  number,
    in_tailtemp     in  number,
    out_orderid     out number,
    out_loadno      out number,
    out_errmsg      out varchar2)
is
	cursor c_oh(p_orderid number, p_shipid number) is
   	select O.orderid, O.shipid, O.loadno, O.stopno, O.shipno, O.priority,
      		 L.doorloc, L.carrier, L.loadstatus, O.orderstatus
      	from orderhdr O, loads L
         where O.orderid = p_orderid
           and O.shipid = p_shipid
           and L.loadno (+) = O.loadno;
	oh c_oh%rowtype;

   cursor c_itv(p_custid varchar2, p_item varchar2) is
      select baseuom, shelflife, expiryaction, use_catch_weights, catch_weight_in_cap_type,
             min_sale_life
         from custitemview
         where custid = p_custid
           and item = p_item;
   itv c_itv%rowtype;

	l_qtyrcvd orderdtl.qtyrcvd%type;
	l_qtyrcvdgood orderdtl.qtyrcvd%type;
	l_qtyrcvddmgd orderdtl.qtyrcvd%type;
	l_weightrcvd orderdtl.weightrcvd%type;
	l_weightrcvdgood orderdtl.weightrcvd%type;
	l_weightrcvddmgd orderdtl.weightrcvd%type;
	l_cubercvd orderdtl.cubercvd%type;
	l_cubercvdgood orderdtl.cubercvd%type;
	l_cubercvddmgd orderdtl.cubercvd%type;
	l_amtrcvd orderdtl.amtrcvd%type;
	l_amtrcvdgood orderdtl.amtrcvd%type;
	l_amtrcvddmgd orderdtl.amtrcvd%type;
   l_lpid plate.lpid%type;
  l_tracktrailertemps varchar2(1);
  l_nosetemp orderhdr.trailernosetemp%type;
  l_middletemp orderhdr.trailermiddletemp%type;
  l_tailtemp orderhdr.trailertailtemp%type;
   l_found boolean;
   l_msg varchar2(255);


CURSOR C_CAUX(in_custid varchar2)
IS
    SELECT verify_sale_life_yn
      FROM customer_aux
     WHERE custid = in_custid;

CAUX C_CAUX%rowtype;

l_invstatus plate.invstatus%type;


begin
	out_errmsg := 'OKAY';

-- Get customer info
    CAUX := null;
    OPEN C_CAUX(in_custid);
    FETCH C_CAUX into CAUX;
    CLOSE C_CAUX;

	select nvl(tracktrailertemps,'N')
	  into l_tracktrailertemps
	  from customer
	 where custid = in_custid;

	l_nosetemp := null;
	l_middletemp := null;
	l_tailtemp := null;

	if l_tracktrailertemps = 'Y' then
		l_nosetemp := in_nosetemp;
		l_middletemp := in_middletemp;
		l_tailtemp := in_tailtemp;
	end if;

	oh.loadno := 0;
	if in_orderid = 0 then

   	-- need load and order

		build_load(in_receiptdate, in_trailer, in_seal, in_facility, in_doorloc,
    			in_carrier, in_billoflading, in_user, oh.loadno, l_msg);
  		if l_msg != 'OKAY' then
      	out_errmsg := 'Unable to build load: ' || l_msg;
         return;
     	end if;
      oh.stopno := 1;
      oh.shipno := 1;

  		zoe.get_next_orderid(oh.orderid, l_msg);
  		if l_msg != 'OKAY' then
      	out_errmsg := 'No next orderid: ' || l_msg;
         return;
     	end if;
      oh.shipid := 1;
      oh.priority := 'A';

      insert into orderhdr
      	   (orderid, shipid, custid, ordertype, entrydate, po,
             orderstatus, commitstatus, tofacility, loadno, stopno, shipno,
             statususer, statusupdate, lastuser, lastupdate, billoflading,
             priority, shipper, carrier, reference, saturdaydelivery,
             cod, rfautodisplay, source, companycheckok,
             trailernosetemp, trailermiddletemp, trailertailtemp)
    	   values
      	   (oh.orderid, oh.shipid, in_custid, 'R', in_receiptdate, in_po,
            'A', '0', in_facility, oh.loadno, oh.stopno, oh.shipno,
             in_user, sysdate, in_user, sysdate, in_billoflading,
             oh.priority, in_shipper, in_carrier, in_reference, 'N',
             'N', 'N', 'CRT', 'N',
             l_nosetemp, l_middletemp, l_tailtemp);
	else
      open c_oh(in_orderid, in_shipid);
      fetch c_oh into oh;
   	l_found := c_oh%found;
      close c_oh;

      if not l_found then
      	out_errmsg := 'Order ' || in_orderid || '-' || in_shipid || ' not found.';
         return;
     	end if;

      -- PRN 25488 - check the status of the order, as you shouldn't be able to receive items against a closed order
      if (oh.orderstatus = 'R')
      then
        out_errmsg := 'Order ' || in_orderid || '-' || in_shipid || ' has been closed (in status R).';
        return;
      end if;

		-- order exists

      if nvl(oh.loadno, 0) = 0 then

			-- need load

		   build_load(in_receiptdate, in_trailer, in_seal, in_facility, in_doorloc,
    			   in_carrier, in_billoflading, in_user, oh.loadno, l_msg);
  		   if l_msg != 'OKAY' then
      	   out_errmsg := 'Unable to build load: ' || l_msg;
            return;
     	   end if;
         oh.stopno := 1;
         oh.shipno := 1;
		elsif nvl(oh.doorloc, '(none)') != in_doorloc
      or nvl(oh.carrier, '(none)') != in_carrier
      or oh.loadstatus != 'A' then

			-- need to update load

			update loadstop
            set loadstopstatus = 'A'
            where loadno = oh.loadno
              and stopno = oh.stopno
              and loadstopstatus != 'A';
         update loads
            set doorloc = in_doorloc,
                carrier = in_carrier,
                loadstatus = 'A',
                rcvddate = nvl(in_receiptdate, sysdate)
				where loadno = oh.loadno;
		end if;

		-- insure orderhdr is ok

      update orderhdr
      	set orderstatus = 'A',
             loadno = oh.loadno,
             stopno = oh.stopno,
             shipno = oh.shipno,
             carrier = nvl(in_carrier, carrier),
             po = nvl(in_po, po),
             billoflading = nvl(in_billoflading, billoflading),
             reference = nvl(in_reference, reference),
             shipper = nvl(in_shipper, shipper),
             trailernosetemp = l_nosetemp,
             trailermiddletemp = l_middletemp,
             trailertailtemp = l_tailtemp
         where orderid = in_orderid
           and shipid = in_shipid
           and (orderstatus = 'O'
             or nvl(loadno, 0) != oh.loadno
             or nvl(stopno, 0) != oh.stopno
             or nvl(shipno, 0) != oh.shipno
             or (in_carrier is not null and nvl(carrier, '<?>') != in_carrier)
             or (in_po is not null and nvl(po, '<?>') != in_po)
             or (in_billoflading is not null and nvl(billoflading, '<?>') != in_billoflading)
             or (in_reference is not null and nvl(reference, '<?>') != in_reference)
             or (in_shipper is not null and nvl(shipper, '<?>') != in_shipper));

	end if;

   open c_itv(in_custid, in_item);
   fetch c_itv into itv;
   close c_itv;

   zbut.translate_uom(in_custid, in_item, in_qty, in_uom, itv.baseuom, l_qtyrcvd, l_msg);
   if l_msg != 'OKAY' then
      out_errmsg := 'No uom conversion from ' || in_uom || ' to ' || itv.baseuom;
      return;
   end if;

	l_weightrcvd := in_weight;
   if nvl(itv.use_catch_weights,'N') = 'Y' then
      if nvl(itv.catch_weight_in_cap_type,'G') = 'N' then
         l_weightrcvd := l_weightrcvd + zci.item_tareweight(in_custid, in_item, itv.baseuom)
               * l_qtyrcvd;
      end if;
		zcwt.set_item_catch_weight(in_custid, in_item, oh.orderid, oh.shipid,
    			in_qty, in_uom, l_weightrcvd, in_user, l_msg);
	   if l_msg != 'OKAY' then
   	   out_errmsg := 'Error setting catch weight: ' || l_msg;
      	return;
   	end if;
		zcwt.add_item_lot_catch_weight(in_facility, in_custid, in_item, in_lot,
    			l_weightrcvd, l_msg);
	   if l_msg != 'OKAY' then
   	   out_errmsg := 'Error adding catch weight: ' || l_msg;
      	return;
   	end if;
	end if;

  	l_cubercvd := zci.item_cube(in_custid, in_item, itv.baseuom) * l_qtyrcvd;
  	l_amtrcvd := zci.item_amt(in_custid, in_orderid, in_shipid, in_item, in_lot) * l_qtyrcvd; --prn 25133

   if in_invstatus = 'DM' then
	   l_qtyrcvdgood := 0;
	   l_qtyrcvddmgd := l_qtyrcvd;
	   l_weightrcvdgood := 0;
	   l_weightrcvddmgd := l_weightrcvd;
	   l_cubercvdgood := 0;
	   l_cubercvddmgd := l_cubercvd;
	   l_amtrcvdgood := 0;
	   l_amtrcvddmgd := l_amtrcvd;
   else
	   l_qtyrcvdgood := l_qtyrcvd;
	   l_qtyrcvddmgd := 0;
	   l_weightrcvdgood := l_weightrcvd;
	   l_weightrcvddmgd := 0;
	   l_cubercvdgood := l_cubercvd;
	   l_cubercvddmgd := 0;
	   l_amtrcvdgood := l_amtrcvd;
	   l_amtrcvddmgd := 0;
   end if;

-- Verify expiration shelflife
    l_invstatus := null;
    if CAUX.verify_sale_life_yn = 'Y' and in_invstatus = 'AV'
      and nvl(itv.min_sale_life,0) > 0 then
        if in_expdate is not null then
            if in_expdate < trunc(sysdate) + itv.min_sale_life then
                l_invstatus := 'VC';
            end if;
        end if;
    end if;



   zrec.update_receipt_dtl
      (oh.orderid, oh.shipid, in_item, in_lot, itv.baseuom, in_itementered, in_uom,
       l_qtyrcvd, l_qtyrcvdgood, l_qtyrcvddmgd,
       l_weightrcvd, l_weightrcvdgood, l_weightrcvddmgd,
       l_cubercvd, l_cubercvdgood, l_cubercvddmgd,
       l_amtrcvd, l_amtrcvdgood, l_amtrcvddmgd,
       in_user, null, l_msg);

   if l_msg != 'OKAY' then
      out_errmsg := 'Error updating receipt details: ' || l_msg;
      return;
   end if;

   update loadstopship
		set qtyrcvd = nvl(qtyrcvd, 0) + l_qtyrcvd,
		    weightrcvd = nvl(weightrcvd, 0) + l_weightrcvd,
		    weightrcvd_kgs = nvl(weightrcvd_kgs, 0)
                       + nvl(zwt.from_lbs_to_kgs(in_custid,l_weightrcvd),0),
		    cubercvd = nvl(cubercvd, 0) + l_cubercvd,
		    amtrcvd = nvl(amtrcvd, 0) + l_amtrcvd,
          lastuser = in_user,
          lastupdate = sysdate
      where loadno = oh.loadno
        and stopno = oh.stopno
        and shipno = oh.shipno;

   zrf.get_next_lpid(l_lpid, l_msg);
   if l_msg is not null then
 		out_errmsg := 'No next lpid: ' || l_msg;
      return;
   end if;

   insert into plate
  			(lpid, item, custid, facility, location,
          status, unitofmeasure, quantity, type, serialnumber,
          lotnumber, creationdate, manufacturedate,
          expirationdate,
          expiryaction, po, recmethod, lastoperator, countryof,
          useritem1, useritem2, useritem3, lastuser, lastupdate,
          invstatus, qtyentered, itementered, uomentered, inventoryclass,
          loadno, stopno, shipno, orderid, shipid,
          weight, qtyrcvd, parentfacility, parentitem)
   	values
      	(l_lpid, in_item, in_custid, in_facility, in_location,
          'A', itv.baseuom, l_qtyrcvd, 'PA', in_serial,
          in_lot, in_receiptdate, in_mfgdate,
          zrf.calc_expiration(to_char(in_expdate, 'MM/DD/RRRR'),
          		to_char(in_mfgdate, 'MM/DD/RRRR'), itv.shelflife),
			 itv.expiryaction, in_po, in_handtype, in_user, in_countryof,
          in_useritem1, in_useritem2, in_useritem3, in_user, sysdate,
          nvl(l_invstatus, in_invstatus), in_qty, in_itementered, in_uom, in_invclass,
          oh.loadno, oh.stopno, oh.shipno, oh.orderid, oh.shipid,
          l_weightrcvd, l_qtyrcvd, in_facility, in_item);

	insert into orderdtlrcpt
   	   (orderid, shipid, orderitem, orderlot, facility,
          custid, item, lotnumber, uom, inventoryclass,
          invstatus, lpid, qtyrcvd, lastuser, lastupdate,
          qtyrcvdgood, qtyrcvddmgd,
          serialnumber, useritem1, useritem2, useritem3, weight)
		values
      	(oh.orderid, oh.shipid, in_item, in_lot, in_facility,
          in_custid, in_item, in_lot, itv.baseuom, in_invclass,
          nvl(l_invstatus, in_invstatus), l_lpid, l_qtyrcvd, in_user, sysdate,
          decode(in_invstatus, 'DM', 0, l_qtyrcvd), decode(in_invstatus, 'DM', l_qtyrcvd, 0),
          in_serial, in_useritem1, in_useritem2, in_useritem3, l_weightrcvd);

	out_orderid := oh.orderid;
   out_loadno := oh.loadno;

exception when others then
  out_errmsg := sqlerrm;

end receive_item;


procedure close_receipt
	(in_facility in  varchar2,
    in_loadno   in  number,
    in_user     in  varchar2,
    in_receiptdate  in  date,
    out_errmsg  out varchar2)
is
   l_msg varchar2(255);
begin
	out_errmsg := 'OKAY';

	update loads
   	set loadstatus = 'E',
   	    rcvddate = nvl(rcvddate, nvl(in_receiptdate, sysdate)),
          lastuser = in_user,
          lastupdate = sysdate
    	where loadno = in_loadno;

	zld.close_inbound_load(in_loadno, in_facility, in_user, l_msg);
   out_errmsg := l_msg;

exception when others then
  out_errmsg := sqlerrm;

end close_receipt;


end zrecorder;
/

show errors package body zrecorder;
exit;
