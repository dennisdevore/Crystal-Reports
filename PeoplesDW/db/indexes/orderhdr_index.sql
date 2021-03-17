--
-- $Id$
--
drop index orderhdr_idx;
drop index orderhdr_load_idx;
drop index orderhdr_commit_idx;
drop index orderhdr_status_idx;
drop index orderhdr_wave_idx;
drop index orderhdr_ref_idx;
drop index orderhdr_po_idx;

create unique index orderhdr_idx
on orderhdr(orderid, shipid);

create index orderhdr_load_idx
on orderhdr(loadno, stopno, shipno);

create index orderhdr_commit_idx
on orderhdr(fromfacility,commitstatus);

create index orderhdr_status_idx
on orderhdr(fromfacility,orderstatus);

create index orderhdr_wave_idx
on orderhdr(wave);

create index orderhdr_ref_idx
on orderhdr(reference);

create index orderhdr_po_idx
on orderhdr(po);
exit;