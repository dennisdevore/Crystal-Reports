--
-- $Id$
--
create or replace PACKAGE alps.zimportproc2

Is

procedure import_location
(in_facility in varchar2
,in_location in varchar2
,in_loctype in varchar2
,in_storagetype in varchar2
,in_section in varchar2
,in_checkdigit in varchar2
,in_status in varchar2
,in_pickingseq in number
,in_pickingzone in varchar2
,in_putawayseq in number
,in_putawayzone in varchar2
,in_inboundzone in varchar2
,in_outboundzone in varchar2
,in_panddlocation in varchar2
,in_equipprof in varchar2
,in_velocity in varchar2
,in_mixeditemsok in varchar2
,in_mixedlotsok in varchar2
,in_mixeduomok in varchar2
,in_countinterval in number
,in_unitofstorage in varchar2
,in_descr in varchar2
,in_weightlimit in number
,in_aisle in varchar2
,in_mixedcustsok in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_loc_with_validation
(in_locid in varchar2
,in_facility in varchar2
,in_loctype in varchar2
,in_storagetype in varchar2
,in_section in varchar2
,in_checkdigit in varchar2
,in_status in varchar2
,in_pickingseq in number
,in_pickingzone in varchar2
,in_putawayseq in number
,in_putawayzone in varchar2
,in_inboundzone in varchar2
,in_outboundzone in varchar2
,in_panddlocation in varchar2
,in_equipprof in varchar2
,in_velocity in varchar2
,in_mixeditemsok in varchar2
,in_mixedlotsok in varchar2
,in_mixeduomok in varchar2
,in_countinterval in number
,in_unitofstorage in varchar2
,in_descr in varchar2
,in_weightlimit in number
,in_aisle in varchar2
,in_stackheight in number
,in_count_after_pick in varchar2
,in_mixedcustsok in varchar2
,out_errorno in out number
,out_msg in out varchar2
);
procedure end_import_loc
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure aip_import_inventory
(in_location in varchar2
,in_serialno in varchar2
,in_batch_lot in varchar2
,in_warehouse in varchar2
,in_lm_locn in varchar2
,in_item in varchar2
,in_itemdsc in varchar2
,in_qty in number
,in_rcptno in varchar2
,in_rcptdate in date
,in_custid in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_inventory
(in_location in varchar2
,in_lpid in varchar2
,in_batch_lot in varchar2
,in_warehouse in varchar2
,in_item in varchar2
,in_itemdsc in varchar2
,in_uom in varchar2
,in_qty in number
,in_rcptno in varchar2
,in_rcptdate in date
,in_custid in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_ship_sum
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_ship_sum
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_shipsum
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_shipsum
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_rcptnote
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_rcptnote
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_stockstat
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_alias_descr IN varchar2
,in_exclude_zero_bal_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_stockstat
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_order_attach_import
(in_custid IN varchar2
,in_short_filename IN varchar2
,in_filename IN varchar2
,in_order_attach_dir IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_stockstat_gt
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_facility IN varchar2
,in_exclude_zero IN VARCHAR2
,in_exclude_open_receipts IN VARCHAR2
,in_partner_edi_code IN varchar2
,in_sender_edi_code IN varchar2
,in_app_sender_code IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_stockstat_gt
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_stockstat_ks
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_facility IN varchar2
,in_freezer_id IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_stockstat_ks
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_ordstat870
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_bol_tracking_yn IN varchar2
,in_shipment_column IN varchar2
,in_aux_shipment_column IN varchar2
,in_masterbol_column IN varchar2
,in_track_separator IN varchar2
,in_force_estdelivery_yn IN varchar2
,in_estdelivery_validation_tbl in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_ordstat870
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

end zimportproc2;
/
show error package zimportproc2;
exit;
