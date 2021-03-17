--
-- $Id$
--
alter table usergrids drop column gridlayout;

create table usercxgrids
(
  nameid      varchar2(12 byte)                 not null,
  formid      varchar2(32 byte)                 not null,
  gridid      varchar2(32 byte)                 not null,
  gridlayout  blob
);

create unique index usercxgrids_unique on usercxgrids
(nameid, formid, gridid);


alter table usercxgrids add (
  constraint pk_usercxgrids
 primary key
 (nameid, formid, gridid));

exit;
