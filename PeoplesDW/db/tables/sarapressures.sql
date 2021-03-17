--
-- $Id: sarapressures.sql 1 2006-09-06 00:00:00Z eric $
--
create table sarapressures
(code varchar2(12) not null
,descr varchar2(255) not null
,abbrev varchar2(12) not null
,dtlupdate varchar2(1)
,lastuser varchar2(12)
,lastupdate date
);

create unique index sarapressures_unique
   on sarapressures(code);

insert into sarapressures values('A','Ambient pressure','Ambient','Y','SYSTEM',sysdate);
insert into sarapressures values('B','Greater than ambient pressure','Above amb.','Y','SYSTEM',sysdate);
insert into sarapressures values('C','Less than ambient pressure','Below amb.','Y','SYSTEM',sysdate);

insert into tabledefs values('SARAPressures','Y','Y','>A;0;_','SYSTEM',sysdate);

exit;
