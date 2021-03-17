create table lastqbbill_all (
  code        varchar2 (12)  not null,
  descr       varchar2 (32)  not null,
  abbrev      varchar2 (12)  not null,
  dtlupdate   varchar2 (1),
  lastuser    varchar2 (12),
  lastupdate  date ) ;

insert into tabledefs
(tableid, hdrupdate, dtlupdate, codemask, lastuser, lastupdate)
values ('LastQBBill_All','Y','Y','>Aaaaaaa','SYNAPSE',sysdate);

insert into lastqbbill_all
(code, descr, abbrev, dtlupdate, lastuser, lastupdate)
values ('ALLALL', 'Last Header Export', '060101010000','Y','SYNAPSE',sysdate);

commit;


exit;

