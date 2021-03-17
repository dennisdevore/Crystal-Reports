--
-- $Id$
--
create table shipshortreasons
(
  code        varchar2(12) not null,
  descr       varchar2(32) not null,
  abbrev      varchar2(12) not null,
  dtlupdate   varchar2(1),
  lastuser    varchar2(12),
  lastupdate  date
);
exit;
