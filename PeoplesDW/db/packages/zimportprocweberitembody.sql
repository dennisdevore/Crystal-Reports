create or replace
PACKAGE BODY      zimportprocweberitem AS
	--
	-- $Id: zimportprocweberitembody.sql 219 2005-10-04 11:33:19Z ed $
	--


	PROCEDURE weber_import_item
	(
		in_func IN OUT VARCHAR2, in_custid IN VARCHAR2, in_item IN VARCHAR2,
		in_descr IN VARCHAR2, in_abbrev IN OUT VARCHAR2, in_baseuom IN VARCHAR2, in_stackheightuom IN VARCHAR2, in_cube IN NUMBER, in_weight IN NUMBER, in_hazardous IN VARCHAR2, in_lotrequired IN VARCHAR2, in_serialrequired IN VARCHAR2, in_user1required IN VARCHAR2, in_user2required IN VARCHAR2, in_user3required IN VARCHAR2, in_mfgdaterequired IN VARCHAR2, in_expdaterequired IN VARCHAR2, in_countryrequired IN VARCHAR2, in_to_uom1 IN VARCHAR2, in_to_uom1_qty IN NUMBER, in_to_uom2 IN VARCHAR2, in_to_uom2_qty IN NUMBER, in_to_uom3 IN VARCHAR2, in_to_uom3_qty IN NUMBER, in_to_uom4 IN VARCHAR2, in_to_uom4_qty IN NUMBER, in_rategroup IN VARCHAR2, in_shelflife IN NUMBER, in_countryof IN VARCHAR2, in_bolcomment IN VARCHAR2, in_alias1wipe IN VARCHAR2, in_alias1 IN VARCHAR2, in_alias1desc IN VARCHAR2, in_alias2wipe IN VARCHAR2, in_alias2 IN VARCHAR2, in_alias2desc IN VARCHAR2, in_alias3wipe IN VARCHAR2, in_alias3 IN VARCHAR2, in_alias3desc IN VARCHAR2, in_alias4wipe IN VARCHAR2, in_alias4 IN VARCHAR2, in_alias4desc IN VARCHAR2, in_alias5wipe IN VARCHAR2, in_alias5 IN VARCHAR2, in_alias5desc IN VARCHAR2, in_alias6wipe IN VARCHAR2, in_alias6 IN VARCHAR2, in_alias6desc IN VARCHAR2, in_alias7wipe IN VARCHAR2, in_alias7 IN VARCHAR2, in_alias7desc IN VARCHAR2, in_alias8wipe IN VARCHAR2, in_alias8 IN VARCHAR2, in_alias8desc IN VARCHAR2, in_alias9wipe IN VARCHAR2, in_alias9 IN VARCHAR2, in_alias9desc IN VARCHAR2, in_alias10wipe IN VARCHAR2, in_alias10 IN VARCHAR2, in_alias10desc IN VARCHAR2, in_alias11wipe IN VARCHAR2, in_alias11 IN VARCHAR2, in_alias11desc IN VARCHAR2, in_add_status IN VARCHAR2, in_delete_status IN VARCHAR2, in_add_review_yn IN VARCHAR2, in_update_review_yn IN VARCHAR2, in_delete_review_yn IN VARCHAR2, in_length IN NUMBER, in_width IN NUMBER, in_height IN NUMBER, in_tms_commodity_code IN VARCHAR2, in_nmfc IN VARCHAR2, in_nmfc_article IN VARCHAR2, in_useramt1 IN NUMBER, in_useramt2 IN NUMBER, in_uom_update IN VARCHAR2, in_critlevel1 IN NUMBER, in_critlevel2 IN NUMBER, in_critlevel3 IN NUMBER, in_labeluom IN VARCHAR2, in_productgroup IN VARCHAR2, in_picktotype IN VARCHAR2, in_cartontype IN VARCHAR2, in_passthrunum01 IN NUMBER, in_passthrunum02 IN NUMBER, in_passthrunum03 IN NUMBER, in_passthrunum04 IN NUMBER, in_passthruchar01 IN VARCHAR2, in_passthruchar02 IN VARCHAR2, in_passthruchar03 IN VARCHAR2, in_passthruchar04 IN VARCHAR2, in_uom_picktotype IN VARCHAR2
		, in_uom_cartontype IN VARCHAR2, out_errorno IN OUT NUMBER, out_msg IN OUT VARCHAR2
	) IS
		CURSOR curCustomer IS
			SELECT name
			FROM   customer
			WHERE  custid = UPPER ( RTRIM ( in_custid ) );

		cs curCustomer%ROWTYPE;

		CURSOR curCustItem IS
			SELECT ci.descr, ci.status, SUM ( NVL ( cit.qty, 0 ) ) qty
			FROM   custitem ci, custitemtot cit
			WHERE  ci.custid = cit.custid(+)
			AND    ci.item = cit.item(+)
			AND    cit.invstatus(+) = 'AV'
			AND    ci.custid = UPPER ( RTRIM ( in_custid ) )
			AND    ci.item = UPPER ( RTRIM ( in_item ) )
			GROUP BY ci.descr, ci.status, cit.invstatus;

		ci curCustItem%ROWTYPE;

		uom_sequence custitemuom.sequence%TYPE;
		wrk custitem%ROWTYPE;
		uomqty custitemuom.qty%TYPE;
		uomqty2 custitemuom.qty%TYPE;
		str_subject VARCHAR2 ( 500 );
		real_cube NUMBER;

		PROCEDURE log_msg ( in_msgtype VARCHAR2 ) IS
			strMsg appmsgs.msgtext%TYPE;
		BEGIN
			out_msg := ' Item: ' || RTRIM ( in_item ) || ': ' || out_msg;
			zms.log_msg
			(
				'IMPEXP', NULL, RTRIM ( in_custid ),
				out_msg, NVL ( RTRIM ( in_msgtype ), 'E' ), 'WEBERIMP',
				strMsg
			);
		END;

		PROCEDURE update_uom
		(
			in_seq NUMBER, in_qty NUMBER, in_from_uom VARCHAR2,
			in_to_uom VARCHAR2
		) IS
		BEGIN
			BEGIN
				INSERT INTO custitemuom
							(
							  custid, item, sequence,
							  qty, fromuom, touom,
							  lastuser, lastupdate, velocity,
							  picktotype, cartontype
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), in_seq,
						   in_qty, in_from_uom, in_to_uom,
						   'WEBERIMP', SYSDATE, 'C',
						   NVL ( in_uom_picktotype, 'FULL' ), NVL ( in_uom_cartontype, 'PLT' )
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemuom
					SET    fromuom = in_from_uom, touom = in_to_uom, qty = in_qty
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    sequence = in_seq;
			END;
		END;
	BEGIN
		IF RTRIM ( UPPER ( in_func ) ) NOT IN ( 'A', 'U', 'D' ) THEN
			out_errorno := 4;
			out_msg := 'Invalid function code: ' || in_func;
			log_msg ( 'E' );
			RETURN;
		END IF;

		IF RTRIM ( in_custid ) IS NULL THEN
			out_errorno := 1;
			out_msg := 'Customer ID is required';
			log_msg ( 'E' );
			RETURN;
		END IF;

		cs := NULL;

		OPEN curCustomer;

		FETCH curCustomer
			INTO   cs;

		CLOSE curCustomer;

		IF cs.name IS NULL THEN
			out_errorno := 2;
			out_msg := 'Invalid Customer ID: ' || in_custid;
			log_msg ( 'E' );
			RETURN;
		END IF;

		IF RTRIM ( in_item ) IS NULL THEN
			out_errorno := 3;
			out_msg := 'Item ID is required';
			log_msg ( 'E' );
			RETURN;
		END IF;

		ci := NULL;

		OPEN curCustItem;

		FETCH curCustItem
			INTO   ci;

		CLOSE curCustItem;

		IF ci.descr IS NULL THEN
			IF UPPER ( RTRIM ( in_func ) ) = 'D' THEN
				out_errorno := 5;
				out_msg := 'Item not found for deletion: ' || in_item;
				log_msg ( 'E' );
				RETURN;
			END IF;

			IF UPPER ( RTRIM ( in_func ) ) = 'U' THEN
				out_msg :=
					'Item not found for update (add performed): ' || in_item;
				log_msg ( 'W' );
				in_func := 'A';
			END IF;
		ELSE
			IF UPPER ( RTRIM ( in_func ) ) = 'A' THEN
				out_msg :=
					   'Item to be added already on file (update performed): '
					|| in_item;
				log_msg ( 'W' );
				in_func := 'U';
			END IF;
		END IF;

		IF UPPER ( RTRIM ( in_func ) ) = 'A' THEN
			wrk.status := in_add_status;
			wrk.needs_review_yn := in_add_review_yn;
		ELSIF UPPER ( RTRIM ( in_func ) ) = 'U' THEN
			wrk.status := ci.status;
			wrk.needs_review_yn := in_update_review_yn;
		ELSE
			wrk.status := in_delete_status;
			wrk.needs_review_yn := in_delete_review_yn;
		END IF;

		IF RTRIM ( in_abbrev ) IS NULL THEN
			in_abbrev :=
				SUBSTR
				(
					in_descr, 1, 12
				);
		END IF;

		IF in_cube IS NULL
		   AND in_length IS NOT NULL
		   AND in_width IS NOT NULL
		   AND in_height IS NOT NULL THEN
			real_cube := in_length * in_width * in_height;
		ELSE
			real_cube := in_cube;
		END IF;

		-- if no item then just create it
		IF ci.status IS NULL THEN
			INSERT INTO custitem
						(
						  custid, item, descr,
						  abbrev, status, baseuom,
						  stackheightuom, cube, weight,
						  hazardous, shelflife, min_sale_life,
						  lotrequired, serialrequired, user1required,
						  user2required, user3required, mfgdaterequired,
						  expdaterequired, countryrequired, allowsub,
						  backorder, invstatusind, invclassind,
						  qtytype, velocity, recvinvstatus,
						  weightcheckrequired, ordercheckrequired, use_fifo,
						  putawayconfirmation, nodamaged, iskit,
						  subslprsnrequired, lotsumreceipt, lotsumrenewal,
						  lotsumbol, lotsumaccess, lotfmtaction,
						  serialfmtaction, user1fmtaction, user2fmtaction,
						  user3fmtaction, maxqtyof1, rategroup,
						  serialasncapture, user1asncapture, user2asncapture,
						  user3asncapture, lastuser, lastupdate,
						  needs_review_yn, countryof, LENGTH,
						  width, height, tms_commodity_code,
						  nmfc, nmfc_article, useramt1,
						  useramt2, critlevel1, critlevel2,
						  critlevel3, labeluom, productgroup,
						  picktotype, cartontype, itmpassthrunum01,
						  itmpassthrunum02, itmpassthrunum03, itmpassthrunum04, itmpassthruchar01, itmpassthruchar02, itmpassthruchar03
						  , itmpassthruchar04
						)
			VALUES
				   (
					   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), RTRIM ( in_descr ),
					   RTRIM ( in_abbrev ), wrk.status, NVL ( UPPER ( RTRIM ( in_baseuom ) ), 'EA' ),
					   NVL ( UPPER ( RTRIM ( in_stackheightuom ) ), 'PLT' ), NVL ( real_cube, 0 ), NVL ( in_weight, 0 ),
					   NVL ( UPPER ( RTRIM ( in_hazardous ) ), 'N' ), NVL ( in_shelflife, 0 ), NVL ( in_shelflife, 0 ),
					   RTRIM ( NVL ( in_lotrequired, 'C' ) ), RTRIM ( NVL ( in_serialrequired, 'C' ) ), RTRIM ( NVL ( in_user1required, 'C' ) ),
					   RTRIM ( NVL ( in_user2required, 'C' ) ), RTRIM ( NVL ( in_user3required, 'C' ) ), RTRIM ( NVL ( in_mfgdaterequired, 'C' ) ),
					   RTRIM ( NVL ( in_expdaterequired, 'C' ) ), RTRIM ( NVL ( in_countryrequired, 'C' ) ), 'C',
					   'C', 'C', 'C',
					   'C', 'C', 'AV',
					   'C', 'C', 'N',
					   'C', 'C', 'N',
					   'C', 'N', 'N',
					   'N', 'N', 'C',
					   'C', 'C', 'C',
					   'C', 'C', in_rategroup,
					   'C', 'C', 'C',
					   'C', 'WEBERIMP', SYSDATE,
					   wrk.needs_review_yn, UPPER ( RTRIM ( in_countryof ) ), in_length,
					   in_width, in_height, in_tms_commodity_code,
					   in_nmfc, in_nmfc_article, in_useramt1,
					   in_useramt2, in_critlevel1, in_critlevel2,
					   in_critlevel3, in_labeluom, in_productgroup,
					   in_picktotype, in_cartontype, in_passthrunum01,
					   in_passthrunum02, in_passthrunum03, in_passthrunum04,
					   in_passthruchar01, in_passthruchar02, in_passthruchar03,
					   in_passthruchar04
				   );

			--create uom conversions
			IF ( RTRIM ( in_to_uom1 ) IS NOT NULL )
			   AND ( NVL ( in_to_uom1_qty, 0 ) <> 0 ) THEN
				DELETE FROM custitemuom
				WHERE  custid = UPPER ( RTRIM ( in_custid ) )
				AND    item = UPPER ( RTRIM ( in_item ) );

				uom_sequence := 10;

				INSERT INTO custitemuom
							(
							  custid, item, sequence,
							  qty, fromuom, touom,
							  lastuser, lastupdate, velocity,
							  picktotype, cartontype
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), uom_sequence,
						   in_to_uom1_qty, NVL ( UPPER ( RTRIM ( in_baseuom ) ), 'EA' ), UPPER ( RTRIM ( in_to_uom1 ) ),
						   'WEBERIMP', SYSDATE, 'C',
						   NVL ( in_uom_picktotype, 'FULL' ), NVL ( in_uom_cartontype, 'PLT' )
					   );

				IF ( RTRIM ( in_to_uom2 ) IS NOT NULL )
				   AND ( NVL ( in_to_uom2_qty, 0 ) <> 0 ) THEN
					uom_sequence := uom_sequence + 10;

					INSERT INTO custitemuom
								(
								  custid, item, sequence,
								  qty, fromuom, touom,
								  lastuser, lastupdate, velocity,
								  picktotype, cartontype
								)
					VALUES
						   (
							   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), uom_sequence,
							   in_to_uom2_qty, UPPER ( RTRIM ( in_to_uom1 ) ), UPPER ( RTRIM ( in_to_uom2 ) ),
							   'WEBERIMP', SYSDATE, 'C',
							   NVL ( in_uom_picktotype, 'FULL' ), NVL ( in_uom_cartontype, 'PLT' )
						   );

					IF ( RTRIM ( in_to_uom3 ) IS NOT NULL )
					   AND ( NVL ( in_to_uom3_qty, 0 ) <> 0 ) THEN
						uom_sequence := uom_sequence + 10;

						INSERT INTO custitemuom
									(
									  custid, item, sequence,
									  qty, fromuom, touom,
									  lastuser, lastupdate, velocity,
									  picktotype, cartontype
									)
						VALUES
							   (
								   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), uom_sequence,
								   in_to_uom3_qty, UPPER ( RTRIM ( in_to_uom2 ) ), UPPER ( RTRIM ( in_to_uom3 ) ),
								   'WEBERIMP', SYSDATE, 'C',
								   NVL ( in_uom_picktotype, 'FULL' ), NVL ( in_uom_cartontype, 'PLT' )
							   );

						IF ( RTRIM ( in_to_uom4 ) IS NOT NULL )
						   AND ( NVL ( in_to_uom4_qty, 0 ) <> 0 ) THEN
							uom_sequence := uom_sequence + 10;

							INSERT INTO custitemuom
										(
										  custid, item, sequence,
										  qty, fromuom, touom,
										  lastuser, lastupdate, velocity,
										  picktotype, cartontype
										)
							VALUES
								   (
									   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), uom_sequence,
									   in_to_uom4_qty, UPPER ( RTRIM ( in_to_uom3 ) ), UPPER ( RTRIM ( in_to_uom4 ) ),
									   'WEBERIMP', SYSDATE, 'C',
									   NVL ( in_uom_picktotype, 'FULL' ), NVL ( in_uom_cartontype, 'PLT' )
								   );
						END IF;
					END IF;
				END IF;
			END IF;
		ELSE
			IF ci.status = 'ACTV' THEN
				--if active only update description, shelflife, nmfc, critlevel, all passthru fields, itemaliases
				UPDATE custitem
				SET --descr = nvl(rtrim(in_descr),descr),
				   abbrev = NVL ( RTRIM ( in_abbrev ), abbrev ), status = wrk.status, --baseuom = nvl(upper(rtrim(in_baseuom)),baseuom),
																					  stackheightuom = NVL ( UPPER ( RTRIM ( in_stackheightuom ) ), 'PLT' ),
					   --cube = nvl(real_cube,cube),
					   --weight = nvl(in_weight,weight),
					   hazardous = NVL ( UPPER ( RTRIM ( in_hazardous ) ), hazardous ), shelflife = NVL ( in_shelflife, shelflife ), min_sale_life = NVL ( in_shelflife, shelflife ),
					   lastuser = 'WEBERIMP', lastupdate = SYSDATE, needs_review_yn = wrk.needs_review_yn,
					   --length = nvl(in_length,length),
					   --width = nvl(in_width,width),
					   --height = nvl(in_height,height),
					   nmfc = in_nmfc, nmfc_article = in_nmfc_article, rategroup = in_rategroup,
					   useramt1 = in_useramt1, useramt2 = in_useramt2, critlevel1 = in_critlevel1,
					   critlevel2 = in_critlevel2, critlevel3 = in_critlevel3, --labeluom = in_labeluom,
																			   productgroup = in_productgroup,
					   --picktotype = in_picktotype,
					   --cartontype = in_cartontype,
					   itmpassthrunum01 = NVL ( in_passthrunum01, itmpassthrunum01 ), itmpassthrunum02 = NVL ( in_passthrunum02, itmpassthrunum02 ), itmpassthrunum03 = NVL ( in_passthrunum03, itmpassthrunum03 ),
					   itmpassthrunum04 = NVL ( in_passthrunum04, itmpassthrunum04 ), itmpassthruchar01 = NVL ( in_passthruchar01, itmpassthruchar01 ), itmpassthruchar02 = NVL ( in_passthruchar02, itmpassthruchar02 ),
					   itmpassthruchar03 = NVL ( in_passthruchar03, itmpassthruchar03 ), itmpassthruchar04 = NVL ( in_passthruchar04, itmpassthruchar04 )
				WHERE  custid = UPPER ( RTRIM ( in_custid ) )
				AND    item = UPPER ( RTRIM ( in_item ) );

				BEGIN
					SELECT qty
					INTO   uomqty
					FROM   custitemuom
					WHERE  ROWNUM = 1
					AND    custid = RTRIM ( in_custid )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    sequence = 10;
				EXCEPTION
					WHEN OTHERS THEN
						uomqty := 0;
				END;

				BEGIN
					SELECT qty
					INTO   uomqty2
					FROM   custitemuom
					WHERE  ROWNUM = 1
					AND    custid = RTRIM ( in_custid )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    sequence = 20;
				EXCEPTION
					WHEN OTHERS THEN
						uomqty2 := 0;
				END;



				--time to check for UOM Conversion and if different then we need to send an email
				--old statement which didn't care of the uom existed before checking to compare
				--IF NVL(uomqty,0)!=NVL(rtrim(in_useramt1),rtrim(in_abbrev)) or NVL(uomqty2,0)!=NVL(rtrim(in_useramt2),0) THEN
				IF NVL ( uomqty, 0 ) !=
					   NVL ( RTRIM ( in_useramt1 ), RTRIM ( in_abbrev ) )
				   OR ( NVL ( uomqty2, 0 ) !=
						   NVL ( RTRIM ( in_useramt2 ), 0 )
					   AND NVL ( uomqty2, 0 ) <> 0
					   AND NVL ( RTRIM ( in_useramt2 ), 0 ) <> 0 ) THEN
					DECLARE
						conn UTL_SMTP.connection;
					BEGIN
						IF NVL ( uomqty2, 0 ) !=
							   NVL ( RTRIM ( in_useramt2 ), 0 ) THEN
							str_subject :=
								   'New UOM for CustID '
								|| in_custid
								|| ' / Item '
								|| UPPER ( RTRIM ( in_item ) )
								|| ' / QTY from '
								|| NVL ( uomqty, 0 )
								|| ' to '
								|| NVL
								   (
									   RTRIM ( in_useramt1 ),
									   RTRIM ( in_abbrev )
								   )
								|| ' seq 10 / '
								|| uomqty2
								|| ' to '
								|| NVL ( RTRIM ( in_useramt2 ), 0 )
								|| ' seq 20';
						ELSE
							str_subject :=
								   'New UOM for CustID '
								|| in_custid
								|| ' / Item '
								|| UPPER ( RTRIM ( in_item ) )
								|| ' / QTY from '
								|| NVL ( uomqty, 0 )
								|| ' to '
								|| NVL
								   (
									   RTRIM ( in_useramt1 ),
									   RTRIM ( in_abbrev )
								   );
						END IF;

						conn :=
							weber_mail.begin_mail
							(
								sender => 'New UOM <edi@weberlogistics.com>', recipients => in_custid || ' <' || in_custid || 'uom@weberlogistics.com>', subject => str_subject
								, mime_type => 'text/html'
							);

						weber_mail.write_text
						(
							conn => conn, MESSAGE => '<HTML>' || '<BODY leftmargin="0" rightmargin="0" topmargin="0" marginwidth="0" marginheight="0" bgcolor="#FFFFFF">' || '<font face="Arial, Helvetica, sans-serif">' || '<table width="100%" border="0" cellspacing="0" cellpadding="2">' || '<tr>' || '<td bgcolor="#000000"><font size="2" face="Verdana, Arial, Helvetica, sans-serif" color="#FFFFFF"><b>Item Details</b></font></td>' || '</tr>' || '<tr align="center">' || '<td bgcolor="#CCCCCC" colspan="2" valign="top">' || '<table width="100%" border="0" cellspacing="0" cellpadding="5" bgcolor="#FFFFFF">' || '<tr>' || '<td width=15% bgcolor="FFFFFF" colspan=10 nowrap><font face="Verdana, Arial, Helvetica, sans-serif" size="2" color="0000FF"><b>CustID ' || in_custid || '</b></font></td>' || '<td width=15% bgcolor="FFFFFF" colspan=10 nowrap><font face="Verdana, Arial, Helvetica, sans-serif" size="2" color="0000FF"><b>Item ' || UPPER ( RTRIM ( in_item ) ) || '</b></font></td>' || '<td bgcolor="FFFFFF" colspan=10 nowrap><font face="Verdana, Arial, Helvetica, sans-serif" size="2" color="0000FF"><b>UOM from ' || NVL ( uomqty, 0 ) || ' to ' || NVL ( RTRIM ( in_useramt1 ), RTRIM ( in_abbrev ) ) || ' seq 10</b></font></td>' || '<td bgcolor="FFFFFF" colspan=10 nowrap><font face="Verdana, Arial, Helvetica, sans-serif" size="2" color="0000FF"><b>UOM from ' || NVL ( uomqty2, 0 ) || ' to ' || NVL ( RTRIM ( in_useramt2 ), 0 ) || ' seq 20</b></font></td>' || '</tr>' || '</table>' || '</td>' || '</tr>' || '</table>' || '</font>' || '</body>' || '</html>'
						);

						weber_mail.end_mail ( conn => conn );
					EXCEPTION
						WHEN OTHERS THEN
							zms.log_msg
							(
								'WEBERIMP', NULL, in_custid,
								'MAIL DID NOT SEND, IS THE CUSTID EMAIL SETUP?', 'I', 'WEBERIMP'
								, out_msg
							);
					END;
				END IF;
			ELSE --this must be 'INAC'
				--if inactive we can update all fields

				UPDATE custitem
				SET    descr = NVL ( RTRIM ( in_descr ), descr ), abbrev = NVL ( RTRIM ( in_abbrev ), abbrev ), status = wrk.status,
					   baseuom = NVL ( UPPER ( RTRIM ( in_baseuom ) ), baseuom ), stackheightuom = NVL ( UPPER ( RTRIM ( in_stackheightuom ) ), 'PLT' ), cube = NVL ( real_cube, cube ),
					   weight = NVL ( in_weight, weight ), hazardous = NVL ( UPPER ( RTRIM ( in_hazardous ) ), hazardous ), lotrequired = RTRIM ( NVL ( in_lotrequired, 'C' ) ),
					   serialrequired = RTRIM ( NVL ( in_serialrequired, 'C' ) ), user1required = RTRIM ( NVL ( in_user1required, 'C' ) ), user2required = RTRIM ( NVL ( in_user2required, 'C' ) ),
					   user3required = RTRIM ( NVL ( in_user3required, 'C' ) ), mfgdaterequired = RTRIM ( NVL ( in_mfgdaterequired, 'C' ) ), expdaterequired = RTRIM ( NVL ( in_expdaterequired, 'C' ) ),
					   countryrequired = RTRIM ( NVL ( in_countryrequired, 'C' ) ), shelflife = NVL ( in_shelflife, shelflife ), min_sale_life = NVL ( in_shelflife, shelflife ),
					   lastuser = 'WEBERIMP', lastupdate = SYSDATE, needs_review_yn = wrk.needs_review_yn,
					   LENGTH = NVL ( in_length, LENGTH ), width = NVL ( in_width, width ), height = NVL ( in_height, height ),
					   nmfc = in_nmfc, nmfc_article = in_nmfc_article, rategroup = in_rategroup,
					   useramt1 = in_useramt1, useramt2 = in_useramt2, critlevel1 = in_critlevel1,
					   critlevel2 = in_critlevel2, critlevel3 = in_critlevel3, labeluom = in_labeluom,
					   productgroup = in_productgroup, picktotype = in_picktotype, cartontype = in_cartontype,
					   itmpassthrunum01 = NVL ( in_passthrunum01, itmpassthrunum01 ), itmpassthrunum02 = NVL ( in_passthrunum02, itmpassthrunum02 ), itmpassthrunum03 = NVL ( in_passthrunum03, itmpassthrunum03 ),
					   itmpassthrunum04 = NVL ( in_passthrunum04, itmpassthrunum04 ), itmpassthruchar01 = NVL ( in_passthruchar01, itmpassthruchar01 ), itmpassthruchar02 = NVL ( in_passthruchar02, itmpassthruchar02 ),
					   itmpassthruchar03 = NVL ( in_passthruchar03, itmpassthruchar03 ), itmpassthruchar04 = NVL ( in_passthruchar04, itmpassthruchar04 )
				WHERE  custid = UPPER ( RTRIM ( in_custid ) )
				AND    item = UPPER ( RTRIM ( in_item ) );

				--not sure if we want to allow uom conversions from customers? I'll use this uomupdate flag to allow or disallow insert/update
				--copy and move this within the above if statementss if we want different rules for actv items vs inac items
				IF NVL ( in_uom_update, 'N' ) = 'Y' THEN
					NULL;

					IF ( RTRIM ( in_to_uom1 ) IS NOT NULL )
					   AND ( NVL ( in_to_uom1_qty, 0 ) <> 0 ) THEN
						uom_sequence := 10;
						update_uom
						(
							uom_sequence, in_to_uom1_qty, NVL ( UPPER ( RTRIM ( in_baseuom ) ), 'EA' )
							, UPPER ( RTRIM ( in_to_uom1 ) )
						);

						IF ( RTRIM ( in_to_uom2 ) IS NOT NULL )
						   AND ( NVL ( in_to_uom2_qty, 0 ) <> 0 ) THEN
							uom_sequence := uom_sequence + 10;
							update_uom
							(
								uom_sequence, in_to_uom2_qty, UPPER ( RTRIM ( in_to_uom1 ) )
								, UPPER ( RTRIM ( in_to_uom2 ) )
							);

							IF ( RTRIM ( in_to_uom3 ) IS NOT NULL )
							   AND ( NVL ( in_to_uom3_qty, 0 ) <> 0 ) THEN
								uom_sequence := uom_sequence + 10;

								update_uom
								(
									uom_sequence, in_to_uom3_qty, UPPER ( RTRIM ( in_to_uom2 ) )
									, UPPER ( RTRIM ( in_to_uom3 ) )
								);

								IF ( RTRIM ( in_to_uom4 ) IS NOT NULL )
								   AND ( NVL ( in_to_uom4_qty, 0 ) <> 0 ) THEN
									uom_sequence := uom_sequence + 10;

									update_uom
									(
										uom_sequence, in_to_uom4_qty, UPPER ( RTRIM ( in_to_uom3 ) )
										, UPPER ( RTRIM ( in_to_uom4 ) )
									);
								END IF;
							END IF;
						END IF;

						DELETE FROM custitemuom
						WHERE  custid = UPPER ( RTRIM ( in_custid ) )
						AND    item = UPPER ( RTRIM ( in_item ) )
						AND    sequence > uom_sequence;
					END IF;
				END IF;
			END IF;
		END IF;


		--do we want customers to be able to update bol comments?
		IF RTRIM ( in_bolcomment ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitembolcomments
							(
							  custid, item, consignee,
							  comment1, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), NULL,
						   in_bolcomment, 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitembolcomments
					SET    comment1 = in_bolcomment, lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    consignee IS NULL;
			END;
		END IF;

		--add or update UPC code
		IF RTRIM ( in_alias1 ) IS NOT NULL
		   AND RTRIM ( NVL ( in_alias1wipe, 'N' ) ) = 'Y' THEN
			DELETE FROM custitemalias
			WHERE  custid = UPPER ( RTRIM ( in_custid ) )
			AND    item = UPPER ( RTRIM ( in_item ) )
			AND    aliasdesc = NVL ( RTRIM ( in_alias1desc ), in_alias1 );
		END IF;

		IF RTRIM ( in_alias1 ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitemalias
							(
							  custid, item, itemalias,
							  aliasdesc, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), UPPER ( RTRIM ( in_alias1 ) ),
						   NVL ( RTRIM ( in_alias1desc ), in_alias1 ), 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemalias
					SET    aliasdesc = NVL ( RTRIM ( in_alias1desc ), in_alias1 ), lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    itemalias = UPPER ( RTRIM ( in_alias1 ) );
			END;
		END IF;

		--add or update second alias, probably mainly GTIN
		IF RTRIM ( in_alias2 ) IS NOT NULL
		   AND RTRIM ( NVL ( in_alias2wipe, 'N' ) ) = 'Y' THEN
			DELETE FROM custitemalias
			WHERE  custid = UPPER ( RTRIM ( in_custid ) )
			AND    item = UPPER ( RTRIM ( in_item ) )
			AND    aliasdesc = NVL ( RTRIM ( in_alias2desc ), in_alias2 );
		END IF;

		IF RTRIM ( in_alias2 ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitemalias
							(
							  custid, item, itemalias,
							  aliasdesc, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), UPPER ( RTRIM ( in_alias2 ) ),
						   NVL ( RTRIM ( in_alias2desc ), in_alias2 ), 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemalias
					SET    aliasdesc = NVL ( RTRIM ( in_alias2desc ), in_alias2 ), lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    itemalias = UPPER ( RTRIM ( in_alias2 ) );

					IF SQL%ROWCOUNT = 0 THEN
						out_errorno := 105;
						out_msg :=
							   'Alias2 value of '
							|| RTRIM ( in_alias2 )
							|| ' is already in use';
						log_msg ( 'E' );
						RETURN;
					END IF;
			END;
		END IF;

		--add or update third alias, just in case
		IF RTRIM ( in_alias3 ) IS NOT NULL
		   AND RTRIM ( NVL ( in_alias3wipe, 'N' ) ) = 'Y' THEN
			DELETE FROM custitemalias
			WHERE  custid = UPPER ( RTRIM ( in_custid ) )
			AND    item = UPPER ( RTRIM ( in_item ) )
			AND    aliasdesc = NVL ( RTRIM ( in_alias3desc ), in_alias3 );
		END IF;

		IF RTRIM ( in_alias3 ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitemalias
							(
							  custid, item, itemalias,
							  aliasdesc, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), UPPER ( RTRIM ( in_alias3 ) ),
						   NVL ( RTRIM ( in_alias3desc ), in_alias3 ), 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemalias
					SET    aliasdesc = NVL ( RTRIM ( in_alias3desc ), in_alias3 ), lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    itemalias = UPPER ( RTRIM ( in_alias3 ) );

					IF SQL%ROWCOUNT = 0 THEN
						out_errorno := 105;
						out_msg :=
							   'Alias3 value of '
							|| RTRIM ( in_alias3 )
							|| ' is already in use';
						log_msg ( 'E' );
						RETURN;
					END IF;
			END;
		END IF;

		IF RTRIM ( in_alias4 ) IS NOT NULL
		   AND RTRIM ( NVL ( in_alias4wipe, 'N' ) ) = 'Y' THEN
			DELETE FROM custitemalias
			WHERE  custid = UPPER ( RTRIM ( in_custid ) )
			AND    item = UPPER ( RTRIM ( in_item ) )
			AND    aliasdesc = NVL ( RTRIM ( in_alias4desc ), in_alias4 );
		END IF;

		IF RTRIM ( in_alias4 ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitemalias
							(
							  custid, item, itemalias,
							  aliasdesc, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), UPPER ( RTRIM ( in_alias4 ) ),
						   NVL ( RTRIM ( in_alias4desc ), in_alias4 ), 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemalias
					SET    aliasdesc = NVL ( RTRIM ( in_alias4desc ), in_alias4 ), lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    itemalias = UPPER ( RTRIM ( in_alias4 ) );

					IF SQL%ROWCOUNT = 0 THEN
						out_errorno := 105;
						out_msg :=
							   'Alias4 value of '
							|| RTRIM ( in_alias4 )
							|| ' is already in use';
						log_msg ( 'E' );
						RETURN;
					END IF;
			END;
		END IF;

		IF RTRIM ( in_alias5 ) IS NOT NULL
		   AND RTRIM ( NVL ( in_alias5wipe, 'N' ) ) = 'Y' THEN
			DELETE FROM custitemalias
			WHERE  custid = UPPER ( RTRIM ( in_custid ) )
			AND    item = UPPER ( RTRIM ( in_item ) )
			AND    aliasdesc = NVL ( RTRIM ( in_alias5desc ), in_alias5 );
		END IF;

		IF RTRIM ( in_alias5 ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitemalias
							(
							  custid, item, itemalias,
							  aliasdesc, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), UPPER ( RTRIM ( in_alias5 ) ),
						   NVL ( RTRIM ( in_alias5desc ), in_alias5 ), 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemalias
					SET    aliasdesc = NVL ( RTRIM ( in_alias5desc ), in_alias5 ), lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    itemalias = UPPER ( RTRIM ( in_alias5 ) );

					IF SQL%ROWCOUNT = 0 THEN
						out_errorno := 105;
						out_msg :=
							   'Alias5 value of '
							|| RTRIM ( in_alias5 )
							|| ' is already in use';
						log_msg ( 'E' );
						RETURN;
					END IF;
			END;
		END IF;

		IF RTRIM ( in_alias6 ) IS NOT NULL
		   AND RTRIM ( NVL ( in_alias6wipe, 'N' ) ) = 'Y' THEN
			DELETE FROM custitemalias
			WHERE  custid = UPPER ( RTRIM ( in_custid ) )
			AND    item = UPPER ( RTRIM ( in_item ) )
			AND    aliasdesc = NVL ( RTRIM ( in_alias6desc ), in_alias6 );
		END IF;

		IF RTRIM ( in_alias6 ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitemalias
							(
							  custid, item, itemalias,
							  aliasdesc, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), UPPER ( RTRIM ( in_alias6 ) ),
						   NVL ( RTRIM ( in_alias6desc ), in_alias6 ), 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemalias
					SET    aliasdesc = NVL ( RTRIM ( in_alias6desc ), in_alias6 ), lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    itemalias = UPPER ( RTRIM ( in_alias6 ) );

					IF SQL%ROWCOUNT = 0 THEN
						out_errorno := 105;
						out_msg :=
							   'Alias6 value of '
							|| RTRIM ( in_alias6 )
							|| ' is already in use';
						log_msg ( 'E' );
						RETURN;
					END IF;
			END;
		END IF;

		IF RTRIM ( in_alias7 ) IS NOT NULL
		   AND RTRIM ( NVL ( in_alias7wipe, 'N' ) ) = 'Y' THEN
			DELETE FROM custitemalias
			WHERE  custid = UPPER ( RTRIM ( in_custid ) )
			AND    item = UPPER ( RTRIM ( in_item ) )
			AND    aliasdesc = NVL ( RTRIM ( in_alias7desc ), in_alias7 );
		END IF;

		IF RTRIM ( in_alias7 ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitemalias
							(
							  custid, item, itemalias,
							  aliasdesc, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), UPPER ( RTRIM ( in_alias7 ) ),
						   NVL ( RTRIM ( in_alias7desc ), in_alias7 ), 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemalias
					SET    aliasdesc = NVL ( RTRIM ( in_alias7desc ), in_alias7 ), lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    itemalias = UPPER ( RTRIM ( in_alias7 ) );

					IF SQL%ROWCOUNT = 0 THEN
						out_errorno := 105;
						out_msg :=
							   'Alias7 value of '
							|| RTRIM ( in_alias7 )
							|| ' is already in use';
						log_msg ( 'E' );
						RETURN;
					END IF;
			END;
		END IF;

		IF RTRIM ( in_alias8 ) IS NOT NULL
		   AND RTRIM ( NVL ( in_alias8wipe, 'N' ) ) = 'Y' THEN
			DELETE FROM custitemalias
			WHERE  custid = UPPER ( RTRIM ( in_custid ) )
			AND    item = UPPER ( RTRIM ( in_item ) )
			AND    aliasdesc = NVL ( RTRIM ( in_alias8desc ), in_alias8 );
		END IF;

		IF RTRIM ( in_alias8 ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitemalias
							(
							  custid, item, itemalias,
							  aliasdesc, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), UPPER ( RTRIM ( in_alias8 ) ),
						   NVL ( RTRIM ( in_alias8desc ), in_alias8 ), 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemalias
					SET    aliasdesc = NVL ( RTRIM ( in_alias8desc ), in_alias8 ), lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    itemalias = UPPER ( RTRIM ( in_alias8 ) );

					IF SQL%ROWCOUNT = 0 THEN
						out_errorno := 105;
						out_msg :=
							   'Alias8 value of '
							|| RTRIM ( in_alias8 )
							|| ' is already in use';
						log_msg ( 'E' );
						RETURN;
					END IF;
			END;
		END IF;

		IF RTRIM ( in_alias9 ) IS NOT NULL
		   AND RTRIM ( NVL ( in_alias9wipe, 'N' ) ) = 'Y' THEN
			DELETE FROM custitemalias
			WHERE  custid = UPPER ( RTRIM ( in_custid ) )
			AND    item = UPPER ( RTRIM ( in_item ) )
			AND    aliasdesc = NVL ( RTRIM ( in_alias9desc ), in_alias9 );
		END IF;

		IF RTRIM ( in_alias9 ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitemalias
							(
							  custid, item, itemalias,
							  aliasdesc, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), UPPER ( RTRIM ( in_alias9 ) ),
						   NVL ( RTRIM ( in_alias9desc ), in_alias9 ), 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemalias
					SET    aliasdesc = NVL ( RTRIM ( in_alias9desc ), in_alias9 ), lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    itemalias = UPPER ( RTRIM ( in_alias9 ) );

					IF SQL%ROWCOUNT = 0 THEN
						out_errorno := 105;
						out_msg :=
							   'Alias9 value of '
							|| RTRIM ( in_alias9 )
							|| ' is already in use';
						log_msg ( 'E' );
						RETURN;
					END IF;
			END;
		END IF;

		IF RTRIM ( in_alias10 ) IS NOT NULL
		   AND RTRIM ( NVL ( in_alias10wipe, 'N' ) ) = 'Y' THEN
			DELETE FROM custitemalias
			WHERE  custid = UPPER ( RTRIM ( in_custid ) )
			AND    item = UPPER ( RTRIM ( in_item ) )
			AND    aliasdesc = NVL ( RTRIM ( in_alias10desc ), in_alias10 );
		END IF;

		IF RTRIM ( in_alias10 ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitemalias
							(
							  custid, item, itemalias,
							  aliasdesc, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), UPPER ( RTRIM ( in_alias10 ) ),
						   NVL ( RTRIM ( in_alias10desc ), in_alias10 ), 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemalias
					SET    aliasdesc = NVL ( RTRIM ( in_alias10desc ), in_alias10 ), lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    itemalias = UPPER ( RTRIM ( in_alias10 ) );

					IF SQL%ROWCOUNT = 0 THEN
						out_errorno := 105;
						out_msg :=
							   'Alias10 value of '
							|| RTRIM ( in_alias10 )
							|| ' is already in use';
						log_msg ( 'E' );
						RETURN;
					END IF;
			END;
		END IF;

		IF RTRIM ( in_alias11 ) IS NOT NULL
		   AND RTRIM ( NVL ( in_alias11wipe, 'N' ) ) = 'Y' THEN
			DELETE FROM custitemalias
			WHERE  custid = UPPER ( RTRIM ( in_custid ) )
			AND    item = UPPER ( RTRIM ( in_item ) )
			AND    aliasdesc = NVL ( RTRIM ( in_alias11desc ), in_alias11 );
		END IF;

		IF RTRIM ( in_alias11 ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitemalias
							(
							  custid, item, itemalias,
							  aliasdesc, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), UPPER ( RTRIM ( in_alias11 ) ),
						   NVL ( RTRIM ( in_alias11desc ), in_alias11 ), 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemalias
					SET    aliasdesc = NVL ( RTRIM ( in_alias11desc ), in_alias11 ), lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    itemalias = UPPER ( RTRIM ( in_alias11 ) );

					IF SQL%ROWCOUNT = 0 THEN
						out_errorno := 105;
						out_msg :=
							   'Alias11 value of '
							|| RTRIM ( in_alias11 )
							|| ' is already in use';
						log_msg ( 'E' );
						RETURN;
					END IF;
			END;
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			out_msg := 'zimi ' || SQLERRM;
			out_errorno := SQLCODE;
	END weber_import_item;



	--THIS IS THE SAME AS THE ABOVE PROC AND SHOULD BE UPDATED TOGETHER
	--THE ONLY DIFFERENCE IS WE ALLOW ACTIVE ITEMS TO GET DIMS, WEIGHT AND CUBE UPDATED
	PROCEDURE weber_import_item2
	(
		in_func IN OUT VARCHAR2, in_custid IN VARCHAR2, in_item IN VARCHAR2,
		in_descr IN VARCHAR2, in_abbrev IN OUT VARCHAR2, in_baseuom IN VARCHAR2, in_stackheightuom IN VARCHAR2, in_cube IN NUMBER, in_weight IN NUMBER, in_hazardous IN VARCHAR2, in_lotrequired IN VARCHAR2, in_serialrequired IN VARCHAR2, in_user1required IN VARCHAR2, in_user2required IN VARCHAR2, in_user3required IN VARCHAR2, in_mfgdaterequired IN VARCHAR2, in_expdaterequired IN VARCHAR2, in_countryrequired IN VARCHAR2, in_to_uom1 IN VARCHAR2, in_to_uom1_qty IN NUMBER, in_to_uom2 IN VARCHAR2, in_to_uom2_qty IN NUMBER, in_to_uom3 IN VARCHAR2, in_to_uom3_qty IN NUMBER, in_to_uom4 IN VARCHAR2, in_to_uom4_qty IN NUMBER, in_rategroup IN VARCHAR2, in_shelflife IN NUMBER, in_countryof IN VARCHAR2, in_bolcomment IN VARCHAR2, in_alias1wipe IN VARCHAR2, in_alias1 IN VARCHAR2, in_alias1desc IN VARCHAR2, in_alias2wipe IN VARCHAR2, in_alias2 IN VARCHAR2, in_alias2desc IN VARCHAR2, in_alias3wipe IN VARCHAR2, in_alias3 IN VARCHAR2, in_alias3desc IN VARCHAR2, in_alias4wipe IN VARCHAR2, in_alias4 IN VARCHAR2, in_alias4desc IN VARCHAR2, in_alias5wipe IN VARCHAR2, in_alias5 IN VARCHAR2, in_alias5desc IN VARCHAR2, in_alias6wipe IN VARCHAR2, in_alias6 IN VARCHAR2, in_alias6desc IN VARCHAR2, in_alias7wipe IN VARCHAR2, in_alias7 IN VARCHAR2, in_alias7desc IN VARCHAR2, in_alias8wipe IN VARCHAR2, in_alias8 IN VARCHAR2, in_alias8desc IN VARCHAR2, in_alias9wipe IN VARCHAR2, in_alias9 IN VARCHAR2, in_alias9desc IN VARCHAR2, in_alias10wipe IN VARCHAR2, in_alias10 IN VARCHAR2, in_alias10desc IN VARCHAR2, in_alias11wipe IN VARCHAR2, in_alias11 IN VARCHAR2, in_alias11desc IN VARCHAR2, in_add_status IN VARCHAR2, in_delete_status IN VARCHAR2, in_add_review_yn IN VARCHAR2, in_update_review_yn IN VARCHAR2, in_delete_review_yn IN VARCHAR2, in_length IN NUMBER, in_width IN NUMBER, in_height IN NUMBER, in_tms_commodity_code IN VARCHAR2, in_nmfc IN VARCHAR2, in_nmfc_article IN VARCHAR2, in_useramt1 IN NUMBER, in_useramt2 IN NUMBER, in_uom_update IN VARCHAR2, in_critlevel1 IN NUMBER, in_critlevel2 IN NUMBER, in_critlevel3 IN NUMBER, in_labeluom IN VARCHAR2, in_productgroup IN VARCHAR2, in_picktotype IN VARCHAR2, in_cartontype IN VARCHAR2, in_passthrunum01 IN NUMBER, in_passthrunum02 IN NUMBER, in_passthrunum03 IN NUMBER, in_passthrunum04 IN NUMBER, in_passthruchar01 IN VARCHAR2, in_passthruchar02 IN VARCHAR2, in_passthruchar03 IN VARCHAR2, in_passthruchar04 IN VARCHAR2, in_uom_picktotype IN VARCHAR2
		, in_uom_cartontype IN VARCHAR2, out_errorno IN OUT NUMBER, out_msg IN OUT VARCHAR2
	) IS
		CURSOR curCustomer IS
			SELECT name
			FROM   customer
			WHERE  custid = UPPER ( RTRIM ( in_custid ) );

		cs curCustomer%ROWTYPE;

		CURSOR curCustItem IS
			SELECT ci.descr, ci.status, SUM ( NVL ( cit.qty, 0 ) ) qty
			FROM   custitem ci, custitemtot cit
			WHERE  ci.custid = cit.custid(+)
			AND    ci.item = cit.item(+)
			AND    cit.invstatus(+) = 'AV'
			AND    ci.custid = UPPER ( RTRIM ( in_custid ) )
			AND    ci.item = UPPER ( RTRIM ( in_item ) )
			GROUP BY ci.descr, ci.status, cit.invstatus;

		ci curCustItem%ROWTYPE;

		uom_sequence custitemuom.sequence%TYPE;
		wrk custitem%ROWTYPE;
		uomqty custitemuom.qty%TYPE;
		uomqty2 custitemuom.qty%TYPE;
		str_subject VARCHAR2 ( 500 );
		real_cube NUMBER;

		PROCEDURE log_msg ( in_msgtype VARCHAR2 ) IS
			strMsg appmsgs.msgtext%TYPE;
		BEGIN
			out_msg := ' Item: ' || RTRIM ( in_item ) || ': ' || out_msg;
			zms.log_msg
			(
				'IMPEXP', NULL, RTRIM ( in_custid ),
				out_msg, NVL ( RTRIM ( in_msgtype ), 'E' ), 'WEBERIMP',
				strMsg
			);
		END;

		PROCEDURE update_uom
		(
			in_seq NUMBER, in_qty NUMBER, in_from_uom VARCHAR2,
			in_to_uom VARCHAR2
		) IS
		BEGIN
			BEGIN
				INSERT INTO custitemuom
							(
							  custid, item, sequence,
							  qty, fromuom, touom,
							  lastuser, lastupdate, velocity,
							  picktotype, cartontype
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), in_seq,
						   in_qty, in_from_uom, in_to_uom,
						   'WEBERIMP', SYSDATE, 'C',
						   NVL ( in_uom_picktotype, 'FULL' ), NVL ( in_uom_cartontype, 'PLT' )
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemuom
					SET    fromuom = in_from_uom, touom = in_to_uom, qty = in_qty
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    sequence = in_seq;
			END;
		END;
	BEGIN
		IF RTRIM ( UPPER ( in_func ) ) NOT IN ( 'A', 'U', 'D' ) THEN
			out_errorno := 4;
			out_msg := 'Invalid function code: ' || in_func;
			log_msg ( 'E' );
			RETURN;
		END IF;

		IF RTRIM ( in_custid ) IS NULL THEN
			out_errorno := 1;
			out_msg := 'Customer ID is required';
			log_msg ( 'E' );
			RETURN;
		END IF;

		cs := NULL;

		OPEN curCustomer;

		FETCH curCustomer
			INTO   cs;

		CLOSE curCustomer;

		IF cs.name IS NULL THEN
			out_errorno := 2;
			out_msg := 'Invalid Customer ID: ' || in_custid;
			log_msg ( 'E' );
			RETURN;
		END IF;

		IF RTRIM ( in_item ) IS NULL THEN
			out_errorno := 3;
			out_msg := 'Item ID is required';
			log_msg ( 'E' );
			RETURN;
		END IF;

		ci := NULL;

		OPEN curCustItem;

		FETCH curCustItem
			INTO   ci;

		CLOSE curCustItem;

		IF ci.descr IS NULL THEN
			IF UPPER ( RTRIM ( in_func ) ) = 'D' THEN
				out_errorno := 5;
				out_msg := 'Item not found for deletion: ' || in_item;
				log_msg ( 'E' );
				RETURN;
			END IF;

			IF UPPER ( RTRIM ( in_func ) ) = 'U' THEN
				out_msg :=
					'Item not found for update (add performed): ' || in_item;
				log_msg ( 'W' );
				in_func := 'A';
			END IF;
		ELSE
			IF UPPER ( RTRIM ( in_func ) ) = 'A' THEN
				out_msg :=
					   'Item to be added already on file (update performed): '
					|| in_item;
				log_msg ( 'W' );
				in_func := 'U';
			END IF;
		END IF;

		IF UPPER ( RTRIM ( in_func ) ) = 'A' THEN
			wrk.status := in_add_status;
			wrk.needs_review_yn := in_add_review_yn;
		ELSIF UPPER ( RTRIM ( in_func ) ) = 'U' THEN
			wrk.status := ci.status;
			wrk.needs_review_yn := in_update_review_yn;
		ELSE
			wrk.status := in_delete_status;
			wrk.needs_review_yn := in_delete_review_yn;
		END IF;

		IF RTRIM ( in_abbrev ) IS NULL THEN
			in_abbrev :=
				SUBSTR
				(
					in_descr, 1, 12
				);
		END IF;

		IF in_cube IS NULL
		   AND in_length IS NOT NULL
		   AND in_width IS NOT NULL
		   AND in_height IS NOT NULL THEN
			real_cube := in_length * in_width * in_height;
		ELSE
			real_cube := in_cube;
		END IF;

		-- if no item then just create it
		IF ci.status IS NULL THEN
			INSERT INTO custitem
						(
						  custid, item, descr,
						  abbrev, status, baseuom,
						  stackheightuom, cube, weight,
						  hazardous, shelflife, min_sale_life,
						  lotrequired, serialrequired, user1required,
						  user2required, user3required, mfgdaterequired,
						  expdaterequired, countryrequired, allowsub,
						  backorder, invstatusind, invclassind,
						  qtytype, velocity, recvinvstatus,
						  weightcheckrequired, ordercheckrequired, use_fifo,
						  putawayconfirmation, nodamaged, iskit,
						  subslprsnrequired, lotsumreceipt, lotsumrenewal,
						  lotsumbol, lotsumaccess, lotfmtaction,
						  serialfmtaction, user1fmtaction, user2fmtaction,
						  user3fmtaction, maxqtyof1, rategroup,
						  serialasncapture, user1asncapture, user2asncapture,
						  user3asncapture, lastuser, lastupdate,
						  needs_review_yn, countryof, LENGTH,
						  width, height, tms_commodity_code,
						  nmfc, nmfc_article, useramt1,
						  useramt2, critlevel1, critlevel2,
						  critlevel3, labeluom, productgroup,
						  picktotype, cartontype, itmpassthrunum01,
						  itmpassthrunum02, itmpassthrunum03, itmpassthrunum04, itmpassthruchar01, itmpassthruchar02, itmpassthruchar03
						  , itmpassthruchar04
						)
			VALUES
				   (
					   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), RTRIM ( in_descr ),
					   RTRIM ( in_abbrev ), wrk.status, NVL ( UPPER ( RTRIM ( in_baseuom ) ), 'EA' ),
					   NVL ( UPPER ( RTRIM ( in_stackheightuom ) ), 'PLT' ), NVL ( real_cube, 0 ), NVL ( in_weight, 0 ),
					   NVL ( UPPER ( RTRIM ( in_hazardous ) ), 'N' ), NVL ( in_shelflife, 0 ), NVL ( in_shelflife, 0 ),
					   RTRIM ( NVL ( in_lotrequired, 'C' ) ), RTRIM ( NVL ( in_serialrequired, 'C' ) ), RTRIM ( NVL ( in_user1required, 'C' ) ),
					   RTRIM ( NVL ( in_user2required, 'C' ) ), RTRIM ( NVL ( in_user3required, 'C' ) ), RTRIM ( NVL ( in_mfgdaterequired, 'C' ) ),
					   RTRIM ( NVL ( in_expdaterequired, 'C' ) ), RTRIM ( NVL ( in_countryrequired, 'C' ) ), 'C',
					   'C', 'C', 'C',
					   'C', 'C', 'AV',
					   'C', 'C', 'N',
					   'C', 'C', 'N',
					   'C', 'N', 'N',
					   'N', 'N', 'C',
					   'C', 'C', 'C',
					   'C', 'C', in_rategroup,
					   'C', 'C', 'C',
					   'C', 'WEBERIMP', SYSDATE,
					   wrk.needs_review_yn, UPPER ( RTRIM ( in_countryof ) ), in_length,
					   in_width, in_height, in_tms_commodity_code,
					   in_nmfc, in_nmfc_article, in_useramt1,
					   in_useramt2, in_critlevel1, in_critlevel2,
					   in_critlevel3, in_labeluom, in_productgroup,
					   in_picktotype, in_cartontype, in_passthrunum01,
					   in_passthrunum02, in_passthrunum03, in_passthrunum04,
					   in_passthruchar01, in_passthruchar02, in_passthruchar03,
					   in_passthruchar04
				   );

			--create uom conversions
			IF ( RTRIM ( in_to_uom1 ) IS NOT NULL )
			   AND ( NVL ( in_to_uom1_qty, 0 ) <> 0 ) THEN
				DELETE FROM custitemuom
				WHERE  custid = UPPER ( RTRIM ( in_custid ) )
				AND    item = UPPER ( RTRIM ( in_item ) );

				uom_sequence := 10;

				INSERT INTO custitemuom
							(
							  custid, item, sequence,
							  qty, fromuom, touom,
							  lastuser, lastupdate, velocity,
							  picktotype, cartontype
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), uom_sequence,
						   in_to_uom1_qty, NVL ( UPPER ( RTRIM ( in_baseuom ) ), 'EA' ), UPPER ( RTRIM ( in_to_uom1 ) ),
						   'WEBERIMP', SYSDATE, 'C',
						   NVL ( in_uom_picktotype, 'FULL' ), NVL ( in_uom_cartontype, 'PLT' )
					   );

				IF ( RTRIM ( in_to_uom2 ) IS NOT NULL )
				   AND ( NVL ( in_to_uom2_qty, 0 ) <> 0 ) THEN
					uom_sequence := uom_sequence + 10;

					INSERT INTO custitemuom
								(
								  custid, item, sequence,
								  qty, fromuom, touom,
								  lastuser, lastupdate, velocity,
								  picktotype, cartontype
								)
					VALUES
						   (
							   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), uom_sequence,
							   in_to_uom2_qty, UPPER ( RTRIM ( in_to_uom1 ) ), UPPER ( RTRIM ( in_to_uom2 ) ),
							   'WEBERIMP', SYSDATE, 'C',
							   NVL ( in_uom_picktotype, 'FULL' ), NVL ( in_uom_cartontype, 'PLT' )
						   );

					IF ( RTRIM ( in_to_uom3 ) IS NOT NULL )
					   AND ( NVL ( in_to_uom3_qty, 0 ) <> 0 ) THEN
						uom_sequence := uom_sequence + 10;

						INSERT INTO custitemuom
									(
									  custid, item, sequence,
									  qty, fromuom, touom,
									  lastuser, lastupdate, velocity,
									  picktotype, cartontype
									)
						VALUES
							   (
								   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), uom_sequence,
								   in_to_uom3_qty, UPPER ( RTRIM ( in_to_uom2 ) ), UPPER ( RTRIM ( in_to_uom3 ) ),
								   'WEBERIMP', SYSDATE, 'C',
								   NVL ( in_uom_picktotype, 'FULL' ), NVL ( in_uom_cartontype, 'PLT' )
							   );

						IF ( RTRIM ( in_to_uom4 ) IS NOT NULL )
						   AND ( NVL ( in_to_uom4_qty, 0 ) <> 0 ) THEN
							uom_sequence := uom_sequence + 10;

							INSERT INTO custitemuom
										(
										  custid, item, sequence,
										  qty, fromuom, touom,
										  lastuser, lastupdate, velocity,
										  picktotype, cartontype
										)
							VALUES
								   (
									   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), uom_sequence,
									   in_to_uom4_qty, UPPER ( RTRIM ( in_to_uom3 ) ), UPPER ( RTRIM ( in_to_uom4 ) ),
									   'WEBERIMP', SYSDATE, 'C',
									   NVL ( in_uom_picktotype, 'FULL' ), NVL ( in_uom_cartontype, 'PLT' )
								   );
						END IF;
					END IF;
				END IF;
			END IF;
		ELSE
			IF ci.status = 'ACTV' THEN
				--if active only update description, shelflife, nmfc, critlevel, all passthru fields, itemaliases
				UPDATE custitem
				SET --descr = nvl(rtrim(in_descr),descr),
					--abbrev = nvl(rtrim(in_abbrev),abbrev),
					   status = wrk.status, --baseuom = nvl(upper(rtrim(in_baseuom)),baseuom),
											--stackheightuom = nvl(upper(rtrim(in_stackheightuom)),'PLT'),
											cube = NVL ( real_cube, cube ), weight = NVL ( in_weight, weight ),
					   --hazardous = nvl(upper(rtrim(in_hazardous)),hazardous),
					   --shelflife = nvl(in_shelflife,shelflife),
					   --min_sale_life = nvl(in_shelflife,shelflife),
					   lastuser = 'WEBERIMP', lastupdate = SYSDATE, needs_review_yn = wrk.needs_review_yn,
					   LENGTH = NVL ( in_length, LENGTH ), width = NVL ( in_width, width ), height = NVL ( in_height, height ) --,
				--nmfc = in_nmfc,
				--nmfc_article = in_nmfc_article,
				--rategroup = in_rategroup,
				--useramt1 = in_useramt1,
				--useramt2 = in_useramt2,
				--critlevel1 = in_critlevel1,
				--critlevel2 = in_critlevel2,
				--critlevel3 = in_critlevel3,
				--labeluom = in_labeluom,
				--productgroup = in_productgroup,
				--picktotype = in_picktotype,
				--cartontype = in_cartontype,
				--itmpassthrunum01=nvl(in_passthrunum01, itmpassthrunum01),
				--itmpassthrunum02=nvl(in_passthrunum02, itmpassthrunum02),
				--itmpassthrunum03=nvl(in_passthrunum03, itmpassthrunum03),
				--itmpassthrunum04=nvl(in_passthrunum04, itmpassthrunum04),
				--itmpassthruchar01=nvl(in_passthruchar01, itmpassthruchar01),
				--itmpassthruchar02=nvl(in_passthruchar02, itmpassthruchar02),
				--itmpassthruchar03=nvl(in_passthruchar03, itmpassthruchar03),
				--itmpassthruchar04=nvl(in_passthruchar04, itmpassthruchar04)
				WHERE  custid = UPPER ( RTRIM ( in_custid ) )
				AND    item = UPPER ( RTRIM ( in_item ) );

				BEGIN
					SELECT qty
					INTO   uomqty
					FROM   custitemuom
					WHERE  ROWNUM = 1
					AND    custid = RTRIM ( in_custid )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    sequence = 10;
				EXCEPTION
					WHEN OTHERS THEN
						uomqty := 0;
				END;

				BEGIN
					SELECT qty
					INTO   uomqty2
					FROM   custitemuom
					WHERE  ROWNUM = 1
					AND    custid = RTRIM ( in_custid )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    sequence = 20;
				EXCEPTION
					WHEN OTHERS THEN
						uomqty2 := 0;
				END;



				--time to check for UOM Conversion and if different then we need to send an email
				--old statement which didn't care of the uom existed before checking to compare
				--IF NVL(uomqty,0)!=NVL(rtrim(in_useramt1),rtrim(in_abbrev)) or NVL(uomqty2,0)!=NVL(rtrim(in_useramt2),0) THEN
				IF NVL ( uomqty, 0 ) !=
					   NVL ( RTRIM ( in_useramt1 ), RTRIM ( in_abbrev ) )
				   OR ( NVL ( uomqty2, 0 ) !=
						   NVL ( RTRIM ( in_useramt2 ), 0 )
					   AND NVL ( uomqty2, 0 ) <> 0
					   AND NVL ( RTRIM ( in_useramt2 ), 0 ) <> 0 ) THEN
					DECLARE
						conn UTL_SMTP.connection;
					BEGIN
						IF NVL ( uomqty2, 0 ) !=
							   NVL ( RTRIM ( in_useramt2 ), 0 ) THEN
							str_subject :=
								   'New UOM for CustID '
								|| in_custid
								|| ' / Item '
								|| UPPER ( RTRIM ( in_item ) )
								|| ' / QTY from '
								|| NVL ( uomqty, 0 )
								|| ' to '
								|| NVL
								   (
									   RTRIM ( in_useramt1 ),
									   RTRIM ( in_abbrev )
								   )
								|| ' seq 10 / '
								|| uomqty2
								|| ' to '
								|| NVL ( RTRIM ( in_useramt2 ), 0 )
								|| ' seq 20';
						ELSE
							str_subject :=
								   'New UOM for CustID '
								|| in_custid
								|| ' / Item '
								|| UPPER ( RTRIM ( in_item ) )
								|| ' / QTY from '
								|| NVL ( uomqty, 0 )
								|| ' to '
								|| NVL
								   (
									   RTRIM ( in_useramt1 ),
									   RTRIM ( in_abbrev )
								   );
						END IF;

						conn :=
							weber_mail.begin_mail
							(
								sender => 'New UOM <edi@weberlogistics.com>', recipients => in_custid || ' <' || in_custid || 'uom@weberlogistics.com>', subject => str_subject
								, mime_type => 'text/html'
							);

						weber_mail.write_text
						(
							conn => conn, MESSAGE => '<HTML>' || '<BODY leftmargin="0" rightmargin="0" topmargin="0" marginwidth="0" marginheight="0" bgcolor="#FFFFFF">' || '<font face="Arial, Helvetica, sans-serif">' || '<table width="100%" border="0" cellspacing="0" cellpadding="2">' || '<tr>' || '<td bgcolor="#000000"><font size="2" face="Verdana, Arial, Helvetica, sans-serif" color="#FFFFFF"><b>Item Details</b></font></td>' || '</tr>' || '<tr align="center">' || '<td bgcolor="#CCCCCC" colspan="2" valign="top">' || '<table width="100%" border="0" cellspacing="0" cellpadding="5" bgcolor="#FFFFFF">' || '<tr>' || '<td width=15% bgcolor="FFFFFF" colspan=10 nowrap><font face="Verdana, Arial, Helvetica, sans-serif" size="2" color="0000FF"><b>CustID ' || in_custid || '</b></font></td>' || '<td width=15% bgcolor="FFFFFF" colspan=10 nowrap><font face="Verdana, Arial, Helvetica, sans-serif" size="2" color="0000FF"><b>Item ' || UPPER ( RTRIM ( in_item ) ) || '</b></font></td>' || '<td bgcolor="FFFFFF" colspan=10 nowrap><font face="Verdana, Arial, Helvetica, sans-serif" size="2" color="0000FF"><b>UOM from ' || NVL ( uomqty, 0 ) || ' to ' || NVL ( RTRIM ( in_useramt1 ), RTRIM ( in_abbrev ) ) || ' seq 10</b></font></td>' || '<td bgcolor="FFFFFF" colspan=10 nowrap><font face="Verdana, Arial, Helvetica, sans-serif" size="2" color="0000FF"><b>UOM from ' || NVL ( uomqty2, 0 ) || ' to ' || NVL ( RTRIM ( in_useramt2 ), 0 ) || ' seq 20</b></font></td>' || '</tr>' || '</table>' || '</td>' || '</tr>' || '</table>' || '</font>' || '</body>' || '</html>'
						);

						weber_mail.end_mail ( conn => conn );
					EXCEPTION
						WHEN OTHERS THEN
							zms.log_msg
							(
								'WEBERIMP', NULL, in_custid,
								'MAIL DID NOT SEND, IS THE CUSTID EMAIL SETUP?', 'I', 'WEBERIMP'
								, out_msg
							);
					END;
				END IF;
			ELSE --this must be 'INAC'
				--if inactive we can update all fields

				UPDATE custitem
				SET    descr = NVL ( RTRIM ( in_descr ), descr ), abbrev = NVL ( RTRIM ( in_abbrev ), abbrev ), status = 'ACTV', --wrk.status,
					   baseuom = NVL ( UPPER ( RTRIM ( in_baseuom ) ), baseuom ), stackheightuom = NVL ( UPPER ( RTRIM ( in_stackheightuom ) ), 'PLT' ), cube = NVL ( real_cube, cube ),
					   weight = NVL ( in_weight, weight ), hazardous = NVL ( UPPER ( RTRIM ( in_hazardous ) ), hazardous ), lotrequired = RTRIM ( NVL ( in_lotrequired, 'C' ) ),
					   serialrequired = RTRIM ( NVL ( in_serialrequired, 'C' ) ), user1required = RTRIM ( NVL ( in_user1required, 'C' ) ), user2required = RTRIM ( NVL ( in_user2required, 'C' ) ),
					   user3required = RTRIM ( NVL ( in_user3required, 'C' ) ), mfgdaterequired = RTRIM ( NVL ( in_mfgdaterequired, 'C' ) ), expdaterequired = RTRIM ( NVL ( in_expdaterequired, 'C' ) ),
					   countryrequired = RTRIM ( NVL ( in_countryrequired, 'C' ) ), shelflife = NVL ( in_shelflife, shelflife ), min_sale_life = NVL ( in_shelflife, shelflife ),
					   lastuser = 'WEBERIMP', lastupdate = SYSDATE, needs_review_yn = wrk.needs_review_yn,
					   LENGTH = NVL ( in_length, LENGTH ), width = NVL ( in_width, width ), height = NVL ( in_height, height ),
					   nmfc = in_nmfc, nmfc_article = in_nmfc_article, rategroup = in_rategroup,
					   useramt1 = in_useramt1, useramt2 = in_useramt2, critlevel1 = in_critlevel1,
					   critlevel2 = in_critlevel2, critlevel3 = in_critlevel3, labeluom = in_labeluom,
					   productgroup = in_productgroup, picktotype = in_picktotype, cartontype = in_cartontype,
					   itmpassthrunum01 = NVL ( in_passthrunum01, itmpassthrunum01 ), itmpassthrunum02 = NVL ( in_passthrunum02, itmpassthrunum02 ), itmpassthrunum03 = NVL ( in_passthrunum03, itmpassthrunum03 ),
					   itmpassthrunum04 = NVL ( in_passthrunum04, itmpassthrunum04 ), itmpassthruchar01 = NVL ( in_passthruchar01, itmpassthruchar01 ), itmpassthruchar02 = NVL ( in_passthruchar02, itmpassthruchar02 ),
					   itmpassthruchar03 = NVL ( in_passthruchar03, itmpassthruchar03 ), itmpassthruchar04 = NVL ( in_passthruchar04, itmpassthruchar04 )
				WHERE  custid = UPPER ( RTRIM ( in_custid ) )
				AND    item = UPPER ( RTRIM ( in_item ) );

				--not sure if we want to allow uom conversions from customers? I'll use this uomupdate flag to allow or disallow insert/update
				--copy and move this within the above if statementss if we want different rules for actv items vs inac items
				IF NVL ( in_uom_update, 'N' ) = 'Y' THEN
					NULL;

					IF ( RTRIM ( in_to_uom1 ) IS NOT NULL )
					   AND ( NVL ( in_to_uom1_qty, 0 ) <> 0 ) THEN
						uom_sequence := 10;
						update_uom
						(
							uom_sequence, in_to_uom1_qty, NVL ( UPPER ( RTRIM ( in_baseuom ) ), 'EA' )
							, UPPER ( RTRIM ( in_to_uom1 ) )
						);

						IF ( RTRIM ( in_to_uom2 ) IS NOT NULL )
						   AND ( NVL ( in_to_uom2_qty, 0 ) <> 0 ) THEN
							uom_sequence := uom_sequence + 10;
							update_uom
							(
								uom_sequence, in_to_uom2_qty, UPPER ( RTRIM ( in_to_uom1 ) )
								, UPPER ( RTRIM ( in_to_uom2 ) )
							);

							IF ( RTRIM ( in_to_uom3 ) IS NOT NULL )
							   AND ( NVL ( in_to_uom3_qty, 0 ) <> 0 ) THEN
								uom_sequence := uom_sequence + 10;

								update_uom
								(
									uom_sequence, in_to_uom3_qty, UPPER ( RTRIM ( in_to_uom2 ) )
									, UPPER ( RTRIM ( in_to_uom3 ) )
								);

								IF ( RTRIM ( in_to_uom4 ) IS NOT NULL )
								   AND ( NVL ( in_to_uom4_qty, 0 ) <> 0 ) THEN
									uom_sequence := uom_sequence + 10;

									update_uom
									(
										uom_sequence, in_to_uom4_qty, UPPER ( RTRIM ( in_to_uom3 ) )
										, UPPER ( RTRIM ( in_to_uom4 ) )
									);
								END IF;
							END IF;
						END IF;

						DELETE FROM custitemuom
						WHERE  custid = UPPER ( RTRIM ( in_custid ) )
						AND    item = UPPER ( RTRIM ( in_item ) )
						AND    sequence > uom_sequence;
					END IF;
				END IF;
			END IF;
		END IF;


		--do we want customers to be able to update bol comments?
		IF RTRIM ( in_bolcomment ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitembolcomments
							(
							  custid, item, consignee,
							  comment1, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), NULL,
						   in_bolcomment, 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitembolcomments
					SET    comment1 = in_bolcomment, lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    consignee IS NULL;
			END;
		END IF;

		--add or update UPC code
		IF RTRIM ( in_alias1 ) IS NOT NULL
		   AND RTRIM ( NVL ( in_alias1wipe, 'N' ) ) = 'Y' THEN
			DELETE FROM custitemalias
			WHERE  custid = UPPER ( RTRIM ( in_custid ) )
			AND    item = UPPER ( RTRIM ( in_item ) )
			AND    aliasdesc = NVL ( RTRIM ( in_alias1desc ), in_alias1 );
		END IF;

		IF RTRIM ( in_alias1 ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitemalias
							(
							  custid, item, itemalias,
							  aliasdesc, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), UPPER ( RTRIM ( in_alias1 ) ),
						   NVL ( RTRIM ( in_alias1desc ), in_alias1 ), 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemalias
					SET    aliasdesc = NVL ( RTRIM ( in_alias1desc ), in_alias1 ), lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    itemalias = UPPER ( RTRIM ( in_alias1 ) );
			END;
		END IF;

		--add or update second alias, probably mainly GTIN
		IF RTRIM ( in_alias2 ) IS NOT NULL
		   AND RTRIM ( NVL ( in_alias2wipe, 'N' ) ) = 'Y' THEN
			DELETE FROM custitemalias
			WHERE  custid = UPPER ( RTRIM ( in_custid ) )
			AND    item = UPPER ( RTRIM ( in_item ) )
			AND    aliasdesc = NVL ( RTRIM ( in_alias2desc ), in_alias2 );
		END IF;

		IF RTRIM ( in_alias2 ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitemalias
							(
							  custid, item, itemalias,
							  aliasdesc, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), UPPER ( RTRIM ( in_alias2 ) ),
						   NVL ( RTRIM ( in_alias2desc ), in_alias2 ), 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemalias
					SET    aliasdesc = NVL ( RTRIM ( in_alias2desc ), in_alias2 ), lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    itemalias = UPPER ( RTRIM ( in_alias2 ) );

					IF SQL%ROWCOUNT = 0 THEN
						out_errorno := 105;
						out_msg :=
							   'Alias2 value of '
							|| RTRIM ( in_alias2 )
							|| ' is already in use';
						log_msg ( 'E' );
						RETURN;
					END IF;
			END;
		END IF;

		--add or update third alias, just in case
		IF RTRIM ( in_alias3 ) IS NOT NULL
		   AND RTRIM ( NVL ( in_alias3wipe, 'N' ) ) = 'Y' THEN
			DELETE FROM custitemalias
			WHERE  custid = UPPER ( RTRIM ( in_custid ) )
			AND    item = UPPER ( RTRIM ( in_item ) )
			AND    aliasdesc = NVL ( RTRIM ( in_alias3desc ), in_alias3 );
		END IF;

		IF RTRIM ( in_alias3 ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitemalias
							(
							  custid, item, itemalias,
							  aliasdesc, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), UPPER ( RTRIM ( in_alias3 ) ),
						   NVL ( RTRIM ( in_alias3desc ), in_alias3 ), 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemalias
					SET    aliasdesc = NVL ( RTRIM ( in_alias3desc ), in_alias3 ), lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    itemalias = UPPER ( RTRIM ( in_alias3 ) );

					IF SQL%ROWCOUNT = 0 THEN
						out_errorno := 105;
						out_msg :=
							   'Alias3 value of '
							|| RTRIM ( in_alias3 )
							|| ' is already in use';
						log_msg ( 'E' );
						RETURN;
					END IF;
			END;
		END IF;

		IF RTRIM ( in_alias4 ) IS NOT NULL
		   AND RTRIM ( NVL ( in_alias4wipe, 'N' ) ) = 'Y' THEN
			DELETE FROM custitemalias
			WHERE  custid = UPPER ( RTRIM ( in_custid ) )
			AND    item = UPPER ( RTRIM ( in_item ) )
			AND    aliasdesc = NVL ( RTRIM ( in_alias4desc ), in_alias4 );
		END IF;

		IF RTRIM ( in_alias4 ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitemalias
							(
							  custid, item, itemalias,
							  aliasdesc, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), UPPER ( RTRIM ( in_alias4 ) ),
						   NVL ( RTRIM ( in_alias4desc ), in_alias4 ), 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemalias
					SET    aliasdesc = NVL ( RTRIM ( in_alias4desc ), in_alias4 ), lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    itemalias = UPPER ( RTRIM ( in_alias4 ) );

					IF SQL%ROWCOUNT = 0 THEN
						out_errorno := 105;
						out_msg :=
							   'Alias4 value of '
							|| RTRIM ( in_alias4 )
							|| ' is already in use';
						log_msg ( 'E' );
						RETURN;
					END IF;
			END;
		END IF;

		IF RTRIM ( in_alias5 ) IS NOT NULL
		   AND RTRIM ( NVL ( in_alias5wipe, 'N' ) ) = 'Y' THEN
			DELETE FROM custitemalias
			WHERE  custid = UPPER ( RTRIM ( in_custid ) )
			AND    item = UPPER ( RTRIM ( in_item ) )
			AND    aliasdesc = NVL ( RTRIM ( in_alias5desc ), in_alias5 );
		END IF;

		IF RTRIM ( in_alias5 ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitemalias
							(
							  custid, item, itemalias,
							  aliasdesc, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), UPPER ( RTRIM ( in_alias5 ) ),
						   NVL ( RTRIM ( in_alias5desc ), in_alias5 ), 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemalias
					SET    aliasdesc = NVL ( RTRIM ( in_alias5desc ), in_alias5 ), lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    itemalias = UPPER ( RTRIM ( in_alias5 ) );

					IF SQL%ROWCOUNT = 0 THEN
						out_errorno := 105;
						out_msg :=
							   'Alias5 value of '
							|| RTRIM ( in_alias5 )
							|| ' is already in use';
						log_msg ( 'E' );
						RETURN;
					END IF;
			END;
		END IF;

		IF RTRIM ( in_alias6 ) IS NOT NULL
		   AND RTRIM ( NVL ( in_alias6wipe, 'N' ) ) = 'Y' THEN
			DELETE FROM custitemalias
			WHERE  custid = UPPER ( RTRIM ( in_custid ) )
			AND    item = UPPER ( RTRIM ( in_item ) )
			AND    aliasdesc = NVL ( RTRIM ( in_alias6desc ), in_alias6 );
		END IF;

		IF RTRIM ( in_alias6 ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitemalias
							(
							  custid, item, itemalias,
							  aliasdesc, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), UPPER ( RTRIM ( in_alias6 ) ),
						   NVL ( RTRIM ( in_alias6desc ), in_alias6 ), 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemalias
					SET    aliasdesc = NVL ( RTRIM ( in_alias6desc ), in_alias6 ), lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    itemalias = UPPER ( RTRIM ( in_alias6 ) );

					IF SQL%ROWCOUNT = 0 THEN
						out_errorno := 105;
						out_msg :=
							   'Alias6 value of '
							|| RTRIM ( in_alias6 )
							|| ' is already in use';
						log_msg ( 'E' );
						RETURN;
					END IF;
			END;
		END IF;

		IF RTRIM ( in_alias7 ) IS NOT NULL
		   AND RTRIM ( NVL ( in_alias7wipe, 'N' ) ) = 'Y' THEN
			DELETE FROM custitemalias
			WHERE  custid = UPPER ( RTRIM ( in_custid ) )
			AND    item = UPPER ( RTRIM ( in_item ) )
			AND    aliasdesc = NVL ( RTRIM ( in_alias7desc ), in_alias7 );
		END IF;

		IF RTRIM ( in_alias7 ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitemalias
							(
							  custid, item, itemalias,
							  aliasdesc, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), UPPER ( RTRIM ( in_alias7 ) ),
						   NVL ( RTRIM ( in_alias7desc ), in_alias7 ), 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemalias
					SET    aliasdesc = NVL ( RTRIM ( in_alias7desc ), in_alias7 ), lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    itemalias = UPPER ( RTRIM ( in_alias7 ) );

					IF SQL%ROWCOUNT = 0 THEN
						out_errorno := 105;
						out_msg :=
							   'Alias7 value of '
							|| RTRIM ( in_alias7 )
							|| ' is already in use';
						log_msg ( 'E' );
						RETURN;
					END IF;
			END;
		END IF;

		IF RTRIM ( in_alias8 ) IS NOT NULL
		   AND RTRIM ( NVL ( in_alias8wipe, 'N' ) ) = 'Y' THEN
			DELETE FROM custitemalias
			WHERE  custid = UPPER ( RTRIM ( in_custid ) )
			AND    item = UPPER ( RTRIM ( in_item ) )
			AND    aliasdesc = NVL ( RTRIM ( in_alias8desc ), in_alias8 );
		END IF;

		IF RTRIM ( in_alias8 ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitemalias
							(
							  custid, item, itemalias,
							  aliasdesc, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), UPPER ( RTRIM ( in_alias8 ) ),
						   NVL ( RTRIM ( in_alias8desc ), in_alias8 ), 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemalias
					SET    aliasdesc = NVL ( RTRIM ( in_alias8desc ), in_alias8 ), lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    itemalias = UPPER ( RTRIM ( in_alias8 ) );

					IF SQL%ROWCOUNT = 0 THEN
						out_errorno := 105;
						out_msg :=
							   'Alias8 value of '
							|| RTRIM ( in_alias8 )
							|| ' is already in use';
						log_msg ( 'E' );
						RETURN;
					END IF;
			END;
		END IF;

		IF RTRIM ( in_alias9 ) IS NOT NULL
		   AND RTRIM ( NVL ( in_alias9wipe, 'N' ) ) = 'Y' THEN
			DELETE FROM custitemalias
			WHERE  custid = UPPER ( RTRIM ( in_custid ) )
			AND    item = UPPER ( RTRIM ( in_item ) )
			AND    aliasdesc = NVL ( RTRIM ( in_alias9desc ), in_alias9 );
		END IF;

		IF RTRIM ( in_alias9 ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitemalias
							(
							  custid, item, itemalias,
							  aliasdesc, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), UPPER ( RTRIM ( in_alias9 ) ),
						   NVL ( RTRIM ( in_alias9desc ), in_alias9 ), 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemalias
					SET    aliasdesc = NVL ( RTRIM ( in_alias9desc ), in_alias9 ), lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    itemalias = UPPER ( RTRIM ( in_alias9 ) );

					IF SQL%ROWCOUNT = 0 THEN
						out_errorno := 105;
						out_msg :=
							   'Alias9 value of '
							|| RTRIM ( in_alias9 )
							|| ' is already in use';
						log_msg ( 'E' );
						RETURN;
					END IF;
			END;
		END IF;

		IF RTRIM ( in_alias10 ) IS NOT NULL
		   AND RTRIM ( NVL ( in_alias10wipe, 'N' ) ) = 'Y' THEN
			DELETE FROM custitemalias
			WHERE  custid = UPPER ( RTRIM ( in_custid ) )
			AND    item = UPPER ( RTRIM ( in_item ) )
			AND    aliasdesc = NVL ( RTRIM ( in_alias10desc ), in_alias10 );
		END IF;

		IF RTRIM ( in_alias10 ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitemalias
							(
							  custid, item, itemalias,
							  aliasdesc, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), UPPER ( RTRIM ( in_alias10 ) ),
						   NVL ( RTRIM ( in_alias10desc ), in_alias10 ), 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemalias
					SET    aliasdesc = NVL ( RTRIM ( in_alias10desc ), in_alias10 ), lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    itemalias = UPPER ( RTRIM ( in_alias10 ) );

					IF SQL%ROWCOUNT = 0 THEN
						out_errorno := 105;
						out_msg :=
							   'Alias10 value of '
							|| RTRIM ( in_alias10 )
							|| ' is already in use';
						log_msg ( 'E' );
						RETURN;
					END IF;
			END;
		END IF;

		IF RTRIM ( in_alias11 ) IS NOT NULL
		   AND RTRIM ( NVL ( in_alias11wipe, 'N' ) ) = 'Y' THEN
			DELETE FROM custitemalias
			WHERE  custid = UPPER ( RTRIM ( in_custid ) )
			AND    item = UPPER ( RTRIM ( in_item ) )
			AND    aliasdesc = NVL ( RTRIM ( in_alias11desc ), in_alias11 );
		END IF;

		IF RTRIM ( in_alias11 ) IS NOT NULL THEN
			BEGIN
				INSERT INTO custitemalias
							(
							  custid, item, itemalias,
							  aliasdesc, lastuser, lastupdate
							)
				VALUES
					   (
						   UPPER ( RTRIM ( in_custid ) ), UPPER ( RTRIM ( in_item ) ), UPPER ( RTRIM ( in_alias11 ) ),
						   NVL ( RTRIM ( in_alias11desc ), in_alias11 ), 'WEBERIMP', SYSDATE
					   );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE custitemalias
					SET    aliasdesc = NVL ( RTRIM ( in_alias11desc ), in_alias11 ), lastuser = 'WEBERIMP', lastupdate = SYSDATE
					WHERE  custid = UPPER ( RTRIM ( in_custid ) )
					AND    item = UPPER ( RTRIM ( in_item ) )
					AND    itemalias = UPPER ( RTRIM ( in_alias11 ) );

					IF SQL%ROWCOUNT = 0 THEN
						out_errorno := 105;
						out_msg :=
							   'Alias11 value of '
							|| RTRIM ( in_alias11 )
							|| ' is already in use';
						log_msg ( 'E' );
						RETURN;
					END IF;
			END;
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			out_msg := 'zimi ' || SQLERRM;
			out_errorno := SQLCODE;
	END weber_import_item2;

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
)
is

cursor curCustomer is
  select name
    from customer
   where custid = upper(rtrim(in_custid));
cs curCustomer%rowtype;

cursor curCustItem is
  select ci.descr,ci.status,sum(NVL(cit.qty,0)) qty
    from custitem ci, custitemtot cit
   where ci.custid=cit.custid(+) and ci.item=cit.item(+) and cit.invstatus(+)='AV'
     and ci.custid = upper(rtrim(in_custid))
     and ci.item = upper(rtrim(in_item))
     group by ci.descr,ci.status,cit.invstatus;
ci curCustItem%rowtype;

uom_sequence custitemuom.sequence%type;
wrk custitem%rowtype;
uomqty custitemuom.qty%type;
uomqty2 custitemuom.qty%type;
str_subject varchar2(500);
real_cube number;
wrk_prodgroup varchar2(4);

procedure log_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := ' Item: ' || rtrim(in_item) || ': ' || out_msg;
  zms.log_msg('IMPEXP', null, rtrim(in_custid),
    out_msg, nvl(rtrim(in_msgtype),'E'), 'WEBERIMP', strMsg);
end;

procedure update_uom(in_seq number, in_qty number,
    in_from_uom varchar2, in_to_uom varchar2, 
    in_length number, in_width number, in_height number,
    in_weight number, in_cube number)
IS
begin
    begin

        insert into custitemuom
        (custid,item,
         sequence,qty,
         fromuom,
         touom,
         length,
         width,
         height,
         weight,
         cube,
         lastuser,lastupdate,
         velocity,picktotype,cartontype)
        values
        (upper(rtrim(in_custid)),upper(rtrim(in_item)),
        in_seq,in_qty,
        in_from_uom,
        in_to_uom,
        in_length,
        in_width,
        in_height,
        in_weight,
        in_cube,
        'WEBERIMP',sysdate,
        'C',NVL(in_uom_picktotype,'FULL'),NVL(in_uom_cartontype,'PLT'));

    exception when DUP_VAL_ON_INDEX then
    
        update custitemuom
           set fromuom = in_from_uom,
               touom = in_to_uom,
               qty = in_qty,        
               weight = in_weight,
               cube = in_cube,
               length = in_length,
               width = in_width,
               height = in_height
        where custid = upper(rtrim(in_custid))
          and item = upper(rtrim(in_item))
          and sequence = in_seq;
    end;

end;

begin

if rtrim(upper(in_func)) not in ('A','U','D') then
  out_errorno := 4;
  out_msg := 'Invalid function code: ' || in_func;
  log_msg('E');
  return;
end if;

if rtrim(in_custid) is null then
  out_errorno := 1;
  out_msg := 'Customer ID is required';
  log_msg('E');
  return;
end if;

cs := null;
open curCustomer;
fetch curCustomer into cs;
close curCustomer;
if cs.name is null then
  out_errorno := 2;
  out_msg := 'Invalid Customer ID: ' || in_custid;
  log_msg('E');
  return;
end if;

if rtrim(in_item) is null then
  out_errorno := 3;
  out_msg := 'Item ID is required';
  log_msg('E');
  return;
end if;

ci := null;
open curCustItem;
fetch curCustItem into ci;
close curCustItem;

if ci.descr is null then
  if upper(rtrim(in_func)) = 'D' then
    out_errorno := 5;
    out_msg := 'Item not found for deletion: ' || in_item;
    log_msg('E');
    return;
  end if;
  if upper(rtrim(in_func)) = 'U' then
    out_msg := 'Item not found for update (add performed): ' || in_item;
    log_msg('W');
    in_func := 'A';
  end if;
else
  if upper(rtrim(in_func)) = 'A' then
    out_msg := 'Item to be added already on file (update performed): ' || in_item;
    log_msg('W');
    in_func := 'U';
  end if;
end if;

if upper(rtrim(in_func)) = 'A' then
  wrk.status := in_add_status;
  wrk.needs_review_yn := in_add_review_yn;
elsif upper(rtrim(in_func)) = 'U' then
  wrk.status := ci.status;
  wrk.needs_review_yn := in_update_review_yn;
else
  wrk.status := in_delete_status;
  wrk.needs_review_yn := in_delete_review_yn;
end if;

if rtrim(in_abbrev) is null then
  in_abbrev := substr(in_descr,1,12);
end if;

if in_cube is null and in_length is not null and in_width is not null and in_height is not null then
  real_cube:=in_length*in_width*in_height;
else
  real_cube:=in_cube;
end if;

if in_custid = '11405' and in_productgroup = 'S' then
  wrk_prodgroup := null;
else
  wrk_prodgroup := in_productgroup;
end if;

-- if no item then just create it
if ci.status is null then
    out_msg := 'ci.status is null inserting custitem ' || in_item;
    log_msg('W');

  insert into custitem
  (custid,item,
   descr,abbrev,
   status,baseuom,
   stackheightuom,cube,
   weight,hazardous,
   shelflife,min_sale_life,
   lotrequired,serialrequired,
   user1required,user2required,user3required,
   mfgdaterequired,expdaterequired,countryrequired,
   allowsub,backorder,invstatusind,invclassind,
   qtytype,velocity,recvinvstatus,
   weightcheckrequired,ordercheckrequired,
   use_fifo,putawayconfirmation,
   nodamaged,iskit,subslprsnrequired,
   lotsumreceipt,lotsumrenewal,lotsumbol,lotsumaccess,
   lotfmtaction,serialfmtaction,
   user1fmtaction,user2fmtaction,user3fmtaction,
   maxqtyof1,rategroup,
   serialasncapture,user1asncapture,user2asncapture,user3asncapture,
   lastuser,lastupdate,needs_review_yn,countryof,
   length,width,height,tms_commodity_code, nmfc, nmfc_article,
   useramt1, useramt2,
  critlevel1,
  critlevel2,
  critlevel3,
  labeluom,
  productgroup,
  picktotype,
  cartontype,
    itmpassthrunum01,itmpassthrunum02,itmpassthrunum03,itmpassthrunum04,
    itmpassthruchar01,itmpassthruchar02,itmpassthruchar03,itmpassthruchar04)
  values
  (upper(rtrim(in_custid)),upper(rtrim(in_item)),
   rtrim(in_descr),rtrim(in_abbrev),
   wrk.status,nvl(upper(rtrim(in_baseuom)),'EA'),
   nvl(upper(rtrim(in_stackheightuom)),'PLT'),nvl(real_cube,0),
   nvl(in_weight,0),nvl(upper(rtrim(in_hazardous)),'N'),
   nvl(in_shelflife,0),nvl(in_shelflife,0),
   rtrim(nvl(in_lotrequired,'C')),rtrim(nvl(in_serialrequired,'C')),
   rtrim(nvl(in_user1required,'C')),rtrim(nvl(in_user2required,'C')),rtrim(nvl(in_user3required,'C')),
   rtrim(nvl(in_mfgdaterequired,'C')),rtrim(nvl(in_expdaterequired,'C')),rtrim(nvl(in_countryrequired,'C')),
   'C','C','C','C',
   'C','C','AV',
   'C','C',
   'N','C',
   'C','N','C',
   'N','N','N','N',
   'C','C',
   'C','C','C',
   'C',in_rategroup,
   'C','C','C','C',
   'WEBERIMP',sysdate,wrk.needs_review_yn,upper(rtrim(in_countryof)),
   in_length,in_width,in_height,in_tms_commodity_code, in_nmfc,
   in_nmfc_article, in_useramt1, in_useramt2,
  in_critlevel1,
  in_critlevel2,
  in_critlevel3,
  in_labeluom,
--  in_productgroup,
  wrk_prodgroup,
  in_picktotype,
  in_cartontype,
    in_passthrunum01,  in_passthrunum02,  in_passthrunum03,  in_passthrunum04,
    in_passthruchar01, in_passthruchar02, in_passthruchar03, in_passthruchar04);

  --create uom conversions
    out_msg := 'creating UOM conversions ' || in_item ||' in_length = '||in_length||'in_width = '||in_width||'in_height = '||in_height||'in_cube = '||in_cube||' real_cube = '||real_cube;
    log_msg('W');
    out_msg := 'creating UOM1 conversions ' || in_item ||' in_uom1_length = '||in_uom1_length||'in_uom1_width = '||in_uom1_width||'in_uom1_height = '||in_uom1_height||'in_uom1_cube = '||in_uom1_cube||' in_uom1_weight = '||in_uom1_weight;
    log_msg('W');
    out_msg := 'creating UOM2 conversions ' || in_item ||' in_uom2_length = '||in_uom2_length||'in_uom2_width = '||in_uom2_width||'in_uom2_height = '||in_uom2_height||'in_uom2_cube = '||in_uom2_cube||' in_uom2_weight = '||in_uom2_weight;
    log_msg('W');
    out_msg := 'creating UOM3 conversions ' || in_item ||' in_uom3_length = '||in_uom3_length||'in_uom3_width = '||in_uom3_width||'in_uom3_height = '||in_uom3_height||'in_uom3_cube = '||in_uom3_cube||' in_uom3_weight = '||in_uom3_weight;
    log_msg('W');
    out_msg := 'creating UOM4 conversions ' || in_item ||' in_uom4_length = '||in_uom4_length||'in_uom4_width = '||in_uom4_width||'in_uom4_height = '||in_uom4_height||'in_uom4_cube = '||in_uom4_cube||' in_uom4_weight = '||in_uom4_weight;
    log_msg('W');


  if (rtrim(in_to_uom1) is not null) and
     (nvl(in_to_uom1_qty,0) <> 0) then
    delete from custitemuom
       where custid = upper(rtrim(in_custid))
         and item = upper(rtrim(in_item));
    uom_sequence := 10;
    
   
    insert into custitemuom
    (custid,item,
     sequence,qty,
     fromuom,
     touom,
     length,
     width,
     height,
     weight,
     cube,
     lastuser,lastupdate,
     velocity,picktotype,cartontype)
    values
    (upper(rtrim(in_custid)),upper(rtrim(in_item)),
    uom_sequence,in_to_uom1_qty,
    nvl(upper(rtrim(in_baseuom)),'EA'),
    upper(rtrim(in_to_uom1)),
    in_uom1_length,
    in_uom1_width,
    in_uom1_height,
    in_uom1_weight,
    in_uom1_cube,
    'WEBERIMP',sysdate,
    'C',NVL(in_uom_picktotype,'FULL'),NVL(in_uom_cartontype,'PLT'));
    if (rtrim(in_to_uom2) is not null) and
       (nvl(in_to_uom2_qty,0) <> 0) then
      uom_sequence := uom_sequence + 10;
      
      insert into custitemuom
      (custid,item,
       sequence,qty,
       fromuom,
       touom,
       length,
       width,
       height,
       weight,
       cube,
       lastuser,lastupdate,
       velocity,picktotype,cartontype)
      values
      (upper(rtrim(in_custid)),upper(rtrim(in_item)),
      uom_sequence,in_to_uom2_qty,
      upper(rtrim(in_to_uom1)),
      upper(rtrim(in_to_uom2)),
      in_uom2_length,
      in_uom2_width,
      in_uom2_height,
      in_uom2_weight,
      in_uom2_cube,
      'WEBERIMP',sysdate,
      'C',NVL(in_uom_picktotype,'FULL'),NVL(in_uom_cartontype,'PLT'));
      if (rtrim(in_to_uom3) is not null) and
         (nvl(in_to_uom3_qty,0) <> 0) then
        uom_sequence := uom_sequence + 10;
        
        insert into custitemuom
        (custid,item,
         sequence,qty,
         fromuom,
         touom,
         length,
         width,
         height,
         weight,
         cube,
        lastuser,lastupdate,
        velocity,picktotype,cartontype)
        values
        (upper(rtrim(in_custid)),upper(rtrim(in_item)),
        uom_sequence,in_to_uom3_qty,
        upper(rtrim(in_to_uom2)),
        upper(rtrim(in_to_uom3)),
        in_uom3_length,
        in_uom3_width,
        in_uom3_height,
        in_uom3_weight,
        in_uom3_cube,
        'WEBERIMP',sysdate,
        'C',NVL(in_uom_picktotype,'FULL'),NVL(in_uom_cartontype,'PLT'));
        if (rtrim(in_to_uom4) is not null) and
           (nvl(in_to_uom4_qty,0) <> 0) then
          uom_sequence := uom_sequence + 10;
          
          insert into custitemuom
          (custid,item,
           sequence,qty,
           fromuom,
           touom,
           length,
           width,
           height,
           weight,
           cube,
          lastuser,lastupdate,
          velocity,picktotype,cartontype)
          values
          (upper(rtrim(in_custid)),upper(rtrim(in_item)),
          uom_sequence,in_to_uom4_qty,
          upper(rtrim(in_to_uom3)),
          upper(rtrim(in_to_uom4)),
          in_uom4_length,
          in_uom4_width,
          in_uom4_height,
          in_uom4_weight,
          in_uom4_cube,
          'WEBERIMP',sysdate,
          'C',NVL(in_uom_picktotype,'FULL'),NVL(in_uom_cartontype,'PLT'));
        end if;
      end if;
    end if;
  end if;


else

  if ci.status='ACTV' THEN
    --if active only update description, shelflife, nmfc, critlevel, all passthru fields, itemaliases
      update custitem
        set --descr = nvl(rtrim(in_descr),descr),
            abbrev = nvl(rtrim(in_abbrev),abbrev),
            status = wrk.status,
            --baseuom = nvl(upper(rtrim(in_baseuom)),baseuom),
            stackheightuom = nvl(upper(rtrim(in_stackheightuom)),'PLT'),
            --cube = nvl(real_cube,cube),
            --weight = nvl(in_weight,weight),
            hazardous = nvl(upper(rtrim(in_hazardous)),hazardous),
            shelflife = nvl(in_shelflife,shelflife),
            min_sale_life = nvl(in_shelflife,shelflife),
            lastuser = 'WEBERIMP',
            lastupdate = sysdate,
            needs_review_yn = wrk.needs_review_yn,
            --length = nvl(in_length,length),
            --width = nvl(in_width,width),
            --height = nvl(in_height,height),
            nmfc = in_nmfc,
            nmfc_article = in_nmfc_article,
            rategroup = in_rategroup,
            useramt1 = in_useramt1,
            useramt2 = in_useramt2,
          critlevel1 = in_critlevel1,
          critlevel2 = in_critlevel2,
          critlevel3 = in_critlevel3,
          --labeluom = in_labeluom,
--          productgroup = in_productgroup,
            productgroup = wrk_prodgroup,
          --picktotype = in_picktotype,
          --cartontype = in_cartontype,
                itmpassthrunum01=nvl(in_passthrunum01, itmpassthrunum01),
                itmpassthrunum02=nvl(in_passthrunum02, itmpassthrunum02),
                itmpassthrunum03=nvl(in_passthrunum03, itmpassthrunum03),
                itmpassthrunum04=nvl(in_passthrunum04, itmpassthrunum04),
                itmpassthruchar01=nvl(in_passthruchar01, itmpassthruchar01),
                itmpassthruchar02=nvl(in_passthruchar02, itmpassthruchar02),
                itmpassthruchar03=nvl(in_passthruchar03, itmpassthruchar03),
                itmpassthruchar04=nvl(in_passthruchar04, itmpassthruchar04)
      where custid = upper(rtrim(in_custid))
        and item = upper(rtrim(in_item));

      BEGIN
        SELECT qty
        into uomqty
        FROM custitemuom
        WHERE ROWNUM=1 and custid=RTrim(in_custid)
        AND item=upper(rtrim(in_item))
        AND sequence=10;
      exception when others then
        uomqty := 0;
      end;

      BEGIN
        SELECT qty
        into uomqty2
        FROM custitemuom
        WHERE ROWNUM=1 and custid=RTrim(in_custid)
        AND item=upper(rtrim(in_item))
        AND sequence=20;
      exception when others then
        uomqty2 := 0;
      end;


      --time to check for UOM Conversion and if different then we need to send an email
      --old statement which didn't care of the uom existed before checking to compare
      --IF NVL(uomqty,0)!=NVL(rtrim(in_useramt1),rtrim(in_abbrev)) or NVL(uomqty2,0)!=NVL(rtrim(in_useramt2),0) THEN
      IF NVL(uomqty,0)!=NVL(rtrim(in_useramt1),rtrim(in_abbrev)) or (NVL(uomqty2,0)!=NVL(rtrim(in_useramt2),0) and NVL(uomqty2,0)<>0 and NVL(rtrim(in_useramt2),0)<>0) THEN
          DECLARE
            conn utl_smtp.connection;
          BEGIN

          if NVL(uomqty2,0)!=NVL(rtrim(in_useramt2),0) then
            str_subject:='New UOM for CustID '|| in_custid || ' / Item '|| upper(rtrim(in_item)) || ' / QTY from ' || NVL(uomqty,0) || ' to ' || NVL(rtrim(in_useramt1),rtrim(in_abbrev)) || ' seq 10 / ' || uomqty2 || ' to ' || NVL(rtrim(in_useramt2),0) || ' seq 20';
          else
            str_subject:='New UOM for CustID '|| in_custid || ' / Item '|| upper(rtrim(in_item)) || ' / QTY from ' || NVL(uomqty,0) || ' to ' || NVL(rtrim(in_useramt1),rtrim(in_abbrev));
          end if;

            conn := weber_mail.begin_mail(
              sender     => 'New UOM <edi@weberlogistics.com>',
              recipients => in_custid || ' <' || in_custid || 'uom@weberlogistics.com>',
              subject    => str_subject,
              mime_type  => 'text/html');

            weber_mail.write_text(
              conn    => conn,
              message => '<HTML>'||
                          '<BODY leftmargin="0" rightmargin="0" topmargin="0" marginwidth="0" marginheight="0" bgcolor="#FFFFFF">'||
                          '<font face="Arial, Helvetica, sans-serif">'||
                          '<table width="100%" border="0" cellspacing="0" cellpadding="2">'||
                              '<tr>'||
                                  '<td bgcolor="#000000"><font size="2" face="Verdana, Arial, Helvetica, sans-serif" color="#FFFFFF"><b>Item Details</b></font></td>'||
                              '</tr>'||
                              '<tr align="center">'||
                              '<td bgcolor="#CCCCCC" colspan="2" valign="top">'||
                                      '<table width="100%" border="0" cellspacing="0" cellpadding="5" bgcolor="#FFFFFF">'||
                                          '<tr>'||
                                              '<td width=15% bgcolor="FFFFFF" colspan=10 nowrap><font face="Verdana, Arial, Helvetica, sans-serif" size="2" color="0000FF"><b>CustID ' || in_custid || '</b></font></td>'||
                                              '<td width=15% bgcolor="FFFFFF" colspan=10 nowrap><font face="Verdana, Arial, Helvetica, sans-serif" size="2" color="0000FF"><b>Item ' || upper(rtrim(in_item)) || '</b></font></td>'||
                                              '<td bgcolor="FFFFFF" colspan=10 nowrap><font face="Verdana, Arial, Helvetica, sans-serif" size="2" color="0000FF"><b>UOM from ' || NVL(uomqty,0) || ' to ' || NVL(rtrim(in_useramt1),rtrim(in_abbrev)) || ' seq 10</b></font></td>'||
                                              '<td bgcolor="FFFFFF" colspan=10 nowrap><font face="Verdana, Arial, Helvetica, sans-serif" size="2" color="0000FF"><b>UOM from ' || NVL(uomqty2,0) || ' to ' || NVL(rtrim(in_useramt2),0) || ' seq 20</b></font></td>'||
                                          '</tr>'||
                                      '</table>'||
                                  '</td>'||
                              '</tr>'||
                          '</table>'||
                          '</font>'||
                          '</body>'||
                        '</html>');

                weber_mail.end_mail( conn => conn );
              exception when others THEN
                zms.log_msg('WEBERIMP',null,in_custid,'MAIL DID NOT SEND, IS THE CUSTID EMAIL SETUP?','I','WEBERIMP',out_msg);
          END;
      END IF;




  else --this must be 'INAC'
    --if inactive we can update all fields

      update custitem
        set descr = nvl(rtrim(in_descr),descr),
            abbrev = nvl(rtrim(in_abbrev),abbrev),
            status = wrk.status,
            baseuom = nvl(upper(rtrim(in_baseuom)),baseuom),
            stackheightuom = nvl(upper(rtrim(in_stackheightuom)),'PLT'),
            cube = nvl(real_cube,cube),
            weight = nvl(in_weight,weight),
            hazardous = nvl(upper(rtrim(in_hazardous)),hazardous),
            lotrequired = rtrim(nvl(in_lotrequired,'C')),
            serialrequired = rtrim(nvl(in_serialrequired,'C')),
            user1required = rtrim(nvl(in_user1required,'C')),
            user2required = rtrim(nvl(in_user2required,'C')),
            user3required = rtrim(nvl(in_user3required,'C')),
            mfgdaterequired = rtrim(nvl(in_mfgdaterequired,'C')),
            expdaterequired = rtrim(nvl(in_expdaterequired,'C')),
            countryrequired = rtrim(nvl(in_countryrequired,'C')),
            shelflife = nvl(in_shelflife,shelflife),
            min_sale_life = nvl(in_shelflife,shelflife),
            lastuser = 'WEBERIMP',
            lastupdate = sysdate,
            needs_review_yn = wrk.needs_review_yn,
            length = nvl(in_length,length),
            width = nvl(in_width,width),
            height = nvl(in_height,height),
            nmfc = in_nmfc,
            nmfc_article = in_nmfc_article,
            rategroup = in_rategroup,
            useramt1 = in_useramt1,
            useramt2 = in_useramt2,
          critlevel1 = in_critlevel1,
          critlevel2 = in_critlevel2,
          critlevel3 = in_critlevel3,
          labeluom = in_labeluom,
--          productgroup = in_productgroup,
          productgroup = wrk_prodgroup,
          picktotype = in_picktotype,
          cartontype = in_cartontype,
                itmpassthrunum01=nvl(in_passthrunum01, itmpassthrunum01),
                itmpassthrunum02=nvl(in_passthrunum02, itmpassthrunum02),
                itmpassthrunum03=nvl(in_passthrunum03, itmpassthrunum03),
                itmpassthrunum04=nvl(in_passthrunum04, itmpassthrunum04),
                itmpassthruchar01=nvl(in_passthruchar01, itmpassthruchar01),
                itmpassthruchar02=nvl(in_passthruchar02, itmpassthruchar02),
                itmpassthruchar03=nvl(in_passthruchar03, itmpassthruchar03),
                itmpassthruchar04=nvl(in_passthruchar04, itmpassthruchar04)
      where custid = upper(rtrim(in_custid))
        and item = upper(rtrim(in_item));

      --not sure if we want to allow uom conversions from customers? I'll use this uomupdate flag to allow or disallow insert/update
      --copy and move this within the above if statementss if we want different rules for actv items vs inac items

      if nvl(in_uom_update,'N') = 'Y' then
          null;
        if (rtrim(in_to_uom1) is not null) and
          (nvl(in_to_uom1_qty,0) <> 0) then
          uom_sequence := 10;
          update_uom(uom_sequence, in_to_uom1_qty,
              nvl(upper(rtrim(in_baseuom)),'EA'),
              upper(rtrim(in_to_uom1)),
              in_uom1_length,
              in_uom1_width,
              in_uom1_height,
              in_uom1_weight,
              in_uom1_cube);

          if (rtrim(in_to_uom2) is not null) and
            (nvl(in_to_uom2_qty,0) <> 0) then
            uom_sequence := uom_sequence + 10;
            
            update_uom(uom_sequence, in_to_uom2_qty,
              upper(rtrim(in_to_uom1)),
              upper(rtrim(in_to_uom2)),
              in_uom2_length,
              in_uom2_width,
              in_uom2_height,
              in_uom2_weight,
              in_uom2_cube);

            if (rtrim(in_to_uom3) is not null) and
              (nvl(in_to_uom3_qty,0) <> 0) then
              uom_sequence := uom_sequence + 10;

            update_uom(uom_sequence, in_to_uom3_qty,
              upper(rtrim(in_to_uom2)),
              upper(rtrim(in_to_uom3)),
              in_uom3_length,
              in_uom3_width,
              in_uom3_height,
              in_uom3_weight,
              in_uom3_cube);

              if (rtrim(in_to_uom4) is not null) and
                (nvl(in_to_uom4_qty,0) <> 0) then
                uom_sequence := uom_sequence + 10;

                update_uom(uom_sequence, in_to_uom4_qty,
                  upper(rtrim(in_to_uom3)),
                  upper(rtrim(in_to_uom4)),
                  in_uom4_length,
                  in_uom4_width,
                  in_uom4_height,
                  in_uom4_weight,
                  in_uom4_cube);

              end if;
            end if;
          end if;
          delete from custitemuom
            where custid = upper(rtrim(in_custid))
              and item = upper(rtrim(in_item))
              and sequence > uom_sequence;
        end if;
      end if;
   end if;
end if;


--do we want customers to be able to update bol comments?
if rtrim(in_bolcomment) is not null then
  begin
    insert into custitembolcomments
     (custid,item,consignee,comment1,lastuser,lastupdate)
    values
     (upper(rtrim(in_custid)),upper(rtrim(in_item)),null,
      in_bolcomment,'WEBERIMP',sysdate);
  exception when dup_val_on_index then
    update custitembolcomments
       set comment1 = in_bolcomment,
           lastuser = 'WEBERIMP',
           lastupdate = sysdate
     where custid = upper(rtrim(in_custid))
       and item = upper(rtrim(in_item))
       and consignee is null;
  end;

end if;

--add or update UPC code
if rtrim(in_alias1) is not null and rtrim(NVL(in_alias1wipe,'N'))='Y' then
  delete from custitemalias
    where
      custid=upper(rtrim(in_custid)) and
      item=upper(rtrim(in_item)) and
      aliasdesc=nvl(rtrim(in_alias1desc),in_alias1);
end if;

if rtrim(in_alias1) is not null then
  begin
    insert into custitemalias
      (custid,item,itemalias,aliasdesc,lastuser,lastupdate)
    values
      (upper(rtrim(in_custid)),upper(rtrim(in_item)),upper(rtrim(in_alias1)),
       nvl(rtrim(in_alias1desc),in_alias1),'WEBERIMP',sysdate);
  exception when dup_val_on_index then
    update custitemalias
       set aliasdesc = nvl(rtrim(in_alias1desc),in_alias1),
           lastuser = 'WEBERIMP',
           lastupdate = sysdate
     where custid = upper(rtrim(in_custid))
       and item = upper(rtrim(in_item))
       and itemalias = upper(rtrim(in_alias1));
  end;
end if;

--add or update second alias, probably mainly GTIN
if rtrim(in_alias2) is not null and rtrim(NVL(in_alias2wipe,'N'))='Y' then
  delete from custitemalias
    where
      custid=upper(rtrim(in_custid)) and
      item=upper(rtrim(in_item)) and
      aliasdesc=nvl(rtrim(in_alias2desc),in_alias2);
end if;

if rtrim(in_alias2) is not null then
  begin
    insert into custitemalias
      (custid,item,itemalias,aliasdesc,lastuser,lastupdate)
    values
      (upper(rtrim(in_custid)),upper(rtrim(in_item)),upper(rtrim(in_alias2)),
       nvl(rtrim(in_alias2desc),in_alias2),'WEBERIMP',sysdate);
  exception when dup_val_on_index then
    update custitemalias
       set aliasdesc = nvl(rtrim(in_alias2desc),in_alias2),
           lastuser = 'WEBERIMP',
           lastupdate = sysdate
     where custid = upper(rtrim(in_custid))
       and item = upper(rtrim(in_item))
       and itemalias = upper(rtrim(in_alias2));
    if sql%rowcount = 0 then
      out_errorno := 105;
      out_msg := 'Alias2 value of ' || rtrim(in_alias2) || ' is already in use';
      log_msg('E');
      return;
    end if;
  end;
end if;

--add or update third alias, just in case
if rtrim(in_alias3) is not null and rtrim(NVL(in_alias3wipe,'N'))='Y' then
  delete from custitemalias
    where
      custid=upper(rtrim(in_custid)) and
      item=upper(rtrim(in_item)) and
      aliasdesc=nvl(rtrim(in_alias3desc),in_alias3);
end if;

if rtrim(in_alias3) is not null then
  begin
    insert into custitemalias
      (custid,item,itemalias,aliasdesc,lastuser,lastupdate)
    values
      (upper(rtrim(in_custid)),upper(rtrim(in_item)),upper(rtrim(in_alias3)),
       nvl(rtrim(in_alias3desc),in_alias3),'WEBERIMP',sysdate);
  exception when dup_val_on_index then
    update custitemalias
       set aliasdesc = nvl(rtrim(in_alias3desc),in_alias3),
           lastuser = 'WEBERIMP',
           lastupdate = sysdate
     where custid = upper(rtrim(in_custid))
       and item = upper(rtrim(in_item))
       and itemalias = upper(rtrim(in_alias3));
    if sql%rowcount = 0 then
      out_errorno := 105;
      out_msg := 'Alias3 value of ' || rtrim(in_alias3) || ' is already in use';
      log_msg('E');
      return;
    end if;
  end;
end if;

if rtrim(in_alias4) is not null and rtrim(NVL(in_alias4wipe,'N'))='Y' then
  delete from custitemalias
    where
      custid=upper(rtrim(in_custid)) and
      item=upper(rtrim(in_item)) and
      aliasdesc=nvl(rtrim(in_alias4desc),in_alias4);
end if;

if rtrim(in_alias4) is not null then
  begin
    insert into custitemalias
      (custid,item,itemalias,aliasdesc,lastuser,lastupdate)
    values
      (upper(rtrim(in_custid)),upper(rtrim(in_item)),upper(rtrim(in_alias4)),
       nvl(rtrim(in_alias4desc),in_alias4),'WEBERIMP',sysdate);
  exception when dup_val_on_index then
    update custitemalias
       set aliasdesc = nvl(rtrim(in_alias4desc),in_alias4),
           lastuser = 'WEBERIMP',
           lastupdate = sysdate
     where custid = upper(rtrim(in_custid))
       and item = upper(rtrim(in_item))
       and itemalias = upper(rtrim(in_alias4));
    if sql%rowcount = 0 then
      out_errorno := 105;
      out_msg := 'Alias4 value of ' || rtrim(in_alias4) || ' is already in use';
      log_msg('E');
      return;
    end if;
  end;
end if;

if rtrim(in_alias5) is not null and rtrim(NVL(in_alias5wipe,'N'))='Y' then
  delete from custitemalias
    where
      custid=upper(rtrim(in_custid)) and
      item=upper(rtrim(in_item)) and
      aliasdesc=nvl(rtrim(in_alias5desc),in_alias5);
end if;

if rtrim(in_alias5) is not null then
  begin
    insert into custitemalias
      (custid,item,itemalias,aliasdesc,lastuser,lastupdate)
    values
      (upper(rtrim(in_custid)),upper(rtrim(in_item)),upper(rtrim(in_alias5)),
       nvl(rtrim(in_alias5desc),in_alias5),'WEBERIMP',sysdate);
  exception when dup_val_on_index then
    update custitemalias
       set aliasdesc = nvl(rtrim(in_alias5desc),in_alias5),
           lastuser = 'WEBERIMP',
           lastupdate = sysdate
     where custid = upper(rtrim(in_custid))
       and item = upper(rtrim(in_item))
       and itemalias = upper(rtrim(in_alias5));
    if sql%rowcount = 0 then
      out_errorno := 105;
      out_msg := 'Alias5 value of ' || rtrim(in_alias5) || ' is already in use';
      log_msg('E');
      return;
    end if;
  end;
end if;

if rtrim(in_alias6) is not null and rtrim(NVL(in_alias6wipe,'N'))='Y' then
  delete from custitemalias
    where
      custid=upper(rtrim(in_custid)) and
      item=upper(rtrim(in_item)) and
      aliasdesc=nvl(rtrim(in_alias6desc),in_alias6);
end if;

if rtrim(in_alias6) is not null then
  begin
    insert into custitemalias
      (custid,item,itemalias,aliasdesc,lastuser,lastupdate)
    values
      (upper(rtrim(in_custid)),upper(rtrim(in_item)),upper(rtrim(in_alias6)),
       nvl(rtrim(in_alias6desc),in_alias6),'WEBERIMP',sysdate);
  exception when dup_val_on_index then
    update custitemalias
       set aliasdesc = nvl(rtrim(in_alias6desc),in_alias6),
           lastuser = 'WEBERIMP',
           lastupdate = sysdate
     where custid = upper(rtrim(in_custid))
       and item = upper(rtrim(in_item))
       and itemalias = upper(rtrim(in_alias6));
    if sql%rowcount = 0 then
      out_errorno := 105;
      out_msg := 'Alias6 value of ' || rtrim(in_alias6) || ' is already in use';
      log_msg('E');
      return;
    end if;
  end;
end if;

if rtrim(in_alias7) is not null and rtrim(NVL(in_alias7wipe,'N'))='Y' then
  delete from custitemalias
    where
      custid=upper(rtrim(in_custid)) and
      item=upper(rtrim(in_item)) and
      aliasdesc=nvl(rtrim(in_alias7desc),in_alias7);
end if;

if rtrim(in_alias7) is not null then
  begin
    insert into custitemalias
      (custid,item,itemalias,aliasdesc,lastuser,lastupdate)
    values
      (upper(rtrim(in_custid)),upper(rtrim(in_item)),upper(rtrim(in_alias7)),
       nvl(rtrim(in_alias7desc),in_alias7),'WEBERIMP',sysdate);
  exception when dup_val_on_index then
    update custitemalias
       set aliasdesc = nvl(rtrim(in_alias7desc),in_alias7),
           lastuser = 'WEBERIMP',
           lastupdate = sysdate
     where custid = upper(rtrim(in_custid))
       and item = upper(rtrim(in_item))
       and itemalias = upper(rtrim(in_alias7));
    if sql%rowcount = 0 then
      out_errorno := 105;
      out_msg := 'Alias7 value of ' || rtrim(in_alias7) || ' is already in use';
      log_msg('E');
      return;
    end if;
  end;
end if;

if rtrim(in_alias8) is not null and rtrim(NVL(in_alias8wipe,'N'))='Y' then
  delete from custitemalias
    where
      custid=upper(rtrim(in_custid)) and
      item=upper(rtrim(in_item)) and
      aliasdesc=nvl(rtrim(in_alias8desc),in_alias8);
end if;

if rtrim(in_alias8) is not null then
  begin
    insert into custitemalias
      (custid,item,itemalias,aliasdesc,lastuser,lastupdate)
    values
      (upper(rtrim(in_custid)),upper(rtrim(in_item)),upper(rtrim(in_alias8)),
       nvl(rtrim(in_alias8desc),in_alias8),'WEBERIMP',sysdate);
  exception when dup_val_on_index then
    update custitemalias
       set aliasdesc = nvl(rtrim(in_alias8desc),in_alias8),
           lastuser = 'WEBERIMP',
           lastupdate = sysdate
     where custid = upper(rtrim(in_custid))
       and item = upper(rtrim(in_item))
       and itemalias = upper(rtrim(in_alias8));
    if sql%rowcount = 0 then
      out_errorno := 105;
      out_msg := 'Alias8 value of ' || rtrim(in_alias8) || ' is already in use';
      log_msg('E');
      return;
    end if;
  end;
end if;

if rtrim(in_alias9) is not null and rtrim(NVL(in_alias9wipe,'N'))='Y' then
  delete from custitemalias
    where
      custid=upper(rtrim(in_custid)) and
      item=upper(rtrim(in_item)) and
      aliasdesc=nvl(rtrim(in_alias9desc),in_alias9);
end if;

if rtrim(in_alias9) is not null then
  begin
    insert into custitemalias
      (custid,item,itemalias,aliasdesc,lastuser,lastupdate)
    values
      (upper(rtrim(in_custid)),upper(rtrim(in_item)),upper(rtrim(in_alias9)),
       nvl(rtrim(in_alias9desc),in_alias9),'WEBERIMP',sysdate);
  exception when dup_val_on_index then
    update custitemalias
       set aliasdesc = nvl(rtrim(in_alias9desc),in_alias9),
           lastuser = 'WEBERIMP',
           lastupdate = sysdate
     where custid = upper(rtrim(in_custid))
       and item = upper(rtrim(in_item))
       and itemalias = upper(rtrim(in_alias9));
    if sql%rowcount = 0 then
      out_errorno := 105;
      out_msg := 'Alias9 value of ' || rtrim(in_alias9) || ' is already in use';
      log_msg('E');
      return;
    end if;
  end;
end if;

if rtrim(in_alias10) is not null and rtrim(NVL(in_alias10wipe,'N'))='Y' then
  delete from custitemalias
    where
      custid=upper(rtrim(in_custid)) and
      item=upper(rtrim(in_item)) and
      aliasdesc=nvl(rtrim(in_alias10desc),in_alias10);
end if;

if rtrim(in_alias10) is not null then
  begin
    insert into custitemalias
      (custid,item,itemalias,aliasdesc,lastuser,lastupdate)
    values
      (upper(rtrim(in_custid)),upper(rtrim(in_item)),upper(rtrim(in_alias10)),
       nvl(rtrim(in_alias10desc),in_alias10),'WEBERIMP',sysdate);
  exception when dup_val_on_index then
    update custitemalias
       set aliasdesc = nvl(rtrim(in_alias10desc),in_alias10),
           lastuser = 'WEBERIMP',
           lastupdate = sysdate
     where custid = upper(rtrim(in_custid))
       and item = upper(rtrim(in_item))
       and itemalias = upper(rtrim(in_alias10));
    if sql%rowcount = 0 then
      out_errorno := 105;
      out_msg := 'Alias10 value of ' || rtrim(in_alias10) || ' is already in use';
      log_msg('E');
      return;
    end if;
  end;
end if;

if rtrim(in_alias11) is not null and rtrim(NVL(in_alias11wipe,'N'))='Y' then
  delete from custitemalias
    where
      custid=upper(rtrim(in_custid)) and
      item=upper(rtrim(in_item)) and
      aliasdesc=nvl(rtrim(in_alias11desc),in_alias11);
end if;

if rtrim(in_alias11) is not null then
  begin
    insert into custitemalias
      (custid,item,itemalias,aliasdesc,lastuser,lastupdate)
    values
      (upper(rtrim(in_custid)),upper(rtrim(in_item)),upper(rtrim(in_alias11)),
       nvl(rtrim(in_alias11desc),in_alias11),'WEBERIMP',sysdate);
  exception when dup_val_on_index then
    update custitemalias
       set aliasdesc = nvl(rtrim(in_alias11desc),in_alias11),
           lastuser = 'WEBERIMP',
           lastupdate = sysdate
     where custid = upper(rtrim(in_custid))
       and item = upper(rtrim(in_item))
       and itemalias = upper(rtrim(in_alias11));
    if sql%rowcount = 0 then
      out_errorno := 105;
      out_msg := 'Alias11 value of ' || rtrim(in_alias11) || ' is already in use';
      log_msg('E');
      return;
    end if;
  end;
end if;

exception when others then
  out_msg := 'zimi ' || sqlerrm;
  out_errorno := sqlcode;
end weber_import_item2A;



	FUNCTION order_count_on_load ( in_loadno IN NUMBER )
		RETURN NUMBER IS
		out_count INTEGER;
	BEGIN
		out_count := 0;

		SELECT COUNT ( 1 )
		INTO   out_count
		FROM   orderhdr
		WHERE  loadno = in_loadno
		AND    orderstatus != 'X';

		RETURN out_count;
	EXCEPTION
		WHEN OTHERS THEN
			RETURN 0;
	END order_count_on_load;

	FUNCTION order_seq_on_load
	(
		in_loadno IN NUMBER, in_orderid IN NUMBER, in_shipid IN NUMBER
	)
		RETURN NUMBER IS
		CURSOR curOrders IS
			SELECT orderid, shipid
			FROM   orderhdr
			WHERE  loadno = in_loadno
			AND    orderstatus != 'X'
			ORDER BY orderid, shipid;

		out_seq INTEGER;
		orderfound BOOLEAN;
	BEGIN
		out_seq := 0;
		orderfound := FALSE;

		FOR oh IN curOrders LOOP
			out_seq := out_seq + 1;

			IF oh.orderid = in_orderid
			   AND oh.shipid = in_shipid THEN
				orderfound := TRUE;
				EXIT;
			END IF;
		END LOOP;

		IF orderfound = FALSE THEN
			out_seq := 0;
		END IF;

		RETURN out_seq;
	EXCEPTION
		WHEN OTHERS THEN
			RETURN 0;
	END order_seq_on_load;
END ZIMPORTPROCWEBERITEM;