--
-- $Id$
--
drop index oldorderhdr_idx;
drop index oldorderhdr_date_idx;

create index oldorderhdr_idx
on oldorderhdr(orderid, shipid);

create index oldorderhdr_date_idx
on oldorderhdr(chgdate,chguser);
exit;
