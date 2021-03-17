--
-- $Id$
--
update custitem
	set iskit = 'N'
 where iskit is null;
exit;
