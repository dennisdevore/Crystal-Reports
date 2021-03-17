--
-- $Id$
--
drop index custitemoutcomments_unique;
create unique index custitemoutcomments_unique on
  custitemoutcomments(custid,item,consignee);

drop index custitemoutcomments_con;
create unique index custitemoutcomments_con on
  custitemoutcomments(consignee,custid,item);

exit;