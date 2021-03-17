--
-- $Id$
--
--drop table door;

create table door
(facility varchar2(3) not null
,doorloc varchar2(10) not null
,loadno number(7)
,lastuser varchar2(12)
,lastupdate date
);

create unique index door_unique on
  door(facility,doorloc);
