--
-- $Id: create_putaway_queue.sql 1 2005-05-26 12:20:03Z ed $
--
BEGIN
dbms_aqadm.create_queue_table(
    queue_table         => 'qt_rp_putaway',
    sort_list           =>'PRIORITY,ENQ_TIME',
    queue_payload_type  => 'QMSG');

dbms_aqadm.create_queue(
    queue_table         => 'qt_rp_putaway',
    queue_name          => 'putaway');

dbms_aqadm.start_queue(
    queue_name          => 'putaway');

END;
/
exit;
