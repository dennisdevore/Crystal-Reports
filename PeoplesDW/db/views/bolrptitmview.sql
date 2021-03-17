create or replace view bolrptitm
(
       orderid, 
       shipid, 
       custid,
       item, 
       lotnumber, 
       qtyship, 
       weightship
)
as 
select 
       OD.orderid, 
       OD.shipid,
       OD.custid,
       OD.item, 
       decode(CI.lotsumbol,'Y',null,OD.lotnumber), 
       sum(OD.qtyship), 
       sum(OD.weightship)
from
    custitem CI,
    orderdtl OD
where
    OD.custid = CI.custid and
    OD.item = CI.item
group by
       OD.orderid, 
       OD.shipid,
       OD.custid, 
       OD.item, 
       decode(CI.lotsumbol,'Y',null,OD.lotnumber);

comment on table bolrptitm is '$Id$';

exit;

