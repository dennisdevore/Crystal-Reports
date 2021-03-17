--
-- $Id$
--
create or replace PACKAGE alps.zimportprocsip

is

function lip_expirationdate
(in_lpid varchar2
) return date;

function order_reference
(in_orderid number
,in_shipid number
,in_qualifier varchar2
) return varchar2;

function shipment_identifier
(in_orderid IN number
,in_shipid IN number
) return varchar2;

function tradingpartnerid_to_custid
(in_sip_tradingpartnerid IN varchar2
) return varchar2;

function sip_consignee_tradingpartnerid
(in_custid IN varchar2
,in_consignee IN varchar2
) return varchar2;

function sip_consignee_match
(in_custid IN varchar2
,in_orderid IN number
,in_shipid IN number
) return varchar2;

procedure import_order_header_sip_wso_ho  --header order
(in_func IN OUT varchar2
,in_sip_tradingpartnerid IN varchar2
,in_reference IN varchar2
,in_record_type IN varchar2
,in_po IN varchar2
,in_order_status IN varchar2
,in_tran_type IN varchar2
,in_action_code IN varchar2
,in_link_sequence IN number          --hdrpassthrunum01
,in_master_link_number IN varchar2   --hdrpassthruchar09
,in_payment_method IN varchar2       --map shipterms
,in_trans_method IN varchar2         --map shiptype
,in_pallet_exchange IN varchar2
,in_unit_load_option IN varchar2
,in_carrier_routing IN varchar2
,in_fob_location_qualifier IN varchar2
,in_fob_location_descr IN varchar2
,in_cod_method IN varchar2           --map cod
,in_amount IN number
,in_carrier IN varchar2
,in_flex_field1 IN varchar2          --hdrpassthruchar01 thru 08
,in_flex_field2 IN varchar2
,in_flex_field3 IN varchar2
,in_flex_field4 IN varchar2
,in_flex_field5 IN varchar2
,in_flex_field6 IN varchar2
,in_flex_field7 IN varchar2
,in_flex_field8 IN varchar2
,in_importfileid IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

PROCEDURE get_sipfileseq
(in_custid IN varchar2
,out_sipfileseq OUT varchar2
);

procedure import_sip_wso_rr  --reference record
(in_func IN OUT varchar2
,in_sip_tradingpartnerid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_record_type IN varchar2
,in_qualifier IN varchar2
,in_data IN varchar2
,in_descr IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_sip_wso_dr  --date record
(in_func IN OUT varchar2
,in_sip_tradingpartnerid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_record_type IN varchar2
,in_qualifier IN varchar2
,in_date IN date
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_sip_wso_ha  --header address
(in_func IN OUT varchar2
,in_sip_tradingpartnerid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_record_type IN varchar2
,in_address_type IN varchar2
,in_location_code IN varchar2
,in_location_number IN varchar2
,in_address_name IN varchar2
,in_address_alternate_name IN varchar2
,in_address1 IN varchar2
,in_address2 IN varchar2
,in_address3 IN varchar2
,in_address4 IN varchar2
,in_city IN varchar2
,in_state IN varchar2
,in_postalcode IN varchar2
,in_country IN varchar2
,in_contact IN varchar2
,in_contact_phone IN varchar2
,in_contact_fax IN varchar2
,in_contact_email IN varchar2
,in_tax_id IN varchar2
,in_tax_exempt IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_sip_wso_hn -- header note
(in_func IN OUT varchar2
,in_sip_tradingpartnerid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_record_type IN varchar2
,in_sequence_number IN number
,in_note1 IN varchar2
,in_note2 IN varchar2
,in_note3 IN varchar2
,in_note4 IN varchar2
,in_note5 IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_sip_wso_li -- line item
(in_func IN OUT varchar2
,in_sip_tradingpartnerid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_record_type IN varchar2
,in_line_number IN number
,in_part1_qualifier IN varchar2
,in_part1_item IN varchar2
,in_part2_qualifier IN varchar2
,in_part2_item IN varchar2
,in_part3_qualifier IN varchar2
,in_part3_item IN varchar2
,in_part4_qualifier IN varchar2
,in_part4_item IN varchar2
,in_part_desc1 IN varchar2
,in_part_desc2 IN varchar2
,in_qty_entered IN number
,in_uom_entered IN varchar2
,in_pack IN number
,in_size IN number
,in_uom IN varchar2
,in_weight IN number
,in_weight_qualifier IN varchar2
,in_weight_uom IN varchar2
,in_unit_weight IN number
,in_volume IN number
,in_volume_uom IN varchar2
,in_color IN varchar2
,in_amt1_qualifier in varchar2
,in_amt1 IN number
,in_credit_debit_flag1 IN varchar2
,in_amt2_qualifier in varchar2
,in_amt2 IN number
,in_credit_debit_flag2 IN varchar2
,in_flex_field1 IN varchar2
,in_flex_field2 IN varchar2
,in_flex_field3 IN varchar2
,in_flex_field4 IN varchar2
,in_flex_field5 IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_sip_wso_st --  summary total
(in_func IN OUT varchar2
,in_sip_tradingpartnerid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_record_type IN varchar2
,in_qty_entered IN number
,in_weight IN number
,in_uom IN varchar2
,in_volume_unit_basis IN number
,in_volume IN varchar2
,in_order_sizing_factor IN number
,in_flex_field1 IN varchar2
,in_flex_field2 IN varchar2
,in_flex_field3 IN varchar2
,in_flex_field4 IN varchar2
,in_flex_field5 IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_sip_WSA_945
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_sip_WSA_945
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_sip_asn_856
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_shipto IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_default_carton_uom IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_sip_asn_856
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_sip_str_944
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_sip_str_944
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

PRAGMA RESTRICT_REFERENCES (lip_expirationdate, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (order_reference, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (tradingpartnerid_to_custid, WNDS, WNPS, RNPS);

end zimportprocsip;
/
show error package zimportprocsip;
exit;
