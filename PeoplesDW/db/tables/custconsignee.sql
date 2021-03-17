--
-- $Id$
--
drop table custconsignee;

create table custconsignee
(
CUSTID                                   VARCHAR2(10) not null
,consignee varchar2(10) not null
, LASTUSER                                 VARCHAR2(12)
, LASTUPDATE                               DATE
);

exit;
