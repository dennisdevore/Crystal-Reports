--
-- $Id$
--
create table orderdtlbolcomments
(orderid number(7) not null
,shipid number(7) not null
,item varchar2(50) not null
,lotnumber varchar2(30)
,bolcomment long
,lastuser varchar2(12)
,lastupdate date
);
exit;