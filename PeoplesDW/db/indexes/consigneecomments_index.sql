--
-- $Id$
--
create unique index consigneecomments_unique on
  consigneecomments(consignee,custid);

exit;