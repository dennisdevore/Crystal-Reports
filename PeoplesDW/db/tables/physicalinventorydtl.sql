--
-- $Id$
--
drop table physicalinventorydtl;

create table physicalinventorydtl(
   id           number(7) not null,
   facility     varchar2(3) not null,
   custid       varchar2(10),
   taskid       number(15) not null,
   lpid         varchar2(15),
   status       varchar2(2),
   location     varchar2(10),
   item varchar2(50),
   lotnumber    varchar2(30),
   uom          varchar2(4),
   systemcount  number(7),
   usercount    number(7),
   countby      varchar2(12),
   countdate    date,
   countcount   number(3),
   countlocation varchar2(10),
   countitem varchar2(50),
   countcustid  varchar2(10),
   countlot     varchar2(30),
   prev1countby      varchar2(12),
   prev1countdate    date,
   prev1usercount   number(7),
   prev1countlocation varchar2(10),
   prev1countitem varchar2(50),
   prev1countcustid  varchar2(10),
   prev1countlot     varchar2(30),
   prev2countby      varchar2(12),
   prev2countdate    date,
   prev2usercount   number(7),
   prev2countlocation varchar2(10),
   prev2countitem varchar2(50),
   prev2countcustid  varchar2(10),
   prev2countlot     varchar2(30),
   lastuser     varchar2(12),
   lastupdate   date
);

create unique index pk_phinvdtl
  on physicalinventorydtl
  (id, facility, location, custid, item, lotnumber, lpid);

create index idx_phinvdtl_custid
  on physicalinventorydtl(custid);

create index idx_phinvdtl_taskid
  on physicalinventorydtl(taskid);

create index idx_phynvdtl_lpid
  on physicalinventorydtl(lpid);

create index idx_phynvdtl_location
  on physicalinventorydtl(facility,location);
--exit;
