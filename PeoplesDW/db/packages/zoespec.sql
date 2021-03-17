create or replace package zorderentry
IS
--
-- $Id$
--

FUNCTION cartontype_length
(in_cartontype IN varchar2
) return number;

FUNCTION cartontype_width
(in_cartontype IN varchar2
) return number;

FUNCTION cartontype_height
(in_cartontype IN varchar2
) return number;

FUNCTION sum_shipping_weight
(in_orderid IN number
,in_shipid  IN number
) return number;

FUNCTION sum_shipping_cost
(in_orderid IN number
,in_shipid  IN number
) return number;

FUNCTION max_shipping_container
(in_orderid IN number
,in_shipid  IN number
) return varchar2;

FUNCTION min_nonserial_lpid
(in_orderid IN number
,in_shipid  IN number
) return varchar2;

FUNCTION max_cartontype
(in_orderid IN number
,in_shipid  IN number
) return varchar2;

FUNCTION max_trackingno
(in_orderid IN number
,in_shipid  IN number
,in_orderitem IN varchar2 default null
,in_orderlot IN varchar2 default null
) return varchar2;

FUNCTION max_carrierused
(in_orderid IN number
,in_shipid  IN number
) return varchar2;

FUNCTION unknown_lip_count
(in_orderid IN number
,in_shipid  IN number
) return number;

FUNCTION orderdtl_line_count
(in_orderid IN number
,in_shipid  IN number
) return number;

FUNCTION orderdtlline_line_count
(in_orderid IN number
,in_shipid  IN number
) return number;


PROCEDURE get_next_orderid
(out_orderid OUT number
,out_msg IN OUT varchar2
);

PROCEDURE get_base_uom_equivalent
(in_custid IN varchar2
,in_itemalias IN varchar2
,in_uom IN varchar2
,in_qty IN number
,out_item OUT varchar2
,out_uom OUT varchar2
,out_qty OUT number
,out_msg  OUT varchar2
);

PROCEDURE get_base_uom_equivalent_up
(in_custid IN varchar2
,in_itemalias IN varchar2
,in_uom IN varchar2
,in_qty IN number
,out_item OUT varchar2
,out_uom  OUT varchar2
,out_qty  OUT number
,out_entered_uom out varchar2
,out_entered_qty out varchar2
,out_msg  OUT varchar2
);
PROCEDURE cancel_item
(in_orderid IN number
,in_shipid IN number
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE uncancel_item
(in_orderid IN number
,in_shipid IN number
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE cancel_order
(in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_source IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
);

procedure usp_cancel_order
(
in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_source IN varchar2
,in_userid IN varchar2
,out_cancel_id out number
,out_msg  OUT varchar2
);

PROCEDURE remove_order_from_hold
(in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_warning IN OUT number
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
,in_manual_removal IN varchar2 DEFAULT 'N'
);

PROCEDURE place_order_on_hold
(in_orderid IN number
,in_shipid IN number
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
);

PROCEDURE validate_line
(in_orderid IN number
,in_shipid IN number
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,out_warning IN OUT number
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
);

PROCEDURE validate_order
(in_orderid IN number
,in_shipid IN number
,in_userid IN varchar2
,out_warning IN OUT number
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
);

FUNCTION orderstatus_abbrev
(in_orderstatus IN varchar2
) return varchar2;

FUNCTION commitstatus_abbrev
(in_commitstatus IN varchar2
) return varchar2;

FUNCTION shiptype_abbrev
(in_shiptype IN varchar2
) return varchar2;

FUNCTION shipterms_abbrev
(in_shipterms IN varchar2
) return varchar2;

FUNCTION line_count
(in_orderid IN number
,in_shipid IN number
) return number;

procedure check_for_export_procs
(in_custid IN varchar2
,in_importfileid IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

FUNCTION line_number
(in_orderid IN number
,in_shipid IN number
,in_orderitem IN varchar2
,in_orderlot IN varchar2
) return number;

FUNCTION commit_date
(dateshipped IN date
,satokay     IN varchar2
,plusdays    IN number
) return date;

PROCEDURE cancel_order_request
(in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_source IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE usp_cancel_order_request
(in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_source IN varchar2
,in_userid IN varchar2
,out_cancel_id out varchar2
,out_msg   OUT varchar2
);

PROCEDURE regenerate_picks
(in_orderid IN number
,in_shipid IN number
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
);

FUNCTION line_number_str
(in_orderid IN number
,in_shipid IN number
,in_orderitem IN varchar2
,in_orderlot IN varchar2
) return varchar2;

FUNCTION last_pick_label
(in_orderid IN number
,in_shipid  IN number
) return varchar2;

function order_reference
(in_orderid number
,in_shipid number
) return varchar2;

function outbound_trackingno
(in_orderid number
,in_shipid number
,in_item varchar2
,in_lotnumber varchar2
,in_serialnumber varchar2
,in_useritem1 varchar2
,in_useritem2 varchar2
,in_useritem3 varchar2
) return varchar2;

function inbound_condition
(in_orderid number
,in_shipid number
,in_item varchar2
,in_lotnumber varchar2
,in_serialnumber varchar2
,in_useritem1 varchar2
,in_useritem2 varchar2
,in_useritem3 varchar2
) return varchar2;

procedure check_cancel_interface
(in_orderid IN NUMBER
,in_shipid IN NUMBER
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

FUNCTION get_pref_carrier
(in_orderid IN number
,in_shipid  IN number
,out_shiptype OUT varchar2
,out_delivcode OUT varchar2
) return varchar2;


FUNCTION line_qtyorder
(in_orderid IN number
,in_shipid IN number
,in_orderitem IN varchar2
,in_orderlot IN varchar2
) return number;

FUNCTION order_trackingnos
(in_orderid IN number
,in_shipid  IN number
) return varchar2;

FUNCTION order_trackingnos -- overload
(in_orderid IN number
,in_shipid  IN number
,in_seperator IN varchar2
) return varchar2;

FUNCTION dtl_trackingnos
(in_orderid IN number
,in_shipid  IN number
,in_item    IN varchar2
) return varchar2;

PROCEDURE regenerate_order
(in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
);

function expected_seal_value
(in_orderid IN number
,in_shipid IN number
) return varchar2;

PROCEDURE seal_override_request
(in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE seal_verification_attempt
(in_orderid IN number
,in_shipid IN number
,in_seal IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
);

function is_seal_verified
(in_orderid IN number
,in_shipid IN number
) return varchar2;

function get_min_days_to_expiration
(in_orderid IN number
,in_shipid IN number
,in_item IN varchar2
) return number;

function consumable_entry_required
(in_custid IN varchar2
,in_ordertype IN varchar2
) return varchar2;
procedure release_orders_from_hold
(in_included_rowids IN clob
,in_facility IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
,out_warning_count IN OUT number
,out_error_count IN OUT number
,out_release_count IN OUT number
);

function check_for_billing_charges
(in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_invtype IN varchar2
,in_event IN varchar2
) return boolean;

procedure update_ordered_values
(in_wave_plan_sql IN clob
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

FUNCTION total_cases
(in_orderid IN number
,in_shipid  IN number
) return number;

procedure check870
(in_custid IN varchar2
,in_orderid IN number
,in_shipid IN number
,out_msg in out varchar2
,out_map out varchar2
);
procedure request870
(in_custid IN varchar2
,in_orderid IN number
,in_shipid IN number
,in_userid IN varchar2
,out_msg IN OUT varchar2
);
procedure update_order_attach
(
  in_type in varchar2,
  in_data in varchar2,
  in_user in varchar2,
  in_filename in varchar2,
  out_msg in out varchar2
);
PRAGMA RESTRICT_REFERENCES (orderstatus_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (commitstatus_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (shiptype_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (shipterms_abbrev, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (line_count, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (unknown_lip_count, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (orderdtl_line_count, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (max_shipping_container, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (min_nonserial_lpid, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (max_cartontype, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (max_trackingno, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (max_carrierused, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (sum_shipping_weight, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (sum_shipping_cost, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (line_number, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (cartontype_height, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (cartontype_width, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (cartontype_length, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (commit_date, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (line_number_str, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (last_pick_label, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (order_reference, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (outbound_trackingno, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (inbound_condition, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (get_pref_carrier, WNDS, WNPS);
PRAGMA RESTRICT_REFERENCES (line_qtyorder, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (order_trackingnos, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (expected_seal_value, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (is_seal_verified, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (consumable_entry_required, WNDS, WNPS, RNPS);

END zorderentry;
/
exit;

