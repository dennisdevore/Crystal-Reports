--alter system set log_archive_max_processes=10 scope=spfile;
--alter system set db_recovery_file_dest_size=20G scope=spfile;
shutdown immediate;
startup mount;
alter database archivelog;
alter database open;

archive log list;

create pfile from spfile;


