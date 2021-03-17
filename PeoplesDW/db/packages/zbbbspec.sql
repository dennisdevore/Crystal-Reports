--
-- $Id: zbbbspec.sql 7277 2011-09-24 06:31:18Z brianb $
--
create or replace PACKAGE zbedbathbeyond
IS

AUTHOR constant appmsgs.author%type := 'BBBROUTING';

PROCEDURE set_debug_mode
(in_mode boolean
);

PROCEDURE debug_msg
(in_text varchar2
,in_custid varchar2
,in_facility varchar2
,in_userid varchar2
);

function routing_control_value
(in_custid varchar2
,in_orderid number
,in_shipid number
) return varchar2;

function is_a_bbb_order
(in_custid varchar2
,in_orderid number
,in_shipid number
) return varchar2;

function distance_to_consignee
(in_shipto varchar2
,in_fromfacility varchar2
) return integer;

function oversize_carton_type
(in_custid varchar2
,in_bbb_custid_template varchar2
,in_item varchar2
,in_uom varchar2
) return varchar2;

procedure compute_carton_count
(in_orderid number
,in_shipid number
,in_item varchar2
,in_userid varchar2
,out_carton_uom IN OUT varchar2
,out_carton_count IN OUT number
);

FUNCTION zipcode_matches
(in_zipcode varchar2
,in_zipcode_match varchar2
) return boolean;

FUNCTION assigned_ltl_carrier
(in_custid varchar2
,in_fromfacility varchar2
,in_shipto varchar2
,in_effdate date
) return varchar2;

FUNCTION assigned_tl_carrier
(in_custid varchar2
,in_fromfacility varchar2
,in_shipto varchar2
,in_effdate date
) return varchar2;

PROCEDURE submit_uncommit_wave_job
(in_wave number
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

PROCEDURE uncommit_wave
(in_wave number
,in_userid varchar2
);

PROCEDURE assign_pool_tl_shipments
(in_wave number
,in_custid varchar2
,in_fromfacility varchar2
,in_control_value varchar2
,in_userid varchar2
,in_bbb_pooler_shipto varchar2
,in_generate_p_and_c_waves_by varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

PROCEDURE assign_pool_ltl_shipments
(in_wave number
,in_custid varchar2
,in_fromfacility varchar2
,in_control_value varchar2
,in_generate_p_and_c_waves_by varchar2
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

PROCEDURE assign_small_package_shipments
(in_wave number
,in_custid varchar2
,in_fromfacility varchar2
,in_control_value varchar2
,in_bbb_routing_yn varchar2 -- 'P'ooler and Consolidator, 'V'endor Program
,in_generate_p_and_c_waves_by varchar2
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

PROCEDURE split_consolidated_to_stores
(in_wave number
,in_shipment_rowid rowid
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

PROCEDURE route_wave
(in_func varchar2 /* 'CHECK'--check for shortages only; 'ROUTE'--route the wave */
,in_wave number
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

function is_consolidator
(in_shipto varchar2
) return char;

PROCEDURE unroute_master_wave
(in_master_wave number
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

function routing_request_carrier
(in_custid varchar2
) return varchar2;

PROCEDURE assign_vendor_tl_shipments
(in_wave number
,in_custid varchar2
,in_fromfacility varchar2
,in_control_value varchar2
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

PROCEDURE assign_vendor_ltl_shipments
(in_wave number
,in_custid varchar2
,in_fromfacility varchar2
,in_control_value varchar2
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

PROCEDURE combine_waves
(in_included_wave_rowids clob
,in_fromfacility varchar2
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

PROCEDURE uncombine_wave
(in_wave number
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

function tasksview_item
(in_wave number
,in_taskid number
,in_tasktype varchar2
,in_item varchar2
) return varchar2;

PRAGMA RESTRICT_REFERENCES (distance_to_consignee, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (assigned_ltl_carrier, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (assigned_tl_carrier, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (zipcode_matches, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (oversize_carton_type, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (is_consolidator, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (routing_request_carrier, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (is_a_bbb_order, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (tasksview_item, WNDS, WNPS, RNPS);

END zbedbathbeyond;
/

show errors package zbedbathbeyond;

exit;
