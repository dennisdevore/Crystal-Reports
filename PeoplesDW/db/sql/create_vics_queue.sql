--
-- $Id$
--
BEGIN
dbms_aqadm.create_queue_table(
    Queue_table         => 'qt_rp_vics',
    sort_list           =>'PRIORITY,ENQ_TIME',
    queue_payload_type  => 'QMSG');

dbms_aqadm.create_queue(
    queue_table         => 'qt_rp_vics',
    queue_name          => 'vics');

dbms_aqadm.start_queue(
    queue_name          => 'vics');

END;
/
exit;
