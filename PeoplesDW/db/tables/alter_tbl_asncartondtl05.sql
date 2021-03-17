--
-- $Id: alter_tbl_asncartondtl05.sql 727 2006-03-27 16:12:12Z ed $
--
alter table asncartondtl add
(
   manufacturedate  date,
   invstatus   varchar2(2)
);

exit;
