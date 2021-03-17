--
-- $Id$
--
drop index ordercheck_order;

create index ordercheck_order on ordercheck
   (orderid, shipid);

exit;
