--
-- $Id$
--
drop table RcptNote944IdeEx;

create table RcptNote944IdeEx (
   sessionid varchar2(12),   -- CUSTIDn  n = sequence
   custid    varchar2(10),
   orderid    number(7),
   shipid    number(2),
   item varchar2(50),
   lotnumber varchar2(30),
   qty       number(7),
   uom       varchar2(4),
   condition varchar2(2),
   damagereason varchar2(2)
);
