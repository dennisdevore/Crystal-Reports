--
-- $Id: add_picktypelabel_default.sql 3830 2009-09-02 15:08:52Z ed $
--
insert into systemdefaults values ('ALLOWFULLTOTEPICKTOLP', 'Y', 'SUP', sysdate);
commit;
exit;

