--
-- $Id$
--
alter table custitem add
(
   require_cyclecount_item varchar(1)
);
update custitem set require_cyclecount_item = 'Y'
   where require_cyclecount_item is null;
commit;

exit;
