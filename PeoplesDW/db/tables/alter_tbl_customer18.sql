--
-- $Id$
--
alter table customer add
(
recent_order_days number(7)
);
update customer
   set recent_order_days = 30
 where recent_order_days is null;
commit;
--exit;
