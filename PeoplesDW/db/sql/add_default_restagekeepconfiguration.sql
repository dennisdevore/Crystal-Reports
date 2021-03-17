--
-- $Id: add_picklist_default.sql 1 2005-05-26 12:20:03Z ed $
--
insert into systemdefaults values ('RESTAGEKEEPCONFIGURATION', 'N', 'SUP', sysdate);
commit;
exit;

