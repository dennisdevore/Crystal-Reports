--
-- $Id$
--
create or replace package logteam_cslbl as

procedure order18
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    in_auxdata in varchar2,
    out_stmt  out varchar2);

procedure orderipk18
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    in_auxdata in varchar2,
    out_stmt  out varchar2);

end logteam_cslbl;
/

show error package logteam_cslbl;
exit;
