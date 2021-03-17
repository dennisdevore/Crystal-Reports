create or replace
PACKAGE      zimportprocweberitem IS
	--
	-- $Id: zimportprocweberitemspec.sql 219 2005-10-04 11:33:19Z ed $
	--

	PROCEDURE weber_import_item
	(
		in_func IN OUT VARCHAR2, in_custid IN VARCHAR2, in_item IN VARCHAR2,
		in_descr IN VARCHAR2, in_abbrev IN OUT VARCHAR2, in_baseuom IN VARCHAR2, in_stackheightuom IN VARCHAR2, in_cube IN NUMBER, in_weight IN NUMBER, in_hazardous IN VARCHAR2, in_lotrequired IN VARCHAR2, in_serialrequired IN VARCHAR2, in_user1required IN VARCHAR2, in_user2required IN VARCHAR2, in_user3required IN VARCHAR2, in_mfgdaterequired IN VARCHAR2, in_expdaterequired IN VARCHAR2, in_countryrequired IN VARCHAR2, in_to_uom1 IN VARCHAR2, in_to_uom1_qty IN NUMBER, in_to_uom2 IN VARCHAR2, in_to_uom2_qty IN NUMBER, in_to_uom3 IN VARCHAR2, in_to_uom3_qty IN NUMBER, in_to_uom4 IN VARCHAR2, in_to_uom4_qty IN NUMBER, in_rategroup IN VARCHAR2, in_shelflife IN NUMBER, in_countryof IN VARCHAR2, in_bolcomment IN VARCHAR2, in_alias1wipe IN VARCHAR2, in_alias1 IN VARCHAR2, in_alias1desc IN VARCHAR2, in_alias2wipe IN VARCHAR2, in_alias2 IN VARCHAR2, in_alias2desc IN VARCHAR2, in_alias3wipe IN VARCHAR2, in_alias3 IN VARCHAR2, in_alias3desc IN VARCHAR2, in_alias4wipe IN VARCHAR2, in_alias4 IN VARCHAR2, in_alias4desc IN VARCHAR2, in_alias5wipe IN VARCHAR2, in_alias5 IN VARCHAR2, in_alias5desc IN VARCHAR2, in_alias6wipe IN VARCHAR2, in_alias6 IN VARCHAR2, in_alias6desc IN VARCHAR2, in_alias7wipe IN VARCHAR2, in_alias7 IN VARCHAR2, in_alias7desc IN VARCHAR2, in_alias8wipe IN VARCHAR2, in_alias8 IN VARCHAR2, in_alias8desc IN VARCHAR2, in_alias9wipe IN VARCHAR2, in_alias9 IN VARCHAR2, in_alias9desc IN VARCHAR2, in_alias10wipe IN VARCHAR2, in_alias10 IN VARCHAR2, in_alias10desc IN VARCHAR2, in_alias11wipe IN VARCHAR2, in_alias11 IN VARCHAR2, in_alias11desc IN VARCHAR2, in_add_status IN VARCHAR2, in_delete_status IN VARCHAR2, in_add_review_yn IN VARCHAR2, in_update_review_yn IN VARCHAR2, in_delete_review_yn IN VARCHAR2, in_length IN NUMBER, in_width IN NUMBER, in_height IN NUMBER, in_tms_commodity_code IN VARCHAR2, in_nmfc IN VARCHAR2, in_nmfc_article IN VARCHAR2, in_useramt1 IN NUMBER, in_useramt2 IN NUMBER, in_uom_update IN VARCHAR2, in_critlevel1 IN NUMBER, in_critlevel2 IN NUMBER, in_critlevel3 IN NUMBER, in_labeluom IN VARCHAR2, in_productgroup IN VARCHAR2, in_picktotype IN VARCHAR2, in_cartontype IN VARCHAR2, in_passthrunum01 IN NUMBER, in_passthrunum02 IN NUMBER, in_passthrunum03 IN NUMBER, in_passthrunum04 IN NUMBER, in_passthruchar01 IN VARCHAR2, in_passthruchar02 IN VARCHAR2, in_passthruchar03 IN VARCHAR2, in_passthruchar04 IN VARCHAR2, in_uom_picktotype IN VARCHAR2
		, in_uom_cartontype IN VARCHAR2, out_errorno IN OUT NUMBER, out_msg IN OUT VARCHAR2
	);



	PROCEDURE weber_import_item2
	(
		in_func IN OUT VARCHAR2, in_custid IN VARCHAR2, in_item IN VARCHAR2,
		in_descr IN VARCHAR2, in_abbrev IN OUT VARCHAR2, in_baseuom IN VARCHAR2, in_stackheightuom IN VARCHAR2, in_cube IN NUMBER, in_weight IN NUMBER, in_hazardous IN VARCHAR2, in_lotrequired IN VARCHAR2, in_serialrequired IN VARCHAR2, in_user1required IN VARCHAR2, in_user2required IN VARCHAR2, in_user3required IN VARCHAR2, in_mfgdaterequired IN VARCHAR2, in_expdaterequired IN VARCHAR2, in_countryrequired IN VARCHAR2, in_to_uom1 IN VARCHAR2, in_to_uom1_qty IN NUMBER, in_to_uom2 IN VARCHAR2, in_to_uom2_qty IN NUMBER, in_to_uom3 IN VARCHAR2, in_to_uom3_qty IN NUMBER, in_to_uom4 IN VARCHAR2, in_to_uom4_qty IN NUMBER, in_rategroup IN VARCHAR2, in_shelflife IN NUMBER, in_countryof IN VARCHAR2, in_bolcomment IN VARCHAR2, in_alias1wipe IN VARCHAR2, in_alias1 IN VARCHAR2, in_alias1desc IN VARCHAR2, in_alias2wipe IN VARCHAR2, in_alias2 IN VARCHAR2, in_alias2desc IN VARCHAR2, in_alias3wipe IN VARCHAR2, in_alias3 IN VARCHAR2, in_alias3desc IN VARCHAR2, in_alias4wipe IN VARCHAR2, in_alias4 IN VARCHAR2, in_alias4desc IN VARCHAR2, in_alias5wipe IN VARCHAR2, in_alias5 IN VARCHAR2, in_alias5desc IN VARCHAR2, in_alias6wipe IN VARCHAR2, in_alias6 IN VARCHAR2, in_alias6desc IN VARCHAR2, in_alias7wipe IN VARCHAR2, in_alias7 IN VARCHAR2, in_alias7desc IN VARCHAR2, in_alias8wipe IN VARCHAR2, in_alias8 IN VARCHAR2, in_alias8desc IN VARCHAR2, in_alias9wipe IN VARCHAR2, in_alias9 IN VARCHAR2, in_alias9desc IN VARCHAR2, in_alias10wipe IN VARCHAR2, in_alias10 IN VARCHAR2, in_alias10desc IN VARCHAR2, in_alias11wipe IN VARCHAR2, in_alias11 IN VARCHAR2, in_alias11desc IN VARCHAR2, in_add_status IN VARCHAR2, in_delete_status IN VARCHAR2, in_add_review_yn IN VARCHAR2, in_update_review_yn IN VARCHAR2, in_delete_review_yn IN VARCHAR2, in_length IN NUMBER, in_width IN NUMBER, in_height IN NUMBER, in_tms_commodity_code IN VARCHAR2, in_nmfc IN VARCHAR2, in_nmfc_article IN VARCHAR2, in_useramt1 IN NUMBER, in_useramt2 IN NUMBER, in_uom_update IN VARCHAR2, in_critlevel1 IN NUMBER, in_critlevel2 IN NUMBER, in_critlevel3 IN NUMBER, in_labeluom IN VARCHAR2, in_productgroup IN VARCHAR2, in_picktotype IN VARCHAR2, in_cartontype IN VARCHAR2, in_passthrunum01 IN NUMBER, in_passthrunum02 IN NUMBER, in_passthrunum03 IN NUMBER, in_passthrunum04 IN NUMBER, in_passthruchar01 IN VARCHAR2, in_passthruchar02 IN VARCHAR2, in_passthruchar03 IN VARCHAR2, in_passthruchar04 IN VARCHAR2, in_uom_picktotype IN VARCHAR2
		, in_uom_cartontype IN VARCHAR2, out_errorno IN OUT NUMBER, out_msg IN OUT VARCHAR2
	);

procedure weber_import_item2A
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_item IN varchar2
,in_descr IN varchar2
,in_abbrev IN OUT varchar2
,in_baseuom IN varchar2
,in_stackheightuom in varchar2
,in_cube IN number
,in_weight IN number
,in_hazardous IN varchar2
,in_lotrequired IN varchar2
,in_serialrequired IN varchar2
,in_user1required IN varchar2
,in_user2required IN varchar2
,in_user3required IN varchar2
,in_mfgdaterequired IN varchar2
,in_expdaterequired IN varchar2
,in_countryrequired IN varchar2
,in_to_uom1 IN varchar2
,in_to_uom1_qty IN number
,in_to_uom2 IN varchar2
,in_to_uom2_qty IN number
,in_to_uom3 IN varchar2
,in_to_uom3_qty IN number
,in_to_uom4 IN varchar2
,in_to_uom4_qty IN number
,in_rategroup IN varchar2
,in_shelflife IN number
,in_countryof IN varchar2
,in_bolcomment IN varchar2
,in_alias1wipe IN varchar2
,in_alias1 IN varchar2
,in_alias1desc IN varchar2
,in_alias2wipe IN varchar2
,in_alias2 IN varchar2
,in_alias2desc IN varchar2
,in_alias3wipe IN varchar2
,in_alias3 IN varchar2
,in_alias3desc IN varchar2
,in_alias4wipe IN varchar2
,in_alias4 IN varchar2
,in_alias4desc IN varchar2
,in_alias5wipe IN varchar2
,in_alias5 IN varchar2
,in_alias5desc IN varchar2
,in_alias6wipe IN varchar2
,in_alias6 IN varchar2
,in_alias6desc IN varchar2
,in_alias7wipe IN varchar2
,in_alias7 IN varchar2
,in_alias7desc IN varchar2
,in_alias8wipe IN varchar2
,in_alias8 IN varchar2
,in_alias8desc IN varchar2
,in_alias9wipe IN varchar2
,in_alias9 IN varchar2
,in_alias9desc IN varchar2
,in_alias10wipe IN varchar2
,in_alias10 IN varchar2
,in_alias10desc IN varchar2
,in_alias11wipe IN varchar2
,in_alias11 IN varchar2
,in_alias11desc IN varchar2
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
,in_critlevel1 IN number
,in_critlevel2 IN number
,in_critlevel3 IN number
,in_labeluom IN varchar2
,in_productgroup IN varchar2
,in_picktotype IN varchar2
,in_cartontype IN varchar2
,in_passthrunum01  IN  number
,in_passthrunum02  IN  number
,in_passthrunum03  IN  number
,in_passthrunum04  IN  number
,in_passthruchar01  IN varchar2
,in_passthruchar02  IN varchar2
,in_passthruchar03  IN varchar2
,in_passthruchar04  IN varchar2
,in_uom_picktotype IN varchar2
,in_uom_cartontype IN varchar2
,in_uom1_length IN number
,in_uom1_width IN number
,in_uom1_height IN number
,in_uom1_cube IN number
,in_uom1_weight IN number
,in_uom2_length IN number
,in_uom2_width IN number
,in_uom2_height IN number
,in_uom2_cube IN number
,in_uom2_weight IN number
,in_uom3_length IN number
,in_uom3_width IN number
,in_uom3_height IN number
,in_uom3_cube IN number
,in_uom3_weight IN number
,in_uom4_length IN number
,in_uom4_width IN number
,in_uom4_height IN number
,in_uom4_cube IN number
,in_uom4_weight IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

	FUNCTION order_count_on_load ( in_loadno IN NUMBER )
		RETURN NUMBER;

	FUNCTION order_seq_on_load
	(
		in_loadno IN NUMBER, in_orderid IN NUMBER, in_shipid IN NUMBER
	)
		RETURN NUMBER;

	PRAGMA RESTRICT_REFERENCES ( order_count_on_load, WNDS, WNPS,
								 RNPS );
	PRAGMA RESTRICT_REFERENCES ( order_seq_on_load, WNDS, WNPS,
								 RNPS );
END ZIMPORTPROCWEBERITEM;