create or replace view loadflagsview
(
    facility,
    custid,
    jobno,
    item,
    type,
    lpid,
    status,
    carrier,
    orderid,
    shipid,
    quantity,
    created
)
as
select
    H.facility,
    H.custid,
    H.jobno,
    decode (zlfv.itemcnt(H.lpid),1,D.item,null),
    H.type,
    H.lpid,
    H.status,
    decode(zlfv.carriercnt(H.lpid),1,O.carrier,null),
    decode(zlfv.ordercnt(H.lpid),1,O.orderid,null),
    decode(zlfv.ordercnt(H.lpid),1,O.shipid,null),
    sum(D.pieces*D.quantity),
    H.created
from alps.orderhdr O, load_flag_dtl D, load_flag_hdr H
where D.lpid = H.lpid
  and O.orderid = D.orderid
  and O.shipid = D.shipid
group by H.facility, H.custid, H.jobno, decode (zlfv.itemcnt(H.lpid),1,D.item,null),
         H.type, H.lpid, H.status, decode(zlfv.carriercnt(H.lpid),1,O.carrier,null),
        decode(zlfv.ordercnt(H.lpid),1,O.orderid,null),
        decode(zlfv.ordercnt(H.lpid),1,O.shipid,null), H.created;

comment on table loadflagsview is '$Id$';



drop public synonym loadflagsview;
create public synonym loadflagsview for pecas.loadflagsview;

exit;

