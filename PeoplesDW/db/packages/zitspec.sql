--
-- $Id$
--
create or replace PACKAGE alps.zitem
IS

FUNCTION uom_abbrev
(in_uom IN varchar2
) return varchar2;

FUNCTION status_abbrev
(in_status IN varchar2
) return varchar2;

FUNCTION item_abbrev
(in_custid IN varchar2
,in_item IN varchar2
) return varchar2;

FUNCTION item_productgroup
(in_custid IN varchar2
,in_item IN varchar2
) return varchar2;

FUNCTION item_descr
(in_custid IN varchar2
,in_item IN varchar2
) return varchar2;

FUNCTION backorder_abbrev
(in_backorder IN varchar2
) return varchar2;

FUNCTION qtytype_abbrev
(in_qtytype IN varchar2
) return varchar2;

PROCEDURE max_uom
(in_custid IN varchar2
,in_item IN varchar2
,out_maxuom IN OUT varchar2
);

FUNCTION alloc_qty
(in_custid IN varchar2
,in_item IN varchar2
,in_facility IN varchar2
) return number;

FUNCTION alloc_weight
(in_custid IN varchar2
,in_item IN varchar2
,in_facility IN varchar2
) return number;

FUNCTION alloc_qty_class
(in_custid IN varchar2
,in_item IN varchar2
,in_facility IN varchar2
,in_inventoryclass IN varchar2
) return number;

FUNCTION not_avail_qty
(in_custid IN varchar2
,in_item IN varchar2
,in_facility IN varchar2
,in_inventoryclass IN varchar2
) return number;

FUNCTION no_neg
(in_number IN number
) return number;

FUNCTION alias_by_descr
(in_custid IN varchar2
,in_item IN varchar2
,in_aliasdesc IN varchar2
) return varchar2;

FUNCTION committed_picknotship_qty
(in_custid IN varchar2
,in_item IN varchar2
,in_facility IN varchar2
) return number;

PRAGMA RESTRICT_REFERENCES (uom_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (status_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (item_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (item_descr, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (backorder_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (item_productgroup, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (qtytype_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (alloc_qty, WNDS, WNPS);
PRAGMA RESTRICT_REFERENCES (alloc_qty_class, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (not_avail_qty, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (no_neg, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (alias_by_descr, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (committed_picknotship_qty, WNDS, WNPS, RNPS);

END zitem;
/
exit;
