--
-- $Id: alter_tbl_waves_by_zone.sql $
--
alter table waves add
(
	pick_by_zone  char(1) default 'N'
);

exit;
