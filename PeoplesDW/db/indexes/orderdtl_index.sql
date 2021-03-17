--
-- $Id$
--
drop index orderdtl_unique;

create unique index orderdtl_unique
on orderdtl(orderid,shipid,item,lotnumber);

exit;
