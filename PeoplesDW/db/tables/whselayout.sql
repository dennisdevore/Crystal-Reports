--
-- $Id:  $
--
create table whselayout
(
  nameid              varchar2(12) not null,
  facility            varchar2(3) not null,
  layout              blob
);

create unique index whselayout_unique on whselayout
(nameid, facility);

alter table whselayout add (
  constraint pk_whselayout
 primary key
 (nameid, facility));

exit;
