--
-- $Id: add_def_lot_default.sql 1 2005-05-26 12:20:03Z ed $
--
insert into systemdefaults values ('DEFAULT_LOT', 'Default Lot Number', 'SUP', sysdate);
commit;
exit;

