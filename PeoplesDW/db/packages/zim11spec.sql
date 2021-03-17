create or replace PACKAGE alps.zimportproc11
--
-- $Id$
--

Is

procedure import_carrier
(in_carrier IN varchar2
,in_carrierstatus IN varchar2
,in_scac IN varchar2
,in_name IN varchar2
,in_contact IN varchar2
,in_addr1 IN varchar2
,in_addr2 IN varchar2
,in_city IN varchar2
,in_state IN varchar2
,in_postalcode IN varchar2
,in_countrycode IN varchar2
,in_phone IN varchar2
,in_fax IN varchar2
,in_email IN varchar2
,in_carriertype IN varchar2
,in_multiship IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_section
(in_facility IN varchar2
,in_sectionid IN varchar2
,in_sectionnw IN varchar2
,in_sectionn IN varchar2
,in_sectionne IN varchar2
,in_sectione IN varchar2
,in_sectionse IN varchar2
,in_sections IN varchar2
,in_sectionsw IN varchar2
,in_sectionw IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);


procedure import_zones
(in_facility IN varchar2
,in_zoneid IN varchar2
,in_description IN varchar2
,in_panddlocation IN varchar2
,in_picktype IN varchar2
,in_pickdirection IN varchar2
,in_nextlinepickby IN varchar2
,in_abbrev IN varchar2
,in_pickconfirmlocation IN varchar2
,in_pickconfirmitem IN varchar2
,in_pickconfirmcontainer IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_customernames
(in_custid IN varchar2
,in_status IN varchar2
,in_name IN varchar2
,in_lookup IN varchar2
,in_contact IN varchar2
,in_addr1 IN varchar2
,in_addr2 IN varchar2
,in_city IN varchar2
,in_state IN varchar2
,in_postalcode IN varchar2
,in_countrycode IN varchar2
,in_phone IN varchar2
,in_fax IN varchar2
,in_email IN varchar2
,in_csr IN varchar2
,in_dup_reference_ynw IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_shippingoptions1
(in_custid IN varchar2
,in_item IN varchar2
,in_backorder IN varchar2
,in_allowsub IN varchar2
,in_invstatusind IN varchar2
,in_invstatus IN varchar2
,in_invclassind IN varchar2
,in_inventoryclass IN varchar2
,in_fifowindowdays IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_itemshipopt1_validation
(in_custid IN varchar2
,in_item IN varchar2
,in_backorder IN varchar2
,in_allowsub IN varchar2
,in_invstatusind IN varchar2
,in_invstatus IN varchar2
,in_invclassind IN varchar2
,in_inventoryclass IN varchar2
,in_fifowindowdays IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure end_itemshipopt1_validation
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure import_custdictionary
(in_custid IN varchar2
,in_fieldname IN varchar2
,in_labelvalue IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_consigneename
(in_consignee IN varchar2
,in_consigneestatus IN varchar2
,in_name IN varchar2
,in_contact IN varchar2
,in_addr1 IN varchar2
,in_addr2 IN varchar2
,in_city IN varchar2
,in_state IN varchar2
,in_postalcode IN varchar2
,in_countrycode IN varchar2
,in_phone IN varchar2
,in_fax IN varchar2
,in_email IN varchar2
,in_billto IN varchar2
,in_shipto IN varchar2
,in_billtoconsignee IN varchar2
,in_shiptype IN varchar2
,in_shipterms IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_consigneecarriers
(in_consignee IN varchar2
,in_tlcarrier IN varchar2
,in_ltlcarrier IN varchar2
,in_spscarrier IN varchar2
,in_railcarrier IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_itemname
(in_custid IN varchar2
,in_item IN varchar2
,in_descr IN varchar2
,in_abbrev IN varchar2
,in_rategroup IN varchar2
,in_status IN varchar2
,in_needs_review_yn IN varchar2
,in_iskit IN varchar2
,in_require_cyclecount_item IN varchar2
,in_require_cyclecount_lot IN varchar2
,in_require_phyinv_item IN varchar2
,in_require_phyinv_lot IN varchar2 
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_itemname_validation
(in_custid IN varchar2
,in_item IN varchar2
,in_descr IN varchar2
,in_abbrev IN varchar2
,in_rategroup IN varchar2
,in_status IN varchar2
,in_needs_review_yn IN varchar2
,in_iskit IN varchar2
,in_require_cyclecount_item IN varchar2
,in_require_cyclecount_lot IN varchar2
,in_require_phyinv_item IN varchar2
,in_require_phyinv_lot IN varchar2 
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure end_itemname_validataion
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure import_itemspecs
(in_custid IN varchar2
,in_item IN varchar2
,in_shelflife IN number
,in_expiryaction IN varchar2
,in_profid IN varchar2
,in_labeluom IN varchar2
,in_productgroup IN varchar2
,in_nmfc IN varchar2
,in_lotsumreceipt IN varchar2
,in_lotsumrenewal IN varchar2
,in_lotsumbol IN varchar2
,in_lotsumaccess IN varchar2
,in_ltlfc IN varchar2
,in_countryof IN varchar2
,in_hazardous IN varchar2
,in_stackheight IN number
,in_stackheightuom in varchar2
,in_reorderqty IN number
,in_unitsofstorage IN varchar2
,in_nmfc_article IN varchar2
,in_tms_commodity_code IN varchar2
,in_itmpassthruchar01 IN varchar2
,in_itmpassthruchar02 IN varchar2
,in_itmpassthruchar03 IN varchar2
,in_itmpassthruchar04 IN varchar2
,in_itmpassthruchar05 IN varchar2
,in_itmpassthruchar06 IN varchar2
,in_itmpassthruchar07 IN varchar2
,in_itmpassthruchar08 IN varchar2
,in_itmpassthruchar09 IN varchar2
,in_itmpassthruchar10 IN varchar2
,in_itmpassthrunum01 IN number
,in_itmpassthrunum02 IN number
,in_itmpassthrunum03 IN number
,in_itmpassthrunum04 IN number
,in_itmpassthrunum05 IN number
,in_itmpassthrunum06 IN number
,in_itmpassthrunum07 IN number
,in_itmpassthrunum08 IN number
,in_itmpassthrunum09 IN number
,in_itmpassthrunum10 IN number
,in_use_fifo IN varchar2
,in_labelqty IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_itemspecs_validation
(in_custid IN varchar2
,in_item IN varchar2
,in_shelflife IN number
,in_expiryaction IN varchar2
,in_profid IN varchar2
,in_labeluom IN varchar2
,in_productgroup IN varchar2
,in_nmfc IN varchar2
,in_lotsumreceipt IN varchar2
,in_lotsumrenewal IN varchar2
,in_lotsumbol IN varchar2
,in_lotsumaccess IN varchar2
,in_ltlfc IN varchar2
,in_countryof IN varchar2
,in_hazardous IN varchar2
,in_stackheight IN number
,in_stackheightuom in varchar2
,in_reorderqty IN number
,in_unitsofstorage IN varchar2
,in_nmfc_article IN varchar2
,in_tms_commodity_code IN varchar2
,in_itmpassthruchar01 IN varchar2
,in_itmpassthruchar02 IN varchar2
,in_itmpassthruchar03 IN varchar2
,in_itmpassthruchar04 IN varchar2
,in_itmpassthruchar05 IN varchar2
,in_itmpassthruchar06 IN varchar2
,in_itmpassthruchar07 IN varchar2
,in_itmpassthruchar08 IN varchar2
,in_itmpassthruchar09 IN varchar2
,in_itmpassthruchar10 IN varchar2
,in_itmpassthrunum01 IN number
,in_itmpassthrunum02 IN number
,in_itmpassthrunum03 IN number
,in_itmpassthrunum04 IN number
,in_itmpassthrunum05 IN number
,in_itmpassthrunum06 IN number
,in_itmpassthrunum07 IN number
,in_itmpassthrunum08 IN number
,in_itmpassthrunum09 IN number
,in_itmpassthrunum10 IN number
,in_use_fifo IN varchar2
,in_labelqty IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure end_itemspecs_validataion
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure import_itemspecs2
(in_custid IN varchar2
,in_item IN varchar2
,in_allow_uom_chgs IN varchar2
,in_min_sale_life IN NUMBER
,in_min0qtysuspenseweight IN NUMBER
,in_stacking_factor IN varchar2
,in_treat_labeluom_separate IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure import_itemspecs2_validation
(
in_custid IN varchar2
,in_item IN varchar2
,in_allow_uom_chgs IN varchar2
,in_min_sale_life IN NUMBER
,in_min0qtysuspenseweight IN NUMBER
,in_stacking_factor IN varchar2
,in_treat_labeluom_separate IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure end_itemspecs2_validataion
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure import_itembaseuom
(in_custid IN varchar2
,in_item IN varchar2
,in_baseuom IN varchar2
,in_weight IN number
,in_cube IN number
,in_useramt1 IN number
,in_useramt2 IN number
,in_tareweight IN number
,in_velocity IN varchar2
,in_picktotype IN varchar2
,in_cartontype IN varchar2
,in_length IN number
,in_width IN number
,in_height IN number
,in_pallet_qty IN number
,in_pallet_uom IN varchar2
,in_pallet_name IN varchar2
,in_limit_pallet_to_qty_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure import_itembaseuom_validation
(in_custid IN varchar2
,in_item IN varchar2
,in_baseuom IN varchar2
,in_weight IN number
,in_cube IN number
,in_useramt1 IN number
,in_useramt2 IN number
,in_tareweight IN number
,in_velocity IN varchar2
,in_picktotype IN varchar2
,in_cartontype IN varchar2
,in_length IN number
,in_width IN number
,in_height IN number
,in_pallet_qty IN number
,in_pallet_uom IN varchar2
,in_pallet_name IN varchar2
,in_limit_pallet_to_qty_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure end_itembaseuom_validataion
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_itemuomsequences
(in_custid IN varchar2
,in_item IN varchar2
,in_sequence IN number
,in_qty IN number
,in_fromuom IN varchar2
,in_touom IN varchar2
,in_cube IN number
,in_picktotype IN varchar2
,in_velocity IN varchar2
,in_weight IN number
,in_cartontype IN varchar2
,in_length IN number
,in_width IN number
,in_height IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_itemuomseq_validation
(in_custid IN varchar2
,in_item IN varchar2
,in_sequence IN number
,in_qty IN number
,in_fromuom IN varchar2
,in_touom IN varchar2
,in_cube IN number
,in_picktotype IN varchar2
,in_velocity IN varchar2
,in_weight IN number
,in_cartontype IN varchar2
,in_length IN number
,in_width IN number
,in_height IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure end_itemuomseq_validataion
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure import_itemrecoptions1
(in_custid IN varchar2
,in_item IN varchar2
,in_lotrequired IN varchar2
,in_lotrftag IN varchar2
,in_serialrequired IN varchar2
,in_serialrftag IN varchar2
,in_user1required IN varchar2
,in_user1rftag IN varchar2
,in_user2required IN varchar2
,in_user2rftag IN varchar2
,in_user3required IN varchar2
,in_user3rftag IN varchar2
,in_mfgdaterequired IN varchar2
,in_expdaterequired IN varchar2
,in_countryrequired IN varchar2
,in_use_catch_weights IN varchar2
,in_catch_weight_in_cap_type IN varchar2
,in_catch_weight_out_cap_type IN varchar2
,in_capture_pickuom IN varchar2
,in_bulkcount_expdaterequired IN varchar2
,in_bulkcount_mfgdaterequired IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure end_itemrecopt1_validation
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure import_itemrecopt1_validation
(in_custid IN varchar2
,in_item IN varchar2
,in_lotrequired IN varchar2
,in_lotrftag IN varchar2
,in_serialrequired IN varchar2
,in_serialrftag IN varchar2
,in_user1required IN varchar2
,in_user1rftag IN varchar2
,in_user2required IN varchar2
,in_user2rftag IN varchar2
,in_user3required IN varchar2
,in_user3rftag IN varchar2
,in_mfgdaterequired IN varchar2
,in_expdaterequired IN varchar2
,in_countryrequired IN varchar2
,in_use_catch_weights IN varchar2
,in_catch_weight_in_cap_type IN varchar2
,in_catch_weight_out_cap_type IN varchar2
,in_capture_pickuom IN varchar2
,in_bulkcount_expdaterequired IN varchar2
,in_bulkcount_mfgdaterequired IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_itemvalidation
(in_custid IN varchar2
,in_item IN varchar2
,in_lotfmtruleid IN varchar2
,in_lotfmtaction IN varchar2
,in_serialfmtruleid IN varchar2
,in_serialfmtaction IN varchar2
,in_user1fmtruleid IN varchar2
,in_user1fmtaction IN varchar2
,in_user2fmtruleid IN varchar2
,in_user2fmtaction IN varchar2
,in_user3fmtruleid IN varchar2
,in_user3fmtaction IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_itemval_validation
(in_custid IN varchar2
,in_item IN varchar2
,in_lotfmtruleid IN varchar2
,in_lotfmtaction IN varchar2
,in_serialfmtruleid IN varchar2
,in_serialfmtaction IN varchar2
,in_user1fmtruleid IN varchar2
,in_user1fmtaction IN varchar2
,in_user2fmtruleid IN varchar2
,in_user2fmtaction IN varchar2
,in_user3fmtruleid IN varchar2
,in_user3fmtaction IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure end_itemval_validation
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure import_itemrecoptions2
(in_custid IN varchar2
,in_item IN varchar2
,in_nodamaged IN varchar2
,in_recinvstatus IN varchar2
,in_putawayconfirmation IN varchar2
,in_critlevel1 IN number
,in_critlevel2 IN number
,in_critlevel3 IN number
,in_parseruleaction IN varchar2
,in_parseruleid IN varchar2
,in_parseentryfield IN varchar2
,in_putaway_highest_wholeuom_yn IN varchar2
,in_returnsdisposition IN varchar2
,in_warnshortlp IN varchar2
,in_warnshortlpqty IN number
,in_disallowoverbuiltlp IN varchar2
,in_maxqtyof1 IN varchar2
,in_nomixeditemlp IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure import_itemrecopt2_validation
(in_custid IN varchar2
,in_item IN varchar2
,in_nodamaged IN varchar2
,in_recinvstatus IN varchar2
,in_putawayconfirmation IN varchar2
,in_critlevel1 IN number
,in_critlevel2 IN number
,in_critlevel3 IN number
,in_parseruleaction IN varchar2
,in_parseruleid IN varchar2
,in_parseentryfield IN varchar2
,in_putaway_highest_wholeuom_yn IN varchar2
,in_returnsdisposition IN varchar2
,in_warnshortlp IN varchar2
,in_warnshortlpqty IN number
,in_disallowoverbuiltlp IN varchar2
,in_maxqtyof1 IN varchar2
,in_nomixeditemlp IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure end_itemrecopt2_validation
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure import_itemrecoptions3
(in_custid             IN varchar2
,in_item               IN varchar2
,in_serialasncapture   IN varchar2
,in_user1asncapture    IN varchar2
,in_user2asncapture    IN varchar2
,in_user3asncapture    IN varchar2
,in_lot_seq_max        IN number
,in_lot_seq_min        IN number
,in_lot_seq_name       IN varchar2
,in_serial_seq_max     IN number
,in_serial_seq_min     IN number
,in_serial_seq_name    IN varchar2
,in_useritem1_seq_max  IN number
,in_useritem1_seq_min  IN number
,in_useritem1_seq_name IN varchar2
,in_useritem2_seq_max  IN number
,in_useritem2_seq_min  IN number
,in_useritem2_seq_name IN varchar2
,in_useritem3_seq_max  IN number
,in_useritem3_seq_min  IN number
,in_useritem3_seq_name IN varchar2
,out_errorno           IN OUT number
,out_msg               IN OUT varchar2
);
procedure import_itemrecopt3_validation
(in_custid             IN varchar2
,in_item               IN varchar2
,in_serialasncapture   IN varchar2
,in_user1asncapture    IN varchar2
,in_user2asncapture    IN varchar2
,in_user3asncapture    IN varchar2
,in_lot_seq_max        IN number
,in_lot_seq_min        IN number
,in_lot_seq_name       IN varchar2
,in_serial_seq_max     IN number
,in_serial_seq_min     IN number
,in_serial_seq_name    IN varchar2
,in_useritem1_seq_max  IN number
,in_useritem1_seq_min  IN number
,in_useritem1_seq_name IN varchar2
,in_useritem2_seq_max  IN number
,in_useritem2_seq_min  IN number
,in_useritem2_seq_name IN varchar2
,in_useritem3_seq_max  IN number
,in_useritem3_seq_min  IN number
,in_useritem3_seq_name IN varchar2
,out_errorno           IN OUT number
,out_msg               IN OUT varchar2
);
procedure end_itemrecopt3_validation
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_itemfacilitysettings
(in_custid IN varchar2
,in_item IN varchar2
,in_facility   IN varchar2
,in_allocrule  IN varchar2
,in_replenrule IN varchar2
,in_putawayprofile IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure import_itemfacset_validation
(in_custid IN varchar2
,in_item IN varchar2
,in_facility   IN varchar2
,in_allocrule  IN varchar2
,in_replenrule IN varchar2
,in_putawayprofile IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure end_itemfacset_validation
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_itemhazardsettings
(in_custid IN varchar2
,in_item IN varchar2
,in_hazardflag  IN varchar2
,in_hazardclass IN varchar2
,in_primarychemcode IN varchar2
,in_secondarychemcode IN varchar2
,in_tertiarychemcode IN varchar2
,in_quaternarychemcode IN varchar2
,in_imoprimarychemcode IN varchar2
,in_imosecondarychemcode IN varchar2
,in_imotertiarychemcode IN varchar2
,in_imoquaternarychemcode IN varchar2
,in_iataprimarychemcode IN varchar2
,in_iatasecondarychemcode IN varchar2
,in_iatatertiarychemcode IN varchar2
,in_iataquaternarychemcode IN varchar2
,in_printmsds IN varchar2
,in_msdsformat IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_itemhazset_validation
(in_custid IN varchar2
,in_item IN varchar2
,in_hazardflag  IN varchar2
,in_hazardclass IN varchar2
,in_primarychemcode IN varchar2
,in_secondarychemcode IN varchar2
,in_tertiarychemcode IN varchar2
,in_quaternarychemcode IN varchar2
,in_imoprimarychemcode IN varchar2
,in_imosecondarychemcode IN varchar2
,in_imotertiarychemcode IN varchar2
,in_imoquaternarychemcode IN varchar2
,in_iataprimarychemcode IN varchar2
,in_iatasecondarychemcode IN varchar2
,in_iatatertiarychemcode IN varchar2
,in_iataquaternarychemcode IN varchar2
,in_printmsds IN varchar2
,in_msdsformat IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure end_itemhazset_validation
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure import_itemshippingoptions2
(in_custid IN varchar2
,in_item IN varchar2
,in_allocrule IN varchar2
,in_qtytype IN varchar2
,in_variancepct IN number
,in_weightcheckrequired IN varchar2
,in_subslprsnrequired IN varchar2
,in_use_min_units_qty IN varchar2
,in_min_units_qty IN number
,in_use_multiple_units_qty IN varchar2
,in_multiple_units_qty IN number
,in_sip_carton_uom IN varchar2
,in_tms_uom IN varchar2
,in_track_picked_pf_lps IN varchar2
,in_variancepct_use_default IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure import_itemshipopt2_validation
(in_custid IN varchar2
,in_item IN varchar2
,in_allocrule IN varchar2
,in_qtytype IN varchar2
,in_variancepct IN number
,in_weightcheckrequired IN varchar2
,in_subslprsnrequired IN varchar2
,in_use_min_units_qty IN varchar2
,in_min_units_qty IN number
,in_use_multiple_units_qty IN varchar2
,in_multiple_units_qty IN number
,in_sip_carton_uom IN varchar2
,in_tms_uom IN varchar2
,in_track_picked_pf_lps IN varchar2
,in_variancepct_use_default IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure end_itemshipopt2_validation
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_itemstorage
(in_custid IN varchar2
,in_item IN varchar2
,in_uomseq IN number
,in_unitofmeasure IN varchar2
,in_uosseq IN number
,in_unitofstorage IN varchar2
,in_uominuos IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_itemaliases
(in_custid IN varchar2
,in_item IN varchar2
,in_itemalias IN varchar2
,in_aliasdesc IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_custitemuomuos
(in_custid IN varchar2
,in_item IN varchar2
,in_uomseq IN number
,in_unitofmeasure IN varchar2
,in_uosseq IN number
,in_unitofstorage IN varchar2
,in_uominuos IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_custitemnmfc
(in_custid IN varchar2
,in_item IN varchar2
,in_NMFC IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_itemhandling
(in_custid                      IN varchar2
,in_item                        IN varchar2
,in_locstchg_loctype            IN varchar2
,in_locstchg_excl_tasktypes     IN varchar2
,in_locstchg_entry_invstatu     IN varchar2
,in_locstchg_entry_adjreasn     IN varchar2
,in_locstchg_exit_invstatus     IN varchar2
,in_locstchg_exit_adjreason   IN varchar2
,out_errorno                    IN OUT NUMBER
,out_msg                        IN OUT varchar2
);
procedure import_itemhandling_validation
(in_custid                      IN varchar2
,in_item                        IN varchar2
,in_locstchg_loctype            IN varchar2
,in_locstchg_excl_tasktypes     IN varchar2
,in_locstchg_entry_invstatu     IN varchar2
,in_locstchg_entry_adjreasn     IN varchar2
,in_locstchg_exit_invstatus     IN varchar2
,in_locstchg_exit_adjreason IN varchar2
,out_errorno                    IN OUT NUMBER
,out_msg                        IN OUT varchar2
);
procedure end_itemhandling_validation
(in_update   IN varchar2
,out_errorno IN OUT NUMBER
,out_msg     IN OUT varchar2
);
procedure import_itemlabel
(in_custid                 IN varchar2
,in_item                   IN varchar2
,in_labelprofile           IN varchar2
,in_prtlps_on_load_arrival IN varchar2
,in_system_generated_lps   IN varchar2
,in_prtlps_profid          IN varchar2
,in_prtlps_def_handling    IN varchar2
,in_sscccasepackfromuom    IN varchar2
,in_sscccasepacktouom      IN varchar2
,in_prtlps_putaway_dir     IN varchar2
,out_errorno               IN OUT number
,out_msg                   IN OUT varchar2
);
procedure import_itemlabel_validation
(in_custid                 IN varchar2
,in_item                   IN varchar2
,in_labelprofile           IN varchar2
,in_prtlps_on_load_arrival IN varchar2
,in_system_generated_lps   IN varchar2
,in_prtlps_profid          IN varchar2
,in_prtlps_def_handling    IN varchar2
,in_sscccasepackfromuom    IN varchar2
,in_sscccasepacktouom      IN varchar2
,in_prtlps_putaway_dir     IN varchar2
,out_errorno               IN OUT number
,out_msg                   IN OUT varchar2
);
procedure end_itemlabel_validation
(in_update   IN varchar2
,out_errorno IN OUT number
,out_msg     IN OUT varchar2
);
end zimportproc11;
/
show error package zimportproc11;
--exit;
