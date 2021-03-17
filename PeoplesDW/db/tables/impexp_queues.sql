create table IMPEXP_QUEUES
(
   code        varchar2(12) not null,
   descr       varchar2(32) not null,
   abbrev      varchar2(12) not null,
   dtlupdate   varchar2(1),
   lastuser    varchar2(12),
   lastupdate  date
);

create unique index impexp_queues_idx
   on impexp_queues(code);

insert into tabledefs
   values('ImpExp_Queues', 'N', 'N', '>Cccccccccccc;0;_', 'SUP', sysdate);

commit;

exit;
