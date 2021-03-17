CREATE OR REPLACE package drebol as
--
-- $Id$
--

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
-- dre_bolitmcmtv3comments
--
----------------------------------------------------------------------
FUNCTION dre_bolitmcmtv3comments
(
    in_orderid   IN      number,
    in_shipid    IN      number,
    in_item      IN      varchar2
)
RETURN varchar2;



----------------------------------------------------------------------
--
-- dre_bolitmcmtv3comments
--
----------------------------------------------------------------------
FUNCTION dre_ohbolcomments
(
    in_orderid   IN      number,
    in_shipid    IN      number
)
RETURN varchar2;


----------------------------------------------------------------------
--
-- dre_odcomments
--
----------------------------------------------------------------------
FUNCTION dre_odcomments
(
    in_orderid   IN      number,
    in_shipid    IN      number,
	in_item      IN      varchar2,
	in_lotnumber_null IN varchar2
)
RETURN varchar2;


----------------------------------------------------------------------
--
-- dre_bolitmcmtv4comments
--
----------------------------------------------------------------------
FUNCTION dre_bolitmcmtv4comments
(
    in_orderid   IN      number,
    in_shipid    IN      number,
    in_item      IN      varchar2,
	 in_lotnumber  IN      varchar2
)
RETURN varchar2;


----------------------------------------------------------------------
--
-- dre_bolitmcmtv5comments
--
----------------------------------------------------------------------
FUNCTION dre_bolitmcmtv5comments
(
    in_orderid   IN      number,
    in_shipid    IN      number,
    in_item      IN      varchar2
)
RETURN varchar2;

PRAGMA RESTRICT_REFERENCES (dre_bolitmcmtv3comments, WNDS, WNPS, RNPS);

end drebol;
/
exit;
