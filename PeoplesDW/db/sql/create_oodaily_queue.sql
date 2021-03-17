--
-- $Id$
--
BEGIN
dbms_aqadm.create_queue_table(
    Queue_table         => 'qt_rp_oodaily',
    sort_list           =>'PRIORITY,ENQ_TIME',
    queue_payload_type  => 'QMSG');

dbms_aqadm.create_queue(
    queue_table         => 'qt_rp_oodaily',
    queue_name          => 'oodaily');

dbms_aqadm.start_queue(
    queue_name          => 'oodaily');

END;
/
exit;
