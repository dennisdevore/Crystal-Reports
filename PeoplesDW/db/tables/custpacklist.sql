--
-- $Id$
--
create table custpacklist
(custid varchar2(10)
,carrier varchar2(4)
,servicecode varchar2(4)
,packlistyn char(1)
,packlistformat varchar2(255)
,lastuser varchar2(12)
,lastupdate date
);

create unique index custpacklist_unique
  on custpacklist(custid,carrier,servicecode);
exit;
