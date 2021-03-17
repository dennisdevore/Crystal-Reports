--
-- $Id$
--
drop table shipnote856hdrex;

create table shipnote856hdrex(
   sessionid varchar2(12),   -- CUSTIDn  n = sequence
   asnnumber varchar2(30),   -- consignee load-stop-ship
   structure varchar2(4),
   status    varchar2(2),   -- CC if complete BO if backordered
   bol       varchar2(30),
   custid    varchar2(10),
   facility  varchar2(3),
   loadno    number(7),
   consignee varchar2(10),
   shiptype  varchar2(1),
   appointment varchar2(8), -- YYYYMMDD
   shipunits   number(8),
   weight      number(8),
   orderid     number(7),
   shipid      number(2)
);
