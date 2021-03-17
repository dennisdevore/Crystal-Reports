--
-- $Id: bef_year.sql 1 2005-08-03 12:20:03Z ron $
--
create table BEF_YEAR
(
   code        varchar2(12) not null,
   descr       varchar2(32) not null,
   abbrev      varchar2(12) not null,
   dtlupdate   varchar2(1),
   lastuser    varchar2(12),
   lastupdate  date
);

create unique index BEF_YEAR_idx
   on BEF_YEAR(code);

insert into tabledefs
   values('BEF_YEAR', 'N', 'N', '>A;0;_', 'SUP', sysdate);


insert into BEF_YEAR
VALUES ('0','Year 2000','2000','Y','SUP', sysdate);
insert into BEF_YEAR
VALUES ('1','Year 2001','2001','Y','SUP', sysdate);
insert into BEF_YEAR
VALUES ('2','Year 2002','2002','Y','SUP', sysdate);
insert into BEF_YEAR
VALUES ('3','Year 2003','2003','Y','SUP', sysdate);
insert into BEF_YEAR
VALUES ('4','Year 2004','2004','Y','SUP', sysdate);
insert into BEF_YEAR
VALUES ('5','Year 2005','2005','Y','SUP', sysdate);
insert into BEF_YEAR
VALUES ('6','Year 2006','2006','Y','SUP', sysdate);
insert into BEF_YEAR
VALUES ('7','Year 2007','2007','Y','SUP', sysdate);
insert into BEF_YEAR
VALUES ('8','Year 2008','2008','Y','SUP', sysdate);
insert into BEF_YEAR
VALUES ('9','Year 1999','1999','Y','SUP', sysdate);



commit;

-- exit;
