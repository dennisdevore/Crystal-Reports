--
-- $Id$
--
alter table customer add(
   require_cyclecount_item varchar(1)
);

update customer set require_cyclecount_item = 'Y'
   where require_cyclecount_item is null;
commit;

exit;
