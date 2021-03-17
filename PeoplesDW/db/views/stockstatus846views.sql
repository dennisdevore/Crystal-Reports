create or replace view stock_status_846_hdr
(
    facility,
    custid,
    facility_name,
    facility_addr1,
    facility_addr2,
    facility_city,
    facility_state,
    facility_postalcode,
    facility_countrycode,
    facility_phone,
    customer_name,
    customer_addr1,
    customer_addr2,
    customer_city,
    customer_state,
    customer_postalcode,
    customer_countrycode,
    customer_phone
)
as
select distinct
    I.facility,
    I.custid,
    F.name,
    F.addr1,
    F.addr2,
    F.city,
    F.state,
    F.postalcode,
    F.countrycode,
    F.phone,
    C.name,
    C.addr1,
    C.addr2,
    C.city,
    C.state,
    C.postalcode,
    C.countrycode,
    C.phone
  from facility F, customer C, custitemtot I
 where I.custid = C.custid
   and I.facility = F.facility(+)
   and I.item not in ('UNKNOWN','RETURNS','x')
   and I.status not in ('D','P','U','CM');

comment on table stock_status_846_hdr is '$Id$';

create or replace view stock_status_846_dtl
(
    facility,
    custid,
    item,
    upc,
    lotnumber,
    link_lotnumber,
    descr,
    baseuom,
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
    itmpassthrunum10
)
as
select distinct
    S.facility,
    CI.custid,
    CI.item,
    decode(T.lotnumber,'(none)', null, T.lotnumber),
    nvl(T.lotnumber, '(none)'),
    U.upc,
    CI.descr,
    CI.baseuom,
    CI.itmpassthruchar01,
    CI.itmpassthruchar02,
    CI.itmpassthruchar03,
    CI.itmpassthruchar04,
    CI.itmpassthruchar05,
    CI.itmpassthruchar06,
    CI.itmpassthruchar07,
    CI.itmpassthruchar08,
    CI.itmpassthruchar09,
    CI.itmpassthruchar10,
    CI.itmpassthrunum01,
    CI.itmpassthrunum02,
    CI.itmpassthrunum03,
    CI.itmpassthrunum04,
    CI.itmpassthrunum05,
    CI.itmpassthrunum06,
    CI.itmpassthrunum07,
    CI.itmpassthrunum08,
    CI.itmpassthrunum09,
    CI.itmpassthrunum10
  from custitemtot T,custitem CI, custitemupcview U, stock_status_846_hdr S
 where S.custid = CI.custid
   and CI.custid = U.custid(+)
   and CI.item = U.item(+)
   and CI.item not in ('UNKNOWN','RETURNS','x')
   and S.facility = T.facility
   and CI.custid = T.custid(+)
   and CI.item = T.item(+)
union
select distinct
    S.facility,
    CI.custid,
    CI.item,
    null,
    '(none)',
    U.upc,
    CI.descr,
    CI.baseuom,
    CI.itmpassthruchar01,
    CI.itmpassthruchar02,
    CI.itmpassthruchar03,
    CI.itmpassthruchar04,
    CI.itmpassthruchar05,
    CI.itmpassthruchar06,
    CI.itmpassthruchar07,
    CI.itmpassthruchar08,
    CI.itmpassthruchar09,
    CI.itmpassthruchar10,
    CI.itmpassthrunum01,
    CI.itmpassthrunum02,
    CI.itmpassthrunum03,
    CI.itmpassthrunum04,
    CI.itmpassthrunum05,
    CI.itmpassthrunum06,
    CI.itmpassthrunum07,
    CI.itmpassthrunum08,
    CI.itmpassthrunum09,
    CI.itmpassthrunum10
  from custitemtot T, custitem CI, custitemupcview U, stock_status_846_hdr S
 where S.custid = CI.custid
   and CI.custid = U.custid(+)
   and CI.item = U.item(+)
   and CI.item not in ('UNKNOWN','RETURNS','x')
   and not exists (select item from custitemtot T
    where T.facility = S.facility
      and T.custid = CI.custid
      and T.item = CI.item);

comment on table stock_status_846_dtl is '$Id$';

create or replace view stock_status_846_qty
(
    facility,
    custid,
    item,
    lotnumber,
    link_lotnumber,
    activity,
    uom,
    quantity
)
as
select
    S.facility,
    S.custid,
    S.item,
    decode(I.lotnumber,'(none)', null, I.lotnumber),
    nvl(I.lotnumber, '(none)'),
    decode(nvl(I.invstatus,'AV'), 'DM','74','AV','02','QH'),
    nvl(I.uom,S.baseuom),
    sum(nvl(qty,0))
  from custitemtot I, stock_status_846_dtl S
 where S.facility = I.facility
   and S.custid = I.custid
   and S.item = I.item
   and I.status not in ('D','P','U','CM')
   and I.invstatus != 'AV'
   group by
    S.facility,
    S.custid,
    S.item,
    decode(I.lotnumber,'(none)', null, I.lotnumber),
    nvl(I.lotnumber, '(none)'),
    decode(nvl(I.invstatus,'AV'), 'DM','74','AV','02','QH'),
    nvl(I.uom,S.baseuom)
union
select
    S.facility,
    S.custid,
    S.item,
    decode(I.lotnumber,'(none)', null, I.lotnumber),
    nvl(I.lotnumber, '(none)'),
    '17',
    nvl(I.uom,S.baseuom),
    sum(nvl(qty,0))
  from custitemtot I, stock_status_846_dtl S
 where S.facility = I.facility(+)
   and S.custid = I.custid(+)
   and S.item = I.item(+)
   and I.status(+) not in ('D','P','U','CM')
   group by
    S.facility,
    S.custid,
    S.item,
    decode(I.lotnumber,'(none)', null, I.lotnumber),
    nvl(I.lotnumber, '(none)'),
    '17',
    nvl(I.uom,S.baseuom);

comment on table stock_status_846_qty is '$Id$';

create or replace view stock_status_846_lip
(
    facility,
    custid,
    lpid,
    item,
    descr,
    lotnumber,
    link_lotnumber,
    quantity,
    itmpassthruchar01,
    itmpassthruchar02,
    itmpassthruchar03,
    itmpassthruchar04,
    useritem1,
    useritem2,
    useritem3,
    expirationdate,
    invstatus,
    condition,
    adjreason,
	manufacturedate,
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
    itmpassthrunum10
)
as
    select distinct P.facility, P.custid, P.lpid, P.item, D.descr,
        P.lotnumber, nvl(P.lotnumber,'(none)'), P.quantity, 
        D.itmpassthruchar01, D.itmpassthruchar02, 
        D.itmpassthruchar03, D.itmpassthruchar04,
        P.useritem1, P.useritem2, P.useritem3, P.expirationdate, 
        P.invstatus, P.condition, zim7.getdmgreason(P.lpid), 
		P.manufacturedate, D.itmpassthruchar05,
        D.itmpassthruchar06, D.itmpassthruchar07,
        D.itmpassthruchar08, D.itmpassthruchar09,
        D.itmpassthruchar10, D.itmpassthrunum01,
        D.itmpassthrunum02,  D.itmpassthrunum03,
        D.itmpassthrunum04, D.itmpassthrunum05,  
    	D.itmpassthrunum06, D.itmpassthrunum07,
        D.itmpassthrunum08, D.itmpassthrunum09,
        D.itmpassthrunum10 
    from stock_status_846_dtl D, 
         allplateview P
    where D.facility = P.facility
     and D.custid = P.custid
     and D.item = P.item
     and D.link_lotnumber = nvl(P.lotnumber,'(none)');

comment on table stock_status_846_lip is '$Id$';
create or replace view stkstat846_hdr
(
    facility,
    custid,
    facility_name,
    facility_addr1,
    facility_addr2,
    facility_city,
    facility_state,
    facility_postalcode,
    facility_countrycode,
    facility_phone,
    customer_name,
    customer_addr1,
    customer_addr2,
    customer_city,
    customer_state,
    customer_postalcode,
    customer_countrycode,
    customer_phone
)
as
select distinct
    I.facility,
    I.custid,
    F.name,
    F.addr1,
    F.addr2,
    F.city,
    F.state,
    F.postalcode,
    F.countrycode,
    F.phone,
    C.name,
    C.addr1,
    C.addr2,
    C.city,
    C.state,
    C.postalcode,
    C.countrycode,
    C.phone
  from facility F, customer C, custitemtot I
 where I.custid = C.custid
   and I.facility = F.facility(+)
   and I.item not in ('UNKNOWN','RETURNS','x')
   and I.status not in ('D','P','U','CM');

comment on table stkstat846_hdr is '$Id$';

create or replace view stkstat846_dtl
(
    facility,
    custid,
    item,
    lotnumber,
    link_lotnumber,
    upc,
    descr,
    baseuom,
    itmpassthruchar01,
    itmpassthruchar02,
    itmpassthruchar03,
    itmpassthruchar04
)
as
select distinct
    S.facility,
    CI.custid,
    CI.item,
    decode(T.lotnumber,'(none)', null, T.lotnumber),
    nvl(T.lotnumber, '(none)'),
    U.upc,
    CI.descr,
    CI.baseuom,
    CI.itmpassthruchar01,
    CI.itmpassthruchar02,
    CI.itmpassthruchar03,
    CI.itmpassthruchar04
  from custitemtot T,custitem CI, custitemupcview U, stkstat846_hdr S
 where S.custid = CI.custid
   and CI.custid = U.custid(+)
   and CI.item = U.item(+)
   and CI.item not in ('UNKNOWN','RETURNS','x')
   and S.facility = T.facility
   and CI.custid = T.custid(+)
   and CI.item = T.item(+)
union
select distinct
    S.facility,
    CI.custid,
    CI.item,
    null,
    '(none)',
    U.upc,
    CI.descr,
    CI.baseuom,
    CI.itmpassthruchar01,
    CI.itmpassthruchar02,
    CI.itmpassthruchar03,
    CI.itmpassthruchar04
  from custitemtot T, custitem CI, custitemupcview U, stock_status_846_hdr S
 where S.custid = CI.custid
   and CI.custid = U.custid(+)
   and CI.item = U.item(+)
   and CI.item not in ('UNKNOWN','RETURNS','x')
   and not exists (select item from custitemtot T
    where T.facility = S.facility
      and T.custid = CI.custid
      and T.item = CI.item);

comment on table stkstat846_dtl is '$Id$';

create or replace view stkstat846_qty
(
    facility,
    custid,
    item,
    lotnumber,
    link_lotnumber,
    activity,
    uom,
    quantity
)
as
select
    S.facility,
    S.custid,
    S.item,
    decode(I.lotnumber,'(none)', null, I.lotnumber),
    nvl(I.lotnumber, '(none)'),
    decode(nvl(I.invstatus,'AV'), 'DM','74','AV','02','QH'),
    nvl(I.uom,S.baseuom),
    sum(nvl(qty,0))
  from custitemtot I, stkstat846_dtl S
 where S.facility = I.facility
   and S.custid = I.custid
   and S.item = I.item
   and I.status not in ('D','P','U','CM')
   and I.invstatus != 'AV'
   group by
    S.facility,
    S.custid,
    S.item,
    decode(I.lotnumber,'(none)', null, I.lotnumber),
    nvl(I.lotnumber, '(none)'),
    decode(nvl(I.invstatus,'AV'), 'DM','74','AV','02','QH'),
    nvl(I.uom,S.baseuom)
union
select
    S.facility,
    S.custid,
    S.item,
    decode(I.lotnumber,'(none)', null, I.lotnumber),
    nvl(I.lotnumber, '(none)'),
    '17',
    nvl(I.uom,S.baseuom),
    sum(nvl(qty,0))
  from custitemtot I, stkstat846_dtl S
 where S.facility = I.facility(+)
   and S.custid = I.custid(+)
   and S.item = I.item(+)
   and I.status(+) not in ('D','P','U','CM')
   group by
    S.facility,
    S.custid,
    S.item,
    decode(I.lotnumber,'(none)', null, I.lotnumber),
    nvl(I.lotnumber, '(none)'),
    '17',
    nvl(I.uom,S.baseuom);

comment on table stkstat846_qty is '$Id$';

create or replace view stkstat846_lip
(
    facility,
    custid,
    lpid,
    item,
    descr,
    lotnumber,
    link_lotnumber,
    quantity,
    itmpassthruchar01,
    itmpassthruchar02,
    itmpassthruchar03,
    itmpassthruchar04,
    useritem1,
    useritem2,
    useritem3,
    expirationdate,
    invstatus,
    condition,
    adjreason
)
as
    select distinct P.facility, P.custid, P.lpid, P.item, D.descr,
        P.lotnumber,  nvl(P.lotnumber,'(none)'), P.quantity, 
        D.itmpassthruchar01, D.itmpassthruchar02, 
        D.itmpassthruchar03, D.itmpassthruchar04,
        P.useritem1, P.useritem2, P.useritem3, P.expirationdate, 
        P.invstatus, P.condition, zim7.getdmgreason(P.lpid) 
    from stkstat846_dtl D,
         allplateview P
    where D.facility = P.facility
     and D.custid = P.custid
     and D.item = P.item
     and D.link_lotnumber = nvl(P.lotnumber,'(none)');

comment on table stkstat846_lip is '$Id$';



-- exit;
