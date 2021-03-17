--
-- $Id$
--
update carrier
set multiship = 'N'
where multiship is null;
commit;
exit;