--
-- $Id$
--
create table custitemlotcatchweight (
   facility   varchar2(3),
   custid     varchar2(10) not null,
   item varchar2(50) not null,
   lotnumber  varchar2(30),
   totweight  number(17,4)
);
exit;
