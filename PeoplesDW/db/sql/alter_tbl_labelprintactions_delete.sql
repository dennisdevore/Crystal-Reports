--
-- $Id: alter_tbl_labelprintactions_delete.sql 9095 2012-11-08 16:53:53Z ed $
--
insert into labelprintactions
   values('D', 'Delete all labels', 'Delete All', 'N', 'SUP', sysdate);

commit;

exit;
