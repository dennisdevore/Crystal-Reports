--
-- $Id$
--
alter table zone add
(separate_batch_tasks_yn char(1) default 'N'
,batch_tasks_limit number(5) default 0
);

exit;
