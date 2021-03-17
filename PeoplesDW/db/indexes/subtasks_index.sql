--
-- $Id$
--
drop index subtasks_unique;
drop index subtasks_taskid;
drop index subtasks_lpid;

create index subtasks_taskid
on subtasks(taskid);

create index subtasks_lpid
on subtasks(lpid);

exit;
