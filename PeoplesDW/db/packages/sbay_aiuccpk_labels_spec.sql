--
-- $Id$
--
create or replace package sbay_aiuccpk as


procedure order18lbl
   (in_lpid    in varchar2,
    in_func    in varchar2,       -- Q - query, X - execute
    in_action  in varchar2,       -- A - all, P - print only
    in_auxdata in varchar2,
    out_stmt   out varchar2);


procedure order14lbl
   (in_lpid    in varchar2,
    in_func    in varchar2,       -- Q - query, X - execute
    in_action  in varchar2,       -- A - all, P - print only
    in_auxdata in varchar2,
    out_stmt   out varchar2);

procedure order18plt
   (in_lpid    in varchar2,
    in_func    in varchar2,       -- Q - query, X - execute
    in_action  in varchar2,       -- A - all, P - print only
    in_auxdata in varchar2,
    out_stmt   out varchar2);

procedure order14plt
   (in_lpid    in varchar2,
    in_func    in varchar2,       -- Q - query, X - execute
    in_action  in varchar2,       -- A - all, P - print only
    in_auxdata in varchar2,
    out_stmt   out varchar2);

end sbay_aiuccpk;
/

show error package sbay_aiuccpk;
exit;
