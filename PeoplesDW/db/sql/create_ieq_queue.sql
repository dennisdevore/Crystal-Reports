BEGIN
dbms_aqadm.create_queue_table(
    queue_table         => 'qt_rp_ieq',
    sort_list           =>'PRIORITY,ENQ_TIME',
    queue_payload_type  => 'QMSG');

dbms_aqadm.create_queue(
    queue_table         => 'qt_rp_ieq',
    queue_name          => 'ieq');

dbms_aqadm.start_queue(
    queue_name          => 'ieq');

END;
/
exit;
