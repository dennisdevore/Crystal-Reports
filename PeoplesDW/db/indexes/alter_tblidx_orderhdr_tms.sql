--
-- $Id$
--
drop index orderhdr_tms_shipment_idx;
create index orderhdr_tms_shipment_idx on
  orderhdr(tms_shipment_id);
drop index orderhdr_tms_release_idx;
create index orderhdr_tms_release_idx on
  orderhdr(tms_release_id);

exit;
