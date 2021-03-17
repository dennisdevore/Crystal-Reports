--
-- $Id$
--
drop table loadstop;

create table loadstop
(loadno number(7)
,stopno number(7)
,entrydate date
,shipto varchar2(10)
,loadstopstatus varchar2(1)
,stageloc varchar2(10)
,qtyorder number(7)
,weightorder number(10,4)
,cubeorder number(10,4)
,amtorder number(10,2)
,qtyship number(7)
,weightship number(10,4)
,cubeship number(10,4)
,amtship number(10,2)
,qtyrcvd number(7)
,weightrcvd number(10,4)
,cubercvd number(10,4)
,amtrcvd number(10,2)
,comment1 long
,lastuser varchar2(12)
,lastupdate date
,statususer varchar2(12)
,statusupdate date
);

create unique index loadstop_idx
   on loadstop(loadno,stopno);
