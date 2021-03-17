--
-- $Id: alter_tbl_custitem_stacking_factor.sql 8660 2012-07-13 20:35:03Z eric $
--
alter table custitem add
(
   stacking_factor varchar(12)
);

exit;
