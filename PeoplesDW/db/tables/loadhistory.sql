--
-- $Id: loadhistory.sql 1 2005-05-26 12:20:03Z ed $
--
create table loadhistory(
   loadno    number(7)  not null,
   chgdate   date       not null,
   userid    varchar2(12) not null,
   action    varchar2(20) not null,
   msg       varchar2(2000)
);

create index loadhistory_load_idx on
  loadhistory(loadno,chgdate,userid);


exit;
