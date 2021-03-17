--
-- $Id$
--
alter table oldorderhdr add
(specialservice1 varchar2(4)
,specialservice2 varchar2(4)
,specialservice3 varchar2(4)
,specialservice4 varchar2(4)
,cod char(1)
,amtcod number(10,2)
);
exit;
