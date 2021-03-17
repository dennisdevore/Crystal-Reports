create or replace view stkstatusview
(facility
,custid
,item
,uom
,qtytot
,weighttot
,cubetot
,qtyavail
,weightavail
,cubeavail
,qtyallocated
,weightallocated
,cubeallocated
,qtynonavail
,weightnonavail
,cubenonavail
) as
select
tot.facility,
tot.custid,
tot.item,
ci.baseuom,
sum(tot.qty),
zci.item_weight(tot.custid,tot.item,ci.baseuom) * sum(tot.qty),
zci.item_cube(tot.custid,tot.item,ci.baseuom) * sum(tot.qty),
zit.alloc_qty(tot.custid,tot.item,tot.facility),
zci.item_weight(tot.custid,tot.item,ci.baseuom) * zit.alloc_qty(tot.custid,tot.item,tot.facility),
zci.item_cube(tot.custid,tot.item,ci.baseuom) * zit.alloc_qty(tot.custid,tot.item,tot.facility),
zit.committed_picknotship_qty(tot.custid,tot.item,tot.facility),
zci.item_weight(tot.custid,tot.item,ci.baseuom) * zit.committed_picknotship_qty(tot.custid,tot.item,tot.facility),
zci.item_cube(tot.custid,tot.item,ci.baseuom) * zit.committed_picknotship_qty(tot.custid,tot.item,tot.facility),
zit.not_avail_qty(tot.custid,tot.item,tot.facility,null),
zci.item_weight(tot.custid,tot.item,ci.baseuom) * zit.not_avail_qty(tot.custid,tot.item,tot.facility,null),
zci.item_cube(tot.custid,tot.item,ci.baseuom) * zit.not_avail_qty(tot.custid,tot.item,tot.facility,null)
from custitem ci,
     custitemtotsumview tot
where tot.custid = ci.custid
  and tot.item = ci.item
  and ( (ci.status = 'ACTV') or
        (tot.qty != 0) )
group by tot.facility,tot.custid,tot.item,ci.baseuom;

comment on table stkstatusview is '$Id$';

-- exit;
