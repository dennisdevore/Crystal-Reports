--
-- $Id$
--
--drop table import_invadj_947_dtl;

create table import_invadj_947_dtl
(importfileid varchar2(255) not null
,item varchar2(50) not null
,adjreason varchar2(2)
,quantity number(3)
,uom varchar2(4)
,facility varchar2(3) not null
,custid varchar2(10) not null
,adjno varchar2(14) not null
,invstatus varchar2(2)
);

exit;