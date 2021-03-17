--
-- $Id$
--
create or replace package zlfv as

FUNCTION itemcnt(in_lpid varchar2)
return number;

FUNCTION ordercnt(in_lpid varchar2)
return number;

FUNCTION carriercnt(in_lpid varchar2)
return number;


PRAGMA RESTRICT_REFERENCES (itemcnt, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (ordercnt, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (carriercnt, WNDS, WNPS, RNPS);


END zlfv;
/
exit;

