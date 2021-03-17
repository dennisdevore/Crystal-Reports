--
-- $Id$
--
drop index allocrulesdtl_unique;

create unique index allocrulesdtl_unique
  on allocrulesdtl(facility,allocrule,priority);
   
exit;
