--
-- $Id$
--
create or replace PACKAGE alps.zimportproc6

is

procedure check_for_adj_interface
(in_adjrowid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure begin_I9_inv_adj
(in_custid IN varchar2
,in_rowid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_include_nsd_yn IN varchar2
,in_invstatus_offset IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_I9_inv_adj
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_matissue_lpid
(in_custid in varchar2
,in_rowid in varchar2
,out_errorno in out number
,out_msg in out varchar2);

procedure end_matissue_lpid
(in_custid in varchar2
,in_viewsuffix in varchar2
,out_errorno in out number
,out_msg in out varchar2
);

procedure begin_staged_shippingplate
(in_custid IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_staged_shippingplate
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

function lip_creationdate
(in_lpid varchar2
) return date;

end zimportproc6;
/
show error package zimportproc6;
exit;

