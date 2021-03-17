--
-- $Id$
--
drop index requests_unique;

create unique index requests_unique
   on requests(facility,reqtype,descr);
   
exit;
