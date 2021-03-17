delete from loads
 where loadno is null;
delete from loadstop
 where loadno is null;
delete from loadstopship
 where loadno is null;
delete from loadstop
 where stopno is null;
delete from loadstopship
 where stopno is null;
delete from loadstopship
 where shipno is null;
alter table loads
modify loadno not null;
alter table loadstop
modify loadno not null;
alter table loadstopship
modify loadno not null;
alter table loadstop
modify stopno not null;
alter table loadstopship
modify stopno not null;
alter table loadstopship
modify shipno not null;
alter table loads drop constraint uk_loads;
alter table loadstop drop constraint uk_loadstop;
alter table loadstopship drop constraint uk_loadstopship;
exit;
