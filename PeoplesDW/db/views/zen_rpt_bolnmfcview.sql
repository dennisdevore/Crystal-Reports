create or replace view zen_rpt_bolnmfc
(
   orderid,
   shipid,
   nmfc,
   descr,
   qty,
   uom,
   weight,
   class,
   cube,
   baseqty,
   baseuom
)
as
select OD.orderid,
       OD.shipid,
       CI.nmfc,
       nvl(N.descr,'NO NMFC DESCRIPTION'),
       sum(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,OD.uomentered)),
       OD.uomentered,
       sum(OD.weightship),
       N.class,	
       sum(OD.cubeship),
       sum(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,CI.baseuom)),
       CI.baseuom
  from nmfclasscodes N, custitem CI, orderdtl OD
 where OD.custid = CI.custid(+)
   and OD.item   = CI.item(+)
   and CI.nmfc = N.nmfc (+)
   and OD.qtyship is not null
  group by OD.orderid, OD.shipid, CI.nmfc, nvl(N.descr,'NO NMFC DESCRIPTION'),OD.uomentered,N.class,CI.baseuom;

comment on table zen_rpt_bolnmfc is '$Id$';

 exit;

