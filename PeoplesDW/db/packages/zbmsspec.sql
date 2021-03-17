--
-- $Id$
--
create or replace package alps.zbillmisc as
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
-- recalc_misc -
--
----------------------------------------------------------------------
FUNCTION recalc_misc
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
-- recalc_freight_misc -
--
----------------------------------------------------------------------
FUNCTION recalc_freight_misc
(
    in_invoice  IN      number,
    in_loadno   IN      number,   -- really a dummy field
    in_custid   IN      varchar2,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
RETURN integer;

FUNCTION recalc_misc_min_and_srchg
(
    INVH        IN      invoicehdr%rowtype,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2,
    in_keep_deleted IN    varchar2 default 'N'
)
RETURN integer;

end zbillmisc;
/

-- exit;
