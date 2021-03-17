--
-- $Id$
--
BEGIN
dbms_aqadm.create_queue_table(
    queue_table         => 'qt_rp_&&1',
    sort_list           =>'PRIORITY,ENQ_TIME',
    queue_payload_type  => 'QMSG');

dbms_aqadm.create_queue(
    queue_table         => 'qt_rp_&&1',
    queue_name          => '&&1');

dbms_aqadm.start_queue(
    queue_name          => '&&1');

END;
/
exit;
