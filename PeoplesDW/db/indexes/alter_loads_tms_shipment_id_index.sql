--
-- $Id$
--
drop index loads_tms_shipment_id_idx;
create index loads_tms_shipment_id_idx
on loads(tms_shipment_id);
exit;

