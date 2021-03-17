-- NOTE: these are static representations of views that
-- are created dynamically at export time; if changes are made here
-- they must also be reflected in the view definition logic in
-- zim14.begin_receipts/zim14.end_med_receipts
create or replace view alps.med_receipts
(fromdate,
todate,
rcvddate,
facility,
custid,
orderid,
shipid,
reference,
po,
item,
uom,
lotnumber,
uomorder,
qtyorder,
uomrcvd,
qtyrcvd,
uomrcvdgood,
qtyrcvdgood,
uomrcvddmgd,
qtyrcvddmgd)
as
select
to_date('20020102030405','yyyymmddhh24miss'),
to_date('20020102030405','yyyymmddhh24miss'),
oh.statusupdate,
oh.tofacility,
oh.custid,
oh.orderid,
oh.shipid,
oh.reference,
oh.po,
od.item,
od.uom,
od.lotnumber,
od.uomentered,
od.qtyorder,
od.uom,
od.qtyrcvd,
'UOM1',
od.qtyrcvdgood,
'U0M2',
od.qtyrcvddmgd
from orderdtl od, orderhdr oh
where oh.orderid = od.orderid
  and oh.shipid = od.shipid;
  
comment on table med_receipts is '$Id';
  
--exit;
