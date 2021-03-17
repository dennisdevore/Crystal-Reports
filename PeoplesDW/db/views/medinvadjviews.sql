-- NOTE: these are static representations of views that
-- are created dynamically at export time; if changes are made here
-- they must also be reflected in the view definition logic in
-- zim14.begin_med_inv_adj/zim14.end_med_inv_adj

create or replace view alps.med_inv_adj_dtl
(fromdate,
todate,
facility,
custid,
item,
strItem,
uom,
category,
adjreason,
adjsign,
qtygood,
qtydamaged,
qtyother,
qtynet
)
as
select
WHENOCCURRED,
LASTUPDATE,
FACILITY,
CUSTID,
ITEM,
'Item ' || item,
UOM,
lastuser,
ADJREASON,
'x',
adjqty,
adjqty as q1,
adjqty as q2,
adjqty as q3
from invadjactivity
where rowid = '1';

comment on table med_inv_adj_dtl is '$Id';

create or replace view alps.med_inv_adj_hdr
(fromdate,
todate,
facility,
custid,
item,
strItem,
uom,
qtygood,
qtydamaged,
qtyother,
qtynet
)
as
select
fromdate,
todate,
facility,
custid,
item,
strItem,
uom,
sum(qtygood),
sum(qtydamaged),
sum(qtyother),
sum(qtynet)
from med_inv_adj_dtl
group by fromdate, todate, facility, custid, item, strItem, uom;

comment on table med_inv_adj_hdr is '$Id';

create or replace view alps.med_inv_adj_sum
(fromdate,
todate,
facility,
custid,
qtygood,
qtydamaged,
qtyother,
qtynet
)
as
select
fromdate,
todate,
facility,
custid,
sum(qtygood),
sum(qtydamaged),
sum(qtyother),
sum(qtynet)
from med_inv_adj_dtl
group by fromdate, todate, facility, custid;

comment on table med_inv_adj_sum is '$Id';


--exit;
