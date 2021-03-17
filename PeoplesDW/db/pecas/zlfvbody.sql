create or replace package body zlfv as
--
-- $Id$
--

FUNCTION itemcnt(in_lpid varchar2)
return number
IS
tcnt integer;

BEGIN

    tcnt := 0;
    select count(distinct item)
      into tcnt
      from load_flag_dtl
     where lpid = in_lpid;

    return nvl(tcnt,0);
END itemcnt;

FUNCTION ordercnt(in_lpid varchar2)
return number
IS
tcnt integer;

BEGIN

    tcnt := 0;
    select count(distinct orderid*100 + shipid)
      into tcnt
      from load_flag_dtl
     where lpid = in_lpid;

    return nvl(tcnt,0);
END ordercnt;

FUNCTION carriercnt(in_lpid varchar2)
return number
IS
tcnt integer;

BEGIN

    tcnt := 0;
    select count(distinct carrier)
      into tcnt
      from alps.orderhdr O, load_flag_dtl D
     where lpid = in_lpid
       and O.orderid = D.orderid
       and O.shipid = D.shipid;

    return nvl(tcnt,0);
END carriercnt;

END zlfv;
/
exit;

