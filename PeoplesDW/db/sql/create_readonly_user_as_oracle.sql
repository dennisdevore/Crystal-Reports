--
-- $Id: create_niceware.sql 361 2005-11-14 21:03:09Z ed $
--
create user synread
  identified by synr3ad54
  default tablespace users
  temporary tablespace temp
  profile default
  account unlock;
grant connect,create session,select any dictionary,select any table to synread;
alter user synread identified by synr3ad54;
exit;
