--
-- $Id$
--
create or replace PACKAGE alps.zimportprocsb

is

procedure import_832_item
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_item IN varchar2
,in_descr IN varchar2
,in_abbrev IN OUT varchar2
,in_baseuom IN varchar2
,in_cube IN number
,in_weight IN number
,in_tareweight IN number
,in_hazardous IN varchar2
,in_to_uom1 IN varchar2
,in_to_uom1_qty IN number
,in_to_uom1_weight IN number
,in_to_uom1_cube IN number
,in_to_uom1_length IN number
,in_to_uom1_width IN number
,in_to_uom1_height IN number
,in_velocity1 IN varchar2
,in_picktotype1 IN varchar2
,in_cartontype1 IN varchar2
,in_to_uom2 IN varchar2
,in_to_uom2_qty IN number
,in_to_uom2_weight IN number
,in_to_uom2_cube IN number
,in_to_uom2_length IN number
,in_to_uom2_width IN number
,in_to_uom2_height IN number
,in_velocity2 IN varchar2
,in_picktotype2 IN varchar2
,in_cartontype2 IN varchar2
,in_to_uom3 IN varchar2
,in_to_uom3_qty IN number
,in_to_uom3_weight IN number
,in_to_uom3_cube IN number
,in_to_uom3_length IN number
,in_to_uom3_width IN number
,in_to_uom3_height IN number
,in_velocity3 IN varchar2
,in_picktotype3 IN varchar2
,in_cartontype3 IN varchar2
,in_to_uom4 IN varchar2
,in_to_uom4_qty IN number
,in_to_uom4_weight IN number
,in_to_uom4_cube IN number
,in_to_uom4_length IN number
,in_to_uom4_width IN number
,in_to_uom4_height IN number
,in_velocity4 IN varchar2
,in_picktotype4 IN varchar2
,in_cartontype4 IN varchar2
,in_to_uom5 IN varchar2
,in_to_uom5_qty IN number
,in_to_uom5_weight IN number
,in_to_uom5_cube IN number
,in_to_uom5_length IN number
,in_to_uom5_width IN number
,in_to_uom5_height IN number
,in_velocity5 IN varchar2
,in_picktotype5 IN varchar2
,in_cartontype5 IN varchar2
,in_to_uom6 IN varchar2
,in_to_uom6_qty IN number
,in_to_uom6_weight IN number
,in_to_uom6_cube IN number
,in_to_uom6_length IN number
,in_to_uom6_width IN number
,in_to_uom6_height IN number
,in_velocity6 IN varchar2
,in_picktotype6 IN varchar2
,in_cartontype6 IN varchar2
,in_to_uom7 IN varchar2
,in_to_uom7_qty IN number
,in_to_uom7_weight IN number
,in_to_uom7_cube IN number
,in_to_uom7_length IN number
,in_to_uom7_width IN number
,in_to_uom7_height IN number
,in_velocity7 IN varchar2
,in_picktotype7 IN varchar2
,in_cartontype7 IN varchar2
,in_to_uom8 IN varchar2
,in_to_uom8_qty IN number
,in_to_uom8_weight IN number
,in_to_uom8_cube IN number
,in_to_uom8_length IN number
,in_to_uom8_width IN number
,in_to_uom8_height IN number
,in_velocity8 IN varchar2
,in_picktotype8 IN varchar2
,in_cartontype8 IN varchar2
,in_to_uom9 IN varchar2
,in_to_uom9_qty IN number
,in_to_uom9_weight IN number
,in_to_uom9_cube IN number
,in_to_uom9_length IN number
,in_to_uom9_width IN number
,in_to_uom9_height IN number
,in_velocity9 IN varchar2
,in_picktotype9 IN varchar2
,in_cartontype9 IN varchar2
,in_to_uom10 IN varchar2
,in_to_uom10_qty IN number
,in_to_uom10_weight IN number
,in_to_uom10_cube IN number
,in_to_uom10_length IN number
,in_to_uom10_width IN number
,in_to_uom10_height IN number
,in_velocity10 IN varchar2
,in_picktotype10 IN varchar2
,in_cartontype10 IN varchar2
,in_shelflife IN number
,in_countryof IN varchar2
,in_bolcomment IN varchar2
,in_alias IN varchar2
,in_aliasdesc IN varchar2
,in_alias_partial_match_yn IN varchar2
,in_alias2 IN varchar2
,in_alias2desc IN varchar2
,in_alias2_partial_match_yn IN varchar2
,in_alias3 IN varchar2
,in_alias3desc IN varchar2
,in_alias3_partial_match_yn IN varchar2
,in_alias4 IN varchar2
,in_alias4desc IN varchar2
,in_alias4_partial_match_yn IN varchar2
,in_alias5 IN varchar2
,in_alias5desc IN varchar2
,in_alias5_partial_match_yn IN varchar2
,in_alias6 IN varchar2
,in_alias6desc IN varchar2
,in_alias6_partial_match_yn IN varchar2
,in_alias7 IN varchar2
,in_alias7desc IN varchar2
,in_alias7_partial_match_yn IN varchar2
,in_alias8 IN varchar2
,in_alias8desc IN varchar2
,in_alias8_partial_match_yn IN varchar2
,in_add_status IN varchar2
,in_delete_status IN varchar2
,in_add_review_yn IN varchar2
,in_update_review_yn IN varchar2
,in_delete_review_yn IN varchar2
,in_length IN number
,in_width IN number
,in_height IN number
,in_tms_commodity_code IN varchar2
,in_nmfc IN varchar2
,in_nmfc_article IN varchar2
,in_useramt1 IN number
,in_useramt2 IN number
,in_uom_update IN varchar2
,in_passthrunum01  IN  number
,in_passthrunum02  IN  number
,in_passthrunum03  IN  number
,in_passthrunum04  IN  number
,in_passthrunum05  IN  number
,in_passthrunum06  IN  number
,in_passthrunum07  IN  number
,in_passthrunum08  IN  number
,in_passthrunum09  IN  number
,in_passthrunum10  IN  number
,in_passthruchar01  IN varchar2
,in_passthruchar02  IN varchar2
,in_passthruchar03  IN varchar2
,in_passthruchar04  IN varchar2
,in_passthruchar05  IN varchar2
,in_passthruchar06  IN varchar2
,in_passthruchar07  IN varchar2
,in_passthruchar08  IN varchar2
,in_passthruchar09  IN varchar2
,in_passthruchar10  IN varchar2
,in_productgroup    IN varchar2
,in_recvinvstatus   IN varchar2
,in_lotrequired IN varchar2
,in_serialrequired IN varchar2
,in_user1required IN varchar2
,in_user2required IN varchar2
,in_user3required IN varchar2
,in_mfgdaterequired IN varchar2
,in_expdaterequired IN varchar2
,in_countryrequired IN varchar2
,in_allowsub IN varchar2
,in_backorder IN varchar2
,in_invstatusind IN varchar2
,in_invclassind IN varchar2
,in_qtytype IN varchar2
,in_weightcheckrequired IN varchar2
,in_ordercheckrequired IN varchar2
,in_fifowindowdays IN number
,in_putawayconfirmation IN varchar2
,in_velocity IN varchar2
,in_nodamaged IN varchar2
,in_iskit IN varchar2
,in_picktotype IN varchar2
,in_cartontype      IN varchar2
,in_subslprsnrequired      IN varchar2
,in_lotsumreceipt      IN varchar2
,in_lotsumrenewal      IN varchar2
,in_lotsumbol      IN varchar2
,in_lotsumaccess      IN varchar2
,in_lotfmtaction      IN varchar2
,in_serialfmtaction      IN varchar2
,in_user1fmtaction      IN varchar2
,in_user2fmtaction      IN varchar2
,in_user3fmtaction      IN varchar2
,in_maxqtyof1      IN varchar2
,in_rategroup      IN varchar2
,in_serialasncapture      IN varchar2
,in_user1asncapture      IN varchar2
,in_user2asncapture      IN varchar2
,in_user3asncapture      IN varchar2
,in_style_color_size_columns IN varchar2
,in_table_changes IN varchar2
,in_importfileid IN varchar2
,in_ignore_to_uom in varchar2
,in_labelqty IN number
,in_labeluom IN varchar2
,in_allow_uom_chgs IN varchar2
,in_use_zero_as_null IN varchar2
,in_lotfmtruleid IN varchar2
,in_serialfmtruleid IN varchar2
,in_user1fmtruleid IN varchar2
,in_user2fmtruleid IN varchar2
,in_user3fmtruleid IN varchar2
,in_inventoryclass IN varchar2
,in_invstatus IN varchar2
,in_use_fifo IN varchar2
,in_parseruleid IN varchar2
,in_parseentryfield IN varchar2
,in_parseruleaction IN varchar2
,in_update_existing_item_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_832_component
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_item IN varchar2
,in_component IN varchar2
,in_qty IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
FUNCTION order_count_on_load
(in_loadno IN number
) return number;

FUNCTION order_seq_on_load
(in_loadno IN number
,in_orderid IN number
,in_shipid IN number
) return number;

PRAGMA RESTRICT_REFERENCES (order_count_on_load, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (order_seq_on_load, WNDS, WNPS, RNPS);

end zimportprocsb;
/
show error package zimportprocsb;
exit;
