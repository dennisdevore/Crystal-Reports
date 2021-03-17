--
-- $Id: zim860spec.sql 864 2006-05-16 20:40:15Z mikeh $
--
create or replace PACKAGE alps.zimportproc860

Is

procedure import_860_dillards
(in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_action IN varchar2
,in_shiptoname IN varchar2
,in_shiptoaddr1 IN varchar2
,in_shiptoaddr2 IN varchar2
,in_shiptocity IN varchar2
,in_shiptostate IN varchar2
,in_shiptozip IN varchar2
,in_consignee IN varchar2
,in_datecode37 IN varchar2
,in_date37 IN varchar2
,in_datecode38 IN varchar2
,in_date38 IN varchar2
,in_change_code IN varchar2
,in_orig_qty IN number
,in_qty_change IN number
,in_uom IN varchar2
,in_orig_price IN number
,in_item IN varchar2
,in_adduom IN varchar2
,in_new_price IN number
,in_new_qty IN number
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
,in_weight_entered_lbs number
,in_weight_entered_kgs number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
end zimportproc860;
/
show error package zimportproc860;
exit;
