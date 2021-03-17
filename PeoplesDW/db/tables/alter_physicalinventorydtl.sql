--
-- $Id$
--
alter table physicalinventorydtl
add
(
   prev1countby      varchar2(12),
   prev1countdate    date,
   prev1usercount   number(7),
   prev1countlocation varchar2(10),
   prev1countitem    varchar2(20),
   prev1countcustid  varchar2(10),
   prev1countlot     varchar2(30),
   prev2countby      varchar2(12),
   prev2countdate    date,
   prev2usercount   number(7),
   prev2countlocation varchar2(10),
   prev2countitem    varchar2(20),
   prev2countcustid  varchar2(10),
   prev2countlot     varchar2(30)
);
exit;
