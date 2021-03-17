--
-- $Id: zexppecasspec.sql 1 2005-05-26 12:20:03Z ed $
--
create or replace PACKAGE alps.zexportprocpecas

Is

----------------------------------------------------------------------
--
-- order_skids
--
----------------------------------------------------------------------
FUNCTION order_skids
(
    in_orderid      number,
    in_shipid       number
)
RETURN number;

----------------------------------------------------------------------
--
-- order_cartons
--
----------------------------------------------------------------------
FUNCTION order_cartons
(
    in_orderid      number,
    in_shipid       number
)
RETURN number;

----------------------------------------------------------------------
--
-- order_weight
--
----------------------------------------------------------------------
FUNCTION order_weight
(
    in_orderid      number,
    in_shipid       number
)
RETURN number;

----------------------------------------------------------------------
--
-- lss_skids
--
----------------------------------------------------------------------
FUNCTION lss_skids
(
    in_loadno       number,
    in_stopno       number,
    in_shipno       number
)
RETURN number;

----------------------------------------------------------------------
--
-- lss_cartons
--
----------------------------------------------------------------------
FUNCTION lss_cartons
(
    in_loadno       number,
    in_stopno       number,
    in_shipno       number
)
RETURN number;

----------------------------------------------------------------------
--
-- lss_weight
--
----------------------------------------------------------------------
FUNCTION lss_weight
(
    in_loadno       number,
    in_stopno       number,
    in_shipno       number
)
RETURN number;

----------------------------------------------------------------------
--
-- lss_quantity
--
----------------------------------------------------------------------
FUNCTION lss_quantity
(
    in_loadno       number,
    in_stopno       number,
    in_shipno       number
)
RETURN number;

----------------------------------------------------------------------
--
-- order_trackingnos
--
----------------------------------------------------------------------
FUNCTION order_trackingnos
(
    in_orderid      number,
    in_shipid       number
)
RETURN varchar2;

FUNCTION lfd_rownum
(
    in_lpid         varchar2,
    in_pieces       number
)
RETURN number;


PRAGMA RESTRICT_REFERENCES (order_skids, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (order_cartons, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (order_weight, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (lss_skids, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (lss_cartons, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (lss_weight, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (lss_quantity, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (order_trackingnos, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (lfd_rownum, WNDS, WNPS, RNPS);

end zexportprocpecas;
/
exit;
