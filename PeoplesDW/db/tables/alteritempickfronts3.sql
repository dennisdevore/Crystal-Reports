--
-- $Id$
--
alter table itempickfronts
modify
(item varchar2(50) null);

alter table itempickfronts
add
(
lastpickeddate date,
pendingitem varchar2(50)
);

update itempickfronts a set lastpickeddate = (select  max(lastupdate)  from plate b
where a.facility = b.facility and a.custid=b.custid and a.item = b.item);

commit;

exit;
