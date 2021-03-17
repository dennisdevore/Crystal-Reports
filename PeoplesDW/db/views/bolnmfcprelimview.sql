
CREATE OR REPLACE VIEW BOLNMFC_PRELIM ( ORDERID, 
SHIPID, NMFC, DESCR, CLASS, 
QTY, WEIGHT, CUBE, GROSS, FULL_RPT_PATH ) AS select OD.orderid,  
OD.shipid,  
CI.nmfc,  
nvl(N.descr,'NO NMFC DESCRIPTION'),  
N.class,  
sum(OD.qtyorder),  
sum(OD.weightorder),  
sum(OD.cubeorder),
sum(OD.weightorder + (OD.qtyorder * CI.tareweight)),
zcustomer.bol_rpt_fullpath(OD.orderid, OD.shipid) full_rpt_path
from nmfclasscodes N, custitem CI, orderdtl OD  
where OD.custid = CI.custid(+)  
and OD.item   = CI.item(+)  
and CI.nmfc = N.nmfc (+)  
group by OD.orderid, OD.shipid, CI.nmfc, nvl(N.descr,'NO NMFC DESCRIPTION'), N.class;

comment on table BOLNMFC_PRELIM is '$Id$';

exit;
