--
-- $Id$
--
drop table IrisShipEx;

create table IrisShipEx (
   sessionid varchar2(8),   -- T30DTV1nn  nn = sequence
   orderid   number(7),
   shipid    number(7),
   line      number(3),
   sortord   number(3),
   item varchar2(50),
   lotnumber varchar2(30),
   serialnumber varchar2(30),
   service   varchar2(4),
   class     varchar2(8),
   custid    varchar2(10),
   company   varchar2(4),
   warehouse varchar2(4),
   quantity  number(10,2),
   charge    number(10,2),
   weight    number(10,2),
   trackingno varchar2(20),
   pkgcount   number(3)
);

exit;
