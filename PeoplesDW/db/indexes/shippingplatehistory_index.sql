--
-- $Id$
--
drop index shippingplatehistory_idx;

create index shippingplatehistory_idx on shippingplatehistory(lpid, whenoccurred);

exit;
