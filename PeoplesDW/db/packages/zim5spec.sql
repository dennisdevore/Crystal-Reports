--
-- $Id$
--
create or replace PACKAGE alps.zimportproc5

is

procedure damaged_on_arrival
(in_DmgInStr IN varchar2
,in_fromlpid IN varchar2
,out_doa_yn OUT varchar2
);

procedure begin_I9_rcpt_note
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_I9_rcpt_note
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_I44_ship_note
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_include_cancelled_orders_yn IN varchar2
,in_count_lots_yn IN varchar2
,in_edi_orders_only_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_I44_ship_note
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_I44_rcpt_note
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_I44_rcpt_note
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_I9_ship_note
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_I9_ship_note
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

FUNCTION max_rmatrackingno
(in_orderid IN number
,in_shipid  IN number
) return varchar2;

FUNCTION shipplate_rmatrackingno
(in_lpid IN varchar2
) return varchar2;

procedure begin_855_confirm
(in_custid IN varchar2
,in_importfileid IN varchar2
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_855_confirm
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

PRAGMA RESTRICT_REFERENCES (max_rmatrackingno, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (shipplate_rmatrackingno, WNDS, WNPS, RNPS);

end zimportproc5;
/
show error package zimportproc5;
--exit;
