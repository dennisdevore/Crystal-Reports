BEGIN
dbms_aqadm.create_queue_table(
    queue_table         => 'qt_rp_rptload',
    sort_list           =>'PRIORITY,ENQ_TIME',
    queue_payload_type  => 'QMSG');

dbms_aqadm.create_queue(
    queue_table         => 'qt_rp_rptload',
    queue_name          => 'rptload');

dbms_aqadm.start_queue(
    queue_name          => 'rptload');

END;
/
exit;
