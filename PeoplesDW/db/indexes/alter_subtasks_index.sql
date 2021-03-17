--
-- $Id$
--
create index subtasks_wave_idx
on subtasks(wave);
create index subtasks_order_idx
on subtasks(orderid,shipid);
exit;
