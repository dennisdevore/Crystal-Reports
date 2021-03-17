--
-- $Id$
--
create or replace package alps.zbol as
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
-- order_consignee
--
----------------------------------------------------------------------
FUNCTION order_consignee
(
    in_orderid   IN      number,
    in_shipid    IN      number
)
RETURN varchar2;

----------------------------------------------------------------------
--
-- bolcustcomments
--
----------------------------------------------------------------------
FUNCTION bolcustcomments
(
    in_orderid   IN      number,
    in_shipid    IN      number
)
RETURN varchar2;

----------------------------------------------------------------------
--
-- allbolcustcomments
--
----------------------------------------------------------------------
FUNCTION allbolcustcomments
(
    in_orderid   IN      number,
    in_shipid    IN      number
)
RETURN varchar2;

----------------------------------------------------------------------
--
-- bolcustitmcomments
--
----------------------------------------------------------------------
FUNCTION bolcustitmcomments
(
    in_orderid   IN      number,
    in_shipid    IN      number,
    in_item      IN      varchar2,
    in_lotnumber IN      varchar2
)
RETURN varchar2;

----------------------------------------------------------------------
--
-- orderhdrcomments
--
----------------------------------------------------------------------
FUNCTION orderhdrcomments
(
    in_rowid   IN      rowid
)
RETURN varchar2;

----------------------------------------------------------------------
--
-- orderidhdrcomments
--
----------------------------------------------------------------------
FUNCTION orderidhdrcomments
(
   in_orderid   IN      number,
   in_shipid    IN      number
)
RETURN varchar2;


----------------------------------------------------------------------
--
-- orderdtlcomments
--
----------------------------------------------------------------------
FUNCTION orderdtlcomments
(
    in_rowid   IN      rowid
)
RETURN varchar2;

----------------------------------------------------------------------
--
-- orderiddtlcomments
--
----------------------------------------------------------------------
FUNCTION orderiddtlcomments
(
   in_orderid   IN      number,
   in_shipid    IN      number
)
RETURN varchar2;


----------------------------------------------------------------------
--
-- loadscmt
--
----------------------------------------------------------------------
FUNCTION loadscmt
(
    in_rowid   IN      rowid
)
RETURN varchar2;

----------------------------------------------------------------------
--
-- loadstopcmt
--
----------------------------------------------------------------------
FUNCTION loadstopcmt
(
    in_rowid   IN      rowid
)
RETURN varchar2;

----------------------------------------------------------------------
--
-- loadstopshipcmt
--
----------------------------------------------------------------------
FUNCTION loadstopshipcmt
(
    in_rowid   IN      rowid
)
RETURN varchar2;

----------------------------------------------------------------------
--
-- orderhdrbolcomments
--
----------------------------------------------------------------------
FUNCTION orderhdrbolcomments
(
   in_orderid   IN      number,
   in_shipid    IN      number
)
RETURN varchar2;

----------------------------------------------------------------------
--
-- loadsbolcomments
--
----------------------------------------------------------------------
FUNCTION loadsbolcomments
(
    in_loadno  IN  number
)
RETURN varchar2;

----------------------------------------------------------------------
--
-- custitembolcomments
--
----------------------------------------------------------------------
FUNCTION custitembolcomments
(
    in_custid  IN  varchar,
    in_item    IN  varchar,
    in_consignee IN varchar
)
RETURN varchar2;

----------------------------------------------------------------------
--
-- custitemincomments
--
----------------------------------------------------------------------
FUNCTION custitemincomments
(
    in_custid  IN  varchar,
    in_item    IN  varchar
)
RETURN varchar2;

----------------------------------------------------------------------
--
-- custitemoutcomments
--
----------------------------------------------------------------------
FUNCTION custitemoutcomments
(
    in_custid  IN  varchar,
    in_item    IN  varchar,
    in_consignee IN varchar
)
RETURN varchar2;

----------------------------------------------------------------------
--
-- bolohccomment
--
----------------------------------------------------------------------
FUNCTION bolohccomment
(
   in_orderid   IN      number,
   in_shipid    IN      number
)
RETURN varchar2;

----------------------------------------------------------------------
--
-- bolcicomment
--
----------------------------------------------------------------------
FUNCTION bolcicomment
(
   in_orderid   IN      number,
   in_shipid    IN      number
)
RETURN varchar2;

----------------------------------------------------------------------
--
-- bolcidcomment
--
----------------------------------------------------------------------
FUNCTION bolcidcomment
(
   in_orderid   IN      number,
   in_shipid    IN      number
)
RETURN varchar2;

----------------------------------------------------------------------
--
-- bollbccomment
--
----------------------------------------------------------------------
FUNCTION bollbccomment
(
   in_orderid   IN      number,
   in_shipid    IN      number
)
RETURN varchar2;

----------------------------------------------------------------------
--
-- bollsbccomment
--
----------------------------------------------------------------------
FUNCTION bollsbccomment
(
   in_orderid   IN      number,
   in_shipid    IN      number
)
RETURN varchar2;

----------------------------------------------------------------------
--
-- bollssbccomment
--
----------------------------------------------------------------------
FUNCTION bollssbccomment
(
   in_orderid   IN      number,
   in_shipid    IN      number
)
RETURN varchar2;

----------------------------------------------------------------------
--
-- bolcdfcomment
--
----------------------------------------------------------------------
FUNCTION bolcdfcomment
(
   in_orderid   IN      number,
   in_shipid    IN      number
)
RETURN varchar2;

PRAGMA RESTRICT_REFERENCES (order_consignee, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (bolcustcomments, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (allbolcustcomments, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (bolcustitmcomments, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (orderhdrcomments, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (loadscmt, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (loadstopcmt, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (loadstopshipcmt, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (loadsbolcomments, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (orderhdrbolcomments, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (custitembolcomments, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (bolohccomment, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (bolcicomment, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (bolcidcomment, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (bollbccomment, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (bollsbccomment, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (bollssbccomment, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (bolcdfcomment, WNDS, WNPS, RNPS);

end zbol;
/

exit;
