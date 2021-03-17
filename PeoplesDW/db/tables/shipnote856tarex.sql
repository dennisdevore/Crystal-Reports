--
-- $Id$
--
drop table shipnote856tarex;

create table shipnote856tarex(
   sessionid varchar2(12),   -- CUSTIDn  n = sequence
   asnnumber varchar2(30),   -- consignee load-stop-ship
   loadno    number(7),
   orderid   number(7),
   shipid    number(2),
   ucc128    varchar2(20)
);
