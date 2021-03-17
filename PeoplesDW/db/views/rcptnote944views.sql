create or replace view rcpt_note_944_hdr
(
    custid,
    loadno,
    orderid,
    shipid,
    company,
    warehouse,
    cust_orderid,
    cust_shipid,
    shipfrom,
    shipfromid,
    receipt_date,
    vendor,
    vendor_desc,
    bill_of_lading,
    carrier,
    routing,
    po,
    order_type,
    qtyorder,
    qtyrcvd,
    qtyrcvdgood,
    qtyrcvddmgd,
    reporting_code,
    some_date,
    unload_date,
    whse_receipt_num,
    transmeth_type,
    packer_number,
    vendor_order_num,
    warehouse_name,
    warehouse_id,
    depositor_name,
    depositor_id,
    HDRPASSTHRUCHAR01,
    HDRPASSTHRUCHAR02,
    HDRPASSTHRUCHAR03,
    HDRPASSTHRUCHAR04,
    HDRPASSTHRUCHAR05,
    HDRPASSTHRUCHAR06,
    HDRPASSTHRUCHAR07,
    HDRPASSTHRUCHAR08,
    HDRPASSTHRUCHAR09,
    HDRPASSTHRUCHAR10,
    HDRPASSTHRUCHAR11,
    HDRPASSTHRUCHAR12,
    HDRPASSTHRUCHAR13,
    HDRPASSTHRUCHAR14,
    HDRPASSTHRUCHAR15,
    HDRPASSTHRUCHAR16,
    HDRPASSTHRUCHAR17,
    HDRPASSTHRUCHAR18,
    HDRPASSTHRUCHAR19,
    HDRPASSTHRUCHAR20,
    HDRPASSTHRUCHAR21,
    HDRPASSTHRUCHAR22,
    HDRPASSTHRUCHAR23,
    HDRPASSTHRUCHAR24,
    HDRPASSTHRUCHAR25,
    HDRPASSTHRUCHAR26,
    HDRPASSTHRUCHAR27,
    HDRPASSTHRUCHAR28,
    HDRPASSTHRUCHAR29,
    HDRPASSTHRUCHAR30,
    HDRPASSTHRUCHAR31,
    HDRPASSTHRUCHAR32,
    HDRPASSTHRUCHAR33,
    HDRPASSTHRUCHAR34,
    HDRPASSTHRUCHAR35,
    HDRPASSTHRUCHAR36,
    HDRPASSTHRUCHAR37,
    HDRPASSTHRUCHAR38,
    HDRPASSTHRUCHAR39,
    HDRPASSTHRUCHAR40,
    HDRPASSTHRUCHAR41,
    HDRPASSTHRUCHAR42,
    HDRPASSTHRUCHAR43,
    HDRPASSTHRUCHAR44,
    HDRPASSTHRUCHAR45,
    HDRPASSTHRUCHAR46,
    HDRPASSTHRUCHAR47,
    HDRPASSTHRUCHAR48,
    HDRPASSTHRUCHAR49,
    HDRPASSTHRUCHAR50,
    HDRPASSTHRUCHAR51,
    HDRPASSTHRUCHAR52,
    HDRPASSTHRUCHAR53,
    HDRPASSTHRUCHAR54,
    HDRPASSTHRUCHAR55,
    HDRPASSTHRUCHAR56,
    HDRPASSTHRUCHAR57,
    HDRPASSTHRUCHAR58,
    HDRPASSTHRUCHAR59,
    HDRPASSTHRUCHAR60,
    HDRPASSTHRUNUM01,
    HDRPASSTHRUNUM02,
    HDRPASSTHRUNUM03,
    HDRPASSTHRUNUM04,
    HDRPASSTHRUNUM05,
    HDRPASSTHRUNUM06,
    HDRPASSTHRUNUM07,
    HDRPASSTHRUNUM08,
    HDRPASSTHRUNUM09,
    HDRPASSTHRUNUM10,
    HDRPASSTHRUDATE01,
    HDRPASSTHRUDATE02,
    HDRPASSTHRUDATE03,
    HDRPASSTHRUDATE04,
    HDRPASSTHRUDOLL01,
    HDRPASSTHRUDOLL02,
    prono,
    trailer,
    seal,
    palletcount,
    facility,
    SHIPPERNAME,
    SHIPPERCONTACT,
    SHIPPERADDR1,
    SHIPPERADDR2,
    SHIPPERCITY,
    SHIPPERSTATE,
    SHIPPERPOSTALCODE,
    SHIPPERCOUNTRYCODE,
    SHIPPERPHONE,
    SHIPPERFAX,
    SHIPPEREMAIL,
    BILLTONAME,
    BILLTOCONTACT,
    BILLTOADDR1,
    BILLTOADDR2,
    BILLTOCITY,
    BILLTOSTATE,
    BILLTOPOSTALCODE,
    BILLTOCOUNTRYCODE,
    BILLTOPHONE,
    BILLTOFAX,
    BILLTOEMAIL,
    rma,
    ordertype,
    returntrackingno,
    statususer,
    instructions,
    carriername,
    reference,
    shipper,
    supplier,
    scac,
    weightrcvd,
    cubercvd,
    weightrcvdgood,
    cubercvdgood,
    weightrcvddmgd,
    cubercvddmgd,
    shipterms,
    doorloc
)
as
select
    O.custid,
    L.loadno,
    O.orderid,
    O.shipid,
    ' ',
    ' ',
    O.reference, -- O.hdrpassthruchar02,
    O.hdrpassthruchar03,
    O.hdrpassthruchar19,
    O.hdrpassthruchar04,
    L.rcvddate,
    O.shipper,
    S.name,
    O.billoflading,
    O.carrier,
    O.hdrpassthruchar18,
    O.po,
    O.ordertype,
    O.qtyorder,
    sum(nvl(R.qtyrcvd,0)),
    sum(nvl(R.qtyrcvdgood,0)),
    sum(nvl(R.qtyrcvddmgd,0)),
    O.hdrpassthruchar01,
    sysdate,
    O.statusupdate,
    O.orderid || '-'||O.shipid,
    O.shiptype,
    O.hdrpassthruchar11,
    O.hdrpassthruchar12,
    F.name,
    nvl(O.hdrpassthruchar13,F.facility),
    nvl(O.hdrpassthruchar12,C.name),
    nvl(O.hdrpassthruchar08,C.custid),
    O.HDRPASSTHRUCHAR01,
    O.HDRPASSTHRUCHAR02,
    O.HDRPASSTHRUCHAR03,
    O.HDRPASSTHRUCHAR04,
    O.HDRPASSTHRUCHAR05,
    O.HDRPASSTHRUCHAR06,
    O.HDRPASSTHRUCHAR07,
    O.HDRPASSTHRUCHAR08,
    O.HDRPASSTHRUCHAR09,
    O.HDRPASSTHRUCHAR10,
    O.HDRPASSTHRUCHAR11,
    O.HDRPASSTHRUCHAR12,
    O.HDRPASSTHRUCHAR13,
    O.HDRPASSTHRUCHAR14,
    O.HDRPASSTHRUCHAR15,
    O.HDRPASSTHRUCHAR16,
    O.HDRPASSTHRUCHAR17,
    O.HDRPASSTHRUCHAR18,
    O.HDRPASSTHRUCHAR19,
    O.HDRPASSTHRUCHAR20,
    O.HDRPASSTHRUCHAR21,
    O.HDRPASSTHRUCHAR22,
    O.HDRPASSTHRUCHAR23,
    O.HDRPASSTHRUCHAR24,
    O.HDRPASSTHRUCHAR25,
    O.HDRPASSTHRUCHAR26,
    O.HDRPASSTHRUCHAR27,
    O.HDRPASSTHRUCHAR28,
    O.HDRPASSTHRUCHAR29,
    O.HDRPASSTHRUCHAR30,
    O.HDRPASSTHRUCHAR31,
    O.HDRPASSTHRUCHAR32,
    O.HDRPASSTHRUCHAR33,
    O.HDRPASSTHRUCHAR34,
    O.HDRPASSTHRUCHAR35,
    O.HDRPASSTHRUCHAR36,
    O.HDRPASSTHRUCHAR37,
    O.HDRPASSTHRUCHAR38,
    O.HDRPASSTHRUCHAR39,
    O.HDRPASSTHRUCHAR40,
    O.HDRPASSTHRUCHAR41,
    O.HDRPASSTHRUCHAR42,
    O.HDRPASSTHRUCHAR43,
    O.HDRPASSTHRUCHAR44,
    O.HDRPASSTHRUCHAR45,
    O.HDRPASSTHRUCHAR46,
    O.HDRPASSTHRUCHAR47,
    O.HDRPASSTHRUCHAR48,
    O.HDRPASSTHRUCHAR49,
    O.HDRPASSTHRUCHAR50,
    O.HDRPASSTHRUCHAR51,
    O.HDRPASSTHRUCHAR52,
    O.HDRPASSTHRUCHAR53,
    O.HDRPASSTHRUCHAR54,
    O.HDRPASSTHRUCHAR55,
    O.HDRPASSTHRUCHAR56,
    O.HDRPASSTHRUCHAR57,
    O.HDRPASSTHRUCHAR58,
    O.HDRPASSTHRUCHAR59,
    O.HDRPASSTHRUCHAR60,
    O.HDRPASSTHRUNUM01,
    O.HDRPASSTHRUNUM02,
    O.HDRPASSTHRUNUM03,
    O.HDRPASSTHRUNUM04,
    O.HDRPASSTHRUNUM05,
    O.HDRPASSTHRUNUM06,
    O.HDRPASSTHRUNUM07,
    O.HDRPASSTHRUNUM08,
    O.HDRPASSTHRUNUM09,
    O.HDRPASSTHRUNUM10,
    O.HDRPASSTHRUDATE01,
    O.HDRPASSTHRUDATE02,
    O.HDRPASSTHRUDATE03,
    O.HDRPASSTHRUDATE04,
    O.HDRPASSTHRUDOLL01,
    O.HDRPASSTHRUDOLL02,
    nvl(o.prono,l.prono),
    l.trailer,
    l.seal,
    zim7.pallet_count(o.loadno,o.custid,o.tofacility,o.orderid,o.shipid),
    F.facility,
    SHIPTONAME,
    SHIPTOCONTACT,
    SHIPTOADDR1,
    SHIPTOADDR2,
    SHIPTOCITY,
    SHIPTOSTATE,
    SHIPTOPOSTALCODE,
    SHIPTOCOUNTRYCODE,
    SHIPTOPHONE,
    SHIPTOFAX,
    SHIPTOEMAIL,
    BILLTONAME,
    BILLTOCONTACT,
    BILLTOADDR1,
    BILLTOADDR2,
    BILLTOCITY,
    BILLTOSTATE,
    BILLTOPOSTALCODE,
    BILLTOCOUNTRYCODE,
    BILLTOPHONE,
    BILLTOFAX,
    BILLTOEMAIL,
    rma,
    ordertype,
    returntrackingno,
    o.statususer,
    o.hdrpassthruchar01||o.hdrpassthruchar02||'XX',
    CA.name,
    O.reference,
    O.shipper,
    O.shipper,
    CA.scac,
    sum(nvl(R.weight,0)), --weightrcvd placeholder
    null,                 --cubercvd placeholder
    sum(nvl(R.weight,0)), --weightrcvdgoodplaceholder
    null,                 --cubercvdgoodplaceholder
    sum(nvl(R.weight,0)), --weightrcvddmgdplaceholder
    null,                 --cubercvddmgdplaceholder
    O.shipterms,
    L.doorloc
  from customer C, facility F, shipper S, loads L, orderdtlrcpt R, orderhdr O, carrier CA
 where O.orderstatus = 'R'
   and O.orderid = R.orderid
   and O.shipid = R.shipid
   and O.shipper = S.shipper(+)
   and O.loadno = L.loadno(+)
   and O.tofacility = F.facility(+)
   and O.custid = C.custid
   and O.carrier = CA.carrier(+)
group by
    O.custid,
    L.loadno,
    O.orderid,
    O.shipid,
    O.reference,
    O.hdrpassthruchar03,
    O.hdrpassthruchar19,
    O.hdrpassthruchar04,
    L.rcvddate,
    O.shipper,
    S.name,
    O.billoflading,
    O.carrier,
    O.hdrpassthruchar18,
    O.po,
    O.ordertype,
    O.qtyorder,
    O.hdrpassthruchar01,
    sysdate,
    O.statusupdate,
    O.loadno,
    O.shiptype,
    O.hdrpassthruchar11,
    O.hdrpassthruchar12,
    F.name,
    nvl(O.hdrpassthruchar13,F.facility),
    nvl(O.hdrpassthruchar12,C.name),
    nvl(O.hdrpassthruchar08,C.custid),
    O.HDRPASSTHRUCHAR01,
    O.HDRPASSTHRUCHAR02,
    O.HDRPASSTHRUCHAR03,
    O.HDRPASSTHRUCHAR04,
    O.HDRPASSTHRUCHAR05,
    O.HDRPASSTHRUCHAR06,
    O.HDRPASSTHRUCHAR07,
    O.HDRPASSTHRUCHAR08,
    O.HDRPASSTHRUCHAR09,
    O.HDRPASSTHRUCHAR10,
    O.HDRPASSTHRUCHAR11,
    O.HDRPASSTHRUCHAR12,
    O.HDRPASSTHRUCHAR13,
    O.HDRPASSTHRUCHAR14,
    O.HDRPASSTHRUCHAR15,
    O.HDRPASSTHRUCHAR16,
    O.HDRPASSTHRUCHAR17,
    O.HDRPASSTHRUCHAR18,
    O.HDRPASSTHRUCHAR19,
    O.HDRPASSTHRUCHAR20,
    O.HDRPASSTHRUCHAR21,
    O.HDRPASSTHRUCHAR22,
    O.HDRPASSTHRUCHAR23,
    O.HDRPASSTHRUCHAR24,
    O.HDRPASSTHRUCHAR25,
    O.HDRPASSTHRUCHAR26,
    O.HDRPASSTHRUCHAR27,
    O.HDRPASSTHRUCHAR28,
    O.HDRPASSTHRUCHAR29,
    O.HDRPASSTHRUCHAR30,
    O.HDRPASSTHRUCHAR31,
    O.HDRPASSTHRUCHAR32,
    O.HDRPASSTHRUCHAR33,
    O.HDRPASSTHRUCHAR34,
    O.HDRPASSTHRUCHAR35,
    O.HDRPASSTHRUCHAR36,
    O.HDRPASSTHRUCHAR37,
    O.HDRPASSTHRUCHAR38,
    O.HDRPASSTHRUCHAR39,
    O.HDRPASSTHRUCHAR40,
    O.HDRPASSTHRUCHAR41,
    O.HDRPASSTHRUCHAR42,
    O.HDRPASSTHRUCHAR43,
    O.HDRPASSTHRUCHAR44,
    O.HDRPASSTHRUCHAR45,
    O.HDRPASSTHRUCHAR46,
    O.HDRPASSTHRUCHAR47,
    O.HDRPASSTHRUCHAR48,
    O.HDRPASSTHRUCHAR49,
    O.HDRPASSTHRUCHAR50,
    O.HDRPASSTHRUCHAR51,
    O.HDRPASSTHRUCHAR52,
    O.HDRPASSTHRUCHAR53,
    O.HDRPASSTHRUCHAR54,
    O.HDRPASSTHRUCHAR55,
    O.HDRPASSTHRUCHAR56,
    O.HDRPASSTHRUCHAR57,
    O.HDRPASSTHRUCHAR58,
    O.HDRPASSTHRUCHAR59,
    O.HDRPASSTHRUCHAR60,
    O.HDRPASSTHRUNUM01,
    O.HDRPASSTHRUNUM02,
    O.HDRPASSTHRUNUM03,
    O.HDRPASSTHRUNUM04,
    O.HDRPASSTHRUNUM05,
    O.HDRPASSTHRUNUM06,
    O.HDRPASSTHRUNUM07,
    O.HDRPASSTHRUNUM08,
    O.HDRPASSTHRUNUM09,
    O.HDRPASSTHRUNUM10,
    O.HDRPASSTHRUDATE01,
    O.HDRPASSTHRUDATE02,
    O.HDRPASSTHRUDATE03,
    O.HDRPASSTHRUDATE04,
    O.HDRPASSTHRUDOLL01,
    O.HDRPASSTHRUDOLL02,
    nvl(o.prono,l.prono),
    l.trailer,
    l.seal,
    zim7.pallet_count(o.loadno,o.custid,o.tofacility,o.orderid,o.shipid),
    F.facility,
    shiptoNAME,
    shiptoCONTACT,
    shiptoADDR1,
    shiptoADDR2,
    shiptoCITY,
    shiptoSTATE,
    shiptoPOSTALCODE,
    shiptoCOUNTRYCODE,
    shiptoPHONE,
    shiptoFAX,
    shiptoEMAIL,
    BILLTONAME,
    BILLTOCONTACT,
    BILLTOADDR1,
    BILLTOADDR2,
    BILLTOCITY,
    BILLTOSTATE,
    BILLTOPOSTALCODE,
    BILLTOCOUNTRYCODE,
    BILLTOPHONE,
    BILLTOFAX,
    BILLTOEMAIL,
    rma,
    ordertype,
    returntrackingno,
    o.statususer,
    o.hdrpassthruchar01||o.hdrpassthruchar02||'XX',
    CA.name,
    CA.scac,
    O.shipterms,
    L.doorloc;

comment on table rcpt_note_944_hdr is '$Id';

create or replace view rcpt_note_944_nte
(
    custid,
    orderid,
    shipid,
    sequence,
    qualifier,
    note
)
as
select
    custid,
    orderid,
    shipid,
    sequence,
    qualifier,
    note
  from rcptnote944noteex;

comment on table rcpt_note_944_nte is '$Id';

create or replace view rcpt_note_944_dtl
(
   custid,
   orderid,
   shipid,
   line_number,
   item,
   upc,
   description,
   lotnumber,
   uom,
   qtyrcvd,
   cubercvd,
   qtyrcvdgood,
   cubercvdgood,
   qtyrcvddmgd,
   qtyorder,
   weightitem,
   weightqualifier,
   weightunitcode,
   volume,
   uom_volume
,DTLPASSTHRUCHAR01
,DTLPASSTHRUCHAR02
,DTLPASSTHRUCHAR03
,DTLPASSTHRUCHAR04
,DTLPASSTHRUCHAR05
,DTLPASSTHRUCHAR06
,DTLPASSTHRUCHAR07
,DTLPASSTHRUCHAR08
,DTLPASSTHRUCHAR09
,DTLPASSTHRUCHAR10
,DTLPASSTHRUCHAR11
,DTLPASSTHRUCHAR12
,DTLPASSTHRUCHAR13
,DTLPASSTHRUCHAR14
,DTLPASSTHRUCHAR15
,DTLPASSTHRUCHAR16
,DTLPASSTHRUCHAR17
,DTLPASSTHRUCHAR18
,DTLPASSTHRUCHAR19
,DTLPASSTHRUCHAR20
,DTLPASSTHRUCHAR21
,DTLPASSTHRUCHAR22
,DTLPASSTHRUCHAR23
,DTLPASSTHRUCHAR24
,DTLPASSTHRUCHAR25
,DTLPASSTHRUCHAR26
,DTLPASSTHRUCHAR27
,DTLPASSTHRUCHAR28
,DTLPASSTHRUCHAR29
,DTLPASSTHRUCHAR30
,DTLPASSTHRUCHAR31
,DTLPASSTHRUCHAR32
,DTLPASSTHRUCHAR33
,DTLPASSTHRUCHAR34
,DTLPASSTHRUCHAR35
,DTLPASSTHRUCHAR36
,DTLPASSTHRUCHAR37
,DTLPASSTHRUCHAR38
,DTLPASSTHRUCHAR39
,DTLPASSTHRUCHAR40
,DTLPASSTHRUNUM01
,DTLPASSTHRUNUM02
,DTLPASSTHRUNUM03
,DTLPASSTHRUNUM04
,DTLPASSTHRUNUM05
,DTLPASSTHRUNUM06
,DTLPASSTHRUNUM07
,DTLPASSTHRUNUM08
,DTLPASSTHRUNUM09
,DTLPASSTHRUNUM10
,DTLPASSTHRUNUM11
,DTLPASSTHRUNUM12
,DTLPASSTHRUNUM13
,DTLPASSTHRUNUM14
,DTLPASSTHRUNUM15
,DTLPASSTHRUNUM16
,DTLPASSTHRUNUM17
,DTLPASSTHRUNUM18
,DTLPASSTHRUNUM19
,DTLPASSTHRUNUM20
,DTLPASSTHRUDATE01
,DTLPASSTHRUDATE02
,DTLPASSTHRUDATE03
,DTLPASSTHRUDATE04
,DTLPASSTHRUDOLL01
,DTLPASSTHRUDOLL02
,qtyonhold
,qtyrcvd_invstatus
,serialnumber
,useritem1
,useritem2
,useritem3
,orig_line_number
,unload_date
,condition
,invclass
,manufacturedate
,invstatus
,link_lotnumber
,lineseq
,subpart
,cubercvddmgd
,itmpassthruchar01
,itmpassthruchar02
,itmpassthruchar03
,itmpassthruchar04
,itmpassthruchar05
,itmpassthruchar06
,itmpassthruchar07
,itmpassthruchar08
,itmpassthruchar09
,itmpassthruchar10
,itmpassthrunum01
,itmpassthrunum02
,itmpassthrunum03
,itmpassthrunum04
,itmpassthrunum05
,itmpassthrunum06
,itmpassthrunum07
,itmpassthrunum08
,itmpassthrunum09
,itmpassthrunum10
,gtin
)
as
select
    D.custid,
    D.orderid,
    D.shipid,
    nvl(D.dtlpassthruchar06,'000000'),
    D.item,
    U.upc,
    I.descr,
    D.lotnumber,
    D.uom,
    nvl(D.qtyrcvd,0),
    nvl(D.cubercvd,0),
    nvl(D.qtyrcvdgood,0),
    nvl(D.cubercvdgood,0),
    nvl(D.qtyrcvddmgd,0),
    nvl(D.qtyorder,0),
    I.weight,
    'N',
    'L',
    cube/1728,
    'CF'
,D.DTLPASSTHRUCHAR01
,D.DTLPASSTHRUCHAR02
,D.DTLPASSTHRUCHAR03
,D.DTLPASSTHRUCHAR04
,D.DTLPASSTHRUCHAR05
,D.DTLPASSTHRUCHAR06
,D.DTLPASSTHRUCHAR07
,D.DTLPASSTHRUCHAR08
,D.DTLPASSTHRUCHAR09
,D.DTLPASSTHRUCHAR10
,D.DTLPASSTHRUCHAR11
,D.DTLPASSTHRUCHAR12
,D.DTLPASSTHRUCHAR13
,D.DTLPASSTHRUCHAR14
,D.DTLPASSTHRUCHAR15
,D.DTLPASSTHRUCHAR16
,D.DTLPASSTHRUCHAR17
,D.DTLPASSTHRUCHAR18
,D.DTLPASSTHRUCHAR19
,D.DTLPASSTHRUCHAR20
,D.DTLPASSTHRUCHAR21
,D.DTLPASSTHRUCHAR22
,D.DTLPASSTHRUCHAR23
,D.DTLPASSTHRUCHAR24
,D.DTLPASSTHRUCHAR25
,D.DTLPASSTHRUCHAR26
,D.DTLPASSTHRUCHAR27
,D.DTLPASSTHRUCHAR28
,D.DTLPASSTHRUCHAR29
,D.DTLPASSTHRUCHAR30
,D.DTLPASSTHRUCHAR31
,D.DTLPASSTHRUCHAR32
,D.DTLPASSTHRUCHAR33
,D.DTLPASSTHRUCHAR34
,D.DTLPASSTHRUCHAR35
,D.DTLPASSTHRUCHAR36
,D.DTLPASSTHRUCHAR37
,D.DTLPASSTHRUCHAR38
,D.DTLPASSTHRUCHAR39
,D.DTLPASSTHRUCHAR40
,D.DTLPASSTHRUNUM01
,D.DTLPASSTHRUNUM02
,D.DTLPASSTHRUNUM03
,D.DTLPASSTHRUNUM04
,D.DTLPASSTHRUNUM05
,D.DTLPASSTHRUNUM06
,D.DTLPASSTHRUNUM07
,D.DTLPASSTHRUNUM08
,D.DTLPASSTHRUNUM09
,D.DTLPASSTHRUNUM10
,D.DTLPASSTHRUNUM11
,D.DTLPASSTHRUNUM12
,D.DTLPASSTHRUNUM13
,D.DTLPASSTHRUNUM14
,D.DTLPASSTHRUNUM15
,D.DTLPASSTHRUNUM16
,D.DTLPASSTHRUNUM17
,D.DTLPASSTHRUNUM18
,D.DTLPASSTHRUNUM19
,D.DTLPASSTHRUNUM20
,D.DTLPASSTHRUDATE01
,D.DTLPASSTHRUDATE02
,D.DTLPASSTHRUDATE03
,D.DTLPASSTHRUDATE04
,D.DTLPASSTHRUDOLL01
,D.DTLPASSTHRUDOLL02
,nvl(D.qtyship,0)
,'XX'
,d.dtlpassthruchar01
,d.dtlpassthruchar02
,d.dtlpassthruchar03
,d.dtlpassthruchar04
,nvl(d.dtlpassthrunum10,1)
,O.unload_date
,substr(d.dtlpassthruchar02,2)
,D.inventoryclass
,D.DTLPASSTHRUDATE01 -- manufacture date place holder
,D.invstatus
,nvl(d.lotnumber,'(none)')
,0
,dtlpassthruchar01 -- placeholder for subpart
,nvl(D.cubercvddmgd,0)
,I.itmpassthruchar01
,I.itmpassthruchar02
,I.itmpassthruchar03
,I.itmpassthruchar04
,I.itmpassthruchar05
,I.itmpassthruchar06
,I.itmpassthruchar07
,I.itmpassthruchar08
,I.itmpassthruchar09
,I.itmpassthruchar10
,I.itmpassthrunum01
,I.itmpassthrunum02
,I.itmpassthrunum03
,I.itmpassthrunum04
,I.itmpassthrunum05
,I.itmpassthrunum06
,I.itmpassthrunum07
,I.itmpassthrunum08
,I.itmpassthrunum09
,I.itmpassthrunum10
,D.item -- gtin placeholder
  from custitemupcview U, custitem I, orderdtl D, rcpt_note_944_hdr O
 where D.orderid = O.orderid
   and D.shipid = O.shipid
   and D.custid = I.custid
   and D.item = I.item
   and D.custid = U.custid(+)
   and D.item = U.item(+);

comment on table rcpt_note_944_dtl is '$Id';

create or replace view rcpt_note_944_lu1
(
   custid,
   orderid,
   shipid,
   item,
   lotnumber,
   uom,
   useritem1,
   qty)
   as
select
   custid,
   orderid,
   shipid,
   item,
   lotnumber,
   uom,
   useritem1,
   sum(nvl(qtyrcvdgood,0) + nvl(qtyrcvddmgd,0))
   from orderdtlrcpt
   group by custid, orderid, shipid, item, lotnumber, uom, useritem1;

create or replace view rcpt_note_944_ide
(
    custid,
    orderid,
    shipid,
    item,
    lotnumber,
    qty,
    uom,
    condition,
    damagereason,
    line_number,
    origtrackingno,
    serialnumber,
    useritem1,
    useritem2,
    useritem3,
    qtyrcvd_invstatus,
    orig_line_number,
    qtyrcvdgood,
    qtyrcvddmgd
,DTLPASSTHRUCHAR01
,DTLPASSTHRUCHAR02
,DTLPASSTHRUCHAR03
,DTLPASSTHRUCHAR04
,DTLPASSTHRUCHAR05
,DTLPASSTHRUCHAR06
,DTLPASSTHRUCHAR07
,DTLPASSTHRUCHAR08
,DTLPASSTHRUCHAR09
,DTLPASSTHRUCHAR10
,DTLPASSTHRUCHAR11
,DTLPASSTHRUCHAR12
,DTLPASSTHRUCHAR13
,DTLPASSTHRUCHAR14
,DTLPASSTHRUCHAR15
,DTLPASSTHRUCHAR16
,DTLPASSTHRUCHAR17
,DTLPASSTHRUCHAR18
,DTLPASSTHRUCHAR19
,DTLPASSTHRUCHAR20
,DTLPASSTHRUNUM01
,DTLPASSTHRUNUM02
,DTLPASSTHRUNUM03
,DTLPASSTHRUNUM04
,DTLPASSTHRUNUM05
,DTLPASSTHRUNUM06
,DTLPASSTHRUNUM07
,DTLPASSTHRUNUM08
,DTLPASSTHRUNUM09
,DTLPASSTHRUNUM10
,DTLPASSTHRUDATE01
,DTLPASSTHRUDATE02
,DTLPASSTHRUDATE03
,DTLPASSTHRUDATE04
,DTLPASSTHRUDOLL01
,DTLPASSTHRUDOLL02
,snweight
,zeroqty
)
as
select
    R.custid,
    R.orderid,
    R.shipid,
    R.item,
    R.lotnumber,
    nvl(qty,0),
    R.uom,
    condition,
    damagereason,
    line_number,
    origtrackingno,
    serialnumber,
    useritem1,
    useritem2,
    useritem3,
    qtyrcvd_invstatus,
    orig_line_number,
    decode(qtyrcvd_invstatus, 'DM', 0, nvl(qty,0)),
    decode(qtyrcvd_invstatus, 'DM', nvl(qty,0), 0)
,DTLPASSTHRUCHAR01
,DTLPASSTHRUCHAR02
,DTLPASSTHRUCHAR03
,DTLPASSTHRUCHAR04
,DTLPASSTHRUCHAR05
,DTLPASSTHRUCHAR06
,DTLPASSTHRUCHAR07
,DTLPASSTHRUCHAR08
,DTLPASSTHRUCHAR09
,DTLPASSTHRUCHAR10
,DTLPASSTHRUCHAR11
,DTLPASSTHRUCHAR12
,DTLPASSTHRUCHAR13
,DTLPASSTHRUCHAR14
,DTLPASSTHRUCHAR15
,DTLPASSTHRUCHAR16
,DTLPASSTHRUCHAR17
,DTLPASSTHRUCHAR18
,DTLPASSTHRUCHAR19
,DTLPASSTHRUCHAR20
,DTLPASSTHRUNUM01
,DTLPASSTHRUNUM02
,DTLPASSTHRUNUM03
,DTLPASSTHRUNUM04
,DTLPASSTHRUNUM05
,DTLPASSTHRUNUM06
,DTLPASSTHRUNUM07
,DTLPASSTHRUNUM08
,DTLPASSTHRUNUM09
,DTLPASSTHRUNUM10
,DTLPASSTHRUDATE01
,DTLPASSTHRUDATE02
,DTLPASSTHRUDATE03
,DTLPASSTHRUDATE04
,DTLPASSTHRUDOLL01
,DTLPASSTHRUDOLL02
,zci.item_weight(R.custid,R.item,R.uom) * nvl(qty,0)
,'N'
 from orderdtl D, rcptnote944ideex R
where D.orderid = R.orderid
 and D.shipid = R.shipid
 and D.item = R.item
 and nvl(D.lotnumber,'(none)') = nvl(R.lotnumber,'(none)');

comment on table rcpt_note_944_ide is '$Id';

create or replace view rcpt_note_944_lu1
(
   custid,
   orderid,
   shipid,
   item,
   lotnumber,
   uom,
   useritem1,
   qty)
   as
select
   custid,
   orderid,
   shipid,
   item,
   lotnumber,
   uom,
   useritem1,
   sum(nvl(qtyrcvdgood,0) + nvl(qtyrcvddmgd,0))
   from orderdtlrcpt
   group by custid, orderid, shipid, item, lotnumber, uom, useritem1;

comment on table rcpt_note_944_lu1 is '$Id';
create or replace view rcpt_note_944_lip
(
   custid,
   orderid,
   shipid,
   line_number,
   item,
   upc,
   description,
   lotnumber,
   uom,
   qtyrcvd,
   cubercvd,
   qtyrcvdgood,
   cubercvdgood,
   qtyrcvddmgd,
   qtyorder,
   weightitem,
   weight,
   weightqualifier,
   weightunitcode,
   volume,
   uom_volume
,DTLPASSTHRUCHAR01
,DTLPASSTHRUCHAR02
,DTLPASSTHRUCHAR03
,DTLPASSTHRUCHAR04
,DTLPASSTHRUCHAR05
,DTLPASSTHRUCHAR06
,DTLPASSTHRUCHAR07
,DTLPASSTHRUCHAR08
,DTLPASSTHRUCHAR09
,DTLPASSTHRUCHAR10
,DTLPASSTHRUCHAR11
,DTLPASSTHRUCHAR12
,DTLPASSTHRUCHAR13
,DTLPASSTHRUCHAR14
,DTLPASSTHRUCHAR15
,DTLPASSTHRUCHAR16
,DTLPASSTHRUCHAR17
,DTLPASSTHRUCHAR18
,DTLPASSTHRUCHAR19
,DTLPASSTHRUCHAR20
,DTLPASSTHRUNUM01
,DTLPASSTHRUNUM02
,DTLPASSTHRUNUM03
,DTLPASSTHRUNUM04
,DTLPASSTHRUNUM05
,DTLPASSTHRUNUM06
,DTLPASSTHRUNUM07
,DTLPASSTHRUNUM08
,DTLPASSTHRUNUM09
,DTLPASSTHRUNUM10
,DTLPASSTHRUDATE01
,DTLPASSTHRUDATE02
,DTLPASSTHRUDATE03
,DTLPASSTHRUDATE04
,DTLPASSTHRUDOLL01
,DTLPASSTHRUDOLL02
,qtyonhold
,qtyrcvd_invstatus
,serialnumber
,useritem1
,useritem2
,useritem3
,orig_line_number
,unload_date
,condition
,invclass
,manufacturedate
,lpid
,invstatus
,lineseq
,invstatusdesc
,lpidlast6
,expirationdate
)
as
select
    D.custid,
    D.orderid,
    D.shipid,
    nvl(D.dtlpassthruchar06,'000000'),
    D.item,
    U.upc,
    I.descr,
    D.lotnumber,
    D.uom,
    nvl(D.qtyrcvd,0),
    nvl(D.cubercvd,0),
    nvl(D.qtyrcvdgood,0),
    nvl(D.cubercvdgood,0),
    nvl(D.qtyrcvddmgd,0),
    nvl(D.qtyorder,0),
    I.weight,
    I.weight * nvl(D.qtyrcvd,0),
    'N',
    'L',
    cube/1728,
    'CF'
,D.DTLPASSTHRUCHAR01
,D.DTLPASSTHRUCHAR02
,D.DTLPASSTHRUCHAR03
,D.DTLPASSTHRUCHAR04
,D.DTLPASSTHRUCHAR05
,D.DTLPASSTHRUCHAR06
,D.DTLPASSTHRUCHAR07
,D.DTLPASSTHRUCHAR08
,D.DTLPASSTHRUCHAR09
,D.DTLPASSTHRUCHAR10
,D.DTLPASSTHRUCHAR11
,D.DTLPASSTHRUCHAR12
,D.DTLPASSTHRUCHAR13
,D.DTLPASSTHRUCHAR14
,D.DTLPASSTHRUCHAR15
,D.DTLPASSTHRUCHAR16
,D.DTLPASSTHRUCHAR17
,D.DTLPASSTHRUCHAR18
,D.DTLPASSTHRUCHAR19
,D.DTLPASSTHRUCHAR20
,D.DTLPASSTHRUNUM01
,D.DTLPASSTHRUNUM02
,D.DTLPASSTHRUNUM03
,D.DTLPASSTHRUNUM04
,D.DTLPASSTHRUNUM05
,D.DTLPASSTHRUNUM06
,D.DTLPASSTHRUNUM07
,D.DTLPASSTHRUNUM08
,D.DTLPASSTHRUNUM09
,D.DTLPASSTHRUNUM10
,D.DTLPASSTHRUDATE01
,D.DTLPASSTHRUDATE02
,D.DTLPASSTHRUDATE03
,D.DTLPASSTHRUDATE04
,D.DTLPASSTHRUDOLL01
,D.DTLPASSTHRUDOLL02
,nvl(D.qtyship,0)
,'XX'
,d.dtlpassthruchar01
,d.dtlpassthruchar02
,d.dtlpassthruchar03
,d.dtlpassthruchar04
,nvl(d.dtlpassthrunum10,1)
,O.unload_date
,substr(d.dtlpassthruchar02,2)
,D.inventoryclass
,D.DTLPASSTHRUDATE01 -- manufacture date place holder
,D.DTLPASSTHRUCHAR01 -- lpid place holder
,D.invstatus
,0 -- lineseq place holder
,D.DTLPASSTHRUCHAR01 -- invstatusdecr placeholder
,substr(D.DTLPASSTHRUCHAR01,1,6) --lpidlast6 place holder
,null -- expiration date place holder
  from custitemupcview U, custitem I, orderdtl D, rcpt_note_944_hdr O
 where D.orderid = O.orderid
   and D.shipid = O.shipid
   and D.custid = I.custid
   and D.item = I.item
   and D.custid = U.custid(+)
   and D.item = U.item(+);

comment on table rcpt_note_944_lip is '$Id';

create or replace view rcpt_note_944_pal
(
   custid,
   orderid,
   shipid,
   loadno,
   pallettype,
   inpallets,
   outpallets
)
as
select
    custid,
    orderid,
    shipid,
    loadno,
    pallettype,
    inpallets,
    outpallets
  from pallethistory;

comment on table rcpt_note_944_pal is '$Id';

CREATE OR REPLACE VIEW rcpt_note_944_trl
(
    orderid,
    shipid,
    custid,
    loadno,
    hdr_count,
    dtl_count
)
as
select
    orderid,
    shipid,
    custid,
    loadno,
    (select count(1) from rcpt_note_944_hdr),
    (select count(1) from rcpt_note_944_dtl)
 from dual, orderhdr;

CREATE OR REPLACE VIEW rcpt_note_944_bdn
(
   custid,
   orderid,
   shipid,
   item,
   lotnumber,
   link_lotnumber,
   uom,
   invstatus,
   expirationdate,
   manufacturedate,
   qtyrcvd
)
as
select
   o.custid,
   o.orderid,
   o.shipid,
   o.item,
   o.lotnumber,
   nvl(o.lotnumber,'(none)'),
   o.uom,
   o.invstatus,
   nvl(p.EXPIRATIONDATE, dp.expirationdate),
   nvl(p.MANUFACTUREDATE,dp.manufacturedate),
   sum(o.qtyrcvd)
   from orderdtlrcpt o, plate p, deletedplate dp
   where o.lpid = p.lpid(+)
     and o.lpid = dp.lpid(+)
   group by o.custid, o.orderid, o.shipid, o.item, o.lotnumber, o.uom, o.invstatus,
            nvl(p.EXPIRATIONDATE, dp.expirationdate),nvl(p.MANUFACTUREDATE,dp.manufacturedate);

CREATE OR REPLACE VIEW rcpt_note_944_ltrl
(
    orderid,
    shipid,
    custid,
    loadno,
    lip_count,
    weight,
    qtyrcvd
)
as
select
    orderid,
    shipid,
    custid,
    loadno,
    (select count(1) from rcpt_note_944_lip),
    (select sum(weightitem) from rcpt_note_944_lip),
    (select sum(qtyrcvd) from rcpt_note_944_lip)
 from dual, orderhdr;

CREATE OR REPLACE VIEW rcpt_note_944_ihr
(
    partneredicode,
    datetimecreated,
    custid,
    senderedicode,
    applicationsendercode
)
as
select
    null,
    null,
    custid,
    null,
    null
  from customer;

CREATE OR REPLACE VIEW rcpt_note_944_fac
(
   facility
)
as
select
   distinct facility
  from rcpt_note_944_hdr;

CREATE OR REPLACE VIEW rcpt_note_944_mbr
(
   facility,
   supplier,
   bill_of_lading,
   receipt_date,
   orderid,
   lotnumber,
   lpid,
   item,
   weight,
   qtyrcvd,
   useritem1,
   useritem2,
   useritem3
)
as
select
    h.facility,
    h.supplier,
    h.bill_of_lading,
    h.receipt_date,
    h.orderid,
    l.lotnumber,
    l.lpid,
    l.item,
    l.weight,
    l.qtyrcvd,
    l.useritem1,
    l.useritem2,
    l.useritem3
  from rcpt_note_944_hdr h,
       rcpt_note_944_lip l
  where l.orderid = h.orderid
    and l.shipid = h.shipid;

CREATE OR REPLACE VIEW rcpt_note_944_cfs 
(custid, orderid, shipid, loadno, 
 facility, item, lotnumber, arrivaldate, 
 unload_date, qtyrcvd, uom, 
 opltpallettqty, spltpallettqty, hdrpassthruchar01, 
 qtyrcvd_exceptions, invstatus_exceptions, 
 overdim, hazardous, dtlpassthruchar01, whseloc, dtlpassthruchar08, totalweight
)
AS
  SELECT custid,
    orderid,
    shipid,
    loadno,
    facility,
    item,
    lotnumber,
    arrivaldate,
    unload_date,
    SUM(NVL(qtyrcvd,0)),
    uom,
    opltpallettqty,
    spltpallettqty,
    hdrpassthruchar01,
    SUM(NVL(qtyrcvd_exceptions,0)),
    invstatus_exceptions,
    overdim,
    hazardous,
    dtlpassthruchar01,
    whseloc,
    dtlpassthruchar08,
    totalweight
  FROM
    (SELECT oh.custid CUSTID ,
      oh.orderid ORDERID ,
      oh.shipid SHIPID,
      oh.loadno LOADNO,
      oh.facility FACILITY,
      od.item ITEM,
      od.lotnumber LOTNUMBER,
      (select to_char(rcvddate,'DD-MON-YYYY HH:MI:SS AM')
        from loads where loadno =
                 (select nvl(loadno,0)
                          from orderhdr
                   where orderid=oh.orderid and shipid=oh.shipid)
      ) ARRIVALDATE,
      (select min(to_char(end_time,'DD-MON-YYYY HH:MI:SS AM'))
         from laboractivityview
        where custid = oh.custid
          and facility = oh.facility
          and event = 'MTTR'
          and substr(other_data,8) = to_char(oh.loadno)
      )UNLOAD_DATE,
      od.qtyrcvd QTYRCVD,
      od.uom UOM,
      zim7.pallet_count_by_type(oh.loadno,oh.custid,oh.facility,oh.orderid,oh.shipid, 'R','OPLT') OPLTPALLETTQTY,
      zim7.pallet_count_by_type(oh.loadno,oh.custid,oh.facility,oh.orderid,oh.shipid, 'R','SPLT') SPLTPALLETTQTY,
      oh.hdrpassthruchar01 HDRPASSTHRUCHAR01,
      NULL QTYRCVD_EXCEPTIONS,
      NULL INVSTATUS_EXCEPTIONS,
      NULL OVERDIM,
      (SELECT hazardous FROM custitem WHERE custid=oh.custid AND item=od.item
      ) HAZARDOUS,
      od.dtlpassthruchar01 DTLPASSTHRUCHAR01,
      NULL WHSELOC,
      od.dtlpassthruchar08 DTLPASSTHRUCHAR08,
      od.weightitem * od.qtyrcvd TOTALWEIGHT
    FROM rcpt_note_944_hdr oh,
      rcpt_note_944_dtl od
    WHERE oh.orderid = od.orderid
    AND oh.shipid    = od.shipid
    )
  GROUP BY custid,
    orderid,
    shipid,
    loadno,
    facility,
    item,
    lotnumber,
    arrivaldate,
    unload_date,
    uom,
    opltpallettqty,
    spltpallettqty,
    hdrpassthruchar01,
    invstatus_exceptions,
    overdim,
    hazardous,
    dtlpassthruchar01,
    whseloc,
    dtlpassthruchar08,
    totalweight
  UNION
  SELECT custid,
    orderid,
    shipid,
    loadno,
    facility,
    item,
    lotnumber,
    arrivaldate,
    unload_date,
    SUM(NVL(qtyrcvd,0)),
    uom,
    opltpallettqty,
    spltpallettqty,
    hdrpassthruchar01,
    SUM(NVL(qtyrcvd_exceptions,0)),
    invstatus_exceptions,
    overdim,
    hazardous,
    dtlpassthruchar01,
    whseloc,
    dtlpassthruchar08,
    totalweight
  FROM
    (SELECT oh.custid CUSTID,
      oh.orderid ORDERID,
      oh.shipid SHIPID,
      oh.loadno LOADNO,
      oh.facility FACILITY,
      od.item ITEM,
      od.lotnumber LOTNUMBER,
      (select to_char(rcvddate,'DD-MON-YYYY HH:MI:SS AM')
        from loads where loadno =
                 (select nvl(loadno,0)
                          from orderhdr
                   where orderid=oh.orderid and shipid=oh.shipid)
      ) ARRIVALDATE,
      (select min(to_char(end_time,'DD-MON-YYYY HH:MI:SS AM'))
         from laboractivityview
        where custid = oh.custid
          and facility = oh.facility
          and event = 'MTTR'
          and substr(other_data,8) = to_char(oh.loadno)
      )UNLOAD_DATE,
      NULL QTYRCVD,
      od.uom UOM,
      zim7.pallet_count_by_type(oh.loadno,oh.custid,oh.facility,oh.orderid,oh.shipid, 'R', 'OPLT') OPLTPALLETTQTY,
      zim7.pallet_count_by_type(oh.loadno,oh.custid,oh.facility,oh.orderid,oh.shipid, 'R', 'SPLT') SPLTPALLETTQTY,
      oh.hdrpassthruchar01 HDRPASSTHRUCHAR01,
      oc.qtyrcvd QTYRCVD_EXCEPTIONS,
      oc.invstatus INVSTATUS_EXCEPTIONS,
      NULL OVERDIM,
      (SELECT hazardous FROM custitem WHERE custid=oh.custid AND item=od.item
      ) AS HAZARDOUS,
      od.dtlpassthruchar01 DTLPASSTHRUCHAR01,
      NULL WHSELOC,
      od.dtlpassthruchar08 DTLPASSTHRUCHAR08,
      od.weightitem * od.qtyrcvd TOTALWEIGHT
    FROM rcpt_note_944_hdr oh,
      rcpt_note_944_dtl od,
      orderdtlrcpt oc
    WHERE oh.orderid              = od.orderid
    AND oh.shipid                 = od.shipid
    AND oh.orderid                = oc.orderid
    AND oh.shipid                 = oc.shipid
    AND od.item                   = oc.item
    AND NVL(od.lotnumber, 'none') = NVL(oc.lotnumber,'none')
    AND oc.invstatus             != 'AV'
    AND rownum                    < 5
    )
  GROUP BY custid,
    orderid,
    shipid,
    loadno,
    facility,
    item,
    lotnumber,
    arrivaldate,
    unload_date,
    uom,
    opltpallettqty,
    spltpallettqty,
    hdrpassthruchar01,
    invstatus_exceptions,
    overdim,
    hazardous,
    dtlpassthruchar01,
    whseloc,
    dtlpassthruchar08,
    totalweight;
exit;
