BEGIN
DBMS_SCHEDULER.CREATE_JOB (
   job_name           =>  'alps.report_parm_handler',
   job_type           =>  'STORED_PROCEDURE',
   job_action         =>  'ALPS.WS_QMGMT.dequeue_rptparms',
   repeat_interval    =>  'freq=secondly;interval=5',
   enabled            =>  TRUE,
   comments           =>  'Temp Report Parm Handler');
END;
/

BEGIN
DBMS_SCHEDULER.CREATE_JOB (
   job_name           =>  'alps.report_req_handler',
   job_type           =>  'STORED_PROCEDURE',
   job_action         =>  'ALPS.WS_QMGMT.dequeue_rptreq',
   repeat_interval    =>  'freq=secondly;interval=5',
   enabled            =>  TRUE,
   comments           =>  'Temp Report Request Handler');
END;
/


