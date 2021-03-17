--
-- $Id$
--
create table CUSTCONSIGNEESIPNAME
(CUSTID VARCHAR2(10) not null
,CONSIGNEE VARCHAR2(10) not null
,SIPNAME VARCHAR2(10)
,SIPADDR VARCHAR2(4)
,SIPCITY VARCHAR2(10)
,SIPSTATE VARCHAR(2)
,SIPZIP VARCHAR2(5)
,LASTUSER VARCHAR2(12)
,LASTUPDATE DATE
);

create unique index CUSTCONSIGNEESIPNAME_UNIQUE on CUSTCONSIGNEESIPNAME (
CUSTID
,SIPNAME
,SIPADDR
,SIPCITY
,SIPSTATE
,SIPZIP
);
--exit;