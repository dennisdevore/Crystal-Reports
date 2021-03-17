--
-- $Id$
--
drop index orderlabor_order_idx;
drop index orderlabor_wave_idx;
create index orderlabor_order_idx
   on orderlabor(orderid,shipid,item,lotnumber);
create index orderlabor_wave_idx
   on orderlabor(wave);
exit;