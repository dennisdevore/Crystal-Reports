create or replace view cartongroupsview
(
cartongroup,
code,
abbrev,
descr,
length,
width,
height,
maxweight,
maxcube,
LASTUSER,
LASTUPDATE,
container_weight
)
as
select
cartongroups.cartongroup,
cartongroups.code,
cartontypes.abbrev,
cartontypes.descr,
cartontypes.length,
cartontypes.width,
cartontypes.height,
cartontypes.maxweight,
cartontypes.maxcube,
cartongroups.lastuser,
cartongroups.lastupdate,
cartontypes.container_weight
from cartongroups, cartontypes
where cartongroups.code = cartontypes.code (+);

comment on table cartongroupsview is '$Id$';

exit;
