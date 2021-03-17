--
-- $Id: alter_tbls_pickfront_by_invclass.sql 0 2008-02-04 00:00:00Z eric $
--

alter table custitem add
(pick_front_by_invclass char(1)
);

update custitem
   set pick_front_by_invclass = 'N'
 where pick_front_by_invclass is null;
commit;

alter table itempickfronts add
(inventoryclass varchar2(2)
);

exit;
