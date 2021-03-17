--
-- $Id$
--
drop index orderhistory_order_idx;

create index orderhistory_order_idx
  on orderhistory(orderid, shipid, chgdate, userid);

exit;
