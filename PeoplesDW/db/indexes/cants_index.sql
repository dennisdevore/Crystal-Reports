--
-- $Id$
--
drop index cants_nameid;
create index cants_nameid on cants
   (nameid);

exit;
