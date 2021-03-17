create or replace package body alps.zimportprocspreadsheet as
--
-- $Id$
--

IMP_USERID constant varchar2(8) := 'IMPORDER';

last_orderid    orderhdr.orderid%type := 0;
last_shipid    orderhdr.shipid%type := 0;
last_error     char(1) := 'N';

last_custid     orderhdr.custid%type := '';
last_reference  orderhdr.reference%type := '';

FUNCTION scac_to_carrier
(in_scac    varchar2)
RETURN varchar2
IS
CURSOR C_CARR
IS
SELECT carrier
  FROM alps.carrier
 WHERE scac = in_scac;

    l_carr  varchar2(4);
BEGIN
    l_carr := NULL;

    OPEN C_CARR;
    FETCH C_CARR INTO l_carr;
    CLOSE C_CARR;

    return l_carr;

END scac_to_carrier;



----------------------------------------------------------------------
--
-- SS_import_order
--
----------------------------------------------------------------------
procedure SS_import_order
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_fromfacility varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_consignee IN varchar2
,in_shipdate  IN date
,in_shipterms IN varchar2
,in_shiptype  IN varchar2
,in_carrier IN varchar2
,in_itementered IN varchar2
,in_lotnumber IN varchar2
,in_uomentered IN varchar2
,in_qtyentered IN number
,in_delivery_date IN date
,in_importfileid IN varchar2
,in_weight_entered_lbs number
,in_weight_entered_kgs number
,in_variance_pct_shortage number
,in_variance_pct_overage number
,in_variance_use_default_yn varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
IS

cnt number;

CURSOR C_ORD(in_orderid number,
             in_shipid number)
IS
SELECT *
  FROM orderhdr
 WHERE custid = in_custid
   AND reference = in_reference;

CURSOR C_ORDREF(in_custid varchar2,
             in_reference varchar2)
IS
SELECT *
  FROM orderhdr
 WHERE custid = in_custid
   AND reference = in_reference;

ORD orderhdr%rowtype;


procedure order_msg(in_msgtype varchar2) is
pragma autonomous_transaction;
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_msg(IMP_USERID, in_fromfacility, rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
  commit;

end;

BEGIN
    out_errorno := 0;
    out_msg := '';
    out_orderid := 0;
    out_shipid := 0;

-- Verify function
    if nvl(in_func,'XX') not in ('A','U','D','R') then
        out_errorno := 4;
        out_msg := 'Invalid function code.';
        order_msg('E');
        return;
    end if;

-- Verify cust_ref
    if in_reference is null then
        out_errorno := 4;
        out_msg := 'Customer reference must be provided';
        order_msg('E');
        return;
    end if;

-- Check for last order processed
    ORD := null;
    OPEN C_ORD(last_orderid, last_shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

-- If have previous order and next line for same order don't call header


    if (in_func in ('A','U','R')
     and (nvl(ORD.custid, 'xx') != in_custid
        or nvl(ORD.reference,'xx') != in_reference))
     or (in_func = 'D' and in_itementered is null) then


      zimp.import_order_header(
        in_func, in_custid,'O',null, in_shipdate, in_po, null,
        in_fromfacility, null, in_consignee, null, 'N',
        null,null,in_shiptype, upper(in_carrier),in_reference,
        in_shipterms,
        null,null,null,null,null,null,null,null,null,null,null,
--        in_shiptoname,in_shiptocontact,in_shiptoaddr1,in_shiptoaddr2,
--        in_shiptocity, upper(in_shiptostate), l_postalcode,
--        'USA',null,null,null,
        null,null,null,null,null,null,null,null,null,null,null,

        null,null,null,null,null,null,null,null,null,null,null,
        null,null,null,null,null,null,null,null,
              upper(rtrim(in_importfileid)),

 -- PTC01
         null,null,null,null,null,null,null,null,null,null,
         null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,
        null,null,null,null,null,null,null,null,null,null,
        null,null,null,null,null,null,null,null,null,null,
        null,null,null,null,null,null,null,null,null,null,
        null,null,null,null,null,null,null,null,null,null,

        null,null,null,null,null,null,null,null,
        null,null,null,null,null,null,null, -- HPTDates
        null,null, -- HPTDolls
        NULL,NULL,null,null,null,null,
         null,null,null,null,null,null,null,null,null,null,null,null,null,
        out_orderid, out_shipid, out_errorno, out_msg
      );

    -- If fails send response
      if out_errorno <> 0 then
        return;
      end if;

      if in_func = 'D' then
        return;
      end if;

    end if;


-- Add/Update/Cancel the shipment order

   -- Add order or update it

    zimp.import_order_line(
            in_func,in_custid,in_reference,in_po, in_itementered,in_lotnumber,
            in_uomentered,in_qtyentered,null,null,null,
            null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,null,null,null,
            in_weight_entered_lbs,in_weight_entered_kgs,
            in_variance_pct_shortage, in_variance_pct_overage, in_variance_use_default_yn,null,null,null,
            null,null,null,null,null,null,null,null,null,null,null,null,null,null,
            out_orderid, out_shipid, out_errorno, out_msg
    );


    if out_errorno != 0 then
        return;
    end if;




END SS_import_order;




----------------------------------------------------------------------
--
-- ss_process_orders
--
----------------------------------------------------------------------
procedure ss_process_orders
(
in_importfileid IN      varchar2,
in_userid       IN      varchar2,
out_errorno     IN OUT  number,
out_msg         IN OUT  varchar2
)
IS


BEGIN

    out_errorno := 0;
    out_msg := '';

-- Verify customer

-- Remove orders from hold
    for crec in (select orderid, shipid
                   from orderhdr
                  where importfileid = rtrim(upper(in_importfileid)))
    loop

        zimp.release_and_commit_order(crec.orderid, crec.shipid,
                out_errorno, out_msg);

    end loop;


    last_orderid := 0;
    last_shipid := 0;


EXCEPTION WHEN OTHERS THEN
  out_msg := 'sspo ' || sqlerrm;
  out_errorno := sqlcode;
END ss_process_orders;




----------------------------------------------------------------------
--
-- spreadsheet_import_order
--
----------------------------------------------------------------------

procedure spreadsheet_import_order
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_apptdate IN date
,in_shipdate  IN date
,in_po IN varchar2
,in_rma IN varchar2
,in_fromfacility IN varchar2
,in_shipto IN varchar2
,in_billoflading IN varchar2
,in_priority IN varchar2
,in_shipper IN varchar2
,in_consignee IN varchar2
,in_shiptype IN varchar2
,in_carrier IN varchar2
,in_reference IN varchar2
,in_shipterms IN varchar2
,in_shiptoname IN varchar2
,in_shiptocontact IN varchar2
,in_shiptoaddr1 IN varchar2
,in_shiptoaddr2 IN varchar2
,in_shiptocity IN varchar2
,in_shiptostate IN varchar2
,in_shiptopostalcode IN varchar2
,in_shiptocountrycode IN varchar2
,in_shiptophone IN varchar2
,in_shiptofax IN varchar2
,in_shiptoemail IN varchar2
,in_billtoname IN varchar2
,in_billtocontact IN varchar2
,in_billtoaddr1 IN varchar2
,in_billtoaddr2 IN varchar2
,in_billtocity IN varchar2
,in_billtostate IN varchar2
,in_billtopostalcode IN varchar2
,in_billtocountrycode IN varchar2
,in_billtophone IN varchar2
,in_billtofax IN varchar2
,in_billtoemail IN varchar2
,in_deliveryservice IN varchar2
,in_saturdaydelivery IN varchar2
,in_cod IN varchar2
,in_amtcod IN number
,in_specialservice1 IN varchar2
,in_specialservice2 IN varchar2
,in_specialservice3 IN varchar2
,in_specialservice4 IN varchar2
,in_cancel_after IN date
,in_delivery_requested IN date
,in_requested_ship IN date
,in_ship_not_before IN date
,in_ship_no_later IN date
,in_cancel_if_not_delivered_by IN date
,in_do_not_deliver_after IN date
,in_do_not_deliver_before IN date
,in_rfautodisplay varchar2
,in_ignore_received_orders_yn varchar2
,in_hdrpassthruchar01 IN varchar2
,in_hdrpassthruchar02 IN varchar2
,in_hdrpassthruchar03 IN varchar2
,in_hdrpassthruchar04 IN varchar2
,in_hdrpassthruchar05 IN varchar2
,in_hdrpassthruchar06 IN varchar2
,in_hdrpassthruchar07 IN varchar2
,in_hdrpassthruchar08 IN varchar2
,in_hdrpassthruchar09 IN varchar2
,in_hdrpassthruchar10 IN varchar2
,in_hdrpassthruchar11 IN varchar2
,in_hdrpassthruchar12 IN varchar2
,in_hdrpassthruchar13 IN varchar2
,in_hdrpassthruchar14 IN varchar2
,in_hdrpassthruchar15 IN varchar2
,in_hdrpassthruchar16 IN varchar2
,in_hdrpassthruchar17 IN varchar2
,in_hdrpassthruchar18 IN varchar2
,in_hdrpassthruchar19 IN varchar2
,in_hdrpassthruchar20 IN varchar2
,in_hdrpassthruchar21 IN varchar2
,in_hdrpassthruchar22 IN varchar2
,in_hdrpassthruchar23 IN varchar2
,in_hdrpassthruchar24 IN varchar2
,in_hdrpassthruchar25 IN varchar2
,in_hdrpassthruchar26 IN varchar2
,in_hdrpassthruchar27 IN varchar2
,in_hdrpassthruchar28 IN varchar2
,in_hdrpassthruchar29 IN varchar2
,in_hdrpassthruchar30 IN varchar2
,in_hdrpassthruchar31 IN varchar2
,in_hdrpassthruchar32 IN varchar2
,in_hdrpassthruchar33 IN varchar2
,in_hdrpassthruchar34 IN varchar2
,in_hdrpassthruchar35 IN varchar2
,in_hdrpassthruchar36 IN varchar2
,in_hdrpassthruchar37 IN varchar2
,in_hdrpassthruchar38 IN varchar2
,in_hdrpassthruchar39 IN varchar2
,in_hdrpassthruchar40 IN varchar2
,in_hdrpassthruchar41 IN varchar2
,in_hdrpassthruchar42 IN varchar2
,in_hdrpassthruchar43 IN varchar2
,in_hdrpassthruchar44 IN varchar2
,in_hdrpassthruchar45 IN varchar2
,in_hdrpassthruchar46 IN varchar2
,in_hdrpassthruchar47 IN varchar2
,in_hdrpassthruchar48 IN varchar2
,in_hdrpassthruchar49 IN varchar2
,in_hdrpassthruchar50 IN varchar2
,in_hdrpassthruchar51 IN varchar2
,in_hdrpassthruchar52 IN varchar2
,in_hdrpassthruchar53 IN varchar2
,in_hdrpassthruchar54 IN varchar2
,in_hdrpassthruchar55 IN varchar2
,in_hdrpassthruchar56 IN varchar2
,in_hdrpassthruchar57 IN varchar2
,in_hdrpassthruchar58 IN varchar2
,in_hdrpassthruchar59 IN varchar2
,in_hdrpassthruchar60 IN varchar2
,in_hdrpassthrunum01 IN number
,in_hdrpassthrunum02 IN number
,in_hdrpassthrunum03 IN number
,in_hdrpassthrunum04 IN number
,in_hdrpassthrunum05 IN number
,in_hdrpassthrunum06 IN number
,in_hdrpassthrunum07 IN number
,in_hdrpassthrunum08 IN number
,in_hdrpassthrunum09 IN number
,in_hdrpassthrunum10 IN number
,in_hdrpassthrudate01 date
,in_hdrpassthrudate02 date
,in_hdrpassthrudate03 date
,in_hdrpassthrudate04 date
,in_hdrpassthrudoll01 number
,in_hdrpassthrudoll02 number
,in_importfileid IN varchar2
,in_instructions varchar2
,in_include_cr_lf_yn varchar2
,in_bolcomment varchar2
,in_itementered IN varchar2
,in_lotnumber IN varchar2
,in_uomentered IN varchar2
,in_qtyentered IN number
,in_backorder IN varchar2
,in_allowsub IN varchar2
,in_qtytype IN varchar2
,in_invstatusind IN varchar2
,in_invstatus IN varchar2
,in_invclassind IN varchar2
,in_inventoryclass IN varchar2
,in_consigneesku IN varchar2
,in_dtlpassthruchar01 IN varchar2
,in_dtlpassthruchar02 IN varchar2
,in_dtlpassthruchar03 IN varchar2
,in_dtlpassthruchar04 IN varchar2
,in_dtlpassthruchar05 IN varchar2
,in_dtlpassthruchar06 IN varchar2
,in_dtlpassthruchar07 IN varchar2
,in_dtlpassthruchar08 IN varchar2
,in_dtlpassthruchar09 IN varchar2
,in_dtlpassthruchar10 IN varchar2
,in_dtlpassthruchar11 IN varchar2
,in_dtlpassthruchar12 IN varchar2
,in_dtlpassthruchar13 IN varchar2
,in_dtlpassthruchar14 IN varchar2
,in_dtlpassthruchar15 IN varchar2
,in_dtlpassthruchar16 IN varchar2
,in_dtlpassthruchar17 IN varchar2
,in_dtlpassthruchar18 IN varchar2
,in_dtlpassthruchar19 IN varchar2
,in_dtlpassthruchar20 IN varchar2
,in_dtlpassthruchar21 IN varchar2
,in_dtlpassthruchar22 IN varchar2
,in_dtlpassthruchar23 IN varchar2
,in_dtlpassthruchar24 IN varchar2
,in_dtlpassthruchar25 IN varchar2
,in_dtlpassthruchar26 IN varchar2
,in_dtlpassthruchar27 IN varchar2
,in_dtlpassthruchar28 IN varchar2
,in_dtlpassthruchar29 IN varchar2
,in_dtlpassthruchar30 IN varchar2
,in_dtlpassthruchar31 IN varchar2
,in_dtlpassthruchar32 IN varchar2
,in_dtlpassthruchar33 IN varchar2
,in_dtlpassthruchar34 IN varchar2
,in_dtlpassthruchar35 IN varchar2
,in_dtlpassthruchar36 IN varchar2
,in_dtlpassthruchar37 IN varchar2
,in_dtlpassthruchar38 IN varchar2
,in_dtlpassthruchar39 IN varchar2
,in_dtlpassthruchar40 IN varchar2
,in_dtlpassthrunum01 IN number
,in_dtlpassthrunum02 IN number
,in_dtlpassthrunum03 IN number
,in_dtlpassthrunum04 IN number
,in_dtlpassthrunum05 IN number
,in_dtlpassthrunum06 IN number
,in_dtlpassthrunum07 IN number
,in_dtlpassthrunum08 IN number
,in_dtlpassthrunum09 IN number
,in_dtlpassthrunum10 IN number
,in_dtlpassthrunum11 IN number
,in_dtlpassthrunum12 IN number
,in_dtlpassthrunum13 IN number
,in_dtlpassthrunum14 IN number
,in_dtlpassthrunum15 IN number
,in_dtlpassthrunum16 IN number
,in_dtlpassthrunum17 IN number
,in_dtlpassthrunum18 IN number
,in_dtlpassthrunum19 IN number
,in_dtlpassthrunum20 IN number
,in_dtlpassthrudate01 date
,in_dtlpassthrudate02 date
,in_dtlpassthrudate03 date
,in_dtlpassthrudate04 date
,in_dtlpassthrudoll01 number
,in_dtlpassthrudoll02 number
,in_dtlrfautodisplay varchar2
,in_dtlinstructions varchar2
,in_dtlbolcomment varchar2
,in_use_base_uom varchar2
,in_prono varchar2
,in_weight_entered_lbs number
,in_weight_entered_kgs number
,in_variance_pct_shortage number
,in_variance_pct_overage number
,in_variance_use_default_yn varchar2
,in_arrivaldate DATE
,in_validate_shipto in varchar2
,in_cancel_productgroup varchar2
,in_weight_productgroups varchar2
,in_cancel_item_eoi_yn IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
IS

cnt number;

CURSOR C_ORD(in_orderid number,
             in_shipid number)
IS
SELECT *
  FROM orderhdr
 WHERE custid = in_custid
   AND reference = in_reference
   AND 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
 ORDER BY orderstatus;

CURSOR C_ORDREF(in_custid varchar2,
             in_reference varchar2)
IS
SELECT *
  FROM orderhdr
 WHERE custid = in_custid
   AND reference = in_reference;

ORD orderhdr%rowtype;

CURSOR C_ITEM(in_custid varchar2, in_item varchar2)
IS
SELECT *
  FROM custitemview
 WHERE custid = in_custid
   AND item = in_item;

ITM C_ITEM%rowtype;

strItem custitem.item%type;
strLotRequired custitem.lotrequired%type;
strHazardous custitem.hazardous%type;
strIsKit custitem.IsKit%type;
strProductGroup custitem.productgroup%type;

l_uom custitem.baseuom%type;
l_qty number;
l_weight_entered_lbs number;
len integer;
pos integer;
cur integer;
pGroup varchar2(11);
pFound boolean;
l_cancel_productgroup varchar(255);

procedure delete_old_order(in_orderid number, in_shipid number) is
pragma autonomous_transaction;
begin
  delete from orderhdrbolcomments
   where orderid = in_orderid
     and shipid = in_shipid;
  delete from orderdtlbolcomments
   where orderid = in_orderid
     and shipid = in_shipid;
  delete from orderdtlline
   where orderid = in_orderid
     and shipid = in_shipid;
  delete from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid;
  delete from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
  commit;

end;


procedure order_msg(in_msgtype varchar2) is
pragma autonomous_transaction;
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_msg(IMP_USERID, in_fromfacility, rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
  commit;

end;

BEGIN
    out_errorno := 0;
    out_msg := '';
    out_orderid := 0;
    out_shipid := 0;

-- Verify function
    if nvl(in_func,'XX') not in ('A','U','D','R') then
        out_errorno := 4;
        out_msg := 'Invalid function code.';
        order_msg('E');
        return;
    end if;

-- Verify cust_ref
    if in_reference is null then
        out_errorno := 4;
        out_msg := 'Customer reference must be provided';
        order_msg('E');
        return;
    end if;

-- Check for last order processed
    ORD := null;
    OPEN C_ORD(last_orderid, last_shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;


    if rtrim(in_custid) = last_custid
    and rtrim(in_reference) = last_reference
    and last_error = 'Y' then
        return;
    end if;


    last_custid := rtrim(in_custid);
    last_reference := rtrim(in_reference);
    last_error := 'N';


-- Check if need UOM Conversion
        if rtrim(upper(in_use_base_uom)) = 'Y'
    and (nvl(ORD.orderstatus, '1') in ('1', '0')) then
        zci.get_customer_item(rtrim(in_custid),rtrim(in_itementered),strItem,
            strLotRequired,strHazardous,strIsKit,out_msg);
        if substr(out_msg,1,4) != 'OKAY' then
            last_error := 'Y';
            out_errorno := 8;
            out_msg := 'Invalid item.';
            order_msg('E');
            delete_old_order(ORD.orderid, ORD.shipid);
            return;
        end if;

        ITM := null;
        OPEN C_ITEM(in_custid, strItem);
        FETCH C_ITEM into ITM;
        CLOSE C_ITEM;
        if ITM.custid is null then
            last_error := 'Y';
            out_errorno := 8;
            out_msg := 'Invalid item.';
            order_msg('E');
            -- do not delete old order (PRN 7565))
            -- delete_old_order(ORD.orderid, ORD.shipid);
            return;
        end if;

        l_qty := zcu.equiv_uom_qty(in_custid,stritem,in_uomentered,
                in_qtyentered, ITM.baseuom);
        l_uom := ITM.baseuom;

        if l_qty != trunc(l_qty) then
            last_error := 'Y';
            out_errorno := 8;
            out_msg := 'Invalid UOM Qty. Item:'
                ||in_itementered||' Qty:'||in_qtyentered||' cannot convert to '
                || ITM.baseuom;
            order_msg('E');
            delete_old_order(ORD.orderid, ORD.shipid);
            return;
        end if;

    else
        l_uom := in_uomentered;
        l_qty := in_qtyentered;
    end if;

-- If have previous order and next line for same order don't call header

    if (in_func in ('A','U','R')
     and (nvl(ORD.custid, 'xx') != in_custid
        or nvl(ORD.reference,'xx') != in_reference))
     or (in_func = 'D' and in_itementered is null) then



   zimp.import_order_header(in_func,in_custid,'O',
    in_apptdate,in_shipdate,in_po,in_rma,
    in_fromfacility,null,in_shipto,in_billoflading,in_priority,in_shipper,
    in_consignee,in_shiptype,in_carrier,in_reference,in_shipterms,
    null,null,null,null,null,null,null,null,null,null,null, -- shipper
    in_shiptoname,in_shiptocontact,in_shiptoaddr1,in_shiptoaddr2,
    in_shiptocity,in_shiptostate,in_shiptopostalcode,
    in_shiptocountrycode,in_shiptophone,in_shiptofax,in_shiptoemail,
    in_billtoname,in_billtocontact,in_billtoaddr1,in_billtoaddr2,
    in_billtocity,in_billtostate,in_billtopostalcode,
    in_billtocountrycode,in_billtophone,in_billtofax,in_billtoemail,
    in_deliveryservice,in_saturdaydelivery,in_cod,in_amtcod,
    in_specialservice1,in_specialservice2,
    in_specialservice3,in_specialservice4,
    in_importfileid,
    in_hdrpassthruchar01,in_hdrpassthruchar02,
    in_hdrpassthruchar03,in_hdrpassthruchar04,
    in_hdrpassthruchar05,in_hdrpassthruchar06,
    in_hdrpassthruchar07,in_hdrpassthruchar08,
    in_hdrpassthruchar09,in_hdrpassthruchar10,
    in_hdrpassthruchar11,in_hdrpassthruchar12,
    in_hdrpassthruchar13,in_hdrpassthruchar14,
    in_hdrpassthruchar15,in_hdrpassthruchar16,
    in_hdrpassthruchar17,in_hdrpassthruchar18,
    in_hdrpassthruchar19,in_hdrpassthruchar20,
    in_hdrpassthruchar21,in_hdrpassthruchar22,
    in_hdrpassthruchar23,in_hdrpassthruchar24,
    in_hdrpassthruchar25,in_hdrpassthruchar26,
    in_hdrpassthruchar27,in_hdrpassthruchar28,
    in_hdrpassthruchar29,in_hdrpassthruchar30,
    in_hdrpassthruchar31,in_hdrpassthruchar32,
    in_hdrpassthruchar33,in_hdrpassthruchar34,
    in_hdrpassthruchar35,in_hdrpassthruchar36,
    in_hdrpassthruchar37,in_hdrpassthruchar38,
    in_hdrpassthruchar39,in_hdrpassthruchar40,
    in_hdrpassthruchar41,in_hdrpassthruchar42,
    in_hdrpassthruchar43,in_hdrpassthruchar44,
    in_hdrpassthruchar45,in_hdrpassthruchar46,
    in_hdrpassthruchar47,in_hdrpassthruchar48,
    in_hdrpassthruchar49,in_hdrpassthruchar50,
    in_hdrpassthruchar51,in_hdrpassthruchar52,
    in_hdrpassthruchar53,in_hdrpassthruchar54,
    in_hdrpassthruchar55,in_hdrpassthruchar56,
    in_hdrpassthruchar57,in_hdrpassthruchar58,
    in_hdrpassthruchar59,in_hdrpassthruchar60,
    in_hdrpassthrunum01,in_hdrpassthrunum02,
    in_hdrpassthrunum03,in_hdrpassthrunum04,
    in_hdrpassthrunum05,in_hdrpassthrunum06,
    in_hdrpassthrunum07,in_hdrpassthrunum08,
    in_hdrpassthrunum09,in_hdrpassthrunum10,
    in_cancel_after,in_delivery_requested,in_requested_ship,
    in_ship_not_before,in_ship_no_later,in_cancel_if_not_delivered_by,
    in_do_not_deliver_after,in_do_not_deliver_before,
    in_hdrpassthrudate01,in_hdrpassthrudate02,
    in_hdrpassthrudate03,in_hdrpassthrudate04,
    in_hdrpassthrudoll01,in_hdrpassthrudoll02,
    in_rfautodisplay,in_ignore_received_orders_yn,
    in_arrivaldate,in_validate_shipto, null, in_prono,
    null,null,null,null,null,null,null,null,null,null,null,null,null,
    out_orderid,out_shipid,out_errorno,out_msg);


--    zut.prt('After to call import order header:'||out_errorno
--        ||':'||out_msg);
--    zut.prt('Orderid:'||out_orderid||'/'||out_shipid);

    -- If fails send response
      if out_errorno <> 0 then
        last_orderid := out_orderid;
        last_shipid := out_shipid;
        last_custid := rtrim(in_custid);
        last_reference := rtrim(in_reference);
        last_error := 'Y';
        order_msg('E');
        return;
      end if;

      if in_func = 'D' then
        return;
      end if;

      if rtrim(in_instructions) is not null then
        zimp.import_order_header_instruct(in_func,in_custid,
            in_reference,in_po,in_instructions,in_include_cr_lf_yn, null, -- in_abc_revision
            out_orderid,out_shipid,out_errorno,out_msg);

      end if;
      if rtrim(in_bolcomment) is not null then
        zimp.import_order_header_bolcomment(in_func,in_custid,
            in_reference,in_po,in_bolcomment, null, -- in_abc_revision
            out_orderid,out_shipid,out_errorno,out_msg);

      end if;

    end if;
    l_weight_entered_lbs := nvl(in_weight_entered_lbs,0);

    if in_weight_productgroups is not null then
       begin
         select productgroup into strproductgroup
           from custitemview
            where custid = rtrim(in_custid)
             and item = in_itementered;
       exception when no_data_found then
          strproductgroup := 'zzzz';
    end;
       len := length(in_weight_productgroups);
        cur := 1;
       pFound := false;
       while cur < len loop
         pos := instr(in_weight_productgroups, ',', cur);
        if pos = 0 then
             pos := len + 1;
        end if;
         pGroup := substr(in_weight_productgroups,cur,pos - cur);
         cur := pos + 1;

        if pGroup = strproductgroup then
            pFound := true;
           cur := len + 1;
        end if;
    end loop;
       if pFound then
          l_weight_entered_lbs := l_qty;
          l_qty := 0;
       end if;
      end if;

    if nvl(in_cancel_item_eoi_yn,'N') = 'Y' then
       l_cancel_productgroup := null;
    else
       l_cancel_productgroup := in_cancel_productgroup;
    end if;


-- Add/Update/Cancel the shipment order

   -- Add order or update it

    zimp.import_order_line(in_func,in_custid,in_reference,in_po,
        in_itementered,in_lotnumber,
        l_uom, l_qty, -- in_uomentered,in_qtyentered,
        in_backorder,in_allowsub,in_qtytype,
        in_invstatusind,in_invstatus,in_invclassind,in_inventoryclass,
        in_consigneesku,
        in_dtlpassthruchar01,in_dtlpassthruchar02,
        in_dtlpassthruchar03,in_dtlpassthruchar04,
        in_dtlpassthruchar05,in_dtlpassthruchar06,
        in_dtlpassthruchar07,in_dtlpassthruchar08,
        in_dtlpassthruchar09,in_dtlpassthruchar10,
        in_dtlpassthruchar11,in_dtlpassthruchar12,
        in_dtlpassthruchar13,in_dtlpassthruchar14,
        in_dtlpassthruchar15,in_dtlpassthruchar16,
        in_dtlpassthruchar17,in_dtlpassthruchar18,
        in_dtlpassthruchar19,in_dtlpassthruchar20,
        in_dtlpassthruchar21,in_dtlpassthruchar22,
        in_dtlpassthruchar23,in_dtlpassthruchar24,
        in_dtlpassthruchar25,in_dtlpassthruchar26,
        in_dtlpassthruchar27,in_dtlpassthruchar28,
        in_dtlpassthruchar29,in_dtlpassthruchar30,
        in_dtlpassthruchar31,in_dtlpassthruchar32,
        in_dtlpassthruchar33,in_dtlpassthruchar34,
        in_dtlpassthruchar35,in_dtlpassthruchar36,
        in_dtlpassthruchar37,in_dtlpassthruchar38,
        in_dtlpassthruchar39,in_dtlpassthruchar40,
        in_dtlpassthrunum01,in_dtlpassthrunum02,
        in_dtlpassthrunum03,in_dtlpassthrunum04,
        in_dtlpassthrunum05,in_dtlpassthrunum06,
        in_dtlpassthrunum07,in_dtlpassthrunum08,
        in_dtlpassthrunum09,in_dtlpassthrunum10,
        in_dtlpassthrunum11,in_dtlpassthrunum12,
        in_dtlpassthrunum13,in_dtlpassthrunum14,
        in_dtlpassthrunum15,in_dtlpassthrunum16,
        in_dtlpassthrunum17,in_dtlpassthrunum18,
        in_dtlpassthrunum19,in_dtlpassthrunum20,
        in_dtlpassthrudate01,in_dtlpassthrudate02,
        in_dtlpassthrudate03,in_dtlpassthrudate04,
        in_dtlpassthrudoll01,in_dtlpassthrudoll02,
        in_dtlrfautodisplay,null,l_weight_entered_lbs, in_weight_entered_kgs,
        in_variance_pct_shortage, in_variance_pct_overage, in_variance_use_default_yn,
        null, -- in_abc_revision
        null,
        null,
        l_cancel_productgroup,
        null,
        null,
        null,
        null,
        null,
        null, null, null, null, null,null,null,null,
        out_orderid,out_shipid,out_errorno,out_msg);


    if out_errorno != 0 then
        last_orderid := out_orderid;
        last_shipid := out_shipid;
        last_custid := rtrim(in_custid);
        last_reference := rtrim(in_reference);
        last_error := 'Y';
        order_msg('E');
        return;
    end if;


    last_orderid := out_orderid;
    last_shipid := out_shipid;
    last_error := 'N';


    if rtrim(in_dtlinstructions) is not null then
        zimp.import_order_line_instruct(in_func,in_custid,in_reference,in_po,
            in_itementered,in_lotnumber,in_dtlinstructions,in_include_cr_lf_yn, null, -- in_abc_revision
            out_orderid,out_shipid,out_errorno,out_msg);
    end if;

    if rtrim(in_dtlbolcomment) is not null then
        zimp.import_order_line_bolcomment(in_func,in_custid,in_reference,in_po,
            in_itementered,in_lotnumber,in_dtlbolcomment, null, -- in_abc_revision
            out_orderid,out_shipid,out_errorno,out_msg);
    end if;


END spreadsheet_import_order;


----------------------------------------------------------------------
--
-- spreadsheet_import_receipt
--
----------------------------------------------------------------------

procedure spreadsheet_import_receipt
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_apptdate IN date
,in_shipdate  IN date
,in_po IN varchar2
,in_rma IN varchar2
,in_tofacility IN varchar2
,in_shipto IN varchar2
,in_billoflading IN varchar2
,in_priority IN varchar2
,in_shipper IN varchar2
,in_consignee IN varchar2
,in_shiptype IN varchar2
,in_carrier IN varchar2
,in_reference IN varchar2
,in_shipterms IN varchar2
,in_shippername IN varchar2
,in_shippercontact IN varchar2
,in_shipperaddr1 IN varchar2
,in_shipperaddr2 IN varchar2
,in_shippercity IN varchar2
,in_shipperstate IN varchar2
,in_shipperpostalcode IN varchar2
,in_shippercountrycode IN varchar2
,in_shipperphone IN varchar2
,in_shipperfax IN varchar2
,in_shipperemail IN varchar2
,in_shiptoname IN varchar2
,in_shiptocontact IN varchar2
,in_shiptoaddr1 IN varchar2
,in_shiptoaddr2 IN varchar2
,in_shiptocity IN varchar2
,in_shiptostate IN varchar2
,in_shiptopostalcode IN varchar2
,in_shiptocountrycode IN varchar2
,in_shiptophone IN varchar2
,in_shiptofax IN varchar2
,in_shiptoemail IN varchar2
,in_billtoname IN varchar2
,in_billtocontact IN varchar2
,in_billtoaddr1 IN varchar2
,in_billtoaddr2 IN varchar2
,in_billtocity IN varchar2
,in_billtostate IN varchar2
,in_billtopostalcode IN varchar2
,in_billtocountrycode IN varchar2
,in_billtophone IN varchar2
,in_billtofax IN varchar2
,in_billtoemail IN varchar2
,in_deliveryservice IN varchar2
,in_saturdaydelivery IN varchar2
,in_cod IN varchar2
,in_amtcod IN number
,in_specialservice1 IN varchar2
,in_specialservice2 IN varchar2
,in_specialservice3 IN varchar2
,in_specialservice4 IN varchar2
,in_cancel_after IN date
,in_delivery_requested IN date
,in_requested_ship IN date
,in_ship_not_before IN date
,in_ship_no_later IN date
,in_cancel_if_not_delivered_by IN date
,in_do_not_deliver_after IN date
,in_do_not_deliver_before IN date
,in_rfautodisplay varchar2
,in_ignore_received_orders_yn varchar2
,in_hdrpassthruchar01 IN varchar2
,in_hdrpassthruchar02 IN varchar2
,in_hdrpassthruchar03 IN varchar2
,in_hdrpassthruchar04 IN varchar2
,in_hdrpassthruchar05 IN varchar2
,in_hdrpassthruchar06 IN varchar2
,in_hdrpassthruchar07 IN varchar2
,in_hdrpassthruchar08 IN varchar2
,in_hdrpassthruchar09 IN varchar2
,in_hdrpassthruchar10 IN varchar2
,in_hdrpassthruchar11 IN varchar2
,in_hdrpassthruchar12 IN varchar2
,in_hdrpassthruchar13 IN varchar2
,in_hdrpassthruchar14 IN varchar2
,in_hdrpassthruchar15 IN varchar2
,in_hdrpassthruchar16 IN varchar2
,in_hdrpassthruchar17 IN varchar2
,in_hdrpassthruchar18 IN varchar2
,in_hdrpassthruchar19 IN varchar2
,in_hdrpassthruchar20 IN varchar2
,in_hdrpassthrunum01 IN number
,in_hdrpassthrunum02 IN number
,in_hdrpassthrunum03 IN number
,in_hdrpassthrunum04 IN number
,in_hdrpassthrunum05 IN number
,in_hdrpassthrunum06 IN number
,in_hdrpassthrunum07 IN number
,in_hdrpassthrunum08 IN number
,in_hdrpassthrunum09 IN number
,in_hdrpassthrunum10 IN number
,in_hdrpassthrudate01 date
,in_hdrpassthrudate02 date
,in_hdrpassthrudate03 date
,in_hdrpassthrudate04 date
,in_hdrpassthrudoll01 number
,in_hdrpassthrudoll02 number
,in_importfileid IN varchar2
,in_instructions varchar2
,in_include_cr_lf_yn varchar2
,in_bolcomment varchar2
,in_itementered IN varchar2
,in_lotnumber IN varchar2
,in_uomentered IN varchar2
,in_qtyentered IN number
,in_backorder IN varchar2
,in_allowsub IN varchar2
,in_qtytype IN varchar2
,in_invstatusind IN varchar2
,in_invstatus IN varchar2
,in_invclassind IN varchar2
,in_inventoryclass IN varchar2
,in_consigneesku IN varchar2
,in_dtlpassthruchar01 IN varchar2
,in_dtlpassthruchar02 IN varchar2
,in_dtlpassthruchar03 IN varchar2
,in_dtlpassthruchar04 IN varchar2
,in_dtlpassthruchar05 IN varchar2
,in_dtlpassthruchar06 IN varchar2
,in_dtlpassthruchar07 IN varchar2
,in_dtlpassthruchar08 IN varchar2
,in_dtlpassthruchar09 IN varchar2
,in_dtlpassthruchar10 IN varchar2
,in_dtlpassthruchar11 IN varchar2
,in_dtlpassthruchar12 IN varchar2
,in_dtlpassthruchar13 IN varchar2
,in_dtlpassthruchar14 IN varchar2
,in_dtlpassthruchar15 IN varchar2
,in_dtlpassthruchar16 IN varchar2
,in_dtlpassthruchar17 IN varchar2
,in_dtlpassthruchar18 IN varchar2
,in_dtlpassthruchar19 IN varchar2
,in_dtlpassthruchar20 IN varchar2
,in_dtlpassthrunum01 IN number
,in_dtlpassthrunum02 IN number
,in_dtlpassthrunum03 IN number
,in_dtlpassthrunum04 IN number
,in_dtlpassthrunum05 IN number
,in_dtlpassthrunum06 IN number
,in_dtlpassthrunum07 IN number
,in_dtlpassthrunum08 IN number
,in_dtlpassthrunum09 IN number
,in_dtlpassthrunum10 IN number
,in_dtlpassthrudate01 date
,in_dtlpassthrudate02 date
,in_dtlpassthrudate03 date
,in_dtlpassthrudate04 date
,in_dtlpassthrudoll01 number
,in_dtlpassthrudoll02 number
,in_dtlrfautodisplay varchar2
,in_dtlinstructions varchar2
,in_dtlbolcomment varchar2
,in_use_base_uom varchar2
,in_prono varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
IS

cnt number;

CURSOR C_ORD(in_orderid number,
             in_shipid number)
IS
SELECT *
  FROM orderhdr
 WHERE custid = in_custid
   AND reference = in_reference;

CURSOR C_ORDREF(in_custid varchar2,
             in_reference varchar2)
IS
SELECT *
  FROM orderhdr
 WHERE custid = in_custid
   AND reference = in_reference;

ORD orderhdr%rowtype;

CURSOR C_ITEM(in_custid varchar2, in_item varchar2)
IS
SELECT *
  FROM custitemview
 WHERE custid = in_custid
   AND item = in_item;

ITM C_ITEM%rowtype;

strItem custitem.item%type;
strLotRequired custitem.lotrequired%type;
strHazardous custitem.hazardous%type;
strIsKit custitem.IsKit%type;

l_uom custitem.baseuom%type;
l_qty number;

procedure delete_old_order(in_orderid number, in_shipid number) is
pragma autonomous_transaction;
begin
  delete from orderhdrbolcomments
   where orderid = in_orderid
     and shipid = in_shipid;
  delete from orderdtlbolcomments
   where orderid = in_orderid
     and shipid = in_shipid;
  delete from orderdtlline
   where orderid = in_orderid
     and shipid = in_shipid;
  delete from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid;
  delete from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
  commit;

end;


procedure order_msg(in_msgtype varchar2) is
pragma autonomous_transaction;
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_msg(IMP_USERID, in_tofacility, rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
  commit;

end;

BEGIN
    out_errorno := 0;
    out_msg := '';
    out_orderid := 0;
    out_shipid := 0;

-- Verify function
    if nvl(in_func,'XX') not in ('A','U','D','R') then
        out_errorno := 4;
        out_msg := 'Invalid function code.';
        order_msg('E');
        return;
    end if;

-- Verify cust_ref
    if in_reference is null then
        out_errorno := 4;
        out_msg := 'Customer reference must be provided';
        order_msg('E');
        return;
    end if;

-- Check for last order processed
    ORD := null;
    OPEN C_ORD(last_orderid, last_shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;


    if rtrim(in_custid) = last_custid
    and rtrim(in_reference) = last_reference
    and last_error = 'Y' then
        return;
    end if;


    last_custid := rtrim(in_custid);
    last_reference := rtrim(in_reference);
    last_error := 'N';


-- Check if need UOM Conversion
    if rtrim(upper(in_use_base_uom)) = 'Y' then
        zci.get_customer_item(rtrim(in_custid),rtrim(in_itementered),strItem,
            strLotRequired,strHazardous,strIsKit,out_msg);
        if substr(out_msg,1,4) != 'OKAY' then
            last_error := 'Y';
            out_errorno := 8;
            out_msg := 'Invalid item.';
            order_msg('E');
            delete_old_order(ORD.orderid, ORD.shipid);
            return;
        end if;

        ITM := null;
        OPEN C_ITEM(in_custid, strItem);
        FETCH C_ITEM into ITM;
        CLOSE C_ITEM;
        if ITM.custid is null then
            last_error := 'Y';
            out_errorno := 8;
            out_msg := 'Invalid item.';
            order_msg('E');
            delete_old_order(ORD.orderid, ORD.shipid);
            return;
        end if;

        l_qty := zcu.equiv_uom_qty(in_custid,stritem,in_uomentered,
                in_qtyentered, ITM.baseuom);
        l_uom := ITM.baseuom;

        if l_qty != trunc(l_qty) then
            last_error := 'Y';
            out_errorno := 8;
            out_msg := 'Invalid UOM Qty. Item:'
                ||in_itementered||' Qty:'||in_qtyentered||' cannot convert to '
                || ITM.baseuom;
            order_msg('E');
            delete_old_order(ORD.orderid, ORD.shipid);
            return;
        end if;

    else
        l_uom := in_uomentered;
        l_qty := in_qtyentered;
    end if;

-- If have previous order and next line for same order don't call header

    if (in_func in ('A','U','R')
     and (nvl(ORD.custid, 'xx') != in_custid
        or nvl(ORD.reference,'xx') != in_reference))
     or (in_func = 'D' and in_itementered is null) then



   zimp.import_order_header(in_func,in_custid,'R',
    in_apptdate,in_shipdate,in_po,in_rma,
    null,in_tofacility,in_shipto,in_billoflading,in_priority,in_shipper,
    in_consignee,in_shiptype,in_carrier,in_reference,in_shipterms,
    in_shippername,in_shippercontact,in_shipperaddr1,in_shipperaddr2,
    in_shippercity,in_shipperstate,in_shipperpostalcode,
    in_shippercountrycode,in_shipperphone,in_shipperfax,in_shipperemail,
    in_shiptoname,in_shiptocontact,in_shiptoaddr1,in_shiptoaddr2,
    in_shiptocity,in_shiptostate,in_shiptopostalcode,
    in_shiptocountrycode,in_shiptophone,in_shiptofax,in_shiptoemail,
    in_billtoname,in_billtocontact,in_billtoaddr1,in_billtoaddr2,
    in_billtocity,in_billtostate,in_billtopostalcode,
    in_billtocountrycode,in_billtophone,in_billtofax,in_billtoemail,
    in_deliveryservice,in_saturdaydelivery,in_cod,in_amtcod,
    in_specialservice1,in_specialservice2,
    in_specialservice3,in_specialservice4,
    in_importfileid,
    in_hdrpassthruchar01,in_hdrpassthruchar02,
    in_hdrpassthruchar03,in_hdrpassthruchar04,
    in_hdrpassthruchar05,in_hdrpassthruchar06,
    in_hdrpassthruchar07,in_hdrpassthruchar08,
    in_hdrpassthruchar09,in_hdrpassthruchar10,
    in_hdrpassthruchar11,in_hdrpassthruchar12,
    in_hdrpassthruchar13,in_hdrpassthruchar14,
    in_hdrpassthruchar15,in_hdrpassthruchar16,
    in_hdrpassthruchar17,in_hdrpassthruchar18,
    in_hdrpassthruchar19,in_hdrpassthruchar20,
    null,null,null,null,null,null,null,null,null,null,
    null,null,null,null,null,null,null,null,null,null,
    null,null,null,null,null,null,null,null,null,null,
    null,null,null,null,null,null,null,null,null,null,
    in_hdrpassthrunum01,in_hdrpassthrunum02,
    in_hdrpassthrunum03,in_hdrpassthrunum04,
    in_hdrpassthrunum05,in_hdrpassthrunum06,
    in_hdrpassthrunum07,in_hdrpassthrunum08,
    in_hdrpassthrunum09,in_hdrpassthrunum10,
    in_cancel_after,in_delivery_requested,in_requested_ship,
    in_ship_not_before,in_ship_no_later,in_cancel_if_not_delivered_by,
    in_do_not_deliver_after,in_do_not_deliver_before,
    in_hdrpassthrudate01,in_hdrpassthrudate02,
    in_hdrpassthrudate03,in_hdrpassthrudate04,
    in_hdrpassthrudoll01,in_hdrpassthrudoll02,
    in_rfautodisplay,in_ignore_received_orders_yn,
    null,null,null,
    in_prono,
    null,null,null,null,null,null,null,null,null,null,null,null,null,
    out_orderid,out_shipid,out_errorno,out_msg);


--    zut.prt('After to call import order header:'||out_errorno
--        ||':'||out_msg);
--    zut.prt('Orderid:'||out_orderid||'/'||out_shipid);

    -- If fails send response
      if out_errorno <> 0 then
        last_orderid := out_orderid;
        last_shipid := out_shipid;
        last_custid := rtrim(in_custid);
        last_reference := rtrim(in_reference);
        last_error := 'Y';
        order_msg('E');
        return;
      end if;

      if in_func = 'D' then
        return;
      end if;

      if rtrim(in_instructions) is not null then
        zimp.import_order_header_instruct(in_func,in_custid,
            in_reference,in_po,in_instructions,in_include_cr_lf_yn,
            null,
            out_orderid,out_shipid,out_errorno,out_msg);

      end if;
      if rtrim(in_bolcomment) is not null then
        zimp.import_order_header_bolcomment(in_func,in_custid,
            in_reference,in_po,in_bolcomment,
            null,
            out_orderid,out_shipid,out_errorno,out_msg);

      end if;

    end if;


-- Add/Update/Cancel the shipment order

   -- Add order or update it

    zimp.import_order_line(in_func,in_custid,in_reference,in_po,
        in_itementered,in_lotnumber,
        l_uom, l_qty, -- in_uomentered,in_qtyentered,
        in_backorder,in_allowsub,in_qtytype,
        in_invstatusind,in_invstatus,in_invclassind,in_inventoryclass,
        in_consigneesku,
        in_dtlpassthruchar01,in_dtlpassthruchar02,
        in_dtlpassthruchar03,in_dtlpassthruchar04,
        in_dtlpassthruchar05,in_dtlpassthruchar06,
        in_dtlpassthruchar07,in_dtlpassthruchar08,
        in_dtlpassthruchar09,in_dtlpassthruchar10,
        in_dtlpassthruchar11,in_dtlpassthruchar12,
        in_dtlpassthruchar13,in_dtlpassthruchar14,
        in_dtlpassthruchar15,in_dtlpassthruchar16,
        in_dtlpassthruchar17,in_dtlpassthruchar18,
        in_dtlpassthruchar19,in_dtlpassthruchar20,
        null,null,null,null,null,null,null,null,null,null,
        null,null,null,null,null,null,null,null,null,null,
        in_dtlpassthrunum01,in_dtlpassthrunum02,
        in_dtlpassthrunum03,in_dtlpassthrunum04,
        in_dtlpassthrunum05,in_dtlpassthrunum06,
        in_dtlpassthrunum07,in_dtlpassthrunum08,
        in_dtlpassthrunum09,in_dtlpassthrunum10,
        null,null,null,null,null,null,null,null,null,null,
        in_dtlpassthrudate01,in_dtlpassthrudate02,
        in_dtlpassthrudate03,in_dtlpassthrudate04,
        in_dtlpassthrudoll01,in_dtlpassthrudoll02,
        in_dtlrfautodisplay,null,
        null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,
        null,null,null,null,null,
        out_orderid,out_shipid,out_errorno,out_msg);


    if out_errorno != 0 then
        last_orderid := out_orderid;
        last_shipid := out_shipid;
        last_custid := rtrim(in_custid);
        last_reference := rtrim(in_reference);
        last_error := 'Y';
        order_msg('E');
        return;
    end if;


    last_orderid := out_orderid;
    last_shipid := out_shipid;
    last_error := 'N';


    if rtrim(in_dtlinstructions) is not null then
        zimp.import_order_line_instruct(in_func,in_custid,in_reference,in_po,
            in_itementered,in_lotnumber,in_dtlinstructions,in_include_cr_lf_yn,
            null,
            out_orderid,out_shipid,out_errorno,out_msg);
    end if;

    if rtrim(in_dtlbolcomment) is not null then
        zimp.import_order_line_bolcomment(in_func,in_custid,in_reference,in_po,
            in_itementered,in_lotnumber,in_dtlbolcomment,
            null,
            out_orderid,out_shipid,out_errorno,out_msg);
    end if;


END spreadsheet_import_receipt;


----------------------------------------------------------------------
--
-- spreadsheet_process_orders
--
----------------------------------------------------------------------
procedure spreadsheet_process_orders
(
in_importfileid IN      varchar2,
in_userid       IN      varchar2,
in_cancel_productgroup IN varchar2,
out_errorno     IN OUT  number,
out_msg         IN OUT  varchar2
)
IS
cursor curItem(in_importfileid varchar2, in_orderid number, in_shipid number) is
select oh.custid, oh.orderid, oh.shipid,
       od.item, od.lotnumber, oh.fromfacility
  from orderhdr oh, orderdtl od
 where oh.orderid = od.orderid
   and oh.shipid = od.shipid
   and oh.orderid = in_orderid
   and oh.shipid = in_shipid;

cdat cdata;
strProductGroup custitem.productgroup%type;
strMsg varchar2(255);
l_count number;
l_value varchar2(10);

BEGIN

    out_errorno := 0;
    out_msg := '';

-- Verify customer

-- Remove orders from hold
    for crec in (select orderid, shipid
                   from orderhdr
                  where importfileid = rtrim(upper(in_importfileid)))
    loop
        if nvl(rtrim(in_cancel_productgroup),'zz') != 'zz' then
            for ci in curItem(in_importfileid, crec.orderid, crec.shipid)
            loop
                begin
                select nvl(productgroup,'zzzz') into strProductGroup
                  from custitemview
                 where custid = ci.custid
                   and item = ci.item;
                exception when others then
                  strProductGroup := 'zzzz';
                end;
                l_count := length(in_cancel_productgroup||',') - length(replace(in_cancel_productgroup, ',', ''));
                for i in 1 .. l_count loop
                  select regexp_substr(in_cancel_productgroup,'[^,]+', 1, i)
                  into l_value
                  from dual;
                  if strProductGroup = trim(l_value) then
                       zoe.cancel_item(ci.orderid,ci.shipid,ci.item, ci.lotnumber,
                                       ci.fromfacility,IMP_USERID,out_msg);
                     if substr(out_msg,1,4) != 'OKAY' and
                        substr(out_msg,1,19) != 'Item is not active:' then
                       zms.log_msg('ImpOrder', ci.fromfacility, ci.custid,
                         'Cancel Item: ' || ci.orderid || '-' || ci.shipid || ' ' ||
                         ci.item || ' ' || ci.lotnumber || ' ' ||
                         out_msg, 'E', IMP_USERID, strMsg);
                   end if;
                  end if;
                end loop;
            end loop;
        end if;

    -- Check here for special processing carrier determination
        cdat := zcus.init_cdata;

        cdat.orderid := crec.orderid;
        cdat.shipid := crec.shipid;
        zcus.execute('LDOP',cdat);

        if cdat.out_no != 0 then
            zut.prt('LDOP:'||cdat.out_char);
        end if;

        zimp.release_and_commit_order(crec.orderid, crec.shipid,
                out_errorno, out_msg);

        commit;
    -- Send pick_request
        if nvl(out_errorno,0) > 0 then
          zgp.pick_request('COMORD',null, null, 0, crec.orderid, crec.shipid,
            null, null, 0, null, null, null, out_errorno, out_msg);
        end if;

    end loop;

    zimp.end_of_import(last_custid, in_importfileid, in_userid,
        out_errorno, out_msg);

    last_orderid := 0;
    last_shipid := 0;
    last_custid := '';
    last_reference := '';
    last_error := 'N';



EXCEPTION WHEN OTHERS THEN
  out_msg := 'sspo ' || sqlerrm;
  out_errorno := sqlcode;
END spreadsheet_process_orders;

end zimportprocspreadsheet;
/
show errors package body zimportprocspreadsheet;
exit;

