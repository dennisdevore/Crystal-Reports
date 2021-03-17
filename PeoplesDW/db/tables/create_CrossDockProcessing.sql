--
-- $Id$
--
create table CrossDockProcessing
(
   code        varchar2(12) not null,
   descr       varchar2(32) not null,
   abbrev      varchar2(12) not null,
   dtlupdate   varchar2(1),
   lastuser    varchar2(12),
   lastupdate  date
);

create unique index CrossDockProcessing_idx
   on CrossDockProcessing(code);

insert into tabledefs
   values('CrossDockProcessing', 'N', 'N', '>A;0;_', 'SUP', sysdate);

insert into crossdockprocessing
   values ('A', 'All Crossdock Processing', 'AllXDock', 'N', 'SUP', sysdate);

insert into crossdockprocessing
   values ('N', 'No Crossdock Processing', 'NoXDock', 'N', 'SUP', sysdate);

insert into crossdockprocessing
   values ('S', 'Standard Crossdock Processing', 'StndrdXDock', 'N', 'SUP', sysdate);

commit;

exit;
