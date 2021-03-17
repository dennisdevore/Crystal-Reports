create or replace package body alps.zorderhistory as
--
-- $Id$
--
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************
--


-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************
--

--
-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************



----------------------------------------------------------------------
--
-- add_orderhistory_item
--
----------------------------------------------------------------------
PROCEDURE add_orderhistory_item
(
    in_orderid      IN      number,
    in_shipid       IN      number,
    in_lpid         IN      varchar2,
    in_item         IN      varchar2,
    in_lotnumber    IN      varchar2,
    in_action       IN      varchar2,
    in_msg          IN      varchar2,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
)
IS

   CURSOR C_ORD(in_orderid number, in_shipid number)
     RETURN orderhdr%rowtype
   IS
      SELECT *
        FROM orderhdr
       WHERE orderid = in_orderid
         AND shipid = in_shipid;

ORD orderhdr%rowtype;

chgdate date;


BEGIN
    out_errmsg := 'OKAY';

    chgdate := sysdate;

    ORD := null;
    OPEN C_ORD(in_orderid, in_shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if ORD.orderid is null then
       out_errmsg := 'Invalid orderid/shipid';
       return;
    end if;

    insert into orderhistory 
      (chgdate, orderid, shipid, 
           lpid, item, lot,
                userid, action, msg)
    values
      (chgdate, in_orderid, in_shipid, 
           in_lpid, in_item, in_lotnumber,
           in_user, in_action, in_msg);


EXCEPTION when others then
    out_errmsg := sqlerrm;
END add_orderhistory_item;

----------------------------------------------------------------------
--
-- add_orderhistory
--
----------------------------------------------------------------------
PROCEDURE add_orderhistory
(
    in_orderid      IN      number,
    in_shipid       IN      number,
    in_action       IN      varchar2,
    in_msg          IN      varchar2,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
)
IS
BEGIN

    add_orderhistory_item(
        in_orderid, in_shipid, null, null, null,
        in_action, in_msg, in_user, out_errmsg    );
END add_orderhistory;




end zorderhistory;
/

exit;
