--
-- $Id:$
--
create table droptypes
(
  code        varchar2(12) not null,
  descr       varchar2(32) not null,
  abbrev      varchar2(12) not null,
  dtlupdate   varchar2(1),
  lastuser    varchar2(12),
  lastupdate  date
);
insert into tabledefs
   values('DropTypes', 'N', 'N', '>AAAA;0;_', 'SUP', sysdate);
insert into droptypes(code, descr, abbrev, dtlupdate,
    lastuser, lastupdate)
values ('DROP','DROP','DROP','N','SUP',sysdate);
insert into droptypes(code, descr, abbrev, dtlupdate,
    lastuser, lastupdate)
values ('LIVE','LIVE','LIVE','N','SUP',sysdate);
exit;
