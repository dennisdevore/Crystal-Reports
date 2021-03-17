-- NOTE: these are static representations of views that
-- are created dynamically at export time; if changes are made here
-- they must also be reflected in the view definition logic in
-- zim5.begin_I9_ship_note/zim5.end_I9_ship_note
create or replace view alps.I9_ship_note_dtl
(custid
,loadno
,orderid
,shipid
,reference
,ctostonumber
,orderitem
,orderlot
,po
,linenumber
,carrier
,billoflading
,statusupdate
,movement
,specialstock
,reason
,item
,fromstorageloc
,tostorageloc
,qty
)
as
select
oh.custid,
oh.loadno,
oh.orderid,
oh.shipid,
oh.reference,
12345678,
rc.orderitem,
rc.orderlot,
oh.po,
od.dtlpassthrunum10,
nvl(ld.carrier,oh.carrier),
oh.billoflading,
oh.statusupdate,
'101',
'K',
'0001',
rc.item,
'HPC1',
'HNAR',
sum(rc.qtyrcvd)
from loads ld, orderhdr oh, orderdtl od, orderdtlrcpt rc
where rc.orderid = oh.orderid
  and rc.shipid = oh.shipid
  and rc.orderid = od.orderid
  and rc.shipid = od.shipid
  and rc.orderitem = od.item
  and nvl(rc.lotnumber,'(none)') = nvl(od.lotnumber,'(none)')
  and oh.orderstatus = '9'
  and oh.loadno = ld.loadno(+)
group by oh.custid,oh.loadno,oh.orderid,oh.shipid,oh.reference,12345678,
  rc.orderitem,rc.orderlot,oh.po,od.dtlpassthrunum10,
  nvl(ld.carrier,oh.carrier),oh.billoflading,oh.statusupdate,
  '101','K','0001',rc.item,'HPC1','HNAR';

comment on table I9_ship_note_dtl is '$Id';

CREATE OR REPLACE VIEW ALPS.I9_ship_note_hdr
(custid
,loadno
,orderid
,shipid
,reference
,ctostonumber
,orderitem
,orderlot
,po
,linenumber
,carrier
,billoflading
,statusupdate
,movement
,specialstock
,reason
)
as
select
distinct
 custid
,loadno
,orderid
,shipid
,reference
,ctostonumber
,orderitem
,orderlot
,po
,linenumber
,carrier
,billoflading
,statusupdate
,movement
,specialstock
,reason
from I9_ship_note_dtl;

comment on table I9_ship_note_hdr is '$Id';

exit;

