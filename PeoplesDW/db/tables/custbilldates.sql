--
-- $Id$
--
create table custbilldates
(
 custid         varchar2(10) not null
,nextrenewal    date
,nextreceipt    date
,nextmiscellaneous date
,nextassessorial   date
,lastuser varchar2(12)
,lastupdate date
);
exit;
