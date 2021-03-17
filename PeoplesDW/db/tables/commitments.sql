--
-- $Id$
--
create table commitments
(facility varchar2(3) not null
,custid varchar2(10) not null
,item varchar2(50) not null
,inventoryclass varchar2(2)
,invstatus varchar2(2)
,status varchar2(2)
,lotnumber varchar2(20)
,uom varchar2(4)
,qty number(16)
,orderid number(7)
,shipid number(2)
,orderitem varchar2(50)
,priority varchar2(1)
,lastuser varchar2(12)
,lastupdate date
);
exit;
