create or replace view bolrpthazard
(
       orderid,
       shipid,
       hazardous
)
as
select distinct OD.orderid,
       OD.shipid,
       CI.hazardous
from
    custitem CI,
    orderdtl OD
where
    OD.custid = CI.custid and
    OD.item = CI.item and
    CI.hazardous <> 'N';
    
comment on table bolrpthazard is '$Id: bolrpthazardview.sql 381 2007-05-03 00:00:00Z eric $';        

exit;

