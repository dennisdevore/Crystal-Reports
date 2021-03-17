--
-- $Id$
--
create table itemdemand
(facility varchar2(3) not null
,item varchar2(50) not null
,lotnumber varchar2(30)
,priority char(1)
,invstatusind char(1)
,invclassind char(1)
,invstatus varchar2(255)
,inventoryclass varchar2(255)
,demandtype char(1)  -- 'O' order; 'R' replenishment
,orderid number(7)
,shipid number(2)
,loadno number(7)
,stopno number(7)
,shipno number(7)
,orderitem varchar2(50)
,orderlot varchar2(30)
,qty number(7)
,lastuser varchar2(12)
,lastupdate date
);

create index itemdemand_item_idx on itemdemand
 (facility,item,lotnumber);
create index itemdemand_order_idx on itemdemand
 (orderid,shipid,orderitem,orderlot);
exit;
