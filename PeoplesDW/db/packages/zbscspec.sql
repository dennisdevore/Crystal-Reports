--
-- $Id$
--
create or replace package alps.zbillsurcharge as
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************



-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************


----------------------------------------------------------------------
--
-- calc_minimums -
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
RETURN integer;

----------------------------------------------------------------------
--
-- calc_surcharges -
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
RETURN integer;

----------------------------------------------------------------------
--
-- calc_access_inv_surcharges -
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
RETURN integer;

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
RETURN integer;

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
RETURN integer;

PRAGMA RESTRICT_REFERENCES (check_activity_facility, WNDS, WNPS, RNPS);


end zbillsurcharge;
/

exit;
