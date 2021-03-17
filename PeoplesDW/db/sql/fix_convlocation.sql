--
-- $Id$
--
update zone
   set convlocation = upper(rtrim(convlocation));

commit;
exit;
