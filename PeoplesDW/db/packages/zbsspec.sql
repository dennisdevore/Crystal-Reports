--
-- $Id$
--
create or replace package alps.zbillstorage as
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************

-- Return Status
GOOD            CONSTANT        integer := 1;
BAD             CONSTANT        integer := 0;


----------------------------------------------------------------------
--
-- daily_renewal_process -
--
----------------------------------------------------------------------
FUNCTION daily_renewal_process
(
    in_checkdate IN      date,
    out_errmsg  IN OUT  varchar2
)
RETURN integer;

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
RETURN integer;



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
RETURN integer;

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
RETURN integer;


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
RETURN integer;

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
);

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
);

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
);

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
);

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
);

----------------------------------------------------------------------
--
-- daily_billing_job
--
----------------------------------------------------------------------
PROCEDURE daily_billing_job;

----------------------------------------------------------------------
--
-- check_daily_billing
--
----------------------------------------------------------------------
FUNCTION check_daily_billing
(
    in_effdate  date
)
RETURN boolean;

----------------------------------------------------------------------
--
-- calc_rs_grace_charge -
--
----------------------------------------------------------------------
PROCEDURE calc_rs_grace_charge
(
    in_rowid    IN      rowid,
    in_effdate  IN      date
);

end zbillstorage;
/

-- exit;
