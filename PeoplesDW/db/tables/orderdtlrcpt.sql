--
-- $Id$
--
drop table orderdtlrcpt;

create table orderdtlrcpt
(orderid number(7) not null
,shipid number(2) not null
,orderitem varchar2(50) not null
,orderlot varchar2(30)
,facility varchar2(3)
,custid varchar2(10)
,item varchar2(50)
,lotnumber varchar2(30)
,uom varchar2(4)
,inventoryclass varchar2(2)
,invstatus varchar2(2)
,lpid varchar2(15)
,qtyrcvd number(7)
,lastuser varchar2(12)
,lastupdate date
);
exit;
