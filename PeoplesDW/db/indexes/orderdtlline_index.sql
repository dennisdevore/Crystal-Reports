--
-- $Id$
--
drop index orderdtlline_item;

create unique index orderdtlline_item
on orderdtlline(orderid,shipid,item,lotnumber,linenumber);

drop index orderdtlline_linenumber;

create unique index orderdtlline_linenumber
on orderdtlline(orderid,shipid,linenumber);

exit;
