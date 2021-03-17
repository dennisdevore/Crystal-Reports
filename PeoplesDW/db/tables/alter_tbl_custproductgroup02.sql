--
-- $Id$
--
alter table custproductgroup add
(
   require_cyclecount_item varchar(1)
);
update custproductgroup set require_cyclecount_item = 'Y'
   where require_cyclecount_item is null;
commit;

exit;
