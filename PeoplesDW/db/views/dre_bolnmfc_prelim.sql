
CREATE OR REPLACE VIEW DRE_BOLNMFC_PRELIM ( ORDERID, 
SHIPID, NMFC, DESCR, CLASS, 
QTY, WEIGHT, CUBE, GROSSWEIGHT ) AS select OD.orderid,
OD.shipid,
CI.nmfc,
nvl(N.descr,'NO NMFC DESCRIPTION'),
N.class,
OD.qty,
OD.wght,
OD.cube,
OD.grossweight
from nmfclasscodes N, custitem CI, DRE_AGGRPICKLISTVIEW2 OD, orderhdr OH
where OD.orderid = OH.orderid  
and	  OD.shipid  = OH.shipid  
and	  OH.custid = CI.custid 
and OD.item   = CI.item(+)
and CI.nmfc = N.nmfc (+);

comment on table DRE_BOLNMFC_PRELIM is '$Id';

exit;
