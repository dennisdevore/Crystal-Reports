CREATE OR REPLACE VIEW DRE_BOLNMFC_PRELIM_NOPREORDER
(ORDERID, SHIPID, NMFC, DESCR, CLASS, 
 QTY, WEIGHT, CUBE, SP_QTY, SP_WEIGHT, 
 GROSSWEIGHT, SP_CUBE)
AS 
select OD.orderid,     
OD.shipid,     
CI.nmfc,     
nvl(N.descr,'NO NMFC DESCRIPTION'),     
N.class,     
sum(OD.qty),     
sum(OD.wght),     
sum(OD.cube),    
sum(OD.qty),  --SP_QTY    
sum(OD.wght), --SP_WEIGHT   
sum(OD.grossweight),       
--CUBE_SHIP removed    
sum(OD.cube) --SP_CUBE     
from nmfclasscodes N, custitem CI, DRE_AGGRPICKLISTVIEW OD, orderhdr OH     
where OD.orderid = OH.orderid     
and	  OD.shipid  = OH.shipid     
and	  OH.custid = CI.custid     
and OD.item   = CI.item(+)     
and CI.nmfc = N.nmfc (+)    
and od.shipplatetype <> 'Master Pallet'  
and OD.qty is not null   
and OD.cube is not null   
group by OD.orderid, OD.shipid, CI.nmfc, nvl(N.descr,'NO NMFC DESCRIPTION'), N.class;
comment on table DRE_BOLNMFC_PRELIM_NOPREORDER is '$Id: dre_bolnmfc_prelim_nopreorder.sql 86 2005-12-29 00:00:00Z eric $';
exit;
