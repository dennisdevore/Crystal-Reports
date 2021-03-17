--
-- $Id$
--
set heading off;
select object_type || ' ' || object_name from user_objects where status = 'INVALID';

exit;
