create or replace package body alps.zbillstorage as
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

debug_flag  boolean := False;
--GOOD            CONSTANT        integer := 1;
--BAD             CONSTANT        integer := 0;


-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************
--
-- Cursors are defined in zbillspec.sql
--

CURSOR C_ANV_CHARGE(in_custid varchar2)
IS
    SELECT rowid, activitydate
      FROM invoicedtl
     WHERE custid = in_custid
       AND statusrsn in (zbill.SR_ANVR, zbill.SR_ANVD)
       AND billstatus = zbill.UNCHARGED
       AND calcedamt is null;


-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************


PROCEDURE DbMsg(in_txt varchar2)
IS
BEGIN
    if debug_flag then
        zut.prt(in_txt);
    end if;
END DbMsg;


----------------------------------------------------------------------
--
-- get_renewal_order - there should be an existing renewal order
--                     for attaching renewal charges to. If one exists
--                     return it, otherwise create a new one for the
--                     customer.
--
----------------------------------------------------------------------
FUNCTION get_renewal_order
(
    CUST        IN      customer%rowtype,
    in_facility IN      varchar2,
    ORD         IN OUT  orderhdr%rowtype,
    in_userid   IN      varchar2
)
RETURN integer
IS
  CURSOR C_ORD(in_custid varchar2)
  IS
    SELECT *
      FROM ORDERHDR
     WHERE custid = in_custid
       AND ordertype = 'S'   -- Renewal Storage
       AND orderstatus = 'A'    -- ??? Use Arrived for now
       AND tofacility = in_facility;

 ordid  orderhdr.orderid%type;
 errmsg varchar2(200);

BEGIN
    ORD := NULL;
    OPEN C_ORD(CUST.custid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if ORD.custid is not null then
       return GOOD;
    end if;

    zoe.get_next_orderid(ordid, errmsg);
    if substr(errmsg,1,4) != 'OKAY' then
       return BAD;
    end if;

    INSERT INTO
       ORDERHDR
       (
        orderid,
        tofacility,
        shipid,
        custid,
        ordertype,
        orderstatus,
        lastupdate,
        lastuser
       )
       values
       (
        ordid,
        in_facility,
        1,
        CUST.custid,
        'S',
        'A',
        sysdate,
        in_userid
       );


    ORD := NULL;
    OPEN C_ORD(CUST.custid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if ORD.custid is not null then
       return GOOD;
    end if;

    return BAD;
END get_renewal_order;


----------------------------------------------------------------------
--
-- calc_account_minimums -
--
----------------------------------------------------------------------
FUNCTION calc_account_minimums
(
    ORD         IN      orderhdr%rowtype,
    CUST        IN OUT  customer%rowtype,
    INVH        IN      invoicehdr%rowtype,
    in_effdate  IN      date,           -- Date we are calculating renewals for
    out_errmsg  IN OUT  varchar2
)
RETURN integer
IS
  ITEM  custitem%rowtype;
  RATE  custrate%rowtype;

-- Minimums Cursors
  CURSOR C_ID_ACTV(in_custid varchar2, in_type varchar2, in_start date,
        in_end date)
  IS
    SELECT sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM activity ACT, invoicedtl ID, invoicehdr IH
     WHERE IH.custid = in_custid
       AND IH.invstatus = zbill.BILLED
       AND IH.invoicedate > in_start
       AND IH.invoicedate <= in_end
       AND ID.billstatus = zbill.BILLED
       AND ID.invoice = IH.invoice
       AND ID.billmethod != zbill.BM_MIN_ACCOUNT
       AND ACT.code = ID.activity
       AND ACT.mincategory = in_type;

  CURSOR C_ACTV(in_custid varchar2, in_rategroup varchar2, in_type varchar2,
    in_effdate date)
  IS
    SELECT CR.activity
      FROM custrate CR
     WHERE CR.custid = in_custid
       AND CR.rategroup = in_rategroup
       AND CR.billmethod = zbill.BM_MIN_ACCOUNT
       AND CR.activity in
           (SELECT code
              FROM activity
             WHERE mincategory = in_type)
       AND CR.effdate  =
           (SELECT max(effdate)
              FROM custrate
             WHERE custid = in_custid
               AND rategroup = in_rategroup
               AND activity = CR.activity
               AND billmethod = CR.billmethod
               AND effdate <= trunc(in_effdate));

  t_actv  custrate.activity%type;
  new_total number;
  rc        integer;

  cmt   varchar2(100);

  RG rategrouptype;

BEGIN

     -- DbMsg('Account min for '|| CUST.custid
     --        || ' Date:'|| to_char(in_effdate,'YYYYMMDD'));
     -- DbMsg('  range '||to_char(CUST.prevaccountmin,'YYYYMMDD') ||
     --        ' to '||to_char(CUST.lastaccountmin,'YYYYMMDD'));
-- If we-ve already done this just return
    if in_effdate = CUST.lastaccountmin then
        return zbill.GOOD;
    end if;

-- Check for existing
    rc := 0;
    select count(1)
      into rc
      from invoicedtl
     where custid = CUST.custid
       and facility != INVH.facility
       and billmethod = zbill.BM_MIN_ACCOUNT
       and activitydate = CUST.lastaccountmin;

    if rc > 0 then
        return zbill.GOOD;
    end if;

    RG := zbut.rategroup(CUST.custid, CUST.rategroup);

-- Check for handling minimum
    t_actv := null;
    OPEN C_ACTV(RG.custid, RG.rategroup, 'H', CUST.lastaccountmin);
    FETCH C_ACTV into t_actv;
    CLOSE C_ACTV;

    -- DbMsg(' Activity for account min handling = '||t_actv);

    if t_actv is not null and
      zbill.check_for_minimum(CUST.custid, CUST.rategroup,NULL,
            zbill.EV_BILLING, INVH.facility, zbill.BM_MIN_ACCOUNT,
            t_actv, in_effdate, RATE) = GOOD then

    -- DbMsg(' Check for min rate = '||to_char(RATE.rate));

        OPEN C_ID_ACTV(CUST.custid, 'H',
                        CUST.prevaccountmin, CUST.lastaccountmin);
        FETCH C_ID_ACTV into new_total;
        CLOSE C_ID_ACTV;

        -- DbMsg(' total is = '||to_char(new_total));

        if nvl(new_total,0) < RATE.rate then
              cmt := 'Account minimum adjust for period from '
               || to_char(CUST.prevaccountmin + 1,'MM/DD/YYYY')
               || ' through '
               || to_char(CUST.lastaccountmin,'MM/DD/YYYY');
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, ORD,
                 NULL, NULL, nvl(new_total,0),
            'BILLER', CUST.lastaccountmin, cmt, zbill.EV_BILLING);
        end if;
    end if;


-- Check for storage minimum
    t_actv := null;
    OPEN C_ACTV(RG.custid, RG.rategroup, 'S', CUST.lastaccountmin);
    FETCH C_ACTV into t_actv;
    CLOSE C_ACTV;

    -- DbMsg(' Activity for account storage handling = '||t_actv);

    if t_actv is not null and
     zbill.check_for_minimum(CUST.custid, CUST.rategroup,NULL,
            zbill.EV_BILLING, INVH.facility, zbill.BM_MIN_ACCOUNT,
            t_actv, in_effdate, RATE) = GOOD then

        -- DbMsg(' Check for min rate = '||to_char(RATE.rate));

        OPEN C_ID_ACTV(CUST.custid, 'S',
                        CUST.prevaccountmin, CUST.lastaccountmin);
        FETCH C_ID_ACTV into new_total;
        CLOSE C_ID_ACTV;

        -- DbMsg(' total is = '||to_char(new_total));

        if nvl(new_total,0) < RATE.rate then
              cmt := 'Account minimum adjust for period from '
               || to_char(CUST.prevaccountmin + 1,'MM/DD/YYYY')
               || ' through '
               || to_char(CUST.lastaccountmin,'MM/DD/YYYY');
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, ORD,
                 NULL, NULL, nvl(new_total,0),
                'BILLER',CUST.lastaccountmin, cmt, zbill.EV_BILLING);
        end if;
    end if;

  -- Fix the customer record locally so we don't do this again
  --    by mistake
    CUST.prevaccountmin := CUST.lastaccountmin;
    CUST.lastaccountmin := in_effdate;

    return GOOD;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CAccMins: '||substr(sqlerrm,1,80);
    return zbill.BAD;
END calc_account_minimums;


----------------------------------------------------------------------
--
-- calc_renewal_minimums -
--
----------------------------------------------------------------------
FUNCTION calc_renewal_minimums
(
    INVH        IN      invoicehdr%rowtype,
    in_orderid  IN      number,
    in_custid   IN      varchar2,
    in_userid   IN      varchar2,
    in_effdate  IN      date,
    out_errmsg  IN OUT  varchar2,
    in_keep_deleted IN    varchar2 default 'N'
)
RETURN integer
IS
  CUST  customer%rowtype;
  ITEM  custitem%rowtype;
  RATE  custrate%rowtype;
  ORD   orderhdr%rowtype;

-- Minimums Cursors
  CURSOR C_ID_CHRG(in_orderid number, in_invoice number)
  IS
    SELECT activity, activitydate, item, lotnumber,
           nvl(billedamt,nvl(calcedamt,0)) total
      FROM invoicedtl
     WHERE orderid = in_orderid
       AND invoice = in_invoice
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED);

  CURSOR C_ID_LINE(in_orderid number, in_invoice number)
  IS
    SELECT activity, item, lotnumber,
           sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM invoicedtl
     WHERE orderid = in_orderid
       AND invoice = in_invoice
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED)
     GROUP BY activity, item, lotnumber;

  CURSOR C_ID_ITEM(in_orderid number, in_invoice number)
  IS
    SELECT activity, item, sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM invoicedtl
     WHERE orderid = in_orderid
       AND invoice = in_invoice
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED)
     GROUP BY activity, item;

  CURSOR C_ID_ORDER(in_orderid number, in_invoice number)
  IS
    SELECT activity, sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM invoicedtl
     WHERE orderid = in_orderid
       AND invoice = in_invoice
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED)
     GROUP BY activity;

  CURSOR C_ID_INVOICE(in_orderid number, in_invoice number)
  IS
    SELECT sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM invoicedtl
     WHERE orderid = in_orderid
       AND invoice = in_invoice
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED);

  rc integer;

  now_date date;

  item_rategroup custitem.rategroup%type;

  v_has_minimums number;

BEGIN

   now_date := in_effdate;

-- Order
   ORD := NULL;
   OPEN zbill.C_ORDHDR(in_orderid);
   FETCH zbill.C_ORDHDR into ORD;
   CLOSE zbill.C_ORDHDR;


-- Get the customer information for this receipt order
    if zbill.rd_customer(in_custid, CUST) = BAD then
       out_errmsg := 'Invalid custid = '|| in_custid;
       -- DbMsg(out_errmsg);
       return BAD;
    end if;

-- Get rid of any old minimums
    DELETE FROM invoicedtl
     WHERE orderid = in_orderid
       AND invoice = INVH.invoice
       AND minimum is not null
       and (billstatus != zbill.DELETED or in_keep_deleted = 'N');

    -- check to see if this customer has any EV_RENEWAL events using BM_MIN_CHARGE
    select count(1)
    into v_has_minimums
    from custratewhen
    where businessevent = zbill.EV_RENEWAL and billmethod = zbill.BM_MIN_CHARGE
      and (custid, rategroup) in (
        select distinct
          case when nvl(linkyn,'N') = 'Y' then 'DEFAULT' else custid end as custid,
          case when nvl(linkyn,'N') = 'Y' then linkrategroup else rategroup end as rategroup
        from custrategroup
        where custid = in_custid and status = 'ACTV');

-- Check for Per Charge minimums
    if (v_has_minimums > 0) then
    for crec in C_ID_CHRG(in_orderid, INVH.invoice) loop
    -- Check if line level minimum exists for this item
      if zbill.rd_item(CUST.custid, crec.item, ITEM) = zbill.BAD then
         null;
      end if;
      zbill.rd_item_rategroup(ITEM.custid, ITEM.item, item_rategroup);
      if zbill.check_for_minimum(CUST.custid, item_rategroup, CUST.rategroup,
                 zbill.EV_RENEWAL, INVH.facility, zbill.BM_MIN_CHARGE,
                 crec.activity,
                 crec.activitydate, RATE) = GOOD then
           if crec.total < RATE.rate then
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, ORD,
                 crec.item, crec.lotnumber, crec.total, in_userid,
                 crec.activitydate, null, zbill.EV_RENEWAL, in_keep_deleted);
           end if;
      end if;
    end loop;
    end if;

    -- check to see if this customer has any EV_RENEWAL events using BM_MIN_LINE
    select count(1)
    into v_has_minimums
    from custratewhen
    where businessevent = zbill.EV_RENEWAL and billmethod = zbill.BM_MIN_LINE
      and (custid, rategroup) in (
        select distinct
          case when nvl(linkyn,'N') = 'Y' then 'DEFAULT' else custid end as custid,
          case when nvl(linkyn,'N') = 'Y' then linkrategroup else rategroup end as rategroup
        from custrategroup
        where custid = in_custid and status = 'ACTV');

-- Check for line minimums
    if (v_has_minimums > 0) then
    for crec in C_ID_LINE(in_orderid, INVH.invoice) loop
    -- Check if line level minimum exists for this item
      if zbill.rd_item(CUST.custid, crec.item, ITEM) = zbill.BAD then
         null;
      end if;
      zbill.rd_item_rategroup(ITEM.custid, ITEM.item, item_rategroup);
      if zbill.check_for_minimum(CUST.custid, item_rategroup, CUST.rategroup,
                 zbill.EV_RENEWAL, INVH.facility, zbill.BM_MIN_LINE,
                 crec.activity,
                 now_date, RATE) = GOOD then
           if crec.total < RATE.rate then
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, ORD,
                 crec.item, crec.lotnumber, crec.total, in_userid,sysdate, null, zbill.EV_RENEWAL, in_keep_deleted);
          end if;
      end if;
    end loop;
    end if;
    
    -- check to see if this customer has any EV_RENEWAL events using BM_MIN_ITEM
    select count(1)
    into v_has_minimums
    from custratewhen
    where businessevent = zbill.EV_RENEWAL and billmethod = zbill.BM_MIN_ITEM
      and (custid, rategroup) in (
        select distinct
          case when nvl(linkyn,'N') = 'Y' then 'DEFAULT' else custid end as custid,
          case when nvl(linkyn,'N') = 'Y' then linkrategroup else rategroup end as rategroup
        from custrategroup
        where custid = in_custid and status = 'ACTV');

-- Check for item minimums
    if (v_has_minimums > 0) then
    for crec in C_ID_ITEM(in_orderid, INVH.invoice) loop
    -- Check if line level minimum exists for this item
      if zbill.rd_item(CUST.custid, crec.item, ITEM) = zbill.BAD then
         null;
      end if;
      zbill.rd_item_rategroup(ITEM.custid, ITEM.item, item_rategroup);
      if zbill.check_for_minimum(CUST.custid, item_rategroup, CUST.rategroup,
                 zbill.EV_RENEWAL, INVH.facility, zbill.BM_MIN_ITEM,
                 crec.activity,
                 now_date, RATE) = GOOD then
           if crec.total < RATE.rate then
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, ORD,
                 crec.item, NULL, crec.total, in_userid,sysdate, null, zbill.EV_RENEWAL, in_keep_deleted);
           end if;
      end if;
   end loop;
    end if;
    
    -- check to see if this customer has any EV_RENEWAL events using BM_MIN_ORDER
    select count(1)
    into v_has_minimums
    from custratewhen
    where businessevent = zbill.EV_RENEWAL and billmethod = zbill.BM_MIN_ORDER
      and (custid, rategroup) in (
        select distinct
          case when nvl(linkyn,'N') = 'Y' then 'DEFAULT' else custid end as custid,
          case when nvl(linkyn,'N') = 'Y' then linkrategroup else rategroup end as rategroup
        from custrategroup
        where custid = in_custid and status = 'ACTV');

-- Check for order minimum (must be defined at the cust rate group level)
    if (v_has_minimums > 0) then
    for crec in C_ID_ORDER(in_orderid, INVH.invoice) loop
    -- Check if order level minimums exist
      if zbill.check_for_minimum(CUST.custid, NULL, CUST.rategroup,
                 zbill.EV_RENEWAL, INVH.facility, zbill.BM_MIN_ORDER,
                 crec.activity,
                 now_date, RATE) = GOOD then
           if crec.total < RATE.rate then
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, ORD,
                 NULL, NULL, crec.total, in_userid, sysdate, null, zbill.EV_RENEWAL);
           end if;
      end if;
    end loop;
    end if;

-- Check for order minimum (must be defined at the cust rate group level)
    for crec in C_ID_INVOICE(in_orderid, INVH.invoice) loop
    -- Check if order level minimums exist
      if zbill.check_for_minimum(CUST.custid, NULL, CUST.rategroup,
                 zbill.EV_RENEWAL, INVH.facility, zbill.BM_MIN_INVOICE, NULL,
                 now_date, RATE) = GOOD then
           if crec.total < RATE.rate then
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, ORD,
                 NULL, NULL, crec.total, in_userid, sysdate, null, zbill.EV_RENEWAL, in_keep_deleted);
           end if;
      end if;
    end loop;


    return GOOD;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CRenMins: '||substr(sqlerrm,1,80);
    return zbill.BAD;
END calc_renewal_minimums;


----------------------------------------------------------------------
--
-- calc_rs_grace_charge -
--
----------------------------------------------------------------------
PROCEDURE calc_rs_grace_charge
(
    in_rowid    IN      rowid,
    in_effdate  IN      date
)
IS
errmsg varchar2(200);
INVD invoicedtl%rowtype;
  CURSOR C_CNT(in_custid varchar2,
               in_item   varchar2,
               in_lotnumber varchar2,
               in_orderid number)
  IS
    select unitofmeasure, sum(quantity) qty, sum(weight) weight
	      ,count(distinct nvl(parentlpid, lpid)) plcnt
      from plate
     where custid = in_custid
       and item = in_item
       and NVL(lotnumber,'$X$X$X$') = NVL(in_lotnumber,
            NVL(lotnumber,'$X$X$X$'))
       and orderid = in_orderid
       and type = 'PA'
     group by unitofmeasure;

wt_now number;
qty_now number;
t_qty number;
plcnt_now number;
ORD   orderhdr%rowtype;
RATE  custrate%rowtype;
CUST  customer%rowtype;
rategroup rategrouptype;

BEGIN
  -- Get the invoice detail record;
    INVD := NULL;
    OPEN zbill.CINVD_ROWID(in_rowid);
    FETCH zbill.CINVD_ROWID into INVD;
    CLOSE zbill.CINVD_ROWID;

	-- Get the customer
    if zbill.rd_customer(INVD.custid, CUST) = BAD then
       return;
    end if;
	
	-- Get the rate group
    rategroup := zbut.item_rategroup(INVD.custid, INVD.item);
    if zbill.rd_rate(rategroup, INVD.activity, INVD.billmethod,
               sysdate, RATE) = BAD then
       rategroup := zbut.rategroup(CUST.custid,CUST.rategroup);
       if zbill.rd_rate(rategroup, INVD.activity,
                  INVD.billmethod, sysdate, RATE) = BAD then
		null;
	   end if;
	end if;

  -- check that the inventory received is still in the facility
    qty_now := 0;
    wt_now := 0;
	plcnt_now := 0;

    for crec in C_CNT(INVD.custid, INVD.item, INVD.lotnumber,
      INVD.orderid) loop
        t_qty := 0;
        zbut.translate_uom(INVD.custid,
                    INVD.item,
                    crec.qty,
                    crec.unitofmeasure,
                    INVD.entereduom,
                    t_qty,
                    errmsg);
        qty_now := qty_now + NVL(t_qty,0);
        wt_now := wt_now + crec.weight;
		plcnt_now := plcnt_now + NVL(crec.plcnt,0);
    end loop;
    -- DbMsg('Recalc Itm:'|| INVD.item || ' Qty: '|| to_char(qty_now));

  -- update the qty to the current qty which maybe 0
    if qty_now > INVD.enteredqty then
       qty_now := INVD.enteredqty;
    end if;
	
	if plcnt_now > INVD.calcedqty then
	   plcnt_now := INVD.calcedqty;
	end if;
	
    if RATE.billmethod = zbill.BM_PLT_COUNT or RATE.billmethod = zbill.BM_PLT_CNT_BRK then
	UPDATE invoicedtl
       SET enteredqty = qty_now,
           enteredweight = wt_now,
           billstatus = zbill.RECALC,
		   calcedqty = plcnt_now
    WHERE rowid = in_rowid;
    else
    UPDATE invoicedtl
       SET enteredqty = qty_now,
           enteredweight = wt_now,
           billstatus = zbill.RECALC
     WHERE rowid = in_rowid;
	end if;

    if zbill.calculate_detail_rate(in_rowid, in_effdate, errmsg) = BAD then
       null;
        --DbMsg('GC: '||errmsg);
    end if;
END calc_rs_grace_charge;

----------------------------------------------------------------------
--
-- daily_renewal_process - check for anniversary billing and grace period
--                       expirations
--
----------------------------------------------------------------------
FUNCTION daily_renewal_process
(
    in_checkdate IN      date,
    out_errmsg  IN OUT  varchar2
)
RETURN integer
IS
-- cursor for getting receipt storage delayed charges
CURSOR C_RSDC(in_expdate date)
IS
    SELECT rowid
      FROM invoicedtl
     WHERE expiregrace <= in_checkdate
       AND invoice = 0
       AND billstatus = zbill.UNCHARGED;

CURSOR C_ANV
RETURN customer%rowtype
IS
  SELECT *
    FROM customer
   WHERE custid in
    (SELECT custid
       FROM custratewhen
      WHERE businessevent = ZBILL.EV_ANVR
    UNION
     SELECT custid
       FROM custrategroup
      WHERE linkyn = 'Y'
        and linkrategroup in
        (select rategroup from custratewhen where custid = 'DEFAULT'
            and businessevent = ZBILL.EV_ANVR)
    )
    AND status = 'ACTV';

CURSOR C_ANVR(in_custid varchar2)
IS
  SELECT CI.custid, CI.item, CR.custid cr_custid, CR.rategroup,
         CR.effdate, CR.activity, CR.billmethod, CR.uom,
         CR.rate, CR.gracedays, CR.annvdays, CR.anvdate_grace,
         CR.cxd_grace, CR.cxd_grace_days, CR.cxd_anvdate_grace
    FROM custitem CI, custratewhen CRW, custrate CR
   WHERE CI.custid = in_custid
     AND CRW.businessevent = zbill.EV_ANVR
     AND CRW.automatic in ('A','C')
     AND CRW.custid
        = zbut.item_rategroup(CI.custid, CI.item).custid
     AND CRW.rategroup
        = zbut.item_rategroup(CI.custid, CI.item).rategroup
     AND CRW.effdate =
           (SELECT max(effdate)
              FROM custrate
             WHERE custid = CRW.custid
               AND rategroup = CRW.rategroup
               AND activity = CRW.activity
               AND billmethod = CRW.billmethod
               AND effdate <= trunc(sysdate))
    AND CR.custid = CRW.custid
    AND CR.rategroup = CRW.rategroup
    AND CR.effdate = CRW.effdate
    AND CR.activity = CRW.activity
    AND CR.billmethod = CRW.billmethod
    AND CR.billmethod not in (zbill.BM_QTY_LOT_RCPT,zbill.BM_WT_LOT_RCPT,
                zbill.BM_CWT_LOT_RCPT,zbill.BM_PARENT_BILLING);


CURSOR C_ANVBILL(in_custid varchar2, in_item varchar2,
    in_gracedays number, in_graceoff number,
    in_cxdgracedays number, in_cxdgraceoff number)
IS
    SELECT facility, custid, item, lotnumber, unitofmeasure,
        sum(quantity) quantity,
        sum(weight) weight,
        count(distinct plpid) pltcnt
      FROM (
    SELECT P.facility, P.custid, P.item,
        decode(decode(I.lotsumrenewal,'Y','N',decode(I.lotrequired,'C',
                C.lotrequired,I.lotrequired)),
            'Y', P.lotnumber, 'O', P.lotnumber, 'S', P.lotnumber, 'A', P.lotnumber, null) lotnumber,
        P.unitofmeasure,
        P.quantity,
        P.weight, 'P' rectype, P.lpid fromlpid, P.lpid,
        nvl(P.parentlpid, P.lpid) plpid
      FROM orderhdr OH, customer C, custitem I, loads L, plate P
     WHERE P.custid = in_custid
       AND P.item = in_item
       AND P.custid = C.custid
       AND P.custid = I.custid
       AND P.item = I.item
       AND P.loadno = L.loadno (+)
       AND P.orderid = OH.orderid (+)
       AND P.shipid = OH.shipid (+)
       AND P.type = 'PA'
       AND trunc(nvl(P.anvdate,decode(nvl(P.loadno, 0), 0, P.creationdate, L.rcvddate))) + decode(nvl(OH.ordertype,'R'),'C', in_cxdgracedays, in_gracedays)
                < trunc(in_checkdate)
       AND (to_char(trunc(nvl(P.anvdate,decode(nvl(P.loadno, 0), 0, P.creationdate,
               L.rcvddate))+decode(nvl(OH.ordertype,'R'),'C', in_cxdgraceoff,in_graceoff)),'DD') = to_char(in_checkdate,'DD')
            or (to_char(trunc(nvl(P.anvdate,decode(nvl(P.loadno, 0), 0, P.creationdate,
               L.rcvddate))+decode(nvl(OH.ordertype,'R'),'C', in_cxdgracedays,in_graceoff)),'DD') > to_char(in_checkdate,'DD')
                and last_day(in_checkdate) = in_checkdate))
UNION
    SELECT S.facility, S.custid, S.item,
        decode(decode(I.lotsumrenewal,'Y','N',decode(I.lotrequired,'C',
                C.lotrequired,I.lotrequired)),
            'Y', S.lotnumber, 'O', S.lotnumber, 'S', S.lotnumber, 'A', S.lotnumber,null) lotnumber,
        S.unitofmeasure,
        S.quantity,
        S.weight, 'S' rectype, S.fromlpid, S.lpid,
        nvl(P.parentlpid, P.lpid) plpid
      FROM orderhdr OH, customer C, custitem I, loads L, allplateview P,
            shippingplate S
     WHERE S.custid = in_custid
       AND S.item = in_item
       AND S.custid = C.custid
       AND S.custid = I.custid
       AND S.item = I.item
       AND S.type = 'P'
       AND S.status in ('P','S', 'L','FA')
       AND S.fromlpid = P.lpid(+)
       AND P.loadno = L.loadno (+)
       AND P.type(+) = 'PA'
       AND P.orderid = OH.orderid (+)
       AND P.shipid = OH.shipid (+)
       AND trunc(nvl(P.anvdate,decode(nvl(P.loadno, 0), 0, P.creationdate, L.rcvddate))) + decode(nvl(OH.ordertype,'R'),'C', in_cxdgracedays,in_gracedays)
                < trunc(in_checkdate)
       AND (to_char(trunc(nvl(P.anvdate,decode(nvl(P.loadno, 0), 0, P.creationdate,
               L.rcvddate))+decode(nvl(OH.ordertype,'R'),'C', in_cxdgraceoff,in_graceoff)),'DD') = to_char(in_checkdate,'DD')
            or (to_char(trunc(nvl(P.anvdate,decode(nvl(P.loadno, 0), 0, P.creationdate,
               L.rcvddate))+decode(nvl(OH.ordertype,'R'),'C', in_cxdgraceoff,in_graceoff)),'DD') > to_char(in_checkdate,'DD')
                and last_day(in_checkdate) = in_checkdate))
)
GROUP BY facility, custid, item, lotnumber, unitofmeasure
ORDER BY facility, custid, item;



CURSOR C_ANVD(in_custid varchar2)
IS
  SELECT CI.custid, CI.item, CR.custid cr_custid, CR.rategroup,
         CR.effdate, CR.activity, CR.billmethod, CR.uom,
         CR.rate, CR.gracedays, CR.annvdays, CR.anvdate_grace,
         CR.cxd_grace, CR.cxd_grace_days, CR.cxd_anvdate_grace
    FROM custitem CI, custratewhen CRW, custrate CR
   WHERE CI.custid = in_custid
     AND CRW.businessevent = zbill.EV_ANVD
     AND CRW.automatic in ('A','C')
     AND CRW.custid
        = zbut.item_rategroup(CI.custid, CI.item).custid
     AND CRW.rategroup
        = zbut.item_rategroup(CI.custid, CI.item).rategroup
     AND CRW.effdate =
           (SELECT max(effdate)
              FROM custrate
             WHERE custid = CRW.custid
               AND rategroup = CRW.rategroup
               AND activity = CRW.activity
               AND billmethod = CRW.billmethod
               AND effdate <= trunc(sysdate))
    AND CR.custid = CRW.custid
    AND CR.rategroup = CRW.rategroup
    AND CR.effdate = CRW.effdate
    AND CR.activity = CRW.activity
    AND CR.billmethod = CRW.billmethod
    AND CR.billmethod not in (zbill.BM_QTY_LOT_RCPT,zbill.BM_WT_LOT_RCPT,
           zbill.BM_CWT_LOT_RCPT,zbill.BM_PARENT_BILLING);



CURSOR C_ANVD_BILL(in_custid varchar2, in_item varchar2, in_days number,
    in_gracedays number, in_graceoff number,
    in_cxdgracedays number, in_cxdgraceoff number)
IS
    SELECT facility, custid, item, lotnumber, unitofmeasure,
        sum(quantity) quantity,
        sum(weight) weight,
        count(distinct plpid) pltcnt
      FROM (
    SELECT P.facility, P.custid, P.item,
        decode(decode(I.lotsumrenewal,'Y','N',decode(I.lotrequired,'C',
                C.lotrequired,I.lotrequired)),
            'Y', P.lotnumber, 'O', P.lotnumber, 'S', P.lotnumber, 'A', P.lotnumber, null) lotnumber,
        P.unitofmeasure,
        P.quantity,
        P.weight, 'P' rectype, P.lpid fromlpid, P.lpid,
        nvl(P.parentlpid, P.lpid) plpid
      FROM orderhdr OH, customer C, custitem I, loads L, plate P
     WHERE P.custid = in_custid
       AND P.item = in_item
       AND P.custid = C.custid
       AND P.custid = I.custid
       AND P.item = I.item
       AND P.loadno = L.loadno (+)
       AND P.orderid = OH.orderid (+)
       AND P.shipid = OH.shipid (+)
       AND P.type = 'PA'
       AND nvl(L.loadstatus(+),'R') = 'R'
       AND trunc(nvl(P.anvdate,decode(nvl(P.loadno, 0), 0, P.creationdate, L.rcvddate))) + decode(nvl(OH.ordertype,'R'),'C', in_cxdgracedays,in_gracedays)
                < trunc(in_checkdate)
       AND mod(trunc(in_checkdate) -
                 trunc(nvl(P.anvdate,decode(nvl(P.loadno, 0), 0, P.creationdate,L.rcvddate))+decode(nvl(OH.ordertype,'R'),'C', in_cxdgraceoff,in_graceoff)),
            in_days) = 0
       AND trunc(sysdate) > trunc(nvl(P.anvdate,decode(nvl(P.loadno, 0), 0, P.creationdate,
               L.rcvddate)))
UNION
    SELECT S.facility, S.custid, S.item,
        decode(decode(I.lotsumrenewal,'Y','N',decode(I.lotrequired,'C',
                C.lotrequired,I.lotrequired)),
            'Y', S.lotnumber, 'O', S.lotnumber, 'S', S.lotnumber, 'A', S.lotnumber,null) lotnumber,
        S.unitofmeasure,
        S.quantity,
        S.weight, 'S' rectype, S.fromlpid, S.lpid,
        nvl(P.parentlpid, P.lpid) plpid
      FROM orderhdr OH, customer C, custitem I, loads L, allplateview P, shippingplate S
     WHERE S.custid = in_custid
       AND S.item = in_item
       AND S.custid = C.custid
       AND S.custid = I.custid
       AND S.item = I.item
       AND S.type = 'P'
       AND S.status in ('P','S', 'L','FA')
       AND S.fromlpid = P.lpid(+)
       AND P.loadno = L.loadno (+)
       AND P.orderid = OH.orderid (+)
       AND P.shipid = OH.shipid (+)
       AND P.type(+) = 'PA'
       AND nvl(L.loadstatus(+),'R') = 'R'
       AND trunc(nvl(P.anvdate,decode(nvl(P.loadno, 0), 0, P.creationdate, L.rcvddate)))+decode(nvl(OH.ordertype,'R'),'C', in_cxdgracedays,in_gracedays)
                < trunc(in_checkdate)
       AND mod(trunc(in_checkdate) -
                 trunc(nvl(P.anvdate,decode(nvl(P.loadno, 0), 0,
                    P.creationdate,L.rcvddate))+decode(nvl(OH.ordertype,'R'),'C', in_cxdgracedays,in_graceoff)),
            in_days) = 0
       AND trunc(sysdate) > trunc(nvl(P.anvdate,decode(nvl(P.loadno, 0), 0,
               P.creationdate,
               L.rcvddate))))
GROUP BY facility, custid, item, lotnumber, unitofmeasure
ORDER BY facility, custid, item;


ORD orderhdr%rowtype;
ITEM custitem%rowtype;
RATE custrate%rowtype;
CUST customer%rowtype;

item_rategroup custitem.rategroup%type;

l_facilities varchar2(255);
rc integer;
now_date date;

l_gracedays integer;
l_graceoff integer;
l_cxdgracedays integer;
l_cxdgraceoff integer;
BEGIN

   out_errmsg := 'OKAY';        -- I Hope

    now_date := nvl(in_checkdate,sysdate);

-- Check for rerun of the process
    if not zbs.check_daily_billing(now_date) then
        out_errmsg := 'Daily billing check failed for renewal dt:'
               || to_char(now_date,'YYYYMMDD');
        return BAD;
    end if;


-- First check for receipt storage delay entries that kick off
--       today and have not been processed
   for crec in C_RSDC(in_checkdate) loop
       calc_rs_grace_charge(crec.rowid, in_checkdate);
   end loop;

-- Next for customers with anniversary billing
-- find the loads where today is an anniversary and still in the
-- warehouse and create a charge for them
--   For now just use ??? since there isn't a receive_date
--   and last billed date
   for crec in C_ANV loop
-- Get the customer information
       if zbill.rd_customer(crec.custid, CUST) = BAD then
          out_errmsg := 'Invalid custid = '|| crec.custid;
          return BAD;
       end if;
      ORD := null;
     for crecr in C_ANVR(crec.custid) loop
      if (nvl(crecr.anvdate_grace,'N') = 'Y') then
        l_gracedays := nvl(crecr.gracedays,0);
        l_graceoff := nvl(crecr.gracedays,0);
        l_cxdgracedays := nvl(crecr.gracedays,0);
        l_cxdgraceoff := nvl(crecr.gracedays,0);
      else
        l_gracedays := nvl(crecr.gracedays,0);
        l_graceoff := 0;
        l_cxdgracedays := nvl(crecr.gracedays,0);
        l_cxdgraceoff := 0;
      end if;

      if (nvl(crecr.cxd_grace,'N') = 'Y') then
          if (nvl(crecr.cxd_anvdate_grace,'N') = 'Y') then
            l_cxdgracedays := nvl(crecr.cxd_grace_days,0);
            l_cxdgraceoff := nvl(crecr.cxd_grace_days,0);
          else
            l_cxdgracedays := nvl(crecr.cxd_grace_days,0);
            l_cxdgraceoff := 0;
          end if;
      end if;

      for crec2 in C_ANVBILL(crecr.custid, crecr.item,
            l_gracedays, l_graceoff,
            l_cxdgracedays, l_cxdgraceoff)
      loop
      -- Check Order for this facility
         if NVL(ORD.tofacility,'XX') != crec2.facility then
            rc := get_renewal_order(crec, crec2.facility, ORD, 'DAILY');
         end if;
      -- get the ITEM record for this plate
         if zbill.rd_item(crec.custid, crec2.item, ITEM) = zbill.BAD then
            null;
         end if;
         zbill.rd_item_rategroup(ITEM.custid, ITEM.item, ITEM.rategroup);
    -- Determine the rate group to use for renewal for this item
    -- based on the existance of an entry for the RENEWAL business event
         zbill.select_rategroup(CUST.custid, ITEM.rategroup,
             CUST.rategroup, zbill.EV_ANVR, crec2.facility, item_rategroup);
         -- rategroup := ITEM.rategroup;

      -- get all the activities for this event
         for crec3 in zbill.C_RATE_WHEN_ACTV(crec.custid, item_rategroup,
                zbill.EV_ANVR, crecr.activity, crec2.facility, now_date) loop

             if crec3.billmethod in (zbill.BM_QTY_LOT_RCPT,
                zbill.BM_WT_LOT_RCPT,zbill.BM_CWT_LOT_RCPT) then
                goto skip_it;
             end if;

         -- Get rate for this activity
            if zbill.rd_rate(rategrouptype(crec3.custid, crec3.rategroup),
                 crec3.activity,
                 crec3.billmethod, now_date, RATE) = BAD then
                null;
            end if;
            if RATE.billmethod = zbill.BM_FLAT then
                crec2.quantity := 1;
            end if;

         -- Create a billing entry for this item
            if RATE.rate > 0 then
              INSERT INTO invoicedtl
               (
                  billstatus,
                  facility,
                    custid,
                    invtype,
                    invdate,
                    item,
                    lotnumber,
                    orderid,
                    shipid,
                    activity,
                    activitydate,
                    billmethod,
                    enteredqty,
                    entereduom,
                    enteredweight,
                    calcedqty,
                    calceduom,
                    statusrsn,
                    lastuser,
                    lastupdate,
                    businessevent
                 )
                 values
                 (
                    zbill.UNCHARGED,
                    crec2.facility,
                    CREC.custid,
                    zbill.IT_STORAGE,
                    sysdate,
                    crec2.item,
                    crec2.lotnumber,
                    ORD.orderid,
                    ORD.shipid,
                    RATE.activity,
                    now_date, -- sysdate,
                    RATE.billmethod,
                    crec2.quantity,
                    crec2.unitofmeasure,
                    crec2.weight,
                    crec2.pltcnt,
                    '*PLT',
                    zbill.SR_ANVR,
                    'BILLER',
                    sysdate,
                    zbill.EV_ANVR
                 );
             end if;
    << skip_it >>
            null;
         end loop;
      end loop; -- C_ANVD
     end loop; -- C_ANVR

      for crec2 in C_ANV_CHARGE(crec.custid) loop
        out_errmsg := '';
        if zbill.calculate_detail_rate(crec2.rowid, now_date,out_errmsg) = BAD then
            null;
        end if;
        update invoicedtl
           set billstatus = zbill.UNCHARGED
         where rowid = crec2.rowid;
      end loop;
   end loop;


--
-- Anniversary Days Renewal
--

    for crec in (select *
                   from customer
                  where custid in
                    (select custid
                       from custratewhen
                      where businessevent = ZBILL.EV_ANVD
                    UNION
                     select custid
                       from custrategroup
                      where linkyn = 'Y'
                        and linkrategroup in
                        (select rategroup
                           from custratewhen
                          where custid = 'DEFAULT'
                            and businessevent = ZBILL.EV_ANVD))
                    and status = 'ACTV')
    loop
      -- DbMsg('Have customer:'|| crec.custid);

      ORD := null;
      for cit in C_ANVD(crec.custid)
      loop
          -- DbMsg('...Have Rategroup Item and days:'
          --    ||cit.cr_custid||'/'||cit.rategroup||' Itm:'
          --    ||cit.custid||'/'||cit.item
          --    ||' Days:'||cit.annvdays);

        if (nvl(cit.anvdate_grace,'N') = 'Y') then
            l_gracedays := nvl(cit.gracedays,0);
            l_graceoff := nvl(cit.gracedays,0);
            l_cxdgracedays := nvl(cit.gracedays,0);
            l_cxdgraceoff := nvl(cit.gracedays,0);
        else
            l_gracedays := nvl(cit.gracedays,0);
            l_graceoff := 0;
            l_cxdgracedays := nvl(cit.gracedays,0);
            l_cxdgraceoff := 0;
        end if;

        if (nvl(cit.cxd_grace,'N') = 'Y') then
          if (nvl(cit.cxd_anvdate_grace,'N') = 'Y') then
            l_cxdgracedays := nvl(cit.cxd_grace_days,0);
            l_cxdgraceoff := nvl(cit.cxd_grace_days,0);
          else
            l_cxdgracedays := nvl(cit.cxd_grace_days,0);
            l_cxdgraceoff := 0;
          end if;
        end if;

        for cpl in C_ANVD_BILL(cit.custid, cit.item, cit.annvdays,
            l_gracedays, l_graceoff,
            l_cxdgracedays, l_cxdgraceoff)
        loop

            if zbill.rd_rate(rategrouptype(cit.cr_custid, cit.rategroup),
                 cit.activity,
                 cit.billmethod, now_date, RATE) = BAD then
                goto annvd_continue;
            end if;

            begin
              select ',' || rtrim(facilities) || ','
                into l_facilities
                from custactvfacilities
               where custid = cit.custid
                 and activity = RATE.activity;
            exception when others then
              l_facilities := ',' || rtrim(cpl.facility) || ',';
            end;

            if instr(l_facilities, ',' || rtrim(cpl.facility) || ',') = 0 then            
              goto annvd_continue;
            end if;
            
      -- Check Order for this facility
            if NVL(ORD.tofacility,'XX') != cpl.facility then
               rc := get_renewal_order(crec, cpl.facility, ORD, 'DAILY');
            end if;
            -- DbMsg('......Have totals:'||cpl.quantity||' WT:'||cpl.weight);
            if RATE.billmethod = zbill.BM_FLAT then
                CPL.quantity := 1;
            end if;

         -- Create a billing entry for this item
            if RATE.rate > 0 then
              INSERT INTO invoicedtl
               (
                  billstatus,
                  facility,
                    custid,
                    invtype,
                    invdate,
                    item,
                    lotnumber,
                    orderid,
                    shipid,
                    activity,
                    activitydate,
                    billmethod,
                    enteredqty,
                    entereduom,
                    enteredweight,
                    calcedqty,
                    calceduom,
                    statusrsn,
                    lastuser,
                    lastupdate,
                    businessevent
                 )
                 values
                 (
                    zbill.UNCHARGED,
                    CPL.facility,
                    CIT.custid,
                    zbill.IT_STORAGE,
                    sysdate,
                    CPL.item,
                    CPL.lotnumber,
                    ORD.orderid,
                    ORD.shipid,
                    RATE.activity,
                    now_date,
                    RATE.billmethod,
                    CPL.quantity,
                    CPL.unitofmeasure,
                    CPL.weight,
                    CPL.pltcnt,
                    '*PLT',
                    zbill.SR_ANVD,
                    'BILLER',
                    sysdate,
                    ZBILL.EV_ANVD
                 );
             end if;

    <<annvd_continue>>
            null;
        end loop;

      end loop;

      for crec2 in C_ANV_CHARGE(crec.custid) loop
        out_errmsg := '';
        if zbill.calculate_detail_rate(crec2.rowid, now_date,out_errmsg) = BAD then
            null;
        end if;
        update invoicedtl
           set billstatus = zbill.UNCHARGED
         where rowid = crec2.rowid;
      end loop;
    end loop;




   return GOOD;

END daily_renewal_process;


----------------------------------------------------------------------
--
-- calc_customer_renewal - calculate renewal billing for the
--                    specified customer id for the specified date
--
----------------------------------------------------------------------
FUNCTION calc_customer_renewal
(
    in_custid   IN      varchar2,
    in_facility IN  varchar2,
    in_effdate  IN  date,
    in_force    IN  varchar2,
    in_userid   IN  varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer
IS

  CURSOR C_ASOF_ITEMS(
    in_custid   varchar2,
    in_facility varchar2,
    in_effdate  date)
  IS
    SELECT distinct item
      FROM asofinventory A
     WHERE A.facility = in_facility
       AND A.custid = in_custid
       AND A.currentqty != 0
       AND (A.item, nvl(A.lotnumber,'(none)'), uom, invstatus, inventoryclass,
                A.effdate) in
            (select item, lotnumber, uom, invstatus, inventoryclass,
                effdate from asofeffdate_temp);


  CURSOR C_ASOF_QTY(
    in_custid   varchar2,
    in_facility varchar2,
    in_item varchar2,
    in_tracklot varchar2,
    in_effdate  date)
  IS
    SELECT facility,
           decode(in_tracklot,'Y',lotnumber,'O',lotnumber,'S',lotnumber,'A',lotnumber,null) lot,
           uom, sum(currentqty) qty, sum(currentweight) weight
      FROM asofinventory A
     WHERE A.facility = in_facility
       AND A.custid = in_custid
       AND A.item = in_item
       AND A.currentqty != 0
       AND (A.item, nvl(A.lotnumber,'(none)'), uom, invstatus, inventoryclass,
                A.effdate) in
            (select item, lotnumber, uom, invstatus, inventoryclass,
                effdate from asofeffdate_temp)
    GROUP BY facility,
           decode(in_tracklot,'Y',lotnumber,'O',lotnumber,'S',lotnumber,'A',lotnumber,null),
           uom;


  CURSOR C_ASOF_ITEM_QTY(
    in_custid   varchar2,
    in_facility varchar2,
    in_item varchar2,
    in_lotnumber varchar2,
    in_effdate  date)
  IS
    SELECT uom, sum(currentqty) qty, sum(currentweight) weight
      FROM asofinventory A
     WHERE A.facility = in_facility
       AND A.custid = in_custid
       AND A.item = in_item
       AND nvl(A.lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
       AND A.currentqty != 0
       AND A.effdate =
           (SELECT max(effdate)
              FROM asofinventory B
             WHERE B.facility = in_facility
               AND B.custid = in_custid
               AND B.item = A.item
               AND B.uom = A.uom
               AND NVL(B.lotnumber,'$X$X$X$') = NVL(A.lotnumber,'$X$X$X$')
               AND NVL(B.invstatus,'$X$X$X$') = NVL(A.invstatus,'$X$X$X$')
               AND NVL(B.inventoryclass,'$X$X$X$') = NVL(A.inventoryclass,'$X$X$X$')
               AND effdate <= in_effdate)
    GROUP BY uom;



  CURSOR C_PLTC_ITEMS(
    in_custid   varchar2,
    in_facility varchar2,
    in_effdate  date)
  IS
    SELECT distinct item
      FROM billpalletcnt P
     WHERE P.facility = in_facility
       AND P.custid = in_custid
       AND P.item != 'location'
       AND P.effdate = in_effdate;

  CURSOR C_PLTC_QTY(
    in_custid   varchar2,
    in_facility varchar2,
    in_item varchar2,
    in_tracklot varchar2,
    in_effdate  date)
  IS
    SELECT facility,
           decode(in_tracklot,'Y',lotnumber,'O',lotnumber,'S',lotnumber,'A',lotnumber,null) lot,
           uom, sum(pltqty) pltqty, sum(uomqty) uomqty
      FROM billpalletcnt P
     WHERE P.facility = in_facility
       AND P.custid = in_custid
       AND P.item = in_item
       AND P.item != 'location'
       AND P.effdate = in_effdate
    GROUP BY facility,
           decode(in_tracklot,'Y',lotnumber,'O',lotnumber,'S',lotnumber,'A',lotnumber,null),
           uom;

  CURSOR C_PLTC_TOT(
    in_custid   varchar2,
    in_facility varchar2,
    in_effdate  date)
  IS
    SELECT sum(pltqty) pltqty, sum(uomqty) uomqty
      FROM billpalletcnt P
     WHERE P.facility = in_facility
       AND P.custid = in_custid
       AND P.item != 'location'
       AND P.effdate = in_effdate; 
  PLTC_TOT C_PLTC_TOT%rowtype;

  CURSOR C_LOCC_ITEMS(
    in_custid   varchar2,
    in_facility varchar2,
    in_effdate  date)
  IS
    SELECT A.abbrev activity, sum(P.pltqty) pltcnt
      FROM billbylocationactivity A, billpalletcnt P
     WHERE P.facility = in_facility
       AND P.custid = in_custid
       AND P.item = 'location'
       AND P.effdate = in_effdate
       AND A.code = P.lotnumber
     GROUP BY A.abbrev;

  CURSOR C_PRNT_PLTQTY(in_facility varchar2,
                       in_custid varchar2,
                       in_effdate date)
  is
    select decode(num_items,1,item,decode(num_rategroups,1,'MIXED','NOCALC')) as item, 
      decode(lot_track_req,'Y',decode(num_lotnumbers,1,lotnumber,'MIXED'),null) as lotnumber,
      rategroup, count(1) as pallets
    from (
      select nvl(parentlpid, lpid), zbut.prnt_get_lottrack_req(nvl(parentlpid, lpid), zbill.EV_RENEWAL, in_effdate) as lot_track_req,
        min(a.item) as item, count(distinct a.item) as num_items,
        min(a.lotnumber) as lotnumber, count(distinct nvl(a.lotnumber,'(none)')) as num_lotnumbers,
        min(zbut.rategroup(a.custid, b.rategroup)) as rategroup, 
        count(distinct zbut.rategroup(a.custid, b.rategroup)) as num_rategroups,
        sum(zbut.check_rg_bm_event(zbut.rategroup(a.custid, b.rategroup).custid, 
                                   zbut.rategroup(a.custid, b.rategroup).rategroup, 
                                   zbill.BM_PARENT_BILLING, zbill.EV_RENEWAL, in_effdate)) as use_bm
      from billparentpltcnt a, custitem b
      where a.facility = in_facility and a.custid = in_custid and a.effdate = in_effdate
        and a.custid = b.custid and a.item = b.item
      group by nvl(parentlpid, lpid))
    where use_bm > 0
    group by decode(num_items,1,item,decode(num_rategroups,1,'MIXED','NOCALC')), 
      decode(lot_track_req,'Y',decode(num_lotnumbers,1,lotnumber,'MIXED'),null), rategroup;

  CURSOR C_CBD(in_custid varchar2)
  RETURN custbilldates%rowtype
  IS
    SELECT *
      FROM custbilldates
     WHERE custid = in_custid;

  CURSOR C_ORDERS(in_facility varchar2, in_custid varchar2)
  RETURN orderhdr%rowtype
  IS
    SELECT *
      FROM orderhdr
     WHERE custid = in_custid
       AND tofacility = in_facility
       AND ordertype = 'S'   -- Renewal Storage
       AND orderstatus = 'A';    -- ??? Use Arrived for now

  CURSOR C_INVV(in_invoice number)
  IS
    SELECT rowid, activitydate
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND billstatus = zbill.UNCHARGED;

  CURSOR C_RS_GRACE(in_facility varchar2,
                    in_custid varchar2,
                    in_end    date)
  IS
    SELECT facility, rowid
      FROM invoicedtl
     WHERE facility = in_facility
       AND custid = in_custid
       AND billstatus in ( zbill.NOT_REVIEWED, zbill.REVIEWED)
       AND invoice = 0
       AND expiregrace <= in_end;

  CURSOR C_ANVR(in_facility varchar2,
                    in_custid varchar2,
                    in_end    date)
  IS
    SELECT facility, rowid
      FROM invoicedtl
     WHERE facility = in_facility
       AND custid = in_custid
       AND billstatus in (zbill.UNCHARGED, zbill.NOT_REVIEWED)
       AND invoice = 0
       AND trunc(activitydate) <= in_end
       AND statusrsn in (zbill.SR_ANVR,zbill.SR_ANVD);

  CURSOR C_CLR(in_facility varchar2,
               in_custid varchar2)
  IS
    SELECT lastrenewal
      FROM custlastrenewal
     WHERE facility = in_facility
       AND custid = in_custid;

  CURSOR C_TODO(in_custid varchar2)
  IS
    SELECT *
      FROM renewalsview R
     WHERE R.custid = in_custid;

  CURSOR C_RCPTS(in_facility varchar2, in_custid varchar2, in_effdate date)
  IS
    SELECT count(*)
      FROM loads L, orderhdr O
     WHERE O.custid = in_custid
       AND O.tofacility = in_facility
       AND O.ordertype in ('R','Q','T','C','U')
       AND O.orderstatus = 'A'
       AND O.loadno = L.loadno
       AND L.rcvddate <= in_effdate;

  CURSOR C_SD(in_id varchar2)
  IS
  SELECT defaultvalue
    FROM systemdefaults
   WHERE defaultid = in_id;

  lrr systemdefaults.defaultvalue%type;

  CURSOR C_BLR(in_facility varchar2, in_custid varchar2,
               in_item varchar2, in_lotnumber varchar2)
  IS
    SELECT rowid, bill_lot_renewal.*
      FROM bill_lot_renewal
     WHERE facility = in_facility
       AND custid = in_custid
       AND item = in_item
       and nvl(lotnumber, '(none)') = nvl(in_lotnumber, '(none)');

  BLR C_BLR%rowtype;

 asofeomstart systemdefaults.defaultvalue%type;

 tdate date;
 lastrenewal date;

 CUST customer%rowtype;
 CBD custbilldates%rowtype;
 ITEM custitem%rowtype;
 RATE custrate%rowtype;
 ORD  orderhdr%rowtype;
 INVH invoicehdr%rowtype;

 item_rategroup custitem.rategroup%type;
 rc integer;
 track_lot  char(1);

 nextrenewal date;

 n1      number;
 n2      number;
 n3      number;
 terrmsg varchar2(200);
 cnt integer;
 l_prev_eom date;
 v_count number;
 v_renewal_start  date := sysdate;
 v_renewal_end    date;
 v_proc_beg_seconds  number;
 v_proc_asof_seconds number;
 v_proc_pltc_seconds number;
 v_proc_locc_seconds number;
 v_proc_lrr_seconds  number;
 v_proc_ordloop_seconds  number;
 v_proc_ordloop_rows number;
 v_proc_bac_seconds  number;
 v_proc_end_seconds  number;
 v_proc_tot_seconds  number;

BEGIN
  out_errmsg := 'OKAY';

-- Clear order and invoice header
    ORD := null;
    INVH := null;

-- Get the customer information
    if zbill.rd_customer(in_custid, CUST) = BAD then
       out_errmsg := 'Invalid custid = '|| in_custid;
       -- DbMsg(out_errmsg);
       return BAD;
    end if;

-- Get the customer bill dates
    CBD := null;
    OPEN C_CBD(in_custid);
    FETCH C_CBD into CBD;
    CLOSE C_CBD;

-- Check effective date = nextrenewal date
    if in_effdate != CBD.nextrenewal then
       out_errmsg := 'Invalid renewal date '|| to_char(in_effdate)
        ||' Next renewal is '||to_char(CBD.nextrenewal);
       -- DbMsg(out_errmsg);
       return BAD;
    end if;

-- check for lot receipt renewal processing
    lrr := null;
    OPEN C_SD('LOTRECEIPTRENEWAL');
    FETCH C_SD into lrr;
    CLOSE C_SD;

-- Get the customer last renewal date for this facility
    lastrenewal := null;
    OPEN C_CLR(in_facility, in_custid);
    FETCH C_CLR into lastrenewal;
    CLOSE C_CLR;

    if in_effdate = lastrenewal and in_force != 'Y' then
       out_errmsg := 'Renewal already run for this facility';
       -- DbMsg(out_errmsg);
       return BAD;
    end if;

-- Add the temp table information
    l_prev_eom := last_day(in_effdate - 32);

-- check for asof eom setup
    asofeomstart := null;
    OPEN C_SD('asofeomstart');
    FETCH C_SD into asofeomstart;
    CLOSE C_SD;

    if to_char(l_prev_eom,'YYYYMMDD') < nvl(asofeomstart,'99991231') then
        l_prev_eom := to_date('19900101','YYYYMMDD');
    end if;

    delete from asofeffdate_temp;

    insert into asofeffdate_temp
        select item, nvl(lotnumber,'(none)'),uom,invstatus,inventoryclass,
            max(effdate)
          from asofinventory
         where facility = in_facility
           and custid = in_custid
           and effdate <= in_effdate
           and effdate >= l_prev_eom
        group by item, nvl(lotnumber,'(none)'),uom,invstatus,inventoryclass;


-- Verify all receipts arrived before the effective date have been closed
    rc := 0;
    -- anything arrived to midnight of renewal date
    tdate := to_date(to_char(in_effdate,'YYYYMMDD') || '235959'
            ,'YYYYMMDDHH24MISS');

    OPEN C_RCPTS(in_facility, in_custid, tdate);
    FETCH C_RCPTS into rc;
    CLOSE C_RCPTS;

    if rc > 0 then
        if in_force = 'Y' then
            INSERT INTO userhistory(
                nameid,
                begtime,
                event,
                endtime,
                facility,
                custid,
                equipment,
                units,
                etc
            )
            values (
                in_userid,
                sysdate,
                'RNOV',
                sysdate,
                in_facility,
                in_custid,
                null,
                null,
                'Force renewal with open receipts = '||to_char(rc)
            );

        else
            out_errmsg := 'There are '|| to_char(rc)||' receipts still open.';
            -- DbMsg(out_errmsg);
            return BAD;
        end if;
    end if;


-- NEW TEST ADD
    rc := get_renewal_order(CUST, in_facility, ORD, in_userid);
    rc := zbill.get_invoicehdr('FIND',zbill.IT_STORAGE,
               CUST.custid, in_facility, 'BILLER', INVH);

-- Add the delayed receipt storage charges to invoices for this customer
    for crec in C_RS_GRACE(in_facility, in_custid, in_effdate) loop
        if NVL(INVH.facility,'XX') != crec.facility then
            rc := zbill.get_invoicehdr('FIND',zbill.IT_STORAGE,
                 CUST.custid, crec.facility, 'BILLER', INVH);
        end if;
        UPDATE invoicedtl
           SET invoice = INVH.invoice,
               invtype = INVH.invtype,
               invdate = INVH.invdate
         WHERE rowid = crec.rowid;
    end loop;

-- Add the anniversary receipt storage charge to invoice for this customer
    for crec in C_ANVR(in_facility, in_custid, in_effdate) loop
        if NVL(INVH.facility,'XX') != crec.facility then
            rc := zbill.get_invoicehdr('FIND',zbill.IT_STORAGE,
                 CUST.custid, crec.facility, 'BILLER', INVH);
        end if;
        UPDATE invoicedtl
           SET invoice = INVH.invoice,
               invtype = INVH.invtype,
               invdate = INVH.invdate
         WHERE rowid = crec.rowid;
    end loop;

    v_proc_beg_seconds := round((sysdate - v_renewal_start) * 86400,4);
    v_renewal_end := sysdate;
    

    for crec in C_ASOF_ITEMS(in_custid, in_facility, in_effdate) loop
       -- DbMsg('Item:'||crec.item);

--            ||' Lot:'||crec.lotnumber
--            ||' Effdate:'||to_char(crec.effdate,'YYYYMMDD')
 --           ||' Qty:'||to_char(crec.currentqty));

    -- Get the item row
        if zbill.rd_item(CUST.custid, crec.item, ITEM) = zbill.BAD then
        -- Log an error somewhere ???
           null;
        end if;

    -- Determine the rate group to use for renewal for this item
    -- based on the existance of an entry for the RENEWAL business event
         zbill.rd_item_rategroup(ITEM.custid, ITEM.item, item_rategroup);

    --   DbMsg('Item:'||ITEM.item||' Rategroup:'||rategroup);

    -- For each Renewal Event
        for crec2 in zbill.C_RATE_WHEN(CUST.custid, item_rategroup,
                           zbill.EV_RENEWAL, in_facility, in_effdate) loop


    --   Get the rategroup renewal activity charge row
          if zbill.rd_rate(rategrouptype(crec2.custid, crec2.rategroup),
               crec2.activity,
               crec2.billmethod, in_effdate, RATE) = BAD then
              null;
          end if;
        -- get qtys by lotnumber (if necessary) and create invoicedtl
        -- records
         if crec2.billmethod in
             (zbill.BM_QTY, zbill.BM_QTYM, zbill.BM_FLAT,
              zbill.BM_CWT, zbill.BM_WT, zbill.BM_QTY_BREAK,
              zbill.BM_FLAT_BREAK, zbill.BM_WT_BREAK, zbill.BM_CWT_BREAK,
              zbill.BM_QTY_LOT_RCPT,zbill.BM_WT_LOT_RCPT,
              zbill.BM_CWT_LOT_RCPT) then
         -- Determine if we are tracking lots or not
            track_lot := ITEM.lotrequired;
            if track_lot = 'C' then
               track_lot := CUST.lotrequired;
            end if;
            if ITEM.lotsumrenewal = 'Y' then
                track_lot := 'N';
            end if;

           for crec3 in C_ASOF_QTY(in_custid, in_facility,
            crec.item, track_lot, in_effdate) loop


           --   DbMsg(' Lot:'||crec3.lot
           --   ||' Qty:'||to_char(crec3.qty));
           -- Get order for storage facility
           -- Get invoice hdr for this order

             if RATE.billmethod = zbill.BM_FLAT then
                 crec3.qty := 1;
             end if;

             if NVL(ORD.tofacility,'XX') != crec3.facility then
                 rc := get_renewal_order(CUST, crec3.facility, ORD, in_userid);
                 rc := zbill.get_invoicehdr('FIND',zbill.IT_STORAGE,
                   CUST.custid, crec3.facility, 'BILLER', INVH);
             end if;

             if crec3.qty > 0 then
             INSERT INTO invoicedtl
             (
                billstatus,
                facility,
                custid,
                orderid,
                shipid,
                item,
                lotnumber,
                activity,
                activitydate,
                billmethod,
                enteredqty,
                entereduom,
                enteredrate,
                enteredamt,
                enteredweight,
                invoice,
                invtype,
                invdate,
                statusrsn,
                lastuser,
                lastupdate,
                businessevent
              )
              values
              (
                zbill.UNCHARGED,
                crec3.facility,
                CUST.custid,
                ORD.orderid,
                ORD.shipid,
                ITEM.item,
                crec3.lot,
                RATE.activity,
                in_effdate, -- sysdate,
                RATE.billmethod,
                crec3.qty,
                crec3.uom,
                null,                   -- RATE.rate,
                null,                   -- RATE.rate * crec3.qty,
                crec3.weight,
                INVH.invoice,
                INVH.invtype,
                INVH.invdate,
                zbill.SR_RENEW,
                'BILLER',
                sysdate,
                zbill.EV_RENEWAL
              );

             end if;
           end loop;
         end if;
        end loop;

    end loop;

    v_proc_asof_seconds := round((sysdate - v_renewal_end) * 86400,4);
    v_renewal_end := sysdate;
--
-- Do Processing for pallet counts New Feature
--

    PLTC_TOT := null;
    OPEN C_PLTC_TOT(in_custid, in_facility, trunc(in_effdate));
    FETCH C_PLTC_TOT into PLTC_TOT;
    CLOSE C_PLTC_TOT;
              
    for crec in C_PLTC_ITEMS(in_custid, in_facility, trunc(in_effdate)) loop
    -- Get the item row
        if zbill.rd_item(CUST.custid, crec.item, ITEM) = zbill.BAD then
        -- Log an error somewhere ???
           null;
        end if;

    -- Determine the rate group to use for renewal for this item
    -- based on the existance of an entry for the RENEWAL business event
         zbill.rd_item_rategroup(ITEM.custid, ITEM.item, item_rategroup);

    --   DbMsg('Item:'||ITEM.item||' Rategroup:'||rategroup);

    -- For each Renewal Event
        for crec2 in zbill.C_RATE_WHEN(CUST.custid, item_rategroup,
                           zbill.EV_RENEWAL, in_facility, in_effdate) loop

    --   Get the rategroup renewal activity charge row
          if zbill.rd_rate(rategrouptype(crec2.custid, crec2.rategroup),
               crec2.activity,
               crec2.billmethod, in_effdate, RATE) = BAD then
              null;
          end if;
        -- get qtys by lotnumber (if necessary) and create invoicedtl
        -- records
         if crec2.billmethod = zbill.BM_PLT_COUNT or crec2.billmethod = zbill.BM_PLT_CNT_BRK then
         -- Determine if we are tracking lots or not
            track_lot := ITEM.lotrequired;
            if track_lot = 'C' then
               track_lot := CUST.lotrequired;
            end if;
            if ITEM.lotsumrenewal = 'Y' then
                track_lot := 'N';
            end if;

           for crec3 in C_PLTC_QTY(in_custid, in_facility,
            crec.item, track_lot, trunc(in_effdate)) loop


             if NVL(ORD.tofacility,'XX') != crec3.facility then
                 rc := get_renewal_order(CUST, crec3.facility, ORD, in_userid);
                 rc := zbill.get_invoicehdr('FIND',zbill.IT_STORAGE,
                   CUST.custid, crec3.facility, 'BILLER', INVH);
             end if;

             if crec3.pltqty > 0 then
             INSERT INTO invoicedtl
             (
                billstatus,
                facility,
                custid,
                orderid,
                shipid,
                item,
                lotnumber,
                activity,
                activitydate,
                billmethod,
                enteredqty,
                entereduom,
                enteredrate,
                enteredamt,
                calcedqty,
                calceduom,
                invoice,
                invtype,
                invdate,
                statusrsn,
                lastuser,
                lastupdate,
                businessevent,
                pallet_count_total
              )
              values
              (
                zbill.UNCHARGED,
                crec3.facility,
                CUST.custid,
                ORD.orderid,
                ORD.shipid,
                ITEM.item,
                crec3.lot,
                RATE.activity,
                in_effdate, --sysdate,
                RATE.billmethod,
                crec3.uomqty,
                crec3.uom,
                null,                   -- RATE.rate,
                null,                   -- RATE.rate * crec3.qty,
                crec3.pltqty,
                '*PLT',
                INVH.invoice,
                INVH.invtype,
                INVH.invdate,
                zbill.SR_RENEW,
                'BILLER',
                sysdate,
                zbill.EV_RENEWAL,
                PLTC_TOT.pltqty
              );

             end if;
           end loop;
         end if;
        end loop;

    end loop;

    v_proc_pltc_seconds := round((sysdate - v_renewal_end) * 86400,4);
    v_renewal_end := sysdate;
--
-- Do Processing for location counts New Feature
--
    for crec in C_LOCC_ITEMS(in_custid, in_facility, in_effdate) loop
    -- For each Renewal Event
        item_rategroup := CUST.rategroup;
        for crec2 in zbill.C_RATE_WHEN(CUST.custid, item_rategroup,
                           zbill.EV_RENEWAL, in_facility, in_effdate) loop

    --   Get the rategroup renewal activity charge row
          if zbill.rd_rate(rategrouptype(crec2.custid, crec2.rategroup),
               crec2.activity,
               crec2.billmethod, in_effdate, RATE) = BAD then
              null;
          end if;
        -- get qtys by lotnumber (if necessary) and create invoicedtl
        -- records
         if crec2.billmethod = zbill.BM_LOC_USAGE
         and crec.activity = crec2.activity then
         -- Determine if we are tracking lots or not
             if NVL(ORD.tofacility,'XX') != in_facility then
                 rc := get_renewal_order(CUST, in_facility, ORD, in_userid);
                 rc := zbill.get_invoicehdr('FIND',zbill.IT_STORAGE,
                   CUST.custid, in_facility, 'BILLER', INVH);
             end if;

             if crec.pltcnt > 0 then
             INSERT INTO invoicedtl
             (
                billstatus,
                facility,
                custid,
                orderid,
                shipid,
                activity,
                activitydate,
                billmethod,
                enteredqty,
                entereduom,
                enteredrate,
                enteredamt,
                invoice,
                invtype,
                invdate,
                statusrsn,
                lastuser,
                lastupdate,
                businessevent
              )
              values
              (
                zbill.UNCHARGED,
                in_facility,
                CUST.custid,
                ORD.orderid,
                ORD.shipid,
                RATE.activity,
                in_effdate, --sysdate,
                RATE.billmethod,
                crec.pltcnt,
                'LOC',
                null,                   -- RATE.rate,
                null,                   -- RATE.rate * crec3.qty,
                INVH.invoice,
                INVH.invtype,
                INVH.invdate,
                zbill.SR_RENEW,
                'BILLER',
                sysdate,
                zbill.EV_RENEWAL
              );

             end if;
         end if;
        end loop;

    end loop;

    v_proc_locc_seconds := round((sysdate - v_renewal_end) * 86400,4);
    v_renewal_end := sysdate;

    -- Parent Pallet Renewal Billing
    for crec in C_PRNT_PLTQTY(in_facility, in_custid, in_effdate) loop
      if (crec.item = 'NOCALC') then
        select count(1) into v_count
        from invoicedtl
        where invoice = INVH.invoice and billmethod = zbill.BM_PARENT_BILLING
          and item = 'MIXED' and rategroup = 'NOCALC';
          
        if (v_count = 0) then 
          insert into invoicedtl(
            billstatus, facility, custid, orderid, item, lotnumber, activity, 
            activitydate, billmethod, enteredqty, entereduom, enteredrate,
            enteredweight, invoice, invtype, invdate, statusrsn, 
            shipid, lastuser, lastupdate, businessevent, rategroup
          ) values (
            zbill.UNCHARGED, in_facility, in_custid, ORD.orderid, 'MIXED', null, 0,
            in_effdate, zbill.BM_PARENT_BILLING, 0,'PLTS', 0,
            0, INVH.invoice, INVH.invtype, INVH.invdate, zbill.SR_RENEW,
            ORD.shipid, 'BILLER', sysdate, zbill.EV_RENEWAL, 'NOCALC');
        end if;
        
        goto next_item;
      end if;
      
      -- there could be more than 1 entry for this bill method, for example a different rate for rec methods
      for crec2 in zbill.C_RATE_WHEN(crec.rategroup.custid, crec.rategroup.rategroup, zbill.EV_RENEWAL, in_facility, in_effdate) loop
        if crec2.billmethod in (zbill.BM_PARENT_BILLING) then
          if zbill.rd_rate(rategrouptype(crec2.custid, crec2.rategroup), crec2.activity,
             crec2.billmethod, in_effdate, RATE) = zbill.BAD then
              null;
          end if;
          
          select count(1) into v_count
          from invoicedtl
          where invoice = INVH.invoice and billmethod = zbill.BM_PARENT_BILLING
            and item = crec.item and nvl(lotnumber,'(none)') = nvl(crec.lotnumber,'(none)')
            and activity = RATE.activity;
            
          if (v_count = 0) then
            insert into invoicedtl(
              billstatus, facility, custid, orderid, item, lotnumber, activity, 
              activitydate, billmethod, enteredqty, entereduom, 
              enteredweight, invoice, invtype, invdate, statusrsn, 
              shipid, lastuser, lastupdate, businessevent, rategroup
            ) values (
              zbill.UNCHARGED, in_facility, in_custid, ORD.orderid, crec.item, 
              crec.lotnumber, RATE.activity, 
              in_effdate, zbill.BM_PARENT_BILLING, decode(crec2.automatic,'C',0,crec.pallets),'PLTS',
              0, INVH.invoice, INVH.invtype, INVH.invdate, zbill.SR_RENEW,
              ORD.shipid, 'BILLER', sysdate, zbill.EV_RENEWAL, crec.rategroup.rategroup);
          else 
            update invoicedtl
            set enteredqty = enteredqty + decode(crec2.automatic,'C',0,crec.pallets)
            where invoice = INVH.invoice and billmethod = zbill.BM_PARENT_BILLING
              and item = crec.item and nvl(lotnumber,'(none)') = nvl(crec.lotnumber,'(none)')
              and activity = RATE.activity;
          end if;
        end if;
      end loop;

      << next_item >>
        null;
    end loop;

-- If this is a lot receipt renewal system check it out
    if nvl(lrr, 'N') = 'Y' then
      cnt := 0;

      select count(1)
        into cnt
        from custratewhen
       where  (custid,rategroup) in
              (select decode(nvl(linkyn,'N'),'Y','DEFAULT',custid),
                      decode(nvl(linkyn,'N'),'Y',linkrategroup,rategroup)
                 from custrategroup where custid = in_custid)
         and billmethod in (zbill.BM_QTY_LOT_RCPT,
              zbill.BM_CWT_LOT_RCPT,zbill.BM_WT_LOT_RCPT);

      if cnt > 0 then
    -- Determine last renewal
        lastrenewal := null;
        if CUST.rnewbillfreq in ('M','E') then
            tdate := add_months(in_effdate, -2);

            loop

            if zbill.get_nextbilldate(CUST.custid, tdate,
                    CUST.rnewbillfreq, CUST.rnewbillday,
                    zbill.BT_RENEWAL,
                    tdate) = zbill.BAD
            then
                tdate := in_effdate;
            end if;
            if tdate < in_effdate then
                lastrenewal := tdate;
            end if;
            if trunc(in_effdate) <= tdate then exit; end if;

            end loop;

        else
          select max(billdate)
            into lastrenewal
            from custbillschedule
           where custid = in_custid
             and type = decode(CUST.rnewbillfreq,
                                'C',zbill.BT_RENEWAL,
                                'F', zbill.BT_DEFAULT,
                                null)
             and billdate < in_effdate;
        end if;

    -- If we were successful then do the calc
        if lastrenewal is not null then
    -- Find all the item,lots that were active during the period
          for crec in (select item, lotnumber
                         from asofinventory
                        where effdate > lastrenewal
                          and effdate < in_effdate
                          and facility = in_facility
                          and custid = in_custid
                       union
                        select item, lotnumber
                          from asofinventory A1
                         where facility = in_facility
                          and custid = in_custid
                          and effdate = (select max(effdate)
                                from asofinventory A2
                               where A2.facility = A1.facility
                                 and A2.custid = A1.custid
                                 and A2.item = A1.item
                                 and nvl(A2.lotnumber,'(none)') = nvl(A1.lotnumber,'(none)')
                                 and effdate <= lastrenewal))
          loop

    -- Read the rate for the item
            zbill.rd_item_rategroup(in_custid, crec.item, item_rategroup);

    -- Need to do this for both ANVR (anniversary billing) and
    --      ANVD (anniversary by days)
           for CBE in (select zbill.EV_ANVD BE from dual
                        UNION
                       select zbill.EV_ANVR BE from dual)
           loop

    -- Find an entry for the business event
            for crec2 in zbill.C_RATE_WHEN(CUST.custid, item_rategroup,
                           cbe.BE, in_facility, in_effdate)
            loop

    --   Get the rategroup renewal activity charge row
              if zbill.rd_rate(rategrouptype(crec2.custid, crec2.rategroup),
                   crec2.activity,
                   crec2.billmethod, in_effdate, RATE) = BAD then
                  null;
              end if;

    -- Verify this is for lot rate receipt renewals
              if RATE.billmethod not in (zbill.BM_QTY_LOT_RCPT,
                zbill.BM_WT_LOT_RCPT,zbill.BM_CWT_LOT_RCPT) then
                    goto continue_lrr;
              end if;

    -- Now read the bill rate information for the item
              BLR := null;
              OPEN C_BLR(in_facility, in_custid, crec.item, crec.lotnumber);
              FETCH C_BLR into BLR;
              CLOSE C_BLR;
              if BLR.receiptdate is null then
                BLR.receiptdate := trunc(sysdate);
              end if;
              tdate := nvl(BLR.receiptdate, trunc(sysdate));
              cnt := 0;

    -- Loop thru trying to determine the dates for renewal
              loop
                cnt := cnt + 1;
                if crec2.businessevent = 'ANVD' then
                    tdate := BLR.receiptdate + cnt * RATE.annvdays;
                else
                    tdate := add_months(BLR.receiptdate, cnt);
                end if;
                if tdate > in_effdate then
                    exit;
                end if;
                if tdate > lastrenewal then
                    -- read asof for this date and item
                   for crec3 in C_ASOF_ITEM_QTY(in_custid, in_facility,
                        crec.item, crec.lotnumber, tdate) loop

                     if NVL(ORD.tofacility,'XX') != in_facility then
                         rc := get_renewal_order(CUST, in_facility, ORD,
                                in_userid);
                         rc := zbill.get_invoicehdr('FIND',zbill.IT_STORAGE,
                           CUST.custid, in_facility, 'BILLER', INVH);
                     end if;

                     if crec3.qty > 0 then
                         INSERT INTO invoicedtl
                         (
                            billstatus,
                            facility,
                            custid,
                            orderid,
                            shipid,
                            item,
                            lotnumber,
                            activity,
                            activitydate,
                            billmethod,
                            enteredqty,
                            entereduom,
                            enteredrate,
                            enteredamt,
                            enteredweight,
                            invoice,
                            invtype,
                            invdate,
                            statusrsn,
                            lastuser,
                            lastupdate,
                            businessevent
                          )
                          values
                          (
                            zbill.UNCHARGED,
                            in_facility,
                            CUST.custid,
                            ORD.orderid,
                            ORD.shipid,
                            crec.item,
                            crec.lotnumber,
                            RATE.activity,
                            tdate,
                            RATE.billmethod,
                            crec3.qty,
                            crec3.uom,
                            null,                   -- RATE.rate,
                            null,                   -- RATE.rate * crec3.qty,
                            crec3.weight,
                            INVH.invoice,
                            INVH.invtype,
                            INVH.invdate,
                            zbill.SR_RENEW,
                            'BILLER',
                            sysdate,
                            cbe.BE
                          );

                     end if;

                   end loop; -- crec3
                end if;
              end loop; -- tdate processing
        <<continue_lrr>>
              null;
            end loop; -- crec2
           end loop; --  CBE


          end loop; -- crec
        end if; -- lastrenewal no null
      end if;
    end if;

    v_proc_lrr_seconds := round((sysdate - v_renewal_end) * 86400,4);
    v_renewal_end := sysdate;

-- Do finish up processing for all renewal storage orders
    v_proc_ordloop_rows := 0;
    for crec in C_ORDERS(in_facility, CUST.custid) loop
        ORD := crec;

-- Get invoice header for this order
        rc := zbill.get_invoicehdr('FIND',zbill.IT_STORAGE,
                 CUST.custid, ORD.tofacility, 'BILLER', INVH);

-- Create the customer level renewal items
        rc := zbill.calc_automatic_charges(CUST.custid, CUST.rategroup,
               zbill.EV_RENEWAL, ORD, INVH, in_effdate);

-- Calculate the existing uncalculated line items.
        for crec in C_INVV(INVH.invoice) loop
            out_errmsg := '';
            v_proc_ordloop_rows := v_proc_ordloop_rows + 1;
            if zbill.calculate_detail_rate(crec.rowid,
                trunc(crec.activitydate), out_errmsg) = BAD then
                null;
            end if;
        end loop;

-- Calculate the renewal storage minimums
        rc := calc_renewal_minimums(INVH, ORD.orderid, CUST.custid,
            in_userid,  in_effdate, out_errmsg);

-- Update the order status that we are done ???

    end loop;

    v_proc_ordloop_seconds := round((sysdate - v_renewal_end) * 86400,4);
    v_renewal_end := sysdate;

-- Get invoice header for this order
    rc := zbill.get_invoicehdr('FIND',zbill.IT_STORAGE,
                 CUST.custid, ORD.tofacility, 'BILLER', INVH);

    rc := zbill.calc_automatic_charges(CUST.custid, CUST.rategroup,
      zbill.EV_BILLING, ORD, INVH, in_effdate);

-- Calculate the existing uncalculated line items.
        for crec in C_INVV(INVH.invoice) loop
            out_errmsg := '';
            if zbill.calculate_detail_rate(crec.rowid,
                trunc(crec.activitydate), out_errmsg) = BAD then
                null;
            end if;
        end loop;

    v_proc_bac_seconds := round((sysdate - v_renewal_end) * 86400,4);
    v_renewal_end := sysdate;

-- Keep track of the asof date for this renewal and the date we expect the
--  next renewal for this customer
    if zbill.get_nextbilldate(CUST.custid, in_effdate,
                       CUST.rnewbillfreq,
                       CUST.rnewbillday,
                       zbill.BT_RENEWAL,
                       nextrenewal) = zbill.BAD then
      nextrenewal := trunc(sysdate);
      nextrenewal := add_months(in_effdate,1);
    end if;

    update invoicehdr
       set renewfromdate = in_effdate,
           renewtodate = nextrenewal
     where invoice = INVH.invoice;

-- Update/Add custlastrenewal for this facility
    UPDATE custlastrenewal
       SET lastrenewal = in_effdate,
           lastuser = 'BILLER',
           lastupdate = sysdate
     WHERE custid = in_custid
       AND facility = in_facility;

    if SQL%NOTFOUND then
        INSERT INTO custlastrenewal(
            custid,
            facility,
            lastrenewal,
            lastuser,
            lastupdate
        )
        VALUES (
            in_custid,
            in_facility,
            in_effdate,
            'BILLER',
            sysdate
        );
    end if;


-- Calc surcharges if any
    rc := zbsc.calc_surcharges(INVH, zbill.EV_RENEWAL ,
         null,null,in_userid,in_effdate, out_errmsg);

-- Now calculate account minimums
    rc := calc_account_minimums(ORD,CUST,INVH,in_effdate, out_errmsg);

-- Check if we have done all facilities for this renewal date
    rc := 0;
    for crec in C_TODO(in_custid) loop
        rc := rc + 1;
        -- DbMsg(' Still need to do '||crec.facility||'/'||crec.custid);
    end loop;

-- Note Only Do this if all facilities billed for the account
    if rc = 0 then
    -- Now with all facilities billed update the last renewal date
      -- Can't do until we have actually done the invoice
      --  UPDATE customer
      --     SET rnewlastbilled = in_effdate
      --   WHERE custid = in_custid;
        null;
    end if;

--
    update orderhdr
       set statusupdate = sysdate
     where orderid = ORD.orderid
       and shipid = ORD.shipid;

    if CUST.rnewautobill = 'Y' then
       zbill.approve_invoice(INVH.invoice, zbill.NOT_REVIEWED,
           in_userid, n1, n2, n3, terrmsg);
    end if;

    v_proc_end_seconds := round((sysdate - v_renewal_end) * 86400,4);
    v_proc_tot_seconds := round((sysdate - v_renewal_start) * 86400,4);
    v_renewal_end := sysdate;
    
    UPDATE custlastrenewal
       SET renewal_start = v_renewal_start,
           renewal_end = v_renewal_end,
           proc_beg_seconds = v_proc_beg_seconds,
           proc_asof_seconds = v_proc_asof_seconds,
           proc_pltc_seconds = v_proc_pltc_seconds,
           proc_locc_seconds = v_proc_locc_seconds,
           proc_lrr_seconds = v_proc_lrr_seconds,
           proc_ordloop_seconds = v_proc_ordloop_seconds,
           proc_ordloop_rows = v_proc_ordloop_rows,
           proc_bac_seconds = v_proc_bac_seconds,
           proc_end_seconds = v_proc_end_seconds,
           proc_tot_seconds = v_proc_tot_seconds
     WHERE custid = in_custid
       AND facility = in_facility;

    return zbill.GOOD;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CCustRenw: '||substr(sqlerrm,1,80);
    rollback;
    return zbill.BAD;
END calc_customer_renewal;


----------------------------------------------------------------------
--
-- recalc_renewal -
--
----------------------------------------------------------------------
FUNCTION recalc_renewal
(

    in_invoice  IN      number,
    in_loadno   IN      number,   -- really a dummy field
    in_custid   IN      varchar2,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer
IS


  INVH invoicehdr%rowtype;
  rc integer;

BEGIN

    out_errmsg := 'OKAY';

-- Get renewal invoicehdr
   INVH := null;
   OPEN zbill.C_INVH(in_invoice);
   FETCH zbill.C_INVH into INVH;
   CLOSE zbill.C_INVH;

-- Verify for proper
   if INVH.invoice is null then
      out_errmsg := 'Invalid billing reference does not exist.';
      return zbill.BAD;
   end if;

   if INVH.invtype != 'S' then
      out_errmsg := 'Not a renewal invoice.';
      return zbill.BAD;
   end if;

   if INVH.custid != in_custid then
      out_errmsg := 'Billing reference not for customer.';
      return zbill.BAD;
   end if;

   if INVH.renewfromdate is null then
      out_errmsg := 'Cannot determine renewal date.';
      return zbill.BAD;
   end if;

   if INVH.invstatus = zbill.BILLED then
     out_errmsg := 'Invalid Invoice. Already billed.';
     return zbill.BAD;
   end if;

-- Clean up old data
   delete from invoicedtl
    where invoice = in_invoice
      and (statusrsn = zbill.SR_RENEW or minimum is not null);

   UPDATE invoicedtl
      SET billstatus = zbill.UNCHARGED
    WHERE invoice = in_invoice
      AND billstatus not in  (zbill.DELETED, zbill.BILLED);

   update invoicehdr
      set invstatus = zbill.NOT_REVIEWED
    where invoice = in_invoice;
	  
-- Call routine to calculate data
   rc := calc_customer_renewal(
         in_custid,
         INVH.facility,
         INVH.renewfromdate,
         'Y',
         in_userid,
         out_errmsg);

    return rc;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'RecalcRenw: '||substr(sqlerrm,1,80);
    rollback;
    return zbill.BAD;
END recalc_renewal;

----------------------------------------------------------------------
--
-- count_pallets
--
----------------------------------------------------------------------
PROCEDURE count_pallets
(
    in_facility     IN      varchar2,
    in_custid       IN      varchar2,
    in_effdate      IN      date,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
)
IS

CURSOR C_PAS(in_facility varchar2, in_custid varchar2)
IS
 SELECT facility, custid, item, lotnumber, unitofmeasure uom,
              count(1) pltcnt, sum(quantity) qty
   FROM plate
  WHERE facility = in_facility
    AND custid = in_custid
    AND type = 'PA'
    AND parentlpid is null
    AND status != 'P'
   group by facility, custid, item, lotnumber, unitofmeasure;

CURSOR C_MPS(in_facility varchar2, in_custid varchar2)
RETURN C_PAS%rowtype
IS
 SELECT facility, custid, item, lotnumber, unitofmeasure uom,
              count(distinct parentlpid) pltcnt, sum(quantity) qty
   FROM plate
  WHERE facility = in_facility
    AND custid = in_custid
    AND type = 'PA'
    AND parentlpid is not null
    AND status != 'P'
   group by facility, custid, item, lotnumber, unitofmeasure;

CURSOR C_SPS(in_facility varchar2, in_custid varchar2)
RETURN C_PAS%rowtype
IS
 SELECT SP.facility, SP.custid, SP.item, SP.lotnumber, SP.unitofmeasure uom,
              count(distinct decode(P.lpid, null,
                         nvl(SP.fromlpidparent, SP.fromlpid),
                         null)) pltcnt,
              sum(SP.quantity) qty
   FROM plate P, shippingplate SP
  WHERE SP.facility = in_facility
    AND SP.custid = in_custid
    AND SP.type in ('F','P')
    AND nvl(SP.fromlpidparent, SP.fromlpid) = P.lpid(+)
    AND 'P' != P.status(+)
    AND SP.status in ('S','P','L','FA')
    -- AND P.lpid is null
   group by SP.facility, SP.custid, SP.item, SP.lotnumber, SP.unitofmeasure;

CURSOR C_LOCS(in_facility varchar2, in_custid varchar2)
RETURN C_PAS%rowtype
IS
 SELECT in_facility, in_custid, 'location', L.loctype, 'LOC' uom,
              count(distinct P.location) pltcnt,
              sum(P.quantity) qty
   FROM location L,
     (select lpid, location, unitofmeasure, quantity from plate
       where facility = in_facility and custid = in_custid and type = 'PA'
         and status != 'P'
             union
      select lpid, location, unitofmeasure, quantity from shippingplate
       where facility = in_facility and custid = in_custid
         and type in ('F','P')
         and status in ('S','P','L','FA')) P
  WHERE L.facility = in_facility
    AND L.locid = P.location
   group by in_facility, in_custid, 'location', L.loctype, 'LOC';

CURSOR C_PLCB_RATES(in_custid varchar2, in_effdate date)
IS
    SELECT CR.*
      FROM custrategroup G, custrate CR
     WHERE CR.custid = G.custid
       AND CR.rategroup = G.rategroup
       AND CR.custid = in_custid and G.status = 'ACTV'
       AND CR.billmethod = zbill.BM_PLT_CNT_BRK
       AND CR.effdate  =
           (SELECT max(effdate)
              FROM custrate
             WHERE custid = CR.custid
               AND rategroup = CR.rategroup
               AND activity = CR.activity
               AND billmethod = CR.billmethod
               AND effdate <= trunc(in_effdate));
               
CURSOR C_QTY_BREAKS(RT custrate%rowtype, in_qty number)
IS
  SELECT *
    FROM custratebreak
   WHERE custid = RT.custid
     AND rategroup = RT.rategroup
     AND effdate = RT.effdate
     AND activity = RT.activity
     AND billmethod = RT.billmethod
     AND in_qty >= quantity
   ORDER BY quantity desc;
CRB custratebreak%rowtype;

v_total_pallets number := null;
v_current_rate  number(12,6);

PROCEDURE add_counts(PLT C_PAS%rowtype, in_effdate date, in_user varchar2)
IS

BEGIN
    out_errmsg := 'OKAY';

    begin
        INSERT INTO billpalletcnt
          (
            facility,
            custid,
            effdate,
            item,
            uom,
            lotnumber,
            pltqty,
            uomqty,
            lastuser,
            lastupdate
          )
        VALUES
          (
            PLT.facility,
            PLT.custid,
            in_effdate,
            PLT.item,
            PLT.uom,
            PLT.lotnumber,
            PLT.pltcnt,
            PLT.qty,
            in_user,
            sysdate
          );
     EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
           UPDATE BILLPALLETCNT
              SET pltqty = pltqty + PLT.pltcnt,
                  uomqty = uomqty + PLT.qty
            WHERE facility = PLT.facility
              AND custid = PLT.custid
              AND item = PLT.item
              AND effdate = in_effdate
              AND nvl(lotnumber,'(none)') = nvl(PLT.lotnumber,'(none)');
        WHEN OTHERS THEN
            -- DbMsg('ADD:'||sqlerrm);
            null;
     end;

END;


BEGIN
    out_errmsg := 'OKAY';

    for crec in C_PAS(in_facility, in_custid) loop
        -- DbMsg('PA Item:'||crec.item||' UOM:'||crec.uom
        --          ||' Lot:'||crec.lotnumber);
        -- DbMsg('     Count:'||crec.pltcnt ||' Qty:' || crec.qty);
        add_counts(crec, in_effdate, in_user);
    end loop;

    for crec in C_MPS(in_facility, in_custid) loop
        -- DbMsg('MP Item:'||crec.item||' UOM:'||crec.uom
        --            ||' Lot:'||crec.lotnumber);
        -- DbMsg('     Count:'||crec.pltcnt ||' Qty:' || crec.qty);
        add_counts(crec, in_effdate, in_user);
    end loop;

    for crec in C_SPS(in_facility, in_custid) loop
        -- DbMsg('SP Item:'||crec.item||' UOM:'||crec.uom
        --            ||' Lot:'||crec.lotnumber);
        -- DbMsg('     Count:'||crec.pltcnt ||' Qty:' || crec.qty);
        add_counts(crec, in_effdate, in_user);
    end loop;

    for crec in C_LOCS(in_facility, in_custid) loop
        -- DbMsg('SP Item:'||crec.item||' UOM:'||crec.uom
        --            ||' Lot:'||crec.lotnumber);
        -- DbMsg('     Count:'||crec.pltcnt ||' Qty:' || crec.qty);
        add_counts(crec, in_effdate, in_user);
    end loop;


    for crec in C_PLCB_RATES(in_custid, in_effdate) loop
    
      if (v_total_pallets is null) then
        select nvl(sum(pltqty),0) into v_total_pallets
        from billpalletcnt 
        where facility = in_facility 
          and custid = in_custid
          and item != 'location'
          and effdate = in_effdate;
      end if;

      CRB := NULL;
      OPEN C_QTY_BREAKS(crec, v_total_pallets);
      FETCH C_QTY_BREAKS into CRB;
      CLOSE C_QTY_BREAKS;
      
      insert into custrate_storage_lkup (custid, facility, rategroup, activity, effdate, rate, total_pallets)
      values (in_custid, in_facility, crec.rategroup, crec.activity, in_effdate, nvl(CRB.rate,crec.rate), v_total_pallets);
    end loop;

EXCEPTION when others then
    out_errmsg := sqlerrm;
END count_pallets;

----------------------------------------------------------------------
--
-- count_parent_pallets
--
----------------------------------------------------------------------
PROCEDURE count_parent_pallets
(
    in_facility     IN      varchar2,
    in_custid       IN      varchar2,
    in_effdate      IN      date,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
)
as
  cursor c_plate(in_facility varchar2, in_custid varchar2)
  is
  select facility, custid, lpid, parentlpid, item
  from plate
  where facility = in_facility and custid = in_custid
    and type in ('PA','MP','TO') and status != 'P' and quantity > 0;
    
  /*
  cursor c_shipplate(in_facility varchar2, in_custid varchar2)
  is
  select a.facility, a.custid, a.fromlpid as lpid, b.parentlpid, a.item
  from shippingplate a, plate b
  where a.facility = in_facility and a.custid = in_custid
    and a.type in ('F','P') and nvl(a.fromlpidparent, a.fromlpid) = b.lpid(+)
    and a.status in ('S','P','L','FA') and a.quantity > 0;
  */
    
begin

  insert into billparentpltcnt (facility, custid, effdate, lpid, parentlpid, item, lotnumber,lastuser, lastupdate)
  select facility, custid, in_effdate, lpid, parentlpid, item, lotnumber, in_user, sysdate
  from plate
  where facility = in_facility and custid = in_custid
    and type = 'PA' and quantity > 0;
    
exception when others then
    out_errmsg := sqlerrm;
end count_parent_pallets;

----------------------------------------------------------------------
--
-- count_pallets_today
--
----------------------------------------------------------------------
PROCEDURE count_pallets_today
(
    in_effdate      IN      date,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
)
IS

CURSOR C_CBD(in_renew date)
IS
  select *
    from custbilldates
   where trunc(nextrenewal) = in_renew;

CURSOR C_CBD_CHK(in_renew date)
IS
  select *
    from custbilldates
   where trunc(nextrenewal) < in_renew;

CURSOR C_FACILITIES(in_custid varchar2)
IS
  select distinct facility
    from custitemtot
   where custid = in_custid;

renew_date date;
CUST customer%rowtype;
nextrenewal date;
l_cnt integer;

BEGIN
    out_errmsg := 'OKAY';

-- Find facilities and customers ready to renew today!!!
-- have to do for customers renew yesterday
   renew_date := trunc(in_effdate) -1;


-- Check for rerun of the process
    if not zbs.check_daily_billing(in_effdate) then
        out_errmsg := 'Check daily billing failed for Count pallets dt:'
               || to_char(in_effdate,'YYYYMMDD');
        return;
    end if;


   for crec in C_CBD(renew_date) loop
       -- DbMsg('Found customer:'||crec.custid);
       for crec2 in C_FACILITIES(crec.custid) loop
           -- DbMsg('   In Fac:'||crec2.facility);
           count_pallets(crec2.facility, crec.custid,
                 renew_date, in_user, out_errmsg);
           count_parent_pallets(crec2.facility, crec.custid, 
              renew_date, in_user, out_errmsg);
       end loop;
   end loop;

   for crec in C_CBD_CHK(renew_date) loop
       -- Check if this is a future renewal date
       nextrenewal := crec.nextrenewal;
       if zbill.rd_customer(crec.custid, CUST) = BAD then
         nextrenewal := null;
       end if;

       l_cnt := 0;

       while (nextrenewal is not null and nextrenewal < renew_date) loop
           l_cnt := l_cnt + 1;
           exit when l_cnt > 20;
           if zbill.get_nextbilldate(CUST.custid, nextrenewal,
                         CUST.rnewbillfreq,
                         CUST.rnewbillday,
                         zbill.BT_RENEWAL,
                         nextrenewal) = zbill.BAD then
                nextrenewal := null;
           end if;
       end loop;

       --DbMsg('Check Custid:'||crec.custid
       --      ||' CBD:'||crec.nextrenewal
       --      ||' CNR:'||nextrenewal );
       if nextrenewal = renew_date then
         --DbMsg('Found customer:'||crec.custid);
         for crec2 in C_FACILITIES(crec.custid) loop
           --DbMsg('   In Fac:'||crec2.facility);
           count_pallets(crec2.facility, crec.custid,
                 renew_date, in_user, out_errmsg);
           count_parent_pallets(crec2.facility, crec.custid,
                 renew_date, in_user, out_errmsg);
         end loop;
       end if;
   end loop;

EXCEPTION when others then
    out_errmsg := sqlerrm;
END count_pallets_today;


----------------------------------------------------------------------
--
-- calc_receipt_anniversary_days
--
----------------------------------------------------------------------
PROCEDURE calc_receipt_anniversary_days
(
    in_loadno       IN      number,
    in_custid       IN      varchar2,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
)
IS

cnt integer;

CURSOR C_LOAD(in_loadno number)
IS
    SELECT *
      FROM loads
     WHERE loadno = in_loadno;

LD loads%rowtype;


CURSOR C_ANVD(in_custid varchar2, in_item varchar2)
IS
  SELECT CI.custid, CI.item, CR.custid cr_custid, CR.rategroup,
         CR.effdate, CR.activity, CR.billmethod, CR.uom,
         CR.rate, CR.gracedays, CR.annvdays, CR.anvdate_grace,
         CR.cxd_grace, CR.cxd_grace_days, CR.cxd_anvdate_grace
    FROM custitem CI, custratewhen CRW, custrate CR
   WHERE CI.custid = in_custid
     AND CI.item = in_item
     AND CRW.businessevent = zbill.EV_ANVD
     AND CRW.automatic in ('A','C')
     AND CRW.custid
        = zbut.item_rategroup(CI.custid, CI.item).custid
     AND CRW.rategroup
        = zbut.item_rategroup(CI.custid, CI.item).rategroup
     AND CRW.effdate =
           (SELECT max(effdate)
              FROM custrate
             WHERE custid = CRW.custid
               AND rategroup = CRW.rategroup
               AND activity = CRW.activity
               AND billmethod = CRW.billmethod
               AND effdate <= trunc(sysdate))
    AND CR.custid = CRW.custid
    AND CR.rategroup = CRW.rategroup
    AND CR.effdate = CRW.effdate
    AND CR.activity = CRW.activity
    AND CR.billmethod = CRW.billmethod
    AND CR.billmethod not in (zbill.BM_QTY_LOT_RCPT,
                zbill.BM_WT_LOT_RCPT,zbill.BM_CWT_LOT_RCPT);

ANVD C_ANVD%rowtype;

RATE custrate%rowtype;
ORD orderhdr%rowtype;
CUST customer%rowtype;

checkdt date;
l_rowid varchar2(20);
rc integer;

l_gracedays integer;
l_graceoff integer;

v_prod_orderid number := ceil(in_loadno/100)*-1;
v_prod_shipid number := mod(in_loadno,100)*-1;

BEGIN
    out_errmsg := 'OKAY';

    LD := null;
    OPEN C_LOAD(in_loadno);
    FETCH C_LOAD into LD;
    CLOSE C_LOAD;

    if (in_loadno < 0) then
      begin
        select statusupdate into LD.rcvddate
        from orderhdr
        where orderid = v_prod_orderid and shipid = v_prod_orderid and orderstatus = 'R';
      exception
        when others then
          null;
      end;
    end if;

-- Get the customer information for this receipt order
    if zbill.rd_customer(in_custid, CUST) = BAD then
       out_errmsg := 'Invalid custid = '|| in_custid;
       -- DbMsg(out_errmsg);
       return;
    end if;


-- Check if customer has any anniversary day billing
    cnt := 0;

--    select count(1)
--      into cnt
--     from custratewhen
--    where businessevent = ZBILL.EV_ANVD;

    select count(1)
      into cnt
      from custratewhen W, custrategroup G
     where G.custid = in_custid
       and  W.custid = decode(nvl(G.linkyn,'N'),'Y','DEFAULT',G.custid)
       and W.rategroup =
            decode(nvl(G.linkyn,'N'),'Y',G.linkrategroup,G.rategroup)
       and W.businessevent = 'ANVD';



    if nvl(cnt,0) = 0 then
        return;
    end if;

-- for items in receipt

    for cit in (select OD.facility, OD.item, OD.lotnumber, OD.uom,
                        sum(OD.qtyrcvd) quantity, sum(OD.weight) weight,
                        count(distinct nvl(OD.parentlpid, OD.lpid)) pltcnt,
                        OH.ordertype
                  from orderdtlrcpt OD, orderhdr OH
                 where OH.loadno = in_loadno
                   and OH.custid = in_custid
                   and OD.orderid = OH.orderid
                   and OD.shipid = OH.shipid
                 group by OD.facility, OD.item, OD.lotnumber, OD.uom,
                          OH.ordertype)
    loop
        -- DbMsg('Item:'||cit.item||'/'||cit.lotnumber
        --        ||' Q/W '||cit.quantity||'/'||cit.weight);
-- Check if there is active ANVD billing for this item
        ANVD := null;
        OPEN C_ANVD(in_custid, cit.item);
        FETCH C_ANVD into ANVD;
        CLOSE C_ANVD;

        if ANVD.item is null then
            goto continue;
        end if;
        
        if nvl(ANVD.annvdays,0) <= 0 then
          out_errmsg := 'Anniversary days has to be >= 0 if using ANVD billing';
          return;
        end if;

        if nvl(ANVD.anvdate_grace,'N') = 'Y' then
            l_gracedays := nvl(ANVD.gracedays,0);
            l_graceoff := nvl(ANVD.gracedays,0);
        else
            l_gracedays := nvl(ANVD.gracedays,0);
            l_graceoff := 0;
        end if;

        if (nvl(ANVD.cxd_grace,'N') = 'Y')
         and (cit.ordertype = 'C')
        then
          if (nvl(ANVD.cxd_anvdate_grace,'N') = 'Y') then
            l_gracedays := nvl(ANVD.cxd_grace_days,0);
            l_graceoff := nvl(ANVD.cxd_grace_days,0);
          else
            l_gracedays := nvl(ANVD.cxd_grace_days,0);
            l_graceoff := 0;
          end if;
        end if;

-- OK we have a winner
        -- DbMsg('.. Have a winner:'||ANVD.rategroup||' '||ANVD.annvdays
        --    ||' days.');

        checkdt := trunc(LD.rcvddate) + l_graceoff;
        -- DbMsg('Starting date :'||to_char(checkdt,'YYYYMMDDHH24MISS'));

        loop
            checkdt := checkdt + ANVD.annvdays;
            exit when (nvl(checkdt,sysdate+3) > trunc(sysdate));


            if (checkdt < trunc(LD.rcvddate) + l_gracedays) then
                goto annvd_continue;
            end if;

            -- DbMsg('Checking date :'||to_char(checkdt,'YYYYMMDDHH24MISS'));

      -- Check Order for this facility
            if NVL(ORD.tofacility,'XX') != cit.facility then
               rc := get_renewal_order(CUST, cit.facility, ORD, 'DAILY');
            end if;
            -- DbMsg('......Have totals:'||cit.quantity||' WT:'||cit.weight);
            if zbill.rd_rate(rategrouptype(ANVD.cr_custid, ANVD.rategroup),
                 ANVD.activity,
                 ANVD.billmethod, checkdt, RATE) = BAD then
                goto annvd_continue;
            end if;

            if RATE.rate > 0 then
                -- Try to read the corresponding entry
                l_rowid := null;
                begin
                select rowid
                  into l_rowid
                  from invoicedtl
                 where orderid = ORD.orderid
                   and shipid = ORD.shipid
                   and item = cit.item
                   and nvl(lotnumber,'(none)') = nvl(cit.lotnumber,'(none)')
                   and invoice = 0
                   and invtype = zbill.IT_STORAGE
                   and activity = RATE.activity
                   and billmethod = RATE.billmethod
                   and statusrsn = zbill.SR_ANVD
                   and trunc(activitydate) = checkdt;
                exception when others then
                    l_rowid := null;
                end;
                if l_rowid is not null then
                    update invoicedtl
                       set enteredqty = enteredqty + cit.quantity,
                           enteredweight = enteredweight + cit.weight,
                           billstatus = zbill.uncharged,
                           calcedamt = null
                     where rowid = l_rowid;
                else

              INSERT INTO invoicedtl
               (
                  billstatus,
                  facility,
                    custid,
                    invtype,
                    invdate,
                    item,
                    lotnumber,
                    orderid,
                    shipid,
                    activity,
                    activitydate,
                    billmethod,
                    enteredqty,
                    entereduom,
                    enteredweight,
                    calcedqty,
                    calceduom,
                    statusrsn,
                    lastuser,
                    lastupdate,
                    businessevent
                 )
                 values
                 (
                    zbill.UNCHARGED,
                    CIT.facility,
                    IN_custid,
                    zbill.IT_STORAGE,
                    sysdate,
                    CIT.item,
                    CIT.lotnumber,
                    ORD.orderid,
                    ORD.shipid,
                    RATE.activity,
                    checkdt,
                    RATE.billmethod,
                    CIT.quantity,
                    CIT.uom,
                    CIT.weight,
                    CIT.pltcnt,
                    '*PLT',
                    zbill.SR_ANVD,
                    'BILLER',
                    sysdate,
                    zbill.EV_ANVD
                 );
                end if;
            end if;

<<annvd_continue>>
            null;

        end loop;


<<continue>>
        null;
    end loop;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CRAD:'||sqlerrm;
END calc_receipt_anniversary_days;




----------------------------------------------------------------------
--
-- adjust_agginv_ship_renewal
--
----------------------------------------------------------------------
PROCEDURE adjust_agginv_ship_renewal
(
    in_loadno       IN      number,
    in_shipdate     IN      date,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
)
IS

cnt integer;

CURSOR C_LOAD(in_loadno number)
IS
    SELECT *
      FROM loads
     WHERE loadno = in_loadno;

LD loads%rowtype;


CURSOR C_ANVD(in_custid varchar2, in_item varchar2)
IS
  SELECT CI.custid, CI.item, CR.custid cr_custid, CR.rategroup,
         CR.effdate, CR.activity, CR.billmethod, CR.uom,
         CR.rate, CR.gracedays, CR.annvdays, CR.anvdate_grace,
         CR.cxd_grace, CR.cxd_grace_days, CR.cxd_anvdate_grace
    FROM custitem CI, custratewhen CRW, custrate CR
   WHERE CI.custid = in_custid
     AND CI.item = in_item
     AND CRW.businessevent = zbill.EV_ANVD
     AND CRW.automatic in ('A','C')
     AND CRW.custid
        = zbut.item_rategroup(CI.custid, CI.item).custid
     AND CRW.rategroup
        = zbut.item_rategroup(CI.custid, CI.item).rategroup
     AND CRW.effdate =
           (SELECT max(effdate)
              FROM custrate
             WHERE custid = CRW.custid
               AND rategroup = CRW.rategroup
               AND activity = CRW.activity
               AND billmethod = CRW.billmethod
               AND effdate <= trunc(sysdate))
    AND CR.custid = CRW.custid
    AND CR.rategroup = CRW.rategroup
    AND CR.effdate = CRW.effdate
    AND CR.activity = CRW.activity
    AND CR.billmethod = CRW.billmethod
    AND CR.billmethod not in (zbill.BM_QTY_LOT_RCPT,
                zbill.BM_WT_LOT_RCPT,zbill.BM_CWT_LOT_RCPT);

ANVD C_ANVD%rowtype;

CURSOR C_ANVR(in_custid varchar2, in_item varchar2)
IS
  SELECT CI.custid, CI.item, CR.custid cr_custid, CR.rategroup,
         CR.effdate, CR.activity, CR.billmethod, CR.uom,
         CR.rate, CR.gracedays, CR.annvdays, CR.anvdate_grace,
         CR.cxd_grace, CR.cxd_grace_days, CR.cxd_anvdate_grace
    FROM custitem CI, custratewhen CRW, custrate CR
   WHERE CI.custid = in_custid
     AND CI.item = in_item
     AND CRW.businessevent = zbill.EV_ANVR
     AND CRW.automatic in ('A','C')
     AND CRW.custid
        = zbut.item_rategroup(CI.custid, CI.item).custid
     AND CRW.rategroup
        = zbut.item_rategroup(CI.custid, CI.item).rategroup
     AND CRW.effdate =
           (SELECT max(effdate)
              FROM custrate
             WHERE custid = CRW.custid
               AND rategroup = CRW.rategroup
               AND activity = CRW.activity
               AND billmethod = CRW.billmethod
               AND effdate <= trunc(sysdate))
    AND CR.custid = CRW.custid
    AND CR.rategroup = CRW.rategroup
    AND CR.effdate = CRW.effdate
    AND CR.activity = CRW.activity
    AND CR.billmethod = CRW.billmethod
    AND CR.billmethod not in (zbill.BM_QTY_LOT_RCPT,
                zbill.BM_WT_LOT_RCPT,zbill.BM_CWT_LOT_RCPT);

ANVR C_ANVR%rowtype;

RATE custrate%rowtype;
ORD orderhdr%rowtype;
CUST customer%rowtype;

annvdt  date;
checkdt date;
ixdt integer;
l_rowid varchar2(20);
rc integer;
errmsg varchar2(200);

l_gracedays integer;
l_graceoff integer;
l_ordertype orderhdr.ordertype%type;

PROCEDURE do_anvd(IN_ORD IN orderhdr%rowtype)
IS
BEGIN
-- for shipping plates in shipment

    for cit in (select SP.fromlpid, SP.facility,
                       SP.item, SP.lotnumber, SP.unitofmeasure,
                        sum(SP.quantity) quantity, sum(SP.weight) weight
                  from shippingplate SP
                 where SP.orderid = IN_ORD.orderid
                   and SP.shipid = IN_ORD.shipid
                 group by SP.fromlpid, SP.facility, SP.item,
                       SP.lotnumber, SP.unitofmeasure)
    loop
         DbMsg('LPID:'||cit.fromlpid||' Item:'||cit.item||'/'||cit.lotnumber
                ||' Q/W '||cit.quantity||'/'||cit.weight);

        if cit.fromlpid is null then
            goto continue;

        end if;

-- Check if there is active ANVD billing for this item
        ANVD := null;
        OPEN C_ANVD(CUST.custid, cit.item);
        FETCH C_ANVD into ANVD;
        CLOSE C_ANVD;

        if ANVD.item is null then
            goto continue;
        end if;

        if nvl(ANVD.anvdate_grace,'N') = 'Y' then
            l_gracedays := nvl(ANVD.gracedays,0);
            l_graceoff := nvl(ANVD.gracedays,0);
        else
            l_gracedays := nvl(ANVD.gracedays,0);
            l_graceoff := 0;
        end if;

-- OK we have a winner
         DbMsg('.. Have a winner:'||ANVD.rategroup||' '||ANVD.annvdays
            ||' days.');


-- find the receipt date of the plate
        annvdt := null;
        begin
        select trunc(nvl(P.anvdate,nvl(LD.rcvddate,P.creationdate))),
                nvl(OH.ordertype,'R')
          into annvdt, l_ordertype
          from plate P, loads LD, orderhdr OH
         where P.lpid = cit.fromlpid
           and P.orderid = OH.orderid(+)
           and P.shipid = OH.shipid(+)
           and P.loadno = LD.loadno(+);
        exception when others then
            annvdt := null;
        end;
        if annvdt is null then
          begin
            select trunc(nvl(P.anvdate,nvl(LD.rcvddate,P.creationdate))),
                nvl(OH.ordertype,'R')
              into annvdt, l_ordertype
              from deletedplate P, loads LD, orderhdr OH
             where P.lpid = cit.fromlpid
               and P.orderid = OH.orderid(+)
               and P.shipid = OH.shipid(+)
               and P.loadno = LD.loadno(+);
          exception when others then
            annvdt := null;
          end;

        end if;

        if annvdt is null then
            goto continue;
        end if;

-- If inventory from crossdock order try to use crossdock offset
        if (nvl(ANVD.cxd_grace,'N') = 'Y')
         and (l_ordertype = 'C')
        then
          if (nvl(ANVD.cxd_anvdate_grace,'N') = 'Y') then
            l_gracedays := nvl(ANVD.cxd_grace_days,0);
            l_graceoff := nvl(ANVD.cxd_grace_days,0);
          else
            l_gracedays := nvl(ANVD.cxd_grace_days,0);
            l_graceoff := 0;
          end if;
        end if;

        -- annvdt := to_date('20050322010203','


        DbMsg('Anniversary date :'||to_char(annvdt,'YYYYMMDDHH24MISS'));

-- Start latest of shipdate or receipt date
        -- checkdt := trunc(greatest(IN_ORD.shipdate, annvdt));
        checkdt := trunc(greatest(in_shipdate, annvdt+l_graceoff));

        DbMsg('Starting date :'||to_char(checkdt,'YYYYMMDDHH24MISS'));

        DbMsg('Date diff:'||(checkdt - trunc(annvdt)));
        DbMsg('Div Date diff:'||trunc((checkdt - trunc(annvdt))/ANVD.annvdays));
        DbMsg('Days to add:'||
            trunc((checkdt - trunc(annvdt))/ANVD.annvdays) * ANVD.annvdays);


        if checkdt > annvdt+l_graceoff then
            checkdt := annvdt+l_graceoff + trunc(trunc((checkdt - annvdt-l_graceoff)/ANVD.annvdays))
                    * ANVD.annvdays;
        end if;

        DbMsg('First annv date :'||to_char(checkdt,'YYYYMMDDHH24MISS'));

        loop

            checkdt := checkdt + ANVD.annvdays;
            exit when (nvl(checkdt,sysdate+3) > trunc(sysdate));

            DbMsg('Checking date :'||to_char(checkdt,'YYYYMMDDHH24MISS'));

      -- Verify skip if it is the ship date
            if checkdt <= trunc(in_shipdate) then
                DbMsg('Checkdt not > shipdate'||checkdt||'<='||in_shipdate);
                goto annvd_continue;
            end if;

      -- Verify skip if it is the ship date
            if checkdt <= trunc(annvdt)+l_gracedays then
                DbMsg('Checkdt not > annvdt+grace'||checkdt||'<='||annvdt+l_gracedays);
                goto annvd_continue;
            end if;

      -- Check Order for this facility

            if NVL(ORD.tofacility,'XX') != cit.facility then
               rc := get_renewal_order(CUST, cit.facility, ORD, 'DAILY');
            end if;

            DbMsg('......Have totals:'||cit.quantity||' WT:'||cit.weight);
            if zbill.rd_rate(rategrouptype(ANVD.cr_custid, ANVD.rategroup),
                 ANVD.activity,
                 ANVD.billmethod, checkdt, RATE) = BAD then
                goto annvd_continue;
            end if;

            if RATE.rate > 0 then
                -- Try to read the corresponding entry
                l_rowid := null;
                begin
                select rowid
                  into l_rowid
                  from invoicedtl
                 where orderid = ORD.orderid
                   and shipid = ORD.shipid
                   and item = cit.item
                   and nvl(lotnumber,'(none)') = nvl(cit.lotnumber,'(none)')
                   -- and invoice = 0
                   and invtype = zbill.IT_STORAGE
                   and activity = RATE.activity
                   and billmethod = RATE.billmethod
                   and statusrsn = zbill.SR_ANVD
                   and trunc(activitydate) = checkdt
                   and billstatus not in (zbill.BILLED,zbill.DELETED);
                exception when others then
                    l_rowid := null;
                end;

                DbMsg('Ren Ord:'||ORD.orderid||'/'||ORD.shipid);
                DbMsg('Item:'||cit.item||'/'||nvl(cit.lotnumber,'(none)'));
                DbMsg('Check Date:'||checkdt);

                if l_rowid is not null then
                    DbMsg('Updating an entry ');
                    update invoicedtl
                       set enteredqty = enteredqty - cit.quantity,
                           enteredweight = enteredweight - cit.weight,
                           billstatus = zbill.uncharged,
                           calcedamt = null
                     where rowid = l_rowid;
                    update invoicehdr
                       set invstatus = zbill.NOT_REVIEWED
                     where invoice in
                        (select invoice
                           from invoicedtl
                          where rowid = l_rowid)
                       and invstatus = zbill.REVIEWED;
                else
                    DbMsg('Adding an entry ');
                    zms.log_msg('LoadClose', CIT.facility, CUST.custid,
                        'Can not adjust ANVD renewal for '
                        ||IN_ORD.orderid||'/'||IN_ORD.shipid||'/'
                        ||CIT.item||'/'||CIT.lotnumber
                        ||' on '||checkdt
                        ||' for '||CIT.quantity||' '||CIT.unitofmeasure
                        ||' - '||CIT.weight||' lbs. Actv/BM='
                        ||RATE.activity||'/'||RATE.billmethod,
                         'I', in_user, errmsg);


            /* Not doing for now, negatives may not work
              INSERT INTO invoicedtl
               (
                  billstatus,
                  facility,
                    custid,
                    invtype,
                    invdate,
                    item,
                    lotnumber,
                    orderid,
                    shipid,
                    activity,
                    activitydate,
                    billmethod,
                    enteredqty,
                    entereduom,
                    enteredweight,
                    statusrsn,
                    lastuser,
                    lastupdate
                 )
                 values
                 (
                    zbill.UNCHARGED,
                    CIT.facility,
                    CUST.custid,
                    zbill.IT_STORAGE,
                    sysdate,
                    CIT.item,
                    CIT.lotnumber,
                    ORD.orderid,
                    ORD.shipid,
                    RATE.activity,
                    checkdt,
                    RATE.billmethod,
                    -CIT.quantity,
                    CIT.unitofmeasure,
                    -CIT.weight,
                    zbill.SR_ANVD,
                    'BILLER',
                    sysdate
                 );

               */

                end if;
            end if;

<<annvd_continue>>
            null;

        end loop;


<<continue>>
        null;
    end loop;

END do_anvd;


PROCEDURE do_anvr(IN_ORD IN orderhdr%rowtype)
IS
BEGIN
-- for shipping plates in shipment

    for cit in (select SP.fromlpid, SP.facility,
                       SP.item, SP.lotnumber, SP.unitofmeasure,
                        sum(SP.quantity) quantity, sum(SP.weight) weight
                  from shippingplate SP
                 where SP.orderid = IN_ORD.orderid
                   and SP.shipid = IN_ORD.shipid
                 group by SP.fromlpid, SP.facility, SP.item,
                       SP.lotnumber, SP.unitofmeasure)
    loop
         DbMsg('LPID:'||cit.fromlpid||' Item:'||cit.item||'/'||cit.lotnumber
                ||' Q/W '||cit.quantity||'/'||cit.weight);

        if cit.fromlpid is null then
            goto continue;

        end if;

-- Check if there is active ANVR billing for this item
        ANVR := null;
        OPEN C_ANVR(CUST.custid, cit.item);
        FETCH C_ANVR into ANVR;
        CLOSE C_ANVR;

        if ANVR.item is null then
            goto continue;
        end if;

        if nvl(ANVR.anvdate_grace,'N') = 'Y' then
            l_gracedays := 0;
            l_graceoff := nvl(ANVR.gracedays,0);
        else
            l_gracedays := nvl(ANVR.gracedays,0);
            l_graceoff := 0;
        end if;

-- OK we have a winner
         DbMsg('.. Have a winner:'||ANVR.rategroup);

-- find the receipt date of the plate or deletedplate
        annvdt := null;
        begin
        select trunc(nvl(P.anvdate,nvl(LD.rcvddate,P.creationdate))),
               nvl(OH.ordertype,'R')
          into annvdt, l_ordertype
          from plate P, loads LD, orderhdr OH
         where P.lpid = cit.fromlpid
           and P.orderid = OH.orderid(+)
           and P.shipid = OH.shipid(+)
           and P.loadno = LD.loadno(+);
        exception when others then
            annvdt := null;
        end;
        if annvdt is null then
          begin
            select trunc(nvl(P.anvdate,nvl(LD.rcvddate,P.creationdate))),
               nvl(OH.ordertype,'R')
              into annvdt, l_ordertype
              from deletedplate P, loads LD, orderhdr OH
             where P.lpid = cit.fromlpid
               and P.orderid = OH.orderid(+)
               and P.shipid = OH.shipid(+)
               and P.loadno = LD.loadno(+);
          exception when others then
            annvdt := null;
          end;

        end if;

        if annvdt is null then
            goto continue;
        end if;

--         annvdt := to_date('20050425010203','YYYYMMDDHH24MISS');

-- If crossdock order try to use crossdock grace info
        if (nvl(ANVR.cxd_grace,'N') = 'Y')
         and (l_ordertype = 'C')
        then
          if (nvl(ANVR.cxd_anvdate_grace,'N') = 'Y') then
            l_gracedays := 0; -- nvl(ANVR.cxd_grace_days,0);
            l_graceoff := nvl(ANVR.cxd_grace_days,0);
          else
            l_gracedays := nvl(ANVR.cxd_grace_days,0);
            l_graceoff := 0;
          end if;
        end if;

        DbMsg('Anniversary date :'||to_char(annvdt,'YYYYMMDDHH24MISS'));

        annvdt := annvdt + l_graceoff;

-- Start prcessing at the latest of shipdate or receipt date
        -- checkdt := trunc(greatest(IN_ORD.shipdate, annvdt));
        checkdt := trunc(greatest(in_shipdate, annvdt));
        -- checkdt := trunc(annvdt);

        DbMsg('Starting date :'||to_char(checkdt,'YYYYMMDDHH24MISS'));


        ixdt := 0;
        if checkdt >= annvdt then
            ixdt := trunc(months_between(checkdt, annvdt));
            checkdt := add_months(annvdt, ixdt);
        end if;

        DbMsg('First annv date :'||to_char(checkdt,'YYYYMMDDHH24MISS'));

        loop
            ixdt := ixdt + 1;
            checkdt := add_months(annvdt, ixdt);
            if (extract(day from annvdt) < extract (day from checkdt)) then
              checkdt := checkdt - (extract (day from checkdt) - extract(day from annvdt));
            end if;
            exit when (nvl(checkdt,sysdate+3) > trunc(sysdate));

            DbMsg('Checking date :'||to_char(checkdt,'YYYYMMDDHH24MISS'));

      -- Verify skip if it is the ship date
            if checkdt <= trunc(in_shipdate) then
                DbMsg('Checkdt not > shipdate'||checkdt||'<='||in_shipdate);
                goto annvd_continue;
            end if;

      -- Verify skip if it is the ship date
            if checkdt <= trunc(annvdt)+l_gracedays then
                DbMsg('Checkdt not > annvdt+grace'||checkdt||'<='||annvdt+l_gracedays);
                goto annvd_continue;
            end if;

      -- Check Order for this facility

            if NVL(ORD.tofacility,'XX') != cit.facility then
               rc := get_renewal_order(CUST, cit.facility, ORD, 'DAILY');
            end if;

            DbMsg('......Have totals:'||cit.quantity||' WT:'||cit.weight);
            if zbill.rd_rate(rategrouptype(ANVR.cr_custid, ANVR.rategroup),
                 ANVR.activity,
                 ANVR.billmethod, checkdt, RATE) = BAD then
                goto annvd_continue;
            end if;

            if RATE.rate > 0 then
                -- Try to read the corresponding entry
                l_rowid := null;
                begin
                select rowid
                  into l_rowid
                  from invoicedtl
                 where orderid = ORD.orderid
                   and shipid = ORD.shipid
                   and item = cit.item
                   and nvl(lotnumber,'(none)') = nvl(cit.lotnumber,'(none)')
                   -- and invoice = 0
                   and invtype = zbill.IT_STORAGE
                   and activity = RATE.activity
                   and billmethod = RATE.billmethod
                   and statusrsn = zbill.SR_ANVR
                   and trunc(activitydate) = checkdt
                   and billstatus not in (zbill.BILLED,zbill.DELETED);
                exception when others then
                    l_rowid := null;
                end;

                DbMsg('Ren Ord:'||ORD.orderid||'/'||ORD.shipid);
                DbMsg('Item:'||cit.item||'/'||nvl(cit.lotnumber,'(none)'));
                DbMsg('Check Date:'||checkdt);

                if l_rowid is not null then
                    DbMsg('Updating an entry ');
                    update invoicedtl
                       set enteredqty = enteredqty - cit.quantity,
                           enteredweight = enteredweight - cit.weight,
                           billstatus = zbill.uncharged,
                           calcedamt = null
                     where rowid = l_rowid;
                    update invoicehdr
                       set invstatus = zbill.NOT_REVIEWED
                     where invoice in
                        (select invoice
                           from invoicedtl
                          where rowid = l_rowid)
                       and invstatus = zbill.REVIEWED;
                else
                    DbMsg('Adding an entry ');
                    zms.log_msg('LoadClose', CIT.facility, CUST.custid,
                        'Can not adjust ANVR renewal for '
                        ||IN_ORD.orderid||'/'||IN_ORD.shipid||'/'
                        ||CIT.item||'/'||CIT.lotnumber
                        ||' on '||checkdt
                        ||' for '||CIT.quantity||' '||CIT.unitofmeasure
                        ||' - '||CIT.weight||' lbs. Actv/BM='
                        ||RATE.activity||'/'||RATE.billmethod,
                         'I', in_user, errmsg);

                end if;
            end if;

<<annvd_continue>>
            null;

        end loop;


<<continue>>
        null;
    end loop;

END do_anvr;



BEGIN
    out_errmsg := 'OKAY';

    -- debug_flag := True;

    LD := null;
    OPEN C_LOAD(in_loadno);
    FETCH C_LOAD into LD;
    CLOSE C_LOAD;

    DbMsg('Load found:'||LD.loadno);

    CUST := null;


-- Get the customer information for these shipment orders
    for cord in (select *
                   from orderhdr
                  where loadno = in_loadno
                  order by custid)

    loop
        DbMsg('Orderid:'||cord.orderid||'/'||cord.shipid);
        if nvl(CUST.custid,'xxx') != cord.custid then
            DbMsg('Read customer:'||cord.custid);
    -- Get the customer information for this receipt order
            if zbill.rd_customer(cord.custid, CUST) = BAD then
               out_errmsg := 'Invalid custid = '|| cord.custid;
           -- DbMsg(out_errmsg);
               return;
            end if;

        end if;


    -- Check if customer has any anniversary day billing
        cnt := 0;

        select count(1)
          into cnt
          from custratewhen W, custrategroup G
         where G.custid = cord.custid
           and  W.custid = decode(nvl(G.linkyn,'N'),'Y','DEFAULT',G.custid)
           and W.rategroup =
                decode(nvl(G.linkyn,'N'),'Y',G.linkrategroup,G.rategroup)
           and W.businessevent = 'ANVD';

        if nvl(cnt,0) > 0 then
            DbMsg('Customer '||CUST.custid||' Has anv day billing');
            do_anvd(cord);
        end if;

    -- Check if customer has any anniversary billing
        cnt := 0;

        select count(1)
          into cnt
          from custratewhen W, custrategroup G
         where G.custid = cord.custid
           and  W.custid = decode(nvl(G.linkyn,'N'),'Y','DEFAULT',G.custid)
           and W.rategroup =
                decode(nvl(G.linkyn,'N'),'Y',G.linkrategroup,G.rategroup)
           and W.businessevent = 'ANVR';


        if nvl(cnt,0) > 0 then
            DbMsg('Customer '||CUST.custid||' Has anvr billing');
            do_anvr(cord);
        end if;

<<continue_cord>>
        null;

    end loop;

    for crec in (select distinct custid
                   from orderhdr
                  where loadno = in_loadno)
    loop
      for crec2 in C_ANV_CHARGE(crec.custid) loop
        out_errmsg := '';

        if zbill.calculate_detail_rate(crec2.rowid,
                trunc(crec2.activitydate),out_errmsg) = BAD then
            null;
        end if;
        update invoicedtl
           set billstatus = zbill.UNCHARGED
         where rowid = crec2.rowid;
      end loop;
    end loop;




EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CRAD:'||sqlerrm;
END adjust_agginv_ship_renewal;



----------------------------------------------------------------------
--
-- daily_billing_job
--
----------------------------------------------------------------------
PROCEDURE daily_billing_job
IS
errmsg varchar2(100);
datime varchar2(10) := '0110';
nowtime varchar2(10);

da_job integer;

nowdt varchar2(20);

effdate     date;

CURSOR C_DBR
    IS
select max(effdate)
  from daily_billing_run;

lastrun date;

rc integer;

BEGIN

    effdate := trunc(sysdate);

    lastrun := null;

    OPEN C_DBR;
    FETCH C_DBR into lastrun;
    CLOSE C_DBR;

    if lastrun is null then
        lastrun := effdate - 1;
    end if;

    if lastrun >= effdate then
        return;
    end if;

    loop
        exit when lastrun >= effdate;

        lastrun := lastrun + 1;

        insert into daily_billing_run (effdate, start_dt, end_dt)
            values (lastrun, sysdate, null);


        zms.log_msg('DAILYBILL', null, null,
                    'Begin daily billing run at '
                        ||to_char(sysdate,'YYYYMMDDHH24MISS')
                    || ' for ' || to_char(lastrun,'YYYYMMDD'),
                     'I', 'DB', errmsg);

        select to_char(sysdate,'MISS')
          into nowtime
          from dual;

--      dbms_lock.sleep(10);

-- Run the daily renewal process
        rc := zbs.daily_renewal_process(lastrun, errmsg);
        if rc = zbill.BAD then
            zms.log_msg('DAILYBILL', null, null,
                      errmsg,
                     'E', 'DB', errmsg);

        end if;


-- Reset the customer next billdates daily
        for crec in (select custid from customer) loop
            zbill.set_custbilldates(
                crec.custid,
                'BillDaily',
                errmsg
            );
        end loop;

-- Auto-Approve pending accessorials that have completed.
        zba.approve_accessorials(lastrun, errmsg);
        if errmsg != 'OKAY' then
            zms.log_msg('DAILYBILL', null, null,
                      errmsg,
                     'E', 'DB', errmsg);

        end if;


-- Do pallet and location dounts for them thats got em
        zbs.count_pallets_today(lastrun, 'BillDaily', errmsg);
        if errmsg != 'OKAY' then
            zms.log_msg('DAILYBILL', null, null,
                      errmsg,
                     'E', 'DB', errmsg);
        end if;

-- If today is the first of the month, set the EOM asof
        if to_char(lastrun,'DD') = '01' then
            zbill.set_asofinventory_eom(lastrun-1, 'DAILYBILL', errmsg);
            if errmsg != 'OKAY' then
                zms.log_msg('DAILYBILL', null, null,
                      errmsg,
                     'E', 'DAILYBILL', errmsg);
            end if;
        end if;

        zms.log_msg('DAILYBILL', null, null,
                    'End daily billing run at '
                        ||to_char(sysdate,'YYYYMMDDHH24MISS')
                    || ' for ' || to_char(lastrun,'YYYYMMDD'),
                     'I', 'DB', errmsg);


        update daily_billing_run
           set end_dt = sysdate
         where effdate = lastrun;

        commit;
    end loop;

-- Check the customer custom bill schedules
--  only need to do once for current date
    for crec in (select custid from customer) loop
        zbill.check_billschedule(
            crec.custid,
            errmsg
        );
    end loop;

    commit;

END daily_billing_job;


----------------------------------------------------------------------
--
-- check_daily_billing
--
----------------------------------------------------------------------
FUNCTION check_daily_billing
(
    in_effdate  date
)
RETURN boolean
IS
CURSOR C_DBR(in_effdate date)
IS
SELECT *
  FROM daily_billing_run
 WHERE effdate = in_effdate;

DBR daily_billing_run%rowtype;
BEGIN
    DBR := null;
    OPEN C_DBR(in_effdate);
    FETCH C_DBR into DBR;
    CLOSE C_DBR;

    if DBR.effdate is null then
        return FALSE;
    end if;

    if DBR.end_dt is not null then
        return FALSE;
    end if;

    return TRUE;

EXCEPTION WHEN OTHERS THEN
    return FALSE;
END check_daily_billing;


end zbillstorage;
/

show error package zbillstorage;
show error package body zbillstorage;

exit;
