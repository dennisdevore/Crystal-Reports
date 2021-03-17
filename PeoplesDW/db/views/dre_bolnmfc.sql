CREATE OR REPLACE VIEW DRE_BOLNMFC
(ORDERID, SHIPID, NMFC, DESCR, CLASS, 
 QTY, WEIGHT, CUBE, SP_QTY, SP_WEIGHT, 
 GROSSWEIGHT, CUBE_SHIP, SP_CUBE)
AS 
select OD.orderid,
  OD.shipid,
  CI.nmfc,
  nvl(N.descr,'NO NMFC DESCRIPTION'),
  N.class,
  sum(OD.qtyorder),
  sum(OD.weightorder),
  sum(OD.cubeorder),
  sum(sp.quantity), 
  sum(SP.weight - (zlbl.uom_qty_conv(od.custid,sp.item,SP.quantity,od.uom,ci.baseuom) * decode(ci.catch_weight_out_cap_type, 'N', nvl(ci.tareweight,0), 0))),
  sum(sp.weight),
  sum(od.cubeship),
  sum(sp.quantity * od.cubeship / od.qtyship)
  from nmfclasscodes N, custitemview CI, orderdtl OD, shippingplate SP
  where OD.custid = CI.custid(+)
  and OD.item   = CI.item(+)
  and CI.nmfc = N.nmfc (+)
  and sp.item = ci.item
  and od.orderid = sp.orderid
  and od.shipid = sp.shipid
  and od.item = sp.orderitem
  and sp.type in ('F','P')
  and nvl(od.lotnumber,'(none)') = nvl(sp.orderlot,'(none)')
  group by OD.orderid, OD.shipid, CI.nmfc, nvl(N.descr,'NO NMFC DESCRIPTION'), N.class;

comment on table DRE_BOLNMFC is '$Id$';

exit;
