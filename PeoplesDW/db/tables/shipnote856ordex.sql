--
-- $Id$
--
drop table shipnote856ordex;

create table shipnote856ordex(
   sessionid varchar2(12),   -- CUSTIDn  n = sequence
   asnnumber varchar2(30),   -- consignee load-stop-ship
   loadno    number(7),
   orderid   number(7),
   shipid    number(2),
   custid    varchar2(10),
   shipunits   number(8)
);
