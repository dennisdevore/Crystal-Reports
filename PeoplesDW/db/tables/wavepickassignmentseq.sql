create table WavePickAssignmentSeq (
  code        varchar2 (12)  not null,
  descr       varchar2 (32)  not null,
  abbrev      varchar2 (12)  not null,
  dtlupdate   varchar2 (1),
  lastuser    varchar2 (12),
  lastupdate  date ) ;

insert into tabledefs
   values('WavePickAssignmentSeq', 'N', 'N', '>Aaaaaaaa;0;_', 'SUP', sysdate);
insert into WavePickAssignmentSeq
(code, descr, abbrev, dtlupdate, lastuser, lastupdate)
values ('ITEM', 'By Item', 'By Item','Y','SYNAPSE',sysdate);
insert into WavePickAssignmentSeq
(code, descr, abbrev, dtlupdate, lastuser, lastupdate)
values ('CUBE', 'By Item', 'By Cube','Y','SYNAPSE',sysdate);
insert into WavePickAssignmentSeq
(code, descr, abbrev, dtlupdate, lastuser, lastupdate)
values ('WEIGHT', 'By Item', 'By Item','Y','SYNAPSE',sysdate);
insert into WavePickAssignmentSeq
(code, descr, abbrev, dtlupdate, lastuser, lastupdate)
values ('QUANTITY', 'By Item', 'By Cube','Y','SYNAPSE',sysdate);

create unique index WavePickAssignmentSeq_Idx on WavePickAssignmentSeq(code);

commit;
exit;