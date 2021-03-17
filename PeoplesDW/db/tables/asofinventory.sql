--
-- $Id$
--
create table asofinventory
(
 facility       varchar2(3)  not null
,custid         varchar2(10) not null
,item varchar2(50) not null
,lotnumber      varchar2(30)
,uom            varchar2(4)  not null
,effdate        date
,previousqty    number(10)
,currentqty     number(10)
,lastuser varchar2(12)
,lastupdate date
);
exit;
