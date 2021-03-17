--
-- $Id$
--
create or replace PACKAGE alps.zimportprocfreight

is

function case_count
(in_loadno IN number
,in_hdrpassthruchar02 IN varchar2
) return number;

function carton_count
(in_loadno IN number
,in_hdrpassthruchar02 IN varchar2
) return number;

procedure begin_freight_aims_format
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_consolidate_field IN varchar2
,in_detail_extract IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_freight_aims_format
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

PROCEDURE get_aimsfileseq
(in_custid IN varchar2
,in_loop_count IN number
,in_viewsuffix IN varchar2
,out_aimsfileseq OUT varchar2
);

PRAGMA RESTRICT_REFERENCES (case_count, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (carton_count, WNDS, WNPS, RNPS);

end zimportprocfreight;
/
show error package zimportprocfreight;
exit;
