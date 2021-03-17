--
-- $Id$
--
create table carrierservicecodes
(carrier varchar2(4) not null
,servicecode varchar2(4) not null
,descr varchar2(32)
,abbrev varchar2(12)
,upgradecode varchar2(4)
,lastuser varchar2(12)
,lastupdate date
);

create unique index carrierservicecodes_idx on
  carrierservicecodes(carrier,servicecode);

exit;
