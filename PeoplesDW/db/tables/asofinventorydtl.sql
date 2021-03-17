--
-- $Id$
--
create table asofinventorydtl
(
 facility       varchar2(3)  not null
,custid         varchar2(10) not null
,item varchar2(50) not null
,lotnumber      varchar2(30)
,uom            varchar2(4)  not null
,effdate        date
,adjustment     number(10)
,reason         varchar2(10)
,lastuser       varchar2(12)
,lastupdate     date
);
exit;

