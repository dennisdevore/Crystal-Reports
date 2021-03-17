--
-- $Id$
--
create table packinglist
(
  packlist_field_value varchar2(40) not null,
  packlist_format varchar2(255) not null,
  lastuser  varchar2(12),
  lastupdate  date
);

create unique index packinglist_idx on
   packinglist(packlist_field_value);

exit;