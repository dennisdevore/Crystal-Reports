--
-- $Id: add_invemailsubject.sql 8472 2015-02-17 12:16:22Z ayuan $
--
insert into systemdefaults(defaultid,defaultvalue,lastuser,lastupdate) 
values ('INVEMAILSUBJECT','Invoice# %MASTINV%','SYNAPSE',sysdate);
commit;
exit;