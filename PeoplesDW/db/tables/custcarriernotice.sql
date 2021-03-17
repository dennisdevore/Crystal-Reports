--
-- $Id: custcarriernotice.sql 1695 2009-03-30 18:38:39Z ed $
--

create table custcarriernotice
(
  custid      varchar2(10) not null,
  carrier     varchar2(10) not null,
  ordertype   char(1) not null,
  formatname  varchar2(35) not null,
  lastuser    varchar2(12),
  lastupdate  date
);
create unique index custcarriernotice_idx on custcarriernotice
(custid, ordertype, carrier, formatname);




