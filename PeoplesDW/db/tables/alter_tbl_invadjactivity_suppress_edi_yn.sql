--
-- $Id: alter_tbl_invadjactivity_suppress_edi_yn.sql 1558 2007-02-05 20:26:20Z brianb $
--
alter table invadjactivity add
(
suppress_edi_yn char(1)
);

exit;
