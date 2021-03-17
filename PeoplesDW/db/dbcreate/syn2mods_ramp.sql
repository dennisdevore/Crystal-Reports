alter profile default limit
  failed_login_attempts unlimited
  password_life_time unlimited;
alter system set processes=2000 scope=spfile;
alter system set optimizer_mode='RULE' scope=spfile;
alter system set open_cursors=1000 scope=spfile;

create pfile from spfile;
shutdown immediate;
startup;
exit;
