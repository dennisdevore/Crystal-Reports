--
-- $Id: create_license_queue.sql 1 2005-05-26 12:20:03Z ed $
--
BEGIN
dbms_aqadm.create_queue_table(
    Queue_table         => 'qt_rp_license',
    sort_list           =>'PRIORITY,ENQ_TIME',
    queue_payload_type  => 'QMSG');

dbms_aqadm.create_queue(
    queue_table         => 'qt_rp_license',
    queue_name          => 'license');

dbms_aqadm.start_queue(
    queue_name          => 'license');

END;
/
exit;
