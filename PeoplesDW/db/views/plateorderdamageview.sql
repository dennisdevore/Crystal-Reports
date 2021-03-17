create or replace view plateorderdamageview
(
orderid,
shipid,
item,
lotnumber,
condition,
lastoperator
)
as
select
plate.orderid,
plate.shipid,
plate.item,
plate.lotnumber,
min(condition),
min(lastoperator)
from plate
group by orderid, shipid, item, lotnumber;

comment on table plateorderdamageview is '$Id$';

exit;
