--
-- $Id$
--
drop index neworderhdr_idx;
drop index neworderhdr_date_idx;

create index neworderhdr_idx
on neworderhdr(orderid, shipid);

create index neworderhdr_date_idx
on neworderhdr(chgdate,chguser);
exit;
