create or replace view invadj947hdr
(
    custid,
    lpid,
    trandate,
    adjno,
    cust_name,
    cust_addr1,
    cust_addr2,
    cust_city,
    cust_state,
    cust_postalcode,
    facility,
    facility_name,
    facility_addr1,
    facility_addr2,
    facility_city,
    facility_state,
    facility_postalcode,
    custreference,
    po,
    status
)
as
select distinct
    I.custid,
    I.lpid,
    to_char(I.whenoccurred,'YYYYMMDD'),
    to_char(I.whenoccurred,'YYYYMMDDHH24MISS'),
    C.name,
    C.addr1,
    C.addr2,
    C.city,
    C.state,
    C.postalcode,
    F.facility,
    F.name,
    F.addr1,
    F.addr2,
    F.city,
    F.state,
    F.postalcode,
    I.custreference,
    'PO',
    'STATUS'
  from facility F, customer C, invadj947dtlex I
 where I.custid = C.custid(+)
   and I.facility = F.facility(+);

comment on table invadj947hdr is '$Id$';


create or replace view invadj947dtl
(
    custid,
    facility,
    adjno,
    lpid,
    reason,
    quantity,
    uom,
    upc,
    item,
    lot,
    oldtaxstat,
    newtaxstat,
    sapmove,
    newlot,
    newitem,
    custreference,
    stdinvstatus,
    oldinvstatus,
    newinvstatus,
    manufacturedate,
    expirationdate,
    lotnumber,
    holdreason,
    adjreason,
    reference,
    itmpassthruchar01,
    itmpassthruchar02,
    itmpassthruchar03,
    itmpassthruchar04,
    itmpassthruchar05,
    itmpassthruchar06,
    itmpassthruchar07,
    itmpassthruchar08,
    itmpassthruchar09,
    itmpassthruchar10,
    itmpassthrunum01,
    itmpassthrunum02,
    itmpassthrunum03,
    itmpassthrunum04,
    itmpassthrunum05,
    itmpassthrunum06,
    itmpassthrunum07,
    itmpassthrunum08,
    itmpassthrunum09,
    itmpassthrunum10,
    oldmanufacturedate,
    newmanufacturedate,
    oldexpirationdate,
    newexpirationdate
)
as
select
    I.custid,
    I.facility,
    to_char(I.whenoccurred,'YYYYMMDDHH24MISS'),
    I.lpid,
    I.rsncode,
    I.quantity,
    I.uom,
    I.upc,
    I.item,
    I.lotno,
    I.oldtaxcode,
    I.newtaxcode,
    I.sapmovecode,
    I.newlotno,
    I.newitemno,
    I.custreference,
    I.oldinvstatus,
    I.oldinvstatus,
    I.newinvstatus,
    decode(P.manufacturedate, null, DP.manufacturedate, P.manufacturedate),
    decode(P.expirationdate, null, DP.expirationdate, P.expirationdate),
    I.lotnumber,
    I.holdreason,
    '  ', -- adjreason placeholder
    I.custreference, -- reference placeholder only
    IT.itmpassthruchar01,
    IT.itmpassthruchar02,
    IT.itmpassthruchar03,
    IT.itmpassthruchar04,
    IT.itmpassthruchar05,
    IT.itmpassthruchar06,
    IT.itmpassthruchar07,
    IT.itmpassthruchar08,
    IT.itmpassthruchar09,
    IT.itmpassthruchar10,
    IT.itmpassthrunum01,
    IT.itmpassthrunum02,
    IT.itmpassthrunum03,
    IT.itmpassthrunum04,
    IT.itmpassthrunum05,
    IT.itmpassthrunum06,
    IT.itmpassthrunum07,
    IT.itmpassthrunum08,
    IT.itmpassthrunum09,
    IT.itmpassthrunum10,
    I.oldmanufacturedate,
    I.newmanufacturedate,
    I.oldexpirationdate,
    I.newexpirationdate
  from invadj947dtlex I, plate P, deletedplate DP, custitem IT
  where I.lpid = P.lpid(+)
    and I.lpid = DP.lpid(+)
    and I.custid = IT.custid(+)
    and I.item = IT.item(+);

comment on table invadj947dtl is '$Id$';

create or replace view invadj947ref
(
    custid,
    facility,
    adjno,
    lpid,
    refdesc
)
as
select
    custid,
    facility,
    to_char(whenoccurred,'YYYYMMDDHH24MISS'),
    lpid,
    dmgdesc
  from invadj947dtlex
 where dmgdesc is not null;

comment on table invadj947ref is '$Id$';

create or replace view stdinvadj947hdr
  (custid,
   trandate,
   adjno,
   cust_name,
   cust_addr1,
   cust_addr2,
   cust_city,
   cust_state,
   cust_postalcode,
   facility,
   facility_name,
   facility_addr1,
   facility_addr2,
   facility_city,
   facility_state,
   facility_postalcode)
 as select distinct
    I.custid,
    to_char(I.whenoccurred,'YYYYMMDD'),
    to_char(I.whenoccurred,'YYYYMMDDHH24MISS'),
    C.name,
    C.addr1,
    C.addr2,
    C.city,
    C.state,
    C.postalcode,
    F.facility,
    F.name,
    F.addr1,
    F.addr2,
    F.city,
    F.state,
    F.postalcode
  from facility F, customer C, invadjactivity I
  where I.custid = C.custid(+)
    and I.facility = F.facility(+);

create or replace view stdinvadj947dtl
  (whenoccurred,
   lpid,
   facility,
   custid,
   item,
   lotnumber,
   inventoryclass,
   invstatus,
   uom,
   adjqty,
   adjreason,
   adjuser,
   serialnumber,
   useritem1,
   useritem2,
   useritem3,
   oldcustid,
   olditem,
   oldlotnumber,
   oldinventoryclass,
   oldinvstatus,
   newcustid,
   newitem,
   newlotnumber,
   newinventoryclass,
   newinvstatus,
   adjweight,
   custreference,
   adjno,
   oldmanufacturedate,
   newmanufacturedate,
   oldexpirationdate,
   newexpirationdate)
as select
   whenoccurred,
   lpid,
   facility,
   custid,
   item,
   lotnumber,
   inventoryclass,
   invstatus,
   uom,
   adjqty,
   adjreason,
   adjuser,
   serialnumber,
   useritem1,
   useritem2,
   useritem3,
   oldcustid,
   olditem,
   oldlotnumber,
   oldinventoryclass,
   oldinvstatus,
   newcustid,
   newitem,
   newlotnumber,
   newinventoryclass,
   newinvstatus,
   adjweight,
   custreference,
   to_char(whenoccurred,'YYYYMMDDHH24MISS'),
   oldmanufacturedate,
   newmanufacturedate,
   oldexpirationdate,
   newexpirationdate
 from invadjactivity;

exit;

