--
-- $Id$
--
create table asncartondtl
(orderid number(7) not null
,shipid number(7) not null
,item varchar2(50) not null
,lotnumber varchar2(30)
,serialnumber varchar2(30)
,useritem1 varchar2(20)
,useritem2 varchar2(20)
,useritem3 varchar2(20)
,inventoryclass varchar2(2)
,uom varchar2(4)
,qty number(7)
,trackingno varchar2(22) not null
,custreference varchar2(30)
,importfileid varchar2(255)
,created date
,lastuser varchar2(12)
,lastupdate date
);

create index asncartondtl_order_idx on
  asncartondtl(orderid,shipid,item,lotnumber,serialnumber,useritem1,useritem2,useritem3,trackingno,custreference,qty);

create index asncartondtl_trackingno_idx on
  asncartondtl(trackingno);

create index asncartondtl_custreference_idx on
  asncartondtl(custreference);

exit;
