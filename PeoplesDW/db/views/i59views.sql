/*
** this is a static representation of a view that is dynamically
** created at run time--see zim4.begin_i59_extract
*/
create or replace view alps.I59_item_dtl
(custid
,warehouse
,facility
,item
,invstatus
,qty
)
as
select
lp.custid,
'WHSE',
lp.facility,
lp.item,
lp.invstatus,
sum(lp.quantity)
from plate lp
where lp.custid = 'HP'
  and lp.type = 'PA'
  and lp.status in ('A','M')
group by lp.custid,'WHSE',lp.facility,lp.item,lp.invstatus;

comment on table I59_item_dtl is '$Id$';

--exit;
