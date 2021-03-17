--
-- $Id: start_replenish_queue.sql 1 2005-05-26 12:20:03Z ed $
--
exec dbms_aqadm.start_queue(queue_name => 'replenish');
exit;
