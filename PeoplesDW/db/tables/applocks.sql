--
-- $Id$
--
drop table applocks;

create table applocks
(lockid varchar2(36)
,facility varchar2(3) 
,custid varchar2(10)
,loadno number(7)
,lastuser varchar2(12)
,lastupdate date
);

create index applocks_unique
   on applocks(lockid);
