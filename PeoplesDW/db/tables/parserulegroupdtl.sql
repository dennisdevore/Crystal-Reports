--
-- $Id: parserulegroupdtl.sql 1 2005-05-26 12:20:03Z ed $
--



create table parserulegroupdtl (
  groupid     varchar2(10) not null,
  ruleid      varchar2(10) not null,
  lastuser    varchar2(12),
  lastupdate  date );


create unique index parserulegroupdtl_idx on
  parserulegroupdtl(groupid, ruleid);


exit;