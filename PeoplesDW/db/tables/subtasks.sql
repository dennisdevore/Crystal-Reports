--
-- $Id$
--
create table subtasks
(taskid number(15) not null
,tasktype varchar2(2)
,facility varchar2(3)
,fromsection varchar2(10)
,fromloc varchar2(10)
,fromprofile varchar2(2)
,tosection varchar2(10)
,toloc varchar2(10)
,toprofile varchar2(2)
,touserid varchar2(10)
,custid varchar(10)
,item varchar2(50)
,lpid varchar2(15)
,uom varchar2(4)
,qty number(7)
,locseq number(5)
,loadno number(7)
,stopno number(7)
,shipno number(7)
,orderid number(7)
,shipid number(2)
,orderitem varchar2(50)
,orderlot varchar2(30)
,priority varchar2(1)
,prevpriority varchar2(1)
,curruserid varchar2(10)
,lastuser varchar2(12)
,lastupdate date
);
exit;
