--
-- $Id$
--
create or replace PACKAGE alps.zworkorder
IS

PROCEDURE get_next_seq
(out_seq OUT number
,out_msg IN OUT varchar2
);

PROCEDURE get_next_instr_seq
(out_seq OUT number
,out_msg IN OUT varchar2
);

PROCEDURE validate_kit
(in_custid varchar2
,in_item varchar2
,in_kitted_class varchar2
,out_errorno OUT number
,out_msg IN OUT varchar2
);

procedure update_work_order
(in_orderid number
,in_shipid number
,in_orderitem varchar2
,in_orderlot varchar2
,in_reqtype varchar2
,in_facility varchar2
,in_taskpriority varchar2
,in_picktype varchar2
,in_complete varchar2
,in_stageloc varchar2
,in_userid varchar2
,in_recurse_count number
,out_msg IN OUT varchar2
);

function top_ordertype
(in_orderid number
,in_shipid number
) return varchar2;

function work_order_update_needed
(in_ordertype varchar2
,in_componenttemplate varchar2
,in_iskit varchar2
,in_childorderid number
,in_inventoryclass varchar2
,in_unkitted_class varchar2
) return varchar2;

PROCEDURE validate_ordered_kit_by_class
(in_orderid number
,in_shipid number
,in_item varchar2
,in_lotnumber varchar2
,in_custid varchar2
,in_invclassind varchar2
,in_inventoryclass varchar2
,out_errorno OUT number
,out_msg IN OUT varchar2
);

PRAGMA RESTRICT_REFERENCES (top_ordertype, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (work_order_update_needed, WNDS, WNPS, RNPS);

END zworkorder;
/
show error package zworkorder;
exit;