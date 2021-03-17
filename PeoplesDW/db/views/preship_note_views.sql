create or replace view preship_note_hdr
as
select orderid,
    shipid,
    O.loadno,
    reference,
    orderstatus,
    O.statusupdate,
    shiptoname,
    shiptoaddr1,
    shiptoaddr2,
    shiptocity,
    shiptostate,
    shiptopostalcode,
    shiptocountrycode,
    shiptocontact,
    shiptophone,
    shiptoemail,
    nvl(substr(zoe.max_trackingno(orderid,shipid),1,30),nvl(O.prono,L.prono))
            prono_or_trackingno,
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
    hdrpassthrudate01,
    hdrpassthrudate02,
    hdrpassthrudate03,
    hdrpassthrudate04,
    hdrpassthrudoll01,
    hdrpassthrudoll02
from loads L, orderhdr O
where ordertype = 'O'
 and orderstatus !='X'
 and O.loadno = L.loadno(+);

comment on table preship_note_hdr is '$Id$';

create or replace view preship_note_dtl
as
select
    orderid,
    shipid,
    item,
    sum(quantity) quantity
  from shippingplate
where type in ('F','P')
group by orderid, shipid, item;

comment on table preship_note_dtl is '$Id$';

exit;
