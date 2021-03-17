--
-- $Id: alter_tbl_user_profile_01.sql 3006 2008-08-13 20:43:33Z ed $
--
alter table TBL_USER_PROFILE
modify(ASSIGNED_CUSTOMER VARCHAR2(255 BYTE));

exit;
