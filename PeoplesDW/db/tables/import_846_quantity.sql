--
-- $Id: import_846_quantity.sql 9364 2013-01-14 22:34:32Z jean $
--

create table import_846_quantity
(importfileid varchar2(255)
,invstatus varchar2(12) 
,uom varchar2(20)
,quantity varchar2(20)
,facility varchar2(3)
,custid varchar2(10)
,item varchar2(50)
,created timestamp
);

exit;