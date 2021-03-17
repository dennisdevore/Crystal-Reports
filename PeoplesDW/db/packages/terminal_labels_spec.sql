--
-- $Id$
--
create or replace package terminal_lbls as


procedure addrlabel
	(in_lpid    in varchar2,
	 in_func    in varchar2,			-- Q - query, X - execute
    in_action  in varchar2,			-- A - all, P - print only
    in_auxdata in varchar2,
	 out_stmt   out varchar2);

procedure conssku
	(in_lpid    in varchar2,
	 in_func    in varchar2,			-- Q - query, X - execute
    in_action  in varchar2,			-- A - all, P - print only
    in_auxdata in varchar2,
	 out_stmt   out varchar2);

end terminal_lbls;
/

show error package terminal_lbls;
exit;
