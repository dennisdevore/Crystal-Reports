--
-- $Id$
--
create or replace package alps.zbilling as
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************

-- Bill Status
RECALC          CONSTANT        char(1) := 'R';
ESTIMATED       CONSTANT        char(1) := 'E';
UNCHARGED       CONSTANT        char(1) := '0';
NOT_REVIEWED    CONSTANT        char(1) := '1';
REVIEWED        CONSTANT        char(1) := '2';
BILLED          CONSTANT        char(1) := '3';
DELETED         CONSTANT        char(1) := '4';

-- Return Status
GOOD            CONSTANT        integer := 1;
BAD             CONSTANT        integer := 0;

-- Invoice Types
IT_RECEIPT      CONSTANT        varchar2(1) := 'R';
IT_STORAGE      CONSTANT        varchar2(1) := 'S';
IT_ACCESSORIAL  CONSTANT        varchar2(1) := 'A';
IT_MISC         CONSTANT        varchar2(1) := 'M';
IT_CREDIT       CONSTANT        varchar2(1) := 'C';

-- My billing business events
EV_ANVD         CONSTANT        varchar2(4) := 'ANVD';
EV_ANVR         CONSTANT        varchar2(4) := 'ANVR';
EV_RECEIPT      CONSTANT        varchar2(4) := 'RECO';
EV_XDOCK        CONSTANT        varchar2(4) := 'RCXD';
EV_NONXDOCK     CONSTANT        varchar2(4) := 'RCNX';
EV_RENEWAL      CONSTANT        varchar2(4) := 'RENW';
EV_BILLING      CONSTANT        varchar2(4) := 'BILL';
EV_SHIP         CONSTANT        varchar2(4) := 'SHIP';
EV_SMALLPKG     CONSTANT        varchar2(4) := 'SPS';
EV_LTL          CONSTANT        varchar2(4) := 'LTL';
EV_RETURN       CONSTANT        varchar2(4) := 'RETO';
EV_SMALL        CONSTANT        varchar2(4) := 'SMST';
EV_CPCK         CONSTANT        varchar2(4) := 'CPCK';
EV_SAMEDAYSHIP  CONSTANT        varchar2(4) := 'SDSH';
EV_NOIBPRENOTE  CONSTANT        varchar2(4) := 'NOIB';
EV_MASTERBOL    CONSTANT        varchar2(4) := 'MBOL';
EV_MISC         CONSTANT        varchar2(4) := 'MISC';
EV_XDSHIP       CONSTANT        varchar2(4) := 'XDCL';
EV_XDRECEIPT    CONSTANT        varchar2(4) := 'XDRC';
EV_SEA          CONSTANT        varchar2(4) := 'SEA';

-- VALUES TO GO INTO INVOICE DETAIL WHEN THERE ISN'T A REAL BUSINESS EVENT
EV_FREIGHT      CONSTANT        varchar2(12) := 'FREIGHT';
EV_RFMISC       CONSTANT        varchar2(12) := 'RFMISC';
EV_IMPORT       CONSTANT        varchar2(12) := 'IMPORT';
EV_MULTISHIP    CONSTANT        varchar2(12) := 'MULTISHIP';

-- Bill Methods
BM_CWT          CONSTANT        varchar2(4) := 'CWT';
BM_QTY          CONSTANT        varchar2(4) := 'QTY';
BM_QTYM         CONSTANT        varchar2(4) := 'QTYM';
BM_FLAT         CONSTANT        varchar2(4) := 'FLAT';
BM_PAGE         CONSTANT        varchar2(4) := 'PAGE';
BM_WT           CONSTANT        varchar2(4) := 'WT';
BM_MIN_CHARGE   CONSTANT        varchar2(4) := 'PCHG';
BM_MIN_LINE     CONSTANT        varchar2(4) := 'LINE';
BM_MIN_ITEM     CONSTANT        varchar2(4) := 'ITEM';
BM_MIN_ORDER    CONSTANT        varchar2(4) := 'ORDR';
BM_MIN_INVOICE  CONSTANT        varchar2(4) := 'INV';
BM_MIN_ACCOUNT  CONSTANT        varchar2(4) := 'ACCT';
BM_SC_LINE      CONSTANT        varchar2(4) := 'SCLN';
BM_SC_ITEM      CONSTANT        varchar2(4) := 'SCIT';
BM_SC_ORDER     CONSTANT        varchar2(4) := 'SCOR';
BM_SC_INVOICE   CONSTANT        varchar2(4) := 'SCIN';
BM_PLT_COUNT    CONSTANT        varchar2(4) := 'PLCT';
BM_PLT_CNT_BRK  CONSTANT        varchar2(4) := 'PLCB';
BM_PLT_CNT_RCPT CONSTANT        varchar2(4) := 'PCBR';
BM_LOC_USAGE    CONSTANT        varchar2(4) := 'LUCT';
BM_QTY_BREAK    CONSTANT        varchar2(4) := 'QTYB';
BM_WT_BREAK     CONSTANT        varchar2(4) := 'WTB';
BM_FLAT_BREAK   CONSTANT        varchar2(4) := 'FLTB';
BM_CWT_BREAK    CONSTANT        varchar2(4) := 'CWTB';
BM_FREIGHT      CONSTANT        varchar2(4) := 'FGHT';
BM_FULL_PICK    CONSTANT        varchar2(4) := 'FULL';
BM_PART_PICK    CONSTANT        varchar2(4) := 'PART';
BM_QTY_LOT_RCPT CONSTANT        varchar2(4) := 'QTLR';
BM_WT_LOT_RCPT  CONSTANT        varchar2(4) := 'WTLR';
BM_CWT_LOT_RCPT CONSTANT        varchar2(4) := 'CWLR';
BM_UCC_LABELS   CONSTANT        varchar2(4) := 'UCCL';
BM_PALLET_BILLING CONSTANT      varchar2(4) := 'PLTB';
BM_PCT_SALE     CONSTANT        varchar2(4) := 'POS';
BM_MULT_CTN     CONSTANT        varchar2(4) := 'MULT';
BM_LOAD_PLTS    CONSTANT        varchar2(4) := 'LDPL';
BM_HDR_PASSTHRU_MATCH CONSTANT  varchar2(4) := 'HPTM';
BM_HDR_PASSTHRU_NUMBER CONSTANT varchar2(4) := 'HPTN';
BM_PARENT_BILLING CONSTANT      varchar2(4) := 'PRNT';
BM_ORDER_QTY_BREAK CONSTANT      varchar2(4) := 'OQTB';

-- Bill Types
BT_RENEWAL      CONSTANT        varchar2(12) := 'Renewal';
BT_RECEIPT      CONSTANT        varchar2(12) := 'Receipt';
BT_ACCESSORIAL  CONSTANT        varchar2(12) := 'Accessorial';
BT_MISC         CONSTANT        varchar2(12) := 'Misc';
BT_DEFAULT      CONSTANT        varchar2(12) := 'Default';

-- Calc Types from custrate
CT_ROUNDUP      CONSTANT        varchar2(1)  := 'R';
CT_CALCOUT      CONSTANT        varchar2(1)  := 'C';

-- Status Reason
SR_RECEIPT      CONSTANT        varchar2(4)  := 'RCPT';
SR_MISC         CONSTANT        varchar2(4)  := 'MISC';
SR_ANVR         CONSTANT        varchar2(4)  := 'ANVR';
SR_ANVD         CONSTANT        varchar2(4)  := 'ANVD';
SR_OUTB         CONSTANT        varchar2(4)  := 'OUTB';
SR_RENEW        CONSTANT        varchar2(4)  := 'RNEW';

-- Daily Billing Execute String
DAILY_BILLING   CONSTANT        varchar2(25) := 'zbs.daily_billing_job;';



-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************


----------------------------------------------------------------------
CURSOR CINVD_ROWID(in_rowid ROWID)
 RETURN invoicedtl%rowtype
IS
    SELECT *
      FROM invoicedtl
     WHERE rowid = in_rowid;
----------------------------------------------------------------------
CURSOR C_INVH(in_invoice number)
 RETURN invoicehdr%rowtype
IS
    SELECT *
      FROM invoicehdr
     WHERE invoice = in_invoice;
----------------------------------------------------------------------
CURSOR C_ITEM(in_cust varchar2, in_item varchar2)
 RETURN custitem%rowtype
IS
    SELECT *
      FROM custitem
     WHERE custid = in_cust
       AND item = in_item;
----------------------------------------------------------------------
CURSOR C_LOAD(in_loadno number)
 RETURN loads%rowtype
IS
    SELECT *
      FROM loads
     WHERE loadno = in_loadno;
----------------------------------------------------------------------
CURSOR C_RATE(in_rategroup  rategrouptype, -- varchar2,
              in_activity   varchar2,
              in_billmethod varchar2,
              in_effdate    date)
RETURN custrate%rowtype
IS
    SELECT CR.*
      FROM custrategroup G, custrate CR
     WHERE CR.custid = in_rategroup.custid
       AND CR.rategroup = in_rategroup.rategroup
       AND CR.activity = in_activity
       AND CR.billmethod = in_billmethod
       AND G.custid = in_rategroup.custid
       AND G.rategroup = in_rategroup.rategroup
       AND G.status = 'ACTV'
       AND CR.effdate  =
           (SELECT max(effdate)
              FROM custrate
             WHERE custid = CR.custid
               AND rategroup = CR.rategroup
               AND activity = in_activity
               AND billmethod = CR.billmethod
               AND effdate <= trunc(in_effdate));
----------------------------------------------------------------------
CURSOR C_RATE_WHEN(in_cust  varchar2,
              in_rategroup  varchar2,
              in_event      varchar2,
              in_facility   varchar2,
              in_effdate    date)
RETURN custratewhen%rowtype
IS
    SELECT W.*
      FROM custrategroup G, custactvfacilities F, custratewhen W
     WHERE W.custid 
            = zbut.rategroup(in_cust, in_rategroup).custid
       AND W.rategroup
            = zbut.rategroup(in_cust, in_rategroup).rategroup
       AND W.businessevent  = in_event
       AND W.automatic in ('A','C')
       AND G.custid = W.custid
       AND G.rategroup = W.rategroup
       AND G.status = 'ACTV'
       AND W.custid = F.custid(+)
       AND W.activity = F.activity(+)
       AND 0 < instr(','||nvl(F.facilities,in_facility)||',', 
               ','||in_facility||',')
       AND W.effdate  =
           (SELECT max(effdate)
              FROM custrate
             WHERE custid = W.custid
               AND activity = W.activity
               AND billmethod = W.billmethod
               AND rategroup = W.rategroup
               AND effdate <= trunc(in_effdate));
----------------------------------------------------------------------
CURSOR C_RATE_WHEN_ACTV(in_cust varchar2,
              in_rategroup  varchar2,
              in_event      varchar2,
              in_activity   varchar2,
              in_facility   varchar2,
              in_effdate   date)
RETURN custratewhen%rowtype
IS
    SELECT W.*
      FROM custrategroup G, custactvfacilities F, custratewhen W
     WHERE W.custid
            = zbut.rategroup(in_cust,in_rategroup).custid
       AND W.rategroup
            = zbut.rategroup(in_cust,in_rategroup).rategroup
       AND W.businessevent  = in_event
       AND W.activity = NVL(in_activity,W.activity)
       AND W.automatic in ('A','C')
       AND G.custid = W.custid
       AND G.rategroup = W.rategroup
       AND G.status = 'ACTV'
       AND W.custid = F.custid(+)
       AND W.activity = F.activity(+)
       AND 0 < instr(','||nvl(F.facilities,in_facility)||',', 
               ','||in_facility||',')
       AND effdate  =
           (SELECT max(effdate)
              FROM custratewhen
             WHERE custid = W.custid
               AND businessevent = in_event
               AND activity = W.activity
               AND billmethod = W.billmethod
               AND rategroup = W.rategroup
               AND automatic in ('A','C')
               AND effdate <= trunc(in_effdate));
----------------------------------------------------------------------
CURSOR C_UOM(in_cust varchar2,
             in_item varchar2,
             in_from_uom varchar2)
RETURN custitemuom%rowtype
IS
   SELECT *
     FROM custitemuom
    WHERE custid = in_cust
      AND item   = in_item
      AND fromuom = in_from_uom;

----------------------------------------------------------------------
CURSOR C_CUST(in_custid varchar2)
RETURN customer%rowtype
IS
    SELECT *
      FROM customer
     WHERE custid = in_custid;

----------------------------------------------------------------------
CURSOR C_CUST_ALL
RETURN customer%rowtype
IS
    SELECT *
      FROM customer;

----------------------------------------------------------------------
CURSOR C_ORDHDR(in_orderid number)
RETURN orderhdr%rowtype
IS
    SELECT *
      FROM orderhdr
     WHERE orderid = in_orderid;

----------------------------------------------------------------------
CURSOR C_CRT_INVOICE(
    in_facility varchar2,
    in_custid   varchar2,
    in_csr      varchar2,
    in_invtype  varchar2,
    in_userid   varchar2
)
IS
    SELECT DISTINCT I.facility, I.custid, invtype
      FROM userheader U, invoicehdr I
     WHERE I.facility = nvl(in_facility,I.facility)
       AND invstatus = zbill.REVIEWED
       AND I.custid = nvl(in_custid,I.custid)
       AND invtype = nvl(in_invtype,invtype)
       AND I.custid in 
            (SELECT custid 
               FROM customer 
              WHERE nvl(csr,'XXX') = nvl(in_csr,nvl(csr,'XXX')))
       AND U.nameid = in_userid
       AND (U.allcusts = 'A'
          OR (U.allcusts = 'S' 
            AND I.custid in (select custid
                             from usercustomer
                            where nameid = in_userid)))
     ORDER BY I.custid, invtype, I.facility;

----------------------------------------------------------------------



-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************




----------------------------------------------------------------------
--
-- rd_customer - return a customer row
--
----------------------------------------------------------------------
FUNCTION rd_customer
(
    in_custid   IN      varchar2,
    out_cust    OUT     customer%rowtype
)
RETURN integer;


----------------------------------------------------------------------
--
-- rd_item - read custitem row
--
----------------------------------------------------------------------
FUNCTION rd_item
(
    in_custid   IN      varchar2,
    in_item     IN      varchar2,
    out_item    OUT     custitem%rowtype
)
RETURN integer;

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
;

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
RETURN integer;

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
);

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
RETURN integer;

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
RETURN integer;


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
RETURN integer;

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
RETURN integer;

----------------------------------------------------------------------
--
-- Calculate the rate information for a detail line in the invoicedtl
--           table
--
----------------------------------------------------------------------
FUNCTION calculate_detail_rate
(
    in_rowid    IN      rowid,
    in_effdate  IN      date,
    out_errmsg  OUT     varchar2
)
RETURN integer;

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
RETURN integer;

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
);

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
);

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
);

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
);


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
);

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
);

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
);

----------------------------------------------------------------------
--
-- get_next_invoice -
--
----------------------------------------------------------------------
PROCEDURE get_next_invoice
(
    out_invoice OUT     number,
    out_msg     IN OUT  varchar2
);

----------------------------------------------------------------------
--
-- set_invoice_to_master
--
----------------------------------------------------------------------
PROCEDURE set_invoice_to_master
(
    in_invoice  IN      number,
    out_msg     IN OUT  varchar2
);

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
);

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
);


----------------------------------------------------------------------
--
-- set_invoice_printed
--
----------------------------------------------------------------------
PROCEDURE set_invoice_printed
(
    in_master   IN      varchar2
);

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
);


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
);

----------------------------------------------------------------------
--
-- add_asof_invetory
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
);

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
);

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
);

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
);

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
);

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
);

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
);

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
);

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
);

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
);

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
RETURN integer;

----------------------------------------------------------------------
--
-- get_test_invoiceid - get next test invoice id
--
----------------------------------------------------------------------
PROCEDURE get_test_invoiceid
(
    out_invoiceid   OUT varchar2
);

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
RETURN integer;

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
RETURN integer;

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
RETURN integer;

----------------------------------------------------------------------
--
-- check_billschedule
--
----------------------------------------------------------------------
PROCEDURE check_billschedule
(
    in_custid   IN  varchar2,
    out_errmsg  OUT varchar2
);

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
);

PROCEDURE rollover_preenter_charges
(
    in_invoice  IN      number,
    in_orderid  IN      number,
    in_shipid   IN      number,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
);

end zbilling;
/

show errors package zbilling;
exit;
