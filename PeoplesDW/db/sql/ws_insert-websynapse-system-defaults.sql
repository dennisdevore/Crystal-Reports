-- Configuration below reflects WebSynapse in 2.7
--
-- Apache Running on: 10.5.12.13
-- CR Service Running on: 10.5.12.11 

delete from systemdefaults where defaultid like 'WEBSYNAPSE%';

insert into systemdefaults (defaultid, defaultvalue, lastuser, lastupdate)
values ('WEBSYNAPSERPTPATH', 'C:\Reports', 'SYNAPSE', sysdate);

insert into systemdefaults (defaultid, defaultvalue, lastuser, lastupdate)
values ('WEBSYNAPSELOGPATH', 'C:\CRService\prod\Logs', 'SYNAPSE', sysdate);

insert into systemdefaults (defaultid, defaultvalue, lastuser, lastupdate)
values ('WEBSYNAPSERPTDEST', 'C:\Temp\', 'SYNAPSE', sysdate);

insert into systemdefaults (defaultid, defaultvalue, lastuser, lastupdate)
values ('WEBSYNAPSERPTDESTSRVR', '/var/www/html/reports/', 'SYNAPSE', sysdate);

insert into systemdefaults (defaultid, defaultvalue, lastuser, lastupdate)
values ('WEBSYNAPSERPTDESTWEB', 'http://10.5.12.13/reports/', 'SYNAPSE', sysdate);

insert into systemdefaults (defaultid, defaultvalue, lastuser, lastupdate)
values ('WEBSYNAPSEHELPURL', 'http://10.5.12.13/websynapse-help-html-links.html', 'SYNAPSE', sysdate);

insert into systemdefaults (defaultid, defaultvalue, lastuser, lastupdate)
values ('WEBSYNAPSETIMEOUTMINS', '30', 'SYNAPSE', sysdate);

insert into systemdefaults (defaultid, defaultvalue, lastuser, lastupdate)
values ('WEBSYNAPSELOGUSERACTIVITY', 'Y', 'SYNAPSE', sysdate);

insert into systemdefaults (defaultid, defaultvalue, lastuser, lastupdate)
values ('WEBSYNAPSEPAGESIZE', '100', 'SYNAPSE', sysdate);

insert into systemdefaults (defaultid, defaultvalue, lastuser, lastupdate)
values ('WEBSYNAPSEALLOWENTRYGTALLOCABLE', 'Y', 'SYNAPSE', sysdate);

insert into systemdefaults (defaultid, defaultvalue, lastuser, lastupdate)
values ('WEBSYNAPSEREMOVEFROMHOLD', 'N', 'SYNAPSE', sysdate);

insert into systemdefaults (defaultid, defaultvalue, lastuser, lastupdate)
values ('WEBSYNAPSEMASSENTRYALLOWED', 'N', 'SYNAPSE', sysdate);

-- WebSynapse Validation for zoe.validate_order
delete from ordervalidationerrors where code = 500;
insert into ordervalidationerrors (code, descr, abbrev, dtlupdate, lastuser, lastupdate)
values (500, 'WebSynapse In-Process Order', 'WS InProcess', 'Y', 'SUP', sysdate);

commit;

exit;


