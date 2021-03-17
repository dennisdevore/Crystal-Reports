--
-- $Id: alter_tbl_customer_aux_use_entered_weight_yn.sql 1550 2007-02-02 07:45:54Z brianb $
--
alter table customer_aux add (
use_entered_weight_yn char(1)
);
update customer_aux
   set use_entered_weight_yn = 'N'
   where use_entered_weight_yn is null;
exit;
