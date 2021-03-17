--insert into systemdefaults (defaultid, defaultvalue, lastuser, lastupdate)
--values ('WEBSYNAPSEHOST-TEMP', 'localhost', 'SYNAPSE', sysdate);

insert into systemdefaults (defaultid, defaultvalue, lastuser, lastupdate)
values ('WEBSYNAPSEHOST-TEMP', '10.5.12.13', 'SYNAPSE', sysdate);

commit;


