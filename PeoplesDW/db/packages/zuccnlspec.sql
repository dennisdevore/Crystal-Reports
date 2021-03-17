--
-- $Id$
--
create or replace package zuccnicelabels as

function item_in_uom_to_innerpack
   (in_custid in varchar2,
    in_item   in varchar2)
   return integer;

procedure hptc01notnull
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure bbbhug001
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure targetcase
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure targetcomcase
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);
procedure targetpallet
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure uccblu002
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure ltpallet
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure trucase
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);
procedure trupallet
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);
end zuccnicelabels;
/

show error package zuccnicelabels;
exit;
