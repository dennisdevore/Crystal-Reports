--
-- $Id: subtasks_index1.sql 7805 2012-01-16 18:50:53Z eric $
--
--drop index subtask_idx1;

create index subtask_idx1 on subtasks(facility, custid, item, tasktype);
