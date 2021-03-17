create or replace package body alps.zbilling as
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

  VALUE_TOO_LARGE  EXCEPTION;
  PRAGMA EXCEPTION_INIT(VALUE_TOO_LARGE, -1438);

-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************
--
-- Cursors are defined in zbillspec.sql
--
  CURSOR C_DFLT(in_id varchar2)
  IS
    SELECT to_number(defaultvalue)
      FROM systemdefaults
     WHERE defaultid = in_id;

-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************


----------------------------------------------------------------------
--
-- rd_customer -
--
----------------------------------------------------------------------
FUNCTION rd_customer
(
    in_custid   IN      varchar2,
    out_cust    OUT     customer%rowtype
)
RETURN integer
IS
BEGIN
    out_cust := NULL;
    OPEN C_CUST(in_custid);
    FETCH C_CUST into out_cust;
    CLOSE C_CUST;
    if out_cust.custid is null then
       return BAD;
    end if;
    return GOOD;
END rd_customer;

----------------------------------------------------------------------
--
-- rd_item - read item row
--
----------------------------------------------------------------------
FUNCTION rd_item
(
    in_custid   IN      varchar2,
    in_item     IN      varchar2,
    out_item    OUT     custitem%rowtype
)
RETURN integer
IS
BEGIN
    out_item := NULL;
    OPEN C_ITEM(in_custid, in_item);
    FETCH C_ITEM into out_item;
    CLOSE C_ITEM;

    if out_item.custid is NULL then
       return BAD;
    end if;

    return GOOD;
END rd_item;

----------------------------------------------------------------------
--
-- rd_item_rategroup - read custitemview row for the rategroup
--
----------------------------------------------------------------------
PROCEDURE rd_item_rategroup
(
    in_custid   IN      varchar2,
    in_item     IN      varchar2,
    out_rategroup OUT   custitem.rategroup%type
)
IS
   CURSOR C_CIV(in_custid char, in_item char)
   IS
     SELECT rategroup
       FROM custitemview
      WHERE custid = in_custid
        AND item = in_item;

BEGIN
    out_rategroup := NULL;

    OPEN C_CIV(in_custid, in_item);
    FETCH C_CIV into out_rategroup;
    CLOSE C_CIV;
    -- out_rategroup := zbut.item_rategroup(in_custid, in_item); 

    return; 
    
END rd_item_rategroup;


----------------------------------------------------------------------
--
-- rd_rate - read rate row
--
----------------------------------------------------------------------
FUNCTION rd_rate
(
    in_rategroup IN      rategrouptype,
    in_activity  IN      varchar2,
    in_billmethod IN     varchar2,
    in_effdate   IN      date,
    out_rate     OUT     custrate%rowtype
)
RETURN integer
IS
BEGIN
    out_rate := NULL;
    OPEN C_RATE(in_rategroup, in_activity, in_billmethod,
                    in_effdate);
    FETCH C_RATE into out_rate;
    CLOSE C_RATE;

    if out_rate.custid is NULL then
       return BAD;
    end if;

    return GOOD;
END rd_rate;


----------------------------------------------------------------------
--
-- select_rategroup -
--
----------------------------------------------------------------------
PROCEDURE select_rategroup
(
    in_custid       IN  varchar2,
    in_Irategroup   IN  varchar2,
    in_Crategroup   IN  varchar2,
    in_event        IN  varchar2,
    in_facility     IN  varchar2,
    out_rategroup   OUT varchar2
)
IS
  rategroup custitem.rategroup%type;
BEGIN

  -- Determine the rate group to use for an event for this item
  -- based on the existance of an entry for the business event
    rategroup := in_Crategroup;
    for crec in zbill.C_RATE_WHEN(in_custid, in_Irategroup,
                in_event, in_facility, sysdate) loop
        if crec.billmethod in
            (zbill.BM_QTY, zbill.BM_QTYM, zbill.BM_FLAT, 
             zbill.BM_CWT, zbill.BM_WT, zbill.BM_QTY_BREAK,
             zbill.BM_FLAT_BREAK, zbill.BM_WT_BREAK, zbill.BM_CWT_BREAK,
             zbill.BM_QTY_LOT_RCPT,zbill.BM_WT_LOT_RCPT,
             zbill.BM_CWT_LOT_RCPT,
             zbill.BM_PLT_COUNT, zbill.BM_PLT_CNT_BRK) then
            rategroup := in_Irategroup;
        end if;
    end loop;

    out_rategroup := rategroup;

END select_rategroup;


----------------------------------------------------------------------
--
-- add_min_invoicedtl
--
----------------------------------------------------------------------
FUNCTION add_min_invoicedtl
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
    in_event     IN      varchar2,
    in_check_deleted IN  varchar2 default 'N'
)
RETURN integer
IS
  v_count number;
BEGIN

    if (in_check_deleted = 'Y') then
      select count(1) into v_count
      from invoicedtl
      where facility = INVH.facility
        and custid = CUST.custid
        and orderid = ORD.orderid
        and nvl(item,'(none)') = nvl(in_item,'(none)')
        and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
        and activity = RATE.activity
        and nvl(billmethod,'(none)') = nvl(RATE.billmethod,'(none)')
        and billstatus = zbill.DELETED;
        
      if (v_count > 0) then
        return zbill.GOOD;
      end if;
    end if;
    
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
        decode(INVH.invstatus,zbill.ESTIMATED,zbill.ESTIMATED,zbill.NOT_REVIEWED),
        INVH.facility,
        CUST.custid,
        ORD.orderid,
        in_item,
        in_lotnumber,
        RATE.activity,
        in_date,
        1,
        RATE.uom,
        RATE.rate - in_total,
        RATE.rate - in_total,
        RATE.billmethod,
        RATE.rate,
        decode(INVH.invstatus,zbill.ESTIMATED,null,ORD.loadno),
        INVH.invoice,
        INVH.invtype,
        INVH.invdate,
        ORD.shipid,
        in_comment,
        in_userid,
        sysdate,
        in_event
   );

   return zbill.GOOD;

EXCEPTION WHEN OTHERS THEN
   return zbill.bad;
END add_min_invoicedtl;

----------------------------------------------------------------------
--
-- check_uom_to_uom -
--
----------------------------------------------------------------------
FUNCTION check_uom_to_uom
(
    in_custid   IN      varchar2,
    in_item     IN      varchar2,
    in_from_uom IN      varchar2,
    in_to_uom   IN      varchar2,
    in_level    IN      number,
    in_skips    IN      varchar2
)
RETURN integer
IS
  CURSOR C_UOM(in_cust varchar2,
             in_item varchar2,
             in_from_uom varchar2)
  RETURN custitemuom%rowtype
  IS
   SELECT *
     FROM custitemuom
    WHERE custid = in_cust
      AND item   = in_item
      AND (fromuom = in_from_uom
         OR touom = in_from_uom);
  t_uom  custitemuom.fromuom%type;

  CURSOR C_CNV(in_from_uom varchar2)
  RETURN conversions%rowtype
  IS
   SELECT *
     FROM conversions
    WHERE (fromuom = in_from_uom
         OR touom = in_from_uom);


 my_level number;
 my_skips varchar2(200);

BEGIN

    my_level := nvl(in_level,1) + 1;

    -- zut.prt('Level:'||to_char(my_level)||
    --    ' Trying from:'||in_from_uom||' To:'||in_to_uom);

    if my_level > 10 THEN
       return 0;
    end if;

    if in_from_uom = in_to_uom then
       return 1;
    end if;

    if instr(in_skips,'|'||in_from_uom||'|') > 0 then
       return 0;
    end if;

    my_skips := nvl(in_skips,'|')||in_from_uom||'|';


    for crec in C_UOM(in_custid, in_item, in_from_uom) loop
        if crec.fromuom = in_from_uom then
            t_uom := crec.touom;
        else
            t_uom := crec.fromuom;
        end if;
        if crec.touom = in_to_uom THEN
           return 1;
        end if;
        if check_uom_to_uom(in_custid, in_item,
                      t_uom, in_to_uom,
                      my_level, my_skips) > 0 then
           return 1;
        end if;
    end loop;

    for crec in C_CNV(in_from_uom) loop
        if crec.fromuom = in_from_uom then
            t_uom := crec.touom;
        else
            t_uom := crec.fromuom;
        end if;
        if crec.touom = in_to_uom THEN
           return 1;
        end if;
        if check_uom_to_uom(in_custid, in_item,
                      t_uom, in_to_uom,
                      my_level, my_skips) > 0 then
           return 1;
        end if;
    end loop;


    return 0;



END check_uom_to_uom;

----------------------------------------------------------------------
--
-- get_invoicehdr - retreive or create an invoice header for the
--                specified invoice type
--
----------------------------------------------------------------------
FUNCTION get_invoicehdr
(
        in_lookup       IN      varchar2,   -- FIND to try to lookup
        in_invtype      IN      varchar2,
        in_custid       IN      varchar2,
        in_facility     IN      varchar2,
        in_userid       IN      varchar2,
        INVH            OUT     invoicehdr%rowtype
)
RETURN integer
IS
  CURSOR C_INVH_FIND(in_custid varchar2, in_invtype varchar2)
  RETURN invoicehdr%rowtype
  IS
     SELECT *
       FROM invoicehdr
      WHERE custid = in_custid
        AND facility = in_facility
        AND invtype = in_invtype
        AND invstatus = zbill.NOT_REVIEWED;

  invoice_id invoicehdr.invoice%type;

BEGIN
   INVH := null;
   if upper(in_lookup) = 'FIND' then
       OPEN C_INVH_FIND(in_custid, in_invtype);
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
              lastuser,
              lastupdate
          )
       VALUES
          (
              invoiceseq.nextval,
              sysdate,
              in_invtype,
              zbill.NOT_REVIEWED,
              in_facility,
              in_custid,
              in_userid,
              sysdate
          );

       SELECT invoiceseq.currval INTO invoice_id FROM dual;

       OPEN C_INVH(invoice_id);
       FETCH C_INVH into INVH;
       CLOSE C_INVH;

   end if;

   return GOOD;

END get_invoicehdr;

----------------------------------------------------------------------
--
-- calculate_detail_rate - determine rate to charge for detail line
--                         of invoice
--
----------------------------------------------------------------------
FUNCTION calculate_detail_rate
(
    in_rowid    IN      rowid,
    in_effdate  IN      date,
    out_errmsg  OUT     varchar2
)
RETURN integer
IS
  CUST  customer%rowtype;
  ID    invoicedtl%rowtype;
  ITM   custitem%rowtype;
  RT    custrate%rowtype;
  uom   invoicedtl.calceduom%type;
  rate  invoicedtl.calcedrate%type;
  amt   invoicedtl.calcedamt%type;
  qty   invoicedtl.calcedqty%type;
  f_qty number;
  m_qty number;
  item  invoicedtl.item%type;
  errmsg  varchar2(1000);
  rategroup rategrouptype; --customer.rategroup%type;

  CURSOR C_LOADS(in_loadno number)
  IS
    SELECT rcvddate
      FROM loads
     WHERE loadno = in_loadno;

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

  cursor c_pcbr_rate (v_custid varchar2, v_facility varchar2, v_rategroup varchar2, v_activity varchar2, v_effdate date)
  is
    select * 
    from custrate_storage_lkup
    where custid = v_custid and facility = v_facility 
      and rategroup = v_rategroup and activity = v_activity
      and effdate <= trunc(v_effdate)
	order by effdate desc;
  pcbr c_pcbr_rate%rowtype;
  
  CURSOR C_CBD(in_custid varchar2)
  RETURN custbilldates%rowtype
  IS
    SELECT *
      FROM custbilldates
     WHERE custid = in_custid;
  CBD C_CBD%rowtype;

  CURSOR C_CUSTPALLETRATE(RT custrate%rowtype, in_pallettype varchar2)
  IS
    SELECT *
      FROM custpalletrate
     WHERE custid = RT.custid
       AND rategroup = RT.rategroup
       AND effdate = RT.effdate
       AND activity = RT.activity
       AND billmethod = RT.billmethod
       AND pallettype = in_pallettype;

  CPR c_custpalletrate%rowtype;

  CURSOR C_CUSTPASSTHRURATE(RT custrate%rowtype, in_passthruvalue varchar2)
  IS
    SELECT *
      FROM custpassthrurate
     WHERE custid = RT.custid
       AND rategroup = RT.rategroup
       AND effdate = RT.effdate
       AND activity = RT.activity
       AND billmethod = RT.billmethod
       AND upper(passthruvalue) = upper(in_passthruvalue);
  CPT c_custpassthrurate%rowtype;
  
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

  strg_prorate BOOLEAN;
  strg_proratedays integer;
  strg_proratepct integer;
  strg_proratedays_2 integer;
  strg_proratepct_2 integer;

  lastrenewal  date;
  arrived_date  date;

  mincat activity.mincategory%type;

  itm_weight number;

  now_date  date;
  adj integer; -- adjustment for calculated prorate bill date
  cnt integer;
  l_tare number;
  tare_qty number;
  
  l_carrier carrier.carrier%type;
  l_carrier_discount custratecarrierdiscount.discount%type;
  l_comment varchar2(255);
 
  CURSOR C_ORD(in_orderid number, in_shipid number)
  IS
   SELECT ordertype
     FROM orderhdr
    WHERE orderid = in_orderid
      AND shipid = in_shipid;

  ORD C_ORD%rowtype;

  CURSOR C_CLR(in_facility varchar2,
               in_custid varchar2)
  RETURN custlastrenewal%rowtype
  IS
    SELECT *
      FROM custlastrenewal
     WHERE facility = in_facility
       AND custid = in_custid;

  CLR custlastrenewal%rowtype;


  l_gracedays integer;
  v_sql varchar2(300);
  v_match_value varchar2(255);
  v_num_value number;
  out_logmsg varchar2(4000);
BEGIN
  -- Lets be optimistic and assume we will work fine
  -- errors should be the exception (right?)
    out_errmsg := 'OKAY';

    now_date := in_effdate;

  -- Get the invoicedtl row we are working on
    ID := NULL;
    OPEN CINVD_ROWID(in_rowid);
    FETCH CINVD_ROWID into ID;
    CLOSE CINVD_ROWID;

  -- get the customer
    if rd_customer(ID.custid, CUST) = BAD then
       out_errmsg := 'ID: customer doesnot exist:'||ID.custid;
       return BAD;
    end if;

-- check for lot receipt renewal processing
    lrr := null;
    OPEN C_SD('LOTRECEIPTRENEWAL');
    FETCH C_SD into lrr;
    CLOSE C_SD;

  -- determine if we are subject to storage proration
    select mincategory
      into mincat
      from activity
     where code = ID.activity;
    strg_prorate := FALSE;


    if CUST.splitrecvstorage = 'Y' and ID.invtype = IT_RECEIPT then
       strg_proratedays :=  nvl(CUST.proratedays, 15);
       strg_proratepct := nvl(CUST.proratepct, 50);

       begin
        select proratedays_2, proratepct_2 into strg_proratedays_2, strg_proratepct_2
        from customer_aux
        where custid = CUST.custid;
       exception
        when others then
          strg_proratedays_2 := null;
          strg_proratepct_2 := null;
       end;
       
       if (nvl(strg_proratedays_2,0) < strg_proratedays) then
        strg_proratedays_2 := null;
        strg_proratepct_2 := null;
       else
        strg_proratedays_2 := nvl(strg_proratedays_2,0);
        strg_proratepct_2 := nvl(strg_proratepct_2,0);
       end if;

       if mincat = 'S' then
          adj := -2;
          if CUST.rnewbillfreq = 'M' then
             if to_char(ID.activitydate,'DD') >= CUST.rnewbillday then
                adj := -1;
             end if;
          end if;


     -- If get renewal date
           if CUST.rnewbillfreq in ('C','F') then -- custom calendar
             CLR := null;
             OPEN C_CLR(ID.facility, ID.custid);
             FETCH C_CLR into CLR;
             CLOSE C_CLR;
             lastrenewal := nvl(CLR.lastrenewal,trunc(sysdate));
           elsif get_nextbilldate(CUST.custid,
                       add_months(ID.activitydate, adj), CUST.rnewbillfreq,
                       CUST.rnewbillday, zbill.BT_RENEWAL, lastrenewal) 
             = zbill.BAD then
               lastrenewal := trunc(sysdate);
           end if;

           arrived_date := null;
           OPEN C_LOADS(ID.loadno);
           FETCH C_LOADS into arrived_date;
           CLOSE C_LOADS;

           if arrived_date is null then
              arrived_date := sysdate;
           end if;
		   
		   if CUST.rnewbillfreq in ('C','F') then -- custom calendar
             CBD := null;
             OPEN C_CBD(ID.custid);
             FETCH C_CBD into CBD;
             CLOSE C_CBD;
             if arrived_date > CBD.nextrenewal then  --Activity in next renewal period,
                                                     --but renewal not yet run in current period.
                                                     --So, simulate that the current renewal has been run.
                if get_nextbilldate(CUST.custid, CBD.nextrenewal, 
                       CUST.rnewbillfreq,
                       CUST.rnewbillday,
                       zbill.BT_RENEWAL, 
                       CBD.nextrenewal) = zbill.BAD then
                  lastrenewal := trunc(sysdate);
                else
                  lastrenewal := CBD.nextrenewal;
                end if;
             end if;
           end if;

           if arrived_date - lastrenewal > strg_proratedays then
               strg_prorate := TRUE;
               
               if arrived_date - lastrenewal > strg_proratedays_2 then
                  strg_proratepct := strg_proratepct_2;
               end if;
           end if;
       end if;
    end if;

  -- Only calc if it has never been calced before
    if ID.billstatus not in (zbill.ESTIMATED, zbill.UNCHARGED, zbill.RECALC) then
       out_errmsg := 'INVOICEDTL: Billstatus = ' ||
                  NVL(ID.billstatus,'Not Exist');
       return BAD;
    end if;

 -- Get the item for this detail line
    ITM := null;
    if ID.item is null then
       rategroup := zbut.rategroup(cust.custid, CUST.rategroup);
    elsif (ID.billmethod = zbill.BM_PARENT_BILLING and ID.item = 'MIXED') then
       ITM.weight := 0;
       rategroup := rategrouptype(ID.custid, ID.rategroup);
    else
        if rd_item(ID.custid, ID.item, ITM) = BAD then
           out_errmsg := 'ITEM does not exist: '||ID.custid||'/'||ID.item;
           return BAD;
        end if;
        -- rd_item_rategroup(ID.custid, ID.item, rategroup);
        rategroup := zbut.item_rategroup(ID.custid, ID.item);
    end if;

-- Determine the weight of the objects
    if (ID.billmethod <> zbill.BM_PARENT_BILLING and ID.billmethod <> zbill.BM_ORDER_QTY_BREAK) then
      zbut.translate_uom(ID.custid, ID.item, ID.enteredqty, ID.entereduom,
              ITM.baseuom,
              qty, errmsg);
      if errmsg != 'OKAY' then
         -- out_errmsg := errmsg;
         -- return BAD;
         qty := 0;
      end if;
    end if;
    itm_weight := qty * ITM.weight;

    if ID.billmethod in (zbill.BM_WT,zbill.BM_WT_BREAK, 
                         zbill.BM_WT_LOT_RCPT) then
        itm_weight := ID.enteredweight;
    end if;

 -- If we have an entered rate use it instead of calculating everything out
    if ID.enteredrate is not null then
        qty := nvl(ID.enteredqty, 0);
        amt := qty * ID.enteredrate;
        UPDATE invoicedtl
           SET calcedrate = ID.enteredrate,
               calcedamt = amt,
               calceduom = ID.entereduom,
               calcedqty = qty,
               weight = itm_weight,
               billstatus = decode(billstatus,'E','E',NOT_REVIEWED)
         WHERE rowid = in_rowid;
       return GOOD;
    end if;

 -- IF billmethod is null try to guess what it should be
    if ID.billmethod is null then
        if ID.entereduom is not null then
            ID.billmethod := zbill.BM_QTY;
        else
            ID.billmethod := zbill.BM_FLAT;
        end if;
    end if;

-- Locate proper rate group to use
    if (ID.billmethod = zbill.BM_PARENT_BILLING and ID.item = 'MIXED') then
      rategroup := rategrouptype(ID.custid, ID.rategroup);
    else
      rategroup := zbut.item_rategroup(ID.custid, ID.item);
    end if;

    if rd_rate(rategroup, ID.activity, ID.billmethod,
                    now_date, RT) = BAD then
       rategroup := zbut.rategroup(CUST.custid,CUST.rategroup);
       if rd_rate(rategroup, ID.activity,
                  ID.billmethod, now_date, RT) = BAD then
          out_errmsg := 'RATE does not exist: '||ID.custid||'/'||ID.item;
        UPDATE invoicedtl
           SET calcedrate = 0,
               calcedamt = 0,
               calceduom = ID.entereduom,
               calcedqty = 0,
               weight = 0,
               billstatus = decode(billstatus,'E','E',NOT_REVIEWED)
         WHERE rowid = in_rowid;
          return BAD;
       end if;
    end if;

-- Check for tare adjustment for the rate
    l_tare := 0;
    if nvl(RT.tare_adj,'N') in ('A','S')
      and RT.moduom is not null and ITM.item is not null then
-- Determine Tare UOM
        zbut.translate_uom(ID.custid, ID.item, ID.enteredqty, ID.entereduom,
              RT.moduom,
              tare_qty, errmsg);
        if errmsg != 'OKAY' then
            tare_qty := 0;
        end if;

-- Find UOM tare adjust
        if nvl(ITM.baseuom,'xx') = RT.moduom then
            l_tare := ITM.tareweight;
        else
          begin
            select tareweight
              into l_tare
              from custitemuom
             where custid = ITM.custid
               and item = ITM.item
               and touom = RT.moduom
               and tareweight is not null
              order by sequence;
          exception when others then
            l_tare := 0;
          end;
        end if;

        if (RT.uom = 'CWT') and
           (RT.billmethod not in (zbill.BM_CWT, zbill.BM_CWT_BREAK,
                                  zbill.BM_CWT_LOT_RCPT)) then
              zbut.translate_uom(ID.custid, ID.item, l_tare,
                                 'LBS', RT.uom, l_tare, errmsg);
        end if;        
        l_tare := nvl(l_tare,0) * nvl(tare_qty,0);

        if RT.tare_adj = 'S' then
            l_tare := -l_tare;
        end if;

    end if;

-- If this is a quantity break method lookup the break record and
-- set the rate based on the quantity break
    if RT.billmethod in (zbill.BM_QTY_BREAK, zbill.BM_FLAT_BREAK, 
                         zbill.BM_WT_BREAK, zbill.BM_CWT_BREAK, zbill.BM_ORDER_QTY_BREAK,
                         zbill.BM_PLT_CNT_BRK)
    then
        if RT.billmethod = zbill.BM_CWT_BREAK then
            uom := ITM.baseuom;
        elsif RT.billmethod != zbill.BM_PLT_CNT_BRK then
            uom := RT.uom;
        end if;
        if RT.billmethod = zbill.BM_WT_BREAK then
            zbut.translate_uom(ID.custid, ID.item, ID.enteredweight, 
                  'LBS', RT.uom,
                  f_qty, errmsg);
        elsif RT.billmethod = zbill.BM_ORDER_QTY_BREAK then
          f_qty := ID.enteredqty;
        elsif RT.billmethod != zbill.BM_PLT_CNT_BRK then
            zbut.translate_uom(ID.custid, ID.item, ID.enteredqty, 
                ID.entereduom, uom, f_qty, errmsg);
        end if;
        if errmsg != 'OKAY' then
           f_qty := 0;
        end if;

        
        if RT.billmethod = zbill.BM_CWT_BREAK then
            f_qty := (f_qty * ITM.weight) / 100;

            -- zut.prt('Calc qty for CWT Break:'||f_qty);
        end if;

        if RT.billmethod in (zbill.BM_CWT_BREAK,zbill.BM_WT_BREAK) then
            if RT.billmethod = zbill.BM_CWT_BREAK then
                f_qty := f_qty + l_tare/100;
            else
                f_qty := f_qty + l_tare;
            end if;
            if (f_qty < 0) then
                f_qty := 0;
            end if;
        end if;

        if RT.billmethod = zbill.BM_PLT_CNT_BRK then
            f_qty := ID.pallet_count_total;
        end if;
		
        -- PRN 27015 - need the rounding here so the correct break can be found
        f_qty := round(f_qty,20);
        if RT.calctype = 'U' then
           f_qty := ceil(f_qty);
        elsif RT.calctype = 'D' then
           f_qty := trunc(f_qty);
        else
           f_qty := f_qty;
        end if;
        
        CRB := NULL;
        OPEN C_QTY_BREAKS(RT, f_qty);
        FETCH C_QTY_BREAKS into CRB;
        CLOSE C_QTY_BREAKS;

        if CRB.rate is not null then
            RT.rate := CRB.rate;
        end if;
        if (RT.billmethod = zbill.BM_ORDER_QTY_BREAK) then
          f_qty := 1;
          if (RT.rate = 0) then
            delete invoicedtl
            where rowid = in_rowid;
            return GOOD;
          end if;
        end if;

        if nvl(lrr, 'N') = 'Y' then

            cnt := 0;
            select count(1)
              into cnt
              from LotReceiptCapture
             where code = ID.activity;

            if nvl(cnt,0) > 0 then
            -- Locate the bill_lot_renewal record for this date
                BLR := null;
                OPEN C_BLR(ID.facility, ID.custid, ID.item, ID.lotnumber);
                FETCH C_BLR into BLR;
                CLOSE C_BLR;

                if BLR.custid is not null and 
                   BLR.receiptdate = trunc(ID.activitydate) then
                    update bill_lot_renewal
                      set renewalrate = RT.rate
                     where rowid = BLR.rowid;
                end if;



            end if;
        end if;


    end if;


-- If this is a lot receipt type billing, lookup the lot receipt and use
-- that rate.

    if RT.billmethod in (zbill.BM_QTY_LOT_RCPT, 
                         zbill.BM_WT_LOT_RCPT, zbill.BM_CWT_LOT_RCPT)
    then

        if nvl(lrr, 'N') = 'Y' then


         -- Locate the bill_lot_renewal record for this entry
             BLR := null;
             OPEN C_BLR(ID.facility, ID.custid, ID.item, ID.lotnumber);
             FETCH C_BLR into BLR;
             CLOSE C_BLR;

             if BLR.custid is not null then
                RT.rate := BLR.renewalrate;
                RT.uom := BLR.uom;
             end if;
        end if;


    end if;



 -- translate the uom,qty
    if RT.billmethod in (BM_QTY, BM_QTY_BREAK, BM_QTY_LOT_RCPT) then
        zbut.translate_uom(ID.custid, ID.item, ID.enteredqty, ID.entereduom, 
                RT.uom, f_qty, errmsg);
        if errmsg != 'OKAY' then
           -- out_errmsg := errmsg;
           -- return BAD;
           f_qty := 0;
        end if;
    elsif RT.billmethod = BM_QTYM then
    -- If the detail record already has a MODUOM use it instead of the rate one
       if ID.moduom is not null then
          RT.moduom := ID.moduom;
       end if;

    -- first determine the modulus quantity
        zbut.translate_uom(ID.custid, ID.item, ID.enteredqty, ID.entereduom, 
                  RT.moduom, m_qty, errmsg);
        if errmsg != 'OKAY' then
           m_qty := 0;
        end if;
        qty := trunc(m_qty);

    -- now determine the charge qty to ignore
        zbut.translate_uom(ID.custid, ID.item, qty, RT.moduom, 
                  RT.uom, m_qty, errmsg);
        if errmsg != 'OKAY' then
           m_qty := 0;
        end if;

    -- now determine the full charge qty 
        zbut.translate_uom(ID.custid, ID.item, ID.enteredqty, ID.entereduom, 
                 RT.uom, f_qty, errmsg);
        if errmsg != 'OKAY' then
           f_qty := 0;
        end if;

        f_qty := f_qty - m_qty;

        if f_qty < 0 then
           f_qty := 0;
        end if;

    elsif RT.billmethod in (zbill.BM_CWT, zbill.BM_CWT_BREAK, 
                            zbill.BM_CWT_LOT_RCPT) then
        f_qty := (qty * ITM.weight) / 100;
        f_qty := f_qty + l_tare / 100;
        if (f_qty < 0) then
            f_qty := 0;
        end if;
        RT.uom := 'CWT';
    elsif RT.billmethod in (zbill.BM_WT, zbill.BM_WT_BREAK, 
                            zbill.BM_WT_LOT_RCPT) then
        zbut.translate_uom(ID.custid, ID.item, ID.enteredweight, 
                  'LBS', RT.uom,
                  f_qty, errmsg);
        if errmsg != 'OKAY' then
           f_qty := 0;
        end if;
        f_qty := f_qty + l_tare;
        if (f_qty < 0) then
            f_qty := 0;
        end if;

        -- f_qty := ID.enteredweight;

        itm_weight := ID.enteredweight;
        -- RT.uom := 'WT';
    elsif RT.billmethod = BM_PLT_COUNT then
        f_qty := ID.calcedqty;
        RT.uom := '*PLT';
    elsif RT.billmethod = BM_PLT_CNT_BRK then
        f_qty := ID.calcedqty;
        RT.uom := '*PLT';
    elsif RT.billmethod = BM_PLT_CNT_RCPT then
        f_qty := ID.calcedqty;
        RT.uom := '*PLT';
        
        if (RT.billmethod = BM_PLT_CNT_RCPT) then
          pcbr := NULL;
          OPEN c_pcbr_rate(ID.custid, ID.facility, RT.rategroup, RT.plcb_activity, ID.activitydate);
          FETCH c_pcbr_rate into pcbr;
          if (c_pcbr_rate%notfound) then
            pcbr.rate := RT.rate;
          end if;
          CLOSE c_pcbr_rate;
          
          RT.rate := nvl(pcbr.rate, 0);
        end if;
    elsif RT.billmethod = zbill.BM_LOC_USAGE then
        f_qty := ID.enteredqty;
        -- RT.uom := '';
    elsif RT.billmethod = zbill.BM_FLAT_BREAK then
        f_qty := 1;
        RT.uom := '';
    elsif RT.billmethod  = zbill.BM_FLAT then
        f_qty := nvl(ID.enteredqty,0);
        RT.uom := '';
	elsif RT.billmethod  = zbill.BM_PALLET_BILLING then
        CPR := null;
        open c_custpalletrate(RT, ID.pallettype);
        fetch c_custpalletrate into CPR;
        close c_custpalletrate;
        f_qty := nvl(ID.enteredqty,0);
        RT.rate := CPR.rate;
    elsif RT.billmethod = zbill.BM_HDR_PASSTHRU_MATCH then
        f_qty := nvl(ID.enteredqty,0);
        begin
          v_sql := 'select upper(' || RT.passthru_match || ')
                    from orderhdr
                    where orderid = ' || ID.orderid || ' 
                      and shipid = ' || ID.shipid;
                      
          execute immediate v_sql into v_match_value;
          
          CPT := null;
          open c_custpassthrurate(RT, v_match_value);
          fetch c_custpassthrurate into CPT;
          close c_custpassthrurate;
          
          RT.rate := nvl(CPT.rate,0);
        exception
          when others then
            RT.rate := 0;
        end;
    elsif RT.billmethod = zbill.BM_HDR_PASSTHRU_NUMBER then
        f_qty := nvl(ID.enteredqty,0);
        begin
          v_sql := 'select ' || RT.passthru_number || '
                    from orderhdr
                    where orderid = ' || ID.orderid || ' 
                      and shipid = ' || ID.shipid;
                      
          execute immediate v_sql into v_num_value;
          
          RT.rate := v_num_value;
        exception
          when others then
            RT.rate := 0;
        end;
    elsif RT.billmethod = zbill.BM_ORDER_QTY_BREAK then
      f_qty := 1;
    else
        f_qty := nvl(ID.enteredqty,0);
    end if;

    uom := RT.uom;


 -- Do the rounding as called for in the rate record
    f_qty := round(f_qty,20);
    if RT.calctype = 'U' then
       qty := ceil(f_qty);
    elsif RT.calctype = 'D' then
       qty := trunc(f_qty);
    else
       qty := f_qty;
    end if;


    if strg_prorate then
        RT.rate := (RT.rate * strg_proratepct) / 100.0;
    end if;

    if nvl(RT.apply_carrier_discount_yn,'N') = 'Y' then
	  if nvl(ID.loadno,0) != 0 then
	    begin
		  select carrier
		    into l_carrier
		    from loads
		   where loadno = ID.loadno;
		exception when others then
		  l_carrier := null;
		end;
	  else
	    begin
		  select carrier
		    into l_carrier
		   from orderhdr
		  where orderid = ID.orderid
			and shipid = ID.shipid;
		exception when others then
		  l_carrier := null;
		end;
	  end if;	  
	  if l_carrier is not null then
	    begin
		  select discount
		    into l_carrier_discount
		    from custratecarrierdiscount
		   where custid = RT.custid
		     and rategroup = RT.rategroup
			 and effdate = RT.effdate
			 and activity = RT.activity
			 and billmethod = RT.billmethod
			 and carrier = l_carrier;
		exception when others then
		  l_carrier_discount := 0;
		end;
		if l_carrier_discount != 0 then
		  RT.rate := RT.rate * (100.0 - l_carrier_discount) / 100.0;
		  if remainder(l_carrier_discount, 1) = 0 then
		    l_comment := trim(to_char(l_carrier_discount,'FM999'));
		  else
		    l_comment := trim(to_char(l_carrier_discount,'FM999.99'));
		  end if;
		  l_comment := l_comment || '% discount has been applied';
		  ID.Comment1 := l_comment;
		end if;
	  end if;
	end if;

    amt := RT.rate * qty;

    l_gracedays := RT.gracedays;

    ORD := null;
    OPEN C_ORD(ID.orderid, ID.shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if (nvl(ORD.ordertype, 'R') = 'C')
    and (RT.cxd_grace = 'Y') then
        l_gracedays := RT.cxd_grace_days;
    end if;

    if nvl(l_gracedays,0) > 0 and mincat = 'S' 
     and ID.invtype = IT_RECEIPT and ID.billstatus != zbill.RECALC then
        UPDATE invoicedtl
           SET calcedrate = RT.rate,
               calcedamt = amt,
               calceduom = uom,
               calcedqty = qty,
               expiregrace = trunc(ID.activitydate) + l_gracedays,
               billstatus = UNCHARGED,
               invoice = 0,
               invdate = null,
               weight = itm_weight,
               billmethod = RT.billmethod,
               moduom = RT.moduom,
			   comment1 = ID.comment1
         WHERE rowid = in_rowid;
    else
        UPDATE invoicedtl
           SET calcedrate = RT.rate,
               calcedamt = amt,
               calceduom = uom,
               calcedqty = qty,
               billstatus = decode(billstatus,'E','E',NOT_REVIEWED),
               weight = itm_weight,
               billmethod = RT.billmethod,
               moduom = RT.moduom,
			   comment1 = ID.comment1
         WHERE rowid = in_rowid;
    end if;
    return GOOD;

EXCEPTION WHEN VALUE_TOO_LARGE THEN
  out_errmsg := 'calculate_detail_rate: (VALUE_TOO_LARGE Exception - sqlcode= '||sqlcode||')'||
      '<item= '||ID.item||
      ' enteredweight= '||ID.enteredweight || ' calcedweight= '||itm_weight||
      ' enteredqty= '||ID.enteredqty||' calcedqty= '||qty||
      ' entereduom= '||ID.entereduom||' baseuom= '||ITM.baseuom||
      ' calcedamt= '||amt||'>';      
  zms.log_autonomous_msg('BILLER', ID.facility, ID.custid, out_errmsg, 'E','BILLER', out_logmsg);
  
  UPDATE invoicedtl
     SET calcedrate = 0,
         calcedamt = 0,
         calceduom = ID.entereduom,
         calcedqty = 0,
         weight = 0,
         billstatus = decode(billstatus,'E','E',NOT_REVIEWED)
   WHERE rowid = in_rowid;
   return BAD;
END calculate_detail_rate;

----------------------------------------------------------------------
--
-- get_nextbilldate - determine the next bill date from the billing
--                    cycle information
--
----------------------------------------------------------------------
FUNCTION get_nextbilldate
(
    in_custid       IN      varchar2,
    in_lastbilldate IN      date,
    in_billfreq     IN      varchar2,
    in_billday      IN      number,
    in_billtype     IN      varchar2,
    out_nextbilldate OUT    date
)
RETURN integer
IS
  last_bill_date        DATE;
  wk_date                       DATE;
  work_date             varchar2(12);
  tmp_billday  integer;

  CURSOR C_CRNWL(in_custid varchar2, in_lastdate date, in_type varchar2)
  IS
    SELECT billdate
      FROM custbillschedule
     WHERE custid = in_custid
       AND type = in_type
       AND billdate > nvl(in_lastdate,sysdate)
     ORDER BY billdate;

BEGIN


    last_bill_date := trunc(in_lastbilldate);

    if last_bill_date is null then
    --   last_bill_date := to_date('19990101','YYYYMMDD');
       last_bill_date := trunc(sysdate) - 1;  -- Pretend we just billed
    end if;

    if in_billfreq = 'M' then
        wk_date := add_months(last_bill_date,1);
        work_date := to_char(wk_date, 'YYYYMMDD');
        tmp_billday := to_number(to_char(last_day(wk_date),'DD'));
        if in_billday < tmp_billday then
             tmp_billday := in_billday;
        end if;
        out_nextbilldate := to_date(substr(work_date, 1, 6)
                              || substr(to_char(tmp_billday,'09'),2),
                             'YYYYMMDD');
    elsif in_billfreq = 'E' then
        wk_date := add_months(last_bill_date,1);
        out_nextbilldate := last_day(wk_date);
    elsif in_billfreq = 'W' then
        if in_billday = 1 then
             work_date := 'Monday';
        elsif in_billday = 2 then
             work_date := 'Tuesday';
        elsif in_billday = 3 then
             work_date := 'Wednesday';
        elsif in_billday = 4 then
             work_date := 'Thursday';
        elsif in_billday = 5 then
             work_date := 'Friday';
        elsif in_billday = 6 then
             work_date := 'Saturday';
        else
             work_date := 'Sunday';
        end if;

        out_nextbilldate := next_day(last_bill_date,
                                work_date);
        null;
    elsif in_billfreq = 'D' then
        out_nextbilldate := trunc(sysdate);
    elsif in_billfreq = 'C' then
-- If custom plan use that table to look up
        out_nextbilldate := null;
        OPEN C_CRNWL(in_custid, last_bill_date, in_billtype);
        FETCH C_CRNWL into out_nextbilldate;
        CLOSE C_CRNWL;
        if out_nextbilldate is null then
            out_nextbilldate := trunc(last_bill_date+1);
        end if;
    elsif in_billfreq = 'F' then
-- If custom plan use that table to look up
        out_nextbilldate := null;
        OPEN C_CRNWL(in_custid, last_bill_date, zbill.BT_DEFAULT);
        FETCH C_CRNWL into out_nextbilldate;
        CLOSE C_CRNWL;
        if out_nextbilldate is null then
            out_nextbilldate := trunc(last_bill_date+1);
        end if;
    else
        return BAD;
    end if;

    return GOOD;
END get_nextbilldate;

----------------------------------------------------------------------
--
-- check_for_minimum - find an activity minimum
--
----------------------------------------------------------------------
FUNCTION check_for_minimum
(
    in_custid  IN      varchar2,
    in_rtgrpI  IN      varchar2,       -- Item level rate group to check
    in_rtgrpC  IN      varchar2,       -- Customer level rate group
    in_event   IN      varchar2,       -- Event we are checking
    in_facility IN     varchar2,       -- facility
    in_billm   IN      varchar2,       -- Bill Method we want
    in_actv    IN      varchar2,       -- Activity we need a min for
    in_effdate IN      date,           -- Date for check
    io_rate    IN OUT  custrate%rowtype
)
RETURN integer
IS
  EVNT  custratewhen%rowtype;
BEGIN

-- Check for line level mins
    io_rate := NULL;

    if in_rtgrpI is not null then
       EVNT := null;
       FOR EVNT IN C_RATE_WHEN_ACTV(in_custid, in_rtgrpI, in_event, in_actv,
                             in_facility, in_effdate) loop

       if EVNT.activity = NVL(in_actv,EVNT.activity) then
           for crec in C_RATE(rategrouptype(EVNT.custid,EVNT.rategroup), --????
            EVNT.activity,
             EVNT.billmethod, in_effdate) loop
              if crec.billmethod = in_billm then


                 io_rate := crec;
                 return GOOD;
              end if;
           end loop;
       end if;
       end loop;
    end if;

    if in_rtgrpC is not null then
       EVNT := null;
       FOR EVNT IN C_RATE_WHEN_ACTV(in_custid, in_rtgrpC, in_event, in_actv,
                             in_facility, in_effdate) loop

       if EVNT.activity = NVL(in_actv,EVNT.activity) then
           for crec in C_RATE(rategrouptype(EVNT.custid, EVNT.rategroup), -- ????
            EVNT.activity,
            EVNT.billmethod, in_effdate) loop
              if crec.billmethod = in_billm then
                 io_rate := crec;
                 return GOOD;
              end if;
           end loop;
       end if;
       end loop;
    end if;

    return BAD;

END  check_for_minimum;


----------------------------------------------------------------------
--
-- calc_automatic_charges -
--
----------------------------------------------------------------------
FUNCTION calc_automatic_charges
(
    in_custid   IN      varchar2,
    in_rategrp  IN      varchar2,
    in_event    IN      varchar2,
    ORD         IN      orderhdr%rowtype,
    INVH        IN      invoicehdr%rowtype,
    in_effdate  IN      date
)
RETURN integer
IS
  CUST  customer%rowtype;
  RATE  custrate%rowtype;
  now_date  date;
  l_ucc_label_count pls_integer;
  l_carton_count pls_integer;
  l_plate_count pls_integer;
  v_sql varchar2(300);
  v_match_value varchar2(255);
  v_num_value number;
  v_count number;
  v_order_qty number;
BEGIN

-- Get the customer information
    if rd_customer(in_custid, CUST) = BAD then
       return BAD;
    end if;

    now_date := in_effdate;
     --zut.prt('CUST:'||CUST.custid||' RG:'||in_rategrp
     --    ||' EV:'||in_event||' DT:'||to_char(now_date,'YYYYMMDDHH24MISS'));

-- For the event check for charges
   for crec in C_RATE_WHEN(CUST.custid, in_rategrp,in_event, 
                              INVH.facility, now_date) loop

    --   zut.prt('Found activity'||crec.activity||' BM:'||crec.billmethod);
   -- Get rate entry
      if rd_rate(rategrouptype(crec.custid, crec.rategroup),
                    crec.activity,crec.billmethod,
                    now_date, RATE) = BAD then
          null;
      end if;

      if RATE.billmethod in (BM_QTY, BM_QTYM, BM_FLAT, BM_CWT, BM_WT, 
            BM_QTY_BREAK, BM_FLAT_BREAK, BM_WT_BREAK, BM_CWT_BREAK,
            BM_QTY_LOT_RCPT, BM_WT_LOT_RCPT, BM_CWT_LOT_RCPT,
			BM_UCC_LABELS, BM_PALLET_BILLING, BM_MULT_CTN, BM_LOAD_PLTS,
            BM_HDR_PASSTHRU_MATCH, BM_HDR_PASSTHRU_NUMBER, BM_ORDER_QTY_BREAK) then
		    if RATE.billmethod = BM_UCC_LABELS then
		    begin
			     select count(1)
			       into l_ucc_label_count
				   from caselabels
				  where orderid = ORD.orderid
				    and shipid = ORD.shipid;
	            exception when others then
	              l_ucc_label_count := 0;
		    end;
		    if l_ucc_label_count = 0 then
                      goto continue_charges_loop;
                    end if;
        end if;
        if (RATE.billmethod = BM_ORDER_QTY_BREAK) then
          begin
            select nvl(sum(quantity),0) into v_order_qty
            from shippingplate
            where status = 'SH' and type in ('P','F')
              and orderid = ORD.orderid
              and shipid = ORD.shipid;
          exception 
            when others then
              v_order_qty := 0;
          end;
          if (v_order_qty = 0) then
	    goto continue_charges_loop;
	  end if;
      end if;
       
      if RATE.billmethod = 'MULT' then
        begin
          select count(1)
          into l_carton_count
          from multishipdtl
          where orderid = ORD.orderid and shipid = ORD.shipid
            and status <> 'VOID';
        exception
          when others then
            l_carton_count := 0;
        end;
	  end if;

      if RATE.billmethod = 'LDPL' then
        begin
          select count(1)
          into l_plate_count
          from shippingplate
          where orderid = ORD.orderid and shipid = ORD.shipid
            and type in ('M','C','F')
            and parentlpid is null;
        exception
          when others then
            l_plate_count := 0;
        end;
      end if;

	  if RATE.billmethod = BM_PALLET_BILLING then
    
        delete from pallethistory
        where orderid = ORD.orderid and shipid = ORD.shipid
          and loadno != ORD.loadno;

        for plt in (select pallettype, sum(nvl(outpallets,0)-nvl(inpallets,0)) palletcount
                        from pallethistory
                       where orderid = ORD.orderid
                         and shipid = ORD.shipid
                         and loadno = ORD.loadno
                         and exists 
                             (select 1
                                from custpalletrate
                               where custid = RATE.custid
                                 and rategroup = RATE.rategroup
                                 and effdate = RATE.effdate
                                 and activity = RATE.activity
                                 and billmethod = RATE.billmethod
                                 and pallettype = pallethistory.pallettype)
                       group by pallettype
                      having sum(nvl(outpallets,0)-nvl(inpallets,0)) > 0)
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
               loadno,
               invoice,
               invtype,
               invdate,
               shipid,
               statusrsn,
               lastuser,
               lastupdate,
               pallettype,
               businessevent
            )
            values
            (
               decode(INVH.invstatus,zbill.ESTIMATED,zbill.ESTIMATED,UNCHARGED),
               INVH.facility,
               CUST.custid,
               ORD.orderid,
               NULL,
               NULL,
               RATE.activity,
               now_date,
               RATE.billmethod,
               plt.palletcount,
               RATE.uom,
               0,
               INVH.loadno,
               INVH.invoice,
               INVH.invtype,
               INVH.invdate,
               ORD.shipid,
               decode(INVH.invtype, zbill.IT_RECEIPT, zbill.SR_RECEIPT, 
                                    zbill.IT_ACCESSORIAL, zbill.SR_OUTB,
                                    zbill.IT_STORAGE, zbill.SR_RENEW,
                                    null),
               'BILLER',
               sysdate,
               plt.pallettype,
               in_event
            );
          end loop;
			    goto continue_charges_loop;
        end if;
          
          if RATE.billmethod = BM_HDR_PASSTHRU_MATCH then
            if RATE.passthru_match is null then
              /* Rate record not fully setup, need to know which passthru field */
              --return BAD;
              goto continue_charges_loop;
            end if;
            
            begin
              v_sql := 'select upper(' || RATE.passthru_match || ')
                        from orderhdr
                        where orderid = ' || ORD.orderid || ' 
                          and shipid = ' || ORD.shipid;
                          
              execute immediate v_sql into v_match_value;
              
              select count(1) into v_count
              from custpassthrurate
              where custid = RATE.custid
                and rategroup = RATE.rategroup
                and effdate = RATE.effdate
                and activity = RATE.activity
                and billmethod = RATE.billmethod
                and upper(passthruvalue) = upper(v_match_value);
                
              if v_count = 0 then
                goto continue_charges_loop;
              end if;    
            exception
              when others then
                goto continue_charges_loop;
            end;
          end if;
          
          if RATE.billmethod = BM_HDR_PASSTHRU_NUMBER then
            if RATE.passthru_number is null then
              /* Rate record not fully setup, need to know which passthru field */
              --return BAD;
              goto continue_charges_loop;
            end if;
            
            begin
              v_sql := 'select ' || RATE.passthru_number || '
                        from orderhdr
                        where orderid = ' || ORD.orderid || ' 
                          and shipid = ' || ORD.shipid;
                          
              execute immediate v_sql into v_num_value;
              
              if (v_num_value is null) then
                goto continue_charges_loop;
              end if;
            exception
              when others then
                goto continue_charges_loop;
            end;
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
               shipid,
               statusrsn,
               lastuser,
               lastupdate,
               businessevent
           )
           values
           (
               decode(INVH.invstatus,zbill.ESTIMATED,zbill.ESTIMATED,UNCHARGED),
               INVH.facility,
               CUST.custid,
               ORD.orderid,
               NULL,
               NULL,
               RATE.activity,
               now_date,
               RATE.billmethod,
               decode(crec.automatic,'A',
                      decode(RATE.billmethod,
					         'QTY',0,
					         'FLAT',1,
	                         'FLTB',1,
                             'HPTM',1,
                             'HPTN',1,
					         'UCCL',l_ucc_label_count,
                       'MULT',l_carton_count,
                       'LDPL',l_plate_count,
                          'OQTB',v_order_qty,
					         0),
                      0),
               RATE.uom,
               0, -- jk error
               INVH.loadno,
               INVH.invoice,
               INVH.invtype,
               INVH.invdate,
               ORD.shipid,
               decode(INVH.invtype, zbill.IT_RECEIPT, zbill.SR_RECEIPT, 
                                    zbill.IT_ACCESSORIAL, zbill.SR_OUTB,
                                    zbill.IT_STORAGE, zbill.SR_RENEW,
                                    null),
               'BILLER',
               sysdate,
               in_event
           );
      end if; -- RATE.billmethod in ('QTY','FLAT', 'CWT')
	  << continue_charges_loop >>
	  null;
   end loop;

   return GOOD;

END calc_automatic_charges;


----------------------------------------------------------------------
--
-- approve_invoice -
--
----------------------------------------------------------------------
PROCEDURE approve_invoice
(
    in_invoice  IN      number,
    in_curstat  IN      varchar2,
    in_userid   IN      varchar2,
    out_approved OUT    number,
    out_itms_approved OUT number,
    out_itms_notapproved OUT number,
    out_errmsg  OUT     varchar2
)
IS

  CURSOR C_INVDTL(in_invoice number)
  IS
    SELECT rowid, billstatus, billedqty, billedamt, custid
      FROM invoicedtl
     WHERE invoice = in_invoice;

  CURSOR C_CUST(in_custid char)
  IS
     SELECT approvallimitaccessorial,
            approvallimitmiscellaneous,
            approvallimitreceipt,
            approvallimitrenewal
       FROM customer
      WHERE custid = in_custid;

  CUST C_CUST%rowtype;


INVH invoicehdr%rowtype;

limittype varchar2(40);
limit number;

approved integer;
notapproved integer;
sumapproved integer;
totdetails  integer;
BEGIN

  out_errmsg := 'OKAY';
  approved := 0;
  notapproved := 0;
  sumapproved := 0;
  totdetails := 0;

  out_approved := 0;
  out_itms_approved := 0;
  out_itms_notapproved := 0;

  INVH := NULL;
  OPEN zbill.C_INVH(in_invoice);
  FETCH zbill.C_INVH into INVH;
  CLOSE zbill.C_INVH;

  if INVH.invoice is null then
     out_errmsg := 'Invalid Invoice Number';
     return;
  end if;

  if INVH.invstatus = zbill.BILLED then
     out_errmsg := 'Invalid Invoice. Already billed.';
     return;
  end if;

  if INVH.masterinvoice is not null then
     out_errmsg := 'Invalid Invoice. Currently invoicing.';
     return;
  end if;

-- Get customer approval limits
  CUST := null;
  OPEN C_CUST(INVH.custid);
  FETCH C_CUST into CUST;
  CLOSE C_CUST;

-- determine the limit type
  limit := null;
  if INVH.invtype = zbill.IT_RECEIPT then
      limittype := 'APPROVALLIMITRECEIPT';
      limit := CUST.approvallimitreceipt;
  elsif INVH.invtype = zbill.IT_STORAGE then
      limittype := 'APPROVALLIMITRENEWAL';
      limit := CUST.approvallimitrenewal;
  elsif INVH.invtype = zbill.IT_ACCESSORIAL then
      limittype := 'APPROVALLIMITASSESSORIAL';
      limit := CUST.approvallimitaccessorial;
  elsif INVH.invtype = zbill.IT_MISC then
      limittype := 'APPROVALLIMITMISCELLANEOUS';
      limit := CUST.approvallimitmiscellaneous;
  else
      limittype := 'APPROVALLIMITMISCELLANEOUS';
      limit := CUST.approvallimitmiscellaneous;
  end if;

-- get the default limit if we don't have one set up

  if limit is null then
    BEGIN
      limit := 9999999.99;
      OPEN C_DFLT(limittype);
      FETCH C_DFLT into limit;
    EXCEPTION
      when others then
         limit := 9999999.99;
    END;
    CLOSE C_DFLT;
  end if;

  for crec in C_INVDTL(in_invoice) loop
      totdetails := totdetails + 1;
      if crec.billstatus = in_curstat then
        if (crec.billedamt <= limit and crec.billedqty > 0) or
          in_curstat = zbill.REVIEWED then
          UPDATE invoicedtl
             SET billstatus = decode(in_curstat,
                                 zbill.REVIEWED, zbill.NOT_REVIEWED,
                                 zbill.REVIEWED),
                 statususer = in_userid,
                 statusupdate = sysdate
           WHERE rowid = crec.rowid;
           approved := approved + 1;
        else
           notapproved := notapproved + 1;
           if crec.billedamt > limit then
              out_errmsg := 'Item(s) exceeds approval limit of $'||limit;
           end if;
        end if;
      else
        if crec.billstatus = zbill.UNCHARGED then
            notapproved := notapproved + 1;
        end if;
      end if;
  end loop;

 
  if totdetails > 0 and notapproved = 0 then
    sumapproved := sumapproved + 1;
    UPDATE invoicehdr
       SET invstatus = decode(in_curstat,
                        zbill.REVIEWED, zbill.NOT_REVIEWED,
                        zbill.REVIEWED),
                 statususer = in_userid,
                 statusupdate = sysdate
     WHERE invoice = in_invoice;
  end if;

  if totdetails = 0 then
     out_errmsg := 'No details for invoice';
  end if;

  out_approved := sumapproved;
  out_itms_approved := approved;
  out_itms_notapproved := notapproved;

END approve_invoice;

----------------------------------------------------------------------
--
-- approve_item -
--
----------------------------------------------------------------------
PROCEDURE approve_item
(
    in_rowid    IN      varchar2,
    in_curstat  IN      varchar2,
    in_userid   IN      varchar2,
    out_errmsg  OUT     varchar2
)
IS
ID    invoicedtl%rowtype;
INVH invoicehdr%rowtype;

BEGIN
    out_errmsg := 'OKAY';

  -- Get the invoicedtl row we are working on
    ID := NULL;
    OPEN CINVD_ROWID(in_rowid);
    FETCH CINVD_ROWID into ID;
    CLOSE CINVD_ROWID;

    if ID.BillStatus is null then
     out_errmsg := 'Invoice Detail not found: ' || in_rowid;
     return;
    end if;
    if ID.BillStatus not in ('1','2') then
      return;
    end if;
    INVH := NULL;
    OPEN zbill.C_INVH(ID.invoice);
    FETCH zbill.C_INVH into INVH;
    CLOSE zbill.C_INVH;

    if INVH.invoice is null then
       out_errmsg := 'Invalid Invoice Number';
       return;
    end if;

    if INVH.invstatus = zbill.BILLED then
       out_errmsg := 'Invalid Invoice. Already billed.';
       return;
    end if;

    if INVH.masterinvoice is not null then
       out_errmsg := 'Invalid Invoice. Currently invoicing.';
       return;
    end if;

    UPDATE invoicedtl
       SET billstatus = decode(ID.BillStatus,
                           zbill.REVIEWED, zbill.NOT_REVIEWED,
                           zbill.REVIEWED),
           statususer = in_userid,
           statusupdate = sysdate
     WHERE rowid = chartorowid(in_rowid)
       AND billstatus != zbill.BILLED;

     if ID.BillStatus = zbill.REVIEWED then
        UPDATE invoicehdr
           SET invstatus = zbill.NOT_REVIEWED,
               masterinvoice = null
         WHERE invoice in
          (SELECT invoice
             FROM invoicedtl
            WHERE rowid = chartorowid(in_rowid))
           AND invstatus != zbill.BILLED;
     end if;

END approve_item;

----------------------------------------------------------------------
--
-- approve_multiple_items -
--
----------------------------------------------------------------------
PROCEDURE approve_multiple_items
(
    in_rowids   IN      clob,
    in_userid   IN      varchar2,
    out_errmsg  OUT     varchar2
)
IS
    l_rowids    clob;
    l_count     number;
    l_value     varchar2(50);
	l_userid     varchar2(50);
BEGIN
    out_errmsg := 'OKAY';
    l_rowids := in_rowids;
	l_userid :=  in_userid;
	
    l_rowids := l_rowids || ',';
    l_count := length(in_rowids) - length(replace(l_rowids, ',', ''));

     for i in 1 .. l_count loop
      select regexp_substr(l_rowids,'[^,]+', 1, i)
      into l_value
      from dual;        

	if l_value is not null then
        approve_item(l_value, '', l_userid, out_errmsg);
    end if;    
	  
      if out_errmsg <> 'OKAY' then
    	  exit;
      end if;
    end loop;


END approve_multiple_items;

----------------------------------------------------------------------
--
-- recalc_minimums -
--
----------------------------------------------------------------------
PROCEDURE recalc_minimums
(
    in_invoice  IN      varchar2,
    in_userid   IN      varchar2,
    out_errmsg  OUT     varchar2,
    in_keep_deleted IN  varchar2 default 'N'
)
IS

 INVH  invoicehdr%rowtype;
 INVD  invoicedtl%rowtype;
 CUST  customer%rowtype;
 ORD   orderhdr%rowtype;
 LOAD  loads%rowtype;

 CURSOR C_INVD(in_invoice number)
 RETURN invoicedtl%rowtype
 IS
   SELECT *
     FROM invoicedtl
    WHERE invoice = in_invoice
      AND nvl(orderid,0) > 0;

 CURSOR C_ORDS(in_invoice number)
 IS
   SELECT distinct orderid, shipid
     FROM invoicedtl
    WHERE invoice = in_invoice;

  rc integer;


BEGIN
    INVH := null;
    OPEN C_INVH(in_invoice);
    FETCH C_INVH into INVH;
    CLOSE C_INVH;

    if INVH.invoice is null then
       out_errmsg := 'Invalid billing reference identifier.';
       return;
    end if;

    if INVH.invstatus = zbill.BILLED then
       out_errmsg := 'Invalid Invoice. Already billed.';
       return;
    end if;

    if INVH.masterinvoice is not null then
       out_errmsg := 'Invalid Invoice. Currently invoicing.';
       return;
    end if;

  -- get the customer
    if rd_customer(INVH.custid, CUST) = BAD then
       out_errmsg := 'Customer record does not exist:'||INVH.custid;
       return;
    end if;

  -- get one of the invoice detail lines for testing
    INVD := null;
    OPEN C_INVD(in_invoice);
    FETCH C_INVD into INVD;
    CLOSE C_INVD;


-- Order
    ORD := NULL;
    OPEN zbill.C_ORDHDR(INVD.orderid);
    FETCH zbill.C_ORDHDR into ORD;
    CLOSE zbill.C_ORDHDR;

    if INVH.invtype = IT_RECEIPT then
       LOAD := null;
       OPEN zbill.C_LOAD(ORD.loadno);
       FETCH zbill.C_LOAD into LOAD;
       CLOSE zbill.C_LOAD;
       if LOAD.rcvddate is null then
          LOAD.rcvddate := sysdate;
       end if;

       if ORD.ordertype = 'Q' then
           if zbr.calc_return_minimums(INVH, ORD.orderid, ORD.shipid, 
                          INVH.custid, in_userid, LOAD.rcvddate, 
                                       out_errmsg) = GOOD then
              rc := zbsc.calc_surcharges(INVH, zbill.EV_RETURN ,
                            null,null,in_userid,LOAD.rcvddate,out_errmsg);
              out_errmsg := 'OKAY';
           end if;
       else
           if zbr.calc_receipt_minimums(INVH, ORD.loadno, INVH.custid, 
                          in_userid, LOAD.rcvddate, out_errmsg, in_keep_deleted) = GOOD then
              rc := zbsc.calc_surcharges(INVH, zbill.EV_RECEIPT ,
                            null,null,in_userid,LOAD.rcvddate,out_errmsg);
              out_errmsg := 'OKAY';
           end if;
       end if;
    elsif INVH.invtype = IT_STORAGE then
       if zbs.calc_renewal_minimums(INVH, ORD.orderid, INVH.custid, in_userid,
                   INVH.renewfromdate, out_errmsg) = BAD then
            return;
       end if;
       rc := zbsc.calc_surcharges(INVH, zbill.EV_RENEWAL ,
             null,null,in_userid,INVH.renewfromdate, out_errmsg);

       out_errmsg := 'OKAY';
    elsif INVH.invtype = IT_ACCESSORIAL then
     -- Because can have multiple orders need to do for each order
       for crec in C_ORDS(INVH.invoice) loop
           ORD := null;
           OPEN zbill.C_ORDHDR(crec.orderid);
           FETCH zbill.C_ORDHDR into ORD;
           CLOSE zbill.C_ORDHDR;

           if zba.calc_access_minimums(INVH, crec.orderid, crec.shipid, 
                         INVH.custid, in_userid, nvl(ORD.statusupdate,sysdate),
                         out_errmsg) = BAD then
              return;
           end if;
           rc := zbsc.calc_surcharges(INVH, zbill.EV_SHIP ,
                     crec.orderid, crec.shipid, in_userid, 
                     nvl(ORD.statusupdate,sysdate), out_errmsg);

       end loop;

       rc := zbsc.calc_access_inv_surcharges(INVH, zbill.EV_SHIP ,
            in_userid, INVH.invdate, out_errmsg);
       out_errmsg := 'OKAY';
    elsif (INVH.invtype = IT_MISC or INVH.invtype = IT_CREDIT) then
       rc := zbms.recalc_misc_min_and_srchg(INVH, in_userid, out_errmsg);
       out_errmsg := 'OKAY';
    end if;

    UPDATE invoicehdr
       SET invstatus = decode(invstatus, zbill.ESTIMATED, zbill.ESTIMATED, zbill.NOT_REVIEWED),
           masterinvoice = null
     WHERE invoice = in_invoice;

END recalc_minimums;


----------------------------------------------------------------------
--
-- calc_details -
--
----------------------------------------------------------------------
PROCEDURE calc_details
(
    in_invoice  IN      varchar2,
    in_userid   IN      varchar2,
    out_errmsg  OUT     varchar2
)
IS
  CURSOR C_INVD(in_invoice number)
  IS
    SELECT rowid
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND (billstatus = zbill.UNCHARGED or (invoice < 0 and billstatus = zbill.ESTIMATED));

  INVH  invoicehdr%rowtype;

  now_date date;
  errmsg varchar2(255);

BEGIN
    out_errmsg := 'OKAY';

-- Determine the correct invoice date time
    INVH := null;
    OPEN C_INVH(in_invoice);
    FETCH C_INVH into INVH;
    CLOSE C_INVH;
    
    now_date := nvl(INVH.invdate, sysdate);

-- Calculate the existing uncalculated line items.
    for crec in C_INVD(in_invoice) loop
        errmsg := '';
        if zbill.calculate_detail_rate(crec.rowid, now_date, 
                                    errmsg) = zbill.BAD then
           null;
           --zut.prt('CR: '||errmsg);
        end if;
    end loop;

    update invoicehdr
       set invstatus = decode(invstatus,'E','E',zbill.NOT_REVIEWED),
           masterinvoice = null
     where invoice = in_invoice;

END calc_details;

----------------------------------------------------------------------
--
-- start_misc_invoice -
--
----------------------------------------------------------------------
PROCEDURE start_misc_invoice
(
    in_facility IN      varchar2,
    in_custid   IN      varchar2,
    in_userid   IN      varchar2,
    out_orderid OUT     number,
    out_errmsg  OUT     varchar2
)
IS

 ordid  orderhdr.orderid%type;
 errmsg varchar2(200);

 INVH   invoicehdr%rowtype;

 rc integer;

BEGIN
    out_errmsg := 'OKAY';
    out_orderid := 0;

    zoe.get_next_orderid(ordid, errmsg);
    if substr(errmsg,1,4) != 'OKAY' then
       out_errmsg := errmsg;
       return;
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
        statusupdate,
        entrydate,
        lastupdate,
        lastuser
       )
       values
       (
        ordid,
        in_facility,
        1,
        in_custid,
        'M',
        'A',
        sysdate,
        sysdate,
        sysdate,
        in_userid
       );

    rc := zbill.get_invoicehdr('Create', zbill.IT_MISC, in_custid,
                           in_facility, in_userid, INVH);

    update invoicehdr
       set orderid = ordid
     where invoice = INVH.invoice;

     out_orderid := INVH.invoice;

END start_misc_invoice;


----------------------------------------------------------------------
--
-- start_credit_memo_invoice -
--
----------------------------------------------------------------------
PROCEDURE start_credit_memo_invoice
(
    in_facility IN      varchar2,
    in_custid   IN      varchar2,
    in_userid   IN      varchar2,
    out_orderid OUT     number,
    out_errmsg  OUT     varchar2
)
IS

 ordid  orderhdr.orderid%type;
 errmsg varchar2(200);

 INVH   invoicehdr%rowtype;

 rc integer;

BEGIN
    out_errmsg := 'OKAY';
    out_orderid := 0;

    zoe.get_next_orderid(ordid, errmsg);
    if substr(errmsg,1,4) != 'OKAY' then
       out_errmsg := errmsg;
       return;
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
        statusupdate,
        entrydate,
        lastupdate,
        lastuser
       )
       values
       (
        ordid,
        in_facility,
        1,
        in_custid,
        'M',
        'A',
        sysdate,
        sysdate,
        sysdate,
        in_userid
       );

    rc := zbill.get_invoicehdr('Create', zbill.IT_CREDIT, in_custid,
                           in_facility, in_userid, INVH);

    update invoicehdr
       set orderid = ordid
     where invoice = INVH.invoice;

     out_orderid := INVH.invoice;

END start_credit_memo_invoice;


----------------------------------------------------------------------
--
-- get_next_invoice -
--
----------------------------------------------------------------------
PROCEDURE get_next_invoice
(
    out_invoice OUT     number,
    out_msg     IN OUT  varchar2
)
IS
  CURSOR C_INVOICE
  IS
    SELECT to_number(defaultvalue)
      FROM systemdefaults
     WHERE DEFAULTID = 'invoice'
       FOR UPDATE; -- NOWAIT;

  currcount integer;

BEGIN

    out_msg := 'OKAY';
    out_invoice := null;

    OPEN C_INVOICE;
    FETCH C_INVOICE into currcount;
    CLOSE C_INVOICE;

    out_invoice := currcount;

    UPDATE systemdefaults
       SET defaultvalue = to_char(currcount + 1)
     WHERE defaultid = 'invoice';


exception when others then
  out_msg := sqlerrm;
END get_next_invoice;


----------------------------------------------------------------------
--
-- set_invoice_to_master
--
----------------------------------------------------------------------
PROCEDURE set_invoice_to_master
(
    in_invoice  IN      number,
    out_msg     IN OUT  varchar2
)
IS
BEGIN

   UPDATE invoicehdr
      SET masterinvoice = null,
          invoicedate = null
    WHERE invoice = in_invoice;

out_msg := 'OKAY';

exception when others then
  out_msg := sqlerrm;
END set_invoice_to_master;


----------------------------------------------------------------------
--
-- get_invoice_print_type
--
----------------------------------------------------------------------
PROCEDURE get_invoice_print_type
(
    in_master   IN      varchar2,
    out_print   OUT     varchar2,
    out_msg     IN OUT  varchar2
)
IS
  cnt integer;
BEGIN
   out_msg := 'OKAY';
   if in_master is null then
      out_print := 'INDV';
      return;
   end if;

   cnt := 0;
   SELECT count(1)
     INTO cnt
     FROM invoicehdr
    WHERE masterinvoice = in_master;

   if cnt <= 1 then
      out_print := 'INDV';
      return;
   end if;

   SELECT count(distinct invtype)
     INTO cnt
     FROM invoicehdr
    WHERE masterinvoice = in_master;

   if cnt <= 1 then
      out_print := 'SUM';
   else
       out_print := 'MSTR';
   end if;

END get_invoice_print_type;


----------------------------------------------------------------------
--
-- post_invoice
--
----------------------------------------------------------------------
PROCEDURE post_invoice
(
    in_master   IN      varchar2,
    in_userid   IN      varchar2,
    out_master  OUT     varchar2,
    out_errmsg  OUT     varchar2
)
IS

  CURSOR C_INVTOTAL(in_master varchar2)
  IS
    SELECT H.custid, H.invoicedate, H.facility,
        SUM(nvl(decode(H.invtype,'C',
                  decode(sign(I.billedamt),-1,abs(I.billedamt),0), 
                  decode(sign(I.billedamt),-1,0,abs(I.billedamt))
                    ),0)),
        SUM(nvl(decode(H.invtype,'C',
                  decode(sign(I.billedamt),-1,0,abs(I.billedamt)),
                  decode(sign(I.billedamt),-1,abs(I.billedamt),0) 
                    ),0))
      FROM invoicedtl I, invoicehdr H
     WHERE H.masterinvoice = in_master
       AND H.invoice = I.invoice(+)
       AND I.billstatus(+) != zbill.DELETED
      GROUP BY H.custid, H.invoicedate, H.facility;

  l_custid    varchar2(10);
  l_facility  varchar2(3);
  cr_total number;
  db_total number;

  CURSOR C_INVDTL(in_master varchar2)
  IS
    SELECT I.facility,
           I.activity,
           A.glacct,
           A.descr,
        SUM(nvl(decode(H.invtype,'C',
                  decode(sign(I.billedamt),-1,abs(I.billedamt),0), 
                  decode(sign(I.billedamt),-1,0,abs(I.billedamt))
                    ),0)) db_amount,
        SUM(nvl(decode(H.invtype,'C',
                  decode(sign(I.billedamt),-1,0,abs(I.billedamt)),
                  decode(sign(I.billedamt),-1,abs(I.billedamt),0) 
                    ),0)) cr_amount
      FROM activity A, invoicedtl I, invoicehdr H
     WHERE H.masterinvoice = in_master
       AND I.invoice = H.invoice
       AND A.code = I.activity
       AND I.billstatus != zbill.DELETED
      GROUP BY I.facility, I.activity, A.glacct, A.descr;
   --   HAVING sum(nvl(I.billedamt,0)) != 0;

  CURSOR C_AR
  IS
    SELECT substr(defaultvalue,1,40)
      FROM systemdefaults
     WHERE defaultid = 'AR_ACCOUNT';

  CURSOR C_GETINVTYPE(in_master varchar2)
  IS
    SELECT distinct invtype
      FROM invoicehdr I
     WHERE I.masterinvoice = in_master;

  CURSOR C_CBD(in_custid varchar2)
  RETURN custbilldates%rowtype
  IS
    SELECT *
      FROM custbilldates
     WHERE custid = in_custid;

  CURSOR C_MISC(in_master varchar2)
  IS
    SELECT orderid
      FROM invoicehdr I
     WHERE I.masterinvoice = in_master
       AND invtype in ('M','C');


  CBD custbilldates%rowtype;

  ar_account  varchar2(40);
  invoice_date date;
  post_date date;

    CUST customer%rowtype;

    invoice number;
    master_invoice varchar2(8);

    cnt integer;

BEGIN
  out_errmsg := 'OKAY';

  post_date := sysdate;

  -- Get AR account number
  ar_account := null;
  OPEN C_AR;
  FETCH C_AR into ar_account;
  CLOSE C_AR;
  if ar_account is null then
    ar_account := '**AR_ACCOUNT**';
  end if;


  OPEN C_INVTOTAL(in_master);
  FETCH C_INVTOTAL into l_custid,invoice_date, l_facility, db_total, cr_total;
  CLOSE C_INVTOTAL;

  -- zut.prt('CUSTID:'||l_custid||' Date:'||to_char(invoice_date)||' DB/CR:'||
  --        to_char(db_total)||'/'||to_char(cr_total));

  get_next_invoice(invoice, out_errmsg);
  if substr(out_errmsg,1,4) != 'OKAY' then
    return;
  end if;

    master_invoice := substr(to_char(invoice,'09999999'),2);

    out_master := master_invoice;

  INSERT INTO POSTHDR
              (
                  type,
                  invoice,
                  description,
                  invdate,
                  postdate,
                  custid,
                  amount,
                  lastuser,
                  lastupdate,
                  facility
              )
              values
              (
                  '1',
                  master_invoice,
                  'Post Invoice',
                  invoice_date,
                  post_date,
                  l_custid,
                  db_total - cr_total,
                  in_userid,
                  sysdate,
                  l_facility
              );
   INSERT INTO POSTDTL
              (
                  invoice,
                  account,
                  debit,
                  credit,
                  reference
              )
              VALUES
              (
                  master_invoice,
                  ar_account,
                  db_total,
                  cr_total,
                  'AR Account'
              );


  for crec in C_INVDTL(in_master) loop
      if crec.cr_amount + crec.db_amount != 0 then
         INSERT INTO POSTDTL
              (
                  invoice,
                  account,
                  debit,
                  credit,
                  reference
              )
              VALUES
              (
                  master_invoice,
                  crec.glacct,      -- was prefixed by facility
                  crec.cr_amount,
                  crec.db_amount,
                  substr(crec.descr,1,30)
              );
      end if;
  end loop;

  UPDATE invoicedtl
     SET billstatus = zbill.BILLED
   WHERE invoice in
    (SELECT invoice
       FROM invoicehdr
      WHERE masterinvoice = in_master)
    AND billstatus = zbill.REVIEWED;

  UPDATE invoicehdr
     SET invstatus =  3,
          postdate = post_date,
        masterinvoice = master_invoice
   WHERE masterinvoice = in_master;
 
   CBD := null;
   OPEN C_CBD(l_custid);
   FETCH C_CBD into CBD;
   CLOSE C_CBD;


   for crec in C_MISC(master_invoice) loop
       update orderhdr
          set orderstatus = 'R',
              statusupdate = sysdate,
              statususer = in_userid,
              lastupdate = sysdate,
              lastuser = in_userid
        where orderid = crec.orderid
          and shipid = 1;
   end loop;


  if rd_customer(l_custid, CUST) = zbill.GOOD then
    for crec in C_GETINVTYPE(master_invoice) loop
        if crec.invtype = zbill.IT_STORAGE then
        -- ??? determine renewal date and set last billed to that date
        -- use combo of custlastrenewal and custbilldate and renewals date
        -- (if accessorial is monthly do it each time)
            CUST.rnewlastbilled := invoice_date;

            cnt := 0;
            select count(*)
              into cnt
             from renewalsview
            where custid = l_custid;

            if -- CBD.nextrenewal <= trunc(sysdate) 
             -- and 
				 nvl(cnt,0) = 0
            then

               cnt := 0;
               select count(1)
                 into cnt
                 from invoicehdr
                where custid = CUST.custid
                  and invtype = 'S'
                  and invstatus not in ('3','4')
                  and renewfromdate = CBD.nextrenewal;
               if nvl(cnt,0) = 0 then
                   CUST.prevaccountmin := CUST.lastaccountmin;
                   CUST.lastaccountmin := CBD.nextrenewal;
               end if;
               CBD.lastrenewal := CBD.nextrenewal;
            end if;
        end if;
        if crec.invtype = zbill.IT_RECEIPT then
            CUST.rcptlastbilled := invoice_date;
            if CBD.nextreceipt <= trunc(sysdate) then
               CBD.lastreceipt := CBD.nextreceipt;
            end if;
        end if;
        if crec.invtype = zbill.IT_ACCESSORIAL then
            CUST.outblastbilled := invoice_date;
            if CBD.nextassessorial <= trunc(sysdate) then
               CBD.lastassessorial := CBD.nextassessorial;
            end if;
        end if;
        if crec.invtype = zbill.IT_MISC
        or  crec.invtype = zbill.IT_CREDIT then
            CUST.misclastbilled := invoice_date;
            if CBD.nextmiscellaneous <= trunc(sysdate) then
               CBD.lastmiscellaneous := CBD.nextmiscellaneous;
            end if;
        end if;
    end loop;
    update customer
       set rnewlastbilled = CUST.rnewlastbilled,
           rcptlastbilled = CUST.rcptlastbilled,
           outblastbilled = CUST.outblastbilled,
           misclastbilled = CUST.misclastbilled,
           prevaccountmin = CUST.prevaccountmin,
           lastaccountmin = CUST.lastaccountmin
     where custid = l_custid;


     update custbilldates
        set lastrenewal = CBD.lastrenewal,
            lastreceipt = CBD.lastreceipt,
            lastmiscellaneous = CBD.lastmiscellaneous,
            lastassessorial = CBD.lastassessorial
      where custid = l_custid;

  end if;



END post_invoice;

----------------------------------------------------------------------
--
-- set_invoice_printed
--
----------------------------------------------------------------------
PROCEDURE set_invoice_printed
(
    in_master   IN      varchar2
)
IS
BEGIN
    UPDATE invoicehdr
       SET printdate = sysdate
     WHERE masterinvoice = in_master;

END set_invoice_printed;

----------------------------------------------------------------------
--
-- validate_rate
--
----------------------------------------------------------------------
PROCEDURE validate_rate
(
    in_custid   IN      varchar2,
    in_item     IN      varchar2,
    in_activity IN      varchar2,
    in_billmeth IN      varchar2,
    in_uom      IN      varchar2,
    out_errmsg  OUT     varchar2
)
IS

  CUST  customer%rowtype;
  ITM   custitem%rowtype;

  RATE  custrate%rowtype;
  rategroup rategrouptype; -- customer.rategroup%type;

  errmsg  varchar2(1000);
  qty number;
BEGIN

  out_errmsg := 'OKAY';

  -- get the customer
  if rd_customer(in_custid, CUST) = BAD then
     out_errmsg := 'VR: customer does not exist:'||in_custid;
     return;
  end if;

 -- Get the item for this detail line
  if in_item is null then
     rategroup := zbut.rategroup(CUST.custid,CUST.rategroup);
  else
      if rd_item(in_custid, in_item, ITM) = BAD then
         out_errmsg := 'ITEM does not exist: '||in_custid||'/'||in_item;
         return;
      end if;
      -- rd_item_rategroup(in_custid, in_item, rategroup);
      rategroup := zbut.item_rategroup(in_custid, in_item);
  end if;



  if rd_rate(rategroup,
        in_activity, in_billmeth, sysdate, RATE) = BAD then
     out_errmsg := 'Rate not defined for this activity. Provide rate desired.';
     return;
  end if;

  zbut.translate_uom(in_custid, in_item, 1, in_uom, RATE.uom, qty, errmsg);
  if errmsg != 'OKAY' then
     out_errmsg := 'Can not translate from '|| in_uom ||
                   ' to '|| RATE.uom || ' unit of measure';
     return;
  end if;

END validate_rate;

----------------------------------------------------------------------
--
-- find_rate
--
----------------------------------------------------------------------
PROCEDURE find_rate
(
    in_custid   IN      varchar2,
    in_item     IN      varchar2,
    in_activity IN      varchar2,
    in_billmeth IN      varchar2,
    in_uom      IN      varchar2,
    out_uom     OUT     varchar2,
    out_rate    OUT     number,
    out_errmsg  OUT     varchar2
)
IS

  CUST  customer%rowtype;
  ITM   custitem%rowtype;

  RATE  custrate%rowtype;
  rategroup rategrouptype; -- customer.rategroup%type;

  errmsg  varchar2(1000);
  qty number;
  loc_uom custitem.baseuom%type;

BEGIN

  out_errmsg := 'OKAY';
  out_rate := 0;
  out_uom := null;

  CUST := null;
  ITM := null;

  -- get the customer
  if rd_customer(in_custid, CUST) = BAD then
     out_errmsg := 'Customer does not exist:'||in_custid;
     return;
  end if;

 -- Get the item for this detail line
  if in_item is null then
     rategroup := zbut.rategroup(CUST.custid,CUST.rategroup);
  else
      if rd_item(in_custid, in_item, ITM) = BAD then
         out_errmsg := 'ITEM does not exist: '||in_custid||'/'||in_item;
         return;
      end if;
      -- rd_item_rategroup(in_custid, in_item, rategroup);
      rategroup := zbut.item_rategroup(in_custid, in_item);
  end if;



  if rd_rate(rategroup,
         in_activity, in_billmeth, sysdate, RATE) = BAD then
      if rd_rate(zbut.rategroup(in_custid, CUST.rategroup),
            in_activity, in_billmeth, sysdate, RATE) = BAD then
         out_errmsg := 'Rate not defined for this activity. Provide rate desired.';
         return;
      end if;
  end if;

  loc_uom := rtrim(in_uom);
  if loc_uom is null then
     if in_item is null then
         loc_uom := RATE.uom;
     else
         loc_uom := ITM.baseuom;
     end if;
  end if;

  if in_billmeth in (zbill.BM_QTY, zbill.BM_QTYM, zbill.BM_QTY_BREAK,
                 zbill.BM_FLAT_BREAK, zbill.BM_WT_BREAK, zbill.BM_CWT_BREAK,
                 zbill.BM_QTY_LOT_RCPT, zbill.BM_WT_LOT_RCPT, 
                 zbill.BM_CWT_LOT_RCPT) 
  then
    zbut.translate_uom(in_custid, in_item, 1, loc_uom, RATE.uom, qty, errmsg);
    if errmsg != 'OKAY' then
       out_errmsg := 'Can not translate from '|| in_uom ||
                     ' to '|| RATE.uom || ' unit of measure';
       return;
    end if;
    out_uom := RATE.uom;
  end if;
  out_rate := RATE.rate;

END find_rate;

----------------------------------------------------------------------
--
-- add_asof_inventory
--
----------------------------------------------------------------------
PROCEDURE add_asof_inventory
(
    in_facility IN      varchar2,
    in_custid   IN      varchar2,
    in_item     IN      varchar2,
    in_lotnumber IN     varchar2,
    in_uom      IN      varchar2,
    in_effdate  IN      date,
    in_adjustment IN    number,
    in_adjustweight IN  number,
    in_reason   IN      varchar2,
    in_trantype IN      varchar2,
    in_inventoryclass IN varchar2,
    in_invstatus IN     varchar2,
    in_orderid  IN      number,
    in_shipid   IN      number,
    in_lpid     IN      varchar2,
    in_user     IN      varchar2,
    out_errmsg  OUT     varchar2
)
IS

 CURSOR C_ASOF(in_effdate date)
 IS
   SELECT rowid, effdate, currentqty, nvl(currentweight,0) as currentweight
     FROM asofinventory
    WHERE facility = in_facility
      and custid = in_custid
      and item = in_item
      and nvl(lotnumber, 'XXX') = nvl(in_lotnumber,'XXX')
      and nvl(uom,'XXX') = nvl(in_uom,'XXX')
      and nvl(invstatus,'XXX') = nvl(in_invstatus,'XXX')
      and nvl(inventoryclass,'XXX') = nvl(in_inventoryclass,'XXX')
      and effdate <= trunc(in_effdate)
      order by effdate desc;

 CURSOR C_ASOF_FUTURE(in_effdate date)
 IS
   SELECT rowid, effdate
     FROM asofinventory
    WHERE facility = in_facility
      and custid = in_custid
      and item = in_item
      and nvl(lotnumber, 'XXX') = nvl(in_lotnumber,'XXX')
      and nvl(uom,'XXX') = nvl(in_uom,'XXX')
      and nvl(invstatus,'XXX') = nvl(in_invstatus,'XXX')
      and nvl(inventoryclass,'XXX') = nvl(in_inventoryclass,'XXX')
      and effdate > trunc(in_effdate)
      order by effdate desc;

asof C_ASOF%rowtype;

tr_effdate date;
l_eom      date;
v_max_backdays number;

l_weightadjustment number;
errmsg varchar2(255);
out_logmsg  varchar2(1000);

BEGIN
    out_errmsg := 'OKAY';       -- assume everything will be okay

    tr_effdate := trunc(in_effdate);
    
    if (tr_effdate is null) then
      tr_effdate := trunc(sysdate);
	else
	  BEGIN
		select nvl(max_asof_backdate_days,90)
		  into v_max_backdays
		  from customer_aux
		 where custid = in_custid;
	  EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			v_max_backdays := 90;
	  END;
	  if v_max_backdays > 0 then
		if tr_effdate < (trunc(sysdate) - v_max_backdays) 
		or tr_effdate > (trunc(sysdate) + v_max_backdays) then
			out_errmsg := 'Asof Backdate Error';
			return;
		end if;
	  end if;
    end if;
    
    l_weightadjustment := nvl(in_adjustweight, 0);

   if nvl(in_reason,'xx') != 'EOM Mark' then
-- add entry to the asof detail table
     INSERT INTO asofinventorydtl(
       facility,
       custid,
       item,
       lotnumber,
       uom,
       effdate,
       adjustment,
       weightadjustment,
       reason,
       trantype,
       inventoryclass,
       invstatus,
       orderid,
       shipid,
       lpid,
       lastuser,
       lastupdate
     )
     values (
       in_facility,
       in_custid,
       in_item,
       in_lotnumber,
       in_uom,
       tr_effdate,
       in_adjustment,
       l_weightadjustment,
       in_reason,
       in_trantype,
       in_inventoryclass,
       in_invstatus,
       in_orderid,
       in_shipid,
       in_lpid,
       in_user,
       sysdate
     );

   end if;

-- add/adjust entry to the asof summary table

-- First find out starting point
   asof := null;
   OPEN C_ASOF(tr_effdate);
   FETCH C_ASOF INTO asof;
   CLOSE C_ASOF;

   if asof.effdate = tr_effdate then
    -- If doing EOM mark and already have an EOM entry do not need to
    -- do a bunch of updates for 0 qty
      if nvl(in_reason,'xx') = 'EOM Mark' then
        return;
      end if;

      UPDATE asofinventory
         SET currentqty = currentqty + in_adjustment,
             currentweight = nvl(currentweight,0) + l_weightadjustment,
             lastuser = in_user,
             lastupdate = sysdate
       WHERE rowid = asof.rowid;
      null;
   elsif asof.effdate < tr_effdate then
     INSERT INTO asofinventory(
         facility,
         custid,
         item,
         lotnumber,
         uom,
         effdate,
         inventoryclass,
         invstatus,
         previousqty,
         currentqty,
         previousweight,
         currentweight,
         lastuser,
         lastupdate
     )
     values (
         in_facility,
         in_custid,
         in_item,
         in_lotnumber,
         in_uom,
         tr_effdate,
         in_inventoryclass,
         in_invstatus,
         asof.currentqty,
         asof.currentqty + in_adjustment,
         asof.currentweight,
         asof.currentweight + l_weightadjustment,
         in_user,
         sysdate
     );
   elsif asof.effdate is null then
     INSERT INTO asofinventory(
         facility,
         custid,
         item,
         lotnumber,
         uom,
         effdate,
         inventoryclass,
         invstatus,
         previousqty,
         currentqty,
         previousweight,
         currentweight,
         lastuser,
         lastupdate
     )
     values (
         in_facility,
         in_custid,
         in_item,
         in_lotnumber,
         in_uom,
         tr_effdate,
         in_inventoryclass,
         in_invstatus,
         0,
         in_adjustment,
         0,
         l_weightadjustment,
         in_user,
         sysdate
     );
   end if;

   if nvl(in_adjustment,0) = 0
    and l_weightadjustment = 0 then
        return;
   end if;


-- Now adjust everything in the future
   for crec in C_ASOF_FUTURE(tr_effdate) loop
      UPDATE asofinventory
         SET currentqty = currentqty + in_adjustment,
             previousqty = previousqty + decode(effdate, tr_effdate, 0, in_adjustment),
             currentweight = nvl(currentweight,0) + l_weightadjustment,
             previousweight = nvl(previousweight,0) + decode(effdate, tr_effdate, 0, l_weightadjustment),
             lastuser = in_user,
             lastupdate = sysdate
       WHERE rowid = crec.rowid;
   end loop;


-- Add EOM Marks as needed
   l_eom := last_day(tr_effdate);

   while (l_eom < trunc(sysdate))
   loop
        add_asof_inventory(
            in_facility, in_custid, in_item, in_lotnumber, in_uom, l_eom,
            0,0,'EOM Mark',in_trantype,in_inventoryclass, in_invstatus,
            in_orderid, in_shipid, in_lpid, in_user, errmsg);
		if errmsg != 'OKAY' then
			out_errmsg := errmsg;
			zms.log_msg('add_asof_eommarks', in_facility, in_custid,
             out_errmsg, 'E', in_user, out_logmsg);
			exit;
		end if;

        l_eom := add_months(l_eom, 1);
   end loop;



exception when others then
  out_errmsg := substr(sqlerrm,1,80);
END add_asof_inventory;


----------------------------------------------------------------------
--
-- ship_load_add_asof_old
--
----------------------------------------------------------------------
PROCEDURE ship_load_add_asof_old
(
     in_loadno  IN      number,
     in_userid  IN      varchar2,
     out_errmsg OUT     varchar2
)
IS

  CURSOR C_SHIPPINGPLATE(in_loadno number)
  IS
    SELECT type,status,facility,custid,item,lotnumber,unitofmeasure,
           quantity,weight,inventoryclass,invstatus,orderid,shipid,fromlpid
      FROM SHIPPINGPLATE
     WHERE loadno = in_loadno;

  CURSOR C_CIV(in_custid varchar2, in_item varchar2)
    IS
  SELECT custid, item, lotrequired
    FROM custitemview
   WHERE custid = in_custid
     AND item = in_item;


  CIV C_CIV%rowtype;
  errmsg varchar2(400);

BEGIN
   out_errmsg := 'OKAY';

   CIV := null;

   for crec in C_SHIPPINGPLATE(in_loadno) loop
     if crec.type in ('F','P') and
        crec.status in ('SH') then

       if (nvl(CIV.custid,'aaa') <> crec.custid
        or nvl(CIV.item,'aaa') <> crec.item) then
           OPEN C_CIV(crec.custid, crec.item);
           FETCH C_CIV into CIV;
           CLOSE C_CIV;
       end if;

       if CIV.lotrequired = 'P' then
          crec.lotnumber := null;
       end if;

       zbill.add_asof_inventory(
           crec.facility,
           crec.custid,
           crec.item,
           crec.lotnumber,
           crec.unitofmeasure,
           trunc(sysdate),
           - crec.quantity,
           - crec.weight,
           'Shipped',
           'SH',
           crec.inventoryclass,
           crec.invstatus,
           crec.orderid,
           crec.shipid,
           crec.fromlpid,
           in_userid,
           out_errmsg
       );
       if(out_errmsg <> 'OKAY') then
          zms.log_msg('add_asof_old', crec.facility, crec.custid,
             out_errmsg, 'E', in_userid, errmsg);
       end if;
     end if;
   end loop;

END ship_load_add_asof_old;

----------------------------------------------------------------------
--
-- ship_load_add_asof
--
----------------------------------------------------------------------
PROCEDURE ship_load_add_asof
(
     in_loadno  IN      number,
     in_shipdate IN     date,
     in_userid  IN      varchar2,
     out_errmsg OUT     varchar2
)
IS

  CURSOR C_SHIPPINGPLATE(in_loadno number)
  IS
    SELECT type,status,facility,custid,item,lotnumber,unitofmeasure,
           quantity,weight,inventoryclass,invstatus,orderid,shipid,fromlpid
      FROM SHIPPINGPLATE
     WHERE loadno = in_loadno;

  CURSOR C_CIV(in_custid varchar2, in_item varchar2)
    IS
  SELECT custid, item, lotrequired
    FROM custitemview
   WHERE custid = in_custid
     AND item = in_item;


  CIV C_CIV%rowtype;
  errmsg varchar2(400);

BEGIN
   out_errmsg := 'OKAY';

   CIV := null;

   for crec in C_SHIPPINGPLATE(in_loadno) loop
     if crec.type in ('F','P') and
        crec.status in ('SH') then

       if (nvl(CIV.custid,'aaa') <> crec.custid
        or nvl(CIV.item,'aaa') <> crec.item) then
           OPEN C_CIV(crec.custid, crec.item);
           FETCH C_CIV into CIV;
           CLOSE C_CIV;
       end if;

       if CIV.lotrequired = 'P' then
          crec.lotnumber := null;
       end if;

       zbill.add_asof_inventory(
           crec.facility,
           crec.custid,
           crec.item,
           crec.lotnumber,
           crec.unitofmeasure,
           trunc(nvl(in_shipdate,sysdate)),
           - crec.quantity,
           - crec.weight,
           'Shipped',
           'SH',
           crec.inventoryclass,
           crec.invstatus,
           crec.orderid,
           crec.shipid,
           crec.fromlpid,
           in_userid,
           out_errmsg
       );
       if(out_errmsg <> 'OKAY') then
          zms.log_msg('shp_add_asof', crec.facility, crec.custid,
             out_errmsg, 'E', in_userid, errmsg);
       end if;
     end if;
   end loop;

   if trunc(sysdate) > trunc(in_shipdate) then
        zbs.adjust_agginv_ship_renewal(in_loadno, trunc(in_shipdate),
            in_userid, out_errmsg);
   end if;


END ship_load_add_asof;

----------------------------------------------------------------------
--
-- receipt_load_add_asof
--
----------------------------------------------------------------------
PROCEDURE receipt_load_add_asof
(
     in_loadno  IN      number,
     in_arrived IN      date,
     in_userid  IN      varchar2,
     out_errmsg OUT     varchar2
)
IS
  CURSOR C_PLATE(in_loadno number) IS
    SELECT *
      FROM PLATE
     WHERE status not in ('P','U', 'D')
       AND TYPE = 'PA'
       AND loadno = in_loadno;

  CURSOR C_QTY(in_loadno number)
  IS
    SELECT OD.facility, OD.custid, OD.item, OD.lotnumber, OD.uom unitofmeasure,
           OD.inventoryclass, OD.invstatus, OD.orderid, OD.shipid, OD.lpid,
           sum(OD.qtyrcvd) quantity,
           sum(OD.weight) weight
      FROM orderdtlrcpt OD, orderhdr OH
     WHERE OH.loadno = in_loadno
       AND OD.orderid = OH.orderid
       AND OD.shipid  = OH.shipid
      GROUP BY 
           OD.facility, OD.custid, OD.item, OD.lotnumber, OD.uom,
           OD.inventoryclass, OD.invstatus, OD.orderid, OD.shipid,
           OD.lpid;

errmsg varchar2(400);

BEGIN
   out_errmsg := 'OKAY';

   for crec in C_QTY(in_loadno) loop -- was C_PLATE
       zbill.add_asof_inventory(
           crec.facility,
           crec.custid,
           crec.item,
           crec.lotnumber,
           crec.unitofmeasure,
           trunc(in_arrived),
           crec.quantity,
           crec.weight,
           'Received',
           'RC',
           crec.inventoryclass,
           crec.invstatus,
           crec.orderid,
           crec.shipid,
           crec.lpid,
           in_userid,
           out_errmsg
       );
       if(out_errmsg <> 'OKAY') then
          zms.log_msg('rcp_add_asof', crec.facility, crec.custid,
             out_errmsg, 'E', in_userid, errmsg);
       end if;
   end loop;

END receipt_load_add_asof;

----------------------------------------------------------------------
--
-- receipt_load_remove_asof
--
----------------------------------------------------------------------
PROCEDURE receipt_load_remove_asof
(
     in_loadno  IN      number,
     in_arrived IN      date,
     in_userid  IN      varchar2,
     out_errmsg OUT     varchar2
)
IS

  CURSOR C_QTY(in_loadno number)
  IS
    SELECT OD.facility, OD.custid, OD.item, OD.lotnumber, OD.uom unitofmeasure,
           OD.inventoryclass, OD.invstatus, OD.orderid, OD.shipid, OD.lpid,
           sum(OD.qtyrcvd) quantity,
           sum(OD.weight) weight
      FROM orderdtlrcpt OD, orderhdr OH
     WHERE OH.loadno = in_loadno
       AND OD.orderid = OH.orderid
       AND OD.shipid  = OH.shipid
      GROUP BY 
           OD.facility, OD.custid, OD.item, OD.lotnumber, OD.uom,
           OD.inventoryclass, OD.invstatus, OD.orderid, OD.shipid,
           OD.lpid;

errmsg varchar2(400);

BEGIN
   out_errmsg := 'OKAY';

   for crec in C_QTY(in_loadno) loop
       zbill.add_asof_inventory(
           crec.facility,
           crec.custid,
           crec.item,
           crec.lotnumber,
           crec.unitofmeasure,
           trunc(in_arrived),
           -crec.quantity,
           -crec.weight,
           'Reopen Rcpt',
           'RR',
           crec.inventoryclass,
           crec.invstatus,
           crec.orderid,
           crec.shipid,
           crec.lpid,
           in_userid,
           out_errmsg
       );
       if(out_errmsg <> 'OKAY') then
          zms.log_msg('remove_asof', crec.facility, crec.custid,
             out_errmsg, 'E', in_userid, errmsg);
       end if;
   end loop;

END receipt_load_remove_asof;

----------------------------------------------------------------------
--
-- receipt_prodorder_add_asof
--
----------------------------------------------------------------------
PROCEDURE receipt_prodorder_add_asof
(
     in_orderid  IN      number,
     in_shipid  IN      number,
     in_userid  IN      varchar2,
     out_errmsg OUT     varchar2
)
IS
  CURSOR C_QTY(in_orderid number, in_shipid number)
  IS
    SELECT OD.facility, OD.custid, OD.item, OD.lotnumber, OD.uom unitofmeasure,
           OD.inventoryclass, OD.invstatus, OD.orderid, OD.shipid, OD.lpid,
           sum(OD.qtyrcvd) quantity,
           sum(OD.weight) weight
      FROM orderdtlrcpt OD, orderhdr OH
     WHERE OH.orderid = in_orderid and OH.shipid = in_shipid
       AND OD.orderid = OH.orderid
       AND OD.shipid  = OH.shipid
      GROUP BY 
           OD.facility, OD.custid, OD.item, OD.lotnumber, OD.uom,
           OD.inventoryclass, OD.invstatus, OD.orderid, OD.shipid,
           OD.lpid;

errmsg varchar2(400);
v_max_cd1 date;
v_max_cd2 date;

BEGIN
   out_errmsg := 'OKAY';

   for crec in C_QTY(in_orderid, in_shipid) loop
   
       begin
          select max(nvl(creationdate,sysdate)) into v_max_cd1
          from plate
          where type = 'PA'
            and orderid = in_orderid and shipid = in_shipid;
       exception
          when others then
            v_max_cd1 := sysdate;
       end;
       
       begin
          select max(nvl(creationdate,sysdate)) into v_max_cd1
          from deletedplate
          where type = 'PA'
            and orderid = in_orderid and shipid = in_shipid;
       exception
          when others then
            v_max_cd2 := sysdate;
       end;
       
       zbill.add_asof_inventory(
           crec.facility,
           crec.custid,
           crec.item,
           crec.lotnumber,
           crec.unitofmeasure,
           trunc(greatest(v_max_cd1, v_max_cd2)),
           crec.quantity,
           crec.weight,
           'Received',
           'RC',
           crec.inventoryclass,
           crec.invstatus,
           crec.orderid,
           crec.shipid,
           crec.lpid,
           in_userid,
           out_errmsg
       );
       if(out_errmsg <> 'OKAY') then
          zms.log_msg('rcp_add_asof', crec.facility, crec.custid,
             out_errmsg, 'E', in_userid, errmsg);
       end if;
   end loop;

END receipt_prodorder_add_asof;

----------------------------------------------------------------------
--
-- set_asofinventory_eom
--
----------------------------------------------------------------------
PROCEDURE set_asofinventory_eom
(
    in_eom      IN      date, 
    in_userid   IN      varchar2, 
    out_errmsg  OUT     varchar2
)
IS
l_eom date;
l_cutoff date;
errmsg varchar2(255);
out_logmsg varchar2(1000);
BEGIN
    out_errmsg := 'OKAY';

    l_eom := trunc(in_eom);

    if to_char(l_eom+1,'DD') != '01' then
        out_errmsg := 'Not EOM date';
        return;
    end if;

    l_cutoff := add_months(l_eom, -1);

    for cf in (select distinct facility, custid
                 from asofinventory
                where effdate >= l_cutoff)
    loop
-- Add the temp table information
        delete from asofeffdate_temp;

        insert into asofeffdate_temp
            select item, nvl(lotnumber,'(none)'),uom,invstatus,inventoryclass,
                max(effdate)
              from asofinventory
             where facility = cf.facility
               and custid = cf.custid
               and effdate <= l_eom
               and effdate >= l_cutoff
            group by item, nvl(lotnumber,'(none)'),uom,invstatus,inventoryclass;


        for ci in (
            SELECT item,lotnumber, uom, invstatus, inventoryclass, 
                    currentqty qty, currentweight weight
              FROM asofinventory A
             WHERE A.facility = cf.facility
               AND A.custid = cf.custid
               AND A.currentqty != 0
               AND (A.item, nvl(A.lotnumber,'(none)'), uom, invstatus, inventoryclass,
                A.effdate) in
                    (select item, lotnumber, uom, invstatus, inventoryclass,
                    effdate from asofeffdate_temp))
        loop
            zbill.add_asof_inventory(
                cf.facility, cf.custid, ci.item, ci.lotnumber,ci.uom, l_eom,
                0,0, 'EOM Mark', 'EM', ci.inventoryclass, ci.invstatus,
                null, null, null, 'SYNAPSE', out_errmsg);
			if out_errmsg != 'OKAY' then
				zms.log_autonomous_msg('BILLER', cf.facility, cf.custid, out_errmsg, 'I','BILLER', out_logmsg);
				exit;
			end if;

        end loop;


    end loop;



EXCEPTION WHEN OTHERS THEN
    out_errmsg := sqlerrm;
END set_asofinventory_eom;

----------------------------------------------------------------------
--
-- delete_invoice -
--
----------------------------------------------------------------------
PROCEDURE delete_invoice
(
    in_invoice  IN      number,
    in_curstat  IN      varchar2,
    in_userid   IN      varchar2,
    out_errmsg  OUT     varchar2
)
IS

  CURSOR C_INVDTL(in_invoice number)
  IS
    SELECT rowid, billstatus, billedamt
      FROM invoicedtl
     WHERE invoice = in_invoice;

INVH invoicehdr%rowtype;

BEGIN

  out_errmsg := 'OKAY';

  INVH := NULL;
  OPEN zbill.C_INVH(in_invoice);
  FETCH zbill.C_INVH into INVH;
  CLOSE zbill.C_INVH;

  if INVH.invoice is null then
     out_errmsg := 'Invalid Invoice Number';
     return;
  end if;

  if INVH.invstatus = zbill.BILLED then
     out_errmsg := 'Invalid Invoice. Already billed.';
     return;
  end if;

  if INVH.masterinvoice is not null then
     out_errmsg := 'Invalid Invoice. Currently invoicing.';
     return;
  end if;

  if INVH.invtype != zbill.IT_MISC and INVH.invtype != zbill.IT_CREDIT then
     out_errmsg := 'Only Miscellaneous invoices can be deleted.';
     return;
  end if;

  for crec in C_INVDTL(in_invoice) loop
      if crec.billstatus = in_curstat then
          UPDATE invoicedtl
             SET billstatus = decode(in_curstat,
                                 zbill.DELETED, zbill.NOT_REVIEWED,
                                 zbill.DELETED),
                 statususer = in_userid,
                 statusupdate = sysdate
           WHERE rowid = crec.rowid;
      end if;
  end loop;

  UPDATE invoicehdr
     SET invstatus = decode(in_curstat,
                      zbill.DELETED, zbill.NOT_REVIEWED,
                      zbill.DELETED)
   WHERE invoice = in_invoice;

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
      decode(in_curstat, zbill.DELETED, 'CHUG','CHDL'),
      sysdate,
      INVH.facility,
      INVH.custid,
      null,
      null,
      decode(in_curstat, zbill.DELETED, 'Undeleted','Deleted')
        ||' billing charges for Reference:'||to_char(in_invoice)
  );

END delete_invoice;

----------------------------------------------------------------------
--
-- delete_item -
--
----------------------------------------------------------------------
PROCEDURE delete_item
(
    in_rowid    IN      varchar2,
    in_curstat  IN      varchar2,
    in_userid   IN      varchar2,
    out_errmsg  OUT     varchar2
)
IS

ID    invoicedtl%rowtype;
INVH invoicehdr%rowtype;
l_curstat  varchar(1);
BEGIN
    out_errmsg := 'OKAY';
    l_curstat  := in_curstat;

  -- Get the invoicedtl row we are working on
    ID := NULL;
    OPEN CINVD_ROWID(in_rowid);
    FETCH CINVD_ROWID into ID;
    CLOSE CINVD_ROWID;

    INVH := NULL;
    OPEN zbill.C_INVH(ID.invoice);
    FETCH zbill.C_INVH into INVH;
    CLOSE zbill.C_INVH;

    if INVH.invoice is null then
       out_errmsg := 'Invalid Invoice Number';
       return;
    end if;

    if INVH.invstatus = zbill.BILLED then
       out_errmsg := 'Invalid Invoice. Already billed.';
       return;
    end if;

    if INVH.masterinvoice is not null then
       out_errmsg := 'Invalid Invoice. Currently invoicing.';
       return;
    end if;

    if l_curstat = '' then
      l_curstat := ID.billstatus;
    end if;
    
    -- if NVL(ID.statusrsn,'XXX') != zbill.SR_MISC then
    --   out_errmsg := 'Only detail info entered by an operator can be deleted.';
    --   return;
    -- end if;

    UPDATE invoicedtl
       SET billstatus = decode(ID.billstatus,
                           zbill.DELETED, decode(INVH.invstatus, zbill.ESTIMATED, zbill.ESTIMATED, zbill.NOT_REVIEWED),
                           zbill.DELETED),
           statususer = in_userid,
           statusupdate = sysdate
     WHERE rowid = chartorowid(in_rowid);

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
        decode(l_curstat, zbill.DELETED, 'CHUG','CHDL'),
        sysdate,
        ID.facility,
        ID.custid,
        null,
        null,
        decode(ID.billstatus, zbill.DELETED, 'Undeleted','Deleted')
          ||' billing charge for Reference:'||to_char(ID.invoice)
          ||' Activity:'||ID.activity||' Amount:'||to_char(ID.billedamt,'99999.99')
    );

     if ID.billstatus = zbill.DELETED then
        UPDATE invoicehdr
           SET invstatus = decode(invstatus, zbill.ESTIMATED, zbill.ESTIMATED, zbill.NOT_REVIEWED),
               masterinvoice = null
         WHERE invoice = ID.invoice;
     end if;

END delete_item;

----------------------------------------------------------------------
--
-- delete_multiple_items -
--
----------------------------------------------------------------------
PROCEDURE delete_multiple_items
(
    in_rowids   IN      clob,
    in_userid   IN      varchar2,
    out_errmsg  OUT     varchar2
)
IS
    l_rowids    clob;
    l_count     number;
    l_value     varchar2(50);
BEGIN
    out_errmsg := 'OKAY';
    l_rowids := in_rowids;
    l_rowids := l_rowids || ',';
    l_count := length(in_rowids) - length(replace(l_rowids, ',', ''));
    for i in 1 .. l_count
    loop 
      select regexp_substr(l_rowids,'[^,]+', 1, i)
      into l_value
      from dual;      

      if l_value is not null then
        delete_item(l_value, '', in_userid, out_errmsg);
      end if;
      
      if out_errmsg <> 'OKAY' then
        exit;
      end if;
    end loop;
    
  
END delete_multiple_items;

----------------------------------------------------------------------
--
-- set_custbilldates
--
----------------------------------------------------------------------
PROCEDURE set_custbilldates
(
    in_custid   IN      varchar2,
    in_userid   IN      varchar2,
    out_errmsg  OUT     varchar2
)
IS
  CURSOR C_CBD(in_custid varchar2)
  RETURN custbilldates%rowtype
  IS
    SELECT *
      FROM custbilldates
     WHERE custid = in_custid;

  CUST customer%rowtype;
  CBD custbilldates%rowtype;

  cnt integer;
BEGIN

   out_errmsg := 'OKAY';

-- Read the customer information
    CUST := null;
    if rd_customer(in_custid, CUST) = BAD then
       out_errmsg := 'SC: customer does not exist:'||in_custid;
       return;
    end if;

-- Read current custbilldates information
    CBD := null;
    OPEN C_CBD(in_custid);
    FETCH C_CBD into CBD;
    CLOSE C_CBD;

-- If the record doesn;t exist create an empty one
    if CBD.custid is null then
       INSERT INTO custbilldates(
              custid,
              nextrenewal,
              nextreceipt,
              nextmiscellaneous,
              nextassessorial,
              lastrenewal,
              lastreceipt,
              lastmiscellaneous,
              lastassessorial,
              lastuser,
              lastupdate
          )
       VALUES (
              in_custid,
              CUST.rnewlastbilled,
              CUST.rcptlastbilled,
              CUST.misclastbilled,
              CUST.outblastbilled,
              CUST.rnewlastbilled,
              CUST.rcptlastbilled,
              CUST.misclastbilled,
              CUST.outblastbilled,
              in_userid,
              sysdate
          );
       OPEN C_CBD(in_custid);
       FETCH C_CBD into CBD;
       CLOSE C_CBD;
    end if;


-- Determine the next bill dates for each category
   if get_nextbilldate(CUST.custid, nvl(CBD.lastrenewal,CUST.rnewlastbilled), 
                       CUST.rnewbillfreq,
                       CUST.rnewbillday,
                       zbill.BT_RENEWAL, 
                       CBD.nextrenewal) = zbill.BAD then
      CBD.nextrenewal := trunc(sysdate);
   end if;

   cnt := 0;
   if CBD.nextreceipt < trunc(sysdate) then
    CBD.lastreceipt := CBD.nextreceipt;
   end if;
   loop
    if get_nextbilldate(CUST.custid, nvl(CBD.lastreceipt,CUST.rcptlastbilled), 
                       CUST.rcptbillfreq,
                       CUST.rcptbillday, 
                       zbill.BT_RECEIPT, 
                       CBD.nextreceipt) = zbill.BAD then
      CBD.nextreceipt := trunc(sysdate);
    end if;
    exit when CBD.nextreceipt >= trunc(sysdate);
    CBD.lastreceipt := CBD.nextreceipt;
    cnt := cnt + 1;
    if cnt > 52 then
        exit;
    end if;
   end loop;

   cnt := 0;
   if CBD.nextmiscellaneous < trunc(sysdate) then
    CBD.lastmiscellaneous := CBD.nextmiscellaneous;
   end if;
   loop
    if get_nextbilldate(CUST.custid, nvl(CBD.lastmiscellaneous,CUST.misclastbilled), 
                       CUST.miscbillfreq,
                       CUST.miscbillday, 
                       zbill.BT_MISC, 
                       CBD.nextmiscellaneous) = zbill.BAD then
      CBD.nextmiscellaneous := trunc(sysdate);
    end if;
    exit when CBD.nextmiscellaneous >= trunc(sysdate);
    CBD.lastmiscellaneous := CBD.nextmiscellaneous;
    cnt := cnt + 1;
    if cnt > 52 then
        exit;
    end if;
   end loop;

   cnt := 0;
   if CBD.nextassessorial < trunc(sysdate) then
    CBD.lastassessorial := CBD.nextassessorial;
   end if;
   loop
    if get_nextbilldate(CUST.custid, nvl(CBD.lastassessorial,CUST.outblastbilled), 
                       CUST.outbbillfreq,
                       CUST.outbbillday,
                       zbill.BT_MISC, 
                       CBD.nextassessorial) = zbill.BAD then
      CBD.nextassessorial := trunc(sysdate);
    end if;
    exit when CBD.nextassessorial >= trunc(sysdate);
    CBD.lastassessorial := CBD.nextassessorial;
    cnt := cnt + 1;
    if cnt > 52 then
        exit;
    end if;
   end loop;

   UPDATE custbilldates
      SET nextrenewal = CBD.nextrenewal,
          nextreceipt = CBD.nextreceipt,
          nextmiscellaneous = CBD.nextmiscellaneous,
          nextassessorial = CBD.nextassessorial,
          lastreceipt = CBD.lastreceipt,
          lastmiscellaneous = CBD.lastmiscellaneous,
          lastassessorial = CBD.lastassessorial,
          lastrenewal = CBD.lastrenewal,
          lastuser = in_userid,
          lastupdate = sysdate
    WHERE custid = in_custid;



-- Check for skipped renewal cycle needing advancement
   if (CUST.rnewlastbilled is not null)
    and (CBD.lastrenewal is not null)
    and trunc(sysdate) > CBD.nextrenewal then
      cnt := 0;
      select count(1)
        into cnt
        from invoicehdr
       where custid = CUST.custid
         and invtype = 'S'
         and renewfromdate = CBD.nextrenewal;

      if nvl(cnt,0) = 0 then

        cnt := 0;
        select count(1)
          into cnt
          from renewalsview
         where custid = CUST.custid;

        if nvl(cnt,0) = 0 then
            -- zut.prt('Found one to check:'||CUST.custid
            --       ||' Date:'|| to_char(CBD.nextrenewal,'YYYYMMDD'));
            CBD.lastrenewal := CBD.nextrenewal;
            UPDATE custbilldates
               SET lastrenewal = CBD.lastrenewal,
                   lastuser = in_userid,
                   lastupdate = sysdate
             WHERE custid = in_custid;
        end if;
      end if;
   end if;




END set_custbilldates;


----------------------------------------------------------------------
--
-- check_month_end - verify we can do a month end
--
----------------------------------------------------------------------
FUNCTION check_month_end
(
    in_month_end IN      date,          -- proposed month end date
    in_force     IN      varchar2,
    in_userid    IN      varchar2,
    io_errmsg  IN OUT  varchar2
)
RETURN integer
IS
  tdate date;   -- Make sure the date is truncated

  CURSOR C_RCPTS(in_effdate date)
  IS
    SELECT count(*)
      FROM loads L, orderhdr O
     WHERE O.ordertype in ('R','C')
       AND O.orderstatus = 'A'
       AND O.loadno = L.loadno
       AND L.rcvddate <= in_effdate;

  CURSOR C_RNWL(in_effdate date)
  IS
    SELECT count(*)
      FROM custbilldates
     WHERE nextrenewal < in_effdate;

  CURSOR C_INVD(in_effdate date)
  IS
    SELECT count(*)
      FROM invoicedtl
     WHERE activitydate < in_effdate
       AND billstatus not in ('3','4');   -- ignore billed and deleted

  CURSOR C_ACCT_PERIOD
  IS
    SELECT MAX(cutoffdate)
      FROM accountperiod;

  ap_date date;
  rc integer;
BEGIN


-- Assume we are going to be OKAY.
    io_errmsg := 'OKAY';

    tdate := trunc(in_month_end);

    if tdate > trunc(sysdate) then
        io_errmsg := 'Can not close for a future date.';
        return zbill.BAD;
    end if;

--  Verify we can end the month with all checks in place
--  Verify date later than the latest existing date
    ap_date := null;
    OPEN C_ACCT_PERIOD;
    FETCH C_ACCT_PERIOD INTO ap_date;
    CLOSE C_ACCT_PERIOD;

    if tdate <= ap_date then
        io_errmsg := 'The previous close was '||to_char(ap_date,'MM-DD-YYYY')
           ||'. Try a later date.';
        return zbill.BAD;
    end if;

--  Check that there are no open receipts arrived before the month end date
    rc := 0;
    OPEN C_RCPTS(tdate);
    FETCH C_RCPTS into rc;
    CLOSE C_RCPTS;

    if rc > 0 then
        if nvl(in_force,'N') = 'Y' then
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
                'ACOV',
                sysdate,
                null,
                null,
                null,
                null,
                'Force accounting close for '||
                to_char(tdate, 'YYYYMMDD') ||
                ', with open receipts = '||to_char(rc)
            );
        else
            io_errmsg := 'There are '||to_char(rc)||
                  ' receipts arrived before '||
                  to_char(tdate,'MM-DD-YYYY')||' that have not been closed.';
            return zbill.BAD;
        end if;
    end if;

--  Check that all customers have been billed in the time period
    rc := 0;
    OPEN C_RNWL(tdate);
    FETCH C_RNWL into rc;
    CLOSE C_RNWL;

    if rc > 0 then
        if nvl(in_force,'N') = 'Y' then
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
                'ACOV',
                sysdate,
                null,
                null,
                null,
                null,
                'Force accounting close for '||
                to_char(tdate, 'YYYYMMDD') ||
                ', with open renewals = '||to_char(rc)
            );
        else
            io_errmsg := 'There are '||to_char(rc)||' renewals due before '||
                  to_char(tdate,'MM-DD-YYYY')||' that have not been completed.';
            return zbill.BAD;
        end if;
    end if;

-- Check all charges have been billed or completed
    rc := 0;
    OPEN C_INVD(tdate);
    FETCH C_INVD into rc;
    CLOSE C_INVD;

    if rc > 0 then
        if nvl(in_force,'N') = 'Y' then
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
                'ACOV',
                sysdate,
                null,
                null,
                null,
                null,
                'Force accounting close for '||
                to_char(tdate, 'YYYYMMDD') ||
                ', with open charges = '||to_char(rc)
            );
        else
           io_errmsg := 'There are '||to_char(rc)||' Charges '||
                  to_char(tdate,'MM-DD-YYYY')||' that have not been billed.';
           return zbill.BAD;
        end if;
    end if;

-- INSERT the accountperiod table entry
   INSERT into accountperiod(
        cutoffdate,
        lastuser,
        lastupdate
   )
   VALUES (
       tdate,
       in_userid,
       sysdate
   );

    return zbill.GOOD;

END check_month_end;

----------------------------------------------------------------------
--
-- get_test_invoiceid - get next test invoice id
--
----------------------------------------------------------------------
PROCEDURE get_test_invoiceid
(
    out_invoiceid   OUT varchar2
)
IS
 currnum integer;
 currid varchar2(8);
 cnt integer;
BEGIN

currid := null;


while (currid is null) loop

  select tempinvseq.nextval
    into currnum
    from dual;
  currid := 'TEST'||substr(to_char(currnum,'0999'),2);

  cnt := 0;
  select count(1)
    into cnt
    from invoicehdr
   where masterinvoice = currid;
 if cnt > 0 then
   currid := null;
 end if;

end loop;

out_invoiceid := currid;

END get_test_invoiceid;


----------------------------------------------------------------------
--
-- release_session
--
----------------------------------------------------------------------
FUNCTION release_session
(
    in_userid   IN  varchar2,
    out_errmsg  OUT varchar2
)
RETURN integer
IS
BEGIN

    out_errmsg := 'OKAY';

    UPDATE invoicehdr
       SET masterinvoice = null,
           invoicedate = null
     WHERE lastuser = in_userid
       AND masterinvoice like 'TEST%';

-- Delete old session information if there is any
    DELETE invsession
     WHERE userid = in_userid;

    return zbill.GOOD;

END release_session;

----------------------------------------------------------------------
--
-- release_invoice
--
----------------------------------------------------------------------
FUNCTION release_invoice
(
    in_invoice   IN  varchar2,
    out_errmsg  OUT varchar2
)
RETURN integer
IS
BEGIN

    out_errmsg := 'OKAY';

    UPDATE invoicehdr
       SET masterinvoice = null,
           invoicedate = null
     WHERE masterinvoice = in_invoice;

    return zbill.GOOD;

exception when others then
  out_errmsg := sqlerrm;
END release_invoice;

----------------------------------------------------------------------
--
-- create_invoices
--
----------------------------------------------------------------------
FUNCTION create_invoices
(
    in_userid   IN  varchar2,
    in_facility IN  varchar2,
    in_custid   IN  varchar2,
    in_csr      IN  varchar2,
    in_invdate  IN  date,
    in_reference IN number,
    in_invtype  IN  varchar2,
    in_orderid  IN  number,
    in_onlydue  IN  varchar2,
    out_errmsg  OUT varchar2
)
RETURN integer
IS
  CURSOR C_CBD(in_custid varchar2)
    RETURN custbilldates%rowtype
  IS
    SELECT *
      FROM custbilldates
     WHERE custid = in_custid;

  CURSOR C_INVOICES(in_facility varchar2, in_custid varchar2,
            in_invtype varchar2)
  IS
    SELECT *
      FROM invoicehdr
     WHERE facility = in_facility
       AND custid = in_custid
       AND invtype = in_invtype
       AND invstatus = zbill.REVIEWED
       AND masterinvoice is null;

  CURSOR C_CHECK(in_invoice number, in_orderid number)
  IS
    SELECT count(1)
      FROM invoicedtl D
     WHERE invoice = in_invoice
       AND orderid = in_orderid;

  cnt integer;

  CUST customer%rowtype;
  CBD   custbilldates%rowtype;

  invoices_created integer;

-- invoice info
  due_date      date;
  curr_facility varchar2(3);
  curr_invtype  varchar2(1);
  billtype    varchar2(1);
  suminvoice  varchar2(8);
  mstinvoice  varchar2(8);
  tmpinvoice  varchar2(8);

  cutoffdate date;

  inv_window number;


BEGIN
    out_errmsg := 'OKAY';

-- Determine Invoice Window
    BEGIN
      inv_window := 30;
      OPEN C_DFLT('INVOICE_WINDOW');
      FETCH C_DFLT into inv_window;
    EXCEPTION
      when others then
         inv_window := 30;
    END;
    CLOSE C_DFLT;


-- Verify the invoice date
   if trunc(abs(sysdate - in_invdate)) > inv_window then
       out_errmsg := 'Invoice date must be within '||inv_window||' days.';
       return zbill.BAD;
   end if;

   select max(cutoffdate)
     into cutoffdate
     from accountperiod;
   if cutoffdate >= in_invdate then
       out_errmsg := 'Invoice date must be afer last accounting cutoff of '
         || to_char(cutoffdate,'MON-DD-YYYY');
       return zbill.BAD;
   end if;


-- Delete old session information if there is any
    DELETE invsession
     WHERE userid = in_userid;

-- release any old invoices if there are any
    if zbill.release_session(in_userid, out_errmsg) != zbill.GOOD then
        return zbill.BAD;
    end if;

-- Loop thru potential customers
    invoices_created := 0;
    CUST := null;
    curr_invtype := null;
    curr_facility := null;
    billtype := null;
    due_date := null;
    suminvoice := null;
    mstinvoice := null;

--  add to existing invoice or start new invoice
    for crec in
        zbill.C_CRT_INVOICE(in_facility, in_custid, in_csr, in_invtype,
                            in_userid)
    loop

    --    zut.prt('Got customer '||crec.custid);
    -- Get the customer information if it is a new customer
        if CUST.custid is null or CUST.custid != crec.custid then
            if rd_customer(crec.custid, CUST) = BAD then
                out_errmsg := 'CI: customer doesnot exist:'||crec.custid;
                return BAD;
            end if;
            CBD := null;
            OPEN C_CBD(crec.custid);
            FETCH C_CBD into CBD;
            CLOSE C_CBD;
            if CBD.custid is null then
                out_errmsg := 'CI: customer bill dates doesnot exist:'||crec.custid;
                return BAD;
            end if;
        -- If we switched customers all invoice data old so clear it
            curr_invtype := null;
            curr_facility := null;
            billtype := null;
            due_date := null;
            suminvoice := null;
            mstinvoice := null;
            tmpinvoice := null;
        end if;

        -- if we changed facilities the invoices are done
        if NVL(curr_facility,'XXXX') != crec.facility then
            curr_facility := crec.facility;
            curr_invtype := null;
            billtype := null;
            due_date := null;
            suminvoice := null;
            mstinvoice := null;
            tmpinvoice := null;
        end if;

        -- if we changed invtype we need to reset up
        if NVL(curr_invtype,'XXXX') != crec.invtype then
            curr_invtype := crec.invtype;
            if curr_invtype = zbill.IT_RECEIPT then
                billtype := CUST.rcptbilltype;
                due_date := CBD.nextreceipt;
                if CUST.rcptbillfreq = 'D' then
                   due_date := in_invdate;
                end if;
            elsif curr_invtype = zbill.IT_STORAGE then
                billtype := CUST.rnewbilltype;
                due_date := CBD.nextrenewal;
                if CUST.rnewbillfreq = 'D' then
                   due_date := in_invdate;
                end if;
            elsif curr_invtype = zbill.IT_ACCESSORIAL then
                billtype := CUST.outbbilltype;
                due_date := CBD.nextassessorial;
                if CUST.outbbillfreq = 'D' then
                   due_date := in_invdate;
                end if;
            elsif curr_invtype = zbill.IT_MISC then
                billtype := CUST.miscbilltype;
                due_date := CBD.nextmiscellaneous;
                if CUST.miscbillfreq = 'D' then
                   due_date := in_invdate;
                end if;
            elsif curr_invtype = zbill.IT_CREDIT then
                billtype := CUST.miscbilltype;
                due_date := CBD.nextmiscellaneous;
                if CUST.miscbillfreq = 'D' then
                   due_date := in_invdate;
                end if;
            end if;
            suminvoice := null; -- If doing summaries we need a new one
        end if;
-- Is this type of invoice due now
        if NVL(in_onlydue,'Y') = 'N' or due_date <= in_invdate then
-- Loop thru the customers due invoices
            for crec2 in
            C_INVOICES(crec.facility, crec.custid, crec.invtype) loop

            -- check if this invoice meets all criteria
              cnt := 1;
              if in_orderid is not null then
                  if in_orderid = crec2.loadno then
                      cnt := 1;
                  else
                      cnt := 0;
                      OPEN C_CHECK(crec2.invoice, in_orderid);
                      FETCH C_CHECK into cnt;
                      CLOSE C_CHECK;
                  end if;
              end if;

              if (in_reference is null or crec2.invoice = in_reference)
                 and cnt > 0 then

              -- Now have an invoice what to do
                if billtype = 'I' then
                    zbill.get_test_invoiceid(tmpinvoice);
                elsif billtype = 'S' then
                    if suminvoice is null then
                        zbill.get_test_invoiceid(suminvoice);
                    end if;
                    tmpinvoice := suminvoice;
                elsif billtype = 'M' then
                    if mstinvoice is null then
                        zbill.get_test_invoiceid(mstinvoice);
                    end if;
                    tmpinvoice := mstinvoice;
                elsif billtype is null then
                  out_errmsg := 'Bill type could not be determined';
                  return BAD;
                end if;
                UPDATE invoicehdr
                   SET masterinvoice = tmpinvoice,
                       lastuser = in_userid,
                       invoicedate = in_invdate,
                       lastupdate = sysdate
                 WHERE invoice = crec2.invoice;
                invoices_created := invoices_created + 1;
              end if; -- end of check for all criteria
            end loop;
        end if;
    end loop;

    if invoices_created > 0 then
        INSERT INTO invsession(
            userid,
            facility,
            custid,
            csr,
            invdate,
            reference,
            invtype,
            orderid,
            onlydueinv
        )
        values (
            in_userid,
            in_facility,
            in_custid,
            in_csr,
            in_invdate,
            in_reference,
            in_invtype,
            in_orderid,
            in_onlydue
        );

    end if;


    if invoices_created <= 0 then
       out_errmsg := 'No invoices created for this criteria.';
       return zbill.BAD;
    end if;

    return zbill.GOOD;
END create_invoices;

----------------------------------------------------------------------
--
-- check_billschedule
--
----------------------------------------------------------------------
PROCEDURE check_billschedule
(
    in_custid   IN  varchar2,
    out_errmsg  OUT varchar2
)
IS
l_msg varchar2(2000);
CURSOR C_CUST
IS
select rnewbillfreq,rcptbillfreq,outbbillfreq,miscbillfreq
  from customer
 where custid = in_custid;

CUST C_CUST%rowtype;
l_cnt integer;

PROCEDURE check_sched(in_type varchar2)
IS
BEGIN
    l_cnt := 0;
    l_msg := '';
    select count(1)
      into l_cnt
      from custbillschedule
     where custid = in_custid
       and type = in_type
       and billdate > sysdate;

    if nvl(l_cnt,0) < 3 then
        l_msg := in_type||' Bill schedule has only '
            ||nvl(l_cnt,0)||' entries left.';
        zms.log_msg('BILLER', null, in_custid,
            l_msg, 'W', 'BILLER', out_errmsg);

    end if;


END;

BEGIN
    out_errmsg := 'OKAY';


    CUST := null;
    OPEN C_CUST;
    FETCH C_CUST into CUST;
    CLOSE C_CUST;

    if nvl(CUST.rnewbillfreq,'x') = 'F'
     or nvl(CUST.rcptbillfreq,'x') = 'F'
     or nvl(CUST.outbbillfreq,'x') = 'F'
     or nvl(CUST.miscbillfreq,'x') = 'F' then
        check_sched(zbill.BT_DEFAULT);
    end if;

    if nvl(CUST.rnewbillfreq,'x') = 'C' then
        check_sched(zbill.BT_RENEWAL);
    end if;
    if nvl(CUST.rcptbillfreq,'x') = 'C' then
        check_sched(zbill.BT_RECEIPT);
    end if;
    if nvl(CUST.outbbillfreq,'x') = 'C' then
        check_sched(zbill.BT_ACCESSORIAL);
    end if;
    if nvl(CUST.miscbillfreq,'x') = 'C' then
        check_sched(zbill.BT_MISC);
    end if;

END check_billschedule;

PROCEDURE create_temp_invoicehdr
(
        in_invtype      in      varchar2,
        in_custid       IN      varchar2,
        in_facility     IN      varchar2,
        in_orderid      IN      varchar2,
        in_shipid       IN      varchar2,
        in_userid       IN      varchar2,
        out_invoice     OUT     integer,
        out_errmsg      OUT varchar2
)
IS
  v_count number;
BEGIN
  out_errmsg := 'OKAY';
  if (nvl(in_orderid,0) = 0 or nvl(in_shipid,0) = 0) then
    out_errmsg := 'Order id and ship id required';
    return;
  end if;
  out_invoice := -1 * (in_orderid * 100 + in_shipid);
  select count(1) into v_count
  from invoicehdr
  where invoice = out_invoice; 
  if (v_count > 0) then
    return;
  end if;
  INSERT into invoicehdr(invoice,invdate,invtype,invstatus,facility,
    custid,renewfromdate,renewtodate,lastuser,lastupdate)
  VALUES (out_invoice,trunc(sysdate),in_invtype,zbill.NOT_REVIEWED,in_facility,
    in_custid,sysdate,sysdate,in_userid,sysdate);
exception
  when others then
    out_errmsg := sqlerrm;
END create_temp_invoicehdr;
PROCEDURE rollover_preenter_charges
(
    in_invoice  IN      number,
    in_orderid  IN      number,
    in_shipid   IN      number,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
is
  v_count number;
  v_inv_from invoicehdr%rowtype;
  v_inv_to   invoicehdr%rowtype;
  v_orderhdr orderhdr%rowtype;
begin
  out_errmsg := 'OKAY';
  begin
    select * into v_inv_from
    from invoicehdr
    where invoice = -1 * (in_orderid * 100 + in_shipid);
  exception
    when others then
      return;
  end;
  begin
    select * into v_inv_to
    from invoicehdr
    where invoice = in_invoice;
  exception
    when others then
      out_errmsg := 'Invoice could not be found';
      return;
  end;
  if (v_inv_to.invtype <> v_inv_from.invtype 
    or v_inv_to.invstatus not in (zbill.UNCHARGED, zbill.NOT_REVIEWED, zbill.REVIEWED))
  then
    out_errmsg := 'Wrong invoice type or status';
    return;
  end if;
  if (v_inv_from.custid <> v_inv_to.custid or v_inv_from.facility <> v_inv_to.facility) then
    out_errmsg := 'Incompatable invoices';
    return;
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
  where invoice = v_inv_from.invoice;
  update invoicehdr
  set lastupdate = sysdate,
      lastuser = in_userid,
      invstatus = zbill.NOT_REVIEWED
  where invoice = v_inv_to.invoice;
exception
  when others then
    out_errmsg := sqlerrm;
end rollover_preenter_charges;
end zbilling;
/
show error package body zbilling;

exit;

