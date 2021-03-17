--
-- $Id$
--
create or replace package alps.zbillreceipt as
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************


-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************

-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************




----------------------------------------------------------------------
--
-- calc_receipt_minimums -
--
----------------------------------------------------------------------
FUNCTION xdock_qty
   (in_orderid IN number,
    in_shipid  IN number,
    in_item    IN varchar2,
    in_lot     IN varchar2)
RETURN number;
PRAGMA RESTRICT_REFERENCES (xdock_qty, wnds);

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
RETURN integer;


----------------------------------------------------------------------
--
-- calc_customer_receipt -
--
----------------------------------------------------------------------
FUNCTION calc_customer_receipt
(
    in_invoice  IN      number,    -- If non null this is a recalc
    in_loadno   IN      number,
    in_custid   IN      varchar2,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer;


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
RETURN integer;


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
RETURN integer;


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
RETURN integer;

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
RETURN integer;

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
RETURN integer;

procedure rollover_receipt_charges
(
    in_invoice in       number,
    in_loadno  in       number,
    in_userid  in       varchar2,
    out_errmsg in out   varchar2
);
end zbillreceipt;
/

show errors package zbillreceipt;
exit;
