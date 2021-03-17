--
-- $Id$
--
drop table RcptNote944NoteEx;

create table RcptNote944NoteEx (
   sessionid varchar2(12),   -- CUSTIDn  n = sequence
   custid    varchar2(10),
   orderid    number(7),
   shipid    number(2),
   sequence  number(6),
   qualifier varchar2(4),
   note      varchar2(80)
);
