--
-- $Id$
--
create table custitemcount (
   custid      varchar2(10) not null,
   item varchar2(50) not null,
   type        varchar2(4) not null,
   uom         varchar2(4),
   cnt         number(15),
   lastuser    varchar2(12),
   lastupdate  date
);
exit;
