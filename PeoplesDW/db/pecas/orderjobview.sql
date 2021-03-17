create or replace view orderjobview
(
    facility,
    custid,
    jobno,
    item,
    orderid,
    shipid,
    shiptype,
    shiptoname,
    shiptopostalcode,
    shiptostate,
    shipdate,
    carrier,
    quantity,
    pcs_ctn,
    ctn_plt,
    overage
)
as
select
    O.fromfacility,
    D.custid,
    O.reference, -- substr(D.item,1,6),
    D.item,
    O.orderid,
    O.shipid,
    O.shiptype,
    O.shiptoname,
    O.shiptopostalcode,
    O.shiptostate,
    O.shipdate,
    O.carrier,
    D.qtyorder,
    nvl(nvl(D.dtlpassthrunum01,O.hdrpassthrunum01), J.pcs_ctn),
    nvl(nvl(D.dtlpassthrunum02,O.hdrpassthrunum02), J.ctn_plt),
    nvl(O.hdrpassthrunum10, J.overage)
from alps.orderhdr O, alps.orderdtl D, jobitemsizeview J
where O.ordertype = 'O'
  and O.orderstatus = '1'
  and O.orderid = D.orderid
  and O.shipid = D.shipid
  and D.linestatus != 'X'
  and J.custid = D.custid
  and J.jobno = O.reference||'/001'
  and J.item = D.item;

comment on table orderjobview is '$Id$';

drop public synonym orderjobview;
create public synonym orderjobview for pecas.orderjobview;

exit;
