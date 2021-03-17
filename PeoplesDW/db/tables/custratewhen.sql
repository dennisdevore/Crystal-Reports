--
-- $Id$
--
drop table custratewhen;
create table custratewhen
(custid varchar2(10) not null
,rategroup varchar2(10) not null
,effdate date not null
,activity varchar2(4) not null
,billmethod varchar2(4) not null
,businessevent varchar2(4) not null
,automatic varchar2(1) not null
,lastuser varchar2(12)
,lastupdate date
);
exit;
