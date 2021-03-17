-- NOTE: these are static representations of views that
-- are created dynamically at export time; if changes are made here
-- they must also be reflected in the view definition logic in
-- zimp.begin_ship_sum_class/zimp.end_ship_sum_class
create or replace view shipsum_ord
(custid,
company,
warehouse,
orderid,
shipid,
reference,
qty
)
as
select
oh.custid,
nvl(cc.abbrev,sp.inventoryclass),
nvl(cw.abbrev,sp.inventoryclass),
oh.orderid,
oh.shipid,
oh.reference,
sum(sp.quantity)
from orderstatus cc, inventorystatus cw,
     shippingplate sp, orderhdr oh
where oh.orderid = sp.orderid
  and oh.shipid = sp.shipid
  and oh.custid = 'HP'
  and oh.orderstatus = '9'
  and sp.type in ('F','P')
  and sp.status = 'SH'
  and sp.inventoryclass = cc.code(+)
  and sp.inventoryclass = cw.code(+)
  and oh.dateshipped >= to_date('20001002120000','yyyymmddhh24miss')
  and oh.dateshipped <  to_date('20001003132200','yyyymmddhh24miss')
group by oh.custid,nvl(cc.abbrev,sp.inventoryclass),
  nvl(cw.abbrev,sp.inventoryclass),oh.orderid,oh.shipid,oh.reference
union
select
'HP',
'H51',
'HNAR',
0,
0,
'H',
0
from dual
union
select
'HP',
'H51',
'HNAR',
0,
0,
'X',
0
from dual
union
select
'HP',
'H51',
'HPCD',
0,
0,
'H',
0
from dual
union
select
'HP',
'H51',
'HPCD',
0,
0,
'X',
0
from dual;

comment on table shipsum_ord is '$Id';

CREATE OR REPLACE VIEW ALPS.shipsum_hdr
(custid
,company
,warehouse
)
as
select
custid,
company,
warehouse
from shipsum_ord
group by custid,company,warehouse;

comment on table shipsum_hdr is '$Id';

create or replace view alps.shipsum_dtl
(custid
,company
,warehouse
,item
,itemdescr
,qty
)
as
select
oh.custid,
nvl(cc.abbrev,sp.inventoryclass),
nvl(cw.abbrev,sp.inventoryclass),
sp.item,
substr(zit.item_descr(oh.custid,sp.item),1,255),
sum(nvl(sp.quantity,0))
from orderstatus cc, inventorystatus cw,
     shippingplate sp, shipsum_ord oh
where oh.orderid = sp.orderid
  and oh.shipid = sp.shipid
  and sp.type in ('F','P')
  and sp.status = 'SH'
  and sp.inventoryclass = cc.code
  and sp.inventoryclass = cw.code
  and oh.company = cc.abbrev
  and oh.warehouse = cw.abbrev
group by oh.custid,nvl(cc.abbrev,sp.inventoryclass),
  nvl(cw.abbrev,sp.inventoryclass),
  sp.item,substr(zit.item_descr(oh.custid,sp.item),1,255);

comment on table shipsum_dtl is '$Id';

CREATE OR REPLACE VIEW ALPS.shipsum_tot
(custid
,totalseq
,company
,warehouse
,totaltype
,ordercount
)
as
select
custid,
'A',
company,
warehouse,
decode(substr(reference,1,1),'H','WEBBV ORDERS','SYKES ORDERS'),
count(1) - 1
from shipsum_ord
where substr(reference,1,1) = 'H'
group by custid,'A',company,warehouse,
  decode(substr(reference,1,1),'H','WEBBV ORDERS','SYKES ORDERS')
union
select
custid,
'B',
company,
warehouse,
decode(substr(reference,1,1),'H','WEBBV ORDERS','SYKES ORDERS'),
count(1) - 1
from shipsum_ord
where substr(reference,1,1) != 'H'
group by custid,'B',company,warehouse,
  decode(substr(reference,1,1),'H','WEBBV ORDERS','SYKES ORDERS')
union
select
custid,
'C',
company,
warehouse,
'TOTAL ORDERS',
count(1) - 2
from shipsum_ord
group by custid,'C',company,warehouse,'TOTAL ORDERS';

comment on table shipsum_tot is '$Id';

CREATE OR REPLACE VIEW ALPS.shipsum_grand_tot
(custid
,company
,warehouse
,itemcount
)
as
select
custid,
company,
warehouse,
count(1)
from shipsum_dtl
group by custid,company,warehouse;

comment on table shipsum_grand_tot is '$Id';

exit;

