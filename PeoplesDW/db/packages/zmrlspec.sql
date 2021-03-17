--
-- $Id$
--
create or replace PACKAGE alps.zmasterreceiptlimits
IS

PROCEDURE check_master_limits
(
    in_orderid      IN  number,
    in_shipid       IN  number,
    in_check_type   IN  varchar2,   -- A-Assignment, C-Close
    out_msg         OUT varchar2
);

----------------------------------------------------------------------
PROCEDURE set_master_receipt
(
    in_orderid      IN  number,
    in_shipid       IN  number,
    out_msg         OUT varchar2
);


END zmasterreceiptlimits;
/
exit;
