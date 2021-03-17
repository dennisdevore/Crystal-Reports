--
-- $Id$
--
drop index task_idx2;

create index task_idx2 on tasks(priority, taskid);

drop index task_idx3;

create index task_idx3 on tasks(touserid);
