--
-- $Id$
--
create table labelprintactions
(
   code        varchar2(12) not null,
   descr       varchar2(32) not null,
   abbrev      varchar2(12) not null,
   dtlupdate   varchar2(1),
   lastuser    varchar2(12),
   lastupdate  date
);

create unique index labelprintactions_idx
   on labelprintactions(code);

insert into tabledefs
   values('LabelPrintActions', 'N', 'N', '>A;0;_', 'SUP', sysdate);

insert into labelprintactions
   values('A', 'Generate and print all labels', 'Generate All', 'N', 'SUP', sysdate);

insert into labelprintactions
   values('P', 'Print existing labels', 'Print Only', 'N', 'SUP', sysdate);

insert into labelprintactions
   values('N', 'Generate and print new labels', 'Generate New', 'N', 'SUP', sysdate);

commit;

exit;
