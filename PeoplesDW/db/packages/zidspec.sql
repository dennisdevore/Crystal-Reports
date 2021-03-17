--
-- $Id$
--
create or replace PACKAGE alps.zitemdemand
IS

function include_exclude
(in_indicator varchar2
,in_indicator_values varchar2
,in_value varchar2
) return boolean;

function default_xdocklocid
(in_facility varchar2
) return varchar2;

procedure lip_placed_at_xdock
(in_lpid varchar2
,in_taskpriority varchar2
,in_userid varchar2
,out_errorno in out number
,out_msg in out varchar2
);

procedure xdock_pick_complete
(in_lpid varchar2
,in_userid varchar2
,out_errorno in out number
,out_msg in out varchar2
);

procedure create_itemdemand_for_shortage
(in_orderid number
,in_shipid number
,in_orderitem varchar2
,in_orderlot varchar2
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure check_for_active_itemdemand
(in_lpid varchar2
,out_destlocation IN OUT varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure check_xdock_receipt_order
(in_orderid number
,in_shipid number
,in_facility varchar2
,in_custid varchar2
,in_orderitem varchar2
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure unhold_outbound_xdock_orders
(in_orderid number
,in_shipid number
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

END zitemdemand;
/
show errors package zitemdemand;
exit;