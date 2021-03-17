
CREATE OR REPLACE VIEW BAR_BOLNMFC_PRELIM ( ORDERID, 
SHIPID, NMFC, DESCR, CLASS, 
QTY, WEIGHT, CUBE ) AS select OD.orderid,  
OD.shipid,  
CI.nmfc,  
nvl(N.descr,'NO NMFC DESCRIPTION'),  
N.class,  
sum(nvl(OD.qtycommit,0) + nvl(OD.qtypick,0)),  
sum(nvl(OD.weightcommit,0) + nvl(OD.weightpick,0)),  
sum(nvl(OD.cubecommit,0) + nvl(od.cubepick,0))  
from nmfclasscodes N, custitem CI, orderdtl OD  
where OD.custid = CI.custid(+)  
and OD.item   = CI.item(+)  
and CI.nmfc = N.nmfc (+)  
group by OD.orderid, OD.shipid, CI.nmfc, nvl(N.descr,'NO NMFC DESCRIPTION'), N.class;

comment on table BAR_BOLNMFC_PRELIM is '$Id$';

exit;
