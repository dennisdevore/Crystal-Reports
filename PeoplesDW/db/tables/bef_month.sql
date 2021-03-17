--
-- $Id: bef_month.sql 1 2005-08-03 12:20:03Z ron $
--
create table BEF_MONTH
(
   code        varchar2(12) not null,
   descr       varchar2(32) not null,
   abbrev      varchar2(12) not null,
   dtlupdate   varchar2(1),
   lastuser    varchar2(12),
   lastupdate  date
);

create unique index BEF_MONTH_idx
   on BEF_MONTH(code);

insert into tabledefs
   values('BEF_MONTH', 'N', 'N', '>A;0;_', 'SUP', sysdate);


insert into BEF_MONTH
VALUES ('1','January','01','Y','SUP', sysdate);
insert into BEF_MONTH
VALUES ('2','Febuary','02','Y','SUP', sysdate);
insert into BEF_MONTH
VALUES ('3','March','03','Y','SUP', sysdate);
insert into BEF_MONTH
VALUES ('4','April','04','Y','SUP', sysdate);
insert into BEF_MONTH
VALUES ('5','May','05','Y','SUP', sysdate);
insert into BEF_MONTH
VALUES ('6','June','06','Y','SUP', sysdate);
insert into BEF_MONTH
VALUES ('7','July','07','Y','SUP', sysdate);
insert into BEF_MONTH
VALUES ('8','August','08','Y','SUP', sysdate);
insert into BEF_MONTH
VALUES ('9','September','09','Y','SUP', sysdate);
insert into BEF_MONTH
VALUES ('0','October','10','Y','SUP', sysdate);
insert into BEF_MONTH
VALUES ('N','November','11','Y','SUP', sysdate);
insert into BEF_MONTH
VALUES ('D','December','12','Y','SUP', sysdate);



commit;

-- exit;
