create or replace package body alps.zbol as
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

----------------------------------------------------------------------
CURSOR C_ORDHDR(in_orderid number, in_shipid number)
RETURN orderhdr%rowtype
IS
    SELECT *
      FROM orderhdr
     WHERE orderid = in_orderid
       AND shipid = in_shipid;

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
RETURN
    varchar2
IS

ORD orderhdr%rowtype;
BEGIN

  ORD := null;
  OPEN C_ORDHDR(in_orderid, in_shipid);
  FETCH C_ORDHDR into ORD;
  CLOSE C_ORDHDR;

  return ORD.consignee;
    
END order_consignee;


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
RETURN varchar2
IS
CURSOR C_BOL IS
SELECT *
  FROM bolcustcmtview
 WHERE orderid = in_orderid
   AND shipid = in_shipid;

BOL C_BOL%rowtype;

cmt varchar2(4000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(4000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,4000);
    else
        cmt := substr(cmt || crlf || in_add,1,4000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

if BOL.OHC_custid is not null then
    add_cmt(BOL.ohc_comment);
elsif BOL.CI_custid is not null then
    add_cmt(BOL.ci_comment);
elsif BOL.CID_custid is not null then
    add_cmt(BOL.cid_comment);
end if;

add_cmt(BOL.lbc_bolcomment);
add_cmt(BOL.lsbc_bolcomment);
add_cmt(BOL.lssbc_bolcomment);

return cmt;

END bolcustcomments;

----------------------------------------------------------------------
--
-- bolcustcomments
--
----------------------------------------------------------------------
FUNCTION allbolcustcomments
(
    in_orderid   IN      number,
    in_shipid    IN      number
)
RETURN varchar2
IS
CURSOR C_BOL IS
SELECT *
  FROM bolcustcmtview
 WHERE orderid = in_orderid
   AND shipid = in_shipid;

BOL C_BOL%rowtype;

cmt varchar2(4000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(4000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,4000);
    else
        cmt := substr(cmt || crlf || in_add,1,4000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

add_cmt(BOL.ohc_comment);
add_cmt(BOL.ci_comment);
add_cmt(BOL.cid_comment);

add_cmt(BOL.lbc_bolcomment);
add_cmt(BOL.lsbc_bolcomment);
add_cmt(BOL.lssbc_bolcomment);

return cmt;

END allbolcustcomments;


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
RETURN varchar2
IS
CURSOR C_BOL IS
SELECT *
  FROM bolitmcmtview 
 WHERE orderid = in_orderid
   AND shipid  = in_shipid
   AND item    = in_item
   AND lotnumber = nvl(in_lotnumber,'**NULL**');

BOL C_BOL%rowtype;

cmt varchar2(4000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(4000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,4000);
    else
        cmt := substr(cmt || crlf || in_add,1,4000);
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

END bolcustitmcomments;

----------------------------------------------------------------------
--
-- orderhdrcomments
--
----------------------------------------------------------------------
FUNCTION orderhdrcomments
(
    in_rowid   IN      rowid
)
RETURN varchar2
IS
CURSOR C_BOL IS
SELECT orderhdrrowid
,comment1
  FROM orderhdrcmtview 
 WHERE orderhdrcmtview.orderhdrrowid = in_rowid;
  
BOL C_BOL%rowtype;

cmt varchar2(4000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(4000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,4000);
    else
        cmt := substr(cmt || crlf || in_add,1,4000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

add_cmt(BOL.comment1);

   
return cmt;

END orderhdrcomments;

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
RETURN varchar2
IS
CURSOR C_BOL IS
SELECT orderid,shipid
,comment1
  FROM orderidhdrcmtview 
 WHERE orderid = in_orderid and
	 shipid = in_shipid;
  
BOL C_BOL%rowtype;

cmt varchar2(4000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(4000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,4000);
    else
        cmt := substr(cmt || crlf || in_add,1,4000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

add_cmt(BOL.comment1);

   
return cmt;

END orderidhdrcomments;


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
RETURN varchar2
IS
CURSOR C_BOL IS
SELECT orderid,shipid
,comment1
  FROM orderiddtlcmtview 
 WHERE orderid = in_orderid and
	 shipid = in_shipid;
  
BOL C_BOL%rowtype;

cmt varchar2(4000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(4000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,4000);
    else
        cmt := substr(cmt || crlf || in_add,1,4000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

add_cmt(BOL.comment1);

   
return cmt;

END orderiddtlcomments;


----------------------------------------------------------------------
--
-- orderdtlcomments
--
----------------------------------------------------------------------
FUNCTION orderdtlcomments
(
    in_rowid   IN      rowid
)
RETURN varchar2
IS
CURSOR C_BOL IS
SELECT orderdtlrowid
,comment1
  FROM orderdtlcmtview 
 WHERE orderdtlcmtview.orderdtlrowid = in_rowid;
  
BOL C_BOL%rowtype;

cmt varchar2(4000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(4000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,4000);
    else
        cmt := substr(cmt || crlf || in_add,1,4000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

add_cmt(BOL.comment1);

   
return cmt;

END orderdtlcomments;

----------------------------------------------------------------------
--
-- loadscmt
--
----------------------------------------------------------------------
FUNCTION loadscmt
(
    in_rowid   IN      rowid
)
RETURN varchar2
IS
CURSOR C_BOL IS
SELECT loadsrowid
,comment1
  FROM loadscmtview 
 WHERE loadscmtview.loadsrowid = in_rowid;
  
BOL C_BOL%rowtype;

cmt varchar2(4000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(4000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,4000);
    else
        cmt := substr(cmt || crlf || in_add,1,4000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

add_cmt(BOL.comment1);

   
return cmt;

END loadscmt;

----------------------------------------------------------------------
--
-- loadstopcmt
--
----------------------------------------------------------------------
FUNCTION loadstopcmt
(
    in_rowid   IN      rowid
)
RETURN varchar2
IS
CURSOR C_BOL IS
SELECT loadstoprowid
,comment1
  FROM loadstopcmtview 
 WHERE loadstopcmtview.loadstoprowid = in_rowid;
  
BOL C_BOL%rowtype;

cmt varchar2(4000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(4000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,4000);
    else
        cmt := substr(cmt || crlf || in_add,1,4000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

add_cmt(BOL.comment1);

   
return cmt;

END loadstopcmt;

----------------------------------------------------------------------
--
-- loadstopshipcmt
--
----------------------------------------------------------------------
FUNCTION loadstopshipcmt
(
    in_rowid   IN      rowid
)
RETURN varchar2
IS
CURSOR C_BOL IS
SELECT loadstopshiprowid
,comment1
  FROM loadstopshipcmtview 
 WHERE loadstopshipcmtview.loadstopshiprowid = in_rowid;
  
BOL C_BOL%rowtype;

cmt varchar2(4000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(4000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,4000);
    else
        cmt := substr(cmt || crlf || in_add,1,4000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

add_cmt(BOL.comment1);

   
return cmt;

END loadstopshipcmt;

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
RETURN varchar2
IS
CURSOR C_BOL IS
SELECT orderid,shipid
,bolcomment
  FROM orderhdrbolcomments
 WHERE orderid = in_orderid and
	 shipid = in_shipid;

BOL C_BOL%rowtype;

cmt varchar2(4000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(4000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,4000);
    else
        cmt := substr(cmt || crlf || in_add,1,4000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

add_cmt(BOL.bolcomment);

   
return cmt;

END orderhdrbolcomments;


----------------------------------------------------------------------
--
-- loadsbolcomments
--
----------------------------------------------------------------------
FUNCTION loadsbolcomments
(
    in_loadno  IN  number
)
RETURN varchar2
IS
CURSOR C_BOL IS
SELECT loadno 
,bolcomment 
  FROM loadsbolcomments
 WHERE loadsbolcomments.loadno = in_loadno  ;
  
BOL C_BOL%rowtype;

cmt varchar2(4000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(4000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,4000);
    else
        cmt := substr(cmt || crlf || in_add,1,4000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

add_cmt(BOL.bolcomment);

   
return cmt;

END loadsbolcomments;

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
RETURN varchar2
IS
CURSOR C_BOL IS
	SELECT custid,
		item,
		comment1
		from custitembolcomments
	where custid = in_custid and
  	      item   = in_item and
              consignee = in_consignee;
  
BOL C_BOL%rowtype;

cmt varchar2(4000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(4000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,4000);
    else
        cmt := substr(cmt || crlf || in_add,1,4000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

add_cmt(BOL.comment1);

   
return cmt;

END custitembolcomments;

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
RETURN varchar2
IS
CURSOR C_BOL IS
	SELECT custid,
		item,
		comment1
		from custitemincomments
	where custid = in_custid and
  	      item   = in_item;
  
BOL C_BOL%rowtype;

cmt varchar2(4000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(4000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,4000);
    else
        cmt := substr(cmt || crlf || in_add,1,4000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

add_cmt(BOL.comment1);

   
return cmt;

END custitemincomments;

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
RETURN varchar2
IS
CURSOR C_BOL IS
	SELECT custid,
		item,
		comment1
		from custitemoutcomments
	where custid = in_custid and
  	      item   = in_item and
              consignee = in_consignee;
  
BOL C_BOL%rowtype;

cmt varchar2(4000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(4000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,4000);
    else
        cmt := substr(cmt || crlf || in_add,1,4000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

add_cmt(BOL.comment1);

   
return cmt;

END custitemoutcomments;

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
RETURN varchar2
IS
CURSOR C_BOL IS
SELECT *
  FROM bolcustcmtview
 WHERE orderid = in_orderid
   AND shipid = in_shipid;

BOL C_BOL%rowtype;

cmt varchar2(4000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(4000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,4000);
    else
        cmt := substr(cmt || crlf || in_add,1,4000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

add_cmt(BOL.ohc_comment);

return cmt;

END bolohccomment;

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
RETURN varchar2
IS
CURSOR C_BOL IS
SELECT *
  FROM bolcustcmtview
 WHERE orderid = in_orderid
   AND shipid = in_shipid;

BOL C_BOL%rowtype;

cmt varchar2(4000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(4000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,4000);
    else
        cmt := substr(cmt || crlf || in_add,1,4000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

add_cmt(BOL.ci_comment);

return cmt;

END bolcicomment;

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
RETURN varchar2
IS
CURSOR C_BOL IS
SELECT *
  FROM bolcustcmtview
 WHERE orderid = in_orderid
   AND shipid = in_shipid;

BOL C_BOL%rowtype;

cmt varchar2(4000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(4000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,4000);
    else
        cmt := substr(cmt || crlf || in_add,1,4000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

add_cmt(BOL.cid_comment);

return cmt;

END bolcidcomment;

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
RETURN varchar2
IS
CURSOR C_BOL IS
SELECT *
  FROM bolcustcmtview
 WHERE orderid = in_orderid
   AND shipid = in_shipid;

BOL C_BOL%rowtype;

cmt varchar2(4000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(4000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,4000);
    else
        cmt := substr(cmt || crlf || in_add,1,4000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

add_cmt(BOL.lbc_bolcomment);

return cmt;

END bollbccomment;

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
RETURN varchar2
IS
CURSOR C_BOL IS
SELECT *
  FROM bolcustcmtview
 WHERE orderid = in_orderid
   AND shipid = in_shipid;

BOL C_BOL%rowtype;

cmt varchar2(4000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(4000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,4000);
    else
        cmt := substr(cmt || crlf || in_add,1,4000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

add_cmt(BOL.lsbc_bolcomment);

return cmt;

END bollsbccomment;

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
RETURN varchar2
IS
CURSOR C_BOL IS
SELECT *
  FROM bolcustcmtview
 WHERE orderid = in_orderid
   AND shipid = in_shipid;

BOL C_BOL%rowtype;

cmt varchar2(4000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(4000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,4000);
    else
        cmt := substr(cmt || crlf || in_add,1,4000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

add_cmt(BOL.lssbc_bolcomment);

return cmt;

END bollssbccomment;

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
RETURN varchar2
IS
CURSOR C_BOL IS
SELECT *
  FROM bolcustcmtview
 WHERE orderid = in_orderid
   AND shipid = in_shipid;

BOL C_BOL%rowtype;

cmt varchar2(4000);

crlf char(2) := chr(13)||chr(10);

PROCEDURE add_cmt(in_add varchar2)
IS
tcmt varchar2(4000);
BEGIN
    if cmt is null then
        cmt := substr(in_add,1,4000);
    else
        cmt := substr(cmt || crlf || in_add,1,4000);
    end if;
END;

BEGIN

BOL := null;
OPEN C_BOL;
FETCH C_BOL into BOL;
CLOSE C_BOL;

cmt := '';

add_cmt(BOL.cdf_comment);

return cmt;

END bolcdfcomment;


end zbol;
/

exit;

