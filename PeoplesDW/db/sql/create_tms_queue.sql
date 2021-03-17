--
-- $Id$
--
BEGIN
dbms_aqadm.create_queue_table(
    queue_table         => 'qt_rp_tms',
    sort_list           =>'PRIORITY,ENQ_TIME',
    queue_payload_type  => 'QMSG');

dbms_aqadm.create_queue(
    queue_table         => 'qt_rp_tms',
    queue_name          => 'tms');

dbms_aqadm.start_queue(
    queue_name          => 'tms');

END;
/
exit;
