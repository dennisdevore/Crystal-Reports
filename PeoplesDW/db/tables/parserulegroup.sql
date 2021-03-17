--
-- $Id: parserulegroup.sql 1 2005-05-26 12:20:03Z ed $
--



create table parserulegroup (
  groupid     varchar2(10) not null,
  descr       varchar2(32),
  lastuser    varchar2(12),
  lastupdate  date );


create unique index parserulegroup_idx on
  parserulegroup(groupid);


exit;