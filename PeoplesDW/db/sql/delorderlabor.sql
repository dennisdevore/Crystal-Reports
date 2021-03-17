--
-- $Id$
--
select distinct orderid, shipid from orderlabor
where not exists (select * from orderhdr
where orderlabor.orderid = orderhdr.orderid
and orderlabor.shipid = orderhdr.shipid)
/
--exit;