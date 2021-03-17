--
-- $Id: alter_tbl_zone_autostage.sql 1496 2007-01-24 09:39:40Z brianb $
--
alter table zone add
(auto_stage_yn char(1)
,auto_stage_location varchar2(10)
);

exit;
