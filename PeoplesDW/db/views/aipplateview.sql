drop view aip_plateview;

create view aip_plateview as
select distinct b.orderid as receiptorderid, a.loadno as shiploadno
from shippingplate a, plate b
where a.fromlpid = b.lpid;

comment on table aip_plateview is '$Id$';
exit;
