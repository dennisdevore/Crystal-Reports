--
-- $Id: lbl_debug_level.sql 1 2005-05-26 12:20:03Z ed $
--
create table lbl_debug_level (
  code        varchar2 (12)  not null,
  descr       varchar2 (32)  not null,
  abbrev      varchar2 (12)  not null,
  dtlupdate   varchar2 (1),
  lastuser    varchar2 (12),
  lastupdate  date);


create unique index lbl_debug_level_idx on
  lbl_debug_level(code) ;

insert into tabledefs (tableid,hdrupdate,dtlupdate,codemask)
values('lbl_debug_level','y','y','>aaaaaaaa;0;_');

insert into lbl_debug_level ( code,descr,abbrev) values ('LEVEL','Last Freight Bill Export','0');

exit;
