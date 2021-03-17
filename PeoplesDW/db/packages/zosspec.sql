--
-- $Id$
--
create or replace PACKAGE alps.zordersummary
IS

PROCEDURE get_default_from_to_dates
(out_2daysago IN OUT varchar2
,out_yesterday IN OUT varchar2
,out_today IN OUT varchar2
,out_tomorrow IN OUT varchar2
);

PROCEDURE upgrade_delivery_service
(in_orderid IN number
,in_shipid IN number
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2);

END zordersummary;
/
exit;