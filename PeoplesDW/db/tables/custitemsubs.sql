--
-- $Id$
--
create table custitemsubs
(custid varchar2(10) not null
,item varchar2(50) not null
,seq number(7)
,itemsub varchar2(20) not null
,lastuser varchar2(12)
,lastupdate date
);
