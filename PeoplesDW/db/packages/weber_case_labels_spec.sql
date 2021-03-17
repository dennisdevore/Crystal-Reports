--
-- $Id$
--
create or replace package weber_caslbls as


procedure ord_lbl
	(in_lpid   in varchar2,
	 in_func   in varchar2,			-- Q - query, X - execute
    in_action in varchar2,			-- A - all, P - print only, N = new, C = change
	 out_stmt  out varchar2);

procedure lod_lbl
	(in_lpid   in varchar2,
	 in_func   in varchar2,			-- Q - query, X - execute
    in_action in varchar2,			-- A - all, P - print only, N = new, C = change
	 out_stmt  out varchar2);

procedure wav_lbl
	(in_lpid   in varchar2,
	 in_func   in varchar2,			-- Q - query, X - execute
    in_action in varchar2,			-- A - all, P - print only, N = new, C = change
	 out_stmt  out varchar2);

procedure lpid_lbl
	(in_lpid   in varchar2,
	 in_func   in varchar2,			-- Q - query, X - execute
    in_action in varchar2,			-- A - all, P - print only
    in_termid in varchar2,          -- Terminal ID
	 out_stmt  out varchar2);

function part_of_carton
   (in_type   in varchar2,
    in_parent in varchar2)
return varchar2;
pragma restrict_references (part_of_carton, wnds, wnps, rnps);


end weber_caslbls;
/

show error package weber_caslbls;
exit;
