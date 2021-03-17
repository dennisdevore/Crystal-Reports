--
-- $Id: create_pick_queue.sql 1 2005-05-26 12:20:03Z ed $
--
BEGIN
dbms_aqadm.create_queue_table(
    queue_table         => 'qt_rp_pick',
    sort_list           =>'PRIORITY,ENQ_TIME',
    queue_payload_type  => 'QMSG');

dbms_aqadm.create_queue(
    queue_table         => 'qt_rp_pick',
    queue_name          => 'pick');

dbms_aqadm.start_queue(
    queue_name          => 'pick');

END;
/
exit;
