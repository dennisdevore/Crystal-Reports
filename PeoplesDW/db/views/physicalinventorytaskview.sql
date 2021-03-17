create or replace view physicalinventorytaskview (
   id,
   taskid,
   custid,
   custname,
   location,
   lpid,
   item,
   itemdesc,
   lotnumber,
   uom,
   systemcount
)
as
select
   P.id,
   T.taskid,
   P.custid,
   C.name,
   T.fromloc,
   P.lpid,
   P.item,
   I.descr,
   P.lotnumber,
   P.uom,
   P.systemcount
from custitem I, customer C, physicalinventorydtl P, tasks T
where T.tasktype = 'PI'
  and T.taskid = P.taskid
  and T.fromloc = P.location
  and C.custid = P.custid
  and P.custid = I.custid(+)
  and P.item = I.item(+);

comment on table physicalinventorytaskview is '$Id$';

exit;
