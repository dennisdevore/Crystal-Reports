--
-- $Id: alteractivity.sql 1 2005-05-26 12:20:03Z ed $
--
alter table temp_inventory_adjustment
add
(
calc_weight_from_item  VARCHAR2(1) DEFAULT 'N'
);
exit;