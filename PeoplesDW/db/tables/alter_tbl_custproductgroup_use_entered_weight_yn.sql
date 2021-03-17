--
-- $Id: alter_tbl_custproductgroup_use_entered_weight_yn.sql 1550 2007-02-02 07:45:54Z brianb $
--
alter table custproductgroup add (
use_entered_weight_yn char(1)
);
update custproductgroup
   set use_entered_weight_yn = 'C'
   where use_entered_weight_yn is null;

exit;
