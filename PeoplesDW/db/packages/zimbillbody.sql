create or replace package body alps.zimportprocbill as
--
-- $Id$
--

-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************
IMP_USERID constant varchar2(9) := 'IMPCHARGE';

-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************
  CURSOR C_FAC(in_facility varchar2)
  IS
    SELECT *
      FROM facility
     WHERE facility = in_facility;

  CURSOR C_CUST(in_custid varchar2)
  IS
    SELECT *
      FROM customer
     WHERE custid = in_custid;

  CURSOR C_LD(in_loadno number)
  IS
    SELECT *
      FROM loads
     WHERE loadno = in_loadno;

  CURSOR C_ORD(in_orderid number, in_shipid number)
  IS
    SELECT *
      FROM orderhdr
     WHERE orderid = in_orderid
       AND shipid = in_shipid;

  CURSOR C_INVH(in_invoice number)
  IS
    SELECT *
      FROM invoicehdr
     WHERE invoice = in_invoice;



-------------------------------------------------------------------------------
--   Internal Procedures and Functions
-------------------------------------------------------------------------------
procedure log_msg 
(in_facility in varchar2
,in_custid in varchar2
,in_invoice in varchar2
,in_orderid in varchar2
,in_shipid in varchar2
,in_loadno in varchar2
,in_msgtype in varchar2
,out_msg in out varchar2)
is
  strMsg appmsgs.msgtext%type;
begin
  if nvl(in_invoice, 0) != 0 then
    out_msg := 'Invoice: ' || in_invoice || ' ' || out_msg;
  end if;
  if nvl(in_orderid, 0) != 0 then
    out_msg := 'Order: ' || in_orderid || '-' || in_shipid || ' ' || out_msg;
  end if;
  if nvl(in_loadno, 0) != 0 then
    out_msg := 'Load: ' || in_loadno || ' ' || out_msg;
  end if;
  zms.log_autonomous_msg(IMP_USERID, in_facility, in_custid, out_msg, 
          nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end log_msg;
procedure validate_locate_invoicehdr
(
 in_facility in varchar2
,in_custid in varchar2
,in_invoice_type in varchar2
,in_charge_date in date
,in_loadno in number
,in_orderid in number
,in_shipid in number
,out_INVH IN OUT invoicehdr%rowtype
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
IS

FAC C_FAC%rowtype;
CUST C_CUST%rowtype;
INVH invoicehdr%rowtype;
LD loads%rowtype;
ORD orderhdr%rowtype;

  CURSOR C_CBD(in_custid varchar2)
  RETURN custbilldates%rowtype
  IS
    SELECT *
      FROM custbilldates
     WHERE custid = in_custid;

  CBD custbilldates%rowtype;

  CURSOR C_INVH_FIND(in_custid varchar2, in_effdate date, in_thrudate date)
  RETURN invoicehdr%rowtype
  IS
     SELECT *
       FROM invoicehdr
      WHERE custid = in_custid
        AND facility = in_facility
        AND invtype = zbill.IT_ACCESSORIAL
        AND invstatus = zbill.NOT_REVIEWED
        AND to_char(invdate,'YYYYMM') = to_char(in_effdate,'YYYYMM')
        AND in_thrudate = renewtodate
     ORDER BY invdate desc;

  invoice_id invoicehdr.invoice%type;

  CURSOR C_INVH_R
  IS
    SELECT *
      FROM invoicehdr
     WHERE facility = in_facility
       AND custid = in_custid
       AND invtype = 'R'
       AND loadno = in_loadno
    ORDER BY invstatus;

  CURSOR C_INVH_S
  IS
    SELECT *
      FROM invoicehdr
     WHERE facility = in_facility
       AND custid = in_custid
       AND invtype = 'S'
       AND invstatus = zbill.NOT_REVIEWED;

  rc integer;

  l_invoice invoicehdr.invoice%type;

BEGIN
  out_errorno := 0;
  out_msg := 'OKAY';
  l_invoice := out_INVH.invoice;

  out_INVH := null;

-- Validate Facility
    FAC := null;
    OPEN C_FAC(in_facility);
    FETCH C_FAC into FAC;
    CLOSE C_FAC;

    if FAC.facility is null then
        out_errorno := -1;
        out_msg := 'Invalid facility';
        log_msg(in_facility,in_custid,l_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
        return;
    end if;

-- Validate Custid
    CUST := null;
    OPEN C_CUST(in_custid);
    FETCH C_CUST into CUST;
    CLOSE C_CUST;

    if CUST.custid is null then
        out_errorno := -2;
        out_msg := 'Invalid customer';
        log_msg(in_facility,in_custid,l_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
        return;
    end if;

-- Validate invoice type
    if nvl(in_invoice_type,'x') not in ('R','A','S','M','C') then
        out_errorno := -3;
        out_msg := 'Invalid invoice type:'||nvl(in_invoice_type,'(NULL)');
        log_msg(in_facility,in_custid,l_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
    end if;

-- Read load/order if specified
    LD := null;
    if nvl(in_loadno, 0) > 0 then
        OPEN C_LD(in_loadno);
        FETCH C_LD into LD;
        CLOSE C_LD;
        if LD.loadno is null then
            out_errorno := -4;
            out_msg := 'Invalid load';
            log_msg(in_facility,in_custid,l_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
            return;
        end if;
    end if;

    ORD := null;
    if nvl(in_orderid, 0) > 0 then
        OPEN C_ORD(in_orderid, in_shipid);
        FETCH C_ORD into ORD;
        CLOSE C_ORD;
        if ORD.orderid is null then
            out_errorno := -5;
            out_msg := 'Invalid order';
            log_msg(in_facility,in_custid,l_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
            return;
        end if;
    end if;

    if in_invoice_type = 'R' and in_loadno is null then
        out_errorno := -20;
        out_msg := 'Receipt charge requires loadno';
        log_msg(in_facility,in_custid,l_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
        return;
    end if;

    if in_invoice_type = 'A' and in_orderid is null then
        out_errorno := -21;
        out_msg := 'Accessorial charge requires orderid';
        log_msg(in_facility,in_custid,l_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
        return;
    end if;

-- Based on invoice type try to locate open invoice.
    INVH := null;

    if l_invoice is not null then
        OPEN C_INVH(l_invoice);
        FETCH C_INVH into INVH;
        CLOSE C_INVH;
        if INVH.invoice is null then
            out_errorno := -8;
            out_msg := 'Invoice does not exist:'||l_invoice;
            log_msg(in_facility,in_custid,l_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
            return;
        end if;
    end if;

-- If invoice provided verify it
    if INVH.invoice is not null then
        if in_invoice_type != INVH.invtype then
            out_errorno := -9;
            out_msg := 'Invoice type does not match';
            log_msg(in_facility,in_custid,l_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
            return;
        end if;

        if in_facility != INVH.facility
        or in_custid != INVH.custid then
            out_errorno := -9;
            out_msg := 'Invoice facility custid do not match:'||INVH.facility
                ||'/'||INVH.custid;
            log_msg(in_facility,in_custid,l_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
            return;
        end if;

        out_INVH := INVH;
        return;
    end if;

    if in_invoice_type = 'A' then
-- Lookup custbilldates to determine where we should be in the billing cycle
-- for accessorials
        CBD := null;
        OPEN C_CBD(in_custid);
        FETCH C_CBD into CBD;
        CLOSE C_CBD;

        if zbill.get_nextbilldate(in_custid, trunc(in_charge_date),
                       CUST.outbbillfreq,
                       CUST.outbbillday, zbill.BT_ACCESSORIAL,
                       CBD.nextassessorial) = zbill.BAD then
          CBD.nextassessorial := trunc(in_charge_date);
        end if;
        OPEN C_INVH_FIND(in_custid, in_charge_date, CBD.nextassessorial);
        FETCH C_INVH_FIND into INVH;
        CLOSE C_INVH_FIND;

        if INVH.custid is null then

            INSERT into invoicehdr
              (
                  invoice,
                  invdate,
                  invtype,
                  invstatus,
                  facility,
                  custid,
                  renewfromdate,
                  renewtodate,
                  lastuser,
                  lastupdate
              )
           VALUES
              (
                  invoiceseq.nextval,
                  sysdate,
                  zbill.IT_ACCESSORIAL,
                  zbill.NOT_REVIEWED,
                  in_facility,
                  in_custid,
                  CBD.lastassessorial,
                  CBD.nextassessorial,
                  IMP_USERID,
                  sysdate
              );

           SELECT invoiceseq.currval INTO invoice_id FROM dual;

           OPEN zbill.C_INVH(invoice_id);
           FETCH zbill.C_INVH into INVH;
           CLOSE zbill.C_INVH;

       end if;

        
    end if;

    if in_invoice_type = 'R' then
        if LD.loadno is null then
            out_errorno := -6;
            out_msg := 'Must provide load for receipt bills';
            log_msg(in_facility,in_custid,l_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
            return;
        end if;
        
        if nvl(LD.loadtype,'x') != 'INC' then
            out_errorno := -7;
            out_msg := 'Must provide inbound customer load for receipt bills';
            log_msg(in_facility,in_custid,l_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
            return;
        end if;
        
        OPEN C_INVH_R;
        FETCH C_INVH_R into INVH;
        CLOSE C_INVH_R;

    end if;

    if in_invoice_type = 'S' then
        OPEN C_INVH_S;
        FETCH C_INVH_S into INVH;
        CLOSE C_INVH_S;

    end if;


    out_INVH := INVH;
    return;

END  validate_locate_invoicehdr;

-------------------------------------------------------------------------------
--   Procedures and Functions
-------------------------------------------------------------------------------
procedure import_invoice_header
(
 in_facility in varchar2
,in_custid in varchar2
,in_invoice_type in varchar2
,in_charge_date in date
,in_loadno in number
,in_orderid in number
,in_shipid in number
,out_invoice IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
IS

INVH invoicehdr%rowtype;
out_orderid orderhdr.orderid%type;
errmsg varchar2(255);

BEGIN
  out_errorno := 0;
  out_msg := 'OKAY';
  out_invoice := null;

-- Validate Facility
-- Validate Custid
-- Validate invoice type
-- Lookup Corresponding Order and invoice
    validate_locate_invoicehdr(in_facility,in_custid,in_invoice_type,
        nvl(in_charge_date,sysdate),in_loadno,in_orderid,in_shipid,
        INVH,out_errorno,out_msg);
    if out_errorno < 0 then
        return;
    end if;

    if INVH.invoice is not null then
        if INVH.invstatus != zbill.NOT_REVIEWED then
            out_errorno := -10;
            out_msg := 'Invalid invoice status : '||INVH.invstatus;
            log_msg(in_facility,in_custid,INVH.invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
            return;
        end if;
    end if;    

-- If no invoice create invoicehdr
    if INVH.invoice is null then
        if in_invoice_type = 'M' then
            zbill.start_misc_invoice(in_facility, in_custid, IMP_USERID,
                out_orderid, errmsg);
            update invoicehdr
               set invdate = nvl(in_charge_date, sysdate)
             where invoice = out_orderid;
            OPEN C_INVH(out_orderid);
            FETCH C_INVH into INVH;
            CLOSE C_INVH;
        end if;
        if in_invoice_type = 'C' then
            zbill.start_credit_memo_invoice(in_facility, in_custid, IMP_USERID,
                out_orderid, errmsg);
            update invoicehdr
               set invdate = nvl(in_charge_date, sysdate)
             where invoice = out_orderid;
            OPEN C_INVH(out_orderid);
            FETCH C_INVH into INVH;
            CLOSE C_INVH;
        end if;
        if in_invoice_type = 'R' then
            null;
        end if;
        if in_invoice_type = 'S' then
            null;
        end if;
    end if;

-- Return Invoice found/created
    out_invoice := INVH.invoice;


exception when others then
  out_msg := 'zimbiih ' || sqlerrm;
  out_errorno := sqlcode;
END import_invoice_header;

-------------------------------------------------------------------------------
procedure import_invoice_charge
(
 in_facility in varchar2
,in_custid in varchar2
,in_invoice_type in varchar2
,in_activity_date in date
,in_loadno in number
,in_orderid in number
,in_shipid in number
,in_invoice number
,in_activity in varchar2
,in_item in varchar2
,in_lot in varchar2
,in_uom in varchar2
,in_quantity in number
,in_billmethod in varchar2
,in_rate in number
,in_useinvoice number
,in_comment in varchar2
,in_recalc_invoice in varchar2
,out_invoice IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
IS
INVH invoicehdr%rowtype;
UI   invoicehdr%rowtype;

CURSOR C_ACT(in_activity varchar2)
IS
 SELECT *
   FROM activity
  WHERE code = in_activity;
ACT activity%rowtype;

CURSOR C_ITM(in_custid varchar2, in_item varchar2)
IS
 SELECT *
   FROM custitem
  WHERE custid = in_custid
    AND item = in_item;
ITM custitem%rowtype;

CURSOR C_BM(in_bm varchar2)
IS
 SELECT *
   FROM billingmethod
  WHERE code = in_bm;
BM billingmethod%rowtype;
rc integer;

l_qty number;
errmsg varchar2(255);

BEGIN
  out_errorno := 0;
  out_msg := 'OKAY';

-- Validate Facility
-- Validate Custid
-- Validate invoice type
-- If in_invoice provided read invoicehdr
-- else locate invoicehdr
    INVH := null;
    INVH.invoice := in_invoice;
    validate_locate_invoicehdr(in_facility,in_custid,in_invoice_type,
        in_activity_date,in_loadno,in_orderid,in_shipid,
        INVH,out_errorno,out_msg);
    if out_errorno < 0 then
        log_msg(in_facility,in_custid,in_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
        return;
    end if;

    if INVH.invoice is null then
      if in_invoice_type = 'S' then
        INVH.invoice := 0;
        INVH.invtype := in_invoice_type;
        INVH.invdate := in_activity_date;
        INVH.loadno := null;
        INVH.invstatus := zbill.NOT_REVIEWED;
      else
        out_errorno := -19;
        out_msg := 'Invoice not found for charge';
        log_msg(in_facility,in_custid,in_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
        return;
      end if;
    end if;

-- Verify invoicehdr found still open for mods
    if INVH.invoice is not null then
        if INVH.invstatus != zbill.NOT_REVIEWED then
            out_errorno := -10;
            out_msg := 'Invalid invoice status : '||INVH.invstatus;
            log_msg(in_facility,in_custid,in_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
            return;
        end if;
    end if;    

-- Validate activity date, activity, item, uom, billmethod
    ACT := null;
    OPEN C_ACT(in_activity);
    FETCH C_ACT into ACT;
    CLOSE C_ACT;
    if ACT.code is null then
        out_errorno := -11;
        out_msg := 'Invalid activity code: '||in_activity;
        log_msg(in_facility,in_custid,in_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
        return;
    end if;    

    BM := null;
    OPEN C_BM(in_billmethod);
    FETCH C_BM into BM;
    CLOSE C_BM;
    if BM.code is null then
        out_errorno := -12;
        out_msg := 'Invalid bill method : '||in_billmethod;
        log_msg(in_facility,in_custid,in_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
        return;
    end if;    

    if (in_activity_date is null)
     or (in_activity_date > sysdate)
     or (in_activity_date < sysdate - 100)
    then
        out_errorno := -13;
        out_msg := 'Invalid activity date: '||to_char(in_activity_date);
        log_msg(in_facility,in_custid,in_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
        return;
    end if;

    if in_item is not null then
        ITM := null;
        OPEN C_ITM(in_custid, in_item);
        FETCH C_ITM into ITM;
        CLOSE C_ITM;
        if ITM.item is null then
            out_errorno := -14;
            out_msg := 'Invalid item: '||in_custid||'/'||in_item;
            log_msg(in_facility,in_custid,in_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
            return;
        end if;    
    -- check uom for this item
        zbut.translate_uom(in_custid, in_item, 1, in_uom,
              ITM.baseuom,
              l_qty, errmsg);

        if errmsg != 'OKAY' then
            out_errorno := -15;
            out_msg := errmsg;
            log_msg(in_facility,in_custid,in_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
            return;
        end if;       
    end if;

-- If defined verify useinvoice must be only for credit memo
    if in_useinvoice is not null then
        if in_invoice_type != 'C' then
            out_errorno := -16;
            out_msg := 'Useinvoice is only valid for Credit Memos';
            log_msg(in_facility,in_custid,in_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
            return;
        end if;
        UI := null;
        OPEN C_INVH(in_useinvoice);
        FETCH C_INVH into UI;
        CLOSE C_INVH;
        if UI.invoice is null then
            out_errorno := -17;
            out_msg := 'Useinvoice does not exist';
            log_msg(in_facility,in_custid,in_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
            return;
        end if;
        if UI.facility != UI.facility
         or UI.custid != UI.custid then
            out_errorno := -18;
            out_msg := 'Useinvoice must be for same facility, custid';
            log_msg(in_facility,in_custid,in_invoice,in_orderid,in_shipid,in_loadno,'E',out_msg);
            return;
        end if;
    end if;

-- Add invoicedtl
    INSERT INTO invoicedtl
    (
        billstatus,
        facility,
        custid,
        orderid,
        item,
        lotnumber,
        activity,
        activitydate,
        billmethod,
        enteredqty,
        entereduom,
        enteredweight,
        enteredrate,
        loadno,
        invoice,
        invtype,
        invdate,
        shipid,
        statusrsn,
        useinvoice,
        comment1,
        lastuser,
        lastupdate,
        businessevent
    )
    values
    (
        zbill.UNCHARGED,
        in_facility,
        in_custid,
        in_orderid,
        in_item,
        in_lot,
        in_activity,
        in_activity_date,
        in_billmethod,
        in_quantity,
        in_uom,
        0,
        in_rate,
        INVH.loadno,
        INVH.invoice,
        INVH.invtype,
        INVH.invdate,
        in_shipid,
--        decode(INVH.invtype, zbill.IT_RECEIPT, zbill.SR_RECEIPT, 
--                             zbill.IT_ACCESSORIAL, zbill.SR_OUTB,
--                             zbill.IT_STORAGE, zbill.SR_RENEW,
--                             null),
        decode(INVH.invtype, zbill.IT_STORAGE, zbill.SR_ANVR,
                             null),
        in_useinvoice,
        in_comment,
        IMP_USERID,
        sysdate,
        zbill.EV_IMPORT
    );


-- Calculate the existing uncalculated line items.
    for crec in (SELECT rowid
                   FROM invoicedtl
                  WHERE invoice = INVH.invoice
                    AND billstatus = zbill.UNCHARGED) loop
        errmsg := '';
        if zbill.calculate_detail_rate(crec.rowid, sysdate, 
                                  errmsg) = zbill.BAD then
           null;
        end if;
    end loop;

-- Recalc invoice including mins
    if nvl(in_recalc_invoice,'N') = 'Y' then
        if in_invoice_type in ('M','C') then
            rc := zbms.recalc_misc(INVH.invoice, in_loadno, in_custid,
                IMP_USERID, errmsg);
        elsif in_invoice_type = 'R' then
            rc := zbr.calc_customer_receipt(INVH.invoice, in_loadno, in_custid,
                IMP_USERID, errmsg);
        elsif in_invoice_type = 'A' then
            rc := zba.recalc_access_bills(INVH.invoice, in_loadno, in_custid,
                IMP_USERID, errmsg);
        elsif in_invoice_type = 'S' then
          if INVH.invoice is not null then
            rc := zbs.recalc_renewal(INVH.invoice, in_loadno, in_custid,
                IMP_USERID, errmsg);
          end if;
        end if;
    end if;

    out_invoice := INVH.invoice;

exception when others then
  out_msg := 'zimbiic ' || sqlerrm;
  out_errorno := sqlcode;
END import_invoice_charge;

-------------------------------------------------------------------------------

end zimportprocbill;
/
show error package body zimportprocbill;
exit;
