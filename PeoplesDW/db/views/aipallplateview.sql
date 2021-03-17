create or replace view aip_allplateview
(
LPID,
loadno,
orderid,
shipid
)
as
select
plate.LPID,
plate.loadno,
plate.orderid,
plate.shipid
from plate
union all
select
deletedplate.LPID,
deletedplate.loadno,
deletedplate.orderid,
deletedplate.shipid
from deletedplate;

comment on table aip_allplateview is '$Id$';

exit;
