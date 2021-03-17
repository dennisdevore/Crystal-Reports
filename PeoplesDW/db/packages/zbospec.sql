--
-- $Id$
--
create or replace PACKAGE alps.backorder
IS

procedure create_back_order_item
(in_orderid varchar2
,in_shipid varchar2
,in_orderitem varchar2
,in_orderlot varchar2
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

END backorder;
/
exit;