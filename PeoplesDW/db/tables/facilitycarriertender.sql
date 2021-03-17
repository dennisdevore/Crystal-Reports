--
-- $Id: facilitycarriertender.sql 1 2005-05-26 12:20:03Z ed $
--
create table facilitycarriertender
(
  facility                varchar2(3) not null,
  carrier                 varchar2(4) not null,
  tendermapname           varchar2(35) not null,
  lastuser                varchar2(12),
  lastupdate              date
);
create unique index facilitycarriertender
on facilitycarriertender(facility, carrier, tendermapname);

--exit;
