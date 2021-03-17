--
-- $Id$
--
drop index custitemsubs_seq;

create unique index custitemsubs_seq
  on custitemsubs(custid,item,seq);

drop index custitemsubs_unique;

create unique index custitemsubs_unique
   on custitemsubs(custid,item,itemsub);

exit;
