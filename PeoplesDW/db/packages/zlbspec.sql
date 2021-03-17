--
-- $Id$
--
create or replace package alps.labor as

FUNCTION staff_hours
(in_facility IN varchar2
,in_custid IN varchar2
,in_item IN varchar2
,in_category IN varchar2
,in_zoneid IN varchar2
,in_uom IN varchar2
,in_qty IN number
) return number;

/*
FUNCTION order_staffhours
(in_orderid IN number
,in_shipid IN number
) return number;

FUNCTION line_staffhours
(in_orderid IN number
,in_shipid IN number
,in_item IN varchar2
,in_lotnumber IN varchar2
) return number;
*/

PROCEDURE compute_line_labor
(in_orderid IN number
,in_shipid IN number
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_userid IN varchar2
,in_picktype IN varchar2
,in_facility IN varchar2
,in_delete IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

PROCEDURE compute_order_labor
(in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

FUNCTION formatted_staffhrs
(in_staffhrs IN number
) return varchar2;

PRAGMA RESTRICT_REFERENCES (staff_hours, WNDS, WNPS, RNPS);
/*
PRAGMA RESTRICT_REFERENCES (order_staffhours, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (line_staffhours, WNDS, WNPS, RNPS);
*/
PRAGMA RESTRICT_REFERENCES (formatted_staffhrs, WNDS, WNPS, RNPS);

end labor;
/

exit;
