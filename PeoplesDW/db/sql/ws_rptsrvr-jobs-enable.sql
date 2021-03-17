BEGIN
DBMS_SCHEDULER.ENABLE('alps.report_parm_handler');
DBMS_SCHEDULER.ENABLE('alps.report_req_handler');

--DBMS_SCHEDULER.START_JOB('alps.report_parm_handler');
--DBMS_SCHEDULER.START_JOB('alps.report_req_handler');

END;
/


