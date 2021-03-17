--
-- $Id$
--
create or replace PACKAGE alps.zweight
IS

DEFAULT_LBS_TO_KGS_FACTOR CONSTANT  number := 2.20462262;

FUNCTION system_lbs_to_kgs_factor
return number;

FUNCTION from_lbs_to_kgs
(in_custid varchar2
,in_lbs  number
) return number;

FUNCTION from_kgs_to_lbs
(in_custid varchar2
,in_kgs  number
) return number;

FUNCTION is_ordered_by_weight
(in_orderid number
,in_shipid number
,in_item varchar2
,in_lotnumber varchar2
) return char;

FUNCTION weight_to_display
(in_custid varchar2
,in_lbs  number
) return number;

procedure check_pick_weight_range
   (in_qty       in number,         --\
    in_item      in varchar2,       --- only used if (in_weight == 0)
    in_uom       in varchar2,       --/
    in_lpid      in varchar2,       -- optional
    in_orderid   in number,
    in_shipid    in number,
    in_orderitem in varchar2,
    in_orderlot  in varchar2,
    in_weight    in number,
    out_lower    out number,
    out_upper    out number,
    out_message  out varchar2);

procedure get_lineitem_weight
   (in_orderid     in number,
    in_shipid      in number,
    in_item        in varchar2,
    in_lotnumber   in varchar2,
    out_weight     out number,
    out_tot_weight out number,
    out_confirmed  out varchar2,
    out_message    out varchar2);

procedure confirm_received_weight
   (in_orderid    in number,
    in_shipid     in number,
    in_item       in varchar2,
    in_lotnumber  in varchar2,
    in_weight     in number,
    out_message   out varchar2);

FUNCTION order_by_weight_qty
(in_orderid number
,in_shipid number
,in_item varchar2
,in_lotnumber varchar2
) return number;

function calc_order_by_weight_qty
(in_custid varchar2
,in_item varchar2
,in_uom varchar2
,in_weight_entered_lbs number
,in_weight_entered_kgs number
,in_qtytype varchar2
) return number;

PRAGMA RESTRICT_REFERENCES (from_lbs_to_kgs, WNDS, WNPS);
PRAGMA RESTRICT_REFERENCES (from_kgs_to_lbs, WNDS, WNPS);
PRAGMA RESTRICT_REFERENCES (is_ordered_by_weight, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (weight_to_display, WNDS, WNPS);
PRAGMA RESTRICT_REFERENCES (order_by_weight_qty, WNDS, WNPS);
PRAGMA RESTRICT_REFERENCES (calc_order_by_weight_qty, WNDS, WNPS);

END zweight;
/
exit;
