--
-- $Id$
--
create or replace package weber_labels as


procedure eso_order_label
	(in_lpid   in varchar2,
	 in_func   in varchar2,			-- Q - query, X - execute
    in_action in varchar2,			-- A - all, P - print only, N = new
	 out_stmt  out varchar2);

procedure eso_load_label
	(in_lpid   in varchar2,
	 in_func   in varchar2,			-- Q - query, X - execute
    in_action in varchar2,			-- A - all, P - print only, N = new
	 out_stmt  out varchar2);

procedure eso_wave_label
	(in_lpid   in varchar2,
	 in_func   in varchar2,			-- Q - query, X - execute
    in_action in varchar2,			-- A - all, P - print only, N = new
	 out_stmt  out varchar2);

end weber_labels;
/

show error package weber_labels;
exit;
