/*
** this is a static representation of a view that is dynamically
** created at run time--see zim4.begin_c5_extract
*/
create or replace view alps.c5_item_dtl
(custid
,warehouse
,item
,invstatus
,qty
)
as
select
lp.custid,
'WHSE',
lp.item,
lp.invstatus,
sum(lp.quantity)
from plate lp
where lp.custid = 'HP'
  and lp.type = 'PA'
  and lp.status in ('A','M')
group by lp.custid,'WHSE',lp.item,lp.invstatus;

comment on table c5_item_dtl is '$Id$';

CREATE OR REPLACE VIEW alps.c5_file_hdr
(custid
,warehouse
,cntitems
,qty
)
as
select
custid,
warehouse,
count(1),
sum(qty)
from c5_item_dtl
group by custid,warehouse;

comment on table c5_file_hdr is '$Id$';

exit;
