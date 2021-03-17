--
-- $Id$
--
drop index custitembolcomments_unique;
create unique index custitembolcomments_unique on
  custitembolcomments(custid,item,consignee);

drop index custitembolcomments_con;
create unique index custitembolcomments_con on
  custitembolcomments(consignee,custid,item);
exit;