--
-- $Id$
--
drop index cyclecountactivity_tasklp;

create index cyclecountactivity_tasklp on cyclecountactivity
   (taskid, lpid);

drop index cyclecountactivity_taskitem;

create index cyclecountactivity_taskitem on cyclecountactivity
   (taskid, custid, item, lotnumber);

exit;
