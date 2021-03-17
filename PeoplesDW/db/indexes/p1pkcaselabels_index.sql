--
-- $Id$
--
drop index p1pkcaselabels_unique;
create unique index p1pkcaselabels_unique on p1pkcaselabels
   (orderid, shipid, custid, item);

exit;
