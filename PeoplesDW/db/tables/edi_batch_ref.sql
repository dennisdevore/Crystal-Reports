create table EDI_BATCH_REF (
  code        varchar2 (12)  not null,
  descr       varchar2 (32)  not null,
  abbrev      varchar2 (12)  not null,
  dtlupdate   varchar2 (1),
  lastuser    varchar2 (12),
  lastupdate  date ) ;

insert into tabledefs
(tableid, hdrupdate, dtlupdate, codemask, lastuser, lastupdate)
values ('EDI_BATCH_REF','Y','Y','>Aaaaaaa','SYNAPSE',sysdate);

insert into EDI_BATCH_REF
(code, descr, abbrev, dtlupdate, lastuser, lastupdate)
values ('2298831912', 'TYSFO16T', '2298831912','Y','SYNAPSE',sysdate);

commit;


exit;

