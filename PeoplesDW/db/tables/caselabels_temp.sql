--
-- $Id$
--
drop table caselabels_temp;

create global temporary table caselabels_temp
(
   orderid     number,
   shipid      number,
   custid      varchar2(10),
   item varchar2(50),
   lotnumber   varchar2(30),
   lpid        varchar2(15),
   seq         number,
   seqof       number,
   quantity    number(7),
   labeltype   varchar2(2),
   barcodetype char(1),
   auxrowid    varchar2(20),
   matched     char(1)
)
on commit delete rows;

exit;
