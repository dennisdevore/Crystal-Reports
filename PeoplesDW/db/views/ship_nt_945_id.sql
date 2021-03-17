create or replace view ship_nt_945_cnt
(
    orderid,
    shipid,
    custid,
    lpid,
    fromlpid,
    plt_sscc18,
    ctn_sscc18,
    trackingno,
    link_plt_sscc18,
    link_ctn_sscc18,
    link_trackingno,
    assignedid,
    item,
    lotnumber,
    link_lotnumber,
    useritem1,
    useritem2,
    useritem3,
    qty,
    UOM,
    cartons,
    dtlpassthruchar01,
    dtlpassthruchar02,
    dtlpassthruchar03,
    dtlpassthruchar04,
    dtlpassthruchar05,
    dtlpassthruchar06,
    dtlpassthruchar07,
    dtlpassthruchar08,
    dtlpassthruchar09,
    dtlpassthruchar10,
    dtlpassthruchar11,
    dtlpassthruchar12,
    dtlpassthruchar13,
    dtlpassthruchar14,
    dtlpassthruchar15,
    dtlpassthruchar16,
    dtlpassthruchar17,
    dtlpassthruchar18,
    dtlpassthruchar19,
    dtlpassthruchar20,
    dtlpassthrunum01,
    dtlpassthrunum02,
    dtlpassthrunum03,
    dtlpassthrunum04,
    dtlpassthrunum05,
    dtlpassthrunum06,
    dtlpassthrunum07,
    dtlpassthrunum08,
    dtlpassthrunum09,
    dtlpassthrunum10,
    dtlpassthrudate01,
    dtlpassthrudate02,
    dtlpassthrudate03,
    dtlpassthrudate04,
    dtlpassthrudoll01,
    dtlpassthrudoll02,
    po,
    reference,
    shipmentstatuscode,
    qtyordered,
    qtydifference,
    description,
    weight,
    volume,
    consigneesku,
    vicssubbol, -- vics_bol
    totalqtyordered,
    childlpid,
    length,
    width,
    height,
    pallet_weight
)
as
select
    S.orderid,
    S.shipid,
    S.custid,
    S.lpid,
    S.fromlpid,
    C.barcode,
    C.barcode,
    S.trackingno,
    nvl(C.barcode,'(none)'),
    nvl(C.barcode,'(none)'),
    nvl(S.trackingno,'(none)'),
    D.dtlpassthrunum10,
    S.item,
    S.lotnumber,
    nvl(S.lotnumber,'(none)'),
    S.useritem1,
    S.useritem2,
    S.useritem3,
    C.quantity,
    D.uom,
    Ceil(zcu.equiv_uom_qty(C.custid,C.item,D.uom, S.quantity, 'CS')),
    D.dtlpassthruchar01,
    D.dtlpassthruchar02,
    D.dtlpassthruchar03,
    D.dtlpassthruchar04,
    D.dtlpassthruchar05,
    D.dtlpassthruchar06,
    D.dtlpassthruchar07,
    D.dtlpassthruchar08,
    D.dtlpassthruchar09,
    D.dtlpassthruchar10,
    D.dtlpassthruchar11,
    D.dtlpassthruchar12,
    D.dtlpassthruchar13,
    D.dtlpassthruchar14,
    D.dtlpassthruchar15,
    D.dtlpassthruchar16,
    D.dtlpassthruchar17,
    D.dtlpassthruchar18,
    D.dtlpassthruchar19,
    D.dtlpassthruchar20,
    D.dtlpassthrunum01,
    D.dtlpassthrunum02,
    D.dtlpassthrunum03,
    D.dtlpassthrunum04,
    D.dtlpassthrunum05,
    D.dtlpassthrunum06,
    D.dtlpassthrunum07,
    D.dtlpassthrunum08,
    D.dtlpassthrunum09,
    D.dtlpassthrunum10,
    D.dtlpassthrudate01,
    D.dtlpassthrudate02,
    D.dtlpassthrudate03,
    D.dtlpassthrudate04,
    D.dtlpassthrudoll01,
    D.dtlpassthrudoll02,
    P.po,
    'ref                 ',
    'SS',
    D.qtyorder,
    D.qtyorder - D.qtyship,
    D.dtlpassthruchar10,
    D.weightship,
    D.cubeship,
    D.consigneesku,
    '                 ',
    D.qtyorder,
    S.lpid,
    S.length,
    S.width,
    S.height,
    S.pallet_weight
  from allplateview P, caselabels C, orderdtl D, shippingplate S
 where C.lpid(+) = S.lpid
   and D.orderid = S.orderid
   and D.shipid = S.shipid
   and D.item = S.orderitem
   and nvl(D.lotnumber,'(none)') = nvl(S.orderlot,'(none)')
   and S.type in ('F','P')
   and P.lpid(+) = S.fromlpid;

comment on table ship_nt_945_cnt is '$Id';

create or replace view ship_nt_945_id
(
    plseqno,
    seqno,
    orderid,
    shipid,
    custid,
    lpid,
    fromlpid,
    plt_sscc18,
    ctn_sscc18,
    trackingno,
    link_plt_sscc18,
    link_ctn_sscc18,
    link_trackingno,
    cartons,
    length,
    width,
    height,
    pallet_weight
)
as
select
    y.plseqno,
    row_number() over (order by null),
    orderid,
    shipid,
    custid,
    X.lpid,
    fromlpid,
    plt_sscc18,
    ctn_sscc18,
    trackingno,
    link_plt_sscc18,
    link_ctn_sscc18,
    link_trackingno,
    sum(cartons),
    length,
    width,
    height,
    pallet_weight
  from ship_nt_945_cnt X,
    (select row_number() over (order by lpid) plseqno, lpid
       from ship_nt_945_cnt
      group by lpid) Y
  where X.lpid = Y.lpid
  group by
    Y.plseqno,
    orderid,
    shipid,
    custid,
    X.lpid,
    fromlpid,
    plt_sscc18,
    ctn_sscc18,
    trackingno,
    link_plt_sscc18,
    link_ctn_sscc18,
    link_trackingno,
    length,
    width,
    height,
    pallet_weight;

comment on table ship_nt_945_id is '$Id';

create or replace view ship_nt_945_id_mm
(
    plseqno,
    seqno,
    item,
    lotnumber,
    orderid,
    shipid,
    custid,
    lpid,
    fromlpid,
    plt_sscc18,
    ctn_sscc18,
    trackingno,
    link_plt_sscc18,
    link_ctn_sscc18,
    link_trackingno,
    cartons,
    length,
    width,
    height,
    pallet_weight
)
as
select
    y.plseqno,
    row_number() over (order by null),
    item,
    lotnumber,
    orderid,
    shipid,
    custid,
    X.lpid,
    fromlpid,
    plt_sscc18,
    ctn_sscc18,
    trackingno,
    link_plt_sscc18,
    link_ctn_sscc18,
    link_trackingno,
    sum(cartons),
    length,
    width,
    height,
    pallet_weight
  from ship_nt_945_cnt X,
    (select row_number() over (order by lpid) plseqno, lpid
       from ship_nt_945_cnt
      group by lpid) Y
  where X.lpid = Y.lpid
  group by
    Y.plseqno,
    item,
    lotnumber,
    orderid,
    shipid,
    custid,
    X.lpid,
    fromlpid,
    plt_sscc18,
    ctn_sscc18,
    trackingno,
    link_plt_sscc18,
    link_ctn_sscc18,
    link_trackingno,
    length,
    width,
    height,
    pallet_weight;

comment on table ship_nt_945_id_mm is '$Id';


create or replace view ship_nt_945_pl
(
    plseqno,
    orderid,
    shipid,
    custid,
    lpid,
    fromlpid,
    plt_sscc18,
    link_plt_sscc18,
    cartons,
    length,
    width,
    height,
    pallet_weight
)
as
select
    plseqno,
    orderid,
    shipid,
    custid,
    lpid,
    fromlpid,
    plt_sscc18,
    link_plt_sscc18,
    sum(cartons),
    length,
    width,
    height,
    pallet_weight
  from ship_nt_945_id
  group by
    plseqno,
    orderid,
    shipid,
    custid,
    lpid,
    fromlpid,
    plt_sscc18,
    link_plt_sscc18,
    length,
    width,
    height,
    pallet_weight;

comment on table ship_nt_945_pl is '$Id';

create or replace view ship_nt_945_pl_mm
(
    plseqno,
    seqno,
    item,
    lotnumber,
    orderid,
    shipid,
    custid,
    lpid,
    fromlpid,
    plt_sscc18,
    link_plt_sscc18,
    cartons
)
as
select
    plseqno,
    seqno,
    item,
    lotnumber,
    orderid,
    shipid,
    custid,
    lpid,
    fromlpid,
    plt_sscc18,
    link_plt_sscc18,
    sum(cartons)
  from ship_nt_945_id_mm
  group by
    plseqno,
    seqno,
    item,
    lotnumber,
    orderid,
    shipid,
    custid,
    lpid,
    fromlpid,
    plt_sscc18,
    link_plt_sscc18;

comment on table ship_nt_945_pl is '$Id';

exit
