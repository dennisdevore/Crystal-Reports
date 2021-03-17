--
-- $Id$
--
alter table zone add
(
   count_after_pick char(1)
);

update zone
	set count_after_pick = 'N'
   where count_after_pick is null;

commit;

exit;
