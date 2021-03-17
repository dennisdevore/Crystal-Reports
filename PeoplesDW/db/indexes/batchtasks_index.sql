--
-- $Id$
--
create index batchtasks_wave_idx
on batchtasks(wave);
create index batchtasks_order_idx
on batchtasks(orderid,shipid);
exit;
