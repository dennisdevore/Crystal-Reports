create or replace package body alps.zimportprocconsref as
--
-- $Id$
--

IMP_USERID constant varchar2(8) := 'IMPORDER';

last_orderid    orderhdr.orderid%type := 0;
last_shipid    orderhdr.shipid%type := 0;
last_error     char(1) := 'N';

last_custid     orderhdr.custid%type := '';
last_reference  orderhdr.reference%type := '';

out_msg varchar2(255);

FUNCTION gen_ref(in_ref1 varchar2, in_ref2 varchar2, in_ref3 varchar2,
    in_sep varchar2)
RETURN varchar2
IS
l_ref varchar2(20);
len integer;
BEGIN
    len := 0;

    if rtrim(in_ref1) is not null then
        l_ref := substr(rtrim(in_ref1),1,20);
    end if;
    if rtrim(in_ref2) is not null then
        l_ref := substr(l_ref || rtrim(in_sep) || rtrim(in_ref2),1,20);
    end if;
    if rtrim(in_ref3) is not null then
        l_ref := substr(l_ref || rtrim(in_sep) || rtrim(in_ref3),1,20);
    end if;

    return l_ref;
END;




----------------------------------------------------------------------
--
-- cref_import_order_header
--
----------------------------------------------------------------------
PROCEDURE cref_import_order_header
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_ref_cmp1 IN varchar2
,in_ref_cmp2 IN varchar2
,in_ref_cmp3 IN varchar2
,in_ref_seperator IN varchar2
,in_ordertype IN varchar2
,in_apptdate IN date
,in_shipdate IN date
,in_po IN varchar2
,in_rma IN varchar2
,in_fromfacility IN varchar2
,in_tofacility IN varchar2
,in_shipto IN varchar2
,in_billoflading IN varchar2
,in_priority IN varchar2
,in_shipper IN varchar2
,in_consignee IN varchar2
,in_shiptype IN varchar2
,in_carrier IN varchar2
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
,in_cod in varchar2
,in_amtcod in number
,in_specialservice1 in varchar2
,in_specialservice2 in varchar2
,in_specialservice3 in varchar2
,in_specialservice4 in varchar2
,in_importfileid IN varchar2
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
,in_cancel_after IN date
,in_delivery_requested IN date
,in_requested_ship IN date
,in_ship_not_before IN date
,in_ship_no_later IN date
,in_cancel_if_not_delivered_by IN date
,in_do_not_deliver_after IN date
,in_do_not_deliver_before IN date
,in_hdrpassthrudate01 date
,in_hdrpassthrudate02 date
,in_hdrpassthrudate03 date
,in_hdrpassthrudate04 date
,in_hdrpassthrudoll01 number
,in_hdrpassthrudoll02 number
,in_rfautodisplay varchar2
,in_ignore_received_orders_yn varchar2
,in_arrivaldate IN date
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
IS
    l_ref varchar2(20);
    l_shiptoaddr2 varchar2(40);
    l_shipdate date;

BEGIN

    l_ref := gen_ref(in_ref_cmp1, in_ref_cmp2, in_ref_cmp3,
                in_ref_seperator);


    l_shiptoaddr2 := in_shiptoaddr2;
    if rtrim(l_shiptoaddr2) = rtrim(in_shiptocity) then
        l_shiptoaddr2 := null;
    end if;

    l_shipdate := in_shipdate;
    if l_shipdate is not null
    and trunc(l_shipdate) < trunc(sysdate) then
        l_shipdate := trunc(sysdate);
    end if;


    zimp.import_order_header(
            in_func,
            in_custid,
            in_ordertype,
            in_apptdate,
            l_shipdate,         -- in_shipdate,
            in_po,
            in_rma,
            in_fromfacility,
            in_tofacility,
            in_shipto,
            in_billoflading,
            in_priority,
            in_shipper,
            in_consignee,
            in_shiptype,
            in_carrier,
            l_ref,              -- in_reference,
            in_shipterms,
            in_shippername,
            in_shippercontact,
            in_shipperaddr1,
            in_shipperaddr2,
            in_shippercity,
            in_shipperstate,
            in_shipperpostalcode,
            in_shippercountrycode,
            in_shipperphone,
            in_shipperfax,
            in_shipperemail,
            in_shiptoname,
            in_shiptocontact,
            in_shiptoaddr1,
            l_shiptoaddr2,
            in_shiptocity,
            in_shiptostate,
            in_shiptopostalcode,
            in_shiptocountrycode,
            in_shiptophone,
            in_shiptofax,
            in_shiptoemail,
            in_billtoname,
            in_billtocontact,
            in_billtoaddr1,
            in_billtoaddr2,
            in_billtocity,
            in_billtostate,
            in_billtopostalcode,
            in_billtocountrycode,
            in_billtophone,
            in_billtofax,
            in_billtoemail,
            in_deliveryservice,
            in_saturdaydelivery,
            in_cod,
            in_amtcod,
            in_specialservice1,
            in_specialservice2,
            in_specialservice3,
            in_specialservice4,
            in_importfileid,
            in_hdrpassthruchar01,
            in_hdrpassthruchar02,
            in_hdrpassthruchar03,
            in_hdrpassthruchar04,
            in_hdrpassthruchar05,
            in_hdrpassthruchar06,
            in_hdrpassthruchar07,
            in_hdrpassthruchar08,
            in_hdrpassthruchar09,
            in_hdrpassthruchar10,
            in_hdrpassthruchar11,
            in_hdrpassthruchar12,
            in_hdrpassthruchar13,
            in_hdrpassthruchar14,
            in_hdrpassthruchar15,
            in_hdrpassthruchar16,
            in_hdrpassthruchar17,
            in_hdrpassthruchar18,
            in_hdrpassthruchar19,
            in_hdrpassthruchar20,
            null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,
            in_hdrpassthrunum01,
            in_hdrpassthrunum02,
            in_hdrpassthrunum03,
            in_hdrpassthrunum04,
            in_hdrpassthrunum05,
            in_hdrpassthrunum06,
            in_hdrpassthrunum07,
            in_hdrpassthrunum08,
            in_hdrpassthrunum09,
            in_hdrpassthrunum10,
            in_cancel_after,
            in_delivery_requested,
            in_requested_ship,
            in_ship_not_before,
            in_ship_no_later,
            in_cancel_if_not_delivered_by,
            in_do_not_deliver_after,
            in_do_not_deliver_before,
            in_hdrpassthrudate01,
            in_hdrpassthrudate02,
            in_hdrpassthrudate03,
            in_hdrpassthrudate04,
            in_hdrpassthrudoll01,
            in_hdrpassthrudoll02,
            in_rfautodisplay,
            in_ignore_received_orders_yn,
            in_arrivaldate,
            null,
            null, --in_abc_revision
            null, --in_prono
            null,null,null,null,null,null,null,null,null,null,null,null,null,
            out_orderid,
            out_shipid,
            out_errorno,
            out_msg
    );

END;


----------------------------------------------------------------------
--
-- cref_import_order_line
--
----------------------------------------------------------------------
PROCEDURE cref_import_order_line
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_ref_cmp1 IN varchar2
,in_ref_cmp2 IN varchar2
,in_ref_cmp3 IN varchar2
,in_ref_seperator IN varchar2
,in_po IN varchar2
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
,in_rfautodisplay varchar2
,in_comment  long
,in_weight_entered_lbs number
,in_weight_entered_kgs number
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
IS
  l_ref varchar2(20);
BEGIN

    l_ref := gen_ref(in_ref_cmp1, in_ref_cmp2, in_ref_cmp3,
                in_ref_seperator);

    zimp.import_order_line(
            in_func,
            in_custid,
            l_ref,              -- in_reference,
            in_po,
            in_itementered,
            in_lotnumber,
            in_uomentered,
            in_qtyentered,
            in_backorder,
            in_allowsub,
            in_qtytype,
            in_invstatusind,
            in_invstatus,
            in_invclassind,
            in_inventoryclass,
            in_consigneesku,
            in_dtlpassthruchar01,
            in_dtlpassthruchar02,
            in_dtlpassthruchar03,
            in_dtlpassthruchar04,
            in_dtlpassthruchar05,
            in_dtlpassthruchar06,
            in_dtlpassthruchar07,
            in_dtlpassthruchar08,
            in_dtlpassthruchar09,
            in_dtlpassthruchar10,
            in_dtlpassthruchar11,
            in_dtlpassthruchar12,
            in_dtlpassthruchar13,
            in_dtlpassthruchar14,
            in_dtlpassthruchar15,
            in_dtlpassthruchar16,
            in_dtlpassthruchar17,
            in_dtlpassthruchar18,
            in_dtlpassthruchar19,
            in_dtlpassthruchar20,
            null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,
            in_dtlpassthrunum01,
            in_dtlpassthrunum02,
            in_dtlpassthrunum03,
            in_dtlpassthrunum04,
            in_dtlpassthrunum05,
            in_dtlpassthrunum06,
            in_dtlpassthrunum07,
            in_dtlpassthrunum08,
            in_dtlpassthrunum09,
            in_dtlpassthrunum10,
            null,null,null,null,null,null,null,null,null,null,
            in_dtlpassthrudate01,
            in_dtlpassthrudate02,
            in_dtlpassthrudate03,
            in_dtlpassthrudate04,
            in_dtlpassthrudoll01,
            in_dtlpassthrudoll02,
            in_rfautodisplay,
            in_comment,
            in_weight_entered_lbs,
            in_weight_entered_kgs,
            null,
            null,
            null,
            null, --in_abc_revision
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,null,
            out_orderid,
            out_shipid,
            out_errorno,
            out_msg
    );
END;


----------------------------------------------------------------------
--
-- cref_import_ord_hdr_instruct
--
----------------------------------------------------------------------
PROCEDURE cref_import_ord_hdr_instruct
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_ref_cmp1 IN varchar2
,in_ref_cmp2 IN varchar2
,in_ref_cmp3 IN varchar2
,in_ref_seperator IN varchar2
,in_po IN varchar2
,in_instructions IN long
,in_include_cr_lf_yn IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
IS
  l_ref varchar2(20);
BEGIN

    l_ref := gen_ref(in_ref_cmp1, in_ref_cmp2, in_ref_cmp3,
                in_ref_seperator);

    zimp.import_order_header_instruct(
            in_func,
            in_custid,
            l_ref,          -- in_reference,
            in_po,
            in_instructions,
            in_include_cr_lf_yn,
            null, --in_abc_revision
            out_orderid,
            out_shipid,
            out_errorno,
            out_msg
    );


END;


----------------------------------------------------------------------
--
-- cref_import_ord_hdr_bolcomment
--
----------------------------------------------------------------------
PROCEDURE cref_import_ord_hdr_bolcomment
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_ref_cmp1 IN varchar2
,in_ref_cmp2 IN varchar2
,in_ref_cmp3 IN varchar2
,in_ref_seperator IN varchar2
,in_po IN varchar2
,in_bolcomment IN long
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
IS
  l_ref varchar2(20);
BEGIN

    l_ref := gen_ref(in_ref_cmp1, in_ref_cmp2, in_ref_cmp3,
                in_ref_seperator);

    zimp.import_order_header_bolcomment(
            in_func,
            in_custid,
            l_ref,              --in_reference,
            in_po,
            in_bolcomment,
            null, --in_abc_revision
            out_orderid,
            out_shipid,
            out_errorno,
            out_msg
    );

END;


----------------------------------------------------------------------
--
-- cref_import_ord_ln_instruct
--
----------------------------------------------------------------------
PROCEDURE cref_import_ord_ln_instruct
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_ref_cmp1 IN varchar2
,in_ref_cmp2 IN varchar2
,in_ref_cmp3 IN varchar2
,in_ref_seperator IN varchar2
,in_po IN varchar2
,in_itementered IN varchar2
,in_lotnumber IN varchar2
,in_instructions IN long
,in_include_cr_lf_yn IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
IS
  l_ref varchar2(20);
BEGIN

    l_ref := gen_ref(in_ref_cmp1, in_ref_cmp2, in_ref_cmp3,
                in_ref_seperator);

    zimp.import_order_line_instruct(
        in_func,
        in_custid,
        l_ref,              -- in_reference,
        in_po,
        in_itementered,
        in_lotnumber,
        in_instructions,
        in_include_cr_lf_yn,
        null, --in_abc_revision
        out_orderid,
        out_shipid,
        out_errorno,
        out_msg
    );


END;


----------------------------------------------------------------------
--
-- cref_import_ord_ln_bolcomment
--
----------------------------------------------------------------------
PROCEDURE cref_import_ord_ln_bolcomment
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_ref_cmp1 IN varchar2
,in_ref_cmp2 IN varchar2
,in_ref_cmp3 IN varchar2
,in_ref_seperator IN varchar2
,in_po IN varchar2
,in_itementered IN varchar2
,in_lotnumber IN varchar2
,in_bolcomment IN long
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
IS
  l_ref varchar2(20);
BEGIN

    l_ref := gen_ref(in_ref_cmp1, in_ref_cmp2, in_ref_cmp3,
                in_ref_seperator);


    zimp.import_order_line_bolcomment(
        in_func,
        in_custid,
        l_ref,              -- in_reference,
        in_po,
        in_itementered,
        in_lotnumber,
        in_bolcomment,
        null, --in_abc_revision
        out_orderid,
        out_shipid,
        out_errorno,
        out_msg
    );


END;



----------------------------------------------------------------------
--
-- cref_import_order_seq_comment
--
----------------------------------------------------------------------
PROCEDURE cref_import_order_seq_comment
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_ref_cmp1 IN varchar2
,in_ref_cmp2 IN varchar2
,in_ref_cmp3 IN varchar2
,in_ref_seperator IN varchar2
,in_po IN varchar2
,in_sequence IN number
,in_comment IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
IS
  l_ref varchar2(20);
BEGIN

    l_ref := gen_ref(in_ref_cmp1, in_ref_cmp2, in_ref_cmp3,
                in_ref_seperator);

    zimp.import_order_seq_comment(
        in_func,
        in_custid,
        l_ref,              -- in_reference,
        in_po,
        in_sequence,
        in_comment,
        out_orderid,
        out_shipid,
        out_errorno,
        out_msg
    );


END;


----------------------------------------------------------------------
--
-- cref_import_order_trailer
--
----------------------------------------------------------------------
PROCEDURE cref_import_order_trailer
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_ref_cmp1 IN varchar2
,in_ref_cmp2 IN varchar2
,in_ref_cmp3 IN varchar2
,in_ref_seperator IN varchar2
,in_ordertype IN varchar2
,in_apptdate IN date
,in_shipdate IN date
,in_po IN varchar2
,in_rma IN varchar2
,in_fromfacility IN varchar2
,in_tofacility IN varchar2
,in_shipto IN varchar2
,in_billoflading IN varchar2
,in_priority IN varchar2
,in_shipper IN varchar2
,in_consignee IN varchar2
,in_shiptype IN varchar2
,in_carrier IN varchar2
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
,in_cod in varchar2
,in_amtcod in number
,in_specialservice1 in varchar2
,in_specialservice2 in varchar2
,in_specialservice3 in varchar2
,in_specialservice4 in varchar2
,in_importfileid IN varchar2
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
,in_cancel_after IN date
,in_delivery_requested IN date
,in_requested_ship IN date
,in_ship_not_before IN date
,in_ship_no_later IN date
,in_cancel_if_not_delivered_by IN date
,in_do_not_deliver_after IN date
,in_do_not_deliver_before IN date
,in_hdrpassthrudate01 date
,in_hdrpassthrudate02 date
,in_hdrpassthrudate03 date
,in_hdrpassthrudate04 date
,in_hdrpassthrudoll01 number
,in_hdrpassthrudoll02 number
,in_rfautodisplay varchar2
,in_ignore_received_orders_yn varchar2
,in_arrivaldate IN DATE
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
IS
  l_ref varchar2(20);

  l_shipdate date;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(l_ref) || ': ' || out_msg;
  zms.log_msg(IMP_USERID, nvl(in_fromfacility,in_tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;


BEGIN

    l_ref := gen_ref(in_ref_cmp1, in_ref_cmp2, in_ref_cmp3,
                in_ref_seperator);


    if in_func = 'A' then
        in_func := 'U';
    end if;

    if in_func in ('D','R') then
        out_errorno := 1;
        out_msg := 'Invalid Function Code';
        order_msg('E');
        return;
    end if;


    l_shipdate := in_shipdate;
    if l_shipdate is not null
    and trunc(l_shipdate) < trunc(sysdate) then
        l_shipdate := trunc(sysdate);
    end if;


    zimp.import_order_header(
            in_func,
            in_custid,
            in_ordertype,
            in_apptdate,
            l_shipdate,         -- in_shipdate,
            in_po,
            in_rma,
            in_fromfacility,
            in_tofacility,
            in_shipto,
            in_billoflading,
            in_priority,
            in_shipper,
            in_consignee,
            in_shiptype,
            in_carrier,
            l_ref,              -- in_reference,
            in_shipterms,
            in_shippername,
            in_shippercontact,
            in_shipperaddr1,
            in_shipperaddr2,
            in_shippercity,
            in_shipperstate,
            in_shipperpostalcode,
            in_shippercountrycode,
            in_shipperphone,
            in_shipperfax,
            in_shipperemail,
            in_shiptoname,
            in_shiptocontact,
            in_shiptoaddr1,
            in_shiptoaddr2,
            in_shiptocity,
            in_shiptostate,
            in_shiptopostalcode,
            in_shiptocountrycode,
            in_shiptophone,
            in_shiptofax,
            in_shiptoemail,
            in_billtoname,
            in_billtocontact,
            in_billtoaddr1,
            in_billtoaddr2,
            in_billtocity,
            in_billtostate,
            in_billtopostalcode,
            in_billtocountrycode,
            in_billtophone,
            in_billtofax,
            in_billtoemail,
            in_deliveryservice,
            in_saturdaydelivery,
            in_cod,
            in_amtcod,
            in_specialservice1,
            in_specialservice2,
            in_specialservice3,
            in_specialservice4,
            in_importfileid,
            in_hdrpassthruchar01,
            in_hdrpassthruchar02,
            in_hdrpassthruchar03,
            in_hdrpassthruchar04,
            in_hdrpassthruchar05,
            in_hdrpassthruchar06,
            in_hdrpassthruchar07,
            in_hdrpassthruchar08,
            in_hdrpassthruchar09,
            in_hdrpassthruchar10,
            in_hdrpassthruchar11,
            in_hdrpassthruchar12,
            in_hdrpassthruchar13,
            in_hdrpassthruchar14,
            in_hdrpassthruchar15,
            in_hdrpassthruchar16,
            in_hdrpassthruchar17,
            in_hdrpassthruchar18,
            in_hdrpassthruchar19,
            in_hdrpassthruchar20,
            null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,
            in_hdrpassthrunum01,
            in_hdrpassthrunum02,
            in_hdrpassthrunum03,
            in_hdrpassthrunum04,
            in_hdrpassthrunum05,
            in_hdrpassthrunum06,
            in_hdrpassthrunum07,
            in_hdrpassthrunum08,
            in_hdrpassthrunum09,
            in_hdrpassthrunum10,
            in_cancel_after,
            in_delivery_requested,
            in_requested_ship,
            in_ship_not_before,
            in_ship_no_later,
            in_cancel_if_not_delivered_by,
            in_do_not_deliver_after,
            in_do_not_deliver_before,
            in_hdrpassthrudate01,
            in_hdrpassthrudate02,
            in_hdrpassthrudate03,
            in_hdrpassthrudate04,
            in_hdrpassthrudoll01,
            in_hdrpassthrudoll02,
            in_rfautodisplay,
            in_ignore_received_orders_yn,
            in_arrivaldate,
            null,
            null, --in_abc_revision
            null, --in_prono
            null,null,null,null,null,null,null,null,null,null,null,null,null,
            out_orderid,
            out_shipid,
            out_errorno,
            out_msg
    );

END;



end zimportprocconsref;
/
show errors package body zimportprocconsref;
exit;

