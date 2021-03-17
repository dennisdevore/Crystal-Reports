--
-- $Id: LipPropertyValues.sql 1 2005-08-03 12:20:03Z ron $
--
create table LipPropertyValues
(
   code        varchar2(12) not null,
   descr       varchar2(32) not null,
   abbrev      varchar2(12) not null,
   dtlupdate   varchar2(1),
   lastuser    varchar2(12),
   lastupdate  date
);

create unique index LipPropertyValues_idx
   on LipPropertyValues(code);

insert into tabledefs
   values('LipPropertyValues', 'N', 'N', '>A;0;_', 'SUP', sysdate);


insert into LipPropertyValues
VALUES ('Y','Yes','Yes','N','SUP', sysdate);
insert into LipPropertyValues
VALUES ('N','No','No','N','SUP', sysdate);
insert into LipPropertyValues
VALUES ('P','Upon Pick','Upon Pick','N','SUP', sysdate);
insert into LipPropertyValues
VALUES ('C','Use Customer Default','Use Default','N','SUP', sysdate);
insert into LipPropertyValues
VALUES ('A','Automatic Sequence','AutoSeq','N','SUP', sysdate);
commit;
insert into LotRequiredOptions
VALUES ('A','Automatic Sequence','AutoSeq','N','SUP', sysdate);
exit;
