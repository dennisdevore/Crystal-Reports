--
-- $Id$
--
create or replace PACKAGE alps.zmstrplt
IS

FUNCTION plate_mstrplt
(in_lpid IN varchar2
) return varchar2;

FUNCTION plate_item
(in_lpid IN varchar2
) return varchar2;

FUNCTION plate_custid
(in_lpid IN varchar2
) return varchar2;

FUNCTION plate_location
(in_lpid IN varchar2
) return varchar2;

FUNCTION plate_status
(in_lpid IN varchar2
) return varchar2;

FUNCTION plate_qty
(in_lpid IN varchar2
) return number;

FUNCTION plate_weight
(in_lpid IN varchar2
) return number;

FUNCTION shipplate_mstrplt
(in_lpid IN varchar2
) return varchar2;

FUNCTION shipplate_mstrplt_label
(in_lpid IN varchar2
) return varchar2;

FUNCTION shipplate_item
(in_lpid IN varchar2
) return varchar2;

FUNCTION shipplate_custid
(in_lpid IN varchar2
) return varchar2;

FUNCTION shipplate_location
(in_lpid IN varchar2
) return varchar2;

FUNCTION shipplate_status
(in_lpid IN varchar2
) return varchar2;

FUNCTION shipplate_qty
(in_lpid IN varchar2
) return number;

FUNCTION shipplate_weight
(in_lpid IN varchar2
) return number;

FUNCTION shipplate_trackingno
(in_lpid IN varchar2
) return varchar2;

FUNCTION shipplate_type
(in_lpid IN varchar2
) return varchar2;

FUNCTION shipplate_fromlpid
(in_lpid IN varchar2
) return varchar2;

FUNCTION shipplate_invclass
(in_lpid IN varchar2
) return varchar2;

PRAGMA RESTRICT_REFERENCES (plate_mstrplt, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (plate_item, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (plate_custid, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (plate_location, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (plate_status, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (plate_qty, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (plate_weight, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (shipplate_mstrplt, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (shipplate_mstrplt_label, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (shipplate_item, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (shipplate_custid, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (shipplate_location, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (shipplate_status, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (shipplate_qty, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (shipplate_weight, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (shipplate_trackingno, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (shipplate_type, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (shipplate_fromlpid, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (shipplate_invclass, WNDS, WNPS, RNPS);

END zmstrplt;
/
exit;
