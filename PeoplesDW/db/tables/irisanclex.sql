--
-- $Id$
--
drop table IrisAnclEx;

create table IrisAnclEx (
   sessionid varchar2(8),   -- CUSTIDn  n = sequence
   orderid   number(7),
   shipid    number(7),
   service   varchar2(4), 
   class     varchar2(8),
   custid    varchar2(10),
   irisid    varchar2(4),
   company   varchar2(4),
   warehouse varchar2(4),
   quantity  number(10,2),
   charge    number(10,2)
);

exit;