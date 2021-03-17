--
-- $Id: impexp_log_order.sql 1 2005-05-26 12:20:03Z ed $
--


create index impexp_log_order_idx on impexp_log(orderid, shipid);

exit;
