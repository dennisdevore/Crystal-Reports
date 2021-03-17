--
-- $Id: saratemperatures.sql 1 2006-09-06 00:00:00Z eric $
--
create table saratemperatures
(code varchar2(12) not null
,descr varchar2(255) not null
,abbrev varchar2(12) not null
,dtlupdate varchar2(1)
,lastuser varchar2(12)
,lastupdate date
);

create unique index saratemperatures_unique
   on saratemperatures(code);

insert into saratemperatures values('A','Ambient temperature','Ambient','Y','SYSTEM',sysdate);
insert into saratemperatures values('B','Temperature maintained by heating','Temp heating','Y','SYSTEM',sysdate);
insert into saratemperatures values('C','Temperature maintained by cooling','Temp cooling','Y','SYSTEM',sysdate);
insert into saratemperatures values('D','Cryogenic conditions','Cryogenic','Y','SYSTEM',sysdate);

insert into tabledefs values('SARATemperatures','Y','Y','>A;0;_','SYSTEM',sysdate);

exit;
