--
-- $Id: alter_invstat_846_dtl.sql 14790 2015-11-05 19:47:15Z brianb $
--
alter table invstat_846_dtl modify item varchar2(50);
alter table invstat_846_dtl modify item_description varchar2(255);

exit;
