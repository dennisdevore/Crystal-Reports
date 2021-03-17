--
-- $Id$
--
update labelprofiles
set code = upper(substr(code,1,4));
update custitemlabelprofiles
set profid = upper(substr(profid,1,4));
commit;
exit;
