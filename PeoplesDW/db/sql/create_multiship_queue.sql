--
-- $Id: create_multiship_queue.sql 1 2005-05-26 12:20:03Z ed $
--
BEGIN
dbms_aqadm.create_queue_table(
    Queue_table         => 'qt_rp_multiship',
    sort_list           =>'PRIORITY,ENQ_TIME',
    queue_payload_type  => 'QMSG');

dbms_aqadm.create_queue(
    queue_table         => 'qt_rp_multiship',
    queue_name          => 'multiship');

dbms_aqadm.start_queue(
    queue_name          => 'multiship');

END;
/
exit;
