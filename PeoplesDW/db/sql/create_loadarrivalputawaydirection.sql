--
-- $Id$
--
create table loadarrivalputawaydirection
(
   code        varchar2(12) not null,
   descr       varchar2(32) not null,
   abbrev      varchar2(12) not null,
   dtlupdate   varchar2(1),
   lastuser    varchar2(12),
   lastupdate  date
);

create unique index loadarrivalputawaydir_idx
   on loadarrivalputawaydirection(code);

insert into tabledefs
   values('LoadArrivalPutawayDirection', 'N', 'N', '>A;0;_', 'SUP', sysdate);

insert into loadarrivalputawaydirection
   values('O', 'Operator Directed', 'Operator', 'N', 'SUP', sysdate);

insert into loadarrivalputawaydirection
   values('T', 'Task Directed', 'Task', 'N', 'SUP', sysdate);

commit;

exit;
