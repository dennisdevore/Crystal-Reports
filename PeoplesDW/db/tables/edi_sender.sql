create table EDI_SENDER (
  code        varchar2 (12)  not null,
  descr       varchar2 (32)  not null,
  abbrev      varchar2 (12)  not null,
  dtlupdate   varchar2 (1),
  lastuser    varchar2 (12),
  lastupdate  date ) ;

insert into tabledefs
(tableid, hdrupdate, dtlupdate, codemask, lastuser, lastupdate)
values ('EDI_SENDER','Y','Y','>Aaaaaaa','SYNAPSE',sysdate);

insert into EDI_SENDER
(code, descr, abbrev, dtlupdate, lastuser, lastupdate)
values ('TYSUN', 'TYSFO16T', 'TYSUN','Y','SYNAPSE',sysdate);

commit;


exit;

