--
-- $Id$
--
create or replace PACKAGE alps.zcustitem
IS

FUNCTION item_code
(in_custid IN varchar2
,in_itemalias IN varchar2
) return varchar2;

PROCEDURE get_customer_item
(in_custid IN varchar2
,in_itemalias IN varchar2
,out_item IN OUT varchar2
,out_lotrequired IN OUT varchar2
,out_hazardous IN OUT varchar2
,out_iskit IN OUT varchar2
,out_msg  IN OUT varchar2
);

FUNCTION custitem_status_abbrev
(in_status IN varchar2
) return varchar2;

FUNCTION custitem_sign
(in_status IN varchar2
) return number;

FUNCTION custitem_projected
(in_status IN varchar2
) return number;

FUNCTION hazardous_item
(in_custid IN varchar2
,in_item IN varchar2
) return varchar2;

FUNCTION hazardous_item_on_order
(in_orderid IN number
,in_shipid IN NUMBER
) return varchar2;

PROCEDURE reset_sub_sequence
(in_custid varchar2
,in_item varchar2
,in_userid varchar2
,out_msg IN OUT varchar2
);

FUNCTION product_group
(in_custid IN varchar2
,in_item IN varchar2
) return varchar2;

FUNCTION baseuom
(in_custid IN varchar2
,in_item IN varchar2
) return varchar2;

FUNCTION item_amt
(in_custid IN varchar2
,in_orderid in number
,in_shipid in number
,in_item IN varchar2
,in_lot in varchar2
) return number;

FUNCTION item_stackheight
(in_custid IN varchar2
,in_item IN varchar2
) return number;

FUNCTION item_weight
(in_custid IN varchar2
,in_item IN varchar2
,in_uom IN varchar2
) return number;

FUNCTION item_weight_use_entered_weight
(in_custid IN varchar2
,in_item IN varchar2
,in_orderid in number
,in_shipid in number
,in_uom IN varchar2
) return number;

FUNCTION item_cube
(in_custid IN varchar2
,in_item IN varchar2
,in_uom IN varchar2
) return number;

FUNCTION picktotype
(in_custid IN varchar2
,in_item IN varchar2
,in_pickuom IN varchar2
) return varchar2;

FUNCTION cartontype
(in_custid IN varchar2
,in_item IN varchar2
,in_pickuom IN varchar2
) return varchar2;

FUNCTION item_base_qty
(in_custid IN varchar2
,in_item IN varchar2
,in_uom IN varchar2
,in_qty IN number
) return number;

FUNCTION default_value
(in_defaultid varchar2
) return varchar2;

FUNCTION item_uom_length
(in_custid IN varchar2
,in_item IN varchar2
,in_uom IN varchar2
) return number;

FUNCTION item_uom_width
(in_custid IN varchar2
,in_item IN varchar2
,in_uom IN varchar2
) return number;

FUNCTION item_uom_height
(in_custid IN varchar2
,in_item IN varchar2
,in_uom IN varchar2
) return number;

PROCEDURE item_qty_descr
(in_custid IN varchar2
,in_item IN varchar2
,in_baseuom IN varchar2
,in_baseuom_qty IN number
,out_qty_descr IN OUT varchar2
);

FUNCTION item_touom_qty
(in_custid IN varchar2
,in_item IN varchar2
,in_uom IN varchar2
) return number;

FUNCTION item_tareweight
(in_custid IN varchar2
,in_item IN varchar2
,in_uom IN varchar2
) return number;

FUNCTION variancepct
(in_custid IN varchar2
,in_item IN varchar2
) return number;

FUNCTION variancepct_overage
(in_custid IN varchar2
,in_item IN varchar2
) return number;

FUNCTION item_qty_backorder
(in_facility IN varchar2
,in_custid IN varchar2
,in_item IN varchar2
) return number;


PROCEDURE configure_seq_object
(in_custid IN varchar2
,in_type IN varchar2 -- 'LOT','SER','US1','US2','US3'
,out_seq_name IN OUT varchar2
,out_min_seq IN OUT number
,out_max_seq IN OUT number
);

PROCEDURE validate_auto_seq
(in_custid IN varchar2
,in_productgroup IN varchar2
,in_item IN varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE get_auto_seq
(in_custid IN varchar2
,in_item IN varchar2
,in_type IN varchar2 -- 'LOT','SER','US1','US2','US3'
,out_seq  IN OUT varchar2
);

FUNCTION total_cases
(in_orderid IN number
,in_shipid IN NUMBER
) return varchar2;

PROCEDURE validate_cas_threshold
(in_casnumber IN varchar2
,out_msg  IN OUT varchar2
);

FUNCTION is_valid_cas_threshold
(in_casnumber IN varchar2
) return varchar2;

PRAGMA RESTRICT_REFERENCES (item_code, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (custitem_status_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (custitem_sign, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (custitem_projected, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (hazardous_item, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (hazardous_item_on_order, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (product_group, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (baseuom, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (item_amt, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (item_stackheight, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (item_cube, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (item_weight, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (picktotype, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (cartontype, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (item_base_qty, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (default_value, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (item_uom_length, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (item_uom_width, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (item_uom_height, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (item_touom_qty, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (item_tareweight, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (variancepct, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (variancepct_overage, WNDS, WNPS, RNPS);

END zcustitem;
/
exit;
