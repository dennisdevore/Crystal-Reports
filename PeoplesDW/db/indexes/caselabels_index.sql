--
-- $Id$
--
drop index caselabels_uniq;
create unique index caselabels_uniq on caselabels
   (barcode);

drop index caselabels_idx1;
create index caselabels_idx1 on caselabels
   (orderid, shipid, custid, item, lotnumber);

exit;
