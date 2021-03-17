--
-- $Id$
--
create index tasks_wave_idx
on tasks(wave);
create index tasks_order_idx
on tasks(orderid,shipid);
exit;
