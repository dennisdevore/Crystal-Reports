--
-- $Id$
--
alter table subtasks add
(pickingzone varchar2(10)
,cartontype varchar2(4)
,weight number(10,4)
,cube number(10,4)
,staffhrs number(10,4)
);

exit;
