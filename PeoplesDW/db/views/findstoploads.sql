create or replace view findstoploads
(
    custid,
    orderid,
    shipid,
    importfileid,
    loadno)
as
select distinct
    O.custid,
    O.orderid,
    O.shipid,
    O.importfileid,
    decode( nvl(substr(C.assign_stop_load_passthru,-2),'??'),
        '??',0,
        '01',nvl(O.hdrpassthrunum01,0),
        '02',nvl(O.hdrpassthrunum02,0),
        '03',nvl(O.hdrpassthrunum03,0),
        '04',nvl(O.hdrpassthrunum04,0),
        '05',nvl(O.hdrpassthrunum05,0),
        '06',nvl(O.hdrpassthrunum06,0),
        '07',nvl(O.hdrpassthrunum07,0),
        '08',nvl(O.hdrpassthrunum08,0),
        '09',nvl(O.hdrpassthrunum09,0),
        '10',nvl(O.hdrpassthrunum10,0),
        0)
 from orderhdr O, customer C
where C.custid = O.custid;

comment on table findstoploads is '$Id';

exit;
