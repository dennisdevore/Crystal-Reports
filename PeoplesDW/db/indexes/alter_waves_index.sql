--
-- $Id$
--
drop index waves_facstatus_idx;
drop index waves_statusfac_idx;
create index waves_openfacility_idx
on waves(openfacility);
exit;
