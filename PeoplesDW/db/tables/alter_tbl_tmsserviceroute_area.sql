--
-- $Id: alter_tbl_tmsserviceroute.sql  $
--

ALTER TABLE tmsserviceroute modify(
  FACILITYGROUP VARCHAR2 (6),
  AREA        VARCHAR2 (6),
  ROUTE       VARCHAR2 (6));

commit;

exit;
