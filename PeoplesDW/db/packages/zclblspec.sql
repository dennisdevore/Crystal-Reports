--
-- $Id: zuccspec.sql 753 2007-03-22 21:32:29Z ed $
--
create or replace package zclabels as



procedure pallet_order
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    out_stmt  out varchar2);

procedure pallet_load
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    out_stmt  out varchar2);

procedure pallet_cons
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2);


end zclabels;
/

show error package zclabels;
exit;
