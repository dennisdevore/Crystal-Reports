CREATE OR REPLACE VIEW ALPS.CUSTITEMSUMMARY
(
custid,
item,
facility,
descr,
cntTotal,
qtyTotal,
qtyAlloc,
productGroup,
weightTotal,
weightAlloc
)
as
select
custid,
item,
facility,
substr(zit.item_descr(custid,item),1,255) as itemdescr,
sum(lipcount) as cntTotal,
sum(qty) as qtyTotal,
zit.alloc_qty(custid,item,facility) as qtyAlloc,
zci.product_group(custid,item) as productGroup,
sum(weight) as weightTotal,
zit.alloc_weight(custid,item,facility) as weightAlloc
from custitemtotsumview
group by custid,item,facility,zci.product_group(custid,item);

comment on table CUSTITEMSUMMARY is '$Id$';

exit;
