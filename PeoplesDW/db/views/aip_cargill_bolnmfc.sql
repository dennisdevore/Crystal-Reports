CREATE OR REPLACE VIEW AIP_CARGILL_BOLNMFC ( ORDERID,  
SHIPID, NMFC, DESCR, QTY, WEIGHT, GROSSWEIGHT ) AS select OD.orderid,
       OD.shipid,
       CI.nmfc,
       nvl(N.descr,'NO NMFC DESCRIPTION'),
       sum(OD.qtyship),
       sum(OD.weightship),
	   OD.weightship + (zlbl.uom_qty_conv(od.custid,od.item,od.qtyship,od.uom,ci.baseuom) * nvl(ci.tareweight,0))
  from nationalmotorfreightclass N, custitem CI, orderdtl OD
 where OD.custid = CI.custid(+)
   and OD.item   = CI.item(+)
   and CI.nmfc = N.code (+)
  group by OD.orderid, OD.shipid, CI.nmfc, nvl(N.descr,'NO NMFC DESCRIPTION'),
  		OD.weightship + (zlbl.uom_qty_conv(od.custid,od.item,od.qtyship,od.uom,ci.baseuom) * nvl(ci.tareweight,0));

comment on table AIP_CARGILL_BOLNMFC is '$Id$';

exit;
