--
-- $Id$
--
create or replace package alps.zinvcmt as
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
-- invoiceitmcomments
--
----------------------------------------------------------------------
FUNCTION invoiceitmcomments
(
    in_rowid    IN      rowid,
    in_invoice   IN      number
)
RETURN varchar2;

----------------------------------------------------------------------
--
--  invitemexpdate
--
----------------------------------------------------------------------
FUNCTION invitemexpdate
(
    in_orderid  IN  number,
    in_shipid   IN  number,
    in_item     IN  varchar2,
    in_lot      IN  varchar2
)
RETURN date;

----------------------------------------------------------------------
--
--  invitemmandate
--
----------------------------------------------------------------------
FUNCTION invitemmandate
(
    in_orderid  IN  number,
    in_shipid   IN  number,
    in_item     IN  varchar2,
    in_lot      IN  varchar2
)
RETURN date;

----------------------------------------------------------------------
--
--  invitemqtyrcvd
--
----------------------------------------------------------------------
FUNCTION invitemqtyrcvd
(
    in_orderid  IN  number,
    in_shipid   IN  number,
    in_item     IN  varchar2,
    in_lot      IN  varchar2
)
RETURN number;

PRAGMA RESTRICT_REFERENCES (invoiceitmcomments, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (invitemexpdate, WNDS, WNPS);
PRAGMA RESTRICT_REFERENCES (invitemmandate, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (invitemqtyrcvd, WNDS, WNPS, RNPS);

end zinvcmt;
/

exit;
