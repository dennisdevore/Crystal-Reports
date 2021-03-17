--
-- $Id$
--
create table allocrulesdtl
(facility varchar2(3)
,allocrule varchar2(10) not null
,priority number(7)
,invstatus varchar2(2)
,inventoryclass varchar2(2)
,uom varchar2(4)
,qtymin number(7)
,qtymax number(7)
,pickingzone varchar2(10)
,usefwdpick char(1)
,lifofifo char(1)
,datetype char(1)
,picktoclean char(1)
,lastuser varchar2(12)
,lastupdate date
);
exit;