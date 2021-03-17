alter system set processes=1500 scope=spfile;
/* alter system set sessions=500 scope=spfile; sessions will be set by oracle based on processes */
alter system set transactions=550 scope=spfile;
create pfile from spfile;
/* instance must be bounced as these parms can't be changed dynamically
shutdown immediate;
startup;
*/

