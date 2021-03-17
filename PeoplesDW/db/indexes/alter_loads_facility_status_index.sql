--
-- $Id: alter_loads_index.sql 1 2005-05-26 12:20:03Z ed $
--
create index loads_facility_status_idx
on loads(facility,loadstatus) tablespace users16kb;
exit;
