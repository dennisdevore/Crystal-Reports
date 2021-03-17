--
-- $Id$
--
create unique index tasks_unique
on tasks(taskid);

create index tasks_load_idx
on tasks(loadno, stopno, shipno);
exit;