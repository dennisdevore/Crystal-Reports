--
-- $Id: zogspec.sql 4974 2010-04-22 15:42:54Z eric $
--
create or replace PACKAGE alps.order_grouping
IS

procedure group_orders
(in_orderid number
,in_shipid number
,in_validate_only_yn varchar2
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure group_by_item_and_qty
(in_orderid number
,in_shipid number
,in_validate_only_yn varchar2
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

END order_grouping;
/
exit;
