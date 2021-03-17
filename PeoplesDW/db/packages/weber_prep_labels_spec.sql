--
-- $Id$
--
create or replace package weber_prplbls as


function lbl_remainder_qty
   (in_custid in varchar2,
    in_item   in varchar2,
    in_uom    in varchar2,
    in_qty    in number)
return number;
pragma restrict_references (lbl_remainder_qty, wnds);

procedure lbluom_qtys
   (in_custid     in varchar2,
    in_item       in varchar2,
    in_uom        in varchar2,
    in_qty        in number,
    out_lbluomqty out number,
    out_remqty    out number);

procedure lbl_ord_itm
	(in_lpid    in varchar2,
	 in_func    in varchar2,			-- Q - query, X - execute
    in_action  in varchar2,			-- A - all, P - print only, N = new, C = changes
    in_auxdata in varchar2,
	 out_stmt   out varchar2);

procedure lbl_itm_ord
	(in_lpid    in varchar2,
	 in_func    in varchar2,			-- Q - query, X - execute
    in_action  in varchar2,			-- A - all, P - print only, N = new, C = changes
    in_auxdata in varchar2,
	 out_stmt   out varchar2);

procedure lbl_loc
	(in_lpid    in varchar2,
	 in_func    in varchar2,			-- Q - query, X - execute
    in_action  in varchar2,			-- A - all, P - print only, N = new, C = changes
    in_auxdata in varchar2,
	 out_stmt   out varchar2);

end weber_prplbls;
/

show error package weber_prplbls;
exit;
