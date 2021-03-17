create table EDI_PARTNER (
  code        varchar2 (12)  not null,
  descr       varchar2 (32)  not null,
  abbrev      varchar2 (12)  not null,
  dtlupdate   varchar2 (1),
  lastuser    varchar2 (12),
  lastupdate  date ) ;

insert into tabledefs
(tableid, hdrupdate, dtlupdate, codemask, lastuser, lastupdate)
values ('EDI_PARTNER','Y','Y','>Aaaaaaa','SYNAPSE',sysdate);

insert into EDI_PARTNER
(code, descr, abbrev, dtlupdate, lastuser, lastupdate)
values ('006903702', 'TYSFO16T', '006903702','Y','SYNAPSE',sysdate);

commit;


exit;

