--
-- $Id$
--

alter table alps.tasks
modify(qty number(10),
pickqty number(10));

alter table alps.subtasks
modify(qty number(10),
pickqty number(10),
qtypicked number(10));

alter table alps.batchtasks
modify(qty number(10),
pickqty number(10));

alter table alps.taskhistory
modify(qty number(10),
pickqty number(10));

alter table alps.subtaskhistory
modify(qty number(10),
pickqty number(10),
qtypicked number(10));

alter table alps.batchtaskhistory
modify(qty number(10),
pickqty number(10));

exit;