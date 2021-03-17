--
-- $Id$
--
declare
errno integer;
job_name varchar2(200) := 'ZJOB.RUN_PECAS;';
CURSOR C_JOB
IS
SELECT *
  FROM user_jobs
 WHERE what = job_name;

JB user_jobs%rowtype;

begin

    JB := null;

    OPEN C_JOB;
    FETCH C_JOB into JB;
    CLOSE C_JOB;

    if JB.job is not null then
        dbms_job.remove(JB.job);
        errno := zqm.send('pecas_in','STOP');
    end if;
    commit;

end;
/
