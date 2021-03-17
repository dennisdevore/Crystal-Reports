create or replace view bolnmfc
(
   loadno,
   orderid,
   shipid,
   nmfc,
   descr,
   qty,
   weight,
   class,
   cube,
   gross,
   qtypick,
   weightpick,
   cubepick,
   caseqty,
   full_rpt_path
)
as
select OH.loadno,
       OH.orderid,
       OH.shipid,
       CI.nmfc,
       nvl(N.descr,'NO NMFC DESCRIPTION'),
       sum(OD.qtyship),
       sum(OD.weightship),
       N.class,	
       sum(OD.cubeship),
       sum(OD.weightship + (OD.qtyship * CI.tareweight)),
       sum(OD.qtypick),
       sum(OD.weightpick),	
       sum(OD.cubepick),
       sum(zbut.translate_uom_function
            (OD.custid,OD.item,nvl(OD.qtyship,0),OD.uom,'CS')),
       zcustomer.bol_rpt_fullpath(OH.orderid, OH.shipid) full_rpt_path
  from orderhdr OH, nmfclasscodes N, custitem CI, orderdtl OD
 where OH.orderid = OD.orderid
   and OH.shipid = OD.shipid
   and OH.ordertype <> 'F'
   and OD.custid = CI.custid(+)
   and OD.item   = CI.item(+)
   and CI.nmfc = N.nmfc (+)
  group by OH.loadno, OH.orderid, OH.shipid, OD.orderid, OD.shipid, CI.nmfc, nvl(N.descr,'NO NMFC DESCRIPTION'),N.class
union
select OH.loadno,
       OH.orderid,
       OH.shipid,
       N.nmfc,
       nvl(N.descr,'NO NMFC DESCRIPTION'),
       sum(OD.qtyship),
       sum(OD.weightship),
       N.class,    
       0,
       sum(OD.weightship),
       sum(OD.qtypick),
       sum(OD.weightpick),	
       0,
       0,
       zcustomer.bol_rpt_fullpath(OH.orderid, OH.shipid) full_rpt_path
  from orderhdr OH, nmfclasscodes N, orderdtl OD
 where OH.orderid = OD.orderid
   and OH.shipid = OD.shipid
   and OH.ordertype = 'F'
   and OD.item = N.nmfc (+)
  group by OH.loadno, OH.orderid, OH.shipid, N.nmfc, nvl(N.descr,'NO NMFC DESCRIPTION'),N.class;

comment on table bolnmfc is '$Id$';

create or replace view bolnmfc_shipto
(
   loadno,
   shiptoname,
   shiptoaddr1,
   custid,
   shipto_order_count,
   nmfc,
   descr,
   qty,
   weight,
   class,
   cube,
   gross,
   caseqty,
   full_rpt_path
)
as
select OH.loadno,
       decode(OH.shiptoname,null,CNS.name,OH.shiptoname),
       decode(OH.shiptoname,null,CNS.addr1, OH.shiptoaddr1),
       OH.custid,
       min((select count(1)
              from orderhdr
             where loadno=OH.loadno
               and custid=OH.custid
               and ((shipto=OH.shipto)
                or  (shiptoname=OH.shiptoname
               and   shiptoaddr1=OH.shiptoaddr1)))) shipto_order_count,
       CI.nmfc,
       nvl(N.descr,'NO NMFC DESCRIPTION'),
       sum(OD.qtyship),
       sum(OD.weightship),
       N.class,	
       sum(OD.cubeship),
       sum(OD.weightship + (OD.qtyship * CI.tareweight)),
       sum(zbut.translate_uom_function
            (OD.custid,OD.item,nvl(OD.qtyship,0),OD.uom,'CS')),
       zcustomer.bol_rpt_fullpath(OH.orderid, OH.shipid) full_rpt_path
  from orderhdr OH, orderdtl OD, consignee CNS, nmfclasscodes N, custitem CI
 where OH.orderid = OD.orderid
   and OH.shipid = OD.shipid
   and OH.shipto = CNS.consignee(+)
   and OD.custid = CI.custid(+)
   and OD.item   = CI.item(+)
   and CI.nmfc = N.nmfc (+)
   and OH.ordertype <> 'F'
  group by OH.loadno,
       decode(OH.shiptoname,null,CNS.name,OH.shiptoname),
       decode(OH.shiptoname,null,CNS.addr1, OH.shiptoaddr1),
       OH.custid,
       CI.nmfc,
       nvl(N.descr,'NO NMFC DESCRIPTION'),
       N.class,
       zcustomer.bol_rpt_fullpath(OH.orderid, OH.shipid)
union
select OH.loadno,
       decode(OH.shiptoname,null,CNS.name,OH.shiptoname),
       decode(OH.shiptoname,null,CNS.addr1, OH.shiptoaddr1),
       OH.custid,
       min((select count(1)
              from orderhdr
             where loadno=OH.loadno
               and custid=OH.custid
               and ((shipto=OH.shipto)
                or  (shiptoname=OH.shiptoname
               and   shiptoaddr1=OH.shiptoaddr1)))) shipto_order_count,
       N.nmfc,
       nvl(N.descr,'NO NMFC DESCRIPTION'),
       sum(OD.qtyship),
       sum(OD.weightship),
       N.class,	
       0,
       sum(OD.weightship),
       0,
       zcustomer.bol_rpt_fullpath(OH.orderid, OH.shipid) full_rpt_path
  from orderhdr OH, orderdtl OD, consignee CNS, nmfclasscodes N, custitem CI
 where OH.orderid = OD.orderid
   and OH.shipid = OD.shipid
   and OH.shipto = CNS.consignee(+)
   and OH.ordertype = 'F'
   and OD.custid = CI.custid(+)
   and OD.item = N.nmfc (+)
  group by OH.loadno,
       decode(OH.shiptoname,null,CNS.name,OH.shiptoname),
       decode(OH.shiptoname,null,CNS.addr1, OH.shiptoaddr1),
       OH.custid,
       N.nmfc,
       nvl(N.descr,'NO NMFC DESCRIPTION'),
       N.class,
       zcustomer.bol_rpt_fullpath(OH.orderid, OH.shipid);

comment on table bolnmfc_shipto is '$Id$';

exit;

