-- NOTE: these are static representations of views that
-- are created dynamically at export time; if changes are made here
-- they must also be reflected in the view definition logic in
-- zim14.begin_shipments/zim14.end_med_shipments
create or replace view alps.med_shipments
(fromdate,
todate,
shipdate,
facility,
custid,
orderid,
shipid,
reference,
po,
item,
lotnumber,
linenumber,
uomorder,
qtyorder,
uomship,
qtyship)
as
select
to_date('20020102030405','yyyymmddhh24miss'),
to_date('20020102030405','yyyymmddhh24miss'),
oh.statusupdate,
oh.fromfacility,
oh.custid,
oh.orderid,
oh.shipid,
oh.reference,
oh.po,
od.item,
od.lotnumber,
od.dtlpassthrunum10,
od.uomentered,
od.qtyorder,
od.uom,
od.qtyship
from orderdtl od, orderhdr oh
where oh.orderid = od.orderid
  and oh.shipid = od.shipid;
  
comment on table med_shipments is '$Id';
  
--exit;
