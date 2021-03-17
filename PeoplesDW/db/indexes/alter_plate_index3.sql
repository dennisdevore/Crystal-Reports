--
-- $Id$
--
drop index plate_workorder;

create index plate_workorder
   on plate(facility, workorderseq, workordersubseq);
exit;
