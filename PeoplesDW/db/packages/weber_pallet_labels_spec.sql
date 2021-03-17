--
-- $Id$
--
create or replace package weber_pltlbls as


procedure ord_lbl
	(in_lpid   in varchar2,
	 in_func   in varchar2,			-- Q - query, X - execute
    in_action in varchar2,			-- A - all, P - print only, N = new
	 out_stmt  out varchar2);

procedure lod_lbl
	(in_lpid   in varchar2,
	 in_func   in varchar2,			-- Q - query, X - execute
    in_action in varchar2,			-- A - all, P - print only, N = new
	 out_stmt  out varchar2);

procedure wav_lbl
	(in_lpid   in varchar2,
	 in_func   in varchar2,			-- Q - query, X - execute
    in_action in varchar2,			-- A - all, P - print only, N = new
	 out_stmt  out varchar2);

procedure lpid_lbl
	(in_lpid   in varchar2,
	 in_func   in varchar2,			-- Q - query, X - execute
    in_action in varchar2,			-- A - all, P - print only
    in_termid in varchar2,          -- Terminal ID
	 out_stmt  out varchar2);


end weber_pltlbls;
/

show error package weber_pltlbls;
exit;
