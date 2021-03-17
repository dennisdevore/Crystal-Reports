--
-- $Id: zenith_case_labels_spec.sql 2408 2007-11-05 21:47:25Z bobw $
--
create or replace package zenith_caslbls as


procedure ord_lbl
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, N = new
    out_stmt  out varchar2);

procedure ord_lbl_e13
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, N = new
    out_stmt  out varchar2);

procedure ord_lbl_e13_reprint
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, N = new
    out_stmt  out varchar2);

procedure ord_lbl_lot
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, N = new
    out_stmt  out varchar2);

procedure lod_lbl
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, N = new
    out_stmt  out varchar2);

procedure wav_lbl
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, N = new
    out_stmt  out varchar2);

procedure ord_lbl_all
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, N = new
    out_stmt  out varchar2);

procedure ord_lbl_all_e13
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, N = new
    out_stmt  out varchar2);


end zenith_caslbls;
/

show error package zenith_caslbls;
exit;
