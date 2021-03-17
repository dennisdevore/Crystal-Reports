--
-- $Id$
--
drop table physicalinventoryhdr;

create table physicalinventoryhdr(
   id        number(7) not null,
   facility  varchar2(3) not null,
   paper     varchar2(1),
   status    varchar2(2),
   zone      varchar2(10),
   fromloc   varchar2(10),
   toloc     varchar2(10),
   requester varchar2(12),
   requested date,
   lastuser  varchar2(12),
   lastupdate date
);

create unique index pk_phinvhdr
  on physicalinventoryhdr(id);

create index idx_phinvhdr_status
  on physicalinventoryhdr(status);

exit;

