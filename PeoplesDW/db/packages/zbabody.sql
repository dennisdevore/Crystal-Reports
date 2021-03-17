create or replace package body alps.zbillaccess as
--
-- $Id$
--
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************
--
-- Constants are defined in zbillspec.sql
--
-- MOVE TO zbillspec when get a chance
--


-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************
--
-- Cursors are defined in zbillspec.sql
--
----------------------------------------------------------------------
CURSOR C_ORDHDR(in_orderid number, in_shipid number)
RETURN orderhdr%rowtype
IS
    SELECT *
      FROM orderhdr
     WHERE orderid = in_orderid
       AND shipid = in_shipid;

----------------------------------------------------------------------
  CURSOR C_LD_ITEMS(in_orderid number, in_shipid number)
  IS
    SELECT distinct item
      FROM shippingplate
     WHERE orderid = in_orderid
       AND shipid = in_shipid
       AND type in ('F','P');

----------------------------------------------------------------------
  CURSOR C_QTY(in_orderid number,
               in_shipid number,
               in_custid varchar2,
               in_item varchar2,
               in_track_lot varchar2)
  IS
    SELECT decode(in_track_lot,'Y',lotnumber,'O',lotnumber,'S',lotnumber,'A',lotnumber,null) lotnum,
           unitofmeasure,
           orderitem,
           decode(in_track_lot,'Y',orderlot,'O',orderlot,'S',orderlot,'A',orderlot,null) orderlot,
           sum(quantity) qty,
           sum(weight) weight
      FROM shippingplate
     WHERE orderid = in_orderid
       AND shipid = in_shipid
       AND custid = in_custid
       AND item = in_item
       AND type in ('F','P')
       AND status = 'SH'
      GROUP BY decode(in_track_lot,'Y',lotnumber,'O',lotnumber,'S',lotnumber,'A',lotnumber,null),
               unitofmeasure, orderitem,
               decode(in_track_lot,'Y',orderlot,'O',orderlot,'S',orderlot,'A',orderlot,null);

----------------------------------------------------------------------
  CURSOR C_EST_QTY(in_orderid number,
               in_shipid number,
               in_custid varchar2,
               in_item varchar2,
               in_track_lot varchar2)
  IS
    SELECT decode(in_track_lot,'Y',lotnumber,'O',lotnumber,'S',lotnumber,'A',lotnumber,null) lotnum,
           unitofmeasure,
           orderitem,
           decode(in_track_lot,'Y',orderlot,'O',orderlot,'S',orderlot,'A',orderlot,null) orderlot,
           sum(quantity) qty,
           sum(weight) weight
      FROM shippingplate
     WHERE orderid = in_orderid
       AND shipid = in_shipid
       AND custid = in_custid
       AND item = in_item
       AND type in ('F','P')
      GROUP BY decode(in_track_lot,'Y',lotnumber,'O',lotnumber,'S',lotnumber,'A',lotnumber,null),
               unitofmeasure, orderitem,
               decode(in_track_lot,'Y',orderlot,'O',orderlot,'S',orderlot,'A',orderlot,null);
CURSOR C_LOAD(in_loadno number)
 RETURN loads%rowtype
IS
    SELECT *
      FROM loads
     WHERE loadno = in_loadno;
----------------------------------------------------------------------
CURSOR C_FAC(in_facility varchar2)
IS
  SELECT *
    FROM facility
   WHERE facility = in_facility;
----------------------------------------------------------------------

-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************


----------------------------------------------------------------------
--
-- check_multi_facility
--
----------------------------------------------------------------------
FUNCTION check_multi_facility
(
    in_orderid  IN      number,
    in_shipid   IN      number
)
RETURN integer
IS

  CUST  customer%rowtype;
  ORD   orderhdr%rowtype;
  FAC   facility%rowtype;

  rc integer;
  cnt integer;

BEGIN
    rc := 0;

-- Get the order
    ORD := NULL;
    OPEN C_ORDHDR(in_orderid, in_shipid);
    FETCH C_ORDHDR into ORD;
    CLOSE C_ORDHDR;

    if zbill.rd_customer(ORD.custid, CUST) = zbill.BAD then
       return 0;
    end if;


-- Set multi-facility flag
    FAC := null;
    OPEN C_FAC(nvl(ORD.fromfacility,ORD.tofacility));
    FETCH C_FAC into FAC;
    CLOSE C_FAC;

    cnt := 0;
    select count(1)
      into cnt
      from orderhdr
     where loadno = ORD.loadno
       and orderid = in_orderid;

    if nvl(CUST.multifac_picking,'N') = 'Y'
     and FAC.campus is not null
     and nvl(cnt,0) > 1 then
        select min(shipid)
          into rc
          from orderhdr
         where loadno = ORD.loadno
           and orderid = in_orderid;
    end if;

    return rc;

EXCEPTION WHEN OTHERS THEN
    return 0;

END check_multi_facility;

----------------------------------------------------------------------
--
-- calc_access_minimums -
--
----------------------------------------------------------------------
FUNCTION calc_access_minimums
(
    INVH        IN      invoicehdr%rowtype,
    in_orderid  IN      number,
    in_shipid   IN      number,
    in_custid   IN      varchar2,
    in_userid   IN      varchar2,
    in_effdate  IN      date,
    out_errmsg  IN OUT  varchar2,
    in_keep_deleted IN  varchar2 default 'N'
)
RETURN integer
IS
  CUST  customer%rowtype;
  ITEM  custitem%rowtype;
  RATE  custrate%rowtype;
  LOAD  loads%rowtype;
  ORD   orderhdr%rowtype;
  XDORD orderhdr%rowtype;

-- Minimums Cursors
  CURSOR C_ID_CHRG(in_invoice number, in_orderid number, in_shipid number,
         in_custid varchar2)
  IS
    SELECT activity, activitydate, item, lotnumber,
           nvl(billedamt,nvl(calcedamt,0)) total
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND orderid = in_orderid
       AND shipid = nvl(in_shipid,shipid)
       AND custid = in_custid
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED);

  CURSOR C_ID_LINE(in_invoice number, in_orderid number, in_shipid number,
         in_custid varchar2)
  IS
    SELECT activity, item, lotnumber,
           sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND orderid = in_orderid
       AND shipid = nvl(in_shipid,shipid)
       AND custid = in_custid
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED)
     GROUP BY activity, item, lotnumber;

  CURSOR C_ID_ITEM(in_invoice number, in_orderid number, in_shipid number,
         in_custid varchar2)
  IS
    SELECT activity, item, sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND orderid = in_orderid
       AND shipid = nvl(in_shipid,shipid)
       AND custid = in_custid
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED)
     GROUP BY activity, item;

  CURSOR C_ID_ORDER(in_invoice number, in_orderid number, in_shipid number,
         in_custid varchar2)
  IS
    SELECT activity, sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND orderid = in_orderid
       AND shipid = nvl(in_shipid,shipid)
       AND custid = in_custid
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED)
     GROUP BY activity;

  CURSOR C_ID_INVOICE(in_invoice number, in_orderid number, in_shipid number,
         in_custid varchar2)
  IS
    SELECT sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND orderid = in_orderid
       AND shipid = nvl(in_shipid,shipid)
       AND custid = in_custid
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED);

  rc integer;
  now_date date;
  item_rategroup custitem.rategroup%type;

  l_shipid integer;
  mf_shipid integer;
  l_event custratewhen.businessevent%type;

BEGIN

    now_date := in_effdate;

    mf_shipid := check_multi_facility(in_orderid, in_shipid);

    if mf_shipid = 0 then
        l_shipid := in_shipid;
    else
        l_shipid := null;
    end if;

-- Get the order
    ORD := NULL;
    OPEN C_ORDHDR(in_orderid, in_shipid);
    FETCH C_ORDHDR into ORD;
    CLOSE C_ORDHDR;


-- Get the load
    LOAD := null;
    OPEN C_LOAD(ORD.loadno);
    FETCH C_LOAD into LOAD;
    CLOSE C_LOAD;

    -- zut.prt('Load is '||nvl(to_char(ORD.loadno),'*NULL*'));

-- Get the customer information for this outbound order
    if zbill.rd_customer(in_custid, CUST) = zbill.BAD then
       out_errmsg := 'Invalid custid = '|| in_custid;
       -- zut.prt(out_errmsg);
       return zbill.BAD;
    end if;

-- Get rid of any old minimums
    DELETE FROM invoicedtl
     WHERE invoice = INVH.invoice
       AND orderid = ORD.orderid
       and shipid = ORD.shipid
       AND custid = in_custid
       AND minimum is not null
       and (billstatus != zbill.DELETED or in_keep_deleted = 'N');

-- Check if order is crosdock order
    l_event := zbill.EV_SHIP;
    if ORD.xdockorderid is not null then
        XDORD := NULL;
        OPEN C_ORDHDR(ORD.xdockorderid, ORD.xdockshipid);
        FETCH C_ORDHDR into XDORD;
        CLOSE C_ORDHDR;
        if XDORD.ordertype = 'C' then
            l_event := zbill.EV_XDSHIP;
        end if;
    end if;
-- Determine all the possible mins in order

-- Check for per charge minimums
    for crec in C_ID_CHRG(INVH.invoice, in_orderid, l_shipid, in_custid) loop
    -- Check if line level minimum exists for this item
      if zbill.rd_item(CUST.custid, crec.item, ITEM) = zbill.BAD then
         null;
      end if;
      zbill.rd_item_rategroup(ITEM.custid, ITEM.item, item_rategroup);

      if zbill.check_for_minimum(CUST.custid, item_rategroup, CUST.rategroup,
                 l_event, INVH.facility, zbill.BM_MIN_CHARGE,
                 crec.activity, crec.activitydate, RATE) = zbill.GOOD then
           if crec.total < RATE.rate then
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, ORD,
                 crec.item, crec.lotnumber, crec.total, in_userid,
                 crec.activitydate, null, l_event, in_keep_deleted);

           end if;
      end if;
    end loop;

-- Check for line minimums
    for crec in C_ID_LINE(INVH.invoice, in_orderid, l_shipid, in_custid) loop
    -- Check if line level minimum exists for this item
      if zbill.rd_item(CUST.custid, crec.item, ITEM) = zbill.BAD then
         null;
      end if;
      zbill.rd_item_rategroup(ITEM.custid, ITEM.item, item_rategroup);

      if zbill.check_for_minimum(CUST.custid, item_rategroup, CUST.rategroup,
                 l_event, INVH.facility, zbill.BM_MIN_LINE,
                 crec.activity, now_date, RATE) = zbill.GOOD then
           if crec.total < RATE.rate then
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, ORD,
                 crec.item, crec.lotnumber, crec.total, in_userid,sysdate, null, l_event, in_keep_deleted);

           end if;
      end if;
    end loop;

-- Check for item minimums
    for crec in C_ID_ITEM(INVH.invoice, in_orderid, l_shipid, in_custid) loop
    -- Check if line level minimum exists for this item
      if zbill.rd_item(CUST.custid, crec.item, ITEM) = zbill.BAD then
         null;
      end if;
      zbill.rd_item_rategroup(ITEM.custid, ITEM.item, item_rategroup);

      if zbill.check_for_minimum(CUST.custid, item_rategroup, CUST.rategroup,
                 l_event, INVH.facility, zbill.BM_MIN_ITEM,
                 crec.activity, now_date, RATE) = zbill.GOOD then
           if crec.total < RATE.rate then
               -- zut.prt('Order ID is '||nvl(to_char(orderid),'*NULL*'));
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, ORD,
                 crec.item, NULL, crec.total, in_userid,sysdate, null, l_event, in_keep_deleted);
           end if;
      end if;
   end loop;

-- Check for order minimum (must be defined at the cust rate group level)
    for crec in C_ID_ORDER(INVH.invoice, in_orderid, l_shipid, in_custid) loop
    -- Check if order level minimums exist
      if zbill.check_for_minimum(CUST.custid, NULL, CUST.rategroup,
                 l_event, INVH.facility, zbill.BM_MIN_ORDER,
                 crec.activity, now_date, RATE) = zbill.GOOD then
           if crec.total < RATE.rate then
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, ORD,
                 NULL, NULL, crec.total, in_userid,sysdate, null, l_event, in_keep_deleted);
           end if;
      end if;
    end loop;

-- Check for invoice minimum (must be defined at the cust rate group level)
    for crec in C_ID_INVOICE(INVH.invoice, in_orderid, l_shipid, in_custid) loop
    -- Check if invoice level minimums exist
      if zbill.check_for_minimum(CUST.custid, NULL, CUST.rategroup,
                 l_event, INVH.facility, zbill.BM_MIN_INVOICE, NULL,
                 now_date, RATE) = zbill.GOOD then
           if crec.total < RATE.rate then
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, ORD,
                 NULL, NULL, crec.total, in_userid,sysdate, null, l_event, in_keep_deleted);
           end if;
      end if;
    end loop;


    return zbill.GOOD;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CAccMins: '||substr(sqlerrm,1,80);
    return zbill.BAD;
END calc_access_minimums;


----------------------------------------------------------------------
--
-- get_invoicehdr_accessorial - retreive or create an invoice header for the
--                specified invoice type
--
----------------------------------------------------------------------
FUNCTION get_invoicehdr_accessorial
(
        in_lookup       IN      varchar2,   -- FIND to try to lookup
        in_custid       IN      varchar2,
        in_facility     IN      varchar2,
        in_loadno       IN      varchar2,
        in_userid       IN      varchar2,
        in_effdate      IN      date,
        INVH            OUT     invoicehdr%rowtype
)
RETURN integer
IS
  CURSOR C_INVH_FIND(in_custid varchar2, in_effdate date, in_thrudate date, in_loadno varchar2)
  RETURN invoicehdr%rowtype
  IS
     SELECT *
       FROM invoicehdr
      WHERE custid = in_custid
        AND facility = in_facility
        AND invtype = zbill.IT_ACCESSORIAL
        AND invstatus = zbill.NOT_REVIEWED
        AND to_char(invdate,'YYYYMM') = to_char(in_effdate,'YYYYMM')
        AND (in_loadno is null or (loadno is not null and loadno = in_loadno))
        AND in_thrudate = renewtodate
     ORDER BY invdate desc;

--   AND to_char(in_effdate,'YYYYMMDD') <= to_char(renewtodate,'YYYYMMDD')

  invoice_id invoicehdr.invoice%type;

  CURSOR C_CBD(in_custid varchar2)
  IS
    SELECT a.*, nvl(b.acc_invoice_per_load,'N') as acc_invoice_per_load
      FROM custbilldates a, customer_aux b
     WHERE a.custid = b.custid and a.custid = in_custid;
  CBD C_CBD%rowtype;
  CUST  customer%rowtype;

tdate date;
v_loadno invoicehdr.loadno%type := null;


BEGIN

-- Lookup custbilldates to determine where we should be in the billing cycle
-- for accessorials
   CBD := null;
   OPEN C_CBD(in_custid);
   FETCH C_CBD into CBD;
   CLOSE C_CBD;

     if zbill.rd_customer(in_custid, CUST) = zbill.BAD then
        -- out_errmsg := 'Invalid custid = '|| in_custid;
        -- zut.prt(out_errmsg);
        return zbill.BAD;
     end if;

    if (CBD.acc_invoice_per_load = 'Y' and in_loadno is not null) then
      CBD.nextassessorial := trunc(in_effdate);
    elsif CUST.outbbillfreq = 'M' then
        tdate := add_months(trunc(in_effdate), -1);
        loop
            if zbill.get_nextbilldate(in_custid, tdate,
                       CUST.outbbillfreq,
                       CUST.outbbillday,
                       zbill.BT_ACCESSORIAL,
                       CBD.nextassessorial) = zbill.BAD then
                CBD.nextassessorial := tdate;
            end if;
            if trunc(in_effdate) <= CBD.nextassessorial then
                exit;
            end if;
            tdate := tdate + 5;

        end loop;

    else
     if CUST.outbbillfreq in ('C','F') then
            tdate := in_effdate -1;
     else
            tdate := in_effdate;
     end if;

     if CUST.outbbillfreq = 'D' then
        CUST.outbbillfreq := 'C'; -- Special case to ignore sysdate for daily
     end if;

     if zbill.get_nextbilldate(CUST.custid,
                       tdate,
                       CUST.outbbillfreq,
                       CUST.outbbillday,
                       zbill.BT_ACCESSORIAL,
                       CBD.nextassessorial) = zbill.BAD then
       CBD.nextassessorial := trunc(in_effdate);
     end if;
    end if;

   if (CBD.acc_invoice_per_load = 'Y') then
    v_loadno := in_loadno;
   end if;
   
   INVH := null;
   if upper(in_lookup) = 'FIND' then
       OPEN C_INVH_FIND(in_custid, in_effdate, CBD.nextassessorial, v_loadno);
       FETCH C_INVH_FIND into INVH;
       CLOSE C_INVH_FIND;
   end if;



   if INVH.custid is null then

      INSERT into invoicehdr
          (
              invoice,
              invdate,
              invtype,
              invstatus,
              facility,
              custid,
			  loadno,
              renewfromdate,
              renewtodate,
              lastuser,
              lastupdate
          )
       VALUES
          (
              invoiceseq.nextval,
              in_effdate,
              zbill.IT_ACCESSORIAL,
              zbill.NOT_REVIEWED,
              in_facility,
              in_custid,
              v_loadno,
              CBD.lastassessorial,
              CBD.nextassessorial,
              in_userid,
              sysdate
          );

       SELECT invoiceseq.currval INTO invoice_id FROM dual;

       OPEN zbill.C_INVH(invoice_id);
       FETCH zbill.C_INVH into INVH;
       CLOSE zbill.C_INVH;

   end if;

   return zbill.GOOD;

END get_invoicehdr_accessorial;

----------------------------------------------------------------------
--
-- get_invoicehdr_accessorial - retreive or create an invoice header for the
--                specified invoice type
--
----------------------------------------------------------------------
PROCEDURE get_estimated_invoicehdr
(
        in_custid       IN      varchar2,
        in_facility     IN      varchar2,
        in_orderid      IN      varchar2,
        in_shipid       IN      varchar2,
        in_userid       IN      varchar2,
        INVH            OUT     invoicehdr%rowtype
)
IS
  v_invoice number;
  v_count number;
BEGIN
  v_invoice := -1 * (in_orderid * 100 + in_shipid);
  select count(1) into v_count
  from invoicehdr
  where invoice = v_invoice;
  if (v_count = 0) then
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
              v_invoice,
              trunc(sysdate),
              zbill.IT_ACCESSORIAL,
              zbill.ESTIMATED,
              in_facility,
              in_custid,
              sysdate,
              sysdate,
              in_userid,
              sysdate
          );
  end if;
  update invoicehdr
  set invdate = sysdate
  where invoice = v_invoice;
  OPEN zbill.C_INVH(v_invoice);
  FETCH zbill.C_INVH into INVH;
  CLOSE zbill.C_INVH;
END get_estimated_invoicehdr;

----------------------------------------------------------------------
--
-- calc_order_charges -
--
----------------------------------------------------------------------
FUNCTION calc_order_charges
(
    in_event    IN      varchar2,
    in_userid   IN      varchar2,
    CUST        IN      customer%rowtype,
    ORD         IN      orderhdr%rowtype,
    INVH        IN OUT  invoicehdr%rowtype,
    LOAD        IN      loads%rowtype,
    in_effdate  IN      date
)
RETURN integer
IS
  ITEM  custitem%rowtype;
  RATE  custrate%rowtype;
  now_date  date;
  do_calc    BOOLEAN;
  track_lot  char(1);
  item_rategroup  custrate.rategroup%type;
  rc integer;

BEGIN

--    zut.prt('Calc_Order_charges:'||ORD.orderid||'/'||ORD.shipid
--        ||' '||in_event);

    now_date := in_effdate;

-- For each item
   for crec in C_LD_ITEMS(ORD.orderid, ORD.shipid) loop
        do_calc := TRUE;
        if zbill.rd_item(CUST.custid, crec.item, ITEM) = zbill.BAD then
--           zut.prt('Customer item not found:'||CUST.custid||'/'||crec.item);
           do_calc := FALSE;
        end if;

--         zut.prt('Customer item found:'||CUST.custid||'/'||crec.item);
     -- Determine if we are tracking lots or not
        track_lot := ITEM.lotrequired;
        if track_lot = 'C' then
           track_lot := CUST.lotrequired;
        end if;
        if ITEM.lotsumaccess = 'Y' then
            track_lot := 'N';
        end if;


     -- For this item determine it we are billing anything for this order
        if do_calc then

    -- Determine the rate group to use for renewal for this item
    -- based on the existance of an entry for the SHIP business event
           zbill.rd_item_rategroup(ITEM.custid, ITEM.item, item_rategroup);

           for crec2 in zbill.C_RATE_WHEN(CUST.custid, item_rategroup,
                    in_event, INVH.facility, now_date) loop
--             zut.prt('  Rate event found:'||rategroup||' '||crec2.activity
--                           ||' '||crec2.billmethod);
           -- Get rate entry
              if zbill.rd_rate(rategrouptype(crec2.custid, crec2.rategroup),
                    crec2.activity,
                    crec2.billmethod, now_date, RATE) = zbill.BAD then
            --zut.prt('  Rate not found:'||rategroup||' '||crec2.activity
            --               ||' '||crec2.billmethod);
                  null;
              end if;

              if RATE.billmethod in
                 (zbill.BM_QTY, zbill.BM_QTYM, zbill.BM_FLAT,
                  zbill.BM_CWT, zbill.BM_WT, zbill.BM_QTY_BREAK,
                  zbill.BM_FLAT_BREAK, zbill.BM_WT_BREAK, zbill.BM_CWT_BREAK)
              then

           -- Determine qty's for this item including handling codes
           --   if necessary
              for crec3 in C_QTY(ORD.orderid, ORD.shipid,
                                  CUST.custid,  ITEM.item, track_lot) loop

                  if RATE.billmethod = zbill.BM_FLAT then
                      crec3.qty := 1;
                  end if;

           -- Add entry for this type
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
                             loadno,
                             invoice,
                             invtype,
                             invdate,
                             statusrsn,
                             shipid,
                             orderitem,
                             orderlot,
                             lastuser,
                             lastupdate,
                             businessevent
                         )
                         values
                         (
                             zbill.UNCHARGED,
                             INVH.facility,
                             CUST.custid,
                             ORD.orderid,
                             ITEM.item,
                             crec3.lotnum,
                             RATE.activity,
                             now_date, --sysdate,
                             RATE.billmethod,
                             decode(crec2.automatic,'C',0,crec3.qty),
                             crec3.unitofmeasure,
                             crec3.weight,
                             LOAD.loadno,
                             INVH.invoice,
                             INVH.invtype,
                             INVH.invdate,
                             zbill.SR_OUTB,
                             ORD.shipid,
                             crec3.orderitem,
                             crec3.orderlot,
                             in_userid,
                             sysdate,
                             in_event
                         );

              end loop;
              end if; -- RATE.billmethod in ('QTY','FLAT', 'CWT')
           end loop;

        end if;

   end loop;

   rc := zbill.calc_automatic_charges(CUST.custid, CUST.rategroup,
         in_event, ORD, INVH, now_date);

   return zbill.GOOD;

END calc_order_charges;




----------------------------------------------------------------------
--
-- calc_outbound_order -
--
----------------------------------------------------------------------
FUNCTION calc_outbound_order
(
    in_invoice  IN      number,
    in_loadno   IN      number,
    in_orderid  IN      number,
    in_shipid   IN      number,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer
IS
  CUST  customer%rowtype;
  ITEM  custitem%rowtype;
  RATE  custrate%rowtype;
  ORD   orderhdr%rowtype;
  RORD	orderhdr%rowtype;
  XDORD orderhdr%rowtype;
  LOAD  loads%rowtype;
  INVH  invoicehdr%rowtype;
  RINVD invoicedtl%rowtype;
  FAC   facility%rowtype;


  item_rategroup  custrate.rategroup%type;

  errmsg     varchar2(200);
  do_calc    BOOLEAN;
  track_lot  char(1);
  recmethod  varchar2(2);


-- Local cursors

  CURSOR C_HTYPE(in_activity varchar2)
  IS
    SELECT count(1)
      FROM handlingtypes
     WHERE activity = in_activity;


  CURSOR C_INVD(in_orderid number, in_shipid number, in_custid varchar2)
  IS
    SELECT rowid
      FROM invoicedtl
     WHERE orderid = in_orderid
       AND shipid = in_shipid
       AND custid = in_custid
       AND billstatus = zbill.UNCHARGED;

  CURSOR C_CAR(in_carrier varchar2)
  IS
    SELECT carriertype
      FROM carrier
     WHERE carrier = in_carrier;



  orderid orderhdr.orderid%type;
  carrier_type carrier.carriertype%type;

  qty C_QTY%rowtype;
  
  CURSOR C_FULL_PICKS(in_orderid number, in_shipid number, in_custid varchar2, in_item varchar2, in_track_lot varchar2)
  IS
  SELECT decode(in_track_lot,'Y',lotnumber,'O',lotnumber,'S',lotnumber,'A',lotnumber,null) lotnum,
    orderitem, decode(in_track_lot,'Y',orderlot,'O',orderlot,'S',orderlot,'A',orderlot,null) orderlot,
    count(1) qty, sum(weight) weight
  FROM shippingplate
  WHERE orderid = in_orderid
    AND shipid = in_shipid
    AND custid = in_custid
    AND item = in_item
    AND type in ('F','P')
    AND status = 'SH'
    and (origfromlpqty is not null and quantity = origfromlpqty)
  GROUP BY decode(in_track_lot,'Y',lotnumber,'O',lotnumber,'S',lotnumber,'A',lotnumber,null),
    orderitem, decode(in_track_lot,'Y',orderlot,'O',orderlot,'S',orderlot,'A',orderlot,null);
    
  CURSOR C_PART_PICKS(in_orderid number, in_shipid number, in_custid varchar2, in_item varchar2, in_track_lot varchar2, in_pick_uom varchar2)
  IS
  SELECT decode(in_track_lot,'Y',lotnumber,'O',lotnumber,'S',lotnumber,'A',lotnumber,null) lotnum,
    orderitem, decode(in_track_lot,'Y',orderlot,'O',orderlot,'S',orderlot,'A',orderlot,null) orderlot,
    sum(pickqty) qty, sum(weight) weight
  FROM shippingplate
  WHERE orderid = in_orderid
    AND shipid = in_shipid
    AND custid = in_custid
    AND item = in_item
    AND type in ('F','P')
    AND status = 'SH'
    and pickuom = in_pick_uom
    and (origfromlpqty is null or quantity <> origfromlpqty)
  GROUP BY decode(in_track_lot,'Y',lotnumber,'O',lotnumber,'S',lotnumber,'A',lotnumber,null),
    orderitem, decode(in_track_lot,'Y',orderlot,'O',orderlot,'S',orderlot,'A',orderlot,null);

 rc integer;
 cnt integer;

 now_date date;

 multifac_shipid integer;

 l_event custratewhen.businessevent%type;
 v_orderdtl_dollar_amt_pt varchar2(30);
 v_pt_amt number;

 type metrics_t is record (
	quantity number,
	weight 	 number
 );
 type charge_reversal_t is table of metrics_t index by PLS_INTEGER;
 charge_reversal charge_reversal_t;
 v_precision integer := 1000000;
 v_cr_rate custrate.rate%type;
 v_cr_key pls_integer;
 v_quantity number;
 v_found boolean;
BEGIN
-- Upon close of the outbound order we need to calculate the charges
--   we are generating for the accessorial (outbound) invoice
--   this may require rolling multiple detail lines into
--   a single 'new' billing record or
--   processing the individual invoicedtl lines

-- Get the order
    ORD := NULL;
    OPEN C_ORDHDR(in_orderid, in_shipid);
    FETCH C_ORDHDR into ORD;
    CLOSE C_ORDHDR;

-- Verify order
    if ORD.orderid is null then
       out_errmsg := 'Invalid orderid = '|| in_orderid||'/'||in_shipid;
       return zbill.BAD;
    end if;

    now_date := nvl(nvl(ORD.dateshipped,ORD.statusupdate),sysdate);

-- Check if order is crosdock order
    l_event := zbill.EV_SHIP;
    if ORD.xdockorderid is not null then
        XDORD := NULL;
        OPEN C_ORDHDR(ORD.xdockorderid, ORD.xdockshipid);
        FETCH C_ORDHDR into XDORD;
        CLOSE C_ORDHDR;
        if XDORD.ordertype = 'C' then
            l_event := zbill.EV_XDSHIP;
        end if;
    end if;
-- Get the load
    LOAD := null;
    OPEN C_LOAD(in_loadno);
    FETCH C_LOAD into LOAD;
    CLOSE C_LOAD;

--    if LOAD.loadno is null then
--       LOAD.facility := nvl(ORD.fromfacility,ORD.tofacility);
--    end if;


-- Get the customer information for this outbound order
    if zbill.rd_customer(ORD.custid, CUST) = zbill.BAD then
       out_errmsg := 'Invalid custid = '|| ORD.custid;
       -- zut.prt(out_errmsg);
       return zbill.BAD;
    end if;


-- Set multi-facility flag
    multifac_shipid := check_multi_facility(ORD.orderid, ORD.shipid);

-- Create Invoice header if we have misc charges for this load
   INVH := null;

   if in_invoice is null then
      rc := get_invoicehdr_accessorial('Find', CUST.custid,
                   nvl(ORD.fromfacility,ORD.tofacility), in_loadno, -- was LOAD.facility
                   in_userid,now_date, INVH);
   else
       OPEN zbill.C_INVH(in_invoice);
       FETCH zbill.C_INVH into INVH;
       CLOSE zbill.C_INVH;
   end if;


   SELECT count(1)
     INTO rc
     FROM invoicedtl
    WHERE custid = CUST.custid
      AND orderid = ORD.orderid
      AND shipid = ORD.shipid
    --  AND loadno = LOAD.loadno
      AND (invoice = 0);

    INVH.loadno := LOAD.loadno;

--
-- ??? Maybe if customer is a summary customer we should not create a
-- seperate set of charges ('Create') but add to an existing
-- open accessorial invoice instead. Think about it.
--
   if rc > 0 then
-- Set all misc invoicedtl for this outbound order to this invoice header
     UPDATE invoicedtl
        SET invoice = INVH.invoice,
            invtype = INVH.invtype,
            invdate = INVH.invdate
      WHERE custid = CUST.custid
        AND orderid = ORD.orderid
        AND shipid = ORD.shipid
        AND (invoice = 0);
   end if;
   select count(1) into rc
   from invoicedtl
   where invoice = -1 * (ORD.orderid * 100 + ORD.shipid)
    and invtype = zbill.IT_ACCESSORIAL and billstatus = zbill.ESTIMATED;
   if (rc > 0) then
     return rollover_estimated_charges(INVH.invoice, ORD.orderid, ORD.shipid, in_userid, out_errmsg);
   end if;
   zbill.rollover_preenter_charges(INVH.invoice, ORD.orderid, ORD.shipid, in_userid, out_errmsg);
   if (out_errmsg <> 'OKAY') then
    return zbill.BAD;
   end if;

-- For each item
   for crec in C_LD_ITEMS(ORD.orderid, ORD.shipid) loop
        do_calc := TRUE;
        if zbill.rd_item(CUST.custid, crec.item, ITEM) = zbill.BAD then
           -- zut.prt('Customer item not found:'||CUST.custid||'/'||crec.item);
           do_calc := FALSE;
        end if;

        -- zut.prt('Customer item found:'||CUST.custid||'/'||crec.item);
     -- Determine if we are tracking lots or not
        track_lot := ITEM.lotrequired;
        if track_lot = 'C' then
           track_lot := CUST.lotrequired;
        end if;
        if ITEM.lotsumaccess = 'Y' then
            track_lot := 'N';
        end if;

     -- For this item determine it we are billing anything for this order
        if do_calc then

    -- Determine the rate group to use for renewal for this item
    -- based on the existance of an entry for the SHIP business event
           zbill.rd_item_rategroup(ITEM.custid, ITEM.item, item_rategroup);

           for crec2 in zbill.C_RATE_WHEN(CUST.custid, item_rategroup,
                    l_event, INVH.facility, now_date) loop
           -- zut.prt('  Rate event found:'||crec2.rategroup||' '||crec2.activity ||' '||crec2.billmethod);
			 
           -- Get rate entry
              if zbill.rd_rate(rategrouptype(crec2.custid, crec2.rategroup),
                    crec2.activity,
                    crec2.billmethod, now_date, RATE) = zbill.BAD then
            --zut.prt('  Rate not found:'||rategroup||' '||crec2.activity
            --               ||' '||crec2.billmethod);
                  null;
              end if;

              if RATE.billmethod in
                 (zbill.BM_QTY, zbill.BM_QTYM, zbill.BM_FLAT,
                  zbill.BM_CWT, zbill.BM_WT, zbill.BM_QTY_BREAK,
                  zbill.BM_FLAT_BREAK, zbill.BM_WT_BREAK, zbill.BM_CWT_BREAK, zbill.BM_PCT_SALE)
              then

           -- Determine qty's for this item including handling codes
           --   if necessary
              for crec3 in C_QTY(in_orderid, in_shipid,
                                  CUST.custid,  ITEM.item, track_lot) loop

                  if RATE.billmethod = zbill.BM_FLAT then
                      crec3.qty := 1;
                  end if;

                  if RATE.billmethod = zbill.BM_PCT_SALE
                  then
                      begin
                        select orderdtl_dollar_amt_pt
                        into v_orderdtl_dollar_amt_pt
                        from customer
                        where custid = (select custid from orderhdr where orderid = in_orderid and shipid = in_shipid);
                      exception
                        when others then
                          v_orderdtl_dollar_amt_pt := null;
                      end;
                      
                      begin
                        execute immediate 'select nvl(' || v_orderdtl_dollar_amt_pt || ',0)
                                           from orderdtl
                                           where orderid = :in_orderid and shipid = :in_shipid and item = :in_item and nvl(lotnumber,''(none)'') = nvl(:in_lot,''(none)'')' 
                        into v_pt_amt using in_orderid, in_shipid, ITEM.item, crec3.orderlot;
                      exception
                        when others then
                          v_pt_amt := 0;
                      end;
                      
                      crec3.qty := crec3.qty * v_pt_amt;
                  end if;

           -- Add entry for this type
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
                             loadno,
                             invoice,
                             invtype,
                             invdate,
                             statusrsn,
                             shipid,
                             orderitem,
                             orderlot,
                             lastuser,
                             lastupdate,
                             businessevent
                         )
                         values
                         (
                             zbill.UNCHARGED,
                             INVH.facility,
                             CUST.custid,
                             ORD.orderid,
                             ITEM.item,
                             crec3.lotnum,
                             RATE.activity,
                             now_date, --sysdate,
                             RATE.billmethod,
                             decode(crec2.automatic,'C',0,crec3.qty),
                             crec3.unitofmeasure,
                             crec3.weight,
                             LOAD.loadno,
                             INVH.invoice,
                             INVH.invtype,
                             INVH.invdate,
                             zbill.SR_OUTB,
                             ORD.shipid,
                             crec3.orderitem,
                             crec3.orderlot,
                             in_userid,
                             sysdate,
                             l_event
                         );

              end loop;
              end if; -- RATE.billmethod in ('QTY','FLAT', 'CWT')
              
              if RATE.billmethod in (zbill.BM_FULL_PICK) then
                for crec3 in C_FULL_PICKS(in_orderid, in_shipid, CUST.custid,  ITEM.item, track_lot) loop
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
                       loadno,
                       invoice,
                       invtype,
                       invdate,
                       statusrsn,
                       shipid,
                       orderitem,
                       orderlot,
                       lastuser,
                       lastupdate
                   )
                   values
                   (
                       zbill.UNCHARGED,
                       INVH.facility,
                       CUST.custid,
                       ORD.orderid,
                       ITEM.item,
                       crec3.lotnum,
                       RATE.activity,
                       now_date, --sysdate,
                       RATE.billmethod,
                       decode(crec2.automatic,'C',0,crec3.qty),
                       null,
                       crec3.weight,
                       LOAD.loadno,
                       INVH.invoice,
                       INVH.invtype,
                       INVH.invdate,
                       zbill.SR_OUTB,
                       ORD.shipid,
                       crec3.orderitem,
                       crec3.orderlot,
                       in_userid,
                       sysdate
                   );
                end loop;
              end if;
              
              if RATE.billmethod in (zbill.BM_PART_PICK) then
                for crec3 in C_PART_PICKS(in_orderid, in_shipid, CUST.custid,  ITEM.item, track_lot, RATE.uom) loop
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
                       loadno,
                       invoice,
                       invtype,
                       invdate,
                       statusrsn,
                       shipid,
                       orderitem,
                       orderlot,
                       lastuser,
                       lastupdate
                   )
                   values
                   (
                       zbill.UNCHARGED,
                       INVH.facility,
                       CUST.custid,
                       ORD.orderid,
                       ITEM.item,
                       crec3.lotnum,
                       RATE.activity,
                       now_date, --sysdate,
                       RATE.billmethod,
                       decode(crec2.automatic,'C',0,crec3.qty),
                       RATE.uom,
                       crec3.weight,
                       LOAD.loadno,
                       INVH.invoice,
                       INVH.invtype,
                       INVH.invdate,
                       zbill.SR_OUTB,
                       ORD.shipid,
                       crec3.orderitem,
                       crec3.orderlot,
                       in_userid,
                       sysdate
                   );
                end loop;
              end if;
			  
              if nvl(RATE.apply_charge_reversal_yn,'N') = 'Y'
              then
              
                if RATE.cr_receipt_activity is null or RATE.cr_reversal_activity is null
                then
                  out_errmsg := 'Missing receipt or reversal activity for rate ' || RATE.custid || '/' || RATE.rategroup || '/' || RATE.activity || '/' || RATE.billmethod;
                  return zbill.BAD;
                end if;
          
                -- seperate out by lot if doing lot tracking
                for clots in (select distinct decode(track_lot,'Y',lotnumber,'O',lotnumber,'S',lotnumber,'A',lotnumber,null) lotnum,
                        orderitem, decode(track_lot,'Y',orderlot,'O',orderlot,'S',orderlot,'A',orderlot,null) orderlot
                        FROM shippingplate
                        WHERE orderid = ORD.orderid AND shipid = ORD.shipid AND custid = CUST.custid AND item = crec.item
                        AND type in ('F','P') AND status = 'SH')
                loop
				
                  charge_reversal.Delete();
                  
                  -- this will go over the relevant shipping plates, find the from order from the from plate, and get the rate
                  -- then it will sum up quantities by rate in an associate array, finally putting them in invoice detail
                  for crec3 in (SELECT *
                          FROM shippingplate
                          WHERE orderid = ORD.orderid AND shipid = ORD.shipid AND custid = CUST.custid AND item = crec.item
                          AND type in ('F','P') AND status = 'SH'
                          and nvl(decode(track_lot,'Y',lotnumber,'O',lotnumber,'S',lotnumber,'A',lotnumber,null),'(none)') = nvl(clots.lotnum,'(none)')
                          and nvl(orderitem,'Missing') = nvl(clots.orderitem,'Missing')
                          and nvl(decode(track_lot,'Y',orderlot,'O',orderlot,'S',orderlot,'A',orderlot,null),'(none)') = nvl(clots.orderlot,'(none)'))
                  loop
						
                    v_cr_rate := get_charge_reversal_rate(crec3, RATE.rategroup, RATE.cr_receipt_activity, RATE.uom, out_errmsg);
                    if out_errmsg != 'OKAY' then
                       out_errmsg := 'Error get charge reversal rate - ' || out_errmsg;
                       return zbill.BAD;
                    end if;
                    
                    v_cr_key := round(v_cr_rate * v_precision);
                    
                    zbut.translate_uom(CUST.custid, ITEM.item, crec3.quantity, crec3.unitofmeasure, RATE.uom, v_quantity, out_errmsg);
                    if out_errmsg != 'OKAY' then
                       out_errmsg := 'Problem converting ' || ITEM.item || ' from ' || crec3.unitofmeasure || ' to ' || RATE.uom || ': ' || out_errmsg;
                       return zbill.BAD;
                    end if;
						
                    -- enter the values into the associative array to sum up by rate
                    begin
                      charge_reversal(v_cr_key).quantity := charge_reversal(v_cr_key).quantity + v_quantity;
                      charge_reversal(v_cr_key).weight := charge_reversal(v_cr_key).weight + crec3.weight;
                    exception
                      when others then
                        charge_reversal(v_cr_key).quantity := v_quantity;
                        charge_reversal(v_cr_key).weight := crec3.weight;
                    end;
                  end loop;
					
                  -- after everything is summed above, we just need to enter in the invoice details
                  v_cr_key := charge_reversal.first;
                  while (v_cr_key is not null)
                  loop

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
                                     statusrsn,
                                     shipid,
                                     orderitem,
                                     orderlot,
                                     lastuser,
                                     lastupdate,
                                     businessevent
                                 )
                                 values
                                 (
                                     zbill.UNCHARGED,
                                     INVH.facility,
                                     CUST.custid,
                                     ORD.orderid,
                                     ITEM.item,
                                     decode(clots.lotnum, '(none)', null, clots.lotnum),
                                     RATE.cr_reversal_activity,
                                     now_date, --sysdate,
                                     zbill.BM_QTY,
                                     decode(crec2.automatic,'C',0,charge_reversal(v_cr_key).quantity),
                                     RATE.uom,
                                     charge_reversal(v_cr_key).weight,
                                     -1 * v_cr_key / v_precision,
                                     LOAD.loadno,
                                     INVH.invoice,
                                     INVH.invtype,
                                     INVH.invdate,
                                     zbill.SR_OUTB,
                                     ORD.shipid,
                                     clots.orderitem,
                                     decode(clots.orderlot, '(none)', null, clots.orderlot),
                                     in_userid,
                                     sysdate,
                                     l_event
                                 );
                 
                    v_cr_key := charge_reversal.next(v_cr_key);
                  end loop;
                end loop; -- loop over lots
              end if; -- charge reversals block
              
           end loop;

        end if;

   end loop;

   if multifac_shipid = 0 then

       rc := zbill.calc_automatic_charges(CUST.custid, CUST.rategroup,
          l_event, ORD, INVH, now_date);

-- Calc Small Package Ship Charges
       carrier_type := null;
       OPEN C_CAR(ORD.carrier);
       FETCH C_CAR into carrier_type;
       CLOSE C_CAR;

       if carrier_type = 'S' then
          -- rc := zbill.calc_automatic_charges(CUST.custid, CUST.rategroup,
          --    zbill.EV_SMALLPKG, ORD, INVH);
          rc := calc_order_charges(zbill.EV_SMALLPKG, in_userid,
                  CUST, ORD, INVH, LOAD, now_date);
       end if;

-- LTL/TL event processing only if shiptype of order not 'S'
       if ORD.shiptype = 'S' then
          rc := calc_order_charges(zbill.EV_SMALL, in_userid, CUST, ORD, INVH,
                LOAD, now_date);
       elsif ORD.shiptype = 'P' then
          rc := calc_order_charges(zbill.EV_CPCK, in_userid, CUST, ORD, INVH, 
                LOAD, now_date);
       elsif ORD.shiptype = 'C' then
          rc := calc_order_charges(zbill.EV_SEA, in_userid, CUST, ORD, INVH, 
                LOAD, now_date);
       else
          rc := calc_order_charges(zbill.EV_LTL, in_userid, CUST, ORD, INVH, LOAD,
                now_date);
       end if;

-- If this is a same day ship
       if ORD.priority = 'S' then
          rc := calc_order_charges(zbill.EV_SAMEDAYSHIP, in_userid,
                               CUST, ORD, INVH, LOAD, now_date);
       end if;


   end if;


-- Calculate the existing uncalculated line items.
    for crec in C_INVD(in_orderid, in_shipid, CUST.custid) loop
        errmsg := '';
        if zbill.calculate_detail_rate(crec.rowid, now_date, errmsg) = zbill.BAD then
           null;
           -- zut.prt('CR: '||errmsg);
        end if;
    end loop;

-- Determine all the possible mins in order

   if multifac_shipid = 0 then
       rc := calc_access_minimums(INVH, in_orderid, in_shipid,
                              CUST.custid,in_userid,now_date,out_errmsg);



       rc := zbsc.calc_surcharges(INVH, zbill.EV_SHIP ,
             in_orderid, in_shipid, in_userid, now_date, out_errmsg);


   end if;

   rc := zbsc.calc_access_inv_surcharges(INVH, zbill.EV_SHIP ,
             in_userid, now_date, out_errmsg);


   rc := 0;
   SELECT count(*)
     INTO rc
     FROM invoicedtl
    WHERE invoice = INVH.invoice;

   if nvl(rc,0) = 0 and in_invoice is null then
      DELETE invoicehdr
       WHERE invoice = INVH.invoice;
   end if;
		
   return zbill.GOOD;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'COutOrd: '||substr(sqlerrm,1,80);
    return zbill.BAD;
END calc_outbound_order;

----------------------------------------------------------------------
--
-- estimate_outbound_order -
--
----------------------------------------------------------------------
FUNCTION estimate_outbound_order
(
    in_orderid  IN      number,
    in_shipid   IN      number,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer
IS
  ORD   orderhdr%rowtype;
  XDORD orderhdr%rowtype;
  CUST  customer%rowtype;
  ITEM  custitem%rowtype;
  RATE  custrate%rowtype;
  INVH  invoicehdr%rowtype;
  l_event custratewhen.businessevent%type;
  v_count number;
  track_lot  char(1);
  do_calc    BOOLEAN;
  item_rategroup  custrate.rategroup%type;
  rc number;
  errmsg varchar2(255);
  CURSOR C_INVD(in_invoice number)
  IS
    SELECT rowid
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND billstatus = zbill.ESTIMATED;
BEGIN 

  ORD := NULL;
  OPEN C_ORDHDR(in_orderid, in_shipid);
  FETCH C_ORDHDR into ORD;
  CLOSE C_ORDHDR;
-- Verify order
  if ORD.orderid is null then
     out_errmsg := 'Invalid orderid = '|| in_orderid||'/'||in_shipid;
     return zbill.BAD;
  end if;
-- Check if order is crosdock order
  l_event := zbill.EV_SHIP;
-- Get the customer information for this outbound order
  if zbill.rd_customer(ORD.custid, CUST) = zbill.BAD then
     out_errmsg := 'Invalid custid = '|| ORD.custid;
     return zbill.BAD;
  end if;
  get_estimated_invoicehdr(CUST.custid, ORD.fromfacility, ORD.orderid, ORD.shipid, in_userid, INVH);
-- delete old estimated charges
  select count(1) into v_count
  from invoicedtl
  where invoice = INVH.invoice and billstatus = zbill.ESTIMATED;
  if (v_count > 0) then
    delete from invoicedtl
    where invoice = INVH.invoice and billstatus = zbill.ESTIMATED;
  end if;
-- For each item
  for crec in C_LD_ITEMS(ORD.orderid, ORD.shipid) loop
    do_calc := TRUE;
    if zbill.rd_item(CUST.custid, crec.item, ITEM) = zbill.BAD then
      do_calc := FALSE;
    end if;
    -- zut.prt('Customer item found:'||CUST.custid||'/'||crec.item);
    -- Determine if we are tracking lots or not
    track_lot := ITEM.lotrequired;
    if track_lot = 'C' then
      track_lot := CUST.lotrequired;
    end if;
    if ITEM.lotsumaccess = 'Y' then
      track_lot := 'N';
    end if;
  -- For this item determine it we are billing anything for this order
    if do_calc then
      zbill.rd_item_rategroup(ITEM.custid, ITEM.item, item_rategroup);
      for crec2 in zbill.C_RATE_WHEN(CUST.custid, item_rategroup, l_event, INVH.facility, INVH.invdate) loop
        if zbill.rd_rate(rategrouptype(crec2.custid, crec2.rategroup),crec2.activity,crec2.billmethod, INVH.invdate, RATE) = zbill.BAD then
            null;
        end if;
        if RATE.billmethod in
           (zbill.BM_QTY, zbill.BM_QTYM, zbill.BM_FLAT,
            zbill.BM_CWT, zbill.BM_WT, zbill.BM_QTY_BREAK,
            zbill.BM_FLAT_BREAK, zbill.BM_WT_BREAK, zbill.BM_CWT_BREAK, zbill.BM_PCT_SALE)
        then
          -- Determine qty's for this item including handling codes
          --   if necessary
          for crec3 in C_EST_QTY(in_orderid, in_shipid, CUST.custid, ITEM.item, track_lot) loop
            if RATE.billmethod = zbill.BM_FLAT then
              crec3.qty := 1;
            end if;
            -- Add entry for this type
            INSERT INTO invoicedtl
              (billstatus, facility, custid, orderid, item, lotnumber, activity, activitydate, billmethod,
               enteredqty, entereduom, enteredweight, loadno, invoice, invtype, invdate, statusrsn,
               shipid, orderitem, orderlot, lastuser, lastupdate, businessevent)
            values
              (zbill.ESTIMATED, INVH.facility, CUST.custid, ORD.orderid, ITEM.item, crec3.lotnum, RATE.activity, INVH.invdate, RATE.billmethod,
               decode(crec2.automatic,'C',0,crec3.qty), crec3.unitofmeasure, crec3.weight, null, INVH.invoice, INVH.invtype, INVH.invdate, zbill.SR_OUTB,
               ORD.shipid, crec3.orderitem, crec3.orderlot, in_userid, sysdate, l_event );
          end loop;
        end if; 
      end loop;
    end if;
  end loop;
  rc := zbill.calc_automatic_charges(CUST.custid, CUST.rategroup, l_event, ORD, INVH, INVH.invdate);
  for crec in C_INVD(INVH.invoice) loop
    errmsg := '';
    if zbill.calculate_detail_rate(crec.rowid, INVH.invdate, errmsg) = zbill.BAD then
       null;
    end if;
  end loop;
  rc := calc_access_minimums(INVH, in_orderid, in_shipid, CUST.custid,in_userid,INVH.invdate,errmsg);
  v_count := 0;
  SELECT count(*) INTO v_count
  FROM invoicedtl
  WHERE invoice = INVH.invoice;
  if nvl(v_count,0) = 0 then
    DELETE invoicehdr
    WHERE invoice = INVH.invoice;
  end if;
  return zbill.GOOD;
END estimate_outbound_order;
----------------------------------------------------------------------
--
-- rollover_estimated_charges -
--
----------------------------------------------------------------------
FUNCTION rollover_estimated_charges
(
    in_invoice  IN      number, 
    in_orderid  IN      number,
    in_shipid   IN      number,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer
IS
  v_count number;
  v_inv_from invoicehdr%rowtype;
  v_inv_to   invoicehdr%rowtype;
  v_orderhdr orderhdr%rowtype;
BEGIN
  begin
    select * into v_inv_to
    from invoicehdr
    where invoice = in_invoice;
  exception
    when others then
      out_errmsg := 'Invoice could not be found';
      return zbill.BAD;
  end;
  begin
    select * into v_inv_from
    from invoicehdr
    where invoice = -1 * (in_orderid * 100 + in_shipid);
  exception
    when others then
      out_errmsg := 'Invoice could not be found';
      return zbill.BAD;
  end;
  if (v_inv_to.invtype <> zbill.IT_ACCESSORIAL 
    or v_inv_to.invstatus not in (zbill.UNCHARGED, zbill.NOT_REVIEWED, zbill.REVIEWED)
    or v_inv_from.invtype <> zbill.IT_ACCESSORIAL
    or v_inv_from.invstatus <> zbill.ESTIMATED)
  then
    out_errmsg := 'Wrong invoice type or status';
    return zbill.BAD;
  end if;
  if (v_inv_from.custid <> v_inv_to.custid or v_inv_from.facility <> v_inv_to.facility) then
    out_errmsg := 'Incompatable invoices';
    return zbill.BAD;
  end if;
  select * into v_orderhdr
  from orderhdr
  where orderid = in_orderid and shipid = in_shipid;
  delete from invoicehdr where invoice = v_inv_from.invoice;
  update invoicedtl
  set invoice = v_inv_to.invoice,
      lastupdate = sysdate,
      lastuser = in_userid
  where invoice = v_inv_from.invoice and billstatus = zbill.DELETED;
  update invoicedtl
  set invoice = v_inv_to.invoice,
      billstatus = zbill.NOT_REVIEWED,
      invdate = v_inv_to.invdate,
      loadno = v_orderhdr.loadno, 
      stopno = v_orderhdr.stopno,
      shipno = v_orderhdr.shipno,
      lastupdate = sysdate,
      lastuser = in_userid
  where invoice = v_inv_from.invoice and billstatus = zbill.ESTIMATED;
  update invoicehdr
  set lastupdate = sysdate,
      lastuser = in_userid,
      invstatus = zbill.NOT_REVIEWED
  where invoice = v_inv_to.invoice;
  out_errmsg := 'OKAY';
  return zbill.GOOD;
exception
  when others then
    out_errmsg := 'Rollover_Estimated_Charges: ' || sqlerrm(sqlcode);
    return zbill.BAD;
END rollover_estimated_charges; 
----------------------------------------------------------------------
--
-- delete_estimated_charges -
--
----------------------------------------------------------------------
FUNCTION delete_estimated_charges
(
    in_orderid  IN      number,
    in_shipid   IN      number,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer
IS
  v_invoice number;
  ORD   orderhdr%rowtype;
BEGIN
-- Get the order
  ORD := NULL;
  OPEN C_ORDHDR(in_orderid, in_shipid);
  FETCH C_ORDHDR into ORD;
  CLOSE C_ORDHDR;
-- Verify order
  if ORD.orderid is null then
     out_errmsg := 'Invalid orderid = '|| in_orderid||'/'||in_shipid;
     return zbill.BAD;
  end if;
  v_invoice := -1 * (in_orderid * 100 + in_shipid);
  delete from invoicehdr where invoice = v_invoice;
  delete from invoicedtl where invoice = v_invoice;
  out_errmsg := 'OKAY';
  return zbill.GOOD;
exception
  when others then
    out_errmsg := 'Delete_Estimated_Charges: ' || sqlerrm(sqlcode);
    return zbill.BAD;
END delete_estimated_charges;

----------------------------------------------------------------------
--
-- complete_multi_facility_order -
--
----------------------------------------------------------------------
FUNCTION complete_multi_facility_order
(
    in_orderid  IN      number,
    in_shipid   IN      number,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer
IS
  CUST  customer%rowtype;
  ITEM  custitem%rowtype;
  RATE  custrate%rowtype;
  ORD   orderhdr%rowtype;
  LOAD  loads%rowtype;
  INVH  invoicehdr%rowtype;
  FAC   facility%rowtype;


  errmsg     varchar2(200);
  do_calc    BOOLEAN;
  track_lot  char(1);
  recmethod  varchar2(2);


-- Local cursors

  CURSOR C_HTYPE(in_activity varchar2)
  IS
    SELECT count(1)
      FROM handlingtypes
     WHERE activity = in_activity;


  CURSOR C_INVD(in_orderid number, in_shipid number, in_custid varchar2)
  IS
    SELECT rowid
      FROM invoicedtl
     WHERE orderid = in_orderid
       AND shipid = in_shipid
       AND custid = in_custid
       AND billstatus = zbill.UNCHARGED;

  CURSOR C_CAR(in_carrier varchar2)
  IS
    SELECT carriertype
      FROM carrier
     WHERE carrier = in_carrier;



  orderid orderhdr.orderid%type;
  carrier_type carrier.carriertype%type;

  qty C_QTY%rowtype;

 rc integer;
 cnt integer;

 now_date date;

 multifac_shipid integer;



BEGIN
-- Upon close of the outbound order we need to calculate the charges
--   we are generating for the accessorial (outbound) invoice
--   this may require rolling multiple detail lines into
--   a single 'new' billing record or
--   processing the individual invoicedtl lines


-- Get the base order
    ORD := NULL;
    OPEN C_ORDHDR(in_orderid, in_shipid);
    FETCH C_ORDHDR into ORD;
    CLOSE C_ORDHDR;

-- Verify order
    if ORD.orderid is null then
       out_errmsg := 'Invalid orderid = '|| in_orderid||'/'||in_shipid;
       return zbill.BAD;
    end if;

    now_date := nvl(nvl(ORD.dateshipped,ORD.statusupdate),sysdate);

-- Get the load
    LOAD := null;
    OPEN C_LOAD(ORD.loadno);
    FETCH C_LOAD into LOAD;
    CLOSE C_LOAD;

--    if LOAD.loadno is null then
--       LOAD.facility := nvl(ORD.fromfacility,ORD.tofacility);
--    end if;


-- Get the customer information for this outbound order
    if zbill.rd_customer(ORD.custid, CUST) = zbill.BAD then
       out_errmsg := 'Invalid custid = '|| ORD.custid;
       -- zut.prt(out_errmsg);
       return zbill.BAD;
    end if;


-- Set multi-facility flag
    multifac_shipid := check_multi_facility(ORD.orderid, ORD.shipid);
    if multifac_shipid = 0 then
        return zbill.BAD;
    end if;


-- Create Invoice header if we have misc charges for this load
   INVH := null;

   rc := get_invoicehdr_accessorial('Find', CUST.custid,
                 nvl(ORD.fromfacility,ORD.tofacility), ORD.loadno, -- was LOAD.facility
                 in_userid,now_date, INVH);



   rc := zbill.calc_automatic_charges(CUST.custid, CUST.rategroup,
      zbill.EV_SHIP, ORD, INVH, now_date);

-- Calc Small Package Ship Charges
   carrier_type := null;
   OPEN C_CAR(ORD.carrier);
   FETCH C_CAR into carrier_type;
   CLOSE C_CAR;

   if carrier_type = 'S' then
      -- rc := zbill.calc_automatic_charges(CUST.custid, CUST.rategroup,
      --    zbill.EV_SMALLPKG, ORD, INVH);
      rc := calc_order_charges(zbill.EV_SMALLPKG, in_userid,
              CUST, ORD, INVH, LOAD, now_date);
   end if;

-- LTL/TL event processing only if shiptype of order not 'S'
   if ORD.shiptype = 'S' then
      rc := calc_order_charges(zbill.EV_SMALL, in_userid, CUST, ORD, INVH,
            LOAD, now_date);
   else
      rc := calc_order_charges(zbill.EV_LTL, in_userid, CUST, ORD, INVH, LOAD,
            now_date);
   end if;

-- Business event for shipping customer pickup orders
   if ORD.shiptype = 'P' then
      rc := calc_order_charges(zbill.EV_CPCK, in_userid, CUST, ORD, INVH, LOAD,
            now_date);
   end if;

-- If this is a same day ship
   if ORD.priority = 'S' then
      rc := calc_order_charges(zbill.EV_SAMEDAYSHIP, in_userid,
                           CUST, ORD, INVH, LOAD, now_date);
   end if;


-- Calculate the existing uncalculated line items.
    for crec in C_INVD(in_orderid, in_shipid, CUST.custid) loop
        errmsg := '';
        if zbill.calculate_detail_rate(crec.rowid, now_date, errmsg) = zbill.BAD then
           null;
           -- zut.prt('CR: '||errmsg);
        end if;
    end loop;

-- Determine all the possible mins in order

   rc := calc_access_minimums(INVH, in_orderid, in_shipid,
                          CUST.custid,in_userid,now_date,out_errmsg);



   rc := zbsc.calc_surcharges(INVH, zbill.EV_SHIP ,
         in_orderid, in_shipid, in_userid, now_date, out_errmsg);


   rc := zbsc.calc_access_inv_surcharges(INVH, zbill.EV_SHIP ,
             in_userid, now_date, out_errmsg);


   rc := 0;
   SELECT count(*)
     INTO rc
     FROM invoicedtl
    WHERE invoice = INVH.invoice;

   return zbill.GOOD;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CMFOrd: '||substr(sqlerrm,1,80);
    return zbill.BAD;
END complete_multi_facility_order;


----------------------------------------------------------------------
--
-- calc_access_bills -
--
----------------------------------------------------------------------
FUNCTION calc_access_bills
(
    in_loadno   IN      number,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer
IS
  CURSOR C_LDCUST(in_loadno number)
  IS
    SELECT orderid,
           shipid,
		   ordertype,
		   bill_freight_yn
      FROM orderhdr
     WHERE loadno = in_loadno;

  rc integer;

  CURSOR C_LD_OLD(in_loadno number)
  IS
    SELECT count(1)
      FROM orderhdr
     WHERE loadno = in_loadno;

  CURSOR C_LD(in_loadno number)
  IS
    SELECT count(distinct orderid *100
                + decode(nvl(C.multifac_picking,'N'),'Y',1,shipid) )
      FROM customer C, orderhdr O
     WHERE loadno = in_loadno
       AND C.custid = O.custid;

  cnt integer;

  CURSOR C_LD_CUSTID(in_loadno number)
  IS
    SELECT distinct fromfacility, custid
      FROM orderhdr
     WHERE loadno = in_loadno;

  CURSOR C_LD_ORDERID(in_loadno number, in_custid varchar2)
  IS
    SELECT orderid, shipid
      FROM orderhdr
     WHERE loadno = in_loadno
       AND custid = in_custid;

  ORD C_LD_ORDERID%rowtype;

  CURSOR C_MFPO(in_loadno number)
  IS
    SELECT distinct orderid, min(shipid) shipid
      FROM customer C, orderhdr O
     WHERE loadno = in_loadno
       AND C.custid = O.custid
       AND nvl(C.multifac_picking,'N') = 'Y'
     GROUP by orderid
     HAVING count(shipid) > 1;
	 
	CURSOR C_SYSTEMDEFAULTS(in_defaultid varchar2)
	IS
		select	defaultvalue
		  from	systemdefaults
		 where	defaultid = in_defaultid;
		 
	sysdefault_trace    systemdefaults.defaultvalue%type;
	
BEGIN
  out_errmsg := ''; 
  
  for crec in C_LDCUST(in_loadno) loop
    -- Process Freight order
    if (crec.ordertype = 'F' ) or
	     (crec.ordertype = 'O' and crec.bill_freight_yn = 'Y') then
  	  OPEN C_SYSTEMDEFAULTS('TRACEFREIGHTBILLING');
		  FETCH C_SYSTEMDEFAULTS INTO sysdefault_trace;
		  CLOSE C_SYSTEMDEFAULTS;
	
	    rc := calc_freight_order(in_loadno, in_userid, sysdefault_trace, out_errmsg);
		 
      if rc != zbill.GOOD then
        return zbill.BAD;
	    end if;
	  
		  if crec.ordertype = 'F' then
		    return  zbill.GOOD;
	    end if;
    
    end if;   
      -- Process Outbound order
    rc := calc_outbound_order(NULL, in_loadno, crec.orderid, crec.shipid,
                              in_userid, out_errmsg);				  
    if rc != zbill.GOOD then
      return zbill.BAD;
    end if;
    
  end loop;
  
  -- delete bad data from the pallethistory table (orders that were on load but taken off)
  delete from pallethistory a
  where loadno = in_loadno
    and not exists (select 1 from orderhdr where orderid = a.orderid and shipid = a.shipid and loadno = a.loadno);
  
  out_errmsg := 'OKAY';

-- Check for Master BOL requirement to charge
   cnt := 0;
   OPEN C_LD(in_loadno);
   FETCH C_LD into cnt;
   CLOSE C_LD;

   if cnt > 1 then
      for crec in C_LD_CUSTID(in_loadno) loop
          -- determine an order for this
          OPEN C_LD_ORDERID(in_loadno, crec.custid);
          FETCH C_LD_ORDERID into ORD;
          CLOSE C_LD_ORDERID;

          rc := calc_accessorial_charges(zbill.EV_MASTERBOL,
              crec.fromfacility,
              in_loadno,
              ORD.orderid,
              ORD.shipid,
              in_userid,
              out_errmsg);
      end loop;

   end if;

  for crec in C_MFPO(in_loadno) loop
    rc := complete_multi_facility_order(crec.orderid, crec.shipid,
            in_userid, out_errmsg);
    null;
  end loop;



  return zbill.GOOD;
EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CAccMins: '||substr(sqlerrm,1,80);
--    rollback;
    return zbill.BAD;
END calc_access_bills;

----------------------------------------------------------------------
--
-- recalc_access_bills -
--
----------------------------------------------------------------------
FUNCTION recalc_access_bills
(
    in_invoice  IN      number,
    in_loadno   IN      number,   -- really a dummy field
    in_custid   IN      varchar2,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer
IS
  INVH  invoicehdr%rowtype;

  CURSOR C_ORDS(in_invoice number)
  IS
    SELECT distinct orderid, shipid, loadno
      FROM invoiceorders
     WHERE invoice = in_invoice;

  rc integer;

  CURSOR C_MF_ORDS(in_invoice number)
  IS
    SELECT distinct I.orderid, min(I.shipid) shipid
      FROM customer C, orderhdr O, invoiceorders I
     WHERE I.invoice = in_invoice
       AND O.orderid = I.orderid
       AND O.shipid = I.shipid
       AND C.custid = O.custid
       AND nvl(C.multifac_picking,'N') = 'Y'
     GROUP by I.orderid
     HAVING count(I.shipid) > 1;

  CURSOR C_INVD(in_invoice number)
  IS
    SELECT rowid
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND billstatus = zbill.UNCHARGED;
  
  errmsg varchar2(255);

  l_shipid integer;

BEGIN
-- Try to locate the existing invoice header
   INVH := null;

-- Get the invoice hdr
   OPEN zbill.C_INVH(in_invoice);
   FETCH zbill.C_INVH into INVH;
   CLOSE zbill.C_INVH;
	
   if INVH.invstatus = zbill.BILLED then
      out_errmsg := 'Invalid Invoice. Already billed.';
      return zbill.BAD;
   end if;
	
   DELETE from invoiceorders
    WHERE invoice = in_invoice;

   INSERT INTO invoiceorders(invoice, orderid, shipid, loadno )
   SELECT distinct I.invoice, I.orderid, I.shipid, O.loadno
     FROM invoicedtl I, orderhdr O
    WHERE I.invoice = in_invoice
      AND I.invtype = 'A'
      AND I.statusrsn = zbill.SR_OUTB -- New line to not pick up MISC acc
      AND I.orderid = O.orderid(+)
      AND I.shipid = O.shipid(+);

-- get rid of old info since this is a recalc
   DELETE from invoicedtl
    WHERE custid = in_custid
      AND invoice = in_invoice
      AND statusrsn = zbill.SR_OUTB;

   UPDATE invoicehdr
      SET invstatus = zbill.NOT_REVIEWED,
          masterinvoice = null
    WHERE invoice = in_invoice;

    UPDATE invoicedtl
       SET billstatus = zbill.UNCHARGED
     WHERE invoice = in_invoice
       AND billstatus not in  (zbill.DELETED, zbill.BILLED);


   OPEN zbill.C_INVH(in_invoice);
   FETCH zbill.C_INVH into INVH;
   CLOSE zbill.C_INVH;

-- Calculate the existing uncalculated line items.
    for crec in C_INVD(in_invoice) loop
        errmsg := '';
        if zbill.calculate_detail_rate(crec.rowid, INVH.invdate, errmsg) = zbill.BAD then
           null;
        end if;
    end loop;

-- Recalc the entries just hanging around
    for crec in (SELECT rowid
                   FROM invoicedtl
                  WHERE invoice = INVH.invoice
                    AND billstatus = zbill.UNCHARGED) loop
        out_errmsg := '';
        if zbill.calculate_detail_rate(crec.rowid, sysdate,
                                  out_errmsg) = zbill.BAD then
           null;
        end if;
    end loop;

-- For every order in the invoice recalc
   for crec in C_ORDS(in_invoice) loop
      rc := calc_outbound_order(in_invoice, crec.loadno,
                  crec.orderid, crec.shipid,
                  in_userid, out_errmsg);
      if rc != zbill.GOOD then
--         rollback;
         return zbill.BAD;
      end if;

   end loop;

-- For every order that could be a multifacility pick try to complete it

    for crec in (select * from invoiceorders
                  where invoice = in_invoice)
    loop
        l_shipid := check_multi_facility(crec.orderid, crec.shipid);
        if l_shipid = crec.shipid then
          rc := complete_multi_facility_order(crec.orderid, crec.shipid,
              in_userid, out_errmsg);
        end if;
    end loop;




-- Cleanup after ourselves

   DELETE invoiceorders
    WHERE invoice = in_invoice;

    out_errmsg := 'OKAY';
    return zbill.GOOD;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'RecalcA: '||substr(sqlerrm,1,80);
--    rollback;
    return zbill.BAD;
END recalc_access_bills;


----------------------------------------------------------------------
--
-- calc_accessorial_charges -
--
----------------------------------------------------------------------
FUNCTION calc_accessorial_charges
(
    in_event    IN      varchar2,
    in_facility IN      varchar2,
    in_loadno   IN      number,
    in_orderid  IN      number,
    in_shipid   IN      number,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer
IS
  CUST  customer%rowtype;
  ITEM  custitem%rowtype;
  RATE  custrate%rowtype;
  ORD   orderhdr%rowtype;
  LOAD  loads%rowtype;
  INVH  invoicehdr%rowtype;


  errmsg     varchar2(200);
  recmethod  varchar2(2);


-- Local cursors

  CURSOR C_HTYPE(in_activity varchar2)
  IS
    SELECT count(1)
      FROM handlingtypes
     WHERE activity = in_activity;


  CURSOR C_INVD(in_orderid number, in_custid varchar2)
  IS
    SELECT rowid
      FROM invoicedtl
     WHERE orderid = in_orderid
       AND custid = in_custid
       AND billstatus = zbill.UNCHARGED;

  CURSOR C_CAR(in_carrier varchar2)
  IS
    SELECT carriertype
      FROM carrier
     WHERE carrier = in_carrier;



  orderid orderhdr.orderid%type;
  carrier_type carrier.carriertype%type;

  qty C_QTY%rowtype;

 rc integer;

 now_date date;

 mark varchar2(10);

BEGIN
-- Upon close of the outbound order we need to calculate the charges
--   we are generating for the accessorial (outbound) invoice
--   this may require rolling multiple detail lines into
--   a single 'new' billing record or
--   processing the individual invoicedtl lines

    mark := 'start';
-- Get the order
    ORD := NULL;
    OPEN C_ORDHDR(in_orderid, in_shipid);
    FETCH C_ORDHDR into ORD;
    CLOSE C_ORDHDR;

    now_date := nvl(nvl(ORD.dateshipped,ORD.statusupdate),sysdate);


-- Verify order
    mark := 'Orderid';
    if ORD.orderid is null then
       out_errmsg := 'Invalid orderid = '|| in_orderid||'/'||in_shipid;
       return zbill.BAD;
    end if;

-- Get the load
    mark := 'C_LOAD';
    LOAD := null;
    OPEN C_LOAD(in_loadno);
    FETCH C_LOAD into LOAD;
    CLOSE C_LOAD;

    if LOAD.loadno is null then
       LOAD.facility := in_facility;
    end if;


-- Get the customer information for this outbound order
    mark := 'rd_cust';
    if zbill.rd_customer(ORD.custid, CUST) = zbill.BAD then
       out_errmsg := 'Invalid custid = '|| ORD.custid;
       -- zut.prt(out_errmsg);
       return zbill.BAD;
    end if;

-- Create Invoice header if we have misc charges for this load
    mark := 'get_invh';
   INVH := null;

   rc := get_invoicehdr_accessorial('Find', CUST.custid,
                     in_facility, in_loadno,  -- was LOAD.facility,
                     in_userid,now_date, INVH);

    mark := 'calc_auto';
   INVH.invtype := zbill.IT_MISC; -- To not mark as auto misc charge
   rc := zbill.calc_automatic_charges(CUST.custid, CUST.rategroup,
      in_event, ORD, INVH, now_date);

-- Calculate the existing uncalculated line items.
    mark := 'C_INVD';
    for crec in C_INVD(in_orderid, CUST.custid) loop
        errmsg := '';
        if zbill.calculate_detail_rate(crec.rowid, now_date, errmsg) = zbill.BAD then
           null;
           -- zut.prt('CR: '||errmsg);
        end if;
    end loop;


    mark := 'CNT invd';
   rc := 0;
   SELECT count(*)
     INTO rc
     FROM invoicedtl
    WHERE invoice = INVH.invoice;

   if nvl(rc,0) = 0 then
      DELETE invoicehdr
       WHERE invoice = INVH.invoice;
   end if;

    mark := 'END';
   return zbill.GOOD;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CAccChrg @'||mark||': '||substr(sqlerrm,1,80);
    return zbill.BAD;
END calc_accessorial_charges;


----------------------------------------------------------------------
--
-- locate_accessorial_invoice
--
----------------------------------------------------------------------
PROCEDURE locate_accessorial_invoice
(
    in_custid   IN      varchar2,
    in_facility IN      varchar2,
    in_userid   IN      varchar2,
    out_invoice OUT     number,
    out_errno   OUT     number,
    out_errmsg  OUT     varchar2
)
IS
  rc integer;
  INVH invoicehdr%rowtype;

BEGIN
    out_invoice := null;
    out_errno := 0;
    out_errmsg := 'OKAY';

    INVH := null;

    rc := get_invoicehdr_accessorial('Find', in_custid,
                     in_facility, null, in_userid,sysdate, INVH);


    if INVH.invoice is null then
       out_errno := 101;
       out_errmsg := 'Could not locate invoice.';
    end if;
    out_invoice := INVH.invoice;

EXCEPTION WHEN OTHERS THEN
    out_errno := sqlcode;
    out_errmsg := 'LAccInv @'||': '||substr(sqlerrm,1,80);
END locate_accessorial_invoice;


----------------------------------------------------------------------
--
-- calc_accessorial_invoice
--
----------------------------------------------------------------------
PROCEDURE calc_accessorial_invoice
(
    in_invoice  IN      number,
    out_errno   OUT     number,
    out_errmsg  OUT     varchar2
)
IS
   errmsg varchar2(200);
  CURSOR C_INVD(in_invoice number)
  IS
    SELECT rowid
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND billstatus = zbill.UNCHARGED;


BEGIN
    out_errno := 0;
    out_errmsg := 'OKAY';

    for crec in C_INVD(in_invoice) loop
        errmsg := '';
        if zbill.calculate_detail_rate(crec.rowid, sysdate, errmsg) = zbill.BAD then
           null;
        end if;
    end loop;


EXCEPTION WHEN OTHERS THEN
    out_errno := sqlcode;
    out_errmsg := 'CAccInvChrg @'||': '||substr(sqlerrm,1,80);
END calc_accessorial_invoice;

----------------------------------------------------------------------
--
-- approve_accessorials
--
----------------------------------------------------------------------
PROCEDURE approve_accessorials
(
    in_date     IN      date,
    out_errmsg  OUT     varchar2
)
IS
  CURSOR C_ACCESS(in_date date)
  IS
    SELECT I.*
      FROM customer C, invoicehdr I
     WHERE I.invtype = 'A'
       AND I.invstatus = zbill.NOT_REVIEWED
       AND I.renewtodate < in_date
       AND I.custid = C.custid
       AND C.outbautobill = 'Y';

 n1      number;
 n2      number;
 n3      number;
 terrmsg varchar2(200);

BEGIN
    out_errmsg := 'OKAY';

-- Check for rerun of the process
    if not zbs.check_daily_billing(in_date) then
        out_errmsg := 'Check daily billing failed for approve accessorials dt:'
               || to_char(in_date,'YYYYMMDD');
        return;
    end if;



    for crec in C_ACCESS(in_date) loop
        zbill.approve_invoice(crec.invoice, zbill.NOT_REVIEWED,
              'BILLING', n1, n2, n3, terrmsg);
    end loop;


EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CAppAcc @'||': '||substr(sqlerrm,1,80);
END approve_accessorials;

----------------------------------------------------------------------
--
-- calc_freight_order
--
----------------------------------------------------------------------
FUNCTION calc_freight_order
(
  in_loadno    IN      number,
  in_userid    IN      varchar2,
  in_trace     IN OUT  varchar2,
  out_errmsg   IN OUT  varchar2
)
RETURN integer
IS
	LOADED			CONSTANT        varchar2(12 byte) := '9';

	CURSOR C_LOADS(in_loadno number)
	IS
		SELECT *
		  FROM loads
		 WHERE loadno = in_loadno
		   AND loadstatus = LOADED;

	CURSOR C_LOADSTOP(in_loadno number)
	IS
		SELECT loadno, stopno
		  FROM loadstop
		 WHERE loadno = in_loadno
		   AND loadstopstatus = LOADED;

	CURSOR C_LOADSTOPSHIP(in_loadno number)
	IS
		SELECT *
		  FROM loadstopship
		 WHERE loadno = in_loadno;
		   
	CURSOR	C_ORDERHDR(in_loadno number, in_stopno number)
	IS
	SELECT	orderid, shipid, wave, dateshipped, statusupdate, ordertype
	  FROM	orderhdr
		 WHERE loadno = in_loadno
		   AND stopno = in_stopno
	   AND  (ordertype = 'F'
				OR
			(ordertype = 'O' and bill_freight_yn = 'Y'))
	   AND	orderstatus = LOADED;
	
	LOADS			C_LOADS%rowtype;
	LOADSTOP		C_LOADSTOP%rowtype;
	LOADSTOPSHIP	C_LOADSTOPSHIP%rowtype;
	ORDERHDR		C_ORDERHDR%rowtype;
	now_date		date;
	rc 				number;
	log_msg			varchar2(4000);
	out_logmsg		varchar2(4000);
	
BEGIN
	out_errmsg := 'OKAY';
	
	if in_trace = 'Y' then
		zms.log_autonomous_msg(zfbill.author, null, null, 
			'Start Calc Freight Order for loadno <'||in_loadno||'>',
			'T',in_userid, out_logmsg);
	end if;
	
	-- verify load
	OPEN C_LOADS(in_loadno);
	FETCH C_LOADS INTO LOADS;
	if C_LOADS%NOTFOUND then
		out_errmsg := 'No load found for <'||in_loadno||'>. Check load status';
		return zbill.BAD;
	end if;
	CLOSE C_LOADS;
	
	-- verify loadstop
	OPEN C_LOADSTOP(in_loadno);
	FETCH C_LOADSTOP INTO LOADSTOP;
	if C_LOADSTOP%NOTFOUND then
		out_errmsg := 'No loadstop found for load <'||in_loadno||'>. Check load status';
		return zbill.BAD;
		end if;
	CLOSE C_LOADSTOP;
	
	-- verify loadstopship
	OPEN C_LOADSTOPSHIP(in_loadno);
	FETCH C_LOADSTOPSHIP INTO LOADSTOPSHIP;
	if C_LOADSTOPSHIP%NOTFOUND then
		out_errmsg := 'No loadstopship found for load <'||in_loadno||'>. Check load status';
		return zbill.BAD;
	end if;
	CLOSE C_LOADSTOPSHIP;

	-- Loop through all the orders for each loadstop
	for crec_loadstop in C_LOADSTOP(in_loadno)
	loop
		OPEN C_ORDERHDR(crec_loadstop.loadno, crec_loadstop.stopno);
	FETCH C_ORDERHDR INTO ORDERHDR;
			if C_ORDERHDR%NOTFOUND then
				out_errmsg := 'No order found for load/loastop <'||
					crec_loadstop.loadno||'/'||crec_loadstop.stopno||'>'||' Check order status.';
				return zbill.BAD;
			end if;
	CLOSE C_ORDERHDR;
	
		for crec_ord in C_ORDERHDR(crec_loadstop.loadno, crec_loadstop.stopno)
		loop	
			-- verify order is not in a wave
			if crec_ord.wave is not null and crec_ord.ordertype = 'F' then
				out_errmsg :=	'Order <'||crec_ord.orderid||'> should not be in a wave';
		return zbill.BAD;
	end if;
	
			now_date := nvl(nvl(crec_ord.dateshipped,crec_ord.statusupdate),sysdate);
	
			-- create invoices
			rc := create_freight_invoice
					(	NULL, 
						crec_loadstop.loadno, 
						crec_loadstop.stopno, 
						crec_ord.orderid, 
						crec_ord.shipid, 
						now_date,
						in_userid,
						in_trace,
						out_errmsg );

			if rc != zbill.GOOD then
				return zbill.BAD;
		end if;
		
		end loop;
	end loop;
	
	if in_trace = 'Y' then
		zms.log_autonomous_msg(zfbill.author, null, null, 
			'End Calc Freight Order for loadno <'||in_loadno||'>',
			'T',in_userid, out_errmsg);
	end if;

	return zbill.GOOD;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'calc_freight_order: ' ||substr(sqlerrm,1,80);
			return zbill.BAD;
END calc_freight_order;


----------------------------------------------------------------------
-- create_freight_invoice
----------------------------------------------------------------------
FUNCTION create_freight_invoice
( in_invoice           IN      number,
  in_loadno            IN      number,
  in_stopno            IN      number,
  in_orderid           IN      number,
  in_shipid            IN      number,
  in_surcharge_effdate IN      date,
  in_userid            IN      varchar2,
  in_trace             IN OUT  varchar2,
  out_errmsg           IN OUT  varchar2
)
RETURN integer
IS
	CURSOR C_LOADSTOP(in_loadno number, in_stopno number)
	IS
		SELECT *
		  FROM loadstop
		 WHERE loadno = in_loadno
		   AND stopno = in_stopno;

	CURSOR C_FREIGHT_BILL_RESULTS(in_loadno number, in_stopno number)
	IS
		SELECT *
		  FROM freight_bill_results
		 WHERE loadno = in_loadno
		   AND stopno = in_stopno
		   AND (chargestype = 'FREIGHT_TOTAL_CHARGES' OR
				      chargestype LIKE 'ACCESSORIALS%' OR
				      chargestype = 'FUELSURCHARGE' OR
				      chargestype = 'COD_CHARGES');
				
	CURSOR C_CUSTFAC(in_custid varchar2, in_facility varchar2)
	IS
	  SELECT *
		FROM custfacility
	   WHERE facility = in_facility
		 AND custid = in_custid;
	 
	CUST                       customer%rowtype;
	ORD                        orderhdr%rowtype;
	INVH                       invoicehdr%rowtype;
	CUSTFAC                    c_custfac%rowtype;
	LOADSTOP                   c_loadstop%rowtype;
	out_rategroup              custrategroup%rowtype;
	out_tariffaccessorials     tariffaccessorials%rowtype;
	out_max_truckload_y_n      varchar2(1);
	out_max_truckload_charges  number(10,2);
	now_date                   date;
	log_msg                    varchar2(4000);
	out_logmsg                 varchar2(4000);
	errmsg                     varchar2(200);
 rc                         integer;
 TYPE cur_type is REF CURSOR;
 cr_classes                 cur_type;
 l_freight_class            nmfclasscodes.class%type;
 l_cwt_qty                  orderdtl.weightship%type;
 l_qtyentered               orderdtl.qtyentered%type;
 l_class_count              pls_integer;

BEGIN
	out_errmsg := 'OKAY';
		
	-- Get order
    OPEN C_ORDHDR(in_orderid, in_shipid);
    FETCH C_ORDHDR into ORD;
    if C_ORDHDR%NOTFOUND then
      CLOSE C_ORDHDR;
		    out_errmsg := 'No order found for orderid <'||in_orderid||'>';
		    return zbill.BAD;
		  end if;
    CLOSE C_ORDHDR;
		
    now_date := nvl(nvl(ORD.dateshipped,ORD.statusupdate),sysdate);
	
	-- Get customer
	if zbill.rd_customer(ORD.custid, CUST) = zbill.BAD then
		out_errmsg := 'Invalid custid = '|| ORD.custid;
		return zbill.BAD;
			end if;

	-- Get customer facility
	OPEN C_CUSTFAC(ORD.custid, ORD.fromfacility);
	FETCH C_CUSTFAC INTO CUSTFAC;
	CLOSE C_CUSTFAC;
	
	if CUSTFAC.tariff is null then
		out_errmsg := 'No tariff found for custid/facility = : '|| ORD.custid||'/'||ORD.fromfacility;
			return zbill.BAD;
		end if;
		
	-- Create invoice header
	INVH := null;

	if in_invoice is null then
		rc := get_invoicehdr_freight_misc('FIND', CUST.custid, nvl(ORD.fromfacility,ORD.tofacility), 
				in_loadno, in_orderid, in_userid, now_date, INVH, out_errmsg);
		if rc != zbill.GOOD then
			return zbill.BAD;
		end if;
	end if;
	
	OPEN zbill.C_INVH(nvl(in_invoice,INVH.invoice));
	FETCH zbill.C_INVH into INVH;
	CLOSE zbill.C_INVH;

	if in_trace = 'Y' then
		zms.log_autonomous_msg(zfbill.author, null, null, 
			'Creating Freight Invoice for Loadno/Orderid/Invoice <'||
			in_loadno||'/'||in_orderid||'/'||INVH.invoice||'>',
			'T',in_userid, out_logmsg);
	end if;

	-- Group all the items in the order by class.
	-- Add an entry to the freight summary table for each class.
	
	delete from FREIGHT_SUMMARY_BY_CLASS 
	where 	loadno = in_loadno
	  and 	stopno = in_stopno;
	  
	delete from FREIGHT_BILL_RESULTS 
	where 	loadno = in_loadno
	  and 	stopno = in_stopno;

 if (ORD.ordertype = 'F') then
    open cr_classes for 
    select C.class,
           sum(A.qtyentered),    
           sum(nvl(a.weightship,0))/100 
     from  orderdtl A,
           (select distinct class, nmfc from nmfclasscodes) C 
    where  A.item = C.nmfc  
      and  orderid = in_orderid  
      and  shipid = in_shipid  
      and nvl(A.weightship,0) != 0 
    group by C.class;
 else
    open cr_classes for 
    select C.class, 
           sum(A.qtyentered),
           sum(nvl(A.weightship,0))/100 
     from  orderdtl A,
           (select distinct item, nmfc
             from  custitem 
            where custid = ORD.custid) B,  
           (select distinct class, nmfc from nmfclasscodes) C 
    where  A.item = B.item 
      and  B.nmfc = C.nmfc  
      and  orderid = in_orderid  
      and  shipid = in_shipid 
      and nvl(A.weightship,0) != 0  
    group by C.class;
 end if;

 l_class_count := 0;
 loop
   fetch cr_classes into
     l_freight_class, l_qtyentered, l_cwt_qty;
   exit when cr_classes%notfound;

   if l_freight_class is null then
      out_errmsg := 'Invalid class found for custid/orderid/shipid: '
                    ||ORD.custid||'/'||ORD.orderid||'/'||ORD.shipid;
      return zbill.BAD;
   end if;

   if nvl(l_cwt_qty,0) <= 0 then
     out_errmsg := 'Invalid CWT weight found for custid/orderid/shipid/class '
                   ||ORD.custid||'/'||ORD.orderid||'/'||ORD.shipid||'/'||l_freight_class;
     return zbill.BAD;
   end if;

   l_class_count := l_class_count + 1;
   insert into freight_summary_by_class
   (loadno,
    stopno,
    tariff,
    freight_class,
    cwt_qty,
    lastuser,
    lastupdate
   )
   values
   (in_loadno,
    in_stopno,
    CUSTFAC.tariff,
    l_freight_class,
    l_cwt_qty,
    'FREIGHTBILL',
    sysdate	
   );
	end loop;

  close cr_classes;
  if l_class_count = 0 then  
		out_errmsg := 'No NMFC Match found for orderid/shipid<'||ORD.orderid||'-'||ORD.shipid||'>';
		return zbill.BAD;
	end if;

	-- Get accessorials to be billed
	OPEN C_LOADSTOP(in_loadno, in_stopno);
	FETCH C_LOADSTOP INTO LOADSTOP;
	CLOSE C_LOADSTOP;

	-- Find the rate group associcated with this freight order.
	zfbill.rd_freight_rategroup(CUST.custid, zbill.BM_FREIGHT, zbill.EV_SHIP, now_date, out_rategroup, out_errmsg);
	if out_rategroup.rategroup is null then
		out_errmsg := 'No rategroup was found for custid/billmethod/event/date: '||
			CUST.custid||'/'||zbill.BM_FREIGHT||'/'||zbill.EV_SHIP||'/'||now_date||' : '||out_errmsg;
  zms.log_autonomous_msg(zfbill.author, null, null, out_errmsg,'T',in_userid, out_logmsg);
		return zbill.BAD;
		end if;
		
	-- Call freight calculator to compute the charges
	zfbill.freight_bill_calculator
	(	in_loadno,
		in_stopno,
		CUSTFAC.tariff,
		CUSTFAC.discount,
		CUSTFAC.surchargeid,
		in_surcharge_effdate,
		CUSTFAC.codid,
		ORD.freightvalue,
		LOADSTOP.freight_accesssorials,
		in_trace,
		in_userid,
		out_max_truckload_y_n,
		out_max_truckload_charges,
		out_errmsg);

	if out_errmsg != 'OKAY' then
			return zbill.BAD;
		end if;

	-- Create invoice details
	for crec in C_FREIGHT_BILL_RESULTS(LOADSTOP.loadno, LOADSTOP.stopno) 
	loop
		zfbill.rd_freight_minumum(CUSTFAC.tariff, crec.activitycode, out_tariffaccessorials, out_errmsg);
		
		insert into invoicedtl
		(	billstatus,
			facility,
			custid,
			orderid,
			item,
			lotnumber,
			activity,
			activitydate,
			handling,
			invoice,
			invdate,
			invtype,
			po,
			lpid,
			enteredqty,
			entereduom,
			enteredrate,
			enteredamt,
			calcedqty,
			calceduom,
			calcedrate,
			calcedamt,
			minimum,
			billedqty,
			billedrate,
			billedamt,
			expiregrace,
			statusrsn,
			exceptrsn,
			comment1,
			lastuser,
			lastupdate,
			statususer,
			statusupdate,
			loadno,
			stopno,
			shipno,
			billmethod,
			orderitem,
			orderlot,
			shipid,
			useinvoice,
			weight,
			moduom,
			enteredweight,
      businessevent
		)
		values
		(	zbill.NOT_REVIEWED,	--BILLSTATUS
			INVH.facility,		--FACILITY
			CUST.custid,		--CUSTID
			ORD.orderid,		--ORDERID
			null,				--ITEM
			null,				--LOTNUMBER
			crec.activitycode,	--ACTIVITY
			now_date,			--ACTIVITYDATE
			null,				--HANDLING
			INVH.invoice,		--INVOICE
			INVH.invdate,		--INVDATE
			INVH.invtype,		--INVTYPE
			null,				--PO
			null,				--LPID
			0,					--ENTEREDQTY
			null,				--ENTEREDUOM
			0,					--ENTEREDRATE
			null,				--ENTEREDAMT
			crec.cwt_qty,		--CALCEDQTY
			null,				--CALCEDUOM
			crec.rate,			--CALCEDRATE
			crec.net_charges,	--CALCEDAMT
			nvl(out_tariffaccessorials.min_cwt_charge,0), --MINIMUM
			crec.cwt_qty,		--BILLEDQTY
			crec.rate,			--BILLEDRATE
			crec.net_charges,	--BILLEDAMT
			null,				--EXPIREGRACE
			zbill.SR_MISC,		--STATUSRSN
			null,				--EXCEPTRSN
			null,				--COMMENT1
			in_userid,			--LASTUSER
			sysdate,			--LASTUPDATE
			in_userid,			--STATUSUSER
			sysdate,			--STATUSUPDATE
			LOADSTOP.loadno,	--LOADNO
			LOADSTOP.stopno,	--STOPNO
			null,				--SHIPNO
			zbill.BM_FREIGHT,	--BILLMETHOD
			null,				--ORDERITEM
			null,				--ORDERLOT
			ORD.shipid,			--SHIPID
			null,				--USEINVOICE
			crec.cwt_qty,		--WEIGHT
			null,				--MODUOM
			null,     			--ENTEREDWEIGHT,
      zbill.EV_FREIGHT
		);
	end loop;

   rc := 0;
   SELECT count(*)
     INTO rc
     FROM invoicedtl
    WHERE invoice = INVH.invoice;

   if nvl(rc,0) = 0 and in_invoice is null then
      DELETE invoicehdr
       WHERE invoice = INVH.invoice;
   end if;

	return zbill.GOOD;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'create_freight_invoice: '||substr(sqlerrm,1,80);
	return zbill.BAD;

END create_freight_invoice;

----------------------------------------------------------------------
--
-- get_invoicehdr_freight_misc
--
----------------------------------------------------------------------
FUNCTION get_invoicehdr_freight_misc
(
 in_lookup            IN  varchar2,   -- FIND to try to lookup
 in_custid            IN  varchar2,
 in_facility          IN  varchar2,
 in_loadno            IN  number,
 in_orderid           IN  number,
 in_userid            IN  varchar2,
 in_effdate           IN  date,
 INVH                OUT  invoicehdr%rowtype,
 out_errmsg          OUT  varchar2
)
RETURN integer
IS
	CURSOR C_INVH_FIND(in_custid varchar2, in_facility varchar2, in_loadno number, in_orderid number)
	RETURN invoicehdr%rowtype
	IS
	 SELECT *
	   FROM invoicehdr
	  WHERE custid = in_custid
		AND facility = in_facility
		AND loadno = in_loadno
		AND orderid = in_orderid
		AND invtype = zbill.IT_MISC
		AND invstatus = zbill.NOT_REVIEWED;

	log_msg 	varchar2(4000);
	
BEGIN
	out_errmsg := 'OKAY';
	INVH := null;

	if upper(in_lookup) = 'FIND' then
		OPEN C_INVH_FIND(in_custid, in_facility, in_loadno, in_orderid);
		FETCH C_INVH_FIND into INVH;
		CLOSE C_INVH_FIND;
		
		if INVH.invoice is not null then
			return zbill.GOOD;
		end if;
	end if;

	insert into invoicehdr
	(	invoice,
		invdate,
		invtype,
		invstatus,
		custid,
		facility,
		postdate,
		printdate,
		lastuser,
		lastupdate,
		orderid,
		masterinvoice,
		loadno,
		statususer,
		statusupdate,
		invoicedate,
		renewfromdate,
		renewtodate
	)
	values
	(	invoiceseq.nextval,
		in_effdate,
		zbill.IT_MISC,
		zbill.NOT_REVIEWED,
		in_custid,
		in_facility,
		null,
		null,
		in_userid,
		sysdate,
		in_orderid,
		null,
		in_loadno,
		in_userid,
		sysdate,
		in_effdate,
		null,
		null
	);
	
	OPEN C_INVH_FIND(in_custid, in_facility, in_loadno, in_orderid);
	FETCH C_INVH_FIND into INVH;
	CLOSE C_INVH_FIND;
	
   return zbill.GOOD;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'get_invoicehdr_freight_misc: '||substr(sqlerrm,1,80);
    return zbill.BAD;
END get_invoicehdr_freight_misc;

----------------------------------------------------------------------
--
-- get_charge_reversal_rate
--
----------------------------------------------------------------------
FUNCTION get_charge_reversal_rate
(
  in_shlpid           in shippingplate%rowtype,
  in_rategroup        in custrate.rategroup%type,
  in_activity         in custrate.activity%type,
  in_uom              in custrate.uom%type,
  out_errmsg		      out		varchar2
)
return custrate.rate%type
is
  v_receipt_date date;
  v_found boolean;
  v_rate_when custratewhen%rowtype;
  v_rate custrate%rowtype;
begin
  out_errmsg := 'OKAY';
  
  begin
    select coalesce(anvdate, creationdate, sysdate)
    into v_receipt_date
    from plate
    where lpid = in_shlpid.fromlpid;
      
    v_found := true;
  exception
    when others then
      v_found := false;
  end;
  
  -- if not found, check the deleted plates table
  if (not v_found)
  then
    begin
      select coalesce(anvdate, creationdate, sysdate)
      into v_receipt_date
      from deletedplate
      where lpid = in_shlpid.fromlpid;
    exception
      when others then
        v_receipt_date := sysdate;
    end;
  end if;
  
  begin
    SELECT *
      INTO v_rate_when
      FROM custratewhen W
     WHERE custid = zbut.rategroup(in_shlpid.custid, in_rategroup).custid
       AND rategroup = zbut.rategroup(in_shlpid.custid, in_rategroup).rategroup
       AND businessevent = zbill.EV_RECEIPT
       AND automatic in ('A','C')
       and activity = in_activity
       AND effdate  =
           (SELECT max(effdate)
              FROM custrate
             WHERE custid = W.custid
               AND activity = W.activity
               AND billmethod = W.billmethod
               AND rategroup = W.rategroup
               AND effdate <= trunc(v_receipt_date));
               
    v_found := true;
  exception
    when others then
      v_found := false;
  end;
  
  if (not v_found) then
    begin
      SELECT *
        INTO v_rate_when
        FROM custratewhen W
       WHERE custid = zbut.rategroup(in_shlpid.custid, in_rategroup).custid
         AND rategroup = zbut.rategroup(in_shlpid.custid, in_rategroup).rategroup
         AND businessevent = zbill.EV_RECEIPT
         AND automatic in ('A','C')
         and activity = in_activity
         AND effdate  =
             (SELECT max(effdate)
                FROM custrate
               WHERE custid = W.custid
                 AND activity = W.activity
                 AND billmethod = W.billmethod
                 AND rategroup = W.rategroup
                 AND effdate <= trunc(sysdate));
    exception
      when others then
        out_errmsg := 'get_charge_reversal_rate: could not find inbound rate';
        return 0;
    end;
  end if;
  
  select *
  into v_rate
  from custrate
  where custid = v_rate_when.custid
    and activity = v_rate_when.activity
    and billmethod = v_rate_when.billmethod
    and rategroup = v_rate_when.rategroup
    and effdate = v_rate_when.effdate;
    
  if (v_rate.uom <> in_uom) then
    out_errmsg := 'get_charge_reversal_rate: inbound rate has different uom';
    return 0;
  end if;
  
  return v_rate.rate;
  
exception
  when others then
    out_errmsg := 'get_charge_reversal_rate: '||substr(sqlerrm,1,80);
    return 0;
    
end get_charge_reversal_rate;

end zbillaccess;
/

show errors package body zbillaccess;
exit;
