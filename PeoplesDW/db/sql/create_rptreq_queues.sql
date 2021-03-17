BEGIN
dbms_aqadm.create_queue_table(
    queue_table         => 'qt_rp_rptparm',
    sort_list           =>'PRIORITY,ENQ_TIME',
    queue_payload_type  => 'QMSG');

dbms_aqadm.create_queue(
    queue_table         => 'qt_rp_rptparm',
    queue_name          => 'rptparm');

dbms_aqadm.start_queue(
    queue_name          => 'rptparm');

dbms_aqadm.create_queue_table(
    queue_table         => 'qt_rp_rptreq',
    sort_list           =>'PRIORITY,ENQ_TIME',
    queue_payload_type  => 'QMSG');

dbms_aqadm.create_queue(
    queue_table         => 'qt_rp_rptreq',
    queue_name          => 'rptreq');

dbms_aqadm.start_queue(
    queue_name          => 'rptreq');

END;
/
exit;
