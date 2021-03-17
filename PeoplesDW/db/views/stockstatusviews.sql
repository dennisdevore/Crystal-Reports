create or replace view alps.stockstat_nolip
(custid
,company
,warehouse
,item
,inventoryclass
,invstatus
,status
,lipcount
,qty
)
as
select
distinct
custitem.custid
,'H50'
,'HPC1'
,custitem.item
,'RG'
,'AV'
,'A'
,0
,0
from custitem
where custid = 'HP'
  and custitem.status = 'ACTV'
  and custitem.item not in ('UNKNOWN','RETURNS','x')
  and not exists
    (select * from custitemtot
      where custitem.custid = custitemtot.custid
        and custitem.item = custitemtot.item
        and custitem.inventoryclass = 'RG'
        and custitemtot.status not in ('D','P'));

comment on table stockstat_nolip is '$Id$';

create or replace view alps.stockstat_nolot
(custid
,company
,warehouse
,item
,inventoryclass
,invstatus
,status
,lipcount
,qty
)
as
select
custid
,'CMP'
,'WHSE'
,item
,inventoryclass
,invstatus
,status
,sum(lipcount)
,sum(qty)
from custitemtot
where custid = 'HP'
  and custitemtot.item not in ('UNKNOWN','RETURNS','x')
  and custitemtot.status not in ('D','P')
group by custid,'CMP','WHSE',item,
inventoryclass,invstatus,status
union
select * from stockstat_nolip;

comment on table stockstat_nolot is '$Id$';

CREATE OR REPLACE VIEW alps.stockstat_file_hdr
(custid
,company
,warehouse
,min_warehouse
,max_warehouse
)
as
select
distinct
'HP',
cc.abbrev,
cw.abbrev,
cw.abbrev,
cw.abbrev
from orderstatus cc, orderstatus cw
where cc.code = cw.code;

comment on table stockstat_file_hdr is '$Id$';

create or replace view alps.stockstat_item_hdr
(custid
,company
,warehouse
)
as
select
distinct
custid,
company,
warehouse
from stockstat_file_hdr;

comment on table stockstat_item_hdr is '$Id$';

create or replace view alps.stockstat_class
(custid
,company
,warehouse
,item
,inventoryclass
,qtyonhand
,qtyavail
,qtynotavail
)
as
select
custid,
company,
warehouse,
item,
inventoryclass,
sum(qty),
zit.alloc_qty_class(custid,item,null,inventoryclass),
zit.not_avail_qty(custid,item,null,inventoryclass)
from stockstat_nolot
where zci.custitem_sign(status) > 0
  and invstatus != 'SU'
group by custid,
company,warehouse,item,inventoryclass;

comment on table stockstat_class is '$Id$';

create or replace view alps.stockstat_item
(custid
,company
,warehouse
,item
,inventoryclass
,qtyonhand
,qtyalloc
,qtyavail
,qtynotavail
)
as
select
custid,
company,
warehouse,
item,
inventoryclass,
sum(qtyonhand),
sum(qtyonhand - qtyavail - qtynotavail),
sum(qtyavail),
sum(qtynotavail)
from stockstat_class
group by custid,
company,warehouse,item,inventoryclass;

comment on table stockstat_item is '$Id$';

create or replace view alps.stockstat_item_dtl
(custid
,company
,warehouse
,item
,itemalias
,qtyonhand
,qtyalloc
,qtyavail
,qtynotavail
)
as
select
si.custid,
si.company,
si.warehouse,
si.item,
cia.itemalias,
zit.no_neg(sum(qtyonhand)),
zit.no_neg(sum(qtyalloc)),
zit.no_neg(sum(qtyavail)),
zit.no_neg(sum(qtynotavail))
from custitemalias cia, stockstat_item si
group by si.custid,si.company,si.warehouse,si.item,cia.itemalias;

comment on table stockstat_item_dtl is '$Id$';

create or replace view alps.stockstat_item_trl
(custid
,company
,warehouse
,dtlcount
)
as
select
custid,
company,
warehouse,
0
from stockstat_file_hdr;

comment on table stockstat_item_trl is '$Id$';

create or replace view alps.stockstat_file_trl
(custid
,company
,warehouse
,sumcount
)
as
select
custid,
company,
warehouse,
0
from stockstat_file_hdr;

comment on table stockstat_file_trl is '$Id$';

create or replace view alps.stockstat_summ_rpt
(facility
,custid
,item
,invstatus
,status
,qty
,descr
,name
,qtyorder
)
as
select cit.facility,
cu.custid,
ci.item,
cit.invstatus,
cit.status,
cit.qty,
ci.descr,
cu.name,
(select sum(od.qtyorder)
from orderhdr oh,
orderdtl od
where oh.custid = cu.custid
and oh.fromfacility = cit.facility
and oh.orderstatus in ('0','1')
and od.linestatus = 'A'
and od.orderid = oh.orderid
and od.shipid = oh.shipid
and od.item = ci.item)
from customer cu, custitem ci, custitemtot cit
where cu.custid = ci.custid
and cit.custid = ci.custid
and cit.item = ci.item
and cit.status <> 'P'
and cit.invstatus <> 'SU'
union all
select oh.fromfacility,
cu.custid,
ci.item,
'',
'',
0,
ci.descr,
cu.name,
sum(nvl(od.qtyorder,0))
from customer cu, custitem ci, orderhdr oh, orderdtl od
where cu.custid = ci.custid
and oh.custid = cu.custid
and oh.orderstatus in ('0','1')
and od.linestatus = 'A'
and od.orderid = oh.orderid
and od.shipid = oh.shipid
and od.item = ci.item
and not exists(select 1
from custitemtot cit
where cit.facility = oh.fromfacility
and cit.custid = cu.custid
and cit.item = ci.item
and cit.status <> 'P'
and cit.invstatus <> 'SU')
group by oh.fromfacility,
cu.custid,
ci.item,
ci.descr,
cu.name;

exit;

