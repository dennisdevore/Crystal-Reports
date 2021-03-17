create or replace package body alps.zbillsurcharge as
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
CURSOR C_LOAD(in_loadno number)
 RETURN loads%rowtype
IS
    SELECT *
      FROM loads
     WHERE loadno = in_loadno;
----------------------------------------------------------------------

CURSOR C_FAC(in_facility varchar2)
IS
    SELECT rategroup
      FROM facility
     WHERE facility = in_facility;

FAC C_FAC%rowtype;

  CURSOR C_ID_INVOICE_SELECTED(in_invoice number)
  IS
    SELECT nvl(A.surcharge, D.activity) activity,
            sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM activitysurcharge A, invoicedtl D
     WHERE invoice = in_invoice
       AND D.activity = A.activity(+)
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED)
     GROUP BY nvl(A.surcharge, D.activity);

-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************

----------------------------------------------------------------------
--
-- calc_minimums
--
----------------------------------------------------------------------
FUNCTION calc_minimums
(
    INVH        IN      invoicehdr%rowtype,
    in_event    IN      varchar2,
    in_orderid  IN      number,
    in_shipid   IN      number,
    in_userid   IN      varchar2,
    in_effdate  IN      date,
    out_errmsg  IN OUT  varchar2,
    in_keep_deleted IN    varchar2 default 'N')
RETURN integer
IS
  CUST  customer%rowtype;
  ITEM  custitem%rowtype;
  RATE  custrate%rowtype;
  LOAD  loads%rowtype;
  ORD   orderhdr%rowtype;

-- Minimums Cursors
  CURSOR C_ID_CHRG(in_invoice number, in_orderid number, in_shipid number)
  IS
    SELECT activity, item, lotnumber,
           nvl(billedamt,nvl(calcedamt,0)) total
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND orderid = nvl(in_orderid,orderid)
       AND shipid = nvl(in_shipid,shipid)
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED);

  CURSOR C_ID_LINE(in_invoice number, in_orderid number, in_shipid number)
  IS
    SELECT activity, item, lotnumber,
           sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND orderid = nvl(in_orderid,orderid)
       AND shipid = nvl(in_shipid,shipid)
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED)
     GROUP BY activity, item, lotnumber;

  CURSOR C_ID_ITEM(in_invoice number, in_orderid number, in_shipid number)
  IS
    SELECT activity, item, sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND orderid = nvl(in_orderid,orderid)
       AND shipid = nvl(in_shipid,shipid)
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED)
     GROUP BY activity, item;

  CURSOR C_ID_ORDER(in_invoice number, in_orderid number, in_shipid number)
  IS
    SELECT activity, sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND orderid = nvl(in_orderid,orderid)
       AND shipid = nvl(in_shipid,shipid)
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED)
     GROUP BY activity;

  CURSOR C_ID_INVOICE(in_invoice number)
  IS
    SELECT sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED);

  rc integer;
  now_date date;
  item_rategroup custitem.rategroup%type;

BEGIN

    now_date := in_effdate;


-- Get the order
    ORD := NULL;
    OPEN C_ORDHDR(in_orderid, in_shipid);
    FETCH C_ORDHDR into ORD;
    CLOSE C_ORDHDR;
    if ORD.orderid is null then
       ORD.orderid := 0;
       ORD.shipid := 0;
    end if;

-- Get the load
    LOAD := null;
    OPEN C_LOAD(ORD.loadno);
    FETCH C_LOAD into LOAD;
    CLOSE C_LOAD;


-- Get the customer information for this outbound order
    if zbill.rd_customer(INVH.custid, CUST) = zbill.BAD then
       out_errmsg := 'Invalid custid = '|| INVH.custid;
       -- zut.prt(out_errmsg);
       return zbill.BAD;
    end if;

-- Get rid of any old surcharges
    DELETE FROM invoicedtl
     WHERE invoice = INVH.invoice
       and orderid = nvl(in_orderid,orderid)
       and nvl(shipid,1) = nvl(in_shipid,nvl(shipid,1))
       AND billmethod in ('PCHG','LINE','ITEM','ORDR','INV','ACCT')
       and (billstatus != zbill.DELETED or in_keep_deleted = 'N');

-- Determine all the possible surcharges in order

-- Check for per charge minimums
    for crec in C_ID_CHRG(INVH.invoice, in_orderid, in_shipid) loop
    -- Check if line level minimum exists for this item
      if zbill.rd_item(CUST.custid, crec.item, ITEM) = zbill.BAD then
         null;
      end if;
      zbill.rd_item_rategroup(ITEM.custid, ITEM.item, item_rategroup);

      if zbill.check_for_minimum(CUST.custid, item_rategroup, CUST.rategroup,
                 in_event, INVH.facility, zbill.BM_MIN_CHARGE, crec.activity,
                 now_date, RATE) = zbill.GOOD then

           if crec.total < RATE.rate then
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, ORD,
                 crec.item, crec.lotnumber, crec.total, in_userid,sysdate, null, in_event, in_keep_deleted);
           end if;
      end if;
    end loop;

-- Check for line minimums
    for crec in C_ID_LINE(INVH.invoice, in_orderid, in_shipid) loop
    -- Check if line level minimum exists for this item
      if zbill.rd_item(CUST.custid, crec.item, ITEM) = zbill.BAD then
         null;
      end if;
      zbill.rd_item_rategroup(ITEM.custid, ITEM.item, item_rategroup);

      if zbill.check_for_minimum(CUST.custid, item_rategroup, CUST.rategroup,
                 in_event, INVH.facility, zbill.BM_MIN_LINE, crec.activity,
                 now_date, RATE) = zbill.GOOD then

           if crec.total < RATE.rate then
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, ORD,
                 crec.item, crec.lotnumber, crec.total, in_userid,sysdate, null, in_event, in_keep_deleted);
           end if;
      end if;
    end loop;

-- Check for item minimums
    for crec in C_ID_ITEM(INVH.invoice, in_orderid, in_shipid) loop
    -- Check if line level minimum exists for this item
      if zbill.rd_item(CUST.custid, crec.item, ITEM) = zbill.BAD then
         null;
      end if;
      zbill.rd_item_rategroup(ITEM.custid, ITEM.item, item_rategroup);

      if zbill.check_for_minimum(CUST.custid, item_rategroup, CUST.rategroup,
                 in_event, INVH.facility, zbill.BM_MIN_ITEM, crec.activity,
                 now_date, RATE) = zbill.GOOD then
           if crec.total < RATE.rate then
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, ORD,
                 crec.item, NULL, crec.total, in_userid,sysdate, null, in_event, in_keep_deleted);
           end if;
      end if;
   end loop;

-- Check for order minimum (must be defined at the cust rate group level)
    for crec in C_ID_ORDER(INVH.invoice, in_orderid, in_shipid) loop
    -- Check if order level minimums exist
      if zbill.check_for_minimum(CUST.custid, NULL, CUST.rategroup,
                 in_event, INVH.facility, zbill.BM_MIN_ORDER, crec.activity,
                 now_date, RATE) = zbill.GOOD then
           if crec.total < RATE.rate then
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, ORD,
                 NULL, NULL, crec.total, in_userid,sysdate, null, in_event, in_keep_deleted);
           end if;
      end if;
    end loop;

-- Check for invoice minimum (must be defined at the cust rate group level)
    for crec in C_ID_INVOICE(INVH.invoice) loop
    -- Check if invoice level minimums exist
      if zbill.check_for_minimum(CUST.custid, NULL, CUST.rategroup,
                 in_event, INVH.facility, zbill.BM_MIN_INVOICE, NULL,
                 now_date, RATE) = zbill.GOOD then
           if crec.total < RATE.rate then
             rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, ORD,
                 NULL, NULL, crec.total, in_userid,sysdate, null, in_event, in_keep_deleted);
           end if;
      end if;
    end loop;


    return zbill.GOOD;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CAccMins: '||substr(sqlerrm,1,80);
    return zbill.BAD;
END calc_minimums;

----------------------------------------------------------------------
--
-- calc_surcharges
--
----------------------------------------------------------------------
FUNCTION calc_surcharges
(
    INVH        IN      invoicehdr%rowtype,
    in_event    IN      varchar2,
    in_orderid  IN      number,
    in_shipid   IN      number,
    in_userid   IN      varchar2,
    in_effdate  IN      date,
    out_errmsg  IN OUT  varchar2
)
RETURN integer
IS
  CUST  customer%rowtype;
  ITEM  custitem%rowtype;
  RATE  custrate%rowtype;
  LOAD  loads%rowtype;
  ORD   orderhdr%rowtype;

-- Surcharges Cursors
  CURSOR C_ID_LINE(in_invoice number, in_orderid number, in_shipid number)
  IS
    SELECT activity, item, lotnumber,
           sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND orderid = nvl(in_orderid,orderid)
       AND shipid = nvl(in_shipid,shipid)
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED)
     GROUP BY activity, item, lotnumber;

  CURSOR C_ID_ITEM(in_invoice number, in_orderid number, in_shipid number)
  IS
    SELECT activity, item, sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND orderid = nvl(in_orderid,orderid)
       AND shipid = nvl(in_shipid,shipid)
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED)
     GROUP BY activity, item;

  CURSOR C_ID_ORDER(in_invoice number, in_orderid number, in_shipid number)
  IS
    SELECT activity, sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND orderid = nvl(in_orderid,orderid)
       AND shipid = nvl(in_shipid,shipid)
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED)
     GROUP BY activity;

  CURSOR C_ID_INVOICE(in_invoice number)
  IS
    SELECT sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED);


  rc integer;
  now_date date;
  item_rategroup custitem.rategroup%type;

  mf_shipid integer;
  l_shipid integer;

  v_has_surcharges number;

BEGIN

    now_date := in_effdate;

    mf_shipid := zba.check_multi_facility(in_orderid, in_shipid);
    if mf_shipid = 0 then
        l_shipid := in_shipid;
    else
        l_shipid := null;
    end if;


-- Get the order
    ORD := NULL;
    OPEN C_ORDHDR(in_orderid, nvl(in_shipid,1));
    FETCH C_ORDHDR into ORD;
    CLOSE C_ORDHDR;
    if ORD.orderid is null then
       ORD.orderid := 0;
    end if;

-- Get the load
    LOAD := null;
    OPEN C_LOAD(ORD.loadno);
    FETCH C_LOAD into LOAD;
    CLOSE C_LOAD;


-- Get the customer information for this outbound order
    if zbill.rd_customer(INVH.custid, CUST) = zbill.BAD then
       out_errmsg := 'Invalid custid = '|| INVH.custid;
       -- zut.prt(out_errmsg);
       return zbill.BAD;
    end if;

-- Get rid of any old surcharges
    DELETE FROM invoicedtl
     WHERE invoice = INVH.invoice
       and orderid = nvl(in_orderid,orderid)
       and nvl(shipid,1) = nvl(l_shipid,nvl(shipid,1))
       AND billmethod in ('SCLN','SCIT','SCOR','SCIN');

-- Determine all the possible surcharges in order

-- Check for line surcharges
    select count(1)
    into v_has_surcharges
    from custratewhen
    where businessevent = in_event and billmethod = zbill.BM_SC_LINE
      and (custid, rategroup) in (
        select distinct
          case when nvl(linkyn,'N') = 'Y' then 'DEFAULT' else custid end as custid,
          case when nvl(linkyn,'N') = 'Y' then linkrategroup else rategroup end as rategroup
        from custrategroup
        where custid = CUST.custid and status = 'ACTV');
     
    if (v_has_surcharges > 0) then
    for crec in C_ID_LINE(INVH.invoice, in_orderid, l_shipid) loop
    -- Check if line level minimum exists for this item
      if zbill.rd_item(CUST.custid, crec.item, ITEM) = zbill.BAD then
         null;
      end if;
      zbill.rd_item_rategroup(ITEM.custid, ITEM.item, item_rategroup);

      if zbill.check_for_minimum(CUST.custid, item_rategroup, CUST.rategroup,
                 in_event, INVH.facility, zbill.BM_SC_LINE, crec.activity,
                 now_date, RATE) = zbill.GOOD then
              rc := add_sc_invoicedtl(CUST, RATE, INVH, ORD,
                 crec.item, crec.lotnumber, crec.total, in_userid,sysdate, null, in_event);
      end if;
    end loop;
    end if;

-- Check for item surcharges
    select count(1)
    into v_has_surcharges
    from custratewhen
    where businessevent = in_event and billmethod = zbill.BM_SC_ITEM
      and (custid, rategroup) in (
        select distinct
          case when nvl(linkyn,'N') = 'Y' then 'DEFAULT' else custid end as custid,
          case when nvl(linkyn,'N') = 'Y' then linkrategroup else rategroup end as rategroup
        from custrategroup
        where custid = CUST.custid and status = 'ACTV');
      
    if (v_has_surcharges > 0) then
    for crec in C_ID_ITEM(INVH.invoice, in_orderid, l_shipid) loop
    -- Check if line level minimum exists for this item
      if zbill.rd_item(CUST.custid, crec.item, ITEM) = zbill.BAD then
         null;
      end if;
      zbill.rd_item_rategroup(ITEM.custid, ITEM.item, item_rategroup);

      if zbill.check_for_minimum(CUST.custid, item_rategroup, CUST.rategroup,
                 in_event, INVH.facility, zbill.BM_SC_ITEM, crec.activity,
                 now_date, RATE) = zbill.GOOD then
              rc := add_sc_invoicedtl(CUST, RATE, INVH, ORD,
                 crec.item, NULL, crec.total, in_userid,sysdate, null, in_event);
      end if;
   end loop;
    end if;

-- Check for order minimum (must be defined at the cust rate group level)
    select count(1)
    into v_has_surcharges
    from custratewhen
    where businessevent = in_event and billmethod = zbill.BM_SC_ORDER
      and (custid, rategroup) in (
        select distinct
          case when nvl(linkyn,'N') = 'Y' then 'DEFAULT' else custid end as custid,
          case when nvl(linkyn,'N') = 'Y' then linkrategroup else rategroup end as rategroup
        from custrategroup
        where custid = CUST.custid and status = 'ACTV');
    
    if (v_has_surcharges > 0) then
    for crec in C_ID_ORDER(INVH.invoice, in_orderid, l_shipid) loop
    -- Check if order level surcharges exist
      if zbill.check_for_minimum(CUST.custid, NULL, CUST.rategroup,
                 in_event, INVH.facility, zbill.BM_SC_ORDER, crec.activity,
                 now_date, RATE) = zbill.GOOD then
              rc := add_sc_invoicedtl(CUST, RATE, INVH, ORD,
                 NULL, NULL, crec.total, in_userid,sysdate, null, in_event);
      end if;
    end loop;
    end if;

-- Check for invoice minimum (must be defined at the cust rate group level)
    for crec in C_ID_INVOICE(INVH.invoice) loop
    -- Check if invoice level surcharges exist
       FOR EVNT IN zbill.C_RATE_WHEN_ACTV(CUST.custid, CUST.rategroup, 
                   in_event, NULL, INVH.facility, now_date) loop

           for rt in zbill.C_RATE(rategrouptype(EVNT.custid, EVNT.rategroup), 
             EVNT.activity,
             zbill.BM_SC_INVOICE, now_date) loop
              if rt.billmethod = zbill.BM_SC_INVOICE then
                 RATE := rt;
                 rc := add_sc_invoicedtl(CUST, RATE, INVH, ORD,
                    NULL, NULL, crec.total, in_userid,sysdate, null, in_event);
              end if;
           end loop;
       end loop;


    end loop;


-- Get facility rategroup
    FAC := null;
    OPEN C_FAC(INVH.facility);
    FETCH C_FAC into FAC;
    CLOSE C_FAC;

    if FAC.rategroup is not null then

      for crec in C_ID_INVOICE_SELECTED(INVH.invoice) loop
    -- Check if invoice level surcharges exist
       FOR EVNT IN zbill.C_RATE_WHEN_ACTV('DEFAULT', FAC.rategroup, 
                   in_event, crec.activity, INVH.facility, now_date) loop

           for rt in zbill.C_RATE(rategrouptype(EVNT.custid, EVNT.rategroup), 
             EVNT.activity,
             zbill.BM_SC_INVOICE, now_date) loop
              if rt.billmethod = zbill.BM_SC_INVOICE then
                 RATE := rt;
                 rc := add_sc_invoicedtl(CUST, RATE, INVH, ORD,
                    NULL, NULL, crec.total, in_userid,sysdate, null, in_event);
              end if;
           end loop;
       end loop;


      end loop;
    end if;

    return zbill.GOOD;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CSC: '||substr(sqlerrm,1,80);
    return zbill.BAD;
END calc_surcharges;

----------------------------------------------------------------------
--
-- calc_access_inv_surcharges
--
----------------------------------------------------------------------
FUNCTION calc_access_inv_surcharges
(
    INVH        IN      invoicehdr%rowtype,
    in_event    IN      varchar2,
    in_userid   IN      varchar2,
    in_effdate  IN      date,
    out_errmsg  IN OUT  varchar2
)
RETURN integer
IS
  CUST  customer%rowtype;
  ITEM  custitem%rowtype;
  RATE  custrate%rowtype;
  LOAD  loads%rowtype;
  ORD   orderhdr%rowtype;

-- Surcharge Cursors
  CURSOR C_ID_INVOICE(in_invoice number)
  IS
    SELECT sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED);

  rc integer;
  now_date date;
BEGIN

    now_date := in_effdate;

-- Get the order
    ORD.orderid := 0;

-- Get the customer information for this outbound order
    if zbill.rd_customer(INVH.custid, CUST) = zbill.BAD then
       out_errmsg := 'Invalid custid = '|| INVH.custid;
       -- zut.prt(out_errmsg);
       return zbill.BAD;
    end if;

-- Get rid of any old surcharges
    DELETE FROM invoicedtl
     WHERE invoice = INVH.invoice
       AND billmethod = 'SCIN';

-- Determine all the possible surcharges in order

-- Check for invoice minimum (must be defined at the cust rate group level)
    for crec in C_ID_INVOICE(INVH.invoice) loop
       FOR EVNT IN zbill.C_RATE_WHEN_ACTV(CUST.custid, CUST.rategroup, 
                   in_event, NULL, INVH.facility, now_date) loop

           for rt in zbill.C_RATE(rategrouptype(EVNT.custid, EVNT.rategroup),
             EVNT.activity,
             zbill.BM_SC_INVOICE, now_date) loop
              if rt.billmethod = zbill.BM_SC_INVOICE then
                 RATE := rt;
                 rc := add_sc_invoicedtl(CUST, RATE, INVH, ORD,
                    NULL, NULL, crec.total, in_userid,sysdate, null, in_event);

              end if;
           end loop;
       end loop;


    end loop;

-- Get facility rategroup
    FAC := null;
    OPEN C_FAC(INVH.facility);
    FETCH C_FAC into FAC;
    CLOSE C_FAC;

    if FAC.rategroup is not null then

      for crec in C_ID_INVOICE_SELECTED(INVH.invoice) loop
    -- Check if invoice level surcharges exist
       FOR EVNT IN zbill.C_RATE_WHEN_ACTV('DEFAULT', FAC.rategroup, 
                   in_event, crec.activity, INVH.facility, now_date) loop

           for rt in zbill.C_RATE(rategrouptype(EVNT.custid, EVNT.rategroup), 
             EVNT.activity, zbill.BM_SC_INVOICE, now_date) loop
              if rt.billmethod = zbill.BM_SC_INVOICE then
                 RATE := rt;
                 rc := add_sc_invoicedtl(CUST, RATE, INVH, ORD,
                    NULL, NULL, crec.total, in_userid,sysdate, null, in_event);
              end if;
           end loop;
       end loop;


      end loop;
    end if;

    return zbill.GOOD;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CAccSC: '||substr(sqlerrm,1,80);
    return zbill.BAD;
END calc_access_inv_surcharges;

----------------------------------------------------------------------
--
-- add_sc_invoicedtl
--
----------------------------------------------------------------------
FUNCTION add_sc_invoicedtl
(
    CUST         IN      customer%rowtype,
    RATE         IN      custrate%rowtype,
    INVH         IN      invoicehdr%rowtype,
    ORD          IN      orderhdr%rowtype,
    in_item      IN      varchar2,
    in_lotnumber IN      varchar2,
    in_total     IN      number,
    in_userid    IN      varchar2,
    in_date      IN      date,
    in_comment   IN      varchar2,
    in_event     IN      varchar2
)
RETURN integer
IS
surch number(12,2);

BEGIN

  surch := in_total * RATE.rate / 100.0;

  if surch > 0 then
  
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
        calcedqty,
        calceduom,
        calcedrate,
        calcedamt,
        billmethod,
        minimum,
        loadno,
        invoice,
        invtype,
        invdate,
        shipid,
        comment1,
        lastuser,
        lastupdate,
        businessevent
    )
    values
    (
        zbill.NOT_REVIEWED,
        INVH.facility,
        CUST.custid,
        ORD.orderid,
        in_item,
        in_lotnumber,
        RATE.activity,
        in_date,
        1,
        RATE.uom,
        surch,
        surch,
        RATE.billmethod,
        RATE.rate,
        ORD.loadno,
        INVH.invoice,
        INVH.invtype,
        INVH.invdate,
        ORD.shipid,
        in_comment,
        in_userid,
        sysdate,
        in_event
   );

 end if;

   return zbill.GOOD;

EXCEPTION WHEN OTHERS THEN
   return zbill.bad;
END add_sc_invoicedtl;


----------------------------------------------------------------------
--
-- check_activity_facility
--
----------------------------------------------------------------------
FUNCTION check_activity_facility
(
    in_custid   IN  varchar2,
    in_activity IN  varchar2,
    in_facility IN  varchar2
)
RETURN integer
IS
  CURSOR C_CAF(in_custid char, in_activity char)
  RETURN custactvfacilities%rowtype
  IS
    SELECT *
      FROM custactvfacilities
     WHERE custid = in_custid
       AND activity = in_activity;

 CAF custactvfacilities%rowtype;


BEGIN

  CAF := null;
  OPEN C_CAF(in_custid, in_activity);
  FETCH C_CAF into CAF;
  CLOSE C_CAF;

  if CAF.activity is null then
     return 1;
  end if;

  if instr(CAF.facilities, in_facility) > 0 then
     return 1;
  end if;
  return 0;

END check_activity_facility;


end zbillsurcharge;
/
show error package body zbillsurcharge;
exit;
