--
-- $Id$
--
alter table waves add
(cntorder number(7)
,qtyorder number(9)
,weightorder number(12,4)
,cubeorder number(12,4)
,qtycommit number(9)
,weightcommit number(12,4)
,cubecommit number(12,4)
,staffhrs number(12,4)
);
exit;
