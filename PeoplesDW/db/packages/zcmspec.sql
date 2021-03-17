--
-- $Id$
--
create or replace PACKAGE alps.zcommitment
IS

PROCEDURE expand_simple_kit_item
(in_orderid number
,in_shipid number
,in_item varchar2
,in_userid varchar2
,out_msg  IN OUT varchar2
);

function tokenized_column_value
(in_wave_descr IN varchar2
,in_orderid IN number
,in_shipid IN number
) return varchar2;

function column_select_sql
(in_object_name IN varchar2
,in_column_name IN varchar2
) return varchar2;

function tokenized_wave_descr
(in_wave_descr IN varchar2
,in_column_value IN varchar2
) return varchar2;

procedure check_for_split_wave_token
(in_wave IN number
,in_userid IN varchar2
,out_msg IN OUT varchar2
);

function ineligible_expiration_days_qty
(in_facility varchar2
,in_custid varchar2
,in_orderid number
,in_shipid number
,in_item varchar2
,in_orderlot varchar2
,in_invstatus varchar2
,in_inventoryclass varchar2
,in_min_days_to_expire number
) return number;

function in_str_clause
(in_indicator varchar2
,in_values varchar2
) return varchar2;

procedure match_template_parms
(in_wavetemplate varchar2
,in_orderid number
,in_shipid number
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

function committed_qty
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
) return number;

function allocable_qty
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
) return number;

function order_allocable_qty
(in_facility varchar2
,in_custid varchar2
,in_orderid number
,in_shipid number
) return number;

PROCEDURE commit_line
(in_facility varchar2
,in_custid varchar2
,in_orderid number
,in_shipid number
,in_orderitem varchar2
,in_uom varchar2
,in_orderlot varchar2
,in_invstatusind varchar2
,in_invstatus varchar2
,in_invclassind varchar2
,in_inventoryclass varchar2
,in_qty number
,in_priority varchar2
,in_reqtype varchar2
,in_enter_min_days_to_expire_yn varchar2
,in_min_days_to_expiration number
,in_userid varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE uncommit_line
(in_facility varchar2
,in_custid varchar2
,in_orderid number
,in_shipid number
,in_orderitem varchar2
,in_uom varchar2
,in_orderlot varchar2
,in_invstatusind varchar2
,in_invstatus varchar2
,in_invclassind varchar2
,in_inventoryclass varchar2
,in_qty number
,in_priority varchar2
,in_reqtype varchar2
,in_userid varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE commit_order
(in_orderid number
,in_shipid number
,in_facility varchar2
,in_userid IN OUT varchar2
,in_reqtype varchar2
,in_wave IN OUT number
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

PROCEDURE uncommit_order
(in_orderid number
,in_shipid number
,in_facility varchar2
,in_userid varchar2
,in_reqtype varchar2
,in_wave number
,out_msg IN OUT varchar2
);

PROCEDURE find_open_wave
(in_facility varchar2
,in_custid varchar2
,in_userid varchar2
,in_orderid number
,in_shipid number
,in_template varchar2
,out_wave IN OUT number
,out_tms IN OUT varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure auto_wave_plan
(in_facility varchar2
,in_custid varchar2
,in_wave_prefix varchar2
);

procedure find_next_release
(in_facility varchar2
,in_descr varchar2
,out_next_release IN OUT date
,out_msg IN OUT varchar2
);

PROCEDURE find_open_load
(in_facility varchar2
,in_custid varchar2
,in_userid varchar2
,in_orderid number
,in_shipid number
,in_column_name varchar2
,out_loadno IN OUT number
,out_stopno IN OUT number
,out_shipno IN OUT number
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);
function column_where_sql
(in_table_name IN varchar2
,in_column_name IN varchar2
) return varchar2;
PRAGMA RESTRICT_REFERENCES (in_str_clause, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (tokenized_wave_descr, WNDS, WNPS, RNPS);

END zcommitment;
/
show errors package zcommitment;
exit;
