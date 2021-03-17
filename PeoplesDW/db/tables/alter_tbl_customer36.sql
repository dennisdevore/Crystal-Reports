--
-- $Id$
--
alter table customer add(
   order_changes_ok varchar(1)
);

update customer set order_changes_ok = 'N'
   where order_changes_ok is null;
commit;

exit;
