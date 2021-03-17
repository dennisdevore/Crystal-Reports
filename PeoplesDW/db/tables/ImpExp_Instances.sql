--
-- $Id:
--

create table IMPEXP_INSTANCES
(code varchar2(12) not null
,descr varchar2(255) not null
,abbrev varchar2(12) not null
,dtlupdate varchar2(1)
,lastuser varchar2(12)
,lastupdate date
);

create unique index IMPEXP_INSTANCES_unique
   on IMPEXP_INSTANCES(code);


insert into tabledefs values('ImpExp_Instances','Y','Y','>Aaaaaaaaaaaa;0;_','SYSTEM',sysdate);


exit;

