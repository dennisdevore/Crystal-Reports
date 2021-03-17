--
-- $Id$
--
update tbl_user_profile
	set 	password='sitemgr',
	user_status=1,
	login_attempts=0
where nameid='Sitemanager';
commit;
exit;
