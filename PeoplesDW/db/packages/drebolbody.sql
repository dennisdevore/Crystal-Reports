CREATE OR REPLACE package body drebol as

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
RETURN varchar2
IS
CURSOR C_BOL IS
SELECT *
  FROM dre_bolitmcmtv3
 WHERE orderid = in_orderid
   AND shipid  = in_shipid
   and item    = in_item;

BOL C_BOL%rowtype;

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

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

if BOL.ODC_item is not null then
	add_cmt(BOL.ODC_comment);
elsif BOL.CI_item is not null then
	add_cmt(BOL.CI_comment);
elsif BOL.CID_item is not null then
	add_cmt(BOL.CID_comment);
end if;

return cmt;

END dre_bolitmcmtv3comments;

----------------------------------------------------------------------
--
-- dre_ohbolcomments
--
----------------------------------------------------------------------
FUNCTION dre_ohbolcomments
(
    in_orderid   IN      number,
    in_shipid    IN      number
)
RETURN varchar2
IS
CURSOR C_OH IS
SELECT *
  FROM orderhdrbolcomments
 WHERE orderid = in_orderid
   AND shipid  = in_shipid;

OH C_OH%rowtype;

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

OH := null;
OPEN C_OH;
FETCH C_OH into OH;
CLOSE C_OH;

cmt := '';

add_cmt(OH.bolcomment);

return cmt;

END dre_ohbolcomments;


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
RETURN varchar2
IS
CURSOR C_OD IS
SELECT *
  FROM dre_rpt_orderdtlcmtview
 WHERE orderid = in_orderid
   AND shipid  = in_shipid
   AND item = in_item
   AND lotnumber_null = in_lotnumber_null;

OD C_OD%rowtype;

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

OD := null;
OPEN C_OD;
FETCH C_OD into OD;
CLOSE C_OD;

cmt := '';

add_cmt(OD.od_comment);

return cmt;

END dre_odcomments;


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
	 in_lotnumber IN      varchar2
)
RETURN varchar2
IS
CURSOR C_BOL IS
SELECT bi.*, od.comment1 as OD_COMMENT
  FROM bolitmcmtview bi, orderdtl od
 WHERE bi.orderid = in_orderid
   AND bi.shipid  = in_shipid
   AND bi.item    = in_item
   AND nvl(bi.lotnumber,'**NULL**') = nvl(in_lotnumber,'**NULL**')
   AND bi.orderid = od.orderid
   AND bi.shipid  = od.shipid
   AND bi.item    = od.item
	AND nvl(bi.lotnumber,'**NULL**') = nvl(od.lotnumber,'**NULL**');

CURSOR C_BOL2 IS
SELECT bi.orderid,bi.shipid,bi.item,od.lotnumber,bi.odc_item,
	bi.odc_comment,bi.ci_item,bi.ci_comment,bi.cid_item,bi.cid_comment, od.comment1 as OD_COMMENT
  FROM bolitmcmtview bi, orderdtlorderlotcmtview od
 WHERE bi.orderid = in_orderid
   AND bi.shipid  = in_shipid
   AND bi.item    = in_item
   AND od.lotnumber = in_lotnumber
   AND bi.orderid = od.orderid
   AND bi.shipid  = od.shipid
   AND bi.item    = od.item
   AND bi.lotnumber = od.orderlot;


BOL C_BOL%rowtype;
BOL2 C_BOL2%rowtype;

cmt varchar2(10000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(10000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,10000);
    else
        cmt := substr(cmt || ' ' || in_add,1,10000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

if BOL.OD_comment is not null then
	add_cmt(BOL.OD_comment);
end if;
if BOL.ODC_item is not null then
	add_cmt(BOL.ODC_comment);
end if;
if BOL.CI_item is not null then
	add_cmt(BOL.CI_comment);
end if;
if BOL.CID_item is not null then
	add_cmt(BOL.CID_comment);
end if;

BOL2 := null;
OPEN C_BOL2;
FETCH C_BOL2 into BOL2;
CLOSE C_BOL2;


if BOL2.OD_comment is not null then
	add_cmt(BOL2.OD_comment);
end if;
if BOL2.ODC_item is not null then
	add_cmt(BOL2.ODC_comment);
end if;
if BOL2.CI_item is not null then
	add_cmt(BOL2.CI_comment);
end if;
if BOL2.CID_item is not null then
	add_cmt(BOL2.CID_comment);
end if;

return cmt;

END dre_bolitmcmtv4comments;

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
RETURN varchar2
IS
CURSOR C_BOL IS
SELECT bi.*, od.comment1 as OD_COMMENT
  FROM bolitmcmtview bi, orderdtl od
 WHERE bi.orderid = in_orderid
   AND bi.shipid  = in_shipid
   AND bi.item    = in_item
   AND bi.orderid = od.orderid
   AND bi.shipid  = od.shipid
   AND bi.item    = od.item
   AND od.lotnumber is null;
	
BOL C_BOL%rowtype;

cmt varchar2(10000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(10000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,10000);
    else
        cmt := substr(cmt || ' ' || in_add,1,10000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

if BOL.OD_comment is not null then
	add_cmt(BOL.OD_comment);
end if;
if BOL.ODC_item is not null then
	add_cmt(BOL.ODC_comment);
end if;
if BOL.CI_item is not null then
	add_cmt(BOL.CI_comment);
end if;
if BOL.CID_item is not null then
	add_cmt(BOL.CID_comment);
end if;

return cmt;

END dre_bolitmcmtv5comments;

end drebol;
/
exit;
