--
-- $Id$
--
create index shippingplate_faccustorder_idx
   on shippingplate(facility,custid,orderid,shipid);
create index shippingplate_trackingno_idx
   on shippingplate(trackingno);
create index shippingplate_serialno_idx
   on shippingplate(serialnumber);
--exit;
