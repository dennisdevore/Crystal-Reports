--
-- $Id$
--
create or replace PACKAGE alps.zwave
IS

PROCEDURE set_debug_mode
(in_mode boolean
);

PROCEDURE debug_msg
(in_text varchar2
,in_userid varchar2
);

FUNCTION pick_to_label_okay
(in_orderid IN number
,in_shipid IN number
) return varchar2;

function single_shipping_units_only
(in_orderid IN number
,in_shipid IN number
) return varchar2;

function cartontype_group
(in_cartontype varchar
) return varchar2;

FUNCTION default_picktype
(in_facility varchar2
,in_locid varchar2
) return varchar2;

FUNCTION subtask_total
(in_facility varchar2
,in_locid varchar2
,in_item varchar2
) return number;

FUNCTION subtask_total_by_lip
(in_lpid varchar2
,in_custid varchar2
,in_item varchar2
) return number;

FUNCTION location_lastupdate
(in_facility varchar2
,in_locid varchar2
) return date;

function tasked_at_loc
(in_facility in varchar2
,in_locid    in varchar2
,in_custid   in varchar2
,in_item     in varchar2
,in_wave     in number
,in_lotnumber in varchar2)
return number;

function total_at_loc
(in_facility in varchar2
,in_locid    in varchar2
,in_custid   in varchar2
,in_item     in varchar2
,in_lotnumber in varchar2
,in_invstatus in varchar2
,in_inventoryclass in varchar2)
return number;

PROCEDURE get_next_wave
(out_wave OUT number
,out_msg IN OUT varchar2
);

procedure get_wave_totals
(in_facility varchar2
,in_wave number
,out_cntorder IN OUT number
,out_qtyorder IN OUT number
,out_weightorder IN OUT number
,out_cubeorder IN OUT number
,out_qtycommit IN OUT number
,out_weightcommit IN OUT number
,out_cubecommit IN OUT number
,out_staffhours IN OUT number
,out_msg IN OUT varchar2
);

procedure release_wave
(in_wave number
,in_reqtype varchar2
,in_facility varchar2
,in_taskpriority IN OUT varchar2
,in_picktype IN OUT varchar2
,in_userid varchar2
,in_trace varchar2
,out_msg IN OUT varchar2
);

procedure release_order
(in_orderid varchar2
,in_shipid number
,in_reqtype varchar2
,in_facility varchar2
,in_taskpriority varchar2
,in_picktype varchar2
,in_userid varchar2
,in_trace varchar2
,out_msg IN OUT varchar2
);

procedure find_a_pick
(in_fromfacility varchar2
,in_custid varchar2
,in_orderid number
,in_shipid number
,in_item varchar2
,in_lotnumber varchar2
,in_invstatus varchar2
,in_inventoryclass varchar2
,in_qty number
,in_pickuom varchar2
,in_repl_req_yn varchar2
,in_storage_or_stage varchar2
,in_ordered_by_weight varchar2
,in_qtytype varchar2
,in_wave number
,in_bat_zone_only varchar2
,in_parallel_pick_zones varchar2
,in_expdaterequired varchar2
,in_enter_min_days_to_expire_yn varchar2
,in_min_days_to_expiration number
,in_allocrule varchar2
,in_pass_count number
,out_lpid_or_loc IN OUT varchar2
,out_baseuom IN OUT varchar2
,out_baseqty IN OUT number
,out_pickuom IN OUT varchar2
,out_pickqty IN OUT number
,out_pickfront IN OUT varchar2
,out_picktotype IN OUT varchar2
,out_cartontype IN OUT varchar2
,out_picktype IN OUT varchar2
,out_wholeunitsonly IN OUT varchar2
,out_weight IN OUT number
,in_trace IN varchar2
,out_msg IN OUT varchar2);

procedure release_line
(in_orderid varchar2
,in_shipid varchar2
,in_orderitem varchar2
,in_orderlot varchar2
,in_reqtype varchar2
,in_facility varchar2
,in_taskpriority varchar2
,in_picktype varchar2
,in_complete varchar2
,in_stageloc varchar2
,in_sortloc varchar2
,in_batchcartontype varchar2
,in_regen varchar2
,in_userid varchar2
,in_trace varchar2
,in_recurse_count integer
,out_msg IN OUT varchar2
);

PROCEDURE unrelease_line
(in_facility varchar2
,in_custid varchar2
,in_orderid number
,in_shipid number
,in_orderitem varchar2
,in_uom varchar2
,in_lotnumber varchar2
,in_invstatusind varchar2
,in_invstatus varchar2
,in_invclassind varchar2
,in_inventoryclass varchar2
,in_qty number
,in_priority varchar2
,in_reqtype varchar2
,in_userid varchar2
,in_trace varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE unrelease_order
(in_orderid number
,in_shipid number
,in_facility varchar2
,in_userid varchar2
,in_reqtype varchar2
,in_trace varchar2
,out_wave IN OUT number
,out_msg IN OUT varchar2
);

procedure ready_wave
(in_wave number
,in_reqtype varchar2
,in_facility varchar2
,in_userid varchar2
,out_msg IN OUT varchar2
);

procedure undo_ready_wave
(in_wave number
,in_reqtype varchar2
,in_facility varchar2
,in_userid varchar2
,out_msg IN OUT varchar2
);

procedure complete_pick_tasks
(in_wave number
,in_facility varchar2
,in_orderid number
,in_shipid number
,in_taskpriority varchar2
,in_taskprevpriority varchar2
,in_picktype varchar2
,in_userid varchar2
,in_curruserid varchar2
,in_touserid varchar2
,in_consolidated varchar2
,in_trace varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

PROCEDURE submit_wave_request
(in_wave IN number
,in_trace IN varchar2
,in_userid IN varchar2
);

PROCEDURE submit_order_request
(in_orderid IN number
,in_shipid IN number
,in_trace IN varchar2
,in_userid IN varchar2
);

PROCEDURE submit_autowave_request
(in_wave IN number
,in_trace IN varchar2
,in_userid IN varchar2
);

PROCEDURE send_mass_man_triggers
(in_wave IN number
,in_termid IN varchar2
,in_userid IN varchar2
);


function cancelled_qty
(in_wave number
) return number;

function kitted_qty
(in_wave number
) return number;

function test_wave_aggregateness
	(in_wave in number)
return varchar2;

function test_wave_consolidate
	(in_wave in number)
return varchar2;

function test_wave_mass_manifest
	(in_wave in number)
return varchar2;

function test_wave_batchability
	(in_wave in number)
return varchar2;

function test_wave_ppzone_validity
	(in_wave in number)
return varchar2;

procedure wave_pre_validate
(in_included_rowids IN clob
,in_userid IN varchar2
,in_picktype IN varchar2
,in_release_for_tms IN varchar2
,in_sdi_max_units IN number
,out_tms_format IN OUT varchar2
,out_tms_status IN OUT varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure wave_commit
(in_wave IN number
,in_included_rowids IN clob
,in_reqtype IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
,out_error_count IN OUT number
);

procedure request_pack_lists
(in_wave number
,in_printer varchar2
,in_userid varchar2
,out_msg IN OUT varchar2
);


PRAGMA RESTRICT_REFERENCES (cartontype_group, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (subtask_total, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (subtask_total_by_lip, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (default_picktype, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (location_lastupdate, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (pick_to_label_okay, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (single_shipping_units_only, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (tasked_at_loc, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (total_at_loc, WNDS, WNPS, RNPS);

END zwave;
/
exit;
