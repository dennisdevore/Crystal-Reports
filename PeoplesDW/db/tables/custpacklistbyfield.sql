--
-- $Id$
--
create table custpacklistbyfield
(
  custid  varchar2(10) not null,
  packlist_field1_value  varchar2(40) not null,
  packlist_field2_value  varchar2(40),
  packlist_format varchar2(255),
  lastuser  varchar2(12),
  lastupdate  date
);

create unique index custpacklistbyfield_unique on custpacklistbyfield(custid, packlist_field1_value, packlist_field2_value);

exit;