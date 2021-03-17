shutdown immediate;
startup mount;
alter database noarchivelog;
alter database open;

archive log list;

/* do NOT issue this command -- don't want the change to be permanent
create pfile from spfile;
*/
