--
-- $Id$
--
drop view loadstageview;
drop view loadstopstageview;
drop view orderhdrstageview;
drop view locationstageview;
update loadstop
set facility = (select facility from loads
      where loadstop.loadno = loads.loadno)
where facility is null;
commit;
exit;
