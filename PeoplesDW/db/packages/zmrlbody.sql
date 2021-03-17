create or replace PACKAGE BODY alps.zmasterreceiptlimits
IS
--
-- $Id$
--

CURSOR C_ORD(in_orderid number, in_shipid number)
IS
SELECT *
  FROM orderhdr
 WHERE orderid = in_orderid
   AND shipid = in_shipid;

CURSOR C_CUST(in_custid varchar2)
IS
SELECT *
  FROM customer
 WHERE custid = in_custid;

CURSOR C_MPO(in_custid varchar2, in_po  varchar2)
IS
SELECT *
  FROM orderhdr
 WHERE po = in_po
   AND custid = in_custid
   AND ordertype = 'A';

CURSOR C_ORDDTL(in_orderid number, in_shipid number, in_item varchar2,
              in_lot varchar2)
IS
SELECT *
  FROM orderdtl
 WHERE orderid = in_orderid
   AND shipid = in_shipid
   AND item = in_item
   AND nvl(lotnumber,'(none)') = nvl(in_lot,'(none)');


----------------------------------------------------------------------
PROCEDURE check_master_limits
(
    in_orderid      IN  number,
    in_shipid       IN  number,
    in_check_type   IN  varchar2,   -- A-Assignment, C-Close
    out_msg         OUT varchar2
)
IS

ORD orderhdr%rowtype;
MPO orderhdr%rowtype;
CUST customer%rowtype;

MPODTL orderdtl%rowtype;

itm_tot number;
errlist varchar2(1000);
BEGIN
    out_msg := 'OKAY';

    ORD := null;
    OPEN C_ORD(in_orderid, in_shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

-- Can't violate limits if no the correct order type
    if ORD.orderid is null or nvl(ORD.ordertype,'x') != 'R' then
        return;
    end if;

    CUST := null;
    OPEN C_CUST(ORD.custid);
    FETCH C_CUST into CUST;
    CLOSE C_CUST;

    if CUST.custid is null or nvl(CUST.masterreceiptlimits,'N') != 'Y' then
        return;
    end if;

-- Read master PO
    MPO := null;
    OPEN C_ORD(ORD.parentorderid, ORD.parentshipid);
    FETCH C_ORD into MPO;
    CLOSE C_ORD;
--    OPEN C_MPO(ORD.custid, ORD.po);
--    FETCH C_MPO into MPO;
--    CLOSE C_MPO;

    if MPO.orderid is null then
        return;
    end if;

    errlist := '';

    for citm in (select *
                   from orderdtl
                  where orderid = in_orderid
                    and shipid = in_shipid)
    loop

    -- Find Master Detail Record
        MPODTL := null;
        OPEN C_ORDDTL(MPO.orderid, MPO.shipid,citm.item,citm.lotnumber);
        FETCH C_ORDDTL into MPODTL;
        CLOSE C_ORDDTL;
        if MPODTL.orderid is null then
            errlist := errlist || ',' || ' Item:'||citm.item
                ||'/'||citm.lotnumber||' not on master';
            goto Continue;
        end if;

    -- Total the outstanding orders for this master
        itm_tot := 0;

        begin
            select sum(decode(H.orderstatus,
                    'R', nvl(D.qtyrcvd,0)
                       , greatest(nvl(D.qtyorder,0), nvl(D.qtyrcvd,0))))
              into itm_tot
             from orderdtl D, orderhdr H
            where H.parentorderid = MPO.orderid
              and H.parentshipid = MPO.shipid
              and D.orderid = H.orderid
              and D.shipid = H.shipid
              and D.item = MPODTL.item
              and nvl(D.lotnumber,'(none)') = nvl(MPODTL.lotnumber,'(none)')
              and not (H.orderid = in_orderid
                        and H.shipid = in_shipid)
              and H.orderstatus != 'X'
              and H.orderstatus = decode(in_check_type,'C','R',H.orderstatus)
              and NVL(H.loadno,0) != 0;

            -- zut.prt('Item Tot:'||itm_tot);
        exception when others then
                itm_tot := 0;
        end;
        itm_tot := nvl(itm_tot,0);

        if in_check_type = 'A' then
            itm_tot := itm_tot + citm.qtyorder;
        else
            itm_tot := itm_tot + citm.qtyrcvd;
        end if;

        if itm_tot > nvl(MPODTL.qtyorder,0) then
            errlist := errlist || ',' || ' Item:'||citm.item
                ||'/'||citm.lotnumber||' exceeds master qty of '
                || nvl(MPODTL.qtyorder,0);
        end if;


<< Continue >>
        null;

    end loop;

    if errlist is not null then
        out_msg := substr(errlist,2);
    end if;



END check_master_limits;

----------------------------------------------------------------------
PROCEDURE set_master_receipt
(
    in_orderid      IN  number,
    in_shipid       IN  number,
    out_msg         OUT varchar2
)
IS
ORD orderhdr%rowtype;
MPO orderhdr%rowtype;
CUST customer%rowtype;

MPODTL orderdtl%rowtype;

errmsg varchar2(255);

BEGIN
    out_msg := 'OKAY';

    -- read order
    ORD := null;
    OPEN C_ORD(in_orderid, in_shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

-- Can't process if not valid PO receipt order
    if ORD.orderid is null or nvl(ORD.ordertype,'x') != 'R'
     or nvl(ORD.orderstatus,'0') = 'X'
     or ORD.po is null then
        return;
    end if;

    CUST := null;
    OPEN C_CUST(ORD.custid);
    FETCH C_CUST into CUST;
    CLOSE C_CUST;

    if CUST.custid is null or nvl(CUST.masterreceiptlimits,'N') != 'Y' then
        return;
    end if;

    MPO := null;


    -- If already has parentorderid verify master po
    if ORD.parentorderid is not null then
        MPO := null;
        OPEN C_ORD(ORD.parentorderid, ORD.parentshipid);
        FETCH C_ORD into MPO;
        CLOSE C_ORD;

        if MPO.orderid is null then
            out_msg := 'Invalid parentorderid';
            return;
        end if;

        if MPO.ordertype != 'A' then
            out_msg := 'Invalid parentorder type';
            return;
        end if;

        if nvl(MPO.po,'xxx') != ORD.po then
            out_msg := 'Invalid parentorder po doesnot match';
            return;
        end if;

    else
        MPO := null;
        OPEN C_MPO(ORD.custid, ORD.po);
        FETCH C_MPO into MPO;
        CLOSE C_MPO;

    end if;

    if MPO.orderid is null then
    -- clone and create the new master receipt

        zoe.get_next_orderid(MPO.orderid,out_msg);
        if substr(out_msg,1,4) != 'OKAY' then
            out_msg := 'Can not create orderid for master receipt';
            return;
        end if;
        MPO.shipid := 1;

        zcl.clone_receipt_order(in_orderid, in_shipid, null, 'IMPORT',
            MPO.orderid, MPO.shipid, errmsg);

        if errmsg != 'OKAY' then
            out_msg := 'Can not create orderid for master receipt';
            return;
        end if;

        update orderhdr
           set ordertype = 'A',
               orderstatus = '0',
               parentorderid = null,
               parentshipid = null
         where orderid = MPO.orderid
           and shipid = MPO.shipid;

        update orderhdr
           set parentorderid = MPO.orderid,
               parentshipid = MPO.shipid
         where orderid = in_orderid
           and shipid = in_shipid;

        return;
    end if;


  update orderhdr
     set
         apptdate = ORD.apptdate,
         shipdate = ORD.shipdate,
         shipto = ORD.shipto,
         billoflading = ORD.billoflading,
         priority = ORD.priority,
         shipper = ORD.shipper,
         consignee = ORD.consignee,
         shiptype = ORD.shiptype,
         carrier = ORD.carrier,
         shipterms = ORD.shipterms,
         shippername = ORD.shippername,
         shippercontact = ORD.shippercontact,
         shipperaddr1 = ORD.shipperaddr1,
         shipperaddr2 = ORD.shipperaddr2,
         shippercity = ORD.shippercity,
         shipperstate = ORD.shipperstate,
         shipperpostalcode = ORD.shipperpostalcode,
         shippercountrycode = ORD.shippercountrycode,
         shipperphone = ORD.shipperphone,
         shipperfax = ORD.shipperfax,
         shipperemail = ORD.shipperemail,
         shiptoname = ORD.shiptoname,
         shiptocontact = ORD.shiptocontact,
         shiptoaddr1 = ORD.shiptoaddr1,
         shiptoaddr2 = ORD.shiptoaddr2,
         shiptocity = ORD.shiptocity,
         shiptostate = ORD.shiptostate,
         shiptopostalcode = ORD.shiptopostalcode,
         shiptocountrycode = ORD.shiptocountrycode,
         shiptophone = ORD.shiptophone,
         shiptofax = ORD.shiptofax,
         shiptoemail = ORD.shiptoemail,
         billtoname = ORD.billtoname,
         billtocontact = ORD.billtocontact,
         billtoaddr1 = ORD.billtoaddr1,
         billtoaddr2 = ORD.billtoaddr2,
         billtocity = ORD.billtocity,
         billtostate = ORD.billtostate,
         billtopostalcode = ORD.billtopostalcode,
         billtocountrycode = ORD.billtocountrycode,
         billtophone = ORD.billtophone,
         billtofax = ORD.billtofax,
         billtoemail = ORD.billtoemail,
         deliveryservice = ORD.deliveryservice,
         saturdaydelivery = ORD.saturdaydelivery,
         cod = ORD.cod,
         amtcod = ORD.amtcod,
         specialservice1 = ORD.specialservice1,
         specialservice2 = ORD.specialservice2,
         specialservice3 = ORD.specialservice3,
         specialservice4 = ORD.specialservice4,
         lastuser = ORD.lastuser,
         lastupdate = ORD.lastupdate,
         hdrpassthruchar01 = ORD.hdrpassthruchar01,
         hdrpassthruchar02 = ORD.hdrpassthruchar02,
         hdrpassthruchar03 = ORD.hdrpassthruchar03,
         hdrpassthruchar04 = ORD.hdrpassthruchar04,
         hdrpassthruchar05 = ORD.hdrpassthruchar05,
         hdrpassthruchar06 = ORD.hdrpassthruchar06,
         hdrpassthruchar07 = ORD.hdrpassthruchar07,
         hdrpassthruchar08 = ORD.hdrpassthruchar08,
         hdrpassthruchar09 = ORD.hdrpassthruchar09,
         hdrpassthruchar10 = ORD.hdrpassthruchar10,
         hdrpassthruchar11 = ORD.hdrpassthruchar11,
         hdrpassthruchar12 = ORD.hdrpassthruchar12,
         hdrpassthruchar13 = ORD.hdrpassthruchar13,
         hdrpassthruchar14 = ORD.hdrpassthruchar14,
         hdrpassthruchar15 = ORD.hdrpassthruchar15,
         hdrpassthruchar16 = ORD.hdrpassthruchar16,
         hdrpassthruchar17 = ORD.hdrpassthruchar17,
         hdrpassthruchar18 = ORD.hdrpassthruchar18,
         hdrpassthruchar19 = ORD.hdrpassthruchar19,
         hdrpassthruchar20 = ORD.hdrpassthruchar20,
         hdrpassthrunum01 = ORD.hdrpassthrunum01,
         hdrpassthrunum02 = ORD.hdrpassthrunum02,
         hdrpassthrunum03 = ORD.hdrpassthrunum03,
         hdrpassthrunum04 = ORD.hdrpassthrunum04,
         hdrpassthrunum05 = ORD.hdrpassthrunum05,
         hdrpassthrunum06 = ORD.hdrpassthrunum06,
         hdrpassthrunum07 = ORD.hdrpassthrunum07,
         hdrpassthrunum08 = ORD.hdrpassthrunum08,
         hdrpassthrunum09 = ORD.hdrpassthrunum09,
         hdrpassthrunum10 = ORD.hdrpassthrunum10,
         importfileid = ORD.importfileid,
         cancel_after = ORD.cancel_after,
         delivery_requested = ORD.delivery_requested,
         requested_ship = ORD.requested_ship,
         ship_not_before = ORD.ship_not_before,
         ship_no_later = ORD.ship_no_later,
         cancel_if_not_delivered_by = ORD.cancel_if_not_delivered_by,
         do_not_deliver_after = ORD.do_not_deliver_after,
         do_not_deliver_before = ORD.do_not_deliver_before,
         hdrpassthrudate01 = ORD.hdrpassthrudate01,
         hdrpassthrudate02 = ORD.hdrpassthrudate02,
         hdrpassthrudate03 = ORD.hdrpassthrudate03,
         hdrpassthrudate04 = ORD.hdrpassthrudate04,
         hdrpassthrudoll01 = ORD.hdrpassthrudoll01,
         hdrpassthrudoll02 = ORD.hdrpassthrudoll02,
         rfautodisplay = ORD.rfautodisplay
   where orderid = MPO.orderid
     and shipid = MPO.shipid;




    for cod in (select *
                  from orderdtl
                 where orderid = in_orderid
                   and shipid = in_shipid)
    loop
    -- Find Master Detail Record
        MPODTL := null;
        OPEN C_ORDDTL(MPO.orderid, MPO.shipid,cod.item,cod.lotnumber);
        FETCH C_ORDDTL into MPODTL;
        CLOSE C_ORDDTL;
        if MPODTL.orderid is null then
    -- clone orderdtl
            zcl.clone_orderdtl(in_orderid, in_shipid, cod.item, cod.lotnumber,
                      MPO.orderid, MPO.shipid, cod.item, cod.lotnumber,
                   null, 'IMPORDER', errmsg);

            update  orderdtl
               set  linestatus = 'A',
                    commitstatus = null,
                    qtycommit = null,
                    weightcommit = null,
                    cubecommit = null,
                    amtcommit = null,
                    qtyship = null,
                    weightship = null,
                    cubeship = null,
                    amtship = null,
                    qtytotcommit = null,
                    weighttotcommit = null,
                    cubetotcommit = null,
                    amttotcommit = null,
                    qtyrcvd = null,
                    weightrcvd = null,
                    cubercvd = null,
                    amtrcvd = null,
                    qtyrcvdgood = null,
                    weightrcvdgood = null,
                    cubercvdgood = null,
                    amtrcvdgood = null,
                    qtyrcvddmgd = null,
                    weightrcvddmgd = null,
                    cubercvddmgd = null,
                    amtrcvddmgd = null,
                    qtypick = null,
                    weightpick = null,
                    cubepick = null,
                    amtpick = null,
                    childorderid = null,
                    childshipid = null,
                    staffhrs = null,
                    qty2sort = null,
                    weight2sort = null,
                    cube2sort = null,
                    amt2sort = null,
                    qty2pack = null,
                    weight2pack = null,
                    cube2pack = null,
                    amt2pack = null,
                    qty2check = null,
                    weight2check = null,
                    cube2check = null,
                    amt2check = null,
                    asnvariance = null
             where orderid = MPO.orderid
               and shipid = MPO.shipid
               and item = cod.item
               and nvl(lotnumber,'(none)') = nvl(cod.lotnumber,'(none)');

            zcl.clone_table_row('ORDERDTLBOLCOMMENTS',
                'ORDERID = '||in_orderid||' and SHIPID = '||in_shipid
                    ||' and ITEM = '''||cod.item||''''
                    ||' and nvl(LOTNUMBER,''(none)'') = '''
                        ||nvl(cod.lotnumber,'(none)')||'''',
                MPO.orderid||','||MPO.shipid||','''||cod.item
                    ||''','''||cod.lotnumber||'''',
                'ORDERID,SHIPID,ITEM,LOTNUMBER',
                null,
                'IMPORDER',
                errmsg);
            goto continue;
        end if;

        -- update OD in master receipt
        update orderdtl
           set uomentered = cod.uomentered,
               qtyentered = cod.qtyentered,
               uom = cod.uom,
               qtyorder = cod.qtyorder,
               weightorder = cod.weightorder,
               cubeorder = cod.cubeorder,
               amtorder = cod.amtorder,
               backorder = cod.backorder,
               allowsub = cod.allowsub,
               qtytype = cod.qtytype,
               invstatusind = cod.invstatusind,
               invstatus = cod.invstatus,
               invclassind = cod.invclassind,
               inventoryclass = cod.inventoryclass,
               consigneesku = cod.consigneesku,
               lastuser = cod.lastuser,
               lastupdate = cod.lastupdate,
               dtlpassthruchar01 = cod.dtlpassthruchar01,
               dtlpassthruchar02 = cod.dtlpassthruchar02,
               dtlpassthruchar03 = cod.dtlpassthruchar03,
               dtlpassthruchar04 = cod.dtlpassthruchar04,
               dtlpassthruchar05 = cod.dtlpassthruchar05,
               dtlpassthruchar06 = cod.dtlpassthruchar06,
               dtlpassthruchar07 = cod.dtlpassthruchar07,
               dtlpassthruchar08 = cod.dtlpassthruchar08,
               dtlpassthruchar09 = cod.dtlpassthruchar09,
               dtlpassthruchar10 = cod.dtlpassthruchar10,
               dtlpassthruchar11 = cod.dtlpassthruchar11,
               dtlpassthruchar12 = cod.dtlpassthruchar12,
               dtlpassthruchar13 = cod.dtlpassthruchar13,
               dtlpassthruchar14 = cod.dtlpassthruchar14,
               dtlpassthruchar15 = cod.dtlpassthruchar15,
               dtlpassthruchar16 = cod.dtlpassthruchar16,
               dtlpassthruchar17 = cod.dtlpassthruchar17,
               dtlpassthruchar18 = cod.dtlpassthruchar18,
               dtlpassthruchar19 = cod.dtlpassthruchar19,
               dtlpassthruchar20 = cod.dtlpassthruchar20,
               dtlpassthrunum01 = cod.dtlpassthrunum01,
               dtlpassthrunum02 = cod.dtlpassthrunum02,
               dtlpassthrunum03 = cod.dtlpassthrunum03,
               dtlpassthrunum04 = cod.dtlpassthrunum04,
               dtlpassthrunum05 = cod.dtlpassthrunum05,
               dtlpassthrunum06 = cod.dtlpassthrunum06,
               dtlpassthrunum07 = cod.dtlpassthrunum07,
               dtlpassthrunum08 = cod.dtlpassthrunum08,
               dtlpassthrunum09 = cod.dtlpassthrunum09,
               dtlpassthrunum10 = cod.dtlpassthrunum10,
               dtlpassthrudate01 = cod.dtlpassthrudate01,
               dtlpassthrudate02 = cod.dtlpassthrudate02,
               dtlpassthrudate03 = cod.dtlpassthrudate03,
               dtlpassthrudate04 = cod.dtlpassthrudate04,
               dtlpassthrudoll01 = cod.dtlpassthrudoll01,
               dtlpassthrudoll02 = cod.dtlpassthrudoll02,
               rfautodisplay = cod.rfautodisplay
         where orderid = MPO.orderid
           and shipid = MPO.shipid
           and item = cod.item
           and nvl(lotnumber,'(none)') = nvl(cod.lotnumber,'(none)');



<<continue>>
        null;
    end loop;


END set_master_receipt;

end zmasterreceiptlimits;
/

exit;
