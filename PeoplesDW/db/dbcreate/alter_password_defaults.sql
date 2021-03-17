ALTER PROFILE DEFAULT LIMIT
  FAILED_LOGIN_ATTEMPTS UNLIMITED
  PASSWORD_LIFE_TIME UNLIMITED;
alter system set sec_case_sensitive_logon=false scope=both;
exec DBMS_STATS.SET_PARAM('ESTIMATE_PERCENT',100);
create pfile from spfile;
shutdown immediate;
startup;
exit;
