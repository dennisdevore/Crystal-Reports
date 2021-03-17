-- NOTE: these are static representations of views that
-- are created dynamically at export time; if changes are made here
-- they must also be reflected in the view definition logic in
-- zim5.begin_I44_rcpt_note/zim5.end_I44_rcpt_note
create or replace view I44_rcpt_note_dtl
(
orderid,
shipid,
linenumber,
item,
serialnumber,
trackingno,
qty
)
as
select
OD.orderid,
OD.shipid,
OD.item,
OD.dtlpassthrunum10,
nvl(sp.serialnumber,'000000000000000000000000000000'),
nvl(sp.trackingno,'000000000000000000000000000000'),
OD.qtyorder
from shippingplate sp, orderdtl od
where OD.orderid = sp.orderid(+)
  and OD.shipid = sp.shipid(+)
  and OD.item = sp.item(+);

comment on table I44_rcpt_note_dtl is '$Id';

create or replace view I44_rcpt_note_hdr
(
custid,
loadno,
orderid,
shipid,
po,
statusupdate,
reference,
shiptoname,
shiptoaddr1,
shiptoaddr2,
shiptocity,
shiptostate,
shiptopostalcode,
shiptocountrycode,
hdrpassthruchar01,
hdrpassthruchar02,
hdrpassthruchar03,
hdrpassthruchar04,
hdrpassthruchar05,
hdrpassthruchar06,
hdrpassthruchar07,
hdrpassthruchar08,
hdrpassthruchar09,
hdrpassthruchar10,
hdrpassthruchar11,
hdrpassthruchar12,
hdrpassthruchar13,
hdrpassthruchar14,
hdrpassthruchar15,
hdrpassthruchar16,
hdrpassthruchar17,
hdrpassthruchar18,
hdrpassthruchar19,
hdrpassthruchar20,
hdrpassthrunum01,
hdrpassthrunum02,
hdrpassthrunum03,
hdrpassthrunum04,
hdrpassthrunum05,
hdrpassthrunum06,
hdrpassthrunum07,
hdrpassthrunum08,
hdrpassthrunum09,
hdrpassthrunum10,
rma,
process_type
)
as
select
O.custid,
O.loadno,
O.orderid,
O.shipid,
O.po,
O.statusupdate,
O.reference,
O.shiptoname,
O.shiptoaddr1,
O.shiptoaddr2,
O.shiptocity,
O.shiptostate,
O.shiptopostalcode,
O.shiptocountrycode,
O.hdrpassthruchar01,
O.hdrpassthruchar02,
O.hdrpassthruchar03,
O.hdrpassthruchar04,
O.hdrpassthruchar05,
O.hdrpassthruchar06,
O.hdrpassthruchar07,
O.hdrpassthruchar08,
O.hdrpassthruchar09,
O.hdrpassthruchar10,
O.hdrpassthruchar11,
O.hdrpassthruchar12,
O.hdrpassthruchar13,
O.hdrpassthruchar14,
O.hdrpassthruchar15,
O.hdrpassthruchar16,
O.hdrpassthruchar17,
O.hdrpassthruchar18,
O.hdrpassthruchar19,
O.hdrpassthruchar20,
O.hdrpassthrunum01,
O.hdrpassthrunum02,
O.hdrpassthrunum03,
O.hdrpassthrunum04,
O.hdrpassthrunum05,
O.hdrpassthrunum06,
O.hdrpassthrunum07,
O.hdrpassthrunum08,
O.hdrpassthrunum09,
O.hdrpassthrunum10,
O.rma,
decode((select count(1) from orderhdr where custid=O.custid
   and reference=O.hdrpassthruchar02
   and ordertype='O'), 0, 'OP', 'IP')
from orderhdr O
where O.ordertype = '0'
  and O.orderstatus = 'R';
  
comment on table I44_rcpt_note_hdr is '$Id';
  
exit;

