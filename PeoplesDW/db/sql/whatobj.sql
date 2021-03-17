--
-- $Id$
--
select object_name,object_type
from user_objects
where status != 'VALID'
and object_type
in ('VIEW','PACKAGE','PACKAGE BODY','TRIGGER');
exit;
