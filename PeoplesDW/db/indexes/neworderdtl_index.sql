--
-- $Id$
--
drop index neworderdtl_idx;
drop index neworderdtl_date_idx;

create index neworderdtl_idx
on neworderdtl(orderid, shipid);

create index neworderdtl_date_idx
on neworderdtl(chgdate,chguser);
exit;
