BEGIN
DBMS_SCHEDULER.STOP_JOB('alps.report_parm_handler', force=>true);
DBMS_SCHEDULER.STOP_JOB('alps.report_req_handler', force=>true);

DBMS_SCHEDULER.DISABLE('alps.report_parm_handler');
DBMS_SCHEDULER.DISABLE('alps.report_req_handler');
END;
/


