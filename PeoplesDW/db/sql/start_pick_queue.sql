--
-- $Id: start_genpicks_queue.sql 1 2005-05-26 12:20:03Z ed $
--
Exec dbms_aqadm.start_queue(queue_name => 'pick');
exit;
