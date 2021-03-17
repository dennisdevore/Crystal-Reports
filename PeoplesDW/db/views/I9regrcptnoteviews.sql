-- NOTE: these are static representations of views that
-- are created dynamically at export time; if changes are made here
-- they must also be reflected in the view definition logic in
-- zim5.begin_I9_rcpt_note/zim5.end_I9_rcpt_note
create or replace view alps.I9_rcpt_note_dtl
(custid
,loadno
,orderid
,shipid
,orderitem
,orderlot
,po
,linenumber
,carrier
,billoflading
,receiptdate
,movement
,reason
,item
,warehouse
,qtyrcvd
)
as
select
oh.custid,
oh.loadno,
oh.orderid,
oh.shipid,
rc.orderitem,
rc.orderlot,
oh.po,
od.dtlpassthrunum10,
nvl(ld.carrier,oh.carrier),
oh.billoflading,
oh.statusupdate,
'101',
'0001',
rc.item,
'HPC1',
sum(rc.qtyrcvd)
from loads ld, orderhdr oh, orderdtl od, orderdtlrcpt rc
where rc.orderid = oh.orderid
  and rc.shipid = oh.shipid
  and rc.orderid = od.orderid
  and rc.shipid = od.shipid
  and rc.orderitem = od.item
  and nvl(rc.lotnumber,'(none)') = nvl(od.lotnumber,'(none)')
  and oh.orderstatus = 'R'
  and oh.loadno = ld.loadno(+)
group by oh.custid,oh.loadno,oh.orderid,oh.shipid,
  rc.orderitem,rc.orderlot,oh.po,od.dtlpassthrunum10,
  nvl(ld.carrier,oh.carrier),oh.billoflading,oh.statusupdate,
  '101','0001',rc.item;

comment on table I9_rcpt_note_dtl is '$Id';

CREATE OR REPLACE VIEW ALPS.I9_rcpt_note_hdr
(custid
,loadno
,orderid
,shipid
,orderitem
,orderlot
,po
,linenumber
,carrier
,billoflading
,receiptdate
,movement
,reason
)
as
select
distinct
 custid
,loadno
,orderid
,shipid
,orderitem
,orderlot
,po
,linenumber
,carrier
,billoflading
,receiptdate
,movement
,reason
from I9_rcpt_note_dtl;

comment on table I9_rcpt_note_hdr is '$Id';

exit;

