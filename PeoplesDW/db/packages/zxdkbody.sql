create or replace package body alps.zcrossdock as
--
-- $Id$
--


-- Constants


MAX_SEQ     CONSTANT    integer := 9999999;
IX_CLOSE    CONSTANT    integer := 1;
IX_NEED     CONSTANT    integer := 2;
IX_PK_CLOSE CONSTANT    integer := 3;
IX_PK_NEED  CONSTANT    integer := 4;


-- Public procedures


procedure build_xdock_outbound
   (in_orderid  in number,
    in_shipid   in number,
    in_shipto   in varchar2,
    in_userid   in varchar2,
    out_orderid out number,
    out_shipid  out number,
    io_msg      in out varchar2)
is
   cursor c_xh(p_orderid number, p_shipid number) is
      select ordertype, tofacility, shipto, custid
         from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   xh c_xh%rowtype := null;
   l_found boolean;
   l_orderid orderhdr.orderid%type;
   l_shipid orderhdr.shipid%type;
   l_shippingto orderdtlline.shiptoname%type := null;

   procedure bld_header             -- sets l_orderid, l_shipid, out_orderid and out_shipid
      (in_shipto     in varchar2,
       io_msg        in out varchar2)
   is
      l_msg varchar2(255);
   begin
      io_msg := 'OKAY';

  		zoe.get_next_orderid(l_orderid, l_msg);
  		if l_msg != 'OKAY' then
      	io_msg := 'No next orderid: ' || l_msg;
         return;
     	end if;

      l_shipid := 1;
      zcl.clone_orderhdr(in_orderid, in_shipid, l_orderid, l_shipid, null, in_userid, io_msg);
      if io_msg = 'OKAY' then
         update orderhdr
            set ordertype = 'O',
                orderstatus = '1',
                fromfacility = xh.tofacility,
                tofacility = null,
                qtyorder = 0,
                cubeorder = 0,
                weightorder = 0,
                amtorder = 0,
                xdockorderid = in_orderid,
                xdockshipid = in_shipid,
                shipto = in_shipto,
                qtyrcvd = null,
                weightrcvd = null,
                cubercvd = null,
                amtrcvd = null,
                loadno = null,
                stopno = null,
                shipno = null,
                parentorderid = null,
                parentshipid = null
            where orderid = l_orderid
              and shipid = l_shipid;
      end if;
      out_orderid := l_orderid;
      out_shipid := l_shipid;
   end bld_header;

   procedure do_order_misc
   is
      cursor c_cons is
         select CO.shiptype, CO.shipterms
            from orderhdr OH, consignee CO
            where OH.orderid = l_orderid
              and OH.shipid = l_shipid
              and CO.consignee = OH.shipto;
      cons c_cons%rowtype := null;
      l_errno number;
      l_msg varchar2(255);
      l_auxmsg varchar2(255);
   begin
      open c_cons;
      fetch c_cons into cons;
      close c_cons;
      update orderhdr
         set shiptype = nvl(shiptype, cons.shiptype),
             shipterms = nvl(shipterms, cons.shipterms)
         where orderid = l_orderid
           and shipid = l_shipid;

      zlb.compute_order_labor(l_orderid, l_shipid, xh.tofacility, in_userid,
            l_errno, l_msg);
      if l_errno != 0 then
         zms.log_msg('LABORCALC', xh.tofacility, xh.custid, l_msg, 'W', in_userid, l_auxmsg);
      end if;

      zoh.add_orderhistory(l_orderid, l_shipid, 'Order created',
            'Order created from crossdock: '||in_orderid||'-'||in_shipid, in_userid, l_msg);
      if l_msg != 'OKAY' then
         zms.log_msg('ORDERHISTORY', xh.tofacility, xh.custid, l_msg, 'W', in_userid, l_auxmsg);
      end if;
   end do_order_misc;

   procedure initialize_hdr
   is
   begin
      update orderhdr
         set consignee = null,
             carrier = null,
             deliveryservice = null,
             saturdaydelivery = null,
             shiptype = null,
             shipterms = null,
             shipdate = null,
             arrivaldate = null,
             stageloc = null,
             prono = null,
             shippingcost = null,
             shiptoname = null,
             shiptoaddr1 = null,
             shiptoaddr2 = null,
             shiptocity = null,
             shiptostate = null,
             shiptopostalcode = null,
             shiptocountrycode = null,
             cod = null,
             companycheckok = null,
             amtcod = null,
             shiptocontact = null,
             shiptophone = null,
             shiptofax = null,
             shiptoemail = null,
             specialservice1 = null,
             specialservice2 = null,
             specialservice3 = null,
             specialservice4 = null,
             billtoname = null,
             billtoaddr1 = null,
             billtoaddr2 = null,
             billtocity = null,
             billtostate = null,
             billtopostalcode = null,
             billtocountrycode = null,
             billtocontact = null,
             billtophone = null,
             billtofax = null,
             billtoemail = null
         where orderid = l_orderid
           and shipid = l_shipid;
   end initialize_hdr;

   procedure finalize_hdr
   is
      cursor c_oh is
         select *
            from orderhdr
            where orderid = in_orderid
              and shipid = in_shipid;
      oh c_oh%rowtype := null;
   begin
      open c_oh;
      fetch c_oh into oh;
      close c_oh;

      update orderhdr
         set consignee = nvl(consignee, oh.consignee),
             carrier = nvl(carrier, oh.carrier),
             deliveryservice = nvl(deliveryservice, oh.deliveryservice),
             saturdaydelivery = nvl(saturdaydelivery, oh.saturdaydelivery),
             shiptype = nvl(shiptype, oh.shiptype),
             shipterms = nvl(shipterms, oh.shipterms),
             shipdate = nvl(shipdate, oh.shipdate),
             arrivaldate = nvl(arrivaldate, oh.arrivaldate),
             stageloc = nvl(stageloc, oh.stageloc),
             prono = nvl(prono, oh.prono),
             shippingcost = nvl(shippingcost, oh.shippingcost),
             shiptoname = nvl(shiptoname, oh.shiptoname),
             shiptoaddr1 = nvl(shiptoaddr1, oh.shiptoaddr1),
             shiptoaddr2 = nvl(shiptoaddr2, oh.shiptoaddr2),
             shiptocity = nvl(shiptocity, oh.shiptocity),
             shiptostate = nvl(shiptostate, oh.shiptostate),
             shiptopostalcode = nvl(shiptopostalcode, oh.shiptopostalcode),
             shiptocountrycode = nvl(shiptocountrycode, oh.shiptocountrycode),
             cod = nvl(cod, oh.cod),
             companycheckok = nvl(companycheckok, oh.companycheckok),
             amtcod = nvl(amtcod, oh.amtcod),
             shiptocontact = nvl(shiptocontact, oh.shiptocontact),
             shiptophone = nvl(shiptophone, oh.shiptophone),
             shiptofax = nvl(shiptofax, oh.shiptofax),
             shiptoemail = nvl(shiptoemail, oh.shiptoemail),
             specialservice1 = nvl(specialservice1, oh.specialservice1),
             specialservice2 = nvl(specialservice2, oh.specialservice2),
             specialservice3 = nvl(specialservice3, oh.specialservice3),
             specialservice4 = nvl(specialservice4, oh.specialservice4),
             billtoname = nvl(billtoname, oh.billtoname),
             billtoaddr1 = nvl(billtoaddr1, oh.billtoaddr1),
             billtoaddr2 = nvl(billtoaddr2, oh.billtoaddr2),
             billtocity = nvl(billtocity, oh.billtocity),
             billtostate = nvl(billtostate, oh.billtostate),
             billtopostalcode = nvl(billtopostalcode, oh.billtopostalcode),
             billtocountrycode = nvl(billtocountrycode, oh.billtocountrycode),
             billtocontact = nvl(billtocontact, oh.billtocontact),
             billtophone = nvl(billtophone, oh.billtophone),
             billtofax = nvl(billtofax, oh.billtofax),
             billtoemail = nvl(billtoemail, oh.billtoemail)
         where orderid = l_orderid
           and shipid = l_shipid;
   end finalize_hdr;

begin
   io_msg := 'OKAY';
   out_orderid := null;
   out_shipid := null;

   open c_xh(in_orderid, in_shipid);
   fetch c_xh into xh;
   l_found := c_xh%found;
   close c_xh;
   if not l_found then
      io_msg := 'Order not found';
      return;
   end if;

   if xh.ordertype != 'C' then
      io_msg := 'Not a crossdock order';
      return;
   end if;

   xh.shipto := nvl(xh.shipto, in_shipto);
   if xh.shipto is not null then
      bld_header(xh.shipto, io_msg);
      if io_msg = 'OKAY' then
         if in_shipto is null then
            for od in (select item, lotnumber from orderdtl
                        where orderid = in_orderid
                          and shipid = in_shipid) loop

               zcl.clone_orderdtl(in_orderid, in_shipid, od.item, od.lotnumber,
                     l_orderid, l_shipid, od.item, od.lotnumber, null, in_userid, io_msg);
               if io_msg != 'OKAY' then
                  exit;
               end if;

               update orderdtl
                  set fromfacility = xh.tofacility
                  where orderid = l_orderid
                    and shipid = l_shipid
                    and item = od.item
                    and nvl(lotnumber,'(none)') = nvl(od.lotnumber,'(none)');
            end loop;
         end if;

         if io_msg = 'OKAY' then
            do_order_misc;
         end if;
      end if;
      return;
   end if;

   for ol in (select
                nvl(odl.orderid, od.orderid) orderid,
                nvl(odl.shipid, od.shipid) shipid,
                nvl(odl.item, od.item) item,
                nvl(odl.lotnumber, od.lotnumber) lotnumber,
                nvl(odl.linenumber, 1) linenumber,
                nvl(odl.qty, od.qtyorder) qty,
                nvl(odl.dtlpassthruchar01, od.dtlpassthruchar01) dtlpassthruchar01,
                nvl(odl.dtlpassthruchar02, od.dtlpassthruchar02) dtlpassthruchar02,
                nvl(odl.dtlpassthruchar03, od.dtlpassthruchar03) dtlpassthruchar03,
                nvl(odl.dtlpassthruchar04, od.dtlpassthruchar04) dtlpassthruchar04,
                nvl(odl.dtlpassthruchar05, od.dtlpassthruchar05) dtlpassthruchar05,
                nvl(odl.dtlpassthruchar06, od.dtlpassthruchar06) dtlpassthruchar06,
                nvl(odl.dtlpassthruchar07, od.dtlpassthruchar07) dtlpassthruchar07,
                nvl(odl.dtlpassthruchar08, od.dtlpassthruchar08) dtlpassthruchar08,
                nvl(odl.dtlpassthruchar09, od.dtlpassthruchar09) dtlpassthruchar09,
                nvl(odl.dtlpassthruchar10, od.dtlpassthruchar10) dtlpassthruchar10,
                nvl(odl.dtlpassthruchar11, od.dtlpassthruchar11) dtlpassthruchar11,
                nvl(odl.dtlpassthruchar12, od.dtlpassthruchar12) dtlpassthruchar12,
                nvl(odl.dtlpassthruchar13, od.dtlpassthruchar13) dtlpassthruchar13,
                nvl(odl.dtlpassthruchar14, od.dtlpassthruchar14) dtlpassthruchar14,
                nvl(odl.dtlpassthruchar15, od.dtlpassthruchar15) dtlpassthruchar15,
                nvl(odl.dtlpassthruchar16, od.dtlpassthruchar16) dtlpassthruchar16,
                nvl(odl.dtlpassthruchar17, od.dtlpassthruchar17) dtlpassthruchar17,
                nvl(odl.dtlpassthruchar18, od.dtlpassthruchar18) dtlpassthruchar18,
                nvl(odl.dtlpassthruchar19, od.dtlpassthruchar19) dtlpassthruchar19,
                nvl(odl.dtlpassthruchar20, od.dtlpassthruchar20) dtlpassthruchar20,
                nvl(odl.dtlpassthrunum01, od.dtlpassthrunum01) dtlpassthrunum01,
                nvl(odl.dtlpassthrunum02, od.dtlpassthrunum02) dtlpassthrunum02,
                nvl(odl.dtlpassthrunum03, od.dtlpassthrunum03) dtlpassthrunum03,
                nvl(odl.dtlpassthrunum04, od.dtlpassthrunum04) dtlpassthrunum04,
                nvl(odl.dtlpassthrunum05, od.dtlpassthrunum05) dtlpassthrunum05,
                nvl(odl.dtlpassthrunum06, od.dtlpassthrunum06) dtlpassthrunum06,
                nvl(odl.dtlpassthrunum07, od.dtlpassthrunum07) dtlpassthrunum07,
                nvl(odl.dtlpassthrunum08, od.dtlpassthrunum08) dtlpassthrunum08,
                nvl(odl.dtlpassthrunum09, od.dtlpassthrunum09) dtlpassthrunum09,
                nvl(odl.dtlpassthrunum10, od.dtlpassthrunum10) dtlpassthrunum10,
                nvl(odl.lastuser, od.lastuser) lastuser,
                nvl(odl.lastupdate, od.lastupdate) lastupdate,
                nvl(odl.dtlpassthrudate01, od.dtlpassthrudate01) dtlpassthrudate01,
                nvl(odl.dtlpassthrudate02, od.dtlpassthrudate02) dtlpassthrudate02,
                nvl(odl.dtlpassthrudate03, od.dtlpassthrudate03) dtlpassthrudate03,
                nvl(odl.dtlpassthrudate04, od.dtlpassthrudate04) dtlpassthrudate04,
                nvl(odl.dtlpassthrudoll01, od.dtlpassthrudoll01) dtlpassthrudoll01,
                nvl(odl.dtlpassthrudoll02, od.dtlpassthrudoll02) dtlpassthrudoll02,
                nvl(odl.uomentered, od.uomentered) uomentered,
                nvl(odl.qtyentered, od.qtyentered) qtyentered,
                nvl(odl.shipto, oh.shipto) shipto,
                nvl(odl.xdock, 'Y') xdock,
                nvl(odl.consignee, oh.consignee) consignee,
                nvl(odl.carrier, oh.carrier) carrier,
                nvl(odl.deliveryservice, oh.deliveryservice) deliveryservice,
                nvl(odl.saturdaydelivery, oh.saturdaydelivery) saturdaydelivery,
                nvl(odl.shiptype, oh.shiptype) shiptype,
                nvl(odl.shipterms, oh.shipterms) shipterms,
                nvl(odl.shipdate, oh.shipdate) shipdate,
                nvl(odl.arrivaldate, oh.arrivaldate) arrivaldate,
                nvl(odl.stageloc, oh.stageloc) stageloc,
                nvl(odl.prono, oh.prono) prono,
                nvl(odl.shippingcost, oh.shippingcost) shippingcost,
                nvl(odl.shiptoname, oh.shiptoname) shiptoname,
                nvl(odl.shiptoaddr1, oh.shiptoaddr1) shiptoaddr1,
                nvl(odl.shiptoaddr2, oh.shiptoaddr2) shiptoaddr2,
                nvl(odl.shiptocity, oh.shiptocity) shiptocity,
                nvl(odl.shiptostate, oh.shiptostate) shiptostate,
                nvl(odl.shiptopostalcode, oh.shiptopostalcode) shiptopostalcode,
                nvl(odl.shiptocountrycode, oh.shiptocountrycode) shiptocountrycode,
                nvl(odl.cod, oh.cod) cod,
                nvl(odl.companycheckok, oh.companycheckok) companycheckok,
                nvl(odl.amtcod, oh.amtcod) amtcod,
                nvl(odl.shiptocontact, oh.shiptocontact) shiptocontact,
                nvl(odl.shiptophone, oh.shiptophone) shiptophone,
                nvl(odl.shiptofax, oh.shiptofax) shiptofax,
                nvl(odl.shiptoemail, oh.shiptoemail) shiptoemail,
                nvl(odl.specialservice1, oh.specialservice1) specialservice1,
                nvl(odl.specialservice2, oh.specialservice2) specialservice2,
                nvl(odl.specialservice3, oh.specialservice3) specialservice3,
                nvl(odl.specialservice4, oh.specialservice4) specialservice4,
                nvl(odl.billtoname, oh.billtoname) billtoname,
                nvl(odl.billtoaddr1, oh.billtoaddr1) billtoaddr1,
                nvl(odl.billtoaddr2, oh.billtoaddr2) billtoaddr2,
                nvl(odl.billtocity, oh.billtocity) billtocity,
                nvl(odl.billtostate, oh.billtostate) billtostate,
                nvl(odl.billtopostalcode, oh.billtopostalcode) billtopostalcode,
                nvl(odl.billtocountrycode, oh.billtocountrycode) billtocountrycode,
                nvl(odl.billtocontact, oh.billtocontact) billtocontact,
                nvl(odl.billtophone, oh.billtophone) billtophone,
                nvl(odl.billtofax, oh.billtofax) billtofax,
                nvl(odl.billtoemail, oh.billtoemail) billtoemail
            from orderhdr oh, orderdtlline odl, orderdtl od
               where oh.orderid = in_orderid
                 and oh.shipid = in_shipid
                 and OH.orderid = od.orderid
                 and OH.shipid = od.shipid
                 and nvl(xdock(+),'N') != 'N'
                 and OD.orderid = ODL.orderid(+)
                 and OD.shipid = ODL.shipid(+)
                 and OD.item = ODL.item(+)
                 and nvl(OD.lotnumber,'(none)') = nvl(ODL.lotnumber(+),'(none)')
               order by nvl(shipto,shiptoname), linenumber) loop

      if (l_shippingto is null) or (l_shippingto != nvl(ol.shipto,ol.shiptoname)) then
         if l_shippingto is not null then
            finalize_hdr;
            do_order_misc;
         end if;
         bld_header(ol.shipto, io_msg);
         initialize_hdr;
         if io_msg != 'OKAY' then
            exit;
         end if;
         l_shippingto := nvl(ol.shipto,ol.shiptoname);
      end if;

      update orderhdr
         set consignee = nvl(consignee, ol.consignee),
             carrier = nvl(carrier, ol.carrier),
             deliveryservice = nvl(deliveryservice, ol.deliveryservice),
             saturdaydelivery = nvl(saturdaydelivery, ol.saturdaydelivery),
             shiptype = nvl(shiptype, ol.shiptype),
             shipterms = nvl(shipterms, ol.shipterms),
             shipdate = nvl(shipdate, ol.shipdate),
             arrivaldate = nvl(arrivaldate, ol.arrivaldate),
             stageloc = nvl(stageloc, ol.stageloc),
             prono = nvl(prono, ol.prono),
             shippingcost = nvl(shippingcost, ol.shippingcost),
             shiptoname = nvl(shiptoname, ol.shiptoname),
             shiptoaddr1 = nvl(shiptoaddr1, ol.shiptoaddr1),
             shiptoaddr2 = nvl(shiptoaddr2, ol.shiptoaddr2),
             shiptocity = nvl(shiptocity, ol.shiptocity),
             shiptostate = nvl(shiptostate, ol.shiptostate),
             shiptopostalcode = nvl(shiptopostalcode, ol.shiptopostalcode),
             shiptocountrycode = nvl(shiptocountrycode, ol.shiptocountrycode),
             cod = nvl(cod, ol.cod),
             companycheckok = nvl(companycheckok, ol.companycheckok),
             amtcod = nvl(amtcod, ol.amtcod),
             shiptocontact = nvl(shiptocontact, ol.shiptocontact),
             shiptophone = nvl(shiptophone, ol.shiptophone),
             shiptofax = nvl(shiptofax, ol.shiptofax),
             shiptoemail = nvl(shiptoemail, ol.shiptoemail),
             specialservice1 = nvl(specialservice1, ol.specialservice1),
             specialservice2 = nvl(specialservice2, ol.specialservice2),
             specialservice3 = nvl(specialservice3, ol.specialservice3),
             specialservice4 = nvl(specialservice4, ol.specialservice4),
             billtoname = nvl(billtoname, ol.billtoname),
             billtoaddr1 = nvl(billtoaddr1, ol.billtoaddr1),
             billtoaddr2 = nvl(billtoaddr2, ol.billtoaddr2),
             billtocity = nvl(billtocity, ol.billtocity),
             billtostate = nvl(billtostate, ol.billtostate),
             billtopostalcode = nvl(billtopostalcode, ol.billtopostalcode),
             billtocountrycode = nvl(billtocountrycode, ol.billtocountrycode),
             billtocontact = nvl(billtocontact, ol.billtocontact),
             billtophone = nvl(billtophone, ol.billtophone),
             billtofax = nvl(billtofax, ol.billtofax),
             billtoemail = nvl(billtoemail, ol.billtoemail)
         where orderid = l_orderid
           and shipid = l_shipid;

      zcl.clone_orderdtl(in_orderid, in_shipid, ol.item, ol.lotnumber,
            l_orderid, l_shipid, ol.item, ol.lotnumber, null, in_userid, io_msg);
      if io_msg != 'OKAY' then
         exit;
      end if;

      update orderdtl
         set fromfacility = xh.tofacility,
             qtyentered = ol.qtyentered,
             uomentered = ol.uomentered,
             qtyorder = ol.qty,
             weightorder = ol.qty * zci.item_weight(custid, item, uom),
             cubeorder = ol.qty * zci.item_cube(custid, item, uom),
             amtorder = ol.qty * zci.item_amt(custid, orderid, shipid, item, lotnumber), --prn 25133
             dtlpassthruchar01 = ol.dtlpassthruchar01,
             dtlpassthruchar02 = ol.dtlpassthruchar02,
             dtlpassthruchar03 = ol.dtlpassthruchar03,
             dtlpassthruchar04 = ol.dtlpassthruchar04,
             dtlpassthruchar05 = ol.dtlpassthruchar05,
             dtlpassthruchar06 = ol.dtlpassthruchar06,
             dtlpassthruchar07 = ol.dtlpassthruchar07,
             dtlpassthruchar08 = ol.dtlpassthruchar08,
             dtlpassthruchar09 = ol.dtlpassthruchar09,
             dtlpassthruchar10 = ol.dtlpassthruchar10,
             dtlpassthruchar11 = ol.dtlpassthruchar11,
             dtlpassthruchar12 = ol.dtlpassthruchar12,
             dtlpassthruchar13 = ol.dtlpassthruchar13,
             dtlpassthruchar14 = ol.dtlpassthruchar14,
             dtlpassthruchar15 = ol.dtlpassthruchar15,
             dtlpassthruchar16 = ol.dtlpassthruchar16,
             dtlpassthruchar17 = ol.dtlpassthruchar17,
             dtlpassthruchar18 = ol.dtlpassthruchar18,
             dtlpassthruchar19 = ol.dtlpassthruchar19,
             dtlpassthruchar20 = ol.dtlpassthruchar20,
             dtlpassthrunum01 = ol.dtlpassthrunum01,
             dtlpassthrunum02 = ol.dtlpassthrunum02,
             dtlpassthrunum03 = ol.dtlpassthrunum03,
             dtlpassthrunum04 = ol.dtlpassthrunum04,
             dtlpassthrunum05 = ol.dtlpassthrunum05,
             dtlpassthrunum06 = ol.dtlpassthrunum06,
             dtlpassthrunum07 = ol.dtlpassthrunum07,
             dtlpassthrunum08 = ol.dtlpassthrunum08,
             dtlpassthrunum09 = ol.dtlpassthrunum09,
             dtlpassthrunum10 = ol.dtlpassthrunum10,
             dtlpassthrudate01 = ol.dtlpassthrudate01,
             dtlpassthrudate02 = ol.dtlpassthrudate02,
             dtlpassthrudate03 = ol.dtlpassthrudate03,
             dtlpassthrudate04 = ol.dtlpassthrudate04,
             dtlpassthrudoll01 = ol.dtlpassthrudoll01,
             dtlpassthrudoll02 = ol.dtlpassthrudoll02
         where orderid = l_orderid
           and shipid = l_shipid
           and item = ol.item
           and nvl(lotnumber,'(none)') = nvl(ol.lotnumber,'(none)');
   end loop;

   if io_msg = 'OKAY' then
      finalize_hdr;
      do_order_misc;
   end if;

exception
   when OTHERS then
      io_msg := substr(sqlerrm, 1, 80);
end build_xdock_outbound;


procedure add_xdock_plate
   (in_lpid   in varchar2,
    in_asn    in varchar2,
    in_userid in varchar2,
    in_loc    in varchar2,
    out_err   out varchar2,
    out_msg   out varchar2)
is
   type xord_rectype is record (
      orderid orderhdr.orderid%type,
      shipid orderhdr.shipid%type,
      loadno orderhdr.loadno%type,
      stopno orderhdr.stopno%type,
      shipno orderhdr.shipno%type,
      loc location.locid%type,
      seq integer,
      needed orderhdr.qtyorder%type);
   type xord_tbltype is table of xord_rectype index by binary_integer;
   xord xord_tbltype;
   type dest_rectype is record (
      loc location.locid%type);
   type dest_tbltype is table of dest_rectype index by binary_integer;
   dest dest_tbltype;
   type pick_rectype is record (
      seq integer,
      ix binary_integer);
   type pick_tbltype is table of pick_rectype index by binary_integer;
   pick pick_tbltype;
   cursor c_lp(p_lpid varchar2) is
      select PL.*, OH.ordertype, OH.priority,
             nvl(OH.parentorderid,0) as parentorderid,
             nvl(OH.parentshipid,0) as parentshipid
         from plate PL, orderhdr OH
         where PL.lpid = p_lpid
           and OH.orderid (+) = PL.orderid
           and OH.shipid (+) = PL.shipid;
   lp c_lp%rowtype := null;
   cursor c_oh(p_orderid number, p_shipid number, p_item varchar2, p_lotnumber varchar2) is
      select OH.orderid as orderid,
             OH.shipid as shipid,
             OH.loadno as loadno,
             OH.stopno as stopno,
             OH.shipno as shipno,
             nvl(OD.qtyorder,0) as qtyorder,
             nvl(OD.qtypick,0) as qtypick
         from orderhdr OH, orderdtl OD
         where OH.xdockorderid = p_orderid
           and OH.xdockshipid = p_shipid
           and OH.ordertype = 'O'
           and OH.orderstatus between '1' and '8'
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
           and OD.item = p_item
           and nvl(OD.lotnumber,'(none)') = nvl(p_lotnumber,'(none)');
   oh c_oh%rowtype := null;
   cursor c_loc(p_facility varchar2, p_locid varchar2) is
      select nvl(pickingseq,MAX_SEQ) as pickingseq
         from location
         where facility = p_facility
           and locid = p_locid;
   cursor c_acd(p_asn varchar2) is
      select shipto, nvl(outbound_orderid,0) as outbound_orderid, rowid
         from asncartondtl
         where trackingno = p_asn;
   acd c_acd%rowtype;
   cursor c_oo(p_facility varchar2, p_custid varchar2, p_shipto varchar2) is
      select orderid, shipid, loadno, stopno, shipno
         from orderhdr
         where fromfacility = p_facility
           and custid = p_custid
           and shipto = p_shipto
           and ordertype = 'O'
           and orderstatus < '9';
   oo c_oo%rowtype;
   l_curseq integer;
   l_seq integer;
   l_msg varchar2(255);
   l_stageloc location.locid%type;
   l_loadloc location.locid%type;
   l_loc location.locid%type;
   i binary_integer;
   j binary_integer;
   l_found boolean;

   procedure build_pick
      (p_i binary_integer)
   is
      l_lpid shippingplate.lpid%type;
   begin
      zsp.get_next_shippinglpid(l_lpid, out_msg);
      if out_msg is not null then
         out_err := 'Y';
         return;
      end if;

      insert into shippingplate
         (lpid,
          item,
          custid,
          facility,
          location,
          status,
          holdreason,
          unitofmeasure,
          quantity,
          type,
          fromlpid,
          serialnumber,
          lotnumber,
          parentlpid,
          useritem1,
          useritem2,
          useritem3,
          lastuser,
          lastupdate,
          invstatus,
          qtyentered,
          orderitem,
          uomentered,
          inventoryclass,
          loadno,
          stopno,
          shipno,
          orderid,
          shipid,
          weight,
          ucc128,
          labelformat,
          taskid,
          dropseq,
          orderlot,
          pickuom,
          pickqty,
          trackingno,
          cartonseq,
          checked,
          totelpid,
          cartontype,
          pickedfromloc,
          shippingcost,
          carriercodeused,
          satdeliveryused,
          openfacility,
          audited,
          prevlocation,
          fromlpidparent,
          rmatrackingno,
          actualcarrier,
          manufacturedate,
          expirationdate)
      values
         (l_lpid,
          lp.item,
          lp.custid,
          lp.facility,
          lp.location,
          'P',
          null,
          lp.unitofmeasure,
          lp.quantity,
          'F',
          in_lpid,
          lp.serialnumber,
          lp.lotnumber,
          null,
          lp.useritem1,
          lp.useritem2,
          lp.useritem3,
          in_userid,
          sysdate,
          lp.invstatus,
          lp.qtyentered,
          lp.item,
          lp.uomentered,
          lp.inventoryclass,
          xord(p_i).loadno,
          xord(p_i).stopno,
          xord(p_i).shipno,
          xord(p_i).orderid,
          xord(p_i).shipid,
          lp.weight,
          null,
          null,
          null,
          null,
          lp.lotnumber,
          lp.unitofmeasure,
          lp.quantity,
          null,
          null,
          null,
          null,
          null,
          in_loc,
          null,
          null,
          null,
          null,
          null,
          null,
          lp.parentlpid,
          null,
          null,
          lp.manufacturedate,
          lp.expirationdate);

      -- build orderdtl if none exists
      update orderdtl
         set qtypick = nvl(qtypick,0) + lp.quantity,
             weightpick = nvl(weightpick,0) + lp.weight,
             cubepick = nvl(cubepick,0)
                  + (lp.quantity*zci.item_cube(lp.custid, lp.item, lp.unitofmeasure)),
             amtpick = nvl(amtpick,0) + (lp.quantity*zci.item_amt(lp.custid, orderid, shipid, lp.item, lotnumber)) --prn 25133
         where orderid = xord(p_i).orderid
           and shipid = xord(p_i).shipid
           and item = lp.item
           and nvl(lotnumber,'(none)') = nvl(lp.lotnumber,'(none)');
      if sql%rowcount = 0 then
         insert into orderdtl
            (orderid,
             shipid,
             item,
             custid,
             fromfacility,
             uom,
             linestatus,
             qtyentered,
             itementered,
             uomentered,
             qtyorder,
             weightorder,
             cubeorder,
             amtorder,
             statususer,
             statusupdate,
             lastuser,
             lastupdate,
             priority,
             lotnumber,
             backorder,
             allowsub,
             qtytype,
             qtypick,
             weightpick,
             cubepick,
             amtpick)
         select
             xord(p_i).orderid,
             xord(p_i).shipid,
             lp.item,
             lp.custid,
             lp.facility,
             lp.unitofmeasure,
             'A',
             decode(lp.parentorderid, 0, lp.qtyentered, null),
             lp.itementered,
             lp.uomentered,
             decode(lp.parentorderid, 0, lp.quantity, null),
             decode(lp.parentorderid, 0, lp.weight, null),
             decode(lp.parentorderid, 0,
                  lp.quantity * zci.item_cube(lp.custid, lp.item, lp.unitofmeasure), null),
             decode(lp.parentorderid, 0, lp.quantity * zci.item_amt(lp.custid, null, null, lp.item, null), null),  --prn 25133
             in_userid,
             sysdate,
             in_userid,
             sysdate,
             lp.priority,
             lp.lotnumber,
             backorder,
             allowsub,
             qtytype,
             lp.quantity,
             lp.weight,
             lp.quantity * zci.item_cube(lp.custid, lp.item, lp.unitofmeasure),
             lp.quantity * zci.item_amt(lp.custid, null, null, lp.item, null)
            from custitemview
            where custid = lp.custid
              and item = lp.item;
      end if;
   end build_pick;
begin
   out_err := 'N';
   out_msg := null;

   open c_lp(in_lpid);
   fetch c_lp into lp;
   close c_lp;
   if nvl(lp.ordertype,'?') != 'C' then
      return;
   end if;

   if (lp.parentorderid != 0) and (in_asn = '(none)') then
      out_msg := 'Inb Notice needs asn';
      return;
   end if;

   open c_loc(lp.facility, in_loc);
   fetch c_loc into l_curseq;
   close c_loc;

   xord.delete;
   dest.delete;
-- we're working on an inbound notice
   if lp.parentorderid != 0 then
      open c_acd(in_asn);
      fetch c_acd into acd;
      l_found := c_acd%found;
      close c_acd;
      if not l_found then
         out_msg := 'ASN not found';
         return;
      end if;

      if acd.outbound_orderid != 0 then
         out_msg := 'ASN already received';
         return;
      end if;

      if acd.shipto is null then
         out_msg := 'ASN needs consignee';
         return;
      end if;

--    try to find an open order for the same shipto
      open c_oo(lp.facility, lp.custid, acd.shipto);
      fetch c_oo into oo;
      l_found := c_oo%found;
      close c_oo;

      i := 1;
      if l_found then                        -- found, use it
         xord(i).orderid := oo.orderid;
         xord(i).shipid := oo.shipid;
         xord(i).loadno := oo.loadno;
         xord(i).stopno := oo.stopno;
         xord(i).shipno := oo.shipno;
         update orderhdr
            set xdockorderid = nvl(xdockorderid, lp.orderid),
                xdockshipid = nvl(xdockshipid, lp.shipid)
            where orderid = xord(i).orderid
              and shipid = xord(i).shipid;
      else                                   -- not found, create a new one
         build_xdock_outbound(lp.orderid, lp.shipid, acd.shipto, in_userid,  xord(i).orderid,
               xord(i).shipid, l_msg);
         if l_msg != 'OKAY' then
            out_err := 'Y';
            out_msg := l_msg;
            return;
         end if;
         xord(i).loadno := null;
         xord(i).stopno := null;
         xord(i).shipno := null;
      end if;
      xord(i).loc := null;
      xord(i).seq := 0;
      xord(i).needed := 0;
      update asncartondtl
         set outbound_orderid = xord(i).orderid,
             outbound_shipid = xord(i).shipid
         where rowid = acd.rowid;
   else
      open c_oh(lp.orderid, lp.shipid, lp.item, lp.lotnumber); -- all outbounds with item
      loop
         fetch c_oh into oh;
         exit when c_oh%notfound;

         l_stageloc := null;
         zloc.get_stage_loc(lp.facility, oh.loadno, oh.stopno, oh.orderid, oh.shipid,
               l_stageloc, l_loadloc, l_msg);
         l_loc := nvl(l_loadloc, l_stageloc);

         open c_loc(lp.facility, l_loc);
         fetch c_loc into l_seq;
         if c_loc%notfound then
            l_seq := MAX_SEQ;
         end if;
         close c_loc;

         i := xord.count+1;
         xord(i).orderid := oh.orderid;
         xord(i).shipid := oh.shipid;
         xord(i).loadno := oh.loadno;
         xord(i).stopno := oh.stopno;
         xord(i).shipno := oh.shipno;
         xord(i).loc := l_loc;
         xord(i).seq := abs(l_curseq-l_seq);
         xord(i).needed := oh.qtyorder-oh.qtypick;
      end loop;
      close c_oh;

      if xord.count = 0 then
         return;
      end if;

      for sp in (select distinct loadno, stopno, orderid, shipid  -- all current picks
                  from shippingplate
                  where facility = lp.facility
                    and location = lp.location
                    and status = 'P'
                    and type = 'F') loop
         l_stageloc := null;
         zloc.get_stage_loc(lp.facility, sp.loadno, sp.stopno, sp.orderid, sp.shipid,
               l_stageloc, l_loadloc, l_msg);
         l_loc := nvl(l_loadloc, l_stageloc);

         l_found := false;
         for i in 1..dest.count loop
            if nvl(dest(i).loc,'(none)') = nvl(l_loc,'(none)') then
               l_found := true;
               exit;
            end if;
         end loop;

         if not l_found then
            i := dest.count+1;
            dest(i).loc := l_loc;
         end if;
      end loop;

      pick.delete;
      pick(IX_CLOSE).seq := MAX_SEQ+1;
      pick(IX_CLOSE).ix := 0;
      pick(IX_NEED).seq := MAX_SEQ+1;
      pick(IX_NEED).ix := 0;
      pick(IX_PK_CLOSE).seq := MAX_SEQ+1;
      pick(IX_PK_CLOSE).ix := 0;
      pick(IX_PK_NEED).seq := MAX_SEQ+1;
      pick(IX_PK_NEED).ix := 0;

      for i in 1..xord.count loop
         -- closest
         if xord(i).seq < pick(IX_CLOSE).seq then
            pick(IX_CLOSE).seq := xord(i).seq;
            pick(IX_CLOSE).ix := i;
         end if;
         -- closest and needed
         if (xord(i).seq < pick(IX_NEED).seq) and (xord(i).needed > 0) then
            pick(IX_NEED).seq := xord(i).seq;
            pick(IX_NEED).ix := i;
         end if;
         if dest.count != 0 then    -- user has picks
            for j in 1..dest.count loop
               if xord(i).loc = dest(j).loc then
                  -- closest and picked
                  if xord(i).seq < pick(IX_PK_CLOSE).seq then
                     pick(IX_PK_CLOSE).seq := xord(i).seq;
                     pick(IX_PK_CLOSE).ix := i;
                  end if;
                  -- closest and needed and picked
                  if (xord(i).seq < pick(IX_PK_NEED).seq) and (xord(i).needed > 0) then
                     pick(IX_PK_NEED).seq := xord(i).seq;
                     pick(IX_PK_NEED).ix := i;
                  end if;
                  exit;
               end if;
            end loop;
         end if;
      end loop;

      if pick(IX_PK_NEED).ix != 0 then
         i := pick(IX_PK_NEED).ix;
      elsif pick(IX_NEED).ix != 0 then
         i := pick(IX_NEED).ix;
      elsif pick(IX_PK_CLOSE).ix != 0 then
         i := pick(IX_PK_CLOSE).ix;
      else
         i := pick(IX_CLOSE).ix;
      end if;
   end if;
   build_pick(i);

   if (out_err = 'N') and (dest.count != 0) then
      l_found := false;
      for j in 1..dest.count loop
         if nvl(xord(i).loc,'(none)') = nvl(dest(j).loc,'(none)') then
            l_found := true;
            exit;
         end if;
      end loop;

      if not l_found then
         out_err := '?';
      end if;
   end if;

exception
   when OTHERS then
      out_err := 'Y';
      out_msg := substr(sqlerrm, 1, 80);
end add_xdock_plate;


procedure update_xdock_plate
   (in_lpid   in varchar2,
    in_userid in varchar2,
    out_msg   out varchar2)
is
   cursor c_lp(p_lpid varchar2) is
      select PL.quantity as quantity,
             PL.weight as weight,
             PL.qtyentered as qtyentered,
             PL.custid as custid,
             PL.item as item,
             PL.lotnumber as lotnumber,
             PL.unitofmeasure as unitofmeasure,
             OH.ordertype as ordertype
         from plate PL, orderhdr OH
         where PL.lpid = p_lpid
           and OH.orderid (+) = PL.orderid
           and OH.shipid (+) = PL.shipid;
   lp c_lp%rowtype := null;
   l_orderid shippingplate.orderid%type;
   l_shipid shippingplate.shipid%type;
begin
   out_msg := null;

   open c_lp(in_lpid);
   fetch c_lp into lp;
   close c_lp;
   if nvl(lp.ordertype,'?') = 'C' then
      update shippingplate
         set quantity = lp.quantity,
             weight = lp.weight,
             qtyentered = lp.qtyentered,
             lastuser = in_userid,
             lastupdate = sysdate
         where fromlpid = in_lpid
           and type = 'F'
           and status = 'P'
         returning orderid, shipid
         into l_orderid, l_shipid;
      update orderdtl
         set qtypick = nvl(qtypick,0) + lp.quantity,
             weightpick = nvl(weightpick,0) + lp.weight,
             cubepick = nvl(cubepick,0)
                  + (lp.quantity*zci.item_cube(lp.custid, lp.item, lp.unitofmeasure)),
             amtpick = nvl(amtpick,0) + (lp.quantity*zci.item_amt(lp.custid, orderid, shipid, lp.item, lotnumber)) --prn 25133
         where orderid = l_orderid
           and shipid = l_shipid
           and item = lp.item
           and nvl(lotnumber,'(none)') = nvl(lp.lotnumber,'(none)');
   end if;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end update_xdock_plate;


procedure check_for_active_crossdock
   (in_lpid   in varchar2,
    out_dest  out varchar2,
    out_msg   out varchar2)
is
   cursor c_sp(p_fromlpid varchar2) is
      select SP.facility as facility,
             SP.loadno as loadno,
             SP.stopno as stopno,
             SP.orderid as orderid,
             SP.shipid as shipid,
             OH.xdockorderid as xdockorderid
         from shippingplate SP, orderhdr OH
         where SP.fromlpid = p_fromlpid
           and SP.type = 'F'
           and SP.status = 'P'
           and OH.orderid (+) = SP.orderid
           and OH.shipid (+) = SP.shipid;
   sp c_sp%rowtype := null;
   l_stageloc location.locid%type := null;
   l_loadloc location.locid%type := null;
   l_msg varchar2(255) := null;
begin
   out_dest := null;
   out_msg := 'N/A';

   open c_sp(in_lpid);
   fetch c_sp into sp;
   close c_sp;
   if sp.xdockorderid is not null then
      out_msg := 'OKAY';
      zloc.get_stage_loc(sp.facility, sp.loadno, sp.stopno, sp.orderid, sp.shipid,
            l_stageloc, l_loadloc, l_msg);
      if l_msg is not null then
         out_msg := l_msg;
      elsif l_loadloc is not null then
         out_dest := l_loadloc;
      else
         out_dest := l_stageloc;
      end if;
   end if;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end check_for_active_crossdock;


end zcrossdock;
/

show errors package body zcrossdock;
exit;
