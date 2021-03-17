--
-- $Id:
--
create table LASTGILShipped_ALL
(code varchar2(12) not null
,descr varchar2(255) not null
,abbrev varchar2(12) not null
,dtlupdate varchar2(1)
,lastuser varchar2(12)
,lastupdate date
);

create unique index LASTGILShipped_ALL_unique
   on LASTGILShipped_ALL(code);

insert into tabledefs values('LASTGILShipped_ALL','Y','Y','>Aaaaaaaaa','SYSTEM',sysdate);
insert into lastgilshipped_all values ('ALLALL', 'Last GIL Shipped', '090121010000', 'Y', 'SYSTEM', sysdate);

exit;

