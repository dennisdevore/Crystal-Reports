--
-- $Id$
--
update zone
set nextlinepickby = 'O'
where nextlinepickby is null;
commit;
exit;

