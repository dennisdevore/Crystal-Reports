--
-- $Id$
--
drop index orderhdrbolcomments_unique;

create unique index orderhdrbolcommmnents_unique
   on orderhdrbolcomments(orderid,shipid);

exit;