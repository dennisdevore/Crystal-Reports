drop view physicalinventorysumview;

create or replace view physicalinventoryhdrview (
 ID,
 FACILITY,
 PAPER,
 STATUS,
 ZONE,
 FROMLOC,
 TOLOC,
 REQUESTER,
 REQUESTED,
 LASTUSER,
 LASTUPDATE,
 statusabbrev,
 custid
)
as
select
h.ID,
h.FACILITY,
h.PAPER,
h.STATUS,
h.ZONE,
h.FROMLOC,
h.TOLOC,
h.REQUESTER,
h.REQUESTED,
h.LASTUSER,
h.LASTUPDATE,
s.abbrev,
h.custid
from physicalinventorystatus s, physicalinventoryhdr h
where h.status = s.code(+);

comment on table physicalinventoryhdrview is '$Id$';

create or replace view physicalinventorydtlview (
ID,
FACILITY,
CUSTID,
TASKID,
LPID,
STATUS,
LOCATION,
ITEM,
LOTNUMBER,
UOM,
SYSTEMCOUNT,
USERCOUNT,
COUNTBY,
COUNTDATE,
COUNTCOUNT,
COUNTLOCATION,
COUNTITEM,
COUNTCUSTID,
COUNTLOT,
PREV1COUNTBY,
PREV1COUNTDATE,
PREV1USERCOUNT,
PREV1COUNTLOCATION,
PREV1COUNTITEM,
PREV1COUNTCUSTID,
PREV1COUNTLOT,
PREV2COUNTBY,
PREV2COUNTDATE,
PREV2USERCOUNT,
PREV2COUNTLOCATION,
PREV2COUNTITEM,
PREV2COUNTCUSTID,
PREV2COUNTLOT,
LASTUSER,
LASTUPDATE,
statusabbrev,
variance,
difference,
pidrowid
)
as
select
d.ID,
d.FACILITY,
d.CUSTID,
d.TASKID,
d.LPID,
d.STATUS,
d.LOCATION,
d.ITEM,
d.LOTNUMBER,
d.UOM,
nvl(d.SYSTEMCOUNT,0),
decode(d.status,'NC',0,nvl(d.USERCOUNT,0)),
d.COUNTBY,
d.COUNTDATE,
d.COUNTCOUNT,
d.COUNTLOCATION,
d.COUNTITEM,
d.COUNTCUSTID,
d.COUNTLOT,
d.PREV1COUNTBY,
d.PREV1COUNTDATE,
d.PREV1USERCOUNT,
d.PREV1COUNTLOCATION,
d.PREV1COUNTITEM,
d.PREV1COUNTCUSTID,
d.PREV1COUNTLOT,
d.PREV2COUNTBY,
d.PREV2COUNTDATE,
d.PREV2USERCOUNT,
d.PREV2COUNTLOCATION,
d.PREV2COUNTITEM,
d.PREV2COUNTCUSTID,
d.PREV2COUNTLOT,
d.LASTUSER,
d.LASTUPDATE,
s.abbrev,
decode(status,
       'NC',0-nvl(systemcount,0),
       'CT',nvl(usercount,0)-nvl(systemcount,0),
       null),
substr(zlp.phyinv_difference(d.status,d.custid,d.item,d.lotnumber,
  d.location,d.systemcount,d.countcustid,d.countitem,d.countlot,
  d.countlocation,d.usercount),1,36),
d.rowid
from physicalinventorystatus s, physicalinventorydtl d
where d.status = s.code(+);

comment on table physicalinventorydtlview is '$Id$';

create or replace view phyinvexpview (
id,
facility,
location,
custid,
item,
difference,
systemcount
)
as
select
d.id,
d.facility,
d.location,
d.custid,
d.item,
max(substr(zlp.phyinv_difference(d.status,d.custid,d.item,d.lotnumber,
  d.location,d.systemcount,d.countcustid,d.countitem,d.countlot,
  d.countlocation,d.usercount),1,36)),
sum(nvl(systemcount,0))
from physicalinventorydtl d
where nvl(systemcount,0) != 0
group by d.id,d.facility,d.location,d.custid,d.item;

comment on table phyinvexpview is '$Id$';

create or replace view phyinvactview (
id,
facility,
location,
custid,
item,
difference,
usercount
)
as
select
d.id,
d.facility,
d.countlocation,
d.countcustid,
d.countitem,
max(substr(zlp.phyinv_difference(d.status,d.custid,d.item,d.lotnumber,
  d.location,d.systemcount,d.countcustid,d.countitem,d.countlot,
  d.countlocation,d.usercount),1,36)),
sum(decode(d.status,'NC',0,nvl(usercount,0)))
from physicalinventorydtl d
where nvl(usercount,0) != 0
group by d.id,d.facility,d.countlocation,d.countcustid,d.countitem;

comment on table phyinvactview is '$Id$';

create or replace view phyinvvarview (
id,
facility,
location,
custid,
item,
difference,
systemcount,
usercount,
variance
)
as
select
e.id,
e.facility,
e.location,
e.custid,
e.item,
nvl(e.difference,a.difference),
e.systemcount,
nvl(a.usercount,0),
nvl(a.usercount,0) - e.systemcount
from phyinvactview a, phyinvexpview e
where e.id = a.id(+)
  and e.facility = a.facility(+)
  and e.location = a.location(+)
  and e.custid = a.custid(+)
  and e.item = a.item(+)
union
select
a.id,
a.facility,
a.location,
a.custid,
a.item,
a.difference,
0,
a.usercount,
a.usercount
from phyinvactview a
where not exists
(select *
   from phyinvexpview e
  where a.id = e.id
    and a.facility = e.facility
    and a.location = e.location
    and a.custid = e.custid
    and a.item = e.item);

comment on table phyinvvarview is '$Id$';


create or replace view physicalinventorylocview (
id,
facility,
location,
difference,
systemcount,
usercount,
variance
)
as
select
d.id,
d.facility,
d.location,
max(difference),
sum(d.systemcount),
sum(d.usercount),
sum(d.variance)
from phyinvvarview d
group by d.id, d.facility, d.location;

comment on table physicalinventorylocview is '$Id$';

create or replace view phyinvcompview (
id,
facility,
location,
custid,
item,
quantity
)
as
select
d.id,
d.facility,
d.location,
d.custid,
d.item,
sum(nvl(d.usercount,0))
from phyinvactview d
group by d.id,d.facility,d.location,d.custid,d.item
having sum(nvl(d.usercount,0)) !=
      (select sum(quantity)
         from plate p
        where d.facility = p.facility
          and d.location = p.location
          and d.custid = p.custid
          and d.item = p.item
          and type = 'PA');
          
comment on table phyinvcompview is '$Id$';
          

--exit;
