--
-- $Id: containertypes.sql 1 2006-09-06 00:00:00Z eric $
--
create table containertypes
(code varchar2(12) not null
,descr varchar2(255) not null
,abbrev varchar2(12) not null
,dtlupdate varchar2(1)
,lastuser varchar2(12)
,lastupdate date
);

create unique index containertypes_unique
   on containertypes(code);

insert into containertypes values('A','Above ground tank','Above ground','Y','SYSTEM',sysdate);
insert into containertypes values('B','Below ground tank','Below ground','Y','SYSTEM',sysdate);
insert into containertypes values('C','Tank inside building','Tank Inside','Y','SYSTEM',sysdate);
insert into containertypes values('D','Steel Drum','Steel Drum','Y','SYSTEM',sysdate);
insert into containertypes values('E','Plastic or non-metal drum','Plastic drum','Y','SYSTEM',sysdate);
insert into containertypes values('F','Can','Can','Y','SYSTEM',sysdate);
insert into containertypes values('G','Carboy','Carboy','Y','SYSTEM',sysdate);
insert into containertypes values('H','Silo','Silo','Y','SYSTEM',sysdate);
insert into containertypes values('I','Fiber drum','Fiber drum','Y','SYSTEM',sysdate);
insert into containertypes values('J','Bag','Bag','Y','SYSTEM',sysdate);
insert into containertypes values('K','Box','Box','Y','SYSTEM',sysdate);
insert into containertypes values('L','Cylinder','Cylinder','Y','SYSTEM',sysdate);
insert into containertypes values('M','Glass bottle or jug','Glass jug','Y','SYSTEM',sysdate);
insert into containertypes values('N','Plastic bottle or jug','Plastic jug','Y','SYSTEM',sysdate);
insert into containertypes values('O','Tote bin','Tote bin','Y','SYSTEM',sysdate);
insert into containertypes values('P','Tank wagon','Tank wagon','Y','SYSTEM',sysdate);
insert into containertypes values('Q','Rail car','Rail car','Y','SYSTEM',sysdate);
insert into containertypes values('R','Other','Other','Y','SYSTEM',sysdate);
insert into containertypes values('S','Pail','Pail','Y','SYSTEM',sysdate);
insert into containertypes values('T','Twinke wrapper','Twinke wrap','Y','SYSTEM',sysdate);
insert into containertypes values('U','Wax paper','Wax paper','Y','SYSTEM',sysdate);

insert into tabledefs values('ContainerTypes','Y','Y','>A;0;_','SYSTEM',sysdate);

exit;
