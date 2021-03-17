--
-- $Id$
--
drop index orderhdr_custid_ordertype_idx;

create index orderhdr_custid_ordertype_idx on
   orderhdr(custid, ordertype, orderstatus, source, statusupdate, orderid, shipid) tablespace users16kb;
exit;
