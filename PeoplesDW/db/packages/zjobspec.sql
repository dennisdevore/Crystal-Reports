--
-- $Id$
--
create or replace PACKAGE alps.zjob
IS

daily_jobs_name varchar2(20) := 'ZJOB.DAILY_JOBS;';
alert_job_name varchar2(200) := 'ZALT.ALERT_PROCESS;';

----------------------------------------------------------------------
--
-- start_wave_plan
--
----------------------------------------------------------------------
PROCEDURE start_wave_plan
(
    in_facility IN varchar2,
    in_custid   IN varchar2,
    in_wave_prefix IN varchar2,
    out_msg     OUT varchar2
);

----------------------------------------------------------------------
--
-- start_daily_billing
--
----------------------------------------------------------------------
PROCEDURE start_daily_billing;

----------------------------------------------------------------------
--
-- stop_daily_billing
--
----------------------------------------------------------------------
PROCEDURE stop_daily_billing;

----------------------------------------------------------------------
--
-- set_daily_billing
--
----------------------------------------------------------------------
PROCEDURE set_daily_billing;

----------------------------------------------------------------------
--
-- start_alert_process
--
----------------------------------------------------------------------
PROCEDURE start_alert_process;

----------------------------------------------------------------------
--
-- stop_alert_process
--
----------------------------------------------------------------------
PROCEDURE stop_alert_process;

----------------------------------------------------------------------
--
-- start_daily_jobs
--
----------------------------------------------------------------------
PROCEDURE start_daily_jobs;

----------------------------------------------------------------------
--
-- stop_daily_jobs
--
----------------------------------------------------------------------
PROCEDURE stop_daily_jobs;

----------------------------------------------------------------------
--
-- daily_jobs
--
----------------------------------------------------------------------
PROCEDURE daily_jobs;

PROCEDURE start_pi_updates
(
    in_id       IN number,
    in_type     IN varchar2,
    in_user     IN varchar2,
    out_msg     OUT varchar2
);

PROCEDURE start_late_trailer_check;

PROCEDURE stop_late_trailer_check;

PROCEDURE custitem_import_changes_purge; -- daily

PROCEDURE import204_purge; -- daily

PROCEDURE peopleskhexpiration(in_custid varchar2);

END zjob;
/
exit;
