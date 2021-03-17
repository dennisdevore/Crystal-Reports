--
-- $Id$
--
drop index orderdtlbolcomments_unique;
drop index orderdtlbolcommmnents_unique;

create unique index orderdtlbolcomments_unique
   on orderdtlbolcomments(orderid,shipid,item,lotnumber);

exit;
