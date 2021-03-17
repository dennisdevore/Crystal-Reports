--
-- $Id$
--
create table goaltime
(facility varchar2(3)
,custid varchar2(12)
,category varchar2(4)
,measure varchar2(4)
,qtyperhour number(10,4)
,uom varchar2(4)
,lastuser varchar2(12)
,lastupdate date
);

create unique index goaltime_unique
   on goaltime(facility,custid,category);

exit;
