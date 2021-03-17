create or replace package body alps.rfrestaging as
--
-- $Id$
--


-- Public procedures


procedure adjust_orderdtlline
   (in_custid    in varchar2,
    in_orderid   in number,
    in_shipid    in number,
    in_orderitem in varchar2,
    in_orderlot  in varchar2,
    in_qty       in number,
    in_newshipid in number,
    in_user      in varchar2,
    out_message  out varchar2)
is
   cursor c_cus(p_custid varchar2) is
      select nvl(linenumbersyn, 'N') linenumbersyn
         from customer
         where custid = p_custid;
   cus c_cus%rowtype := null;
   cursor c_odl(p_orderid number, p_shipid number, p_orderitem varchar2,
         p_orderlot varchar2) is
      select orderdtlline.*, rowid
         from orderdtlline
         where orderid = p_orderid
           and shipid = p_shipid
           and item = p_orderitem
           and nvl(lotnumber,'(none)') = nvl(p_orderlot,'(none)')
           and nvl(xdock,'N') = 'N'
      order by linenumber;
   odl c_odl%rowtype;
   l_remaining number := in_qty;
   l_qty number;
   l_msg varchar2(255);
begin
   out_message := null;

   open c_cus(in_custid);
   fetch c_cus into cus;
   close c_cus;
   if cus.linenumbersyn = 'Y' then
      open c_odl(in_orderid, in_shipid, in_orderitem, in_orderlot);
      loop
         fetch c_odl into odl;
         exit when c_odl%notfound;

         l_qty := least(l_remaining, odl.qty);
         update orderdtlline
            set qty = qty + l_qty
            where orderid = in_orderid
              and shipid = in_newshipid
              and item = in_orderitem
              and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)')
              and linenumber = odl.linenumber;

         if sql%rowcount = 0 then
            zcl.clone_table_row('ORDERDTLLINE',
                  'ORDERID = '|| in_orderid ||' and SHIPID = '||in_shipid
                     ||' and ITEM = '''||in_orderitem||''''
                     ||' and nvl(LOTNUMBER,''(none)'') = '''
                     ||nvl(in_orderlot,'(none)')||''''
                     ||' and LINENUMBER = '|| odl.linenumber,
                  in_newshipid||','||l_remaining, 'SHIPID,QTY', null, in_user, l_msg);

            if l_msg != 'OKAY' then
               out_message := l_msg;
            end if;
         end if;

         if l_qty = odl.qty then
            delete orderdtlline
               where rowid = odl.rowid;
         else
            update orderdtlline
               set qty = qty - l_qty
               where rowid = odl.rowid;
         end if;
         l_remaining := l_remaining - l_qty;
         exit when (l_remaining = 0);
      end loop;
      close c_odl;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end adjust_orderdtlline;


procedure wand_lp_for_restage
   (in_lpid      in varchar2,
    in_facility  in varchar2,
    in_user      in varchar2,
    in_equipment in varchar2,
    out_custid   out varchar2,
    out_location out varchar2,
    out_orderid  out number,
    out_shipid   out number,
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
      select facility, location, status, rowid, custid, orderid, shipid
         from shippingplate
         where lpid = p_slp;
   cursor c_mlp(p_mlp varchar2) is
      select facility, location, status, rowid, custid, orderid, shipid
         from shippingplate
         where fromlpid = p_mlp
           and facility = in_facility;
   cursor c_anykid(p_mlp varchar2) is
      select facility, location, status, rowid, custid, orderid, shipid
         from shippingplate
         where facility = in_facility
           and fromlpid in (select lpid from plate
                              start with lpid = p_mlp
                              connect by prior lpid = parentlpid);
   sp c_slp%rowtype;
   spfound boolean;
   sts location.status%type;
   typ location.loctype%type;
   ckid location.checkdigit%type;
   err varchar2(1);
   rlpid plate.lpid%type := in_lpid;
   cordid waves.wave%type;
begin
   out_error := 'N';
   out_message := null;

   zrf.identify_lp(rlpid, lptype, xrefid, xreftype, parentid, parenttype,
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

   if ((parentid is not null) or (topid is not null)) then
      out_message := 'Use parent';
      return;
   end if;

   lptype := nvl(xreftype, lptype);
   rlpid := nvl(xrefid, rlpid);

   if (zrf.is_plate_passed(rlpid, lptype) != 0) then
      out_message := 'Resume pending';
      return;
   end if;

   if (lptype = 'MP') then
      open c_mlp(rlpid);
      fetch c_mlp into sp;
      spfound := c_mlp%found;
      close c_mlp;
      if not spfound then
         open c_anykid(rlpid);
         fetch c_anykid into sp;
         spfound := c_anykid%found;
         close c_anykid;
      end if;
   elsif (lptype not in ('C', 'F', 'M')) then
      out_message := 'Not outbound';
      return;
   else
      open c_slp(rlpid);
      fetch c_slp into sp;
      spfound := c_slp%found;
      close c_slp;
   end if;

   if not spfound then
      out_message := 'Not outbound';
      return;
   end if;

   if (sp.status != 'S') then
      out_message := 'Not staged';
      return;
   end if;

   if (sp.facility != in_facility) then
      out_message := 'Not your facility';
      return;
   end if;

   if (sp.location = in_user) then
      out_message := 'Already wanded';
      return;
   end if;

   zrf.verify_location(in_facility, sp.location, in_equipment, sts, typ, ckid, err, msg);
   if (msg is not null) then
      out_error := err;
      out_message := msg;
      return;
   end if;

   cordid := zcord.cons_orderid(sp.orderid, sp.shipid);
   if cordid != 0 then
      if cordid = sp.orderid then
         out_message := 'Cons order invalid';
      else
         out_message := 'Cons subordr invalid';
      end if;
      return;
   end if;

   if (lptype = 'MP') then
--    update all shippingplates
      update shippingplate
         set location = in_user,
             prevlocation = location,
             lastuser = in_user,
             lastupdate = sysdate
            where fromlpid in (select lpid from plate
                           start with lpid = rlpid
                           connect by prior lpid = parentlpid)
              and facility = in_facility
              and status = 'S';
--    update all plates
      update plate
         set location = in_user,
             prevlocation = location,
             lastoperator = in_user,
             lastuser = in_user,
             lastupdate = sysdate,
             lasttask = 'RS'
         where lpid in (select lpid from plate
                           start with lpid = rlpid
                           connect by prior lpid = parentlpid);
   else
--    update the shippingplate
      zrf.move_shippingplate(sp.rowid, in_user, 'S', in_user, 'RS', msg);
      if (msg is not null) then
         out_error := 'Y';
         out_message := msg;
         return;
      end if;
   end if;

   out_custid := sp.custid;
   out_location := sp.location;
   out_orderid := sp.orderid;
   out_shipid := sp.shipid;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end wand_lp_for_restage;


procedure verify_newshipid
   (in_orderid   in number,
    in_shipid    in number,
    in_newshipid in number,
    out_loadno   out number,
    out_message  out varchar2)
is
   cursor c_oh is
      select orderstatus, loadno
         from orderhdr
         where orderid = in_orderid
           and shipid = in_newshipid;
   oh c_oh%rowtype;
   ohfound boolean;
   maxshipid orderhdr.shipid%type;
begin
   out_message := null;
   out_loadno := 0;

   open c_oh;
   fetch c_oh into oh;
   ohfound := c_oh%found;
   close c_oh;

   if ohfound then
      out_loadno := oh.loadno;
      if (oh.orderstatus = 'X') then
         out_message := 'Order cancelled';
      elsif (oh.orderstatus < zrf.ORD_PICKED) then
         out_message := 'Order not picked';
      elsif (oh.orderstatus > zrf.ORD_LOADED) then
         out_message := 'Order shipped';
      end if;
      return;
   end if;

   select max(shipid)+1
      into maxshipid
      from orderhdr
      where orderid = in_orderid;

   if (maxshipid != in_newshipid) then
      out_message := 'Not next ShipID';
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end verify_newshipid;


procedure restage_shipid
   (in_facility  in varchar2,
    in_location  in varchar2,
    in_user      in varchar2,
    in_orderid   in number,
    in_shipid    in number,
    in_newshipid in number,
    out_error    out varchar2,
    out_message  out varchar2)
is
   cursor c_slp is
      select rowid, type, fromlpid, orderitem, orderlot, quantity,
             (zci.item_cube(custid, orderitem, pickuom) * pickqty) pickcube,
             (zci.item_cube(custid, orderitem, uomentered) * quantity) ordercube,
             (zci.item_amt(custid, orderid, shipid, orderitem, orderlot) * quantity) amt, --prn 25133
             weight, unitofmeasure
         from shippingplate
         where facility = in_facility
           and location = in_user
           and status = 'S'
           and orderid = in_orderid
           and shipid = in_shipid
         order by decode(type, 'C', 1, 'M', 1, 2);
   cursor c_od (p_orderid number, p_shipid number, p_item varchar2, P_lotnumber varchar2) is
      select *
         from orderdtl
         where orderid = p_orderid
           and shipid = p_shipid
           and item = p_item
           and nvl(lotnumber,'(none)') = nvl(p_lotnumber,'(none)');
   ood c_od%rowtype;
   nod c_od%rowtype;
   nodfound boolean;
   cursor c_oh (p_orderid number, p_shipid number) is
      select *
         from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   noh c_oh%rowtype;
   ooh c_oh%rowtype;
   nohfound boolean;
   cursor c_ld (p_loadno number) is
      select nvl(loadstatus,'?') as loadstatus
         from loads
         where loadno = p_loadno;
   ld c_ld%rowtype;
   msg varchar2(80);
   errorno integer;
   xlatqty number(12,4);
   newloadstopstatus loadstop.loadstopstatus%type;
   newloadstatus loads.loadstatus%type;
   palpid plate.parentlpid%type;
   l_key number := 0;
begin
   out_error := 'N';
   out_message := null;

   zrf.so_lock(l_key);
   open c_oh(in_orderid, in_newshipid);
   fetch c_oh into noh;
   nohfound := c_oh%found;
   close c_oh;

-- recheck order status if it exists
   if nohfound then
      if (noh.orderstatus = 'X') then
         out_message := 'Order cancelled';
         rollback;
         return;
      elsif (noh.orderstatus < zrf.ORD_PICKED) then
         out_message := 'Order not picked';
         rollback;
         return;
      elsif (noh.orderstatus > zrf.ORD_LOADED) then
         out_message := 'Order shipped';
         rollback;
         return;
      end if;

--    we could be restaging back to an existing loaded order/load

      if (noh.orderstatus = zrf.ORD_LOADED) then
         update orderhdr
            set orderstatus = zrf.ORD_LOADING,
                lastuser = in_user,
                lastupdate = sysdate
            where orderid = in_orderid
              and shipid = in_newshipid;

         if (nvl(noh.loadno, 0) != 0) then
            select min(orderstatus) into newloadstopstatus
               from orderhdr
               where loadno = noh.loadno
                 and stopno = noh.stopno;
            update loadstop
               set loadstopstatus = newloadstopstatus,
                   lastuser = in_user,
                   lastupdate = sysdate
               where loadno = noh.loadno
                 and stopno = noh.stopno
                 and loadstopstatus != newloadstopstatus;

            select min(loadstopstatus) into newloadstatus
               from loadstop
               where loadno = noh.loadno;
            update loads
               set loadstatus = newloadstatus,
                   lastuser = in_user,
                   lastupdate = sysdate
               where loadno = noh.loadno
                 and loadstatus != newloadstatus;
         end if;
      end if;
   else
--    create new order
      noh := null;

      open c_oh(in_orderid, in_shipid);
      fetch c_oh into ooh;
      close c_oh;
      insert into orderhdr
         (orderid, shipid, custid, ordertype, entrydate,
          apptdate, shipdate, po, rma, orderstatus,
          commitstatus, fromfacility, tofacility, loadno, stopno,
          shipno, shipto, delarea, qtyorder, weightorder,
          cubeorder, amtorder, qtycommit, weightcommit, cubecommit,
          amtcommit, qtyship, weightship, cubeship, amtship,
          qtytotcommit, weighttotcommit, cubetotcommit, amttotcommit, qtyrcvd,
          weightrcvd, cubercvd, amtrcvd, comment1, statususer,
          statusupdate, lastuser, lastupdate, billoflading, priority,
          shipper, arrivaldate, consignee, shiptype, carrier,
          reference, shipterms, wave, stageloc, qtypick,
          weightpick, cubepick, amtpick, shiptoname, shiptocontact,
          shiptoaddr1, shiptoaddr2, shiptocity, shiptostate, shiptopostalcode,
          shiptocountrycode, shiptophone, shiptofax, shiptoemail, billtoname,
          billtocontact, billtoaddr1, billtoaddr2, billtocity, billtostate,
          billtopostalcode, billtocountrycode, billtophone, billtofax, billtoemail,
          parentorderid, parentshipid, parentorderitem, parentorderlot, workorderseq,
          staffhrs, qty2sort, weight2sort, cube2sort, amt2sort,
          qty2pack, weight2pack, cube2pack, amt2pack, qty2check,
          weight2check, cube2check, amt2check, importfileid, hdrpassthruchar01,
          hdrpassthruchar02, hdrpassthruchar03, hdrpassthruchar04, hdrpassthruchar05,
          hdrpassthruchar06, hdrpassthruchar07, hdrpassthruchar08, hdrpassthruchar09,
          hdrpassthruchar10, hdrpassthruchar11, hdrpassthruchar12, hdrpassthruchar13,
          hdrpassthruchar14, hdrpassthruchar15, hdrpassthruchar16, hdrpassthruchar17,
          hdrpassthruchar18, hdrpassthruchar19, hdrpassthruchar20, hdrpassthrunum01,
          hdrpassthrunum02, hdrpassthrunum03, hdrpassthrunum04, hdrpassthrunum05,
          hdrpassthrunum06, hdrpassthrunum07, hdrpassthrunum08, hdrpassthrunum09,
          hdrpassthrunum10, confirmed, rejectcode, rejecttext, dateshipped,
          origorderid, origshipid, bulkretorderid, bulkretshipid, returntrackingno,
          packlistshipdate, edicancelpending, deliveryservice, saturdaydelivery, specialservice1,
          specialservice2, specialservice3, specialservice4, cod, amtcod,
          asnvariance, backorderyn, cancelreason, rfautodisplay, source,
          transapptdate, deliveryaptconfname, interlinecarrier, companycheckok,
          ftz216authorization, shippername, shippercontact, shipperaddr1,
          shipperaddr2, shippercity, shipperstate, shipperpostalcode,
          shippercountrycode, shipperphone, shipperfax, shipperemail,
          cancel_id, cancelled_date, cancel_user_id, prono, componenttemplate,
          hdrpassthrudate01, hdrpassthrudate02, hdrpassthrudate03,
          hdrpassthrudate04, hdrpassthrudoll01, hdrpassthrudoll02,
          ignore_multiship, xdockorderid, xdockshipid, has_consumables,
          hdrpassthruchar21, hdrpassthruchar22, hdrpassthruchar23,
          hdrpassthruchar24, hdrpassthruchar25, hdrpassthruchar26,
          hdrpassthruchar27, hdrpassthruchar28, hdrpassthruchar29,
          hdrpassthruchar30, hdrpassthruchar31, hdrpassthruchar32,
          hdrpassthruchar33, hdrpassthruchar34, hdrpassthruchar35,
          hdrpassthruchar36, hdrpassthruchar37, hdrpassthruchar38,
          hdrpassthruchar39, hdrpassthruchar40, seal_verification_attempts,
          seal_verified, trailernosetemp, trailermiddletemp,
          trailertailtemp, xfercustid, weight_entered_lbs,
          weight_entered_kgs, is_returns_order, cancel_after,
          delivery_requested, requested_ship, ship_not_before,
          ship_no_later, cancel_if_not_delivered_by, do_not_deliver_after,
          do_not_deliver_before, appointmentid, tms_status,
          tms_status_update, tms_shipment_id, tms_release_id,
          recent_order_id, shippingcost, xdockprocessing,
          estimated_cartons, estimated_package_cube,
          estimated_package_weight_lbs, estimated_weight_lbs,
          actual_cartons, actual_package_cube, actual_weight_lbs,
          ownerxferorderid, ownerxfershipid, hdrpassthruchar41,
          hdrpassthruchar42, hdrpassthruchar43, hdrpassthruchar44, hdrpassthruchar45,
          hdrpassthruchar46, hdrpassthruchar47, hdrpassthruchar48, hdrpassthruchar49,
          hdrpassthruchar50, hdrpassthruchar51, hdrpassthruchar52, hdrpassthruchar53,
          hdrpassthruchar54, hdrpassthruchar55, hdrpassthruchar56, hdrpassthruchar57,
          hdrpassthruchar58, hdrpassthruchar59, hdrpassthruchar60, editransaction,
          invoicenumber810, invoiceamount810, expanded_websynapse_fields,
          routingstatus, manual_picks_yn, restaged_yn)
      values
         (in_orderid, in_newshipid, ooh.custid, ooh.ordertype, ooh.entrydate,
          ooh.apptdate, ooh.shipdate, ooh.po, ooh.rma, zrf.ORD_PICKED,
          ooh.commitstatus, ooh.fromfacility, ooh.tofacility, null, null,
          null, ooh.shipto, ooh.delarea, null, null,
          null, null, null, null, null,
          null, null, null, null, null,
          ooh.qtytotcommit, ooh.weighttotcommit, ooh.cubetotcommit, ooh.amttotcommit, null,
          null, null, null, ooh.comment1, in_user,
          sysdate, in_user, sysdate, ooh.billoflading, ooh.priority,
          ooh.shipper, ooh.arrivaldate, ooh.consignee, ooh.shiptype, ooh.carrier,
          ooh.reference, ooh.shipterms, ooh.wave, ooh.stageloc, null,
          null, null, null, ooh.shiptoname, ooh.shiptocontact,
          ooh.shiptoaddr1, ooh.shiptoaddr2, ooh.shiptocity, ooh.shiptostate, ooh.shiptopostalcode,
          ooh.shiptocountrycode, ooh.shiptophone, ooh.shiptofax, ooh.shiptoemail, ooh.billtoname,
          ooh.billtocontact, ooh.billtoaddr1, ooh.billtoaddr2, ooh.billtocity, ooh.billtostate,
          ooh.billtopostalcode, ooh.billtocountrycode, ooh.billtophone, ooh.billtofax, ooh.billtoemail,
          ooh.parentorderid, ooh.parentshipid, ooh.parentorderitem, ooh.parentorderlot, ooh.workorderseq,
          null, null, null, null, null,
          null, null, null, null, null,
          null, null, null, ooh.importfileid, ooh.hdrpassthruchar01,
          ooh.hdrpassthruchar02, ooh.hdrpassthruchar03, ooh.hdrpassthruchar04, ooh.hdrpassthruchar05,
          ooh.hdrpassthruchar06, ooh.hdrpassthruchar07, ooh.hdrpassthruchar08, ooh.hdrpassthruchar09,
          ooh.hdrpassthruchar10, ooh.hdrpassthruchar11, ooh.hdrpassthruchar12, ooh.hdrpassthruchar13,
          ooh.hdrpassthruchar14, ooh.hdrpassthruchar15, ooh.hdrpassthruchar16, ooh.hdrpassthruchar17,
          ooh.hdrpassthruchar18, ooh.hdrpassthruchar19, ooh.hdrpassthruchar20, ooh.hdrpassthrunum01,
          ooh.hdrpassthrunum02, ooh.hdrpassthrunum03, ooh.hdrpassthrunum04, ooh.hdrpassthrunum05,
          ooh.hdrpassthrunum06, ooh.hdrpassthrunum07, ooh.hdrpassthrunum08, ooh.hdrpassthrunum09,
          ooh.hdrpassthrunum10, ooh.confirmed, ooh.rejectcode, ooh.rejecttext, ooh.dateshipped,
          ooh.origorderid, ooh.origshipid, ooh.bulkretorderid, ooh.bulkretshipid, ooh.returntrackingno,
          ooh.packlistshipdate, ooh.edicancelpending, ooh.deliveryservice, ooh.saturdaydelivery, ooh.specialservice1,
          ooh.specialservice2, ooh.specialservice3, ooh.specialservice4, ooh.cod, ooh.amtcod,
          ooh.asnvariance, ooh.backorderyn, ooh.cancelreason, ooh.rfautodisplay, ooh.source,
          ooh.transapptdate, ooh.deliveryaptconfname, ooh.interlinecarrier, ooh.companycheckok,
          ooh.ftz216authorization, ooh.shippername, ooh.shippercontact, ooh.shipperaddr1,
          ooh.shipperaddr2, ooh.shippercity, ooh.shipperstate, ooh.shipperpostalcode,
          ooh.shippercountrycode, ooh.shipperphone, ooh.shipperfax, ooh.shipperemail,
          ooh.cancel_id, ooh.cancelled_date, ooh.cancel_user_id,ooh.prono, ooh.componenttemplate,
          ooh.hdrpassthrudate01, ooh.hdrpassthrudate02, ooh.hdrpassthrudate03,
          ooh.hdrpassthrudate04, ooh.hdrpassthrudoll01, ooh.hdrpassthrudoll02,
          ooh.ignore_multiship, ooh.xdockorderid, ooh.xdockshipid, ooh.has_consumables,
          ooh.hdrpassthruchar21, ooh.hdrpassthruchar22, ooh.hdrpassthruchar23,
          ooh.hdrpassthruchar24, ooh.hdrpassthruchar25, ooh.hdrpassthruchar26,
          ooh.hdrpassthruchar27, ooh.hdrpassthruchar28, ooh.hdrpassthruchar29,
          ooh.hdrpassthruchar30, ooh.hdrpassthruchar31, ooh.hdrpassthruchar32,
          ooh.hdrpassthruchar33, ooh.hdrpassthruchar34, ooh.hdrpassthruchar35,
          ooh.hdrpassthruchar36, ooh.hdrpassthruchar37, ooh.hdrpassthruchar38,
          ooh.hdrpassthruchar39, ooh.hdrpassthruchar40, ooh.seal_verification_attempts,
          ooh.seal_verified, null, null,
          null, ooh.xfercustid, null,
          null, ooh.is_returns_order, ooh.cancel_after,
          ooh.delivery_requested, ooh.requested_ship, ooh.ship_not_before,
          ooh.ship_no_later, ooh.cancel_if_not_delivered_by, ooh.do_not_deliver_after,
          ooh.do_not_deliver_before, ooh.appointmentid,
          decode(ooh.tms_status, null, null, 'X', 'X', '1'), --ooh.tms_status,
          ooh.tms_status_update, ooh.tms_shipment_id, ooh.tms_release_id,
          ooh.recent_order_id, null, ooh.xdockprocessing,
          null, null,
          null, null,
          null, null, null,
          ooh.ownerxferorderid, ooh.ownerxfershipid, ooh.hdrpassthruchar41,
          ooh.hdrpassthruchar42, ooh.hdrpassthruchar43, ooh.hdrpassthruchar44, ooh.hdrpassthruchar45,
          ooh.hdrpassthruchar46, ooh.hdrpassthruchar47, ooh.hdrpassthruchar48, ooh.hdrpassthruchar49,
          ooh.hdrpassthruchar50, ooh.hdrpassthruchar51, ooh.hdrpassthruchar52, ooh.hdrpassthruchar53,
          ooh.hdrpassthruchar54, ooh.hdrpassthruchar55, ooh.hdrpassthruchar56, ooh.hdrpassthruchar57,
          ooh.hdrpassthruchar58, ooh.hdrpassthruchar59, ooh.hdrpassthruchar60, ooh.editransaction,
          ooh.invoicenumber810, ooh.invoiceamount810, ooh.expanded_websynapse_fields,
          ooh.routingstatus, ooh.manual_picks_yn, 'Y');
   end if;

-- loop thru all staged shippingplates that the user is carrying for the orderid/shipid
   for sp in c_slp loop

--    update the shippingplate and any plate
      update shippingplate
         set location = in_location,
             shipid = in_newshipid,
             loadno = noh.loadno,
             stopno = noh.stopno,
             shipno = noh.shipno,
             lastuser = in_user,
             lastupdate = sysdate
            where rowid = sp.rowid;
      if ((sp.type != 'P') and (sp.fromlpid is not null)) then
         update plate
            set location = in_location,
                lastoperator = in_user,
                lastuser = in_user,
                lastupdate = sysdate,
                lasttask = 'RS'
            where lpid = sp.fromlpid
              and type != 'XP'
            returning parentlpid into palpid;

         if ((ooh.ordertype = 'O') and (ooh.componenttemplate is not null)
         and (palpid is not null)) then
--          there is no corresponding master for the MP in this case
            update plate
               set location = in_location,
                   lastoperator = in_user,
                   lastuser = in_user,
                   lastupdate = sysdate,
                   lasttask = 'RS'
               where lpid = palpid
                 and location = in_user;
         end if;
      end if;

--    ignore masters and cartons and only consider fulls and partials
      if (sp.type in ('F','P')) then

         open c_od(in_orderid, in_shipid, sp.orderitem, sp.orderlot);
         fetch c_od into ood;
         close c_od;

         open c_od(in_orderid, in_newshipid, sp.orderitem, sp.orderlot);
         fetch c_od into nod;
         nodfound := c_od%found;
         close c_od;

         if nodfound then

--          update detail for existing shipid
            update orderdtl
               set qtypick = nvl(qtypick, 0) + sp.quantity,
                   weightpick = nvl(weightpick, 0) + sp.weight,
                   cubepick = nvl(cubepick, 0) + sp.pickcube,
                   amtpick = nvl(amtpick, 0) + sp.amt,
                   qtyorder = nvl(qtyorder, 0) + sp.quantity,
                   weightorder = nvl(weightorder, 0) + sp.weight,
                   cubeorder = nvl(cubeorder, 0) + sp.ordercube,
                   amtorder = nvl(amtorder, 0) + sp.amt,
                   lastuser = in_user,
                   lastupdate = sysdate,
                   linestatus = 'A'
            where orderid = in_orderid
              and shipid = in_newshipid
              and item = sp.orderitem
              and nvl(lotnumber,'(none)') = nvl(sp.orderlot,'(none)');

         else
--          insert detail for new shipid

            zbut.translate_uom(ood.custid, ood.itementered, sp.quantity, sp.unitofmeasure,
                  ood.uomentered, xlatqty, msg);
            if ((substr(msg, 1, 4) != 'OKAY') or (mod(xlatqty, 1) != 0)) then
               ood.qtyentered := sp.quantity;
               ood.uomentered := sp.unitofmeasure;
            else
               ood.qtyentered := xlatqty;
            end if;

            insert into orderdtl
               (orderid, shipid, item, custid, fromfacility,
                uom, linestatus, commitstatus, qtyentered, itementered,
                uomentered, qtyorder, weightorder, cubeorder, amtorder,
                qtycommit, weightcommit, cubecommit, amtcommit, qtyship,
                weightship, cubeship, amtship, qtytotcommit, weighttotcommit,
                cubetotcommit, amttotcommit, qtyrcvd, weightrcvd, cubercvd,
                amtrcvd, qtyrcvdgood, weightrcvdgood, cubercvdgood, amtrcvdgood,
                qtyrcvddmgd, weightrcvddmgd, cubercvddmgd, amtrcvddmgd, comment1,
                statususer, statusupdate, lastuser, lastupdate, priority,
                lotnumber, backorder, allowsub, qtytype, invstatusind,
                invstatus, invclassind, inventoryclass, qtypick, weightpick,
                cubepick, amtpick, consigneesku, childorderid, childshipid,
                staffhrs, qty2sort, weight2sort, cube2sort, amt2sort,
                qty2pack, weight2pack, cube2pack, amt2pack, qty2check,
                weight2check, cube2check, amt2check, dtlpassthruchar01, dtlpassthruchar02,
                dtlpassthruchar03, dtlpassthruchar04, dtlpassthruchar05, dtlpassthruchar06,
                dtlpassthruchar07, dtlpassthruchar08, dtlpassthruchar09, dtlpassthruchar10,
                dtlpassthruchar11, dtlpassthruchar12, dtlpassthruchar13, dtlpassthruchar14,
                dtlpassthruchar15, dtlpassthruchar16, dtlpassthruchar17, dtlpassthruchar18,
                dtlpassthruchar19, dtlpassthruchar20, dtlpassthrunum01, dtlpassthrunum02,
                dtlpassthrunum03, dtlpassthrunum04, dtlpassthrunum05, dtlpassthrunum06,
                dtlpassthrunum07, dtlpassthrunum08, dtlpassthrunum09, dtlpassthrunum10,
                asnvariance, cancelreason, rfautodisplay, xdockorderid, xdockshipid,
                xdocklocid, qtyoverpick,
                dtlpassthrudate01, dtlpassthrudate02, dtlpassthrudate03,
                dtlpassthrudate04, dtlpassthrudoll01, dtlpassthrudoll02,
                shipshortreason, qtyorderdiff, lineorder, weight_entered_lbs,
                weight_entered_kgs, variancepct_overage, variancepct, variancepct_use_default,
                dtlpassthruchar21, dtlpassthruchar22, dtlpassthruchar23, dtlpassthruchar24,
                dtlpassthruchar25, dtlpassthruchar26, dtlpassthruchar27, dtlpassthruchar28,
                dtlpassthruchar29, dtlpassthruchar30, dtlpassthruchar31, dtlpassthruchar32,
                dtlpassthruchar33, dtlpassthruchar34, dtlpassthruchar35, dtlpassthruchar36,
                dtlpassthruchar37, dtlpassthruchar38, dtlpassthruchar39, dtlpassthruchar40,
                dtlpassthrunum11, dtlpassthrunum12, dtlpassthrunum13, dtlpassthrunum14,
                dtlpassthrunum15, dtlpassthrunum16, dtlpassthrunum17, dtlpassthrunum18,
                dtlpassthrunum19, dtlpassthrunum20, min_days_to_expiration, receipt_weight_confirmed)
            values
               (in_orderid, in_newshipid, ood.item, ood.custid, ood.fromfacility,
                ood.uom, ood.linestatus, ood.commitstatus, ood.qtyentered, ood.itementered,
                ood.uomentered, sp.quantity, sp.weight, sp.ordercube, sp.amt,
                null, null, null, null, null,
                null, null, null, null, null,
                null, null, null, null, null,
                null, null, null, null, null,
                null, null, null, null, ood.comment1,
                in_user, null, in_user, sysdate, ood.priority,
                ood.lotnumber, ood.backorder, ood.allowsub, ood.qtytype, ood.invstatusind,
                ood.invstatus, ood.invclassind, ood.inventoryclass, sp.quantity, sp.weight,
                sp.pickcube, sp.amt, ood.consigneesku, ood.childorderid, ood.childshipid,
                null, null, null, null, null,
                null, null, null, null, null,
                null, null, null, ood.dtlpassthruchar01, ood.dtlpassthruchar02,
                ood.dtlpassthruchar03, ood.dtlpassthruchar04, ood.dtlpassthruchar05, ood.dtlpassthruchar06,
                ood.dtlpassthruchar07, ood.dtlpassthruchar08, ood.dtlpassthruchar09, ood.dtlpassthruchar10,
                ood.dtlpassthruchar11, ood.dtlpassthruchar12, ood.dtlpassthruchar13, ood.dtlpassthruchar14,
                ood.dtlpassthruchar15, ood.dtlpassthruchar16, ood.dtlpassthruchar17, ood.dtlpassthruchar18,
                ood.dtlpassthruchar19, ood.dtlpassthruchar20, ood.dtlpassthrunum01, ood.dtlpassthrunum02,
                ood.dtlpassthrunum03, ood.dtlpassthrunum04, ood.dtlpassthrunum05, ood.dtlpassthrunum06,
                ood.dtlpassthrunum07, ood.dtlpassthrunum08, ood.dtlpassthrunum09, ood.dtlpassthrunum10,
                ood.asnvariance, ood.cancelreason, ood.rfautodisplay, ood.xdockorderid, ood.xdockshipid,
                ood.xdocklocid, ood.qtyoverpick,
                ood.dtlpassthrudate01, ood.dtlpassthrudate02, ood.dtlpassthrudate03,
                ood.dtlpassthrudate04, ood.dtlpassthrudoll01, ood.dtlpassthrudoll02,
                ood.shipshortreason, null, ood.lineorder, null,
                null, ood.variancepct_overage, ood.variancepct, ood.variancepct_use_default,
                ood.dtlpassthruchar21, ood.dtlpassthruchar22, ood.dtlpassthruchar23, ood.dtlpassthruchar24,
                ood.dtlpassthruchar25, ood.dtlpassthruchar26, ood.dtlpassthruchar27, ood.dtlpassthruchar28,
                ood.dtlpassthruchar29, ood.dtlpassthruchar30, ood.dtlpassthruchar31, ood.dtlpassthruchar32,
                ood.dtlpassthruchar33, ood.dtlpassthruchar34, ood.dtlpassthruchar35, ood.dtlpassthruchar36,
                ood.dtlpassthruchar37, ood.dtlpassthruchar38, ood.dtlpassthruchar39, ood.dtlpassthruchar40,
                ood.dtlpassthrunum11, ood.dtlpassthrunum12, ood.dtlpassthrunum13, ood.dtlpassthrunum14,
                ood.dtlpassthrunum15, ood.dtlpassthrunum16, ood.dtlpassthrunum17, ood.dtlpassthrunum18,
                ood.dtlpassthrunum19, ood.dtlpassthrunum20, ood.min_days_to_expiration, ood.receipt_weight_confirmed);
         end if;

--       update orderdtlline for old and new shipids
         adjust_orderdtlline(ood.custid, in_orderid, in_shipid, sp.orderitem, sp.orderlot,
               sp.quantity, in_newshipid, in_user, msg);
         if (msg is not null) then
            out_error := 'Y';
            out_message := msg;
            return;
         end if;

--       update detail for old shipid
         update orderdtl
            set qtypick = nvl(qtypick, 0) - sp.quantity,
                weightpick = nvl(weightpick, 0) - sp.weight,
                cubepick = nvl(cubepick, 0) - sp.pickcube,
                amtpick = nvl(amtpick, 0) - sp.amt,
                qtyorder = nvl(qtyorder, 0) - sp.quantity,
                weightorder = nvl(weightorder, 0) - sp.weight,
                cubeorder = nvl(cubeorder, 0) - sp.ordercube,
                amtorder = nvl(amtorder, 0) - sp.amt,
                lastuser = in_user,
                lastupdate = sysdate
         where orderid = in_orderid
           and shipid = in_shipid
           and item = sp.orderitem
           and nvl(lotnumber,'(none)') = nvl(sp.orderlot,'(none)')
         returning qtyorder into ood.qtyorder;

         ooh.orderstatus := '1';
         if (ood.qtyorder = 0) then
--          cancel the line item
            update orderdtl
               set linestatus = 'X',
                   lastuser = in_user,
                   lastupdate = sysdate
               where orderid = in_orderid
                 and shipid = in_shipid
                 and item = sp.orderitem
                 and nvl(lotnumber,'(none)') = nvl(sp.orderlot,'(none)');

            open c_oh(in_orderid, in_shipid);
            fetch c_oh into ooh;
            close c_oh;

            if (ooh.qtyorder = 0) then
--             cancel the order
               ooh.orderstatus := 'X';
               update orderhdr
                  set orderstatus = 'X',
                      lastuser = in_user,
                      lastupdate = sysdate
                  where orderid = in_orderid
                    and shipid = in_shipid;

               if (ooh.loadno != 0) then
--                deassign order from load
                  zld.deassign_order_from_load(in_orderid, in_shipid, in_facility, in_user,
                        'N', errorno, msg);
                  if (errorno != 0) then
                     out_message := msg;
                     rollback;
                     return;
                  end if;

                  open c_ld(ooh.loadno);
                  fetch c_ld into ld;
                  close c_ld;

                  if (ld.loadstatus in ('1', '2')) then
--                   cancel the load
                     zld.cancel_load(ooh.loadno, in_facility, in_user, msg);
                     if (msg != 'OKAY') then
                        out_message := msg;
                        rollback;
                        return;
                     end if;
                  end if;
               end if;
            end if;
         end if;
         if (ooh.orderstatus != 'X') then
--          adjust the order
            zdep.adjust_order_and_load(in_orderid, in_shipid, in_facility, in_user, 'N', msg);
            if (msg is not null) then
               out_error := 'Y';
               out_message := msg;
               return;
            end if;
         end if;
      end if;

   end loop;
   begin
      update caselabels
         set shipid = in_newshipid
         where orderid = in_orderid
           and shipid = in_shipid
           and lpid in (select lpid from shippingplate
                         where orderid = in_orderid
                           and shipid =  in_newshipid
                           and parentlpid is null);
   exception when no_data_found then
      null;

   end;

   update orderhdr
      set restaged_yn = 'Y'
    where orderid = in_orderid
      and shipid = in_shipid
      and nvl(restaged_yn,'N') = 'N';

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end restage_shipid;


end rfrestaging;
/

show errors package body rfrestaging;
exit;
