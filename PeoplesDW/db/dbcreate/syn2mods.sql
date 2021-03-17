alter profile default limit
  failed_login_attempts unlimited
  password_life_time unlimited;
-- get rid of deprecated parms
alter system reset commit_write;
alter system reset sec_case_sensitive_logon;
-- end of deprecated parms
alter system set deferred_segment_creation=false scope=both;
alter system set aq_tm_processes=1 scope=spfile;
alter system set db_cache_size=33554432 scope=spfile;
alter system set fast_start_mttr_target=300 scope=spfile;
alter system set java_pool_size=83886080 scope=spfile;
alter system set large_pool_size=16777216 scope=spfile;
alter system set sort_area_size=524288 scope=spfile;
alter system set undo_retention=10800 scope=spfile;
alter system set streams_pool_size=50331648 scope=spfile;
alter system set session_max_open_files=20 scope=spfile;
alter system set cursor_sharing='FORCE' scope=spfile;
alter system set optimizer_index_caching=50 scope=spfile;
alter system set optimizer_index_cost_adj=20 scope=spfile;
alter system set optimizer_mode='ALL_ROWS' scope=spfile;
alter system set open_cursors=7500 scope=spfile;
alter system set filesystemio_options = setall scope=spfile;
alter system set disk_asynch_io = true scope=spfile;
--alter system set log_buffer=2879488 scope=spfile; (12c default is higher)
alter system set commit_logging = 'IMMEDIATE' scope=both;
alter system set commit_wait = 'NOWAIT' scope=both;
alter system set db_recovery_file_dest_size=50G scope=spfile;
alter system set session_cached_cursors = 200 scope=spfile;
alter system set recyclebin = off deferred;

exec DBMS_STATS.SET_PARAM('ESTIMATE_PERCENT',100);

alter system set processes=1500 scope=spfile;
alter system set sessions=500 scope=spfile;
alter system set transactions=550 scope=spfile;
create pfile from spfile;
shutdown immediate;
startup;
exit;
