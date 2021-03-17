--
-- $Id: invstat_846_dtl.sql 9364 2013-01-14 22:34:32Z jean $
--

create table invstat_846_dtl
(item varchar2(50)
,item_description varchar2(255) 
,uom varchar2(4)
,quantity_on_hand number(7)
,quantity_available number(7)
,quantity_allocated number(7)
,quantity_in_qa number(7)
,created timestamp
);

exit;
/