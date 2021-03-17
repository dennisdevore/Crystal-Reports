--
-- $Id$
--
create table itempickfronts
(custid varchar2(10) not null
,item varchar2(10) not null
,facility varchar2(3)
,pickfront varchar2(10)
,pickuom varchar2(4)
,replenishqty number(7)
,replenishuom varchar2(4)
,maxqty number(7)
,maxuom varchar2(4)
,replenishwithuom varchar2(4)
,lastuser varchar2(12)
,lastupdate date
);
exit;
