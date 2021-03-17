--
-- $Id: create_niceware.sql 361 2005-11-14 21:03:09Z ed $
--
create user niceware
  identified by r3aw3cin
  default tablespace users
  temporary tablespace temp
  profile default
  account unlock;
grant connect to niceware;
exit;
