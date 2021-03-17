--
-- $Id$
-

create table orderdtlsn
(custid varchar2(10) not null
,orderid number(7) not null
,shipid number(2) not null
,item varchar2(50) not null
,lotnumber varchar2(30)
,sn varchar2(255)
,lastuser varchar2(12)
,lastupdate date
);
exit;
