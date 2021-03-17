--
-- $Id$
--
--drop table orderattach;

create table orderattach(
   orderid   number(7)  not null,
   filepath  varchar2(255) not null,
   lastuser  varchar2(12),
   lastupdate  date,
   constraint orderattach_pk primary key (orderid, filepath) enable
);

exit;
