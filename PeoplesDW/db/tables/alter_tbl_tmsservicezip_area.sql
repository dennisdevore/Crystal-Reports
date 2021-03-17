--
-- $Id: alter_tbl_tmsservicezip.sql $
--
ALTER TABLE tmsservicezip modify(
  AREA        VARCHAR2 (6));

commit;

exit;
