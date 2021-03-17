--
-- $Id:
--

create table LASTGILPO_ALL
(code varchar2(12) not null
,descr varchar2(255) not null
,abbrev varchar2(12) not null
,dtlupdate varchar2(1)
,lastuser varchar2(12)
,lastupdate date
);

create unique index LASTGILPO_ALL_unique
   on LASTGILPO_ALL(code);


insert into tabledefs values('LASTGILPO_ALL','Y','Y','>Aaaaaaaa;0;_','SYSTEM',sysdate);

insert into lastgilpo_all values ('ALLALL', 'Last GIL Po', '090101010000', 'Y', 'SYSTEM', sysdate);

exit;

