--
-- $Id$
--
create or replace PACKAGE alps.zmiscpackage
IS

PROCEDURE cancel_order
(in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
);


END zmiscpackage;
/
exit;