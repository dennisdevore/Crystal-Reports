--
-- $Id$
--
CReate or replace PACKAGE alps.zimportproc7pd

Is

procedure begin_diageo947
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_diageo947
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_pacam210
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_codelist IN varchar2
,in_custlist IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_pacam210
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_pd_shipnote945
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
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure end_pd_shipnote945
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
procedure begin_pacam856
(in_custid IN varchar2
,in_loadno IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_pacam856
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

end zimportproc7pd;
/
show error package zimportproc7pd;
exit;
