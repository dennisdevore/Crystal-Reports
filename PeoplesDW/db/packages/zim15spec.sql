create or replace PACKAGE alps.zimportproc15

Is

procedure begin_great_plains_hdr
(in_custid in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_great_plains_dtl
(in_custid in varchar2
,in_account_facility_yn varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_greatplains
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_quickbooks
(in_custid in varchar2
,in_heading in number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_quickbooks
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_order_acknowledgment
(in_custid in varchar2
,in_importfileid in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_order_acknowledgment
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_sage
(in_custid in varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_combine_iditem_yn in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_sage
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_sage_sp1
(in_custid in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_sage_sp1
(in_custid in varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_peachtree
(in_custid in varchar2
,in_facility_gl_yn in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_peachtree
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_lawson_dtl_dbaraid
(in_custid IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_lawson_dtl_dbaraid
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_lawson_hdr_dbarait
(in_custid IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);
end zimportproc15;

/
show error package zimportproc15;
exit;
