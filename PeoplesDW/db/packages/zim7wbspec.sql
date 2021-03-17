--
-- $Id$
--
create or replace PACKAGE alps.zimportproc7weber

Is


procedure begin_shipnote945weber
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_summarize_lots_yn IN varchar2
,in_include_zero_qty_lines_yn IN varchar2
,in_include_cancelled_orders_yn IN varchar2
,in_include_fromlpid_yn IN varchar2
,in_ltl_freight_passthru IN varchar2
,in_bol_tracking_yn IN varchar2
,in_round_freight_weight_up_yn IN varchar2
,in_invclass_yn IN varchar2
,in_carton_uom  IN varchar2
,in_contents_by_po  IN  varchar2
,in_outlot IN varchar2
,in_cnt_detail_yn IN varchar2
,in_cnt_detail_ignore_ui3_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_shipnote945weber
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);


FUNCTION find_po
(in_lpid IN varchar2
) return varchar2;


FUNCTION VICSChkDigit
      (in_Data in varchar2
) return varchar2;

function pallet_count
(in_loadno IN number
,in_custid IN varchar2
,in_facility IN varchar2
,in_orderid IN number
,in_shipid IN number
) return integer;
PRAGMA RESTRICT_REFERENCES (find_po, WNDS, WNPS, RNPS);



end zimportproc7weber;
/
show error package zimportproc7weber;
exit;


