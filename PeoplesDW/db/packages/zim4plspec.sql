--
-- $id: zimportproc4pl.sql 6829 2011-06-22 11:27:02z brianb $
--
create or replace package alps.zimportproc4pl

is

procedure import_4pl_945_header
(in_importfileid in varchar2
,in_custid in varchar2
,in_reference in varchar2
,in_orderid in number
,in_shipid in number
,in_company in varchar2
,in_warehouse in varchar2
,in_loadno in number
,in_trackingno in varchar2
,in_dateshipped in date
,in_commitdate in date
,in_shipviacode in varchar2
,in_lbs in number
,in_kgs in number
,in_gms in number
,in_ozs in number
,in_shipticket in varchar2
,in_height in number
,in_width in number
,in_length in number
,in_shiptoidcode in varchar2
,in_shiptoname in varchar2
,in_shiptocontact in varchar2
,in_shiptoaddr1 in varchar2
,in_shiptoaddr2 in varchar2
,in_shiptocity in varchar2
,in_shiptostate in varchar2
,in_shiptopostalcode in varchar2
,in_shiptocountrycode in varchar2
,in_shiptophone in varchar2
,in_billtoidcode in varchar2
,in_billtoname in varchar2
,in_billtocontact in varchar2
,in_billtoaddr1 in varchar2
,in_billtoaddr2 in varchar2
,in_billtocity in varchar2
,in_billtostate in varchar2
,in_billtopostalcode in varchar2
,in_billtocountrycode in varchar2
,in_billtophone in varchar2
,in_billtofax in varchar2
,in_billtoemail in varchar2
,in_carrier in varchar2
,in_carrier_name in varchar2
,in_packlistshipdate in varchar2
,in_routing in varchar2
,in_shiptype in varchar2
,in_shipterms in varchar2
,in_reportingcode in varchar2
,in_depositororder in varchar2
,in_po in varchar2
,in_deliverydate in varchar2
,in_estdelivery in date
,in_billoflading in varchar2
,in_prono in varchar2
,in_masterbol in number
,in_splitshipno in varchar2
,in_invoicedate in varchar2
,in_effectivedate in varchar2
,in_totalunits in number
,in_totalweight in number
,in_uomweight in varchar2
,in_totalvolume in number
,in_uomvolume in varchar2
,in_ladingqty in number
,in_uom in varchar2
,in_warehouse_name in varchar2
,in_warehouse_id in varchar2
,in_depositor_name in varchar2
,in_depositor_id in varchar2
,in_hdrpassthruchar01 in varchar2
,in_hdrpassthruchar02 in varchar2
,in_hdrpassthruchar03 in varchar2
,in_hdrpassthruchar04 in varchar2
,in_hdrpassthruchar05 in varchar2
,in_hdrpassthruchar06 in varchar2
,in_hdrpassthruchar07 in varchar2
,in_hdrpassthruchar08 in varchar2
,in_hdrpassthruchar09 in varchar2
,in_hdrpassthruchar10 in varchar2
,in_hdrpassthruchar11 in varchar2
,in_hdrpassthruchar12 in varchar2
,in_hdrpassthruchar13 in varchar2
,in_hdrpassthruchar14 in varchar2
,in_hdrpassthruchar15 in varchar2
,in_hdrpassthruchar16 in varchar2
,in_hdrpassthruchar17 in varchar2
,in_hdrpassthruchar18 in varchar2
,in_hdrpassthruchar19 in varchar2
,in_hdrpassthruchar20 in varchar2
,in_hdrpassthruchar21 in varchar2
,in_hdrpassthruchar22 in varchar2
,in_hdrpassthruchar23 in varchar2
,in_hdrpassthruchar24 in varchar2
,in_hdrpassthruchar25 in varchar2
,in_hdrpassthruchar26 in varchar2
,in_hdrpassthruchar27 in varchar2
,in_hdrpassthruchar28 in varchar2
,in_hdrpassthruchar29 in varchar2
,in_hdrpassthruchar30 in varchar2
,in_hdrpassthruchar31 in varchar2
,in_hdrpassthruchar32 in varchar2
,in_hdrpassthruchar33 in varchar2
,in_hdrpassthruchar34 in varchar2
,in_hdrpassthruchar35 in varchar2
,in_hdrpassthruchar36 in varchar2
,in_hdrpassthruchar37 in varchar2
,in_hdrpassthruchar38 in varchar2
,in_hdrpassthruchar39 in varchar2
,in_hdrpassthruchar40 in varchar2
,in_hdrpassthruchar41 in varchar2
,in_hdrpassthruchar42 in varchar2
,in_hdrpassthruchar43 in varchar2
,in_hdrpassthruchar44 in varchar2
,in_hdrpassthruchar45 in varchar2
,in_hdrpassthruchar46 in varchar2
,in_hdrpassthruchar47 in varchar2
,in_hdrpassthruchar48 in varchar2
,in_hdrpassthruchar49 in varchar2
,in_hdrpassthruchar50 in varchar2
,in_hdrpassthruchar51 in varchar2
,in_hdrpassthruchar52 in varchar2
,in_hdrpassthruchar53 in varchar2
,in_hdrpassthruchar54 in varchar2
,in_hdrpassthruchar55 in varchar2
,in_hdrpassthruchar56 in varchar2
,in_hdrpassthruchar57 in varchar2
,in_hdrpassthruchar58 in varchar2
,in_hdrpassthruchar59 in varchar2
,in_hdrpassthruchar60 in varchar2
,in_hdrpassthrunum01 in number
,in_hdrpassthrunum02 in number
,in_hdrpassthrunum03 in number
,in_hdrpassthrunum04 in number
,in_hdrpassthrunum05 in number
,in_hdrpassthrunum06 in number
,in_hdrpassthrunum07 in number
,in_hdrpassthrunum08 in number
,in_hdrpassthrunum09 in number
,in_hdrpassthrunum10 in number
,in_hdrpassthrudate01 in date
,in_hdrpassthrudate02 in date
,in_hdrpassthrudate03 in date
,in_hdrpassthrudate04 in date
,in_hdrpassthrudoll01 in number
,in_hdrpassthrudoll02 in number
,in_trailer in varchar2
,in_seal in varchar2
,in_palletcount in number
,in_freightcost in number
,in_lateshipreason in varchar2
,in_carrier_del_serv in varchar2
,in_shippingcost in number
,in_prono_or_all_trackingnos in varchar2
,in_shipfrom_addr1 in varchar2
,in_shipfrom_addr2 in varchar2
,in_shipfrom_city in varchar2
,in_shipfrom_state in varchar2
,in_shipfrom_postalcode in varchar2
,in_invoicenumber810 in number
,in_invoiceamount810 in number
,in_vicsbolnumber in varchar2
,in_scac in varchar2
,in_authorizationnbr in varchar2
,in_link_shipment in varchar2
,in_delivery_requested in date
,in_sscccount in number
,in_shipment in varchar2
,in_seq in number
,out_errorno in out number
,out_msg in out varchar2
);

procedure import_4pl_945_detail
(in_importfileid in varchar2
,in_custid in varchar2
,in_reference in varchar2
,in_orderid in number
,in_shipid in number
,in_item in varchar2
,in_lotnumber in varchar2
,in_assignedid in number
,in_shipticket in varchar2
,in_trackingno in varchar2
,in_servicecode in varchar2
,in_lbs in number
,in_kgs in number
,in_gms in number
,in_ozs in number
,in_link_lotnumber in varchar2
,in_inventoryclass in varchar2
,in_statuscode in varchar2
,in_linenumber in varchar2
,in_orderdate in date
,in_po in varchar2
,in_qtyordered in number
,in_qtyshipped in number
,in_qtydiff in number
,in_uom in varchar2
,in_packlistshipdate in date
,in_weight in number
,in_weightquaifier in varchar2
,in_weightunit in varchar2
,in_description in varchar2
,in_upc in varchar2
,in_dtlpassthruchar01 in varchar2
,in_dtlpassthruchar02 in varchar2
,in_dtlpassthruchar03 in varchar2
,in_dtlpassthruchar04 in varchar2
,in_dtlpassthruchar05 in varchar2
,in_dtlpassthruchar06 in varchar2
,in_dtlpassthruchar07 in varchar2
,in_dtlpassthruchar08 in varchar2
,in_dtlpassthruchar09 in varchar2
,in_dtlpassthruchar10 in varchar2
,in_dtlpassthruchar11 in varchar2
,in_dtlpassthruchar12 in varchar2
,in_dtlpassthruchar13 in varchar2
,in_dtlpassthruchar14 in varchar2
,in_dtlpassthruchar15 in varchar2
,in_dtlpassthruchar16 in varchar2
,in_dtlpassthruchar17 in varchar2
,in_dtlpassthruchar18 in varchar2
,in_dtlpassthruchar19 in varchar2
,in_dtlpassthruchar20 in varchar2
,in_dtlpassthruchar21 in varchar2
,in_dtlpassthruchar22 in varchar2
,in_dtlpassthruchar23 in varchar2
,in_dtlpassthruchar24 in varchar2
,in_dtlpassthruchar25 in varchar2
,in_dtlpassthruchar26 in varchar2
,in_dtlpassthruchar27 in varchar2
,in_dtlpassthruchar28 in varchar2
,in_dtlpassthruchar29 in varchar2
,in_dtlpassthruchar30 in varchar2
,in_dtlpassthruchar31 in varchar2
,in_dtlpassthruchar32 in varchar2
,in_dtlpassthruchar33 in varchar2
,in_dtlpassthruchar34 in varchar2
,in_dtlpassthruchar35 in varchar2
,in_dtlpassthruchar36 in varchar2
,in_dtlpassthruchar37 in varchar2
,in_dtlpassthruchar38 in varchar2
,in_dtlpassthruchar39 in varchar2
,in_dtlpassthruchar40 in varchar2
,in_dtlpassthrunum01 in number
,in_dtlpassthrunum02 in number
,in_dtlpassthrunum03 in number
,in_dtlpassthrunum04 in number
,in_dtlpassthrunum05 in number
,in_dtlpassthrunum06 in number
,in_dtlpassthrunum07 in number
,in_dtlpassthrunum08 in number
,in_dtlpassthrunum09 in number
,in_dtlpassthrunum10 in number
,in_dtlpassthrunum11 in number
,in_dtlpassthrunum12 in number
,in_dtlpassthrunum13 in number
,in_dtlpassthrunum14 in number
,in_dtlpassthrunum15 in number
,in_dtlpassthrunum16 in number
,in_dtlpassthrunum17 in number
,in_dtlpassthrunum18 in number
,in_dtlpassthrunum19 in number
,in_dtlpassthrunum20 in number
,in_dtlpassthrudate01 in date
,in_dtlpassthrudate02 in date
,in_dtlpassthrudate03 in date
,in_dtlpassthrudate04 in date
,in_dtlpassthrudoll01 in number
,in_dtlpassthrudoll02 in number
,in_fromlpid in varchar2
,in_smallpackagelbs in number
,in_deliveryservice in varchar2
,in_entereduom in varchar2
,in_qtyshippedeuom in number
,in_seq in number
,out_errorno in out number
,out_msg in out varchar2
);

procedure end_of_import_4pl_945
(in_custid in varchar2
,in_importfileid in varchar2
,in_userid in varchar2
,out_errorno in out number
,out_msg in out varchar2
);

procedure import_4pl_944_header
(in_importfileid in varchar2
,in_custid in varchar2
,in_reference in varchar2
,in_orderid in number
,in_shipid in number
,in_company in varchar2
,in_warehouse in varchar2
,in_loadno in number
,in_cust_orderid in varchar2
,in_cust_shipid in varchar2
,in_shipfrom in varchar2
,in_shipfromid in varchar2
,in_receipt_date in date
,in_vendor in varchar2
,in_vendor_desc in varchar2
,in_bill_of_lading in varchar2
,in_carrier in varchar2
,in_routing in varchar2
,in_po varchar
,in_order_type in varchar2
,in_qtyorder in number
,in_qtyrcvd in number
,in_qtyrcvdgood in number
,in_qtyrcvddmgd in number
,in_reporting_code in varchar2
,in_some_date in date
,in_unload_date in date
,in_whse_receipt_num in varchar2
,in_transmeth_type in varchar2
,in_packer_number in varchar2
,in_vendor_order_num in varchar2
,in_warehouse_name in varchar2
,in_warehouse_id in varchar2
,in_depositor_name in varchar2
,in_depositor_id in varchar2
,in_hdrpassthruchar01 in varchar2
,in_hdrpassthruchar02 in varchar2
,in_hdrpassthruchar03 in varchar2
,in_hdrpassthruchar04 in varchar2
,in_hdrpassthruchar05 in varchar2
,in_hdrpassthruchar06 in varchar2
,in_hdrpassthruchar07 in varchar2
,in_hdrpassthruchar08 in varchar2
,in_hdrpassthruchar09 in varchar2
,in_hdrpassthruchar10 in varchar2
,in_hdrpassthruchar11 in varchar2
,in_hdrpassthruchar12 in varchar2
,in_hdrpassthruchar13 in varchar2
,in_hdrpassthruchar14 in varchar2
,in_hdrpassthruchar15 in varchar2
,in_hdrpassthruchar16 in varchar2
,in_hdrpassthruchar17 in varchar2
,in_hdrpassthruchar18 in varchar2
,in_hdrpassthruchar19 in varchar2
,in_hdrpassthruchar20 in varchar2
,in_hdrpassthruchar21 in varchar2
,in_hdrpassthruchar22 in varchar2
,in_hdrpassthruchar23 in varchar2
,in_hdrpassthruchar24 in varchar2
,in_hdrpassthruchar25 in varchar2
,in_hdrpassthruchar26 in varchar2
,in_hdrpassthruchar27 in varchar2
,in_hdrpassthruchar28 in varchar2
,in_hdrpassthruchar29 in varchar2
,in_hdrpassthruchar30 in varchar2
,in_hdrpassthruchar31 in varchar2
,in_hdrpassthruchar32 in varchar2
,in_hdrpassthruchar33 in varchar2
,in_hdrpassthruchar34 in varchar2
,in_hdrpassthruchar35 in varchar2
,in_hdrpassthruchar36 in varchar2
,in_hdrpassthruchar37 in varchar2
,in_hdrpassthruchar38 in varchar2
,in_hdrpassthruchar39 in varchar2
,in_hdrpassthruchar40 in varchar2
,in_hdrpassthruchar41 in varchar2
,in_hdrpassthruchar42 in varchar2
,in_hdrpassthruchar43 in varchar2
,in_hdrpassthruchar44 in varchar2
,in_hdrpassthruchar45 in varchar2
,in_hdrpassthruchar46 in varchar2
,in_hdrpassthruchar47 in varchar2
,in_hdrpassthruchar48 in varchar2
,in_hdrpassthruchar49 in varchar2
,in_hdrpassthruchar50 in varchar2
,in_hdrpassthruchar51 in varchar2
,in_hdrpassthruchar52 in varchar2
,in_hdrpassthruchar53 in varchar2
,in_hdrpassthruchar54 in varchar2
,in_hdrpassthruchar55 in varchar2
,in_hdrpassthruchar56 in varchar2
,in_hdrpassthruchar57 in varchar2
,in_hdrpassthruchar58 in varchar2
,in_hdrpassthruchar59 in varchar2
,in_hdrpassthruchar60 in varchar2
,in_hdrpassthrunum01 in number
,in_hdrpassthrunum02 in number
,in_hdrpassthrunum03 in number
,in_hdrpassthrunum04 in number
,in_hdrpassthrunum05 in number
,in_hdrpassthrunum06 in number
,in_hdrpassthrunum07 in number
,in_hdrpassthrunum08 in number
,in_hdrpassthrunum09 in number
,in_hdrpassthrunum10 in number
,in_hdrpassthrudate01 in date
,in_hdrpassthrudate02 in date
,in_hdrpassthrudate03 in date
,in_hdrpassthrudate04 in date
,in_hdrpassthrudoll01 in number
,in_hdrpassthrudoll02 in number
,in_prono in varchar2
,in_trailer in varchar2
,in_seal in varchar2
,in_palletcount in number
,in_facility in varchar2
,in_shippername in varchar2
,in_shippercontact in varchar2
,in_shipperaddr1 in varchar2
,in_shipperaddr2 in varchar2
,in_shippercity in varchar2
,in_shipperstate in varchar2
,in_shipperpostalcode in varchar2
,in_shippercountrycode in varchar2
,in_shipperphone in varchar2
,in_shipperfax in varchar2
,in_shipperemail in varchar2
,in_billtoname in varchar2
,in_billtocontact in varchar2
,in_billtoaddr1 in varchar2
,in_billtoaddr2 in varchar2
,in_billtocity in varchar2
,in_billtostate in varchar2
,in_billtopostalcode in varchar2
,in_billtocountrycode in varchar2
,in_billtophone in varchar2
,in_billtofax in varchar2
,in_billtoemail in varchar2
,in_rma in varchar2
,in_ordertype in varchar2
,in_returntrackingno in varchar2
,in_statususer in varchar2
,in_instructions in varchar2
,in_seq in number
,out_errorno in out number
,out_msg in out varchar2
);

procedure import_4pl_944_detail
(in_importfileid in varchar2
,in_custid in varchar2
,in_reference in varchar2
,in_orderid in number
,in_shipid in number
,in_item in varchar2
,in_lotnumber in varchar2
,in_line_number in number
,in_upc in varchar2
,in_description in varchar2
,in_uom in varchar2
,in_qtyrcvd in number
,in_cubercvd in number
,in_qtyrcvdgood in number
,in_cubercvdgood in number
,in_qtyrcvddmgd in number
,in_qtyorder in number
,in_weightitem in number
,in_weightqualifier char
,in_weightunitcode char
,in_volume in number
,in_uom_volume in varchar2
,in_dtlpassthruchar01 in varchar2
,in_dtlpassthruchar02 in varchar2
,in_dtlpassthruchar03 in varchar2
,in_dtlpassthruchar04 in varchar2
,in_dtlpassthruchar05 in varchar2
,in_dtlpassthruchar06 in varchar2
,in_dtlpassthruchar07 in varchar2
,in_dtlpassthruchar08 in varchar2
,in_dtlpassthruchar09 in varchar2
,in_dtlpassthruchar10 in varchar2
,in_dtlpassthruchar11 in varchar2
,in_dtlpassthruchar12 in varchar2
,in_dtlpassthruchar13 in varchar2
,in_dtlpassthruchar14 in varchar2
,in_dtlpassthruchar15 in varchar2
,in_dtlpassthruchar16 in varchar2
,in_dtlpassthruchar17 in varchar2
,in_dtlpassthruchar18 in varchar2
,in_dtlpassthruchar19 in varchar2
,in_dtlpassthruchar20 in varchar2
,in_dtlpassthruchar21 in varchar2
,in_dtlpassthruchar22 in varchar2
,in_dtlpassthruchar23 in varchar2
,in_dtlpassthruchar24 in varchar2
,in_dtlpassthruchar25 in varchar2
,in_dtlpassthruchar26 in varchar2
,in_dtlpassthruchar27 in varchar2
,in_dtlpassthruchar28 in varchar2
,in_dtlpassthruchar29 in varchar2
,in_dtlpassthruchar30 in varchar2
,in_dtlpassthruchar31 in varchar2
,in_dtlpassthruchar32 in varchar2
,in_dtlpassthruchar33 in varchar2
,in_dtlpassthruchar34 in varchar2
,in_dtlpassthruchar35 in varchar2
,in_dtlpassthruchar36 in varchar2
,in_dtlpassthruchar37 in varchar2
,in_dtlpassthruchar38 in varchar2
,in_dtlpassthruchar39 in varchar2
,in_dtlpassthruchar40 in varchar2
,in_dtlpassthruchar41 in varchar2
,in_dtlpassthruchar42 in varchar2
,in_dtlpassthruchar43 in varchar2
,in_dtlpassthruchar44 in varchar2
,in_dtlpassthruchar45 in varchar2
,in_dtlpassthruchar46 in varchar2
,in_dtlpassthruchar47 in varchar2
,in_dtlpassthruchar48 in varchar2
,in_dtlpassthruchar49 in varchar2
,in_dtlpassthruchar50 in varchar2
,in_dtlpassthruchar51 in varchar2
,in_dtlpassthruchar52 in varchar2
,in_dtlpassthruchar53 in varchar2
,in_dtlpassthruchar54 in varchar2
,in_dtlpassthruchar55 in varchar2
,in_dtlpassthruchar56 in varchar2
,in_dtlpassthruchar57 in varchar2
,in_dtlpassthruchar58 in varchar2
,in_dtlpassthruchar59 in varchar2
,in_dtlpassthruchar60 in varchar2
,in_dtlpassthrunum01 in number
,in_dtlpassthrunum02 in number
,in_dtlpassthrunum03 in number
,in_dtlpassthrunum04 in number
,in_dtlpassthrunum05 in number
,in_dtlpassthrunum06 in number
,in_dtlpassthrunum07 in number
,in_dtlpassthrunum08 in number
,in_dtlpassthrunum09 in number
,in_dtlpassthrunum10 in number
,in_dtlpassthrunum11 in number
,in_dtlpassthrunum12 in number
,in_dtlpassthrunum13 in number
,in_dtlpassthrunum14 in number
,in_dtlpassthrunum15 in number
,in_dtlpassthrunum16 in number
,in_dtlpassthrunum17 in number
,in_dtlpassthrunum18 in number
,in_dtlpassthrunum19 in number
,in_dtlpassthrunum20 in number
,in_dtlpassthrudate01 in date
,in_dtlpassthrudate02 in date
,in_dtlpassthrudate03 in date
,in_dtlpassthrudate04 in date
,in_dtlpassthrudoll01 in number
,in_dtlpassthrudoll02 in number
,in_qtyonhold in number
,in_qtyrcvd_invstatus in varchar2
,in_serialnumber in varchar2
,in_useritem1 in varchar2
,in_useritem2 in varchar2
,in_useritem3 in varchar2
,in_orig_line_number in number
,in_unload_date in date
,in_condition in varchar2
,in_invclass in varchar2
,in_manufacturedate in date
,in_invstatus in varchar2
,in_cubercvddmgd in number
,in_seq in number
,out_errorno in out number
,out_msg in out varchar2
);

procedure end_of_import_4pl_944
(in_custid in varchar2
,in_importfileid in varchar2
,in_userid in varchar2
,out_errorno in out number
,out_msg in out varchar2
);

procedure import_4pl_846_header
(in_importfileid        in varchar2
,in_facility            in varchar2
,in_custid              in varchar2
,out_errorno            in out number
,out_msg                in out varchar2
);

procedure import_4pl_846_detail
(in_importfileid        in varchar2
,in_item                in varchar2
,in_facility            in varchar2
,in_custid              in varchar2
,out_errorno            in out number
,out_msg                in out varchar2
);

procedure import_4pl_846_quantity
(in_importfileid        in varchar2
,in_invstatus           in varchar2
,in_uom                 in varchar2
,in_quantity            in varchar2
,in_facility            in varchar2
,in_custid              in varchar2
,in_item                in varchar2
,out_errorno            in out number
,out_msg                in out varchar2
);

procedure end_of_import_4pl_846
(in_importfileid        in varchar2
,in_custid              in varchar2
,in_userid              in varchar2
,out_errorno            in out number
,out_msg                in out varchar2
);

end zimportproc4pl;

/
show error package zimportproc4pl;
exit;
