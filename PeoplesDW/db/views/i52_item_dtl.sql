/*
** this is a static representation of a view that is dynamically
** created at run time--see zim4.begin_i59_extract
*/
create or replace view i52_item_dtl
(custid
,warehouse
,facility
,item
,invstatus
,inventoryclass
,unitofmeasure
,qty
,refid
,lotnumber
,eventdate
,eventtime
)
as
select
lp.custid,
'WHSE',
lp.facility,
lp.item,
lp.invstatus,
lp.inventoryclass,
lp.unitofmeasure,
sum(lp.quantity),
'XX',
lp.lotnumber,
lp.creationdate,
0
from plate lp
where lp.type = 'PA'
  and lp.status in ('A','M')
group by lp.custid,lp.facility,lp.item,lp.invstatus,lp.inventoryclass,
         lp.unitofmeasure,lp.lotnumber,lp.creationdate;

comment on table i52_item_dtl is '$Id$';

exit;
