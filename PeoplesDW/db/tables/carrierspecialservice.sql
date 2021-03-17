--
-- $Id$
--
create table carrierspecialservice
(carrier varchar2(4) not null
,servicecode varchar2(4) not null
,specialservice varchar2(4) not null
,descr varchar2(32)
,abbrev varchar2(12)
,multishipcode varchar2(30)
,lastuser varchar2(12)
,lastupdate date
);

create unique index carrierspecialservice_idx on
  carrierspecialservice(carrier,servicecode,specialservice);

exit;
