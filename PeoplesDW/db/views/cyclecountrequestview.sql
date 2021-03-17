create or replace view cyclecountrequestview
(
FACILITY,
LOCATION,
STATUS,
STATUSABBREV,
ITEM,
LOTNUMBER,
CUSTID,
PRODUCTGROUP,
VELOCITY,
pickingzone,
loctype,
loctypeabbrev
)
as
select
l.FACILITY,
l.locid,
l.LOCATIONSTATUS,
l.LOCATIONSTATUSABBREV,
null,
null,
null,
null,
l.VELOCITY,
l.pickingzone,
l.loctype,
l.loctypeabbrev
from locationview l
where l.loctype in ('STO','PF')
and not exists
  (select * from tasks t
         where t.facility = l.facility
           and t.fromloc = l.locid
           and t.tasktype = 'CC')
union
select
distinct
p.FACILITY,
p.location,
l.LOCATIONSTATUS,
l.LOCATIONSTATUSABBREV,
p.ITEM,
p.LOTNUMBER,
p.CUSTID,
ci.PRODUCTGROUP,
l.VELOCITY,
l.pickingzone,
l.loctype,
l.loctypeabbrev
from locationview l, plate p, custitem ci
where p.FACILITY = l.FACILITY
and p.location = l.locid
and l.loctype in ('STO','PF')
and p.type = 'PA'
and p.item = ci.item
and ci.custid = p.custid
and not exists
  (select * from tasks t
         where t.facility = l.facility
           and t.fromloc = l.locid
           and t.tasktype = 'CC');
           
create or replace view cyclecountrequestitemview
(
FACILITY,
LOCATION,
STATUS,
STATUSABBREV,
ITEM,
LOTNUMBER,
CUSTID,
PRODUCTGROUP,
VELOCITY,
pickingzone,
loctype,
loctypeabbrev
)
as
select
distinct
p.FACILITY,
p.location,
l.LOCATIONSTATUS,
l.LOCATIONSTATUSABBREV,
p.ITEM,
p.LOTNUMBER,
p.CUSTID,
i.productgroup,
nvl(i.VELOCITY,'?'),
l.pickingzone,
l.loctype,
l.loctypeabbrev
from custitem i, locationview l, plate p
where p.FACILITY = l.FACILITY
and p.location = l.locid
and l.loctype in ('STO','PF')
and p.type = 'PA'
and p.custid = i.custid(+)
and p.item = i.item(+)
and not exists
  (select * from tasks t
         where t.facility = l.facility
           and t.fromloc = l.locid
           and t.tasktype = 'CC'
		   and t.custid = p.custid
		   and t.item = p.item);
comment on table cyclecountrequestitemview is '$Id$';
           
exit;
