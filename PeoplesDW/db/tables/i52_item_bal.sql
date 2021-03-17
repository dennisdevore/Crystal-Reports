--
-- $Id$
--
/*
** this is a static representation of a view that is dynamically
** created at run time--see zim4.begin_i59_extract
*/
create  table I52_item_bal
(custid varchar2(10)
,warehouse varchar2(3)
,facility varchar2(4)
,item varchar2(50)
,invstatus varchar2(2)
,inventoryclass varchar2(2)
,qty number
,refid varchar2(2)
,lotnumber varchar2(30)
,unitofmeasure varchar2(4)
,eventdate date
,eventtime number
);
exit;
