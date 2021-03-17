--
-- $Id: direct_release_warnings.sql 1 2006-09-06 00:00:00Z eric $
--
create table direct_release_warnings
(orderid number(9)
,shipid number(9)
,item varchar2(50)
,lotnumber varchar2(30)
,qtyorder number(10)
,qtycommit number(10)
,qtytasked number(10)
,warning_msg varchar2(255)
);

create index direct_release_warnings_idx on direct_release_warnings(orderid,shipid);

exit;
