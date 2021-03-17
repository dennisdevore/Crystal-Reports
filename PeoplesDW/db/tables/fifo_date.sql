create table FIFO_DATE
(
   code        varchar2(12) not null,
   descr       varchar2(32) not null,
   abbrev      varchar2(12) not null,
   dtlupdate   varchar2(1),
   lastuser    varchar2(12),
   lastupdate  date
);

create unique index FIFO_DATE_idx
   on FIFO_DATE(code);

insert into tabledefs
   values('FIFO_DATE', 'N', 'N', '>A;0;_', 'SUP', sysdate);


insert into FIFO_DATE
VALUES ('M','Manufacture','Manufacture','Y','SUP', sysdate);
insert into FIFO_DATE
VALUES ('E','Expiration','Expiration','Y','SUP', sysdate);
insert into FIFO_DATE
VALUES ('R','Receipt','Receipt','Y','SUP', sysdate);
insert into FIFO_DATE
VALUES ('L','Lot Number','Lot Number','Y','SUP', sysdate);



commit;

-- exit;
