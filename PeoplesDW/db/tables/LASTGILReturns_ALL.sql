--
-- $Id:
--

create table LASTGILRETURNS_ALL
(code varchar2(12) not null
,descr varchar2(255) not null
,abbrev varchar2(12) not null
,dtlupdate varchar2(1)
,lastuser varchar2(12)
,lastupdate date
);

create unique index LASTGILReturns_ALL_unique
   on LASTGILReturns_ALL(code);


insert into tabledefs values('LASTGILReturns_ALL','Y','Y','>Aaaaaaaa;0;_','SYSTEM',sysdate);

insert into lastgilreturns_all values ('ALLALL', 'Last GIL Returns', '090101010000', 'Y', 'SYSTEM', sysdate);

exit;

