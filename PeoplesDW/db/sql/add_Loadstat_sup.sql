--
-- $Id: add_Loadstat_sup.sql $
--
insert into Loadstatus values('S','Suspended - not in door','Suspend','N','SUP',sysdate);
commit;

exit;
