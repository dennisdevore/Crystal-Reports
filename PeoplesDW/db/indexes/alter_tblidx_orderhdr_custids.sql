--
-- $Id$
--
create index orderhdr_custid_recent_idx on
   orderhdr(custid, recent_order_id);
create index orderhdr_custid_lastupdate_idx on
   orderhdr(custid, lastupdate);
exit;

