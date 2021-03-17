--
-- $Id: bef_date.sql 1 2005-08-03 12:20:03Z ron $
--
create table BEF_DATE
(
   code        varchar2(12) not null,
   descr       varchar2(32) not null,
   abbrev      varchar2(12) not null,
   dtlupdate   varchar2(1),
   lastuser    varchar2(12),
   lastupdate  date
);

create unique index BEF_DATE_idx
   on BEF_DATE(code);

insert into tabledefs
   values('BEF_DATE', 'N', 'N', '>A;0;_', 'SUP', sysdate);


insert into BEF_DATE
VALUES ('A','Day 01','01','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('B','Day 02','02','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('C','Day 03','03','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('D','Day 04','04','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('E','Day 05','05','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('F','Day 06','06','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('G','Day 07','07','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('H','Day 08','08','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('I','Day 09','09','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('J','Day 10','10','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('K','Day 11','11','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('L','Day 12','12','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('M','Day 13','13','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('N','Day 14','14','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('O','Day 15','15','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('P','Day 16','16','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('Q','Day 17','17','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('R','Day 18','18','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('S','Day 19','19','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('T','Day 20','20','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('U','Day 21','21','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('V','Day 22','22','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('W','Day 23','23','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('X','Day 24','24','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('Y','Day 25','25','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('Z','Day 26','26','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('1','Day 27','27','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('2','Day 28','28','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('3','Day 29','29','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('4','Day 30','30','Y','SUP', sysdate);
insert into BEF_DATE
VALUES ('5','Day 31','31','Y','SUP', sysdate);



commit;

-- exit;
