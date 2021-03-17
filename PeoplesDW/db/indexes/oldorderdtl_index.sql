--
-- $Id$
--
drop index oldorderdtl_idx;
drop index oldorderdtl_date_idx;

create index oldorderdtl_idx
on oldorderdtl(orderid, shipid);

create index oldorderdtl_date_idx
on oldorderdtl(chgdate,chguser);
exit;
