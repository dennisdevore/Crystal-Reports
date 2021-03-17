--
-- $Id: alter_appobjects_objname_length.sql 1 2005-05-26 12:20:03Z dm $
--
alter table applicationobjects modify objectname varchar2(180);
exit;

