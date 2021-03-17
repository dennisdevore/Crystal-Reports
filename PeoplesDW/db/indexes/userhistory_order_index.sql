--
-- $Id$
--
--drop index userhistory_order_idx;

create index userhistory_order_idx on
   userhistory(orderid, shipid) tablespace users16kb;

exit;
