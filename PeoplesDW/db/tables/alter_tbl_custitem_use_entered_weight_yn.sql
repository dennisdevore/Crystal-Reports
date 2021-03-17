--
-- $Id: alter_tbl_custitem_use_entered_weight_yn.sql 1416 2006-12-19 23:11:38Z ed $
--
alter table custitem add (
use_entered_weight_yn char(1)
);

update custitem
   set use_entered_weight_yn = 'C'
   where use_entered_weight_yn is null;

exit;
