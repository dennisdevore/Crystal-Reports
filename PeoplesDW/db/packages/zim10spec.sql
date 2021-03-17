--
-- $Id$
--
create or replace PACKAGE alps.zimportproc10

Is

procedure import_postalcodes
(in_code IN varchar2
,in_descr IN varchar2
,in_abbrev IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_nmfc
(in_nmfc IN varchar2
,in_descr IN varchar2
,in_abbrev IN varchar2
,in_class IN NUMBER
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_custconsignee
(in_custid IN varchar2
,in_consignee IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_consignee
(in_custid IN varchar2
,in_func IN OUT varchar2
,in_consignee IN varchar2
,in_name IN varchar2
,in_contact IN varchar2
,in_addr1 IN varchar2
,in_addr2 IN varchar2
,in_city IN varchar2
,in_state IN varchar2
,in_postalcode in varchar2
,in_countrycode in varchar2
,in_phone in varchar2
,in_fax in varchar2
,in_email in varchar2
,in_consigneestatus in varchar2
,in_ltlcarrier in varchar2
,in_tlcarrier in varchar2
,in_spscarrier in varchar2
,in_billto in varchar2
,in_shipto in varchar2
,in_railcarrier in varchar2
,in_billtoconsignee in varchar2
,in_shiptype in varchar2
,in_shipterms in varchar2
,in_apptrequired in varchar2
,in_billforpallets in varchar2
,in_masteraccount in varchar2
,in_bolemail in varchar2
,in_importfileid in varchar2
,in_transaction in varchar2
,in_edi_logging_yn in varchar2
,in_facilitycode in varchar2
,in_shiplabelcode in varchar2
,in_retailabelcode in varchar2
,in_packslipcode in varchar2
,in_tpacct in varchar2
,in_storenumber in varchar2
,in_distctrnumber in varchar2
,in_conspassthruchar01 in varchar2
,in_conspassthruchar02 in varchar2
,in_conspassthruchar03 in varchar2
,in_conspassthruchar04 in varchar2
,in_conspassthruchar05 in varchar2
,in_conspassthruchar06 in varchar2
,in_conspassthruchar07 in varchar2
,in_conspassthruchar08 in varchar2
,in_consorderupdate in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2);

procedure import_countrycodes
(in_code in varchar2
,in_descr in varchar2
,in_abbrev in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_custitembolcomments
(in_custid in varchar2
,in_item in varchar2
,in_consignee in varchar2
,in_comment1 in LONG
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_label_profile
(
in_profid IN varchar2
,in_descr IN varchar2
,in_abbrev IN varchar2
,in_businessevent IN varchar2
,in_uom IN varchar2
,in_seq IN number
,in_printerstock IN varchar2
,in_copies IN number
,in_print IN varchar2
,in_apply IN varchar2
,in_rfline1 IN varchar2
,in_rfline2 IN varchar2
,in_rfline3 IN varchar2
,in_rfline4 IN varchar2
,in_postprintproc IN varchar2
,in_viewname IN varchar2
,in_viewkeycol IN varchar2
,in_viewkeyorigin IN varchar2
,in_lpspath IN varchar2
,in_passthrufield IN varchar2
,in_passthruvalue IN varchar2
,in_nicewatchport IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

end zimportproc10;
/
show error package zimportproc10;
exit;
