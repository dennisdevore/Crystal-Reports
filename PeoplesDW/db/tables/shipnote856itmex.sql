--
-- $Id$
--
drop table shipnote856itmex;

create table shipnote856itmex(
   sessionid varchar2(12),   -- CUSTIDn  n = sequence
   asnnumber varchar2(30),   -- consignee load-stop-ship
   loadno    number(7),
   orderid   number(7),
   shipid    number(2),
   custid    varchar2(10),
   ucc128    varchar2(20),
   item varchar2(50),
   venditem  varchar2(49),
   upc       varchar2(20),
   shipped   number(7),
   shipuom   varchar2(4),
   ordered   number(7),
   orderuom  varchar2(4),
   orderlot  varchar2(30)
);
