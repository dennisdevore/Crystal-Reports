create table lastgpbill_all (
  code        varchar2 (12)  not null,
  descr       varchar2 (32)  not null,
  abbrev      varchar2 (12)  not null,
  dtlupdate   varchar2 (1),
  lastuser    varchar2 (12),
  lastupdate  date ) ;

insert into tabledefs
(tableid, hdrupdate, dtlupdate, codemask, lastuser, lastupdate)
values ('LastGPBill_All','Y','Y','>Aaaaaaa','SUP',sysdate);

insert into lastgpbill_all
(code, descr, abbrev, dtlupdate, lastuser, lastupdate)
values ('ALLALL', 'Last Header Export', '060101010000','Y','SUP',sysdate);

commit;


exit;

