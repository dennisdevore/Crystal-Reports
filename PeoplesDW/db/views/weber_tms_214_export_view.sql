CREATE OR REPLACE VIEW WEBER_TMS_214_EXPORT_VIEW
(
   LOADNO,
   STOPNO,
   SHIPNO,
   ORDERID,
   SHIPID,
   ORDERID_SHIPID,
   CUSTID,
   FACILITY,
   TMS_SHIPMENT_ID,
   CARRIER,
   ORIGIN_ALIAS,
   ORIGIN_NAME,
   ORIGIN_ADDRESS1,
   ORIGIN_ADDRESS2,
   ORIGIN_CITY,
   ORIGIN_STATE,
   ORIGIN_POSTALCODE,
   ORIGIN_COUNTRYCODE,
   DEST_ALIAS,
   DEST_NAME,
   DEST_ADDRESS1,
   DEST_ADDRESS2,
   DEST_CITY,
   DEST_STATE,
   DEST_POSTALCODE,
   DEST_COUNTRYCODE,
   ORDER_WEIGHT,
   ORDER_PALLETS,
   ORDER_VOLUME
)
AS
     SELECT /*+ index(orderhdr orderhdr_recent_order_id_idx) */
            oh.loadno,
            oh.stopno,
            oh.shipno,
            oh.orderid,
            oh.shipid,
            oh.orderid || '-' || oh.shipid,
            oh.custid,
            oh.fromfacility,
            oh.tms_shipment_id,
            oh.carrier,
            tms.facility origin_alias,
            tms.shipper origin_name,
            tms.ship_add1 origin_address1,
            tms.ship_add2 origin_address2,
            tms.ship_city origin_city,
            tms.ship_state origin_state,
            tms.ship_zip origin_postalcode,
            'USA' origin_countrycode,
            c.consignee dest_alias,
            c.name dest_name,
            c.addr1 dest_address1,
            c.addr2 dest_address2,
            c.city dest_city,
            c.state dest_state,
            c.postalcode dest_postalcode,
            'USA' dest_countrycode,
            tms.wt order_weight,
            tms.outpallets order_pallets,
            tms.cube order_volume
       FROM alps.orderhdr oh
       		join links.weber_tms_mg_view tms on (
            		oh.orderid = tms.orderid
            	and oh.shipid = tms.shipid)
            left join alps.loadstop ls on (
            		oh.loadno = ls.loadno
            	and oh.stopno = ls.stopno)
            left join alps.consignee c on (
            		nvl(ls.shipto,tms.cons_num) = c.consignee)
      WHERE oh.recent_order_id like 'Y%'
        and nvl(oh.tms_carrier_optimized_yn,'X') = 'Y'
        AND tms.loadno IS NOT NULL
union all
     select /*+ index(orderhdr orderhdr_recent_order_id_idx) */
            oh.loadno,
            oh.stopno,
            oh.shipno,
            oh.orderid,
            oh.shipid,
            oh.orderid || '-' || oh.shipid,
            oh.custid,
            oh.tofacility,
            oh.tms_shipment_id,
            oh.carrier,
            oh.shipper origin_alias,
            nvl(oh.shippername,cs.name) origin_name,
            decode(oh.shippername,null,cs.addr1,oh.shipperaddr1) origin_address1,
            decode(oh.shippername,null,cs.addr2,oh.shipperaddr2) origin_address2,
            decode(oh.shippername,null,cs.city,oh.shippercity) origin_city,
            decode(oh.shippername,null,cs.state,oh.shipperstate) origin_state,
            decode(oh.shippername,null,cs.postalcode,oh.shipperpostalcode) origin_postalcode,
            'USA' origin_countrycode,
            oh.tofacility dest_alias,
            cu.name dest_name,
            fa.addr1 dest_address1,
            fa.addr2 dest_address2,
            fa.city dest_city,
            fa.state dest_state,
            fa.postalcode dest_postalcode,
            'USA' dest_countrycode,
            tms.weightorder order_weight,
            tms.cs_qtyorder order_pallets,
            oh.cubeorder order_volume
       FROM alps.orderhdr oh,
            links.weber_tms_container_import tms,
            alps.facility fa,
            alps.customer cu,
            alps.consignee cs,
            alps.consignee cb
      WHERE oh.recent_order_id like 'Y%'
        and nvl(oh.tms_carrier_optimized_yn,'X') = 'Y'
        and tms.orderid = oh.orderid
        and tms.shipid = oh.shipid
        and fa.facility = oh.tofacility
        and cu.custid = oh.custid
        and oh.shipper = cs.consignee(+)
        and oh.consignee = cb.consignee(+);
