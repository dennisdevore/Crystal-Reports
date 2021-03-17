--
-- $Id$
--
drop index allocruleshdr_unique;

create unique index allocruleshdr_unique
  on allocruleshdr(facility,allocrule);
   
exit;
