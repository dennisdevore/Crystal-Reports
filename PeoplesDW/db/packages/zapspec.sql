--
-- $Id$
--
create or replace PACKAGE alps.zallplate
IS

FUNCTION expiration_date
(in_lpid IN varchar2
) return date;

FUNCTION expiry_action
(in_lpid IN varchar2
) return varchar2;

FUNCTION po
(in_lpid IN varchar2
) return varchar2;

FUNCTION rec_method
(in_lpid IN varchar2
) return varchar2;

FUNCTION condition
(in_lpid IN varchar2
) return varchar2;

FUNCTION last_operator
(in_lpid IN varchar2
) return varchar2;

FUNCTION last_task
(in_lpid IN varchar2
) return varchar2;

FUNCTION fifo_date
(in_lpid IN varchar2
) return date;

PRAGMA RESTRICT_REFERENCES (expiration_date, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (expiry_action, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (po, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (rec_method, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (condition, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (last_operator, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (last_task, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (fifo_date, WNDS, WNPS, RNPS);

END zallplate;
/
exit;