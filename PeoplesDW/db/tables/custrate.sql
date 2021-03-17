--
-- $Id$
--
create table custrate
(custid varchar2(10) not null
,rategroup varchar2(10) not null
,effdate date not null
,activity varchar2(4) not null
,billmethod varchar2(4) not null
,uom varchar2(4)
,rate number(12,6)
,gracedays number(2)
,lastuser varchar2(12)
,lastupdate date
);
exit;