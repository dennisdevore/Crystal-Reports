--
-- $Id: alter_tbl_waves_batch_pick_by_item_yn.sql 1 2005-05-26 12:20:03Z ed $
--
alter table waves add
(
batch_pick_by_item_yn char(1)
);

alter table waves add
(
task_assignment_sequence varchar2(12) -- ITEM, CUBE, WEIGHT, QUANTITY (within load number for batch pick by item)
);

exit;
