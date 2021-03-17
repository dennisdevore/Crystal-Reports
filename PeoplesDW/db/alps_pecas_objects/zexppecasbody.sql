create or replace package body alps.zexportprocpecas as
--
-- $Id: zexppecasbody.sql 1 2005-05-26 12:20:03Z ed $
--



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
RETURN number
IS
cnt integer;

BEGIN

    cnt := 0;
    select count(1)
      into cnt
     from alps.shippingplate S, alps.orderhdr O
    where S.orderid = in_orderid
      and S.shipid = in_shipid
      and O.orderid = S.orderid
      and O.shipid = S.shipid
      and shiptype != 'S';



    return cnt;
EXCEPTION WHEN OTHERS THEN
    return 0;
END order_skids;

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
RETURN number
IS
cnt integer;

BEGIN

    cnt := 0;
    select count(1)
      into cnt
     from alps.shippingplate S, alps.orderhdr O
    where S.orderid = in_orderid
      and S.shipid = in_shipid
      and O.orderid = S.orderid
      and O.shipid = S.shipid
      and shiptype = 'S';



    return cnt;
EXCEPTION WHEN OTHERS THEN
    return 0;
END order_cartons;


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
RETURN number
IS
wt number;

BEGIN

    select sum(nvl(S.weight,0))
      into wt
     from alps.shippingplate S
    where S.orderid = in_orderid
      and S.shipid = in_shipid
      and type in ('F','P');


    return nvl(wt,0);
EXCEPTION WHEN OTHERS THEN
    return 0;
END order_weight;

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
RETURN number
IS
cnt integer;

BEGIN

    cnt := 0;
    select count(1)
      into cnt
     from alps.shippingplate S, alps.orderhdr O
    where S.loadno = in_loadno 
      and S.stopno = in_stopno
      and S.shipno = in_shipno
      and O.orderid = S.orderid
      and O.shipid = S.shipid
      and O.orderstatus = '9'
      and O.shipterms = 'PPD'
      and O.shiptype != 'M'
      and shiptype != 'S';



    return cnt;
EXCEPTION WHEN OTHERS THEN
    return 0;
END lss_skids;

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
RETURN number
IS
cnt integer;

BEGIN

    cnt := 0;
    select count(1)
      into cnt
     from alps.shippingplate S, alps.orderhdr O
    where S.loadno = in_loadno 
      and S.stopno = in_stopno
      and S.shipno = in_shipno
      and O.orderid = S.orderid
      and O.shipid = S.shipid
      and O.orderstatus = '9'
      and O.shipterms = 'PPD'
      and O.shiptype != 'M'
      and shiptype = 'S';



    return cnt;
EXCEPTION WHEN OTHERS THEN
    return 0;
END lss_cartons;


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
RETURN number
IS
wt number;

BEGIN

    select sum(nvl(S.weight,0))
      into wt
     from alps.shippingplate S
    where S.loadno = in_loadno 
      and S.stopno = in_stopno
      and S.shipno = in_shipno
      and S.status = 'SH'
      and type in ('F','P');

    return nvl(wt,0);
EXCEPTION WHEN OTHERS THEN
    return 0;
END lss_weight;

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
RETURN number
IS
wt number;

BEGIN

    select sum(nvl(S.quantity,0))
      into wt
     from alps.shippingplate S
    where S.loadno = in_loadno 
      and S.stopno = in_stopno
      and S.shipno = in_shipno
      and S.status = 'SH'
      and type in ('F','P');

    return nvl(wt,0);
EXCEPTION WHEN OTHERS THEN
    return 0;
END lss_quantity;



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
RETURN varchar2
IS
  lst varchar2(1000);
BEGIN

    lst := '';

    for crec in (select trackingno
                   from shippingplate
                  where orderid = in_orderid
                    and shipid = in_shipid
                    and trackingno is not null)
    loop
        lst := lst || ',' || crec.trackingno;
    end loop;

    return substr(lst,2);

END order_trackingnos;


FUNCTION lfd_rownum
(
    in_lpid         varchar2,
    in_pieces       number
)
RETURN number
IS
cnt number;
BEGIN
    cnt := 0;

    for crec in (select pieces
                   from load_flag_dtl
                  where lpid = in_lpid
                  order by pieces desc)
    loop
        cnt := cnt + 1;
        exit when crec.pieces <= in_pieces;

    end loop;

    return cnt;

END lfd_rownum;




end zexportprocpecas;
/
exit;

