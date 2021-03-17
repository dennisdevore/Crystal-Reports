create or replace view orderdtlseqcntview
(
    orderid,
    shipid,
    item,
    lotnumber,
    seqqty
)
as
select D.orderid, D.shipid, D.item, D.lotnumber, sum(S.qtypick) - D.qtypick  
from orderdtl S, orderdtl D 
where D.orderid = S.orderid
and D.shipid = S.shipid
and S.item || nvl(S.lotnumber,'<NULL>') <= D.item ||nvl(D.lotnumber,'<NULL>')
group by D.orderid, D.shipid, D.item, D.lotnumber, D.qtypick;

comment on table orderdtlseqcntview is '$Id';


create or replace view orderdtlseqview(
     orderid,
     shipid,
     custid,
     item,
     lotnumber,
     consigneesku, 
     dtlpassthruchar09,
     seq,
     seqof,
     bigseqof,
     bigseq
)
as
select C.orderid,
       C.shipid,
       D.custid,
       D.item,
       D.lotnumber,
       D.consigneesku,
       D.dtlpassthruchar09,
       seq,
       D.qtypick,
       H.qtypick,
       seq + C.seqqty
 from orderdtlseqcntview C, zseq Z, orderdtl D, orderhdr H
where D.orderid = H.orderid
  and D.shipid = H.shipid
  and D.orderid = C.orderid
  and D.shipid = C.shipid
  and D.item = C.item
  and nvl(D.lotnumber,'<NULL>') = nvl(C.lotnumber,'<NULL>')
  and Z.seq <= D.qtypick;

comment on table orderdtlseqview is '$Id';


-- exit;
