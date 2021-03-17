--
-- $Id$
--
drop index carrier_scac_idx;

create index CARRIER_SCAC_IDX on CARRIER (
SCAC
);

exit;
