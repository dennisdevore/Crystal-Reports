create table lastsagesp1bill_all (
  code        varchar2 (12)  not null,
  descr       varchar2 (32)  not null,
  abbrev      varchar2 (12)  not null,
  dtlupdate   varchar2 (1),
  lastuser    varchar2 (12),
  lastupdate  date ) ;

insert into tabledefs
(tableid, hdrupdate, dtlupdate, codemask, lastuser, lastupdate)
values ('lastsagesp1bill_All','Y','Y','>Aaaaaaa','SUP',sysdate);

insert into lastsagesp1bill_all
(code, descr, abbrev, dtlupdate, lastuser, lastupdate)
values ('ALLALL', 'Last Sage SP1 Export', '181231010000','Y','SUP',sysdate);

commit;

exit;
