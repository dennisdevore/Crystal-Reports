--
-- $Id$
--
drop table orderhistory;

create table orderhistory(
   chgdate   date       not null,
   orderid   number(7)  not null,
   shipid    number(2)  not null,
   userid    varchar2(12) not null,
   action    varchar2(20) not null,
   lpid      varchar2(15),
   item varchar2(50),
   lot       varchar2(30),
   msg       varchar2(2000)
);



exit;
