--
-- $Id: zaddrlblspec.sql 753 2007-03-22 21:32:29Z ed $
--
create or replace package zaddrlabels as


procedure plate
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    out_stmt  out varchar2);

end zaddrlabels;
/

show error package zaddrlabels;
exit;
