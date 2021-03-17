--
-- $Id$
--
drop table custauditstageloc;

create table custauditstageloc
(facility varchar2(3) not null
,custid varchar2(10) not null
,auditstageloc varchar2(10) not null
,lastuser varchar2(12)
,lastupdate date
);

create unique index custauditstageloc_unique
   on custauditstageloc(facility,custid);

create unique index custauditstageloc_custid
  on custauditstageloc(custid,facility);
exit;

