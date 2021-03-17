create or replace function barrett_tot_order_cs
(
	in_orderid in number,
   in_shipid  in number
)
return number
is
--
-- $Id$
--
	tot number := 0;
begin
   for sh in (select custid, item, unitofmeasure, sum(quantity) as qty
               from shippingplate
               where orderid = in_orderid
                 and shipid = in_shipid
                 and type in ('F', 'P')
               group by custid, item, unitofmeasure) loop
      tot := tot + zlbl.uom_qty_conv(sh.custid, sh.item, sh.qty, sh.unitofmeasure, 'CS');
   end loop;

   return tot;
end barrett_tot_order_cs;
/


create or replace function barrett_tot_item_cs
(
	in_orderid in number,
   in_shipid  in number,
   in_item    in varchar2
)
return number
is
--
-- $Id$
--
	tot number := 0;
begin
   for sh in (select custid, unitofmeasure, sum(quantity) as qty
               from shippingplate
               where orderid = in_orderid
                 and shipid = in_shipid
                 and item = in_item
                 and type in ('F', 'P')
               group by custid, item, unitofmeasure) loop
      tot := tot + zlbl.uom_qty_conv(sh.custid, in_item, sh.qty, sh.unitofmeasure, 'CS');
   end loop;

   return tot;
end barrett_tot_item_cs;
/


create or replace view barrett_leap_year_lbl_view
(
   orderid,
   shipid,
   item,
   alias,
   sku,
   descr,
   ea_in_case,
   weight,
   length,
   width,
   height,
   po,
   toaddr1,
   toaddr2,
   tocity,
   tostate,
   tozip,
   tocountry,
   ctncount,
   totcartons,
   fromaddr1,
   fromaddr2,
   fromcity,
   fromstate,
   fromzip,
   itempassthruchar01,
   itempassthruchar02,
   itempassthruchar03,
   itempassthruchar04,
   itempassthrunum01,
   itempassthrunum02,
   itempassthrunum03,
   itempassthrunum04,
   hdrpassthruchar01,
   hdrpassthruchar02,
   hdrpassthruchar03,
   hdrpassthruchar04,
   hdrpassthruchar05,
   hdrpassthrunum01,
   hdrpassthrunum02,
   hdrpassthrunum03,
   hdrpassthrunum04,
   hdrpassthrunum05
)
as
select
   OD.orderid,
   OD.shipid,
   OD.item,
   CA.itemalias,
   OD.consigneesku,
   CI.descr,
   zlbl.uom_qty_conv(OD.custid, OD.item, 1, 'CS', OD.uom),
   zci.item_weight(OD.custid, OD.item, 'CS'),
   zci.item_uom_length(OD.custid, OD.item, 'CS'),
   zci.item_uom_width(OD.custid, OD.item, 'CS'),
   zci.item_uom_height(OD.custid, OD.item, 'CS'),
   OH.po,
   OH.shiptoaddr1,
   OH.shiptoaddr2,
   OH.shiptocity,
   OH.shiptostate,
   OH.shiptopostalcode,
   OH.shiptocountrycode,
   row_number() over (partition by OD.orderid order by OD.orderid),
   barrett_tot_order_cs(OD.orderid, OD.shipid),
   FA.addr1,
   FA.addr2,
   FA.city,
   FA.state,
   FA.postalcode,
   CI.itmpassthruchar01,
   CI.itmpassthruchar02,
   CI.itmpassthruchar03,
   CI.itmpassthruchar04,
   CI.itmpassthrunum01,
   CI.itmpassthrunum02,
   CI.itmpassthrunum03,
   CI.itmpassthrunum04,
   OH.hdrpassthruchar01,
   OH.hdrpassthruchar02,
   OH.hdrpassthruchar03,
   OH.hdrpassthruchar04,
   OH.hdrpassthruchar05,
   OH.hdrpassthrunum01,
   OH.hdrpassthrunum02,
   OH.hdrpassthrunum03,
   OH.hdrpassthrunum04,
   OH.hdrpassthrunum05
from orderdtl OD,
     zseq ZS,
     orderhdr OH,
     custitemalias CA,
     custitem CI,
     facility FA
where OD.orderid = OH.orderid
  and OD.shipid = OH.shipid
  and ZS.seq <= barrett_tot_item_cs(OD.orderid, OD.shipid, OD.item)
  and OD.custid = CA.custid (+)
  and OD.item = CA.item (+)
  and OD.custid = CI.custid (+)
  and OD.item = CI.item (+)
  and OH.fromfacility = FA.facility (+)
  and not exists (select * from shippingplate where orderid = OH.orderid
	  and shipid = OH.shipid and status in ('U', 'P'));

comment on table barrett_leap_year_lbl_view is '$Id$';

exit;
