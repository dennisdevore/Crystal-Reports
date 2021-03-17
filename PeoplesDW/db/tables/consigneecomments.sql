--
-- $Id$
--
drop table consigneecomments;

create table consigneecomments
(consignee varchar2(10) not null
,custid varchar2(10)
,comment1 long
,lastuser varchar2(12)
,lastupdate date
);
exit;