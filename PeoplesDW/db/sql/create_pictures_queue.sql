--
-- $Id: create_work_queue.sql 1 2005-05-26 12:20:03Z ed $
--
BEGIN
dbms_aqadm.create_queue_table(
    queue_table         => 'qt_rp_pictures',
    sort_list           =>'PRIORITY,ENQ_TIME',
    queue_payload_type  => 'QMSG_BLOB');

dbms_aqadm.create_queue(
    queue_table         => 'qt_rp_pictures',
    queue_name          => 'pictures');

dbms_aqadm.start_queue(
    queue_name          => 'pictures');

END;
/
exit;
