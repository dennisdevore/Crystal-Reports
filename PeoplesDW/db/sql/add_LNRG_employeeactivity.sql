--
-- $Id: add_LNRG_employeeactivity.sql 1 2005-05-26 12:20:03Z ed $
--
insert into employeeactivities values('LNRG', 'Close load w/o label regen', 'Cls no Regen', 'N', 'SYSTEM', sysdate);

commit;

exit;

