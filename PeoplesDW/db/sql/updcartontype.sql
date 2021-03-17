--
-- $Id$
--
update custitem
set cartontype = 'PAL'
where cartontype is null;
commit;
exit;
