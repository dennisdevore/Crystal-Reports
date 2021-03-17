create or replace view qcinspectionview
(
    id,
    facility,
    custid,
    orderid,
    shipid,
    item,
    lotnumber,
    supplier,
    status,
    statusdesc,
    sampletype,
    samplesize,
    sampleuom,
    passpercent,
    qtyexpected,
    qtytoinspect,
    qtychecked,
    qtypass,
    qtyfail,
    controlnumber,
    instructions,
    po,
    qa_by_po_item,
    putaway_before_inspection_yn,
    putaway_after_inspection_yn
)
as
select
    QRQ.id,
    QRQ.facility,
    QRQ.custid,
    QR.orderid,
    QR.shipid,
    QR.item,
    QR.lotnumber,
    QR.supplier,
    QR.status,
    QR.status || ' ' || QCS.abbrev,
    QRQ.sampletype,
    QRQ.samplesize,
    QRQ.sampleuom,
    QRQ.passpercent,
    QR.qtyexpected,
    QR.qtytoinspect,
    QR.qtychecked,
    QR.qtypassed,
    QR.qtyfailed,
    QR.controlnumber,
    QRQ.instructions,
    QRQ.po,
    QRQ.qa_by_po_item,
    QRQ.putaway_before_inspection_yn,
    QRQ.putaway_after_inspection_yn
from qcstatus QCS, qcresult QR, qcrequest QRQ
where QRQ.id = QR.id
  and QR.status = QCS.code(+);

comment on table qcinspectionview is '$Id$';

-- exit;
