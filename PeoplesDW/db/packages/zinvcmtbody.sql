create or replace package body alps.zinvcmt as
--
-- $Id$
--
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************
--
--


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


call_cnt integer := 0;



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
RETURN varchar2
IS
CURSOR C_INV IS
SELECT *
  FROM invitemcmt
 WHERE rowid = in_rowid
   AND invoice  = in_invoice; 

INV C_INV%rowtype;

cmt varchar2(10000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(10000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,10000);
    else
        cmt := substr(cmt || crlf || in_add,1,10000);
    end if;
END;

BEGIN

INV := null;
OPEN C_INV;
FETCH C_INV into INV;
CLOSE C_INV;

cmt := '';


add_cmt(INV.comment1);
   
return cmt;

END invoiceitmcomments;

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
RETURN date
IS

CURSOR C_PL(in_orderid number, in_shipid number, in_item varchar2, 
    in_lotnumber varchar2)
IS
SELECT min(expirationdate) expirationdate
  FROM dre_allplateview P
 WHERE P.orderid = in_orderid
   AND P.shipid = in_shipid
   AND P.item = in_item
   AND nvl(P.lotnumber,'(none)') = nvl(in_lotnumber, '(none)')
   AND P.expirationdate is not null;

PL C_PL%rowtype;
dt date;
BEGIN
    dt := null;

    PL := null;
    OPEN C_PL(in_orderid, in_shipid, in_item, in_lot);
    FETCH C_PL into PL;
    CLOSE C_PL;

    dt := PL.expirationdate;

    return dt;
EXCEPTION WHEN OTHERS THEN
    return dt;
END invitemexpdate;

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
RETURN date
IS

CURSOR C_PL(in_orderid number, in_shipid number, in_item varchar2, 
    in_lotnumber varchar2)
IS
SELECT min(manufacturedate) manufacturedate
  FROM dre_allplateview P
 WHERE P.orderid = in_orderid
   AND P.shipid = in_shipid
   AND P.item = in_item
   AND nvl(P.lotnumber,'(none)') = nvl(in_lotnumber, '(none)')
   AND P.manufacturedate is not null;

PL C_PL%rowtype;
dt date;

BEGIN
    dt := null;

    PL := null;
    OPEN C_PL(in_orderid, in_shipid, in_item, in_lot);
    FETCH C_PL into PL;
    CLOSE C_PL;

    dt := PL.manufacturedate;

    return dt;
EXCEPTION WHEN OTHERS THEN
    return dt;
END invitemmandate;

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
RETURN number
IS
CURSOR C_ODR(in_orderid number, in_shipid number, in_item varchar2, 
    in_lotnumber varchar2)
IS
SELECT sum(nvl(R.qtyrcvd,0)) qty
  FROM orderdtlrcpt R
 WHERE R.orderid = in_orderid
   AND R.shipid = in_shipid
   AND R.item = in_item
   AND nvl(R.lotnumber,'(none)') = nvl(in_lotnumber, '(none)');

ODR C_ODR%rowtype;

tot number;
BEGIN

    tot := 0;
    ODR := null;
    OPEN C_ODR(in_orderid, in_shipid, in_item, in_lot);
    FETCH C_ODR into ODR;
    CLOSE C_ODR;

    tot := nvl(ODR.qty,0);

    return tot;
EXCEPTION WHEN OTHERS THEN
    return tot;
END invitemqtyrcvd;


end zinvcmt;
/

exit;

