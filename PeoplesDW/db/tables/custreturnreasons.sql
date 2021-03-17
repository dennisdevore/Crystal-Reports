--
-- $Id$
--
drop table custreturnreasons;

create table custreturnreasons (
   custid      varchar2(10) not null,
   code        varchar2(2) not null,
   descr       varchar2(32) not null,
   abbrev      varchar2(12) not null,
   lastuser    varchar2(12),
   lastupdate  date
);

exit;
