create or replace package body alps.zbillreceipt as
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


-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************
--
-- Cursors are defined in zbillspec.sql
--
CURSOR C_ORDHDR(in_orderid number, in_shipid number)
RETURN orderhdr%rowtype
IS
    SELECT *
      FROM orderhdr
     WHERE orderid = in_orderid
       AND shipid = in_shipid;


-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************



----------------------------------------------------------------------
--
-- check_orderdtlrcpt
--
----------------------------------------------------------------------
PROCEDURE check_orderdtlrcpt
(
    in_loadno  IN      number,
    in_userid  IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
IS
   CURSOR C_ORDERS(in_loadno number)
   IS
   select orderid,
          shipid,
          custid,
          tofacility
     from orderhdr
    where loadno = in_loadno;


   CURSOR C_ODR(in_orderid number, in_shipid number)
   IS
   select R.lpid,
          R.qtyrcvd r_qty,
          nvl(P.qtyrcvd,0) p_qty,
          nvl(DP.qtyrcvd,0) dp_qty
     from deletedplate DP, plate P, orderdtlrcpt R
    where R.orderid = in_orderid
      and R.shipid = in_shipid
      and R.lpid = P.lpid(+)
      and R.lpid = DP.lpid(+);

tot_qty number;


BEGIN

   out_errmsg := 'OKAY';

   for cord in C_ORDERS(in_loadno) loop

      for crec in C_ODR(cord.orderid, cord.shipid) loop
          tot_qty := crec.p_qty + crec.dp_qty;
          if crec.r_qty != tot_qty then
             update orderdtlrcpt
                set qtyrcvd = tot_qty
              where lpid = crec.lpid;

             zms.log_msg('RCPTBILL', cord.tofacility, cord.custid,
                     'OrderDtlRcpt quantity '||to_char(crec.r_qty)
                     ||' does not match pallet '
                     ||to_char(tot_qty)||
                     ' LPID:'||crec.lpid ,
                     'I', in_userid, out_errmsg);

          end if;
      end loop;
   end loop;

END check_orderdtlrcpt;



----------------------------------------------------------------------
--
-- calc_receipt_minimums -
--
----------------------------------------------------------------------
FUNCTION calc_receipt_minimums
(
    INVH        IN      invoicehdr%rowtype,
    in_loadno   IN      number,
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
  LOAD  loads%rowtype;
  FAKE_ORD      orderhdr%rowtype;  -- fake orderheader to call rtns

-- Minimums Cursors
  CURSOR C_ID_CHRG(in_loadno number, in_custid varchar2)
  IS
    SELECT NVL(HT.minactivity, ID.activity) activity, item, lotnumber,
           nvl(billedamt,nvl(calcedamt,0)) total
      FROM handlingtypes HT, invoicedtl ID
     WHERE loadno = in_loadno
       AND custid = in_custid
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED)
       AND ID.activity = HT.activity(+)
       AND ID.handling = HT.code(+);

  CURSOR C_ID_LINE(in_loadno number, in_custid varchar2)
  IS
    SELECT NVL(HT.minactivity, ID.activity) activity, item, lotnumber,
           sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM handlingtypes HT, invoicedtl ID
     WHERE loadno = in_loadno
       AND custid = in_custid
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED)
       AND ID.activity = HT.activity(+)
       AND ID.handling = HT.code(+)
     GROUP BY NVL(HT.minactivity, ID.activity), item, lotnumber;

  CURSOR C_ID_ITEM(in_loadno number, in_custid varchar2)
  IS
    SELECT NVL(HT.minactivity, ID.activity) activity, item,
           sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM handlingtypes HT, invoicedtl ID
     WHERE loadno = in_loadno
       AND custid = in_custid
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED)
       AND ID.activity = HT.activity(+)
       AND ID.handling = HT.code(+)
     GROUP BY NVL(HT.minactivity, ID.activity), item;

  CURSOR C_ID_ORDER(in_loadno number, in_custid varchar2)
  IS
    SELECT NVL(HT.minactivity, ID.activity) activity,
           sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM handlingtypes HT, invoicedtl ID
     WHERE loadno = in_loadno
       AND custid = in_custid
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED)
       AND ID.activity = HT.activity(+)
       AND ID.handling = HT.code(+)
     GROUP BY NVL(HT.minactivity, ID.activity);

  CURSOR C_ID_INVOICE(in_loadno number, in_custid varchar2)
  IS
    SELECT sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM invoicedtl ID
     WHERE loadno = in_loadno
       AND custid = in_custid
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED);

  CURSOR C_ORDID(in_loadno number, in_custid varchar2, in_item varchar2,
                 in_lotnumber varchar2)
  IS
    SELECT orderid, shipid
      FROM orderhdr
     WHERE custid = in_custid
       AND loadno = in_loadno
       AND orderid in
           (SELECT orderid
              FROM orderdtlrcpt
             WHERE orderid = orderhdr.orderid
               AND nvl(item,'XX') = nvl(in_item,'XX')
               AND nvl(lotnumber,'XX') =
                   nvl(in_lotnumber,nvl(lotnumber,'XX')));

  CURSOR C_ORDER(in_loadno number, in_custid varchar2)
  IS
    SELECT orderid, shipid
      FROM orderhdr
     WHERE custid = in_custid
       AND loadno = in_loadno;

  orderid orderhdr.orderid%type;
  shipid orderhdr.shipid%type;

  rc      integer;
  now_date date;

  item_rategroup custitem.rategroup%type;

BEGIN

    now_date := in_effdate;

-- Get the load
    LOAD := null;
    OPEN zbill.C_LOAD(in_loadno);
    FETCH zbill.C_LOAD into LOAD;
    CLOSE zbill.C_LOAD;

    -- zut.prt('Load is '||nvl(to_char(in_loadno),'*NULL*'));

-- Get the customer information for this receipt order
    if zbill.rd_customer(in_custid, CUST) = zbill.BAD then
       out_errmsg := 'Invalid custid = '|| in_custid;
       -- zut.prt(out_errmsg);
       return zbill.BAD;
    end if;

-- Get rid of any old minimums
    DELETE FROM invoicedtl
     WHERE loadno = in_loadno
       AND custid = in_custid
       AND minimum is not null
       and (billstatus != zbill.DELETED or in_keep_deleted = 'N');

-- Determine all the possible mins in order
   FAKE_ORD := null;
   FAKE_ORD.loadno := in_loadno;


-- Check for per charge minimums
    for crec in C_ID_CHRG(in_loadno, in_custid) loop
    -- Check if line level minimum exists for this item
      if zbill.rd_item(CUST.custid, crec.item, ITEM) = zbill.BAD then
         null;
      end if;
      zbill.rd_item_rategroup(CUST.custid, crec.item, item_rategroup);

      if zbill.check_for_minimum(CUST.custid, item_rategroup, CUST.rategroup,
                 zbill.EV_RECEIPT, INVH.facility, zbill.BM_MIN_CHARGE,
                 crec.activity, now_date, RATE) = zbill.GOOD then
           if nvl(crec.total, 0) < RATE.rate then
               OPEN C_ORDID(in_loadno, in_custid, ITEM.item,
                    crec.lotnumber);
               FETCH C_ORDID into orderid, shipid;
               CLOSE C_ORDID;
               FAKE_ORD.orderid := orderid;
               FAKE_ORD.shipid := shipid;
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, FAKE_ORD,
                 crec.item, crec.lotnumber, nvl(crec.total, 0), in_userid,
                 nvl(LOAD.rcvddate,sysdate), null, zbill.EV_RECEIPT, in_keep_deleted);
           end if;
      end if;
    end loop;

-- Check for line minimums
    for crec in C_ID_LINE(in_loadno, in_custid) loop
    -- Check if line level minimum exists for this item
      if zbill.rd_item(CUST.custid, crec.item, ITEM) = zbill.BAD then
         null;
      end if;
      zbill.rd_item_rategroup(CUST.custid, crec.item, item_rategroup);

      if zbill.check_for_minimum(CUST.custid, item_rategroup, CUST.rategroup,
                 zbill.EV_RECEIPT, INVH.facility, zbill.BM_MIN_LINE,
                 crec.activity, now_date, RATE) = zbill.GOOD then
           if nvl(crec.total, 0) < RATE.rate then
               OPEN C_ORDID(in_loadno, in_custid, ITEM.item,
                    crec.lotnumber);
               FETCH C_ORDID into orderid, shipid;
               CLOSE C_ORDID;
               FAKE_ORD.orderid := orderid;
               FAKE_ORD.shipid := shipid;
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, FAKE_ORD,
                 crec.item, crec.lotnumber, nvl(crec.total, 0), in_userid,
                 nvl(LOAD.rcvddate,sysdate), null, zbill.EV_RECEIPT, in_keep_deleted);
           end if;
      end if;
    end loop;

-- Check for item minimums
    for crec in C_ID_ITEM(in_loadno, in_custid) loop
    -- Check if line level minimum exists for this item
      if zbill.rd_item(CUST.custid, crec.item, ITEM) = zbill.BAD then
         null;
      end if;
      zbill.rd_item_rategroup(CUST.custid, crec.item, item_rategroup);

      if zbill.check_for_minimum(CUST.custid, item_rategroup, CUST.rategroup,
                 zbill.EV_RECEIPT, INVH.facility, zbill.BM_MIN_ITEM,
                 crec.activity, now_date, RATE) = zbill.GOOD then
           if nvl(crec.total, 0) < RATE.rate then
               OPEN C_ORDID(in_loadno, in_custid, ITEM.item, NULL);
               FETCH C_ORDID into orderid, shipid;
               CLOSE C_ORDID;
               FAKE_ORD.orderid := orderid;
               FAKE_ORD.shipid := shipid;
               -- zut.prt('Order ID is '||nvl(to_char(orderid),'*NULL*'));
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, FAKE_ORD,
                 crec.item, NULL, nvl(crec.total, 0), in_userid,
                 NVL(LOAD.rcvddate,sysdate), null, zbill.EV_RECEIPT, in_keep_deleted);
           end if;
      end if;
   end loop;

-- Check for order minimum (must be defined at the cust rate group level)
    for crec in C_ID_ORDER(in_loadno, in_custid) loop
    -- Check if order level minimums exist
      if zbill.check_for_minimum(CUST.custid, NULL, CUST.rategroup,
                 zbill.EV_RECEIPT, INVH.facility, zbill.BM_MIN_ORDER,
                 crec.activity, now_date, RATE) = zbill.GOOD then
           if nvl(crec.total, 0) < RATE.rate then
               OPEN C_ORDER(in_loadno, in_custid);
               FETCH C_ORDER into orderid, shipid;
               CLOSE C_ORDER;
               FAKE_ORD.orderid := orderid;
               FAKE_ORD.shipid := shipid;
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, FAKE_ORD,
                 NULL, NULL, nvl(crec.total, 0), in_userid,
                 NVL(LOAD.rcvddate,sysdate), null, zbill.EV_RECEIPT, in_keep_deleted);
          end if;
      end if;
    end loop;

-- Check for invoice minimum (must be defined at the cust rate group level)
    for crec in C_ID_INVOICE(in_loadno, in_custid) loop
    -- Check if order level minimums exist
      if zbill.check_for_minimum(CUST.custid, NULL, CUST.rategroup,
                 zbill.EV_RECEIPT, INVH.facility, zbill.BM_MIN_INVOICE, NULL,
                 now_date, RATE) = zbill.GOOD then
           if nvl(crec.total, 0) < RATE.rate then
               OPEN C_ORDER(in_loadno, in_custid);
               FETCH C_ORDER into orderid, shipid;
               CLOSE C_ORDER;
               FAKE_ORD.orderid := orderid;
               FAKE_ORD.shipid := shipid;
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, FAKE_ORD,
                 NULL, NULL, nvl(crec.total, 0), in_userid,
                 NVL(LOAD.rcvddate,sysdate), null, zbill.EV_RECEIPT, in_keep_deleted);
           end if;
      end if;
    end loop;


    return zbill.GOOD;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CRecMins: '||substr(sqlerrm,1,80);
    return zbill.BAD;
END calc_receipt_minimums;



----------------------------------------------------------------------
--
-- calc_customer_receipt -
--
----------------------------------------------------------------------
FUNCTION xdock_qty
   (in_orderid IN number,
    in_shipid  IN number,
    in_item    IN varchar2,
    in_lot     IN varchar2)
RETURN number
IS
   rtnqty number := 0;
BEGIN

   SELECT nvl(sum(qtyorder), 0)
      INTO rtnqty
      FROM orderdtl
     WHERE xdockorderid = in_orderid
       AND xdockshipid = in_shipid
       AND item = in_item
       AND nvl(lotnumber, '(none)') = nvl(in_lot, '(none)');
   return rtnqty;

EXCEPTION WHEN OTHERS THEN
      return 0;
END xdock_qty;


FUNCTION calc_customer_receipt
(
    in_invoice  IN      number,    -- If non null this is a recalc
    in_loadno   IN      number,
    in_custid   IN      varchar2,
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


  item_rategroup  custrate.rategroup%type;
  t_activity custrate.activity%type;

  errmsg     varchar2(200);
  do_calc    BOOLEAN;
  track_lot  char(1);
  recmethod  varchar2(2);
  hcnt       integer;           -- count of handling types for activity
  htype     varchar2(4);        -- handling type of activity

-- Local cursors

  CURSOR C_LD_ITEMS(in_loadno number, in_custid varchar2)
  IS
    SELECT distinct OD.item
      FROM orderdtlrcpt OD, orderhdr OH
     WHERE OH.loadno = in_loadno
       AND OH.custid = in_custid
       AND (OH.ordertype in ('T','Q','R','A','C','U')
           or (in_loadno < 0 and OH.ordertype = 'P'))
       AND OD.orderid = OH.orderid
       AND OD.shipid  = OH.shipid;

  CURSOR C_QTY(in_loadno number,
               in_custid varchar2,
               in_item varchar2,
               in_activity varchar2)
  IS
    SELECT decode(track_lot,'Y',OD.lotnumber,'O',OD.lotnumber,'S',OD.lotnumber,'A',OD.lotnumber,null) lotnum,
           OD.uom unitofmeasure,
           sum(OD.qtyrcvd) qty,
           sum(OD.weight) weight,
-- oracle 11g didn't like the 'distinct' (although in 10g it was okay)--created c_pltqty to compensate
--           count(distinct nvl(OD.parentlpid, OD.lpid)) pltqty,
           zbr.xdock_qty(OD.orderid, OD.shipid, OD.item, OD.lotnumber) xdqty
      FROM orderdtlrcpt OD, deletedplate DP, plate P,
           orderhdr OH
     WHERE OH.loadno = in_loadno
       AND OH.custid = in_custid
       AND (OH.ordertype in ('T','Q','R','A','C','U')
            or (in_loadno < 0 and OH.ordertype = 'P'))
       AND OD.orderid = OH.orderid
       AND OD.shipid  = OH.shipid
       AND OD.item = in_item
       AND OD.lpid = P.lpid(+)
       AND OD.lpid = DP.lpid(+)
       AND (
           nvl(P.recmethod,DP.recmethod) in
           (select code
              from handlingtypes
             where activity = in_activity)
           OR in_activity is null
           )
      GROUP BY
           decode(track_lot,'Y',OD.lotnumber,'O',OD.lotnumber,'S',OD.lotnumber,'A',OD.lotnumber,null),
           OD.uom,
           zbr.xdock_qty(OD.orderid, OD.shipid, OD.item, OD.lotnumber);

  CURSOR C_PLTQTY(in_loadno number,
               in_custid varchar2,
               in_item varchar2,
               in_activity varchar2,
               in_lotnumber varchar2)
  IS
    SELECT count(distinct nvl(OD.parentlpid, OD.lpid)) pltqty
      FROM orderdtlrcpt OD, deletedplate DP, plate P,
           orderhdr OH
     WHERE OH.loadno = in_loadno
       AND OH.custid = in_custid
       AND (OH.ordertype in ('T','Q','R','A','C','U')
            or (in_loadno < 0 and OH.ordertype = 'P'))
       AND OD.orderid = OH.orderid
       AND OD.shipid  = OH.shipid
       AND OD.item = in_item
       AND ( (OD.lotnumber = in_lotnumber) or (in_lotnumber is null) )
       AND OD.lpid = P.lpid(+)
       AND OD.lpid = DP.lpid(+)
       AND (
           nvl(P.recmethod,DP.recmethod) in
           (select code
              from handlingtypes
             where activity = in_activity)
           OR in_activity is null
           );
  PQ C_PLTQTY%rowtype;

  CURSOR C_PRNT_PLTQTY(in_loadno number,
                       in_custid varchar2,
                       in_effdate date)
  is
    select decode(num_items,1,item,decode(num_rategroups,1,'MIXED','NOCALC')) as item, 
           decode(lot_track_req,'Y',decode(num_lotnumbers,1,lotnumber,'MIXED'),null) as lotnumber,
           rategroup, handling_types, count(1) as pallets
    from (
      select nvl(parentlpid, lpid), zbut.get_handling_types(nvl(parentlpid, lpid)) as handling_types,
        zbut.prnt_get_lottrack_req(nvl(parentlpid, lpid), zbill.EV_RECEIPT, null) as lot_track_req,
        min(a.item) as item, count(distinct a.item) as num_items,
        min(a.lotnumber) as lotnumber, count(distinct nvl(a.lotnumber,'(none)')) as num_lotnumbers,
        min(zbut.rategroup(a.custid, b.rategroup)) as rategroup, 
        count(distinct zbut.rategroup(a.custid, b.rategroup)) as num_rategroups,
        sum(zbut.check_rg_bm_event(zbut.rategroup(a.custid, b.rategroup).custid, 
                                   zbut.rategroup(a.custid, b.rategroup).rategroup, 
                                   zbill.BM_PARENT_BILLING, zbill.EV_RECEIPT, in_effdate)) as use_bm
      from orderdtlrcpt a, custitem b, orderhdr c
      where a.custid = b.custid and a.item = b.item
        and a.orderid = c.orderid and a.shipid = c.shipid
        and c.custid = in_custid and c.loadno = in_loadno
      group by nvl(parentlpid, lpid))
    where use_bm > 0
    group by decode(num_items,1,item,decode(num_rategroups,1,'MIXED','NOCALC')), 
             decode(lot_track_req,'Y',decode(num_lotnumbers,1,lotnumber,'MIXED'),null),
             rategroup, handling_types;
  
  CURSOR C_HTYPE(in_activity varchar2)
  IS
    SELECT code
      FROM handlingtypes
     WHERE activity = in_activity;

  CURSOR C_ORDID(in_loadno number, in_custid varchar2, in_item varchar2)
  IS
    SELECT orderid, shipid
      FROM orderhdr
     WHERE custid = in_custid
       AND loadno = in_loadno
       AND orderid in
           (SELECT orderid
              FROM orderdtl
             WHERE orderid = orderhdr.orderid
               AND item = nvl(in_item,item));

  CURSOR C_NOIBPRENOTE(in_loadno number, in_custid varchar2)
  RETURN orderhdr%rowtype
  IS
    SELECT *
      FROM orderhdr
     WHERE custid = in_custid
       AND loadno = in_loadno
       AND priority = 'N';

  CURSOR C_INVD(in_invoice number)
  IS
    SELECT rowid
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND billstatus = zbill.UNCHARGED;

  CURSOR C_CLR(in_facility varchar2,
               in_custid varchar2)
  RETURN custlastrenewal%rowtype
  IS
    SELECT *
      FROM custlastrenewal
     WHERE facility = in_facility
       AND custid = in_custid;

  CLR custlastrenewal%rowtype;

  do_renewal boolean;

  orderid orderhdr.orderid%type;
  shipid orderhdr.shipid%type;

  qty C_QTY%rowtype;

 rc integer;

 save_pnt varchar2(20);

CURSOR C_LOAD(in_loadno number)
 RETURN loads%rowtype
IS
    SELECT *
      FROM loads
     WHERE loadno = in_loadno;

  CURSOR C_INVH_FIND(in_facility varchar2,
                     in_custid varchar2,
                     in_invtype varchar2,
                     in_loadno number)
  RETURN invoicehdr%rowtype
  IS
     SELECT *
       FROM invoicehdr
      WHERE custid = in_custid
        AND facility = in_facility
        AND invtype = in_invtype
        AND (loadno = in_loadno
             or (in_loadno < 0 and orderid = ceil(in_loadno/100)*-1 
                 and shipid = mod(-19801,100)*-1));


CURSOR C_SD(in_id varchar2)
IS
SELECT defaultvalue
  FROM systemdefaults
 WHERE defaultid = in_id;

 CURSOR C_RS_GRACE(in_custid varchar2,
                   in_loadno number,
                   in_effdate date)
IS
SELECT rowid
  FROM invoicedtl
 WHERE custid = in_custid
   AND (loadno = in_loadno
        or (in_loadno < 0 and orderid = ceil(in_loadno/100)*-1 
            and shipid = mod(-19801,100)*-1))
   AND billstatus in (zbill.UNCHARGED, zbill.NOT_REVIEWED, zbill.REVIEWED)
   AND invoice = 0
   AND invtype = zbill.IT_RECEIPT
   AND expiregrace <= in_effdate;

lrr systemdefaults.defaultvalue%type;


 now_date date;
 effdate date;

 current_event varchar2(4);
 xdock_qty     number;
 nonxdock_qty  number;
 tot_xdock_qty     number;
 tot_nonxdock_qty  number;
 cur_qty number;
 l_gracedays integer;

 n1      number;
 n2      number;
 n3      number;
 terrmsg varchar2(200);
 handling_found boolean;
 v_count number;
 v_prod_orderid number := ceil(in_loadno/100)*-1;
 v_prod_shipid number := mod(in_loadno,100)*-1;
 v_loadno number := in_loadno;

--
-- check if we need to do lot receipt capture for this activity
--

  PROCEDURE check_lrr(in_activity varchar2, in_facility varchar2, 
                      in_custid varchar2, in_item varchar2,
                      in_lotnumber varchar2,
                      in_rcvddate date,
                      in_qty number, in_uom varchar2, in_weight number,
                      in_userid varchar2) 
  IS
    cnt integer;
  BEGIN
    cnt := 0;
    select count(1)
      into cnt
      from LotReceiptCapture
     where code = in_activity;

    if nvl(cnt,0) = 0 then
        return;
    end if;

    -- If we have a match remove it only for same effective date
    DELETE bill_lot_renewal 
     WHERE facility = in_facility
       AND custid = in_custid
       AND item = in_item
       and nvl(lotnumber, '(none)') = nvl(in_lotnumber, '(none)')
       and receiptdate = trunc(in_rcvddate);

    begin
    insert into bill_lot_renewal(facility, custid, item, lotnumber,
                receiptdate, quantity, uom, weight, renewalrate, lastuser,
                lastupdate)
    values (in_facility, in_custid, in_item, in_lotnumber, 
            trunc(in_rcvddate), in_qty, in_uom, in_weight, null, in_userid,
                sysdate);
    exception when others then
        zms.log_msg('LOTRENEWAL', in_facility, in_custid,
                    'Duplicate lot for item:'||in_item
                        ||'/'||in_lotnumber,
                     'I', in_userid, out_errmsg);

    end;
  EXCEPTION WHEN OTHERS THEN
    return;
  END;

BEGIN

   out_errmsg := 'OKAY';
   save_pnt := 'Strt ';


-- Upon close of the receipt we need to calculate the charges
--   we are generating for the receipt invoice
--   this may require rolling multiple detail lines into
--   a single 'new' billing record or
--   processing the individual invoicedtl lines

-- Get the load
    LOAD := null;
    OPEN zbill.C_LOAD(v_loadno);
    FETCH zbill.C_LOAD into LOAD;
    CLOSE zbill.C_LOAD;

     if (v_loadno < 0) then
      begin
        select tofacility, statusupdate, statusupdate
        into LOAD.facility, LOAD.rcvddate, LOAD.billdate
        from orderhdr
        where orderid = v_prod_orderid and shipid = v_prod_shipid and orderstatus = 'R';
      exception
        when others then
          out_errmsg := 'Order not received';
          return zbill.BAD;
      end;
    end if;

   save_pnt := 'Gld ';

    now_date := nvl(LOAD.rcvddate,sysdate);


-- Get the customer information for this receipt order
    if zbill.rd_customer(in_custid, CUST) = zbill.BAD then
       out_errmsg := 'Invalid custid = '|| in_custid;
       -- zut.prt(out_errmsg);
       return zbill.BAD;
    end if;
   save_pnt := 'RCus ';


-- check for lot receipt renewal processing
    lrr := null;
    OPEN C_SD('LOTRECEIPTRENEWAL');
    FETCH C_SD into lrr;
    CLOSE C_SD;


-- Try to locate the existing invoice header
   INVH := null;
   if in_invoice is not null then
   -- Get the invoice hdr
       OPEN zbill.C_INVH(in_invoice);
       FETCH zbill.C_INVH into INVH;
       CLOSE zbill.C_INVH;
       
       if INVH.invstatus = zbill.BILLED then
         out_errmsg := 'Invalid Invoice. Already billed.';
         return zbill.BAD;
       end if;
      
   -- Check if this is really a returns entry
      ORD := null;
      OPEN C_ORDHDR(INVH.orderid, nvl(INVH.shipid,1));
      FETCH C_ORDHDR into ORD;
      CLOSE C_ORDHDR;

      if (ORD.ordertype = 'P' and nvl(v_loadno,0) = 0) then
        if (ORD.orderstatus <> 'R') then
          out_errmsg := 'Order not received';
          return zbill.BAD;
        end if;
        
        v_prod_orderid := ORD.orderid;
        v_prod_shipid := ORD.shipid;
        LOAD.facility := ORD.tofacility; 
        LOAD.rcvddate := ORD.statusupdate; 
        LOAD.billdate := ORD.statusupdate;
        v_loadno := (v_prod_orderid * 100 + v_prod_shipid) * -1;
        now_date := nvl(LOAD.rcvddate,sysdate);
        
        update orderhdr
        set loadno = v_loadno
        where orderid = ORD.orderid and shipid = ORD.shipid;
      end if;

      if ORD.ordertype = 'Q' then
         return
           calc_customer_return(in_invoice,ORD.orderid,ORD.shipid,
            in_custid, in_userid, out_errmsg);
      end if;

    -- First, set any existing line item with expired gracedays to uncharged
    -- when this is a recalc. Must be done before deleting anything.
    effdate := nvl(INVH.invdate, sysdate);
       UPDATE invoicedtl
          SET invoice = 0,
              billstatus = zbill.UNCHARGED
       WHERE  custid = in_custid
         AND  (loadno = v_loadno
               or (v_loadno < 0 and orderid = v_prod_orderid and shipid = v_prod_shipid))
         AND  invoice = in_invoice
         AND  expiregrace <= effdate
         AND  statusrsn = zbill.SR_RECEIPT;

   -- get rid of old info since this is a recalc
       DELETE from invoicedtl
        WHERE custid = in_custid
          AND invoice = in_invoice
          AND statusrsn = zbill.SR_RECEIPT;

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
   else
   -- Try to find the invoice for this receipt
       OPEN C_INVH_FIND(LOAD.facility, in_custid, zbill.IT_RECEIPT, in_loadno);
       FETCH C_INVH_FIND into INVH;
       CLOSE C_INVH_FIND;
       if INVH.invoice is not null then
          if (v_loadno < 0) then
              out_errmsg := 'Receipt charges already calculated for order: ' || 
              v_prod_orderid || '-' || v_prod_shipid;
          else
              out_errmsg := 'Receipt charges already calculated for customer:'
                 ||in_custid||' Load:'||to_char(v_loadno);
          end if;
          return zbill.BAD;
       end if;
   -- Find order
       OPEN C_ORDID(v_loadno, in_custid, null);
       FETCH C_ORDID into ORD.orderid, ORD.shipid;
       CLOSE C_ORDID;
       OPEN C_ORDHDR(ORD.orderid, ORD.shipid);
       FETCH C_ORDHDR into ORD;
       CLOSE C_ORDHDR;
   end if;

   if (LOAD.loadno is null) and (v_loadno > 0) then
      out_errmsg := 'Unknown load for this receipt';
      return zbill.BAD;
   end if;

   save_pnt := 'InvH ';

-- Add delayed storage charges for receipts with expired gracedays.
   for crec in C_RS_GRACE(in_custid, v_loadno, effdate) loop
       UPDATE invoicedtl
          SET invoice = INVH.invoice,
               invtype = INVH.invtype,  
               invdate = INVH.invdate
        WHERE rowid = crec.rowid;
   
   zbs.calc_rs_grace_charge(crec.rowid, effdate);
   end loop;

-- Create Invoice header if we have misc charges for this load
   SELECT count(1)
     INTO rc
     FROM invoicedtl
    WHERE custid = CUST.custid
      AND (loadno = v_loadno
           or (v_loadno < 0 and orderid = v_prod_orderid and shipid = v_prod_shipid))
      AND (invoice = 0);
   if rc > 0 then
      if INVH.invoice is null then
          rc := zbill.get_invoicehdr('Create', zbill.IT_RECEIPT,CUST.custid,
                           LOAD.facility, in_userid, INVH);
		  INVH.loadno := v_loadno; 				   
      end if;
-- Set all misc invoicedtl for this receipt to this invoice header
     UPDATE invoicedtl
        SET invoice = INVH.invoice,
            invtype = INVH.invtype,
            invdate = INVH.invdate
      WHERE custid = in_custid
        AND (loadno = v_loadno
             or (v_loadno < 0 and orderid = v_prod_orderid and shipid = v_prod_shipid))
        AND (invoice = 0);
   end if;
   save_pnt := 'MC ';
   if INVH.invoice is null then
       rc := zbill.get_invoicehdr('Create', zbill.IT_RECEIPT,CUST.custid,
                        LOAD.facility, in_userid, INVH);
		INVH.loadno := v_loadno;				
   end if;
   rollover_receipt_charges(INVH.invoice,v_loadno,in_userid,out_errmsg);
   if (out_errmsg <> 'OKAY') then
      return zbill.BAD;
   end if;

-- ???? Check if we need to add renewal charges to this run
   CLR := null;
   OPEN C_CLR(LOAD.facility, in_custid);
   FETCH C_CLR into CLR;
   CLOSE C_CLR;

   do_renewal := FALSE;
   if LOAD.rcvddate <= CLR.lastrenewal
    and LOAD.billdate > CLR.lastupdate then
      do_renewal := TRUE;
   end if;

   if do_renewal then
     null;
     -- zut.prt('Determined it is time to do renewal calcs too');
   end if;

-- First validate quantities since some have been bad
   -- check_orderdtlrcpt(in_loadno, in_userid, errmsg);


-- For each item
   tot_xdock_qty := 0;
   tot_nonxdock_qty := 0;
   for crec in C_LD_ITEMS(v_loadno, CUST.custid) loop
        do_calc := TRUE;
        if zbill.rd_item(CUST.custid, crec.item, ITEM) = zbill.BAD then
           -- zut.prt('Customer item not found:'||CUST.custid||'/'||crec.item);
           do_calc := FALSE;
        end if;

        -- zut.prt('Customer item found:'||CUST.custid||'/'||crec.item);
     -- Determine if we are tracking lots or not
        track_lot := nvl(ITEM.lotrequired,'C');
        if track_lot = 'C' then
           track_lot := CUST.lotrequired;
        end if;
        if ITEM.lotsumreceipt = 'Y' then
            track_lot := 'N';
        end if;

     -- For this item determine it we are billing anything for receipt
        if do_calc then

    -- Determine the rate group to use for receipt for this item
    -- based on the existance of an entry for the RECEIPT business event
        zbill.rd_item_rategroup(ITEM.custid, ITEM.item, item_rategroup);


         current_event := zbill.EV_RECEIPT;
         if ORD.ordertype = 'C' then 
            current_event := zbill.EV_XDRECEIPT;
         end if;

         xdock_qty := 0;
         nonxdock_qty := 0;
         loop

           for crec2 in zbill.C_RATE_WHEN(CUST.custid, item_rategroup,
                        current_event, LOAD.facility, now_date) loop
            --zut.prt('  Rate event found:'||item_rategroup||' '||crec2.activity
            --               ||' '||crec2.billmethod);
           -- Get rate entry
              if zbill.rd_rate(rategrouptype(crec2.custid, crec2.rategroup), 
                    crec2.activity,
                    crec2.billmethod, now_date, RATE) = zbill.BAD then
           -- zut.prt('  Rate not found:'||rategroup||' '||crec2.activity
           --                ||' '||crec2.billmethod);
                  null;
              end if;

            -- Check which type of gracedays to use
            l_gracedays := RATE.gracedays;
            if (ORD.ordertype = 'C')
            and (nvl(RATE.cxd_grace,'N') = 'Y')
            then
                l_gracedays := RATE.cxd_grace_days;
            end if;
            -- NOTE: the second part of this conditional is to prevent
            -- re-adding receipt storage grace period items
              if RATE.billmethod in
                (zbill.BM_QTY, zbill.BM_QTYM, zbill.BM_FLAT,
                 zbill.BM_CWT, zbill.BM_WT, zbill.BM_QTY_BREAK,
                 zbill.BM_FLAT_BREAK, zbill.BM_WT_BREAK, zbill.BM_CWT_BREAK,
                 zbill.BM_PLT_COUNT, zbill.BM_PLT_CNT_RCPT)
              and (in_invoice is null or nvl(l_gracedays,0) = 0)
              then

           -- Check if this activity is handling/recmethod specific
              htype := null;
              OPEN C_HTYPE(RATE.activity);
              FETCH C_HTYPE into htype;
              CLOSE C_HTYPE;
              if htype is null then
                 t_activity := NULL; -- do not filter by handling code
              else
                 t_activity := RATE.activity; -- filter by handling codes
              end if;

           -- Determine qty's for this item including handling codes
           --   if necessary
              for crec3 in C_QTY(v_loadno,in_custid,  ITEM.item,
                        t_activity) loop
                  OPEN C_ORDID(v_loadno, in_custid, ITEM.item);
                  FETCH C_ORDID into orderid, shipid;
                  CLOSE C_ORDID;
                  PQ.pltqty := 0;
                  open c_PltQty(v_loadno,in_custid,ITEM.item,t_activity,crec3.lotnum);
                  fetch c_PltQty into PQ;
                  close c_PltQty;
                  if current_event in (zbill.EV_RECEIPT, zbill.EV_XDRECEIPT) 
                  then
                     cur_qty := crec3.qty;
                  elsif current_event = zbill.EV_XDOCK then
                     cur_qty := least(crec3.qty,crec3.xdqty);
                  elsif current_event = zbill.EV_NONXDOCK then
                     cur_qty := crec3.qty - least(crec3.qty,crec3.xdqty);
                  end if;
                  tot_xdock_qty := tot_xdock_qty
                                   + least(crec3.qty,crec3.xdqty);
                  tot_nonxdock_qty := tot_nonxdock_qty
                                   + crec3.qty - least(crec3.qty,crec3.xdqty);

           -- Verify we have an invoicehdr
                  if INVH.invoice is null then
                     rc := zbill.get_invoicehdr('Create',zbill.IT_RECEIPT,
                          in_custid, LOAD.facility,
                          in_userid, INVH);
					INVH.loadno := v_loadno;	  
                  end if;

                  if RATE.billmethod = zbill.BM_FLAT then
                      cur_qty := 1;
                  end if;
           -- Add entry for this type
                 if cur_qty > 0 then
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
                             calcedqty,
                             calceduom,
                             loadno,
                             invoice,
                             invtype,
                             invdate,
                             statusrsn,
                             shipid,
                             orderitem,
                             orderlot,
                             handling,
                             lastuser,
                             lastupdate,
                             businessevent
                         )
                         values
                         (
                             zbill.UNCHARGED,
                             INVH.facility,
                             CUST.custid,
                             orderid,
                             ITEM.item,
                             crec3.lotnum,
                             RATE.activity,
                             NVL(load.rcvddate, sysdate),
                             RATE.billmethod,
                             decode(crec2.automatic,'C',0,cur_qty),
                             crec3.unitofmeasure,
                             crec3.weight,
                             PQ.pltqty,
                             '*PLT',
                             LOAD.loadno,
                             INVH.invoice,
                             INVH.invtype,
                             INVH.invdate,
                             zbill.SR_RECEIPT,
                             shipid,
                             ITEM.item,
                             crec3.lotnum,
                             htype,
                             in_userid,
                             sysdate,
                             current_event
                         );
        -- If we are doing lot receipt renewals and this is a qty break
        -- method check if we are to capture the information
                   if nvl(lrr, 'N') = 'Y' 
                    and RATE.billmethod in (zbill.BM_QTY_BREAK,
                        zbill.BM_WT_BREAK, zbill.BM_CWT_BREAK) 
                   then
                        check_lrr(RATE.activity, INVH.facility, CUST.custid, 
                            ITEM.item, crec3.lotnum,
                            nvl(load.rcvddate,sysdate),
                            cur_qty, rate.uom, crec3.weight,
                            in_userid);

                   end if;
                 end if;

              end loop; -- crec3
              end if; -- RATE.billmethod in ('QTY','FLAT')
           end loop; -- crec2
           if current_event = zbill.EV_RECEIPT then
              current_event := zbill.EV_XDOCK;
           elsif current_event = zbill.EV_XDOCK then
              current_event := zbill.EV_NONXDOCK;
           else
              exit;
           end if;
         end loop;

           if do_renewal then
      -- Determine the rate group to use for renewal for this item
      -- based on the existance of an entry for the RENEWAL business event
             zbill.rd_item_rategroup(ITEM.custid, ITEM.item, item_rategroup);

             for crec2 in zbill.C_RATE_WHEN(CUST.custid, item_rategroup,
                 zbill.EV_RENEWAL, LOAD.facility, now_date) loop

             -- Get rate entry
                if zbill.rd_rate(rategrouptype(crec2.custid, crec2.rategroup), 
                  crec2.activity,
                  crec2.billmethod, now_date, RATE) = zbill.BAD then
                    null;
                end if;

                if RATE.billmethod in
                  (zbill.BM_QTY, zbill.BM_QTYM, zbill.BM_FLAT, 
                   zbill.BM_CWT, zbill.BM_WT, zbill.BM_QTY_BREAK,
                   zbill.BM_FLAT_BREAK, zbill.BM_WT_BREAK, zbill.BM_CWT_BREAK)
                then

                t_activity := NULL; -- do not filter by handling code

             -- Determine qty's for this item including handling codes
             --   if necessary
                for crec3 in C_QTY(v_loadno,in_custid,  ITEM.item,
                          t_activity) loop
                    OPEN C_ORDID(v_loadno, in_custid, ITEM.item);
                    FETCH C_ORDID into orderid, shipid;
                    CLOSE C_ORDID;

             -- Verify we have an invoicehdr
                    if INVH.invoice is null then
                       rc := zbill.get_invoicehdr('Create',zbill.IT_RECEIPT,
                            in_custid, LOAD.facility,
                            in_userid, INVH);
						INVH.loadno := v_loadno;	
                    end if;

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
                               handling,
                               lastuser,
                               lastupdate,
                               businessevent
                           )
                           values
                           (
                               zbill.UNCHARGED,
                               INVH.facility,
                               CUST.custid,
                               orderid,
                               ITEM.item,
                               crec3.lotnum,
                               RATE.activity,
                               NVL(load.rcvddate, sysdate),
                               RATE.billmethod,
                               decode(crec2.automatic,'C',0,crec3.qty),
                               crec3.unitofmeasure,
                               crec3.weight,
                               LOAD.loadno,
                               INVH.invoice,
                               INVH.invtype,
                               INVH.invdate,
                               zbill.SR_RECEIPT,
                               shipid,
                               ITEM.item,
                               crec3.lotnum,
                               htype,
                               in_userid,
                               sysdate,
                               zbill.EV_RENEWAL
                           );

                end loop; -- crec3
                end if; -- RATE.billmethod in ('QTY','FLAT')
             end loop; -- crec2
           end if; -- do_renewal

        end if;

   end loop;
   save_pnt := 'Itms ';

   -- item, rategroup, pallets, handling types
   for crec in C_PRNT_PLTQTY(LOAD.loadno, CUST.custid, now_date) loop
     if INVH.invoice is null then
        rc := zbill.get_invoicehdr('Create',zbill.IT_RECEIPT, in_custid, LOAD.facility, in_userid, INVH);
		INVH.loadno := LOAD.loadno;
      end if;
      
      if (crec.item in ('MIXED','NOCALC')) then
        select orderid, shipid into orderid, shipid
        from orderhdr
        where loadno = in_loadno and rownum = 1;
      else
        OPEN C_ORDID(in_loadno, in_custid, crec.item);
        FETCH C_ORDID into orderid, shipid;
        CLOSE C_ORDID;
      end if;
 
      if (crec.item = 'NOCALC') then
        select count(1) into v_count
        from invoicedtl
        where invoice = INVH.invoice and billmethod = zbill.BM_PARENT_BILLING
          and item = 'MIXED' and lotnumber = 'NOCALC';
          
        if (v_count = 0) then 
          insert into invoicedtl(
            billstatus, facility, custid, orderid, item, lotnumber, activity, 
            activitydate, billmethod, enteredqty, entereduom, enteredrate,
            enteredweight, loadno, invoice, invtype, invdate, statusrsn, 
            shipid, orderitem, handling, lastuser, lastupdate, businessevent,
            rategroup
          ) values (
            zbill.UNCHARGED, INVH.facility, CUST.custid, orderid, 'MIXED', null, 0,
            NVL(load.rcvddate, sysdate), zbill.BM_PARENT_BILLING, 0,'PLTS', 0,
            0, LOAD.loadno, INVH.invoice, INVH.invtype, INVH.invdate, zbill.SR_RECEIPT,
            shipid, 'MIXED', null, in_userid, sysdate, zbill.EV_RECEIPT,
            'NOCALC');
        end if;

        goto next_item;
      end if;
      
      -- there could be more than 1 entry for this bill method, for example a different rate for rec methods
      for crec2 in zbill.C_RATE_WHEN(crec.rategroup.custid, crec.rategroup.rategroup, zbill.EV_RECEIPT, LOAD.facility, now_date) loop
        if crec2.billmethod in (zbill.BM_PARENT_BILLING) then
          if zbill.rd_rate(rategrouptype(crec2.custid, crec2.rategroup), crec2.activity,
             crec2.billmethod, now_date, RATE) = zbill.BAD then
              null;
          end if;
          
          htype := null;
          open  C_HTYPE(RATE.activity);
          fetch C_HTYPE into htype;
          close C_HTYPE;
          
          if (htype is not null) then
            handling_found := false;
            for crec3 in (select code from handlingtypes where activity = RATE.activity)
            loop
              if (instr(crec.handling_types, ',' || crec3.code || ',') > 0) then
                handling_found := true;
              end if;
            end loop;
            if (not handling_found) then
              goto continue_bill_methods;
            end if;
          end if;
          
          select count(1) into v_count
          from invoicedtl
          where invoice = INVH.invoice and billmethod = zbill.BM_PARENT_BILLING
            and item = crec.item and nvl(lotnumber,'(none)') =  nvl(crec.lotnumber,'(none)')
            and loadno = LOAD.loadno and activity = RATE.activity;
            
          if (v_count = 0) then
            insert into invoicedtl(
              billstatus, facility, custid, orderid, item, lotnumber, activity, 
              activitydate, billmethod, enteredqty, entereduom, 
              enteredweight, loadno, invoice, invtype, invdate, statusrsn, 
              shipid, orderitem, handling, lastuser, lastupdate, businessevent,
              rategroup
            ) values (
              zbill.UNCHARGED, INVH.facility, CUST.custid, orderid, crec.item, 
              crec.lotnumber, RATE.activity,
              nvl(load.rcvddate, sysdate), zbill.BM_PARENT_BILLING, decode(crec2.automatic,'C',0,crec.pallets),'PLTS',
              0, LOAD.loadno, INVH.invoice, INVH.invtype, INVH.invdate, zbill.SR_RECEIPT,
              shipid, crec.item, htype, in_userid, sysdate, zbill.EV_RECEIPT,
              crec.rategroup.rategroup);
          else 
            update invoicedtl
            set enteredqty = enteredqty + decode(crec2.automatic,'C',0,crec.pallets)
            where invoice = INVH.invoice and billmethod = zbill.BM_PARENT_BILLING
              and item = crec.item and nvl(lotnumber,'(none)') =  nvl(crec.lotnumber,'(none)')
              and loadno = LOAD.loadno and activity = RATE.activity;
          end if;
        end if;
        
        << continue_bill_methods >>
          null;
      end loop;
      
      << next_item >>
        null;
   end loop;
   save_pnt := 'Prnt ';

   OPEN C_ORDID(v_loadno, in_custid, null);
   FETCH C_ORDID into ORD.orderid, ORD.shipid;
   CLOSE C_ORDID;

   if INVH.invoice is null then
       rc := zbill.get_invoicehdr('Create', zbill.IT_RECEIPT,CUST.custid,
                        LOAD.facility, in_userid, INVH);
	   INVH.loadno := v_loadno;					
   end if;

   rc := zbill.calc_automatic_charges(CUST.custid, CUST.rategroup,
      zbill.EV_RECEIPT, ORD, INVH, now_date);

   if tot_xdock_qty > 0 then
      rc := zbill.calc_automatic_charges(CUST.custid, CUST.rategroup,
         zbill.EV_XDOCK, ORD, INVH, now_date);
   end if;
   if tot_nonxdock_qty > 0 then
      rc := zbill.calc_automatic_charges(CUST.custid, CUST.rategroup,
         zbill.EV_NONXDOCK, ORD, INVH, now_date);
   end if;

   for crec in C_NOIBPRENOTE(v_loadno, in_custid) loop
      rc := zbill.calc_automatic_charges(CUST.custid, CUST.rategroup,
         zbill.EV_NOIBPRENOTE, crec, INVH, now_date);
   end loop;


-- Calculate the existing uncalculated line items.
    for crec in C_INVD(INVH.invoice) loop
        errmsg := '';
        if zbill.calculate_detail_rate(crec.rowid, now_date, errmsg) = zbill.BAD then
           null;
        end if;
    end loop;
   save_pnt := 'ClcItms ';

-- Determine all the possible mins in order

   rc := calc_receipt_minimums(INVH, v_loadno,in_custid,in_userid,
         now_date, out_errmsg);
   save_pnt := 'Mins ';

-- Calc surcharges if any
   rc := zbsc.calc_surcharges(INVH, zbill.EV_RECEIPT ,
         null,null,in_userid,now_date,out_errmsg);
   save_pnt := 'SurCh ';

-- Determine if we really need this invoicehdr
   rc := 0;
   SELECT count(*)
     INTO rc
     FROM invoicedtl
    WHERE invoice = INVH.invoice;

   if nvl(rc,0) = 0 then
      DELETE invoicehdr
       WHERE invoice = INVH.invoice;
   else
      UPDATE invoicehdr
         SET loadno = LOAD.loadno,
             orderid = ORD.orderid,
             shipid = ORD.shipid
       WHERE invoice = INVH.invoice;

       if CUST.rcptautobill = 'Y' then
          zbill.approve_invoice(INVH.invoice, zbill.NOT_REVIEWED,
                in_userid, n1, n2, n3, terrmsg);

       end if;

   end if;

   if (in_invoice is not null) and (ORD.ordertype = 'P') then
      update orderhdr
      set loadno = null
      where orderid = ORD.orderid and shipid = ORD.shipid
        and orderstatus = 'R' and ordertype = 'P';
   end if;

   save_pnt := 'ENd ';
   return zbill.GOOD;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CCusRec: '||save_pnt||substr(sqlerrm,1,80);
    return zbill.BAD;
END calc_customer_receipt;




----------------------------------------------------------------------
--
-- calc_return_minimums -
--
----------------------------------------------------------------------
FUNCTION calc_return_minimums
(
    INVH        IN      invoicehdr%rowtype,
    in_orderid  IN      number,
    in_shipid   IN      number,
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
  LOAD  loads%rowtype;
  ORD   orderhdr%rowtype;  -- fake orderheader to call rtns

-- Minimums Cursors
  CURSOR C_ID_LINE(in_orderid number, in_shipid number)
  IS
    SELECT NVL(HT.minactivity, ID.activity) activity, item, lotnumber,
           sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM handlingtypes HT, invoicedtl ID
     WHERE orderid = in_orderid
       AND shipid = in_shipid
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED)
       AND ID.activity = HT.activity(+)
       AND ID.handling = HT.code(+)
     GROUP BY NVL(HT.minactivity, ID.activity), item, lotnumber;

  CURSOR C_ID_ITEM(in_orderid number, in_shipid number)
  IS
    SELECT NVL(HT.minactivity, ID.activity) activity, item,
           sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM handlingtypes HT, invoicedtl ID
     WHERE orderid = in_orderid
       AND shipid = in_shipid
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED)
       AND ID.activity = HT.activity(+)
       AND ID.handling = HT.code(+)
     GROUP BY NVL(HT.minactivity, ID.activity), item;

  CURSOR C_ID_ORDER(in_orderid number, in_shipid number)
  IS
    SELECT NVL(HT.minactivity, ID.activity) activity,
           sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM handlingtypes HT, invoicedtl ID
     WHERE orderid = in_orderid
       AND shipid = in_shipid
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED)
       AND ID.activity = HT.activity(+)
       AND ID.handling = HT.code(+)
     GROUP BY NVL(HT.minactivity, ID.activity);

  CURSOR C_ID_INVOICE(in_orderid number, in_shipid number)
  IS
    SELECT sum(nvl(billedamt,nvl(calcedamt,0))) total
      FROM invoicedtl ID
     WHERE orderid = in_orderid
       AND shipid = in_shipid
       AND billstatus not in (zbill.UNCHARGED, zbill.DELETED);

  orderid orderhdr.orderid%type;
  shipid orderhdr.shipid%type;

  rc      integer;
  now_date date;

  item_rategroup custitem.rategroup%type;

BEGIN

    now_date := in_effdate;
-- Get the order
   ORD := null;
   OPEN C_ORDHDR(in_orderid, in_shipid);
   FETCH C_ORDHDR into ORD;
   CLOSE C_ORDHDR;


-- Get the load
    LOAD := null;
    OPEN zbill.C_LOAD(ORD.loadno);
    FETCH zbill.C_LOAD into LOAD;
    CLOSE zbill.C_LOAD;


-- Get the customer information for this receipt order
    if zbill.rd_customer(in_custid, CUST) = zbill.BAD then
       out_errmsg := 'Invalid custid = '|| in_custid;
       -- zut.prt(out_errmsg);
       return zbill.BAD;
    end if;

-- Get rid of any old minimums
    DELETE FROM invoicedtl
     WHERE orderid = in_orderid
       AND shipid = in_shipid
       AND invoice = INVH.invoice
       AND minimum is not null
       and (billstatus != zbill.DELETED or in_keep_deleted = 'N');

-- Determine all the possible mins in order

-- Check for line minimums
    for crec in C_ID_LINE(in_orderid, in_shipid) loop
    -- Check if line level minimum exists for this item
      if zbill.rd_item(CUST.custid, crec.item, ITEM) = zbill.BAD then
         null;
      end if;
      zbill.rd_item_rategroup(ITEM.custid, ITEM.item, item_rategroup);

      if zbill.check_for_minimum(CUST.custid, item_rategroup, CUST.rategroup,
                 zbill.EV_RETURN, INVH.facility, zbill.BM_MIN_LINE,
                 crec.activity, now_date, RATE) = zbill.GOOD then
           if crec.total < RATE.rate then
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, ORD,
                 crec.item, crec.lotnumber, crec.total, in_userid,
                 nvl(LOAD.rcvddate,sysdate), null, zbill.EV_RETURN, in_keep_deleted);
           end if;
      end if;
    end loop;

-- Check for item minimums
    for crec in C_ID_ITEM(in_orderid, in_shipid) loop
    -- Check if line level minimum exists for this item
      if zbill.rd_item(CUST.custid, crec.item, ITEM) = zbill.BAD then
         null;
      end if;
      zbill.rd_item_rategroup(ITEM.custid, ITEM.item, item_rategroup);

      if zbill.check_for_minimum(CUST.custid, item_rategroup, CUST.rategroup,
                 zbill.EV_RETURN, INVH.facility, zbill.BM_MIN_ITEM,
                 crec.activity, now_date, RATE) = zbill.GOOD then
           if crec.total < RATE.rate then
               -- zut.prt('Order ID is '||nvl(to_char(orderid),'*NULL*'));
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, ORD,
                 crec.item, NULL, crec.total, in_userid,
                 NVL(LOAD.rcvddate,sysdate), null, zbill.EV_RETURN, in_keep_deleted);
           end if;
      end if;
   end loop;

-- Check for order minimum (must be defined at the cust rate group level)
    for crec in C_ID_ORDER(in_orderid, in_shipid) loop
    -- Check if order level minimums exist
      if zbill.check_for_minimum(CUST.custid, NULL, CUST.rategroup,
                 zbill.EV_RETURN, INVH.facility, zbill.BM_MIN_ORDER,
                 crec.activity, now_date, RATE) = zbill.GOOD then
           if crec.total < RATE.rate then
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, ORD,
                 NULL, NULL, crec.total, in_userid,
                 NVL(LOAD.rcvddate,sysdate), null, zbill.EV_RETURN, in_keep_deleted);
           end if;
      end if;
    end loop;

-- Check for invoice minimum (must be defined at the cust rate group level)
    for crec in C_ID_INVOICE(in_orderid, in_shipid) loop
    -- Check if order level minimums exist
      if zbill.check_for_minimum(CUST.custid, NULL, CUST.rategroup,
                 zbill.EV_RETURN, INVH.facility, zbill.BM_MIN_INVOICE, NULL,
                 now_date, RATE) = zbill.GOOD then
           if crec.total < RATE.rate then
              rc := zbill.add_min_invoicedtl(CUST, RATE, INVH, ORD,
                 NULL, NULL, crec.total, in_userid,
                 NVL(LOAD.rcvddate,sysdate), null, zbill.EV_RETURN, in_keep_deleted);
           end if;
      end if;
    end loop;


    return zbill.GOOD;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CRetMins: '||substr(sqlerrm,1,80);
    return zbill.BAD;
END calc_return_minimums;




----------------------------------------------------------------------
--
-- calc_customer_return -
--
----------------------------------------------------------------------
FUNCTION calc_customer_return
(
    in_invoice  IN      number,    -- If non null this is a recalc
    in_orderid  IN      number,
    in_shipid   IN      number,
    in_custid   IN      varchar2,
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


  item_rategroup  custrate.rategroup%type;
  t_activity custrate.activity%type;

  errmsg     varchar2(200);
  do_calc    BOOLEAN;
  track_lot  char(1);
  recmethod  varchar2(2);
  hcnt       integer;           -- count of handling types for activity
  htype     varchar2(4);        -- handling type of activity


-- Local cursors
  CURSOR C_LD_ITEMS(in_orderid number, in_shipid number)
  IS
    SELECT distinct OD.item
      FROM orderdtlrcpt OD, orderhdr OH
     WHERE OH.orderid = in_orderid and OH.shipid = in_shipid
       AND OH.ordertype in ('T','Q','R','A','C','U')
       AND OD.orderid = OH.orderid
       AND OD.shipid  = OH.shipid;

  CURSOR C_QTY(in_orderid number,
               in_shipid number,
               in_item varchar2,
               in_activity varchar2)
  IS
    SELECT decode(track_lot,'Y',OD.lotnumber,'O',OD.lotnumber,'S',OD.lotnumber,'A',OD.lotnumber,null) lotnum,
           OD.uom unitofmeasure,
           sum(OD.qtyrcvd) qty,
           sum(OD.weight) weight
      FROM orderdtlrcpt OD, deletedplate DP, plate P, orderhdr OH
     WHERE OH.orderid = in_orderid and OH.shipid = in_shipid
       AND OH.ordertype in ('T','Q','R','A','C','U')
       AND OD.orderid = OH.orderid
       AND OD.shipid  = OH.shipid
       AND OD.item = in_item
       AND OD.lpid = P.lpid(+)
       AND OD.lpid = DP.lpid(+)
       AND (
           nvl(P.recmethod,DP.recmethod) in
           (select code
              from handlingtypes
             where activity = in_activity)
           OR in_activity is null
           )
      GROUP BY decode(track_lot,'Y',OD.lotnumber,'O',OD.lotnumber,'S',OD.lotnumber,'A',OD.lotnumber,null), OD.uom;

  CURSOR C_HTYPE(in_activity varchar2)
  IS
    SELECT code
      FROM handlingtypes
     WHERE activity = in_activity;

  CURSOR C_INVD(in_invoice number)
  IS
    SELECT rowid
      FROM invoicedtl
     WHERE invoice = in_invoice
       AND billstatus = zbill.UNCHARGED;

  CURSOR C_CLR(in_facility varchar2,
               in_custid varchar2)
  RETURN custlastrenewal%rowtype
  IS
    SELECT *
      FROM custlastrenewal
     WHERE facility = in_facility
       AND custid = in_custid;

  CLR custlastrenewal%rowtype;

  qty C_QTY%rowtype;

 rc integer;

 save_pnt varchar2(20);

CURSOR C_LOAD(in_loadno number)
 RETURN loads%rowtype
IS
    SELECT *
      FROM loads
     WHERE loadno = in_loadno;

  CURSOR C_INVH_FIND(in_facility varchar2,
                     in_custid varchar2,
                     in_invtype varchar2,
                     in_orderid number,
                     in_shipid number)
  RETURN invoicehdr%rowtype
  IS
     SELECT *
       FROM invoicehdr
      WHERE custid = in_custid
        AND facility = in_facility
        AND invtype = in_invtype
        AND orderid = in_orderid;


 now_date date;

BEGIN

   out_errmsg := 'OKAY';
   save_pnt := 'Strt ';


-- Upon close of the receipt we need to calculate the charges
--   we are generating for the receipt invoice
--   this may require rolling multiple detail lines into
--   a single 'new' billing record or
--   processing the individual invoicedtl lines

-- Get the order
   ORD := null;
   OPEN C_ORDHDR(in_orderid, in_shipid);
   FETCH C_ORDHDR into ORD;
   CLOSE C_ORDHDR;

-- Get the load
    LOAD := null;
    OPEN zbill.C_LOAD(ORD.loadno);
    FETCH zbill.C_LOAD into LOAD;
    CLOSE zbill.C_LOAD;
   save_pnt := 'Gld ';

    now_date := nvl(LOAD.rcvddate,sysdate);

-- Get the customer information for this receipt order
    if zbill.rd_customer(in_custid, CUST) = zbill.BAD then
       out_errmsg := 'Invalid custid = '|| in_custid;
       -- zut.prt(out_errmsg);
       return zbill.BAD;
    end if;
   save_pnt := 'RCus ';

-- Try to locate the existing invoice header
   INVH := null;
   if in_invoice is not null then
   -- get rid of old info since this is a recalc
       DELETE from invoicedtl
        WHERE custid = in_custid
          AND invoice = in_invoice
          AND statusrsn = zbill.SR_RECEIPT;

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
   else
   -- Try to find the invoice for this receipt
       OPEN C_INVH_FIND(ORD.tofacility, in_custid, zbill.IT_RECEIPT,
                       in_orderid, in_shipid);
       FETCH C_INVH_FIND into INVH;
       CLOSE C_INVH_FIND;
       if INVH.invoice is not null then
          out_errmsg := 'Return charges already calculated for customer:'
            ||in_custid||' Order:'||to_char(in_orderid);
          return zbill.BAD;
       end if;
   end if;

   save_pnt := 'InvH ';

-- Create Invoice header if we have misc charges for this load
   SELECT count(1)
     INTO rc
     FROM invoicedtl
    WHERE custid = CUST.custid
      AND orderid = in_orderid
      AND shipid = in_shipid
      AND invoice = 0;
   if rc > 0 then
      if INVH.invoice is null then
          rc := zbill.get_invoicehdr('Create', zbill.IT_RECEIPT,CUST.custid,
                           ORD.tofacility, in_userid, INVH);
		  INVH.loadno := LOAD.loadno;						   
      end if;
-- Set all misc invoicedtl for this receipt to this invoice header
     UPDATE invoicedtl
        SET invoice = INVH.invoice,
            invtype = INVH.invtype,
            invdate = INVH.invdate
      WHERE custid = in_custid
        AND orderid = in_orderid
        AND shipid = in_shipid
        AND invoice = 0;
   end if;
   save_pnt := 'MC ';

-- For each item
   for crec in C_LD_ITEMS(in_orderid, in_shipid) loop
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
        if ITEM.lotsumreceipt = 'Y' then
            track_lot := 'N';
        end if;

     -- For this item determine it we are billing anything for receipt
        if do_calc then

    -- Determine the rate group to use for receipt for this item
    -- based on the existance of an entry for the RECEIPT business event
           zbill.rd_item_rategroup(ITEM.custid, ITEM.item, item_rategroup);

           for crec2 in zbill.C_RATE_WHEN(CUST.custid, item_rategroup,
                        zbill.EV_RETURN, INVH.facility, now_date) loop
           -- zut.prt('  Rate event found:'||rategroup||' '||crec2.activity
           --                ||' '||crec2.billmethod);
           -- Get rate entry
              if zbill.rd_rate(rategrouptype(crec2.custid, crec2.rategroup), 
                    crec2.activity,
                    crec2.billmethod, now_date, RATE) = zbill.BAD then
           -- zut.prt('  Rate not found:'||rategroup||' '||crec2.activity
           --                ||' '||crec2.billmethod);
                  null;
              end if;

            -- NOTE: the second part of this conditional is to prevent
            -- re-adding receipt storage grace period items
              if RATE.billmethod in
                (zbill.BM_QTY, zbill.BM_QTYM, zbill.BM_FLAT, 
                 zbill.BM_CWT, zbill.BM_WT, zbill.BM_QTY_BREAK,
                 zbill.BM_FLAT_BREAK, zbill.BM_WT_BREAK, zbill.BM_CWT_BREAK,
                 zbill.BM_PLT_COUNT)
              and (in_invoice is null or nvl(RATE.gracedays,0) = 0)
              then

           -- Check if this activity is handling/recmethod specific
              htype := null;
              OPEN C_HTYPE(RATE.activity);
              FETCH C_HTYPE into htype;
              CLOSE C_HTYPE;
              if htype is null then
                 t_activity := NULL; -- do not filter by handling code
              else
                 t_activity := RATE.activity; -- filter by handling codes
              end if;

           -- Determine qty's for this item including handling codes
           --   if necessary
              for crec3 in C_QTY(in_orderid, in_shipid, ITEM.item,
                        t_activity) loop
           -- Verify we have an invoicehdr
                  if INVH.invoice is null then
                     rc := zbill.get_invoicehdr('Create',zbill.IT_RECEIPT,
                          in_custid, ORD.tofacility,
                          in_userid, INVH);
					 INVH.loadno := LOAD.loadno;	  
                  end if;

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
                             handling,
                             lastuser,
                             lastupdate,
                             businessevent
                         )
                         values
                         (
                             zbill.UNCHARGED,
                             INVH.facility,
                             CUST.custid,
                             in_orderid,
                             ITEM.item,
                             crec3.lotnum,
                             RATE.activity,
                             NVL(load.rcvddate, sysdate),
                             RATE.billmethod,
                             decode(crec2.automatic,'C',0,crec3.qty),
                             crec3.unitofmeasure,
                             crec3.weight,
                             LOAD.loadno,
                             INVH.invoice,
                             INVH.invtype,
                             INVH.invdate,
                             zbill.SR_RECEIPT,
                             in_shipid,
                             ITEM.item,
                             crec3.lotnum,
                             htype,
                             in_userid,
                             sysdate,
                             zbill.EV_RETURN
                         );

              end loop; -- crec3
              end if; -- RATE.billmethod in ('QTY','FLAT')
           end loop; -- crec2

        end if;

   end loop;
   save_pnt := 'Itms ';


   if INVH.invoice is null then
       rc := zbill.get_invoicehdr('Create', zbill.IT_RECEIPT,CUST.custid,
                        ORD.tofacility, in_userid, INVH);
       INVH.loadno := LOAD.loadno;						
   end if;

   rc := zbill.calc_automatic_charges(CUST.custid, CUST.rategroup,
      zbill.EV_RETURN, ORD, INVH, now_date);


-- Calculate the existing uncalculated line items.
    for crec in C_INVD(INVH.invoice) loop
        errmsg := '';
        if zbill.calculate_detail_rate(crec.rowid, now_date, errmsg) = zbill.BAD then
           null;
           -- zut.prt('CR: '||errmsg);
        end if;
    end loop;
   save_pnt := 'ClcItms ';

-- Determine all the possible mins in order

   rc := calc_return_minimums(INVH, in_orderid, in_shipid,
                           in_custid,in_userid,now_date,out_errmsg);
   save_pnt := 'Mins ';

   rc := zbsc.calc_surcharges(INVH, zbill.EV_RETURN ,
         null,null,in_userid,now_date,out_errmsg);
   save_pnt := 'SurCh ';

-- Determine if we really need this invoicehdr
   rc := 0;
   SELECT count(*)
     INTO rc
     FROM invoicedtl
    WHERE invoice = INVH.invoice;

   if nvl(rc,0) = 0 then
      DELETE invoicehdr
       WHERE invoice = INVH.invoice;
   else
      UPDATE invoicehdr
         SET loadno = LOAD.loadno,
             orderid = in_orderid
       WHERE invoice = INVH.invoice;
   end if;

   save_pnt := 'ENd ';

   return zbill.GOOD;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CCusRet: '||save_pnt||substr(sqlerrm,1,80);
    return zbill.BAD;
END calc_customer_return;

----------------------------------------------------------------------
--
-- calc_receipt_bills -
--
----------------------------------------------------------------------
FUNCTION calc_receipt_bills
(
    in_loadno   IN      number,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer
IS
  CURSOR C_LDCUST(in_loadno number)
  IS
    SELECT distinct custid
      FROM orderhdr
     WHERE loadno = in_loadno and orderstatus <> '9';

  rc integer;

  LOAD  loads%rowtype;

BEGIN
  out_errmsg := '';

-- Get the load
  LOAD := null;
  OPEN zbill.C_LOAD(in_loadno);
  FETCH zbill.C_LOAD into LOAD;
  CLOSE zbill.C_LOAD;

-- Verify this load exists
  if LOAD.loadno is null then
      out_errmsg := 'Load does not exist.';
      return zbill.BAD;
  end if;

-- verify this is an inbound customer load
--  if LOAD.loadtype != 'INC' then
  if substr(LOAD.loadtype,1,1) != 'I' then
    out_errmsg := 'Load is not Inbound type.';
    return zbill.BAD;
  end if;

-- verify we haven't already billed the load
  if LOAD.billdate is not null then
      out_errmsg := 'Load already billed.';
      return zbill.BAD;
  end if;

-- Update the load with the bill date
  UPDATE loads
     SET billdate = sysdate
   WHERE loadno = in_loadno;

  for crec in C_LDCUST(in_loadno) loop
      rc := calc_customer_receipt(NULL, in_loadno, crec.custid,
                                  in_userid, out_errmsg);
      if rc != zbill.GOOD then
--         rollback;
         return zbill.BAD;
      end if;

      zbs.calc_receipt_anniversary_days(in_loadno, crec.custid, in_userid,
            out_errmsg);
      if out_errmsg != 'OKAY' then
        return zbill.BAD;
      end if;
  end loop;
  out_errmsg := 'OKAY';

  return zbill.GOOD;
EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CRecBills: '||substr(sqlerrm,1,80);
--    rollback;
    return zbill.BAD;
END calc_receipt_bills;

----------------------------------------------------------------------
--
-- create_receipt_charges -
--
----------------------------------------------------------------------
FUNCTION create_receipt_charges
(
    in_loadno   IN      number,
    in_custid   IN      varchar2,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer
is
  v_return_code integer;
begin

  v_return_code := calc_customer_receipt(null, in_loadno, in_custid, in_userid, out_errmsg);
  if (v_return_code = zbill.BAD) then
    return zbill.BAD;
  end if;
  
  zbs.calc_receipt_anniversary_days(in_loadno, in_custid, in_userid, out_errmsg);
  if out_errmsg != 'OKAY' then
    return zbill.BAD;
  end if;
  
  out_errmsg := 'OKAY';
  return zbill.GOOD;
  
end create_receipt_charges;

----------------------------------------------------------------------
--
-- calc_prod_receipt_bills -
--
----------------------------------------------------------------------
FUNCTION calc_prod_receipt_bills
(
    in_orderid  IN      number,
    in_shipid   IN      number,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer
as
  v_orderhdr orderhdr%rowtype;
  v_temp_load number;
  rc integer;
begin

  begin
    select * into v_orderhdr
    from orderhdr
    where orderid = in_orderid and shipid = in_shipid;
  exception
    when others then
      out_errmsg := 'Orderhdr not found';
      return zbill.BAD;
  end;
  
  if (v_orderhdr.ordertype <> 'P') then
    out_errmsg := 'Order is not production order';
    return zbill.BAD;
  end if;
  
  if (v_orderhdr.orderstatus <> 'R') then
    out_errmsg := 'Order status is not received';
    return zbill.BAD;
  end if;
  
  v_temp_load := (in_orderid * 100 + in_shipid) * -1;
  update orderhdr
  set loadno = v_temp_load
  where orderid = in_orderid and shipid = in_shipid;
  
  rc := calc_customer_receipt(NULL, v_temp_load, v_orderhdr.custid, in_userid, out_errmsg);
  if rc != zbill.GOOD then
     return zbill.BAD;
  end if;

  zbs.calc_receipt_anniversary_days(v_temp_load, v_orderhdr.custid, in_userid, out_errmsg);
  if out_errmsg != 'OKAY' then
    return zbill.BAD;
  end if;
  
  update orderhdr
  set loadno = null
  where orderid = in_orderid and shipid = in_shipid;
  
  return zbill.GOOD;
end calc_prod_receipt_bills;

procedure rollover_receipt_charges
(
    in_invoice in       number,
    in_loadno  in       number,
    in_userid  in       varchar2,
    out_errmsg in out   varchar2
)
is
begin
  out_errmsg := 'OKAY';
  for rec in (select orderid, shipid from orderhdr where loadno = in_loadno)
  loop
    zbill.rollover_preenter_charges(in_invoice,rec.orderid,rec.shipid,in_userid,out_errmsg);
    if (out_errmsg <> 'OKAY') then
      return;
    end if;
  end loop;
end rollover_receipt_charges;
end zbillreceipt;
/

show errors package body zbillreceipt;
exit;
