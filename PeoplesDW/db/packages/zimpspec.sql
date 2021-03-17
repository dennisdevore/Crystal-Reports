--
-- $Id$
--
create or replace PACKAGE alps.zimportprocs

Is

procedure import_order_header
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_ordertype IN varchar2
,in_apptdate IN date
,in_shipdate IN date
,in_po IN varchar2
,in_rma IN varchar2
,in_fromfacility IN varchar2
,in_tofacility IN varchar2
,in_shipto IN varchar2
,in_billoflading IN varchar2
,in_priority IN varchar2
,in_shipper IN varchar2
,in_consignee IN varchar2
,in_shiptype IN varchar2
,in_carrier IN varchar2
,in_reference IN varchar2
,in_shipterms IN varchar2
,in_shippername IN varchar2
,in_shippercontact IN varchar2
,in_shipperaddr1 IN varchar2
,in_shipperaddr2 IN varchar2
,in_shippercity IN varchar2
,in_shipperstate IN varchar2
,in_shipperpostalcode IN varchar2
,in_shippercountrycode IN varchar2
,in_shipperphone IN varchar2
,in_shipperfax IN varchar2
,in_shipperemail IN varchar2
,in_shiptoname IN varchar2
,in_shiptocontact IN varchar2
,in_shiptoaddr1 IN varchar2
,in_shiptoaddr2 IN varchar2
,in_shiptocity IN varchar2
,in_shiptostate IN varchar2
,in_shiptopostalcode IN varchar2
,in_shiptocountrycode IN varchar2
,in_shiptophone IN varchar2
,in_shiptofax IN varchar2
,in_shiptoemail IN varchar2
,in_billtoname IN varchar2
,in_billtocontact IN varchar2
,in_billtoaddr1 IN varchar2
,in_billtoaddr2 IN varchar2
,in_billtocity IN varchar2
,in_billtostate IN varchar2
,in_billtopostalcode IN varchar2
,in_billtocountrycode IN varchar2
,in_billtophone IN varchar2
,in_billtofax IN varchar2
,in_billtoemail IN varchar2
,in_deliveryservice IN varchar2
,in_saturdaydelivery IN varchar2
,in_cod in varchar2
,in_amtcod in number
,in_specialservice1 in varchar2
,in_specialservice2 in varchar2
,in_specialservice3 in varchar2
,in_specialservice4 in varchar2
,in_importfileid IN varchar2
,in_hdrpassthruchar01 IN varchar2
,in_hdrpassthruchar02 IN varchar2
,in_hdrpassthruchar03 IN varchar2
,in_hdrpassthruchar04 IN varchar2
,in_hdrpassthruchar05 IN varchar2
,in_hdrpassthruchar06 IN varchar2
,in_hdrpassthruchar07 IN varchar2
,in_hdrpassthruchar08 IN varchar2
,in_hdrpassthruchar09 IN varchar2
,in_hdrpassthruchar10 IN varchar2
,in_hdrpassthruchar11 IN varchar2
,in_hdrpassthruchar12 IN varchar2
,in_hdrpassthruchar13 IN varchar2
,in_hdrpassthruchar14 IN varchar2
,in_hdrpassthruchar15 IN varchar2
,in_hdrpassthruchar16 IN varchar2
,in_hdrpassthruchar17 IN varchar2
,in_hdrpassthruchar18 IN varchar2
,in_hdrpassthruchar19 IN varchar2
,in_hdrpassthruchar20 IN varchar2
,in_hdrpassthruchar21 IN varchar2
,in_hdrpassthruchar22 IN varchar2
,in_hdrpassthruchar23 IN varchar2
,in_hdrpassthruchar24 IN varchar2
,in_hdrpassthruchar25 IN varchar2
,in_hdrpassthruchar26 IN varchar2
,in_hdrpassthruchar27 IN varchar2
,in_hdrpassthruchar28 IN varchar2
,in_hdrpassthruchar29 IN varchar2
,in_hdrpassthruchar30 IN varchar2
,in_hdrpassthruchar31 IN varchar2
,in_hdrpassthruchar32 IN varchar2
,in_hdrpassthruchar33 IN varchar2
,in_hdrpassthruchar34 IN varchar2
,in_hdrpassthruchar35 IN varchar2
,in_hdrpassthruchar36 IN varchar2
,in_hdrpassthruchar37 IN varchar2
,in_hdrpassthruchar38 IN varchar2
,in_hdrpassthruchar39 IN varchar2
,in_hdrpassthruchar40 IN varchar2
,in_hdrpassthruchar41 IN varchar2
,in_hdrpassthruchar42 IN varchar2
,in_hdrpassthruchar43 IN varchar2
,in_hdrpassthruchar44 IN varchar2
,in_hdrpassthruchar45 IN varchar2
,in_hdrpassthruchar46 IN varchar2
,in_hdrpassthruchar47 IN varchar2
,in_hdrpassthruchar48 IN varchar2
,in_hdrpassthruchar49 IN varchar2
,in_hdrpassthruchar50 IN varchar2
,in_hdrpassthruchar51 IN varchar2
,in_hdrpassthruchar52 IN varchar2
,in_hdrpassthruchar53 IN varchar2
,in_hdrpassthruchar54 IN varchar2
,in_hdrpassthruchar55 IN varchar2
,in_hdrpassthruchar56 IN varchar2
,in_hdrpassthruchar57 IN varchar2
,in_hdrpassthruchar58 IN varchar2
,in_hdrpassthruchar59 IN varchar2
,in_hdrpassthruchar60 IN varchar2
,in_hdrpassthrunum01 IN number
,in_hdrpassthrunum02 IN number
,in_hdrpassthrunum03 IN number
,in_hdrpassthrunum04 IN number
,in_hdrpassthrunum05 IN number
,in_hdrpassthrunum06 IN number
,in_hdrpassthrunum07 IN number
,in_hdrpassthrunum08 IN number
,in_hdrpassthrunum09 IN number
,in_hdrpassthrunum10 IN number
,in_cancel_after IN date
,in_delivery_requested IN date
,in_requested_ship IN date
,in_ship_not_before IN date
,in_ship_no_later IN date
,in_cancel_if_not_delivered_by IN date
,in_do_not_deliver_after IN date
,in_do_not_deliver_before IN date
,in_hdrpassthrudate01 date
,in_hdrpassthrudate02 date
,in_hdrpassthrudate03 date
,in_hdrpassthrudate04 date
,in_hdrpassthrudoll01 number
,in_hdrpassthrudoll02 number
,in_rfautodisplay varchar2
,in_ignore_received_orders_yn varchar2
,in_arrivaldate IN DATE
,in_validate_shipto in varchar2
,in_abc_revision in varchar2
,in_prono varchar2
,in_editransaction in varchar2
,in_edi_logging_yn in varchar2
,in_futurevc01 in varchar2
,in_futurevc02 in varchar2
,in_futurevc03 in varchar2
,in_futurevc04 in varchar2
,in_futurevc05 in varchar2
,in_futurevc06 in varchar2
,in_futurenum01 in number
,in_futurenum02 in number
,in_futurenum03 in number
,in_order_acknowledgment in varchar2
,in_canceled_new_order in varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_order_line
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_itementered IN varchar2
,in_lotnumber IN varchar2
,in_uomentered IN varchar2
,in_qtyentered IN number
,in_backorder IN varchar2
,in_allowsub IN varchar2
,in_qtytype IN varchar2
,in_invstatusind IN varchar2
,in_invstatus IN varchar2
,in_invclassind IN varchar2
,in_inventoryclass IN varchar2
,in_consigneesku IN varchar2
,in_dtlpassthruchar01 IN varchar2
,in_dtlpassthruchar02 IN varchar2
,in_dtlpassthruchar03 IN varchar2
,in_dtlpassthruchar04 IN varchar2
,in_dtlpassthruchar05 IN varchar2
,in_dtlpassthruchar06 IN varchar2
,in_dtlpassthruchar07 IN varchar2
,in_dtlpassthruchar08 IN varchar2
,in_dtlpassthruchar09 IN varchar2
,in_dtlpassthruchar10 IN varchar2
,in_dtlpassthruchar11 IN varchar2
,in_dtlpassthruchar12 IN varchar2
,in_dtlpassthruchar13 IN varchar2
,in_dtlpassthruchar14 IN varchar2
,in_dtlpassthruchar15 IN varchar2
,in_dtlpassthruchar16 IN varchar2
,in_dtlpassthruchar17 IN varchar2
,in_dtlpassthruchar18 IN varchar2
,in_dtlpassthruchar19 IN varchar2
,in_dtlpassthruchar20 IN varchar2
,in_dtlpassthruchar21 IN varchar2
,in_dtlpassthruchar22 IN varchar2
,in_dtlpassthruchar23 IN varchar2
,in_dtlpassthruchar24 IN varchar2
,in_dtlpassthruchar25 IN varchar2
,in_dtlpassthruchar26 IN varchar2
,in_dtlpassthruchar27 IN varchar2
,in_dtlpassthruchar28 IN varchar2
,in_dtlpassthruchar29 IN varchar2
,in_dtlpassthruchar30 IN varchar2
,in_dtlpassthruchar31 IN varchar2
,in_dtlpassthruchar32 IN varchar2
,in_dtlpassthruchar33 IN varchar2
,in_dtlpassthruchar34 IN varchar2
,in_dtlpassthruchar35 IN varchar2
,in_dtlpassthruchar36 IN varchar2
,in_dtlpassthruchar37 IN varchar2
,in_dtlpassthruchar38 IN varchar2
,in_dtlpassthruchar39 IN varchar2
,in_dtlpassthruchar40 IN varchar2
,in_dtlpassthrunum01 IN number
,in_dtlpassthrunum02 IN number
,in_dtlpassthrunum03 IN number
,in_dtlpassthrunum04 IN number
,in_dtlpassthrunum05 IN number
,in_dtlpassthrunum06 IN number
,in_dtlpassthrunum07 IN number
,in_dtlpassthrunum08 IN number
,in_dtlpassthrunum09 IN number
,in_dtlpassthrunum10 IN number
,in_dtlpassthrunum11 IN number
,in_dtlpassthrunum12 IN number
,in_dtlpassthrunum13 IN number
,in_dtlpassthrunum14 IN number
,in_dtlpassthrunum15 IN number
,in_dtlpassthrunum16 IN number
,in_dtlpassthrunum17 IN number
,in_dtlpassthrunum18 IN number
,in_dtlpassthrunum19 IN number
,in_dtlpassthrunum20 IN number
,in_dtlpassthrudate01 date
,in_dtlpassthrudate02 date
,in_dtlpassthrudate03 date
,in_dtlpassthrudate04 date
,in_dtlpassthrudoll01 number
,in_dtlpassthrudoll02 number
,in_rfautodisplay varchar2
,in_comment long
,in_weight_entered_lbs number
,in_weight_entered_kgs number
,in_variance_pct_shortage number
,in_variance_pct_overage number
,in_variance_use_default_yn varchar2
,in_abc_revision in varchar2
,in_header_carrier varchar2
,in_lineorder varchar2
,in_cancel_productgroup varchar2
,in_invclass_states in varchar2
,in_invclass_states_value in varchar2
,in_upper_item_yn varchar2
,in_order_acknowledgment varchar2
,in_importfileid IN varchar2
,in_notnullpassthrus_yn IN varchar2
,in_delete_by_linenumber_yn in varchar2
,in_weight_acceptance_yn in varchar2
,in_dtl_passthru_item_xref in varchar2
,in_itm_passthru_item_xref in varchar2
,in_canceled_new_order in varchar2
,in_up_to_base_yn in varchar2
,in_style_color_size_columns IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_order_header_instruct
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_instructions IN long
,in_include_cr_lf_yn IN varchar2
,in_abc_revision in varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_order_header_bolcomment
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_bolcomment IN long
,in_abc_revision in varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_order_line_instruct
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_itementered IN varchar2
,in_lotnumber IN varchar2
,in_instructions IN long
,in_include_cr_lf_yn IN varchar2
,in_abc_revision in varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_order_line_bolcomment
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_itementered IN varchar2
,in_lotnumber IN varchar2
,in_bolcomment IN long
,in_abc_revision in varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure release_and_commit_order
(in_orderid IN number
,in_shipid IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_order_seq_comment
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_sequence IN number
,in_comment IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure translate_cust_errorcode
(in_custid IN varchar2
,in_errorcode IN number
,in_errormsg IN varchar2
,out_errorcode IN OUT number
,out_errormsg IN OUT varchar2
);

procedure end_of_import
(in_custid IN varchar2
,in_importfileid IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure update_confirm_date
(in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_confirmdate IN date
,in_userid varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

PROCEDURE get_exportfileseq
(in_custid IN varchar2
,out_exportfileseq OUT varchar2
);

PROCEDURE get_exportfilesuffix
(in_custid IN varchar2
,in_company IN varchar2
,in_warehouse IN varchar2
,out_exportfilesuffix OUT varchar2
);

procedure clone_format
(in_fromname IN varchar2
,in_toname IN varchar2
,in_lineinc IN number
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure import_nothing
(in_dummy_parm IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure get_exportfileseq4
(in_custid IN varchar2
,out_exportfileseq4 OUT varchar2
);

procedure import_dup_order_header
(in_custid IN varchar2
,in_ordertype IN varchar2
,in_apptdate IN date
,in_shipdate IN date
,in_po IN varchar2
,in_rma IN varchar2
,in_fromfacility IN varchar2
,in_tofacility IN varchar2
,in_shipto IN varchar2
,in_billoflading IN varchar2
,in_priority IN varchar2
,in_shipper IN varchar2
,in_consignee IN varchar2
,in_shiptype IN varchar2
,in_carrier IN varchar2
,in_reference IN varchar2
,in_shipterms IN varchar2
,in_shippername IN varchar2
,in_shippercontact IN varchar2
,in_shipperaddr1 IN varchar2
,in_shipperaddr2 IN varchar2
,in_shippercity IN varchar2
,in_shipperstate IN varchar2
,in_shipperpostalcode IN varchar2
,in_shippercountrycode IN varchar2
,in_shipperphone IN varchar2
,in_shipperfax IN varchar2
,in_shipperemail IN varchar2
,in_shiptoname IN varchar2
,in_shiptocontact IN varchar2
,in_shiptoaddr1 IN varchar2
,in_shiptoaddr2 IN varchar2
,in_shiptocity IN varchar2
,in_shiptostate IN varchar2
,in_shiptopostalcode IN varchar2
,in_shiptocountrycode IN varchar2
,in_shiptophone IN varchar2
,in_shiptofax IN varchar2
,in_shiptoemail IN varchar2
,in_billtoname IN varchar2
,in_billtocontact IN varchar2
,in_billtoaddr1 IN varchar2
,in_billtoaddr2 IN varchar2
,in_billtocity IN varchar2
,in_billtostate IN varchar2
,in_billtopostalcode IN varchar2
,in_billtocountrycode IN varchar2
,in_billtophone IN varchar2
,in_billtofax IN varchar2
,in_billtoemail IN varchar2
,in_deliveryservice IN varchar2
,in_saturdaydelivery IN varchar2
,in_cod in varchar2
,in_amtcod in number
,in_specialservice1 in varchar2
,in_specialservice2 in varchar2
,in_specialservice3 in varchar2
,in_specialservice4 in varchar2
,in_importfileid IN varchar2
,in_hdrpassthruchar01 IN varchar2
,in_hdrpassthruchar02 IN varchar2
,in_hdrpassthruchar03 IN varchar2
,in_hdrpassthruchar04 IN varchar2
,in_hdrpassthruchar05 IN varchar2
,in_hdrpassthruchar06 IN varchar2
,in_hdrpassthruchar07 IN varchar2
,in_hdrpassthruchar08 IN varchar2
,in_hdrpassthruchar09 IN varchar2
,in_hdrpassthruchar10 IN varchar2
,in_hdrpassthruchar11 IN varchar2
,in_hdrpassthruchar12 IN varchar2
,in_hdrpassthruchar13 IN varchar2
,in_hdrpassthruchar14 IN varchar2
,in_hdrpassthruchar15 IN varchar2
,in_hdrpassthruchar16 IN varchar2
,in_hdrpassthruchar17 IN varchar2
,in_hdrpassthruchar18 IN varchar2
,in_hdrpassthruchar19 IN varchar2
,in_hdrpassthruchar20 IN varchar2
,in_hdrpassthrunum01 IN number
,in_hdrpassthrunum02 IN number
,in_hdrpassthrunum03 IN number
,in_hdrpassthrunum04 IN number
,in_hdrpassthrunum05 IN number
,in_hdrpassthrunum06 IN number
,in_hdrpassthrunum07 IN number
,in_hdrpassthrunum08 IN number
,in_hdrpassthrunum09 IN number
,in_hdrpassthrunum10 IN number
,in_cancel_after IN date
,in_delivery_requested IN date
,in_requested_ship IN date
,in_ship_not_before IN date
,in_ship_no_later IN date
,in_cancel_if_not_delivered_by IN date
,in_do_not_deliver_after IN date
,in_do_not_deliver_before IN date
,in_hdrpassthrudate01 date
,in_hdrpassthrudate02 date
,in_hdrpassthrudate03 date
,in_hdrpassthrudate04 date
,in_hdrpassthrudoll01 number
,in_hdrpassthrudoll02 number
,in_rfautodisplay varchar2
,in_ignore_received_orders_yn varchar2
,in_arrivaldate IN DATE
,in_validate_shipto in varchar2
,in_loadno in out number
,in_loadstop in out number
,in_loadshipno in out number
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_dup_order_line
(in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_itementered IN varchar2
,in_lotnumber IN varchar2
,in_uomentered IN varchar2
,in_qtyentered IN number
,in_backorder IN varchar2
,in_allowsub IN varchar2
,in_qtytype IN varchar2
,in_invstatusind IN varchar2
,in_invstatus IN varchar2
,in_invclassind IN varchar2
,in_inventoryclass IN varchar2
,in_consigneesku IN varchar2
,in_dtlpassthruchar01 IN varchar2
,in_dtlpassthruchar02 IN varchar2
,in_dtlpassthruchar03 IN varchar2
,in_dtlpassthruchar04 IN varchar2
,in_dtlpassthruchar05 IN varchar2
,in_dtlpassthruchar06 IN varchar2
,in_dtlpassthruchar07 IN varchar2
,in_dtlpassthruchar08 IN varchar2
,in_dtlpassthruchar09 IN varchar2
,in_dtlpassthruchar10 IN varchar2
,in_dtlpassthruchar11 IN varchar2
,in_dtlpassthruchar12 IN varchar2
,in_dtlpassthruchar13 IN varchar2
,in_dtlpassthruchar14 IN varchar2
,in_dtlpassthruchar15 IN varchar2
,in_dtlpassthruchar16 IN varchar2
,in_dtlpassthruchar17 IN varchar2
,in_dtlpassthruchar18 IN varchar2
,in_dtlpassthruchar19 IN varchar2
,in_dtlpassthruchar20 IN varchar2
,in_dtlpassthrunum01 IN number
,in_dtlpassthrunum02 IN number
,in_dtlpassthrunum03 IN number
,in_dtlpassthrunum04 IN number
,in_dtlpassthrunum05 IN number
,in_dtlpassthrunum06 IN number
,in_dtlpassthrunum07 IN number
,in_dtlpassthrunum08 IN number
,in_dtlpassthrunum09 IN number
,in_dtlpassthrunum10 IN number
,in_dtlpassthrudate01 date
,in_dtlpassthrudate02 date
,in_dtlpassthrudate03 date
,in_dtlpassthrudate04 date
,in_dtlpassthrudoll01 number
,in_dtlpassthrudoll02 number
,in_rfautodisplay varchar2
,in_comment  long
,in_header_carrier in varchar2
,in_invclass_states in varchar2
,in_invclass_states_value in varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_dup_order_hdr_notes
(in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_qualifier IN varchar2
,in_note  IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure end_of_dup_import
(in_custid IN varchar2
,in_importfileid IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure import_file_sequence
(in_sequence in varchar2
,in_filename in varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

PROCEDURE import_assign_ob_order_to_load
(in_orderid IN number
,in_shipid IN number
,in_carrier IN varchar2
,in_trailer IN varchar2
,in_seal IN varchar2
,in_billoflading IN varchar2
,in_stageloc IN varchar2
,in_doorloc IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,io_loadno IN OUT number
,io_stopno IN OUT number
,io_shipno IN OUT number
,out_msg  IN OUT varchar2
);

procedure import_order_hdr_sac
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po in varchar2
,in_sac01 in varchar2
,in_sac02 in varchar2
,in_sac03 in varchar2
,in_sac04 in varchar2
,in_sac05 in varchar2
,in_sac06 in varchar2
,in_sac07 in varchar2
,in_sac08 in varchar2
,in_sac09 in varchar2
,in_sac10 in varchar2
,in_sac11 in varchar2
,in_sac12 in varchar2
,in_sac13 in varchar2
,in_sac14 in varchar2
,in_sac15 in varchar2
,in_do_not_allow_duplicate_yn in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_order_dtl_sac
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po in varchar2
,in_item in varchar2
,in_lotnumber in varchar2
,in_sac01 in varchar2
,in_sac02 in varchar2
,in_sac03 in varchar2
,in_sac04 in varchar2
,in_sac05 in varchar2
,in_sac06 in varchar2
,in_sac07 in varchar2
,in_sac08 in varchar2
,in_sac09 in varchar2
,in_sac10 in varchar2
,in_sac11 in varchar2
,in_sac12 in varchar2
,in_sac13 in varchar2
,in_sac14 in varchar2
,in_sac15 in varchar2
,in_do_not_allow_duplicate_yn in varchar2
,out_errorno IN OUT NUMBER
,out_msg  IN OUT varchar2
);

procedure import_dup_order_line_sn
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_sn IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure import_order_line_pack
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_linenumber IN number
,in_itementered IN varchar2
,in_qty IN number
,in_description IN varchar2
,in_dtlpassthruchar01 IN varchar2
,in_dtlpassthruchar02 IN varchar2
,in_dtlpassthruchar03 IN varchar2
,in_dtlpassthruchar04 IN varchar2
,in_dtlpassthruchar05 IN varchar2
,in_dtlpassthruchar06 IN varchar2
,in_dtlpassthruchar07 IN varchar2
,in_dtlpassthruchar08 IN varchar2
,in_dtlpassthruchar09 IN varchar2
,in_dtlpassthruchar10 IN varchar2
,in_dtlpassthruchar11 IN varchar2
,in_dtlpassthruchar12 IN varchar2
,in_dtlpassthruchar13 IN varchar2
,in_dtlpassthruchar14 IN varchar2
,in_dtlpassthruchar15 IN varchar2
,in_dtlpassthruchar16 IN varchar2
,in_dtlpassthruchar17 IN varchar2
,in_dtlpassthruchar18 IN varchar2
,in_dtlpassthruchar19 IN varchar2
,in_dtlpassthruchar20 IN varchar2
,in_dtlpassthrunum01 IN number
,in_dtlpassthrunum02 IN number
,in_dtlpassthrunum03 IN number
,in_dtlpassthrunum04 IN number
,in_dtlpassthrunum05 IN number
,in_dtlpassthrunum06 IN number
,in_dtlpassthrunum07 IN number
,in_dtlpassthrunum08 IN number
,in_dtlpassthrunum09 IN number
,in_dtlpassthrunum10 IN number
,in_dtlpassthrudate01 IN date
,in_dtlpassthrudate02 IN date
,in_dtlpassthrudate03 IN date
,in_dtlpassthrudate04 IN date
,in_dtlpassthrudoll01 IN number
,in_dtlpassthrudoll02 IN number
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_bbb_carrier_assignment
(in_custid varchar2
,in_country_codes varchar2 -- (format: "XXX to YYY")
,in_from_state varchar2
,in_to_state varchar2
,in_ltl_carrier varchar2
,in_tl_carrier varchar2
,in_effdate_str varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure log_order_import_ack
(in_importfile in varchar2
,in_custid in varchar2
,in_po in varchar2
,in_reference in varchar2
,in_orderid in number
,in_shipid in number
,in_status in varchar2
,in_comment in varchar2
,in_action in varchar2);


procedure import_order_header_Kraft
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_ordertype IN varchar2
,in_apptdate IN date
,in_shipdate IN date
,in_po IN varchar2
,in_rma IN varchar2
,in_fromfacility IN varchar2
,in_tofacility IN varchar2
,in_shipto IN varchar2
,in_billoflading IN varchar2
,in_priority IN varchar2
,in_shipper IN varchar2
,in_consignee IN varchar2
,in_shiptype IN varchar2
,in_carrier IN varchar2
,in_reference IN varchar2
,in_shipterms IN varchar2
,in_shippername IN varchar2
,in_shippercontact IN varchar2
,in_shipperaddr1 IN varchar2
,in_shipperaddr2 IN varchar2
,in_shippercity IN varchar2
,in_shipperstate IN varchar2
,in_shipperpostalcode IN varchar2
,in_shippercountrycode IN varchar2
,in_shipperphone IN varchar2
,in_shipperfax IN varchar2
,in_shipperemail IN varchar2
,in_shiptoname IN varchar2
,in_shiptocontact IN varchar2
,in_shiptoaddr1 IN varchar2
,in_shiptoaddr2 IN varchar2
,in_shiptocity IN varchar2
,in_shiptostate IN varchar2
,in_shiptopostalcode IN varchar2
,in_shiptocountrycode IN varchar2
,in_shiptophone IN varchar2
,in_shiptofax IN varchar2
,in_shiptoemail IN varchar2
,in_billtoname IN varchar2
,in_billtocontact IN varchar2
,in_billtoaddr1 IN varchar2
,in_billtoaddr2 IN varchar2
,in_billtocity IN varchar2
,in_billtostate IN varchar2
,in_billtopostalcode IN varchar2
,in_billtocountrycode IN varchar2
,in_billtophone IN varchar2
,in_billtofax IN varchar2
,in_billtoemail IN varchar2
,in_deliveryservice IN varchar2
,in_saturdaydelivery IN varchar2
,in_cod IN varchar2
,in_amtcod IN number
,in_specialservice1 IN varchar2
,in_specialservice2 IN varchar2
,in_specialservice3 IN varchar2
,in_specialservice4 IN varchar2
,in_importfileid IN varchar2
,in_hdrpassthruchar01 IN varchar2
,in_hdrpassthruchar02 IN varchar2
,in_hdrpassthruchar03 IN varchar2
,in_hdrpassthruchar04 IN varchar2
,in_hdrpassthruchar05 IN varchar2
,in_hdrpassthruchar06 IN varchar2
,in_hdrpassthruchar07 IN varchar2
,in_hdrpassthruchar08 IN varchar2
,in_hdrpassthruchar09 IN varchar2
,in_hdrpassthruchar10 IN varchar2
,in_hdrpassthruchar11 IN varchar2
,in_hdrpassthruchar12 IN varchar2
,in_hdrpassthruchar13 IN varchar2
,in_hdrpassthruchar14 IN varchar2
,in_hdrpassthruchar15 IN varchar2
,in_hdrpassthruchar16 IN varchar2
,in_hdrpassthruchar17 IN varchar2
,in_hdrpassthruchar18 IN varchar2
,in_hdrpassthruchar19 IN varchar2
,in_hdrpassthruchar20 IN varchar2
,in_hdrpassthruchar21 IN varchar2
,in_hdrpassthruchar22 IN varchar2
,in_hdrpassthruchar23 IN varchar2
,in_hdrpassthruchar24 IN varchar2
,in_hdrpassthruchar25 IN varchar2
,in_hdrpassthruchar26 IN varchar2
,in_hdrpassthruchar27 IN varchar2
,in_hdrpassthruchar28 IN varchar2
,in_hdrpassthruchar29 IN varchar2
,in_hdrpassthruchar30 IN varchar2
,in_hdrpassthruchar31 IN varchar2
,in_hdrpassthruchar32 IN varchar2
,in_hdrpassthruchar33 IN varchar2
,in_hdrpassthruchar34 IN varchar2
,in_hdrpassthruchar35 IN varchar2
,in_hdrpassthruchar36 IN varchar2
,in_hdrpassthruchar37 IN varchar2
,in_hdrpassthruchar38 IN varchar2
,in_hdrpassthruchar39 IN varchar2
,in_hdrpassthruchar40 IN varchar2
,in_hdrpassthruchar41 IN varchar2
,in_hdrpassthruchar42 IN varchar2
,in_hdrpassthruchar43 IN varchar2
,in_hdrpassthruchar44 IN varchar2
,in_hdrpassthruchar45 IN varchar2
,in_hdrpassthruchar46 IN varchar2
,in_hdrpassthruchar47 IN varchar2
,in_hdrpassthruchar48 IN varchar2
,in_hdrpassthruchar49 IN varchar2
,in_hdrpassthruchar50 IN varchar2
,in_hdrpassthruchar51 IN varchar2
,in_hdrpassthruchar52 IN varchar2
,in_hdrpassthruchar53 IN varchar2
,in_hdrpassthruchar54 IN varchar2
,in_hdrpassthruchar55 IN varchar2
,in_hdrpassthruchar56 IN varchar2
,in_hdrpassthruchar57 IN varchar2
,in_hdrpassthruchar58 IN varchar2
,in_hdrpassthruchar59 IN varchar2
,in_hdrpassthruchar60 IN varchar2
,in_hdrpassthrunum01 IN number
,in_hdrpassthrunum02 IN number
,in_hdrpassthrunum03 IN number
,in_hdrpassthrunum04 IN number
,in_hdrpassthrunum05 IN number
,in_hdrpassthrunum06 IN number
,in_hdrpassthrunum07 IN number
,in_hdrpassthrunum08 IN number
,in_hdrpassthrunum09 IN number
,in_hdrpassthrunum10 IN number
,in_cancel_after IN date
,in_delivery_requested IN date
,in_requested_ship IN date
,in_ship_not_before IN date
,in_ship_no_later IN date
,in_cancel_if_not_delivered_by IN date
,in_do_not_deliver_after IN date
,in_do_not_deliver_before IN date
,in_hdrpassthrudate01 date
,in_hdrpassthrudate02 date
,in_hdrpassthrudate03 date
,in_hdrpassthrudate04 date
,in_hdrpassthrudoll01 number
,in_hdrpassthrudoll02 number
,in_rfautodisplay varchar2
,in_ignore_received_orders_yn varchar2
,in_arrivaldate IN DATE
,in_validate_shipto in varchar2
,in_abc_revision in varchar2
,in_prono varchar2
,in_editransaction in varchar2
,in_edi_logging_yn in varchar2
,in_futurevc01 in varchar2
,in_futurevc02 in varchar2
,in_futurevc03 in varchar2
,in_futurevc04 in varchar2
,in_futurevc05 in varchar2
,in_futurevc06 in varchar2
,in_futurenum01 in number
,in_futurenum02 in number
,in_futurenum03 in number
,in_order_acknowledgment in varchar2
,in_canceled_new_order in varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);


procedure import_order_line_Kraft
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_itementered IN varchar2
,in_lotnumber IN varchar2
,in_uomentered IN varchar2
,in_qtyentered IN number
,in_backorder IN varchar2
,in_allowsub IN varchar2
,in_qtytype IN varchar2
,in_invstatusind IN varchar2
,in_invstatus IN varchar2
,in_invclassind IN varchar2
,in_inventoryclass IN varchar2
,in_consigneesku IN varchar2
,in_dtlpassthruchar01 IN varchar2
,in_dtlpassthruchar02 IN varchar2
,in_dtlpassthruchar03 IN varchar2
,in_dtlpassthruchar04 IN varchar2
,in_dtlpassthruchar05 IN varchar2
,in_dtlpassthruchar06 IN varchar2
,in_dtlpassthruchar07 IN varchar2
,in_dtlpassthruchar08 IN varchar2
,in_dtlpassthruchar09 IN varchar2
,in_dtlpassthruchar10 IN varchar2
,in_dtlpassthruchar11 IN varchar2
,in_dtlpassthruchar12 IN varchar2
,in_dtlpassthruchar13 IN varchar2
,in_dtlpassthruchar14 IN varchar2
,in_dtlpassthruchar15 IN varchar2
,in_dtlpassthruchar16 IN varchar2
,in_dtlpassthruchar17 IN varchar2
,in_dtlpassthruchar18 IN varchar2
,in_dtlpassthruchar19 IN varchar2
,in_dtlpassthruchar20 IN varchar2
,in_dtlpassthruchar21 IN varchar2
,in_dtlpassthruchar22 IN varchar2
,in_dtlpassthruchar23 IN varchar2
,in_dtlpassthruchar24 IN varchar2
,in_dtlpassthruchar25 IN varchar2
,in_dtlpassthruchar26 IN varchar2
,in_dtlpassthruchar27 IN varchar2
,in_dtlpassthruchar28 IN varchar2
,in_dtlpassthruchar29 IN varchar2
,in_dtlpassthruchar30 IN varchar2
,in_dtlpassthruchar31 IN varchar2
,in_dtlpassthruchar32 IN varchar2
,in_dtlpassthruchar33 IN varchar2
,in_dtlpassthruchar34 IN varchar2
,in_dtlpassthruchar35 IN varchar2
,in_dtlpassthruchar36 IN varchar2
,in_dtlpassthruchar37 IN varchar2
,in_dtlpassthruchar38 IN varchar2
,in_dtlpassthruchar39 IN varchar2
,in_dtlpassthruchar40 IN varchar2
,in_dtlpassthrunum01 IN number
,in_dtlpassthrunum02 IN number
,in_dtlpassthrunum03 IN number
,in_dtlpassthrunum04 IN number
,in_dtlpassthrunum05 IN number
,in_dtlpassthrunum06 IN number
,in_dtlpassthrunum07 IN number
,in_dtlpassthrunum08 IN number
,in_dtlpassthrunum09 IN number
,in_dtlpassthrunum10 IN number
,in_dtlpassthrunum11 IN number
,in_dtlpassthrunum12 IN number
,in_dtlpassthrunum13 IN number
,in_dtlpassthrunum14 IN number
,in_dtlpassthrunum15 IN number
,in_dtlpassthrunum16 IN number
,in_dtlpassthrunum17 IN number
,in_dtlpassthrunum18 IN number
,in_dtlpassthrunum19 IN number
,in_dtlpassthrunum20 IN number
,in_dtlpassthrudate01 date
,in_dtlpassthrudate02 date
,in_dtlpassthrudate03 date
,in_dtlpassthrudate04 date
,in_dtlpassthrudoll01 number
,in_dtlpassthrudoll02 number
,in_rfautodisplay varchar2
,in_comment long
,in_weight_entered_lbs number
,in_weight_entered_kgs number
,in_variance_pct_shortage number
,in_variance_pct_overage number
,in_variance_use_default_yn varchar2
,in_abc_revision in varchar2
,in_header_carrier varchar2
,in_lineorder varchar2
,in_cancel_productgroup varchar2
,in_invclass_states in varchar2
,in_invclass_states_value in varchar2
,in_upper_item_yn varchar2
,in_order_acknowledgment varchar2
,in_importfileid IN varchar2
,in_notnullpassthrus_yn IN varchar2
,in_delete_by_linenumber_yn in varchar2
,in_weight_acceptance_yn in varchar2
,in_dtl_passthru_item_xref in varchar2
,in_itm_passthru_item_xref in varchar2
,in_canceled_new_order in varchar2
,in_up_to_base_yn in varchar2
,in_style_color_size_columns IN varchar2
,in_editransaction IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_order_hdr_notes_Kraft
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_qualifier IN varchar2
,in_note  IN varchar2
,in_abc_revision IN varchar2
,in_ordertype IN varchar2
,in_comment_type IN varchar2
,in_editransaction IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);
end zimportprocs;
/
show error package zimportprocs;
exit;
