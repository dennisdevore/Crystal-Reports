--
-- $Id: tasks_index2.sql 7805 2012-01-16 18:50:53Z eric $
--
--drop index task_idx4;

create index task_idx4 on tasks(facility, custid, item, tasktype);
