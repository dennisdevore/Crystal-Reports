--
-- $Id$
--
--drop table import_invadj_947_hdr;

create table import_invadj_947_hdr
(importfileid varchar2(255) not null
,facility varchar2(3) not null
,custid varchar2(10) not null
,transdate date
,transtime  varchar2(10)
,facility_name varchar2(40)
,adjno varchar2(14) not null
);

exit;
