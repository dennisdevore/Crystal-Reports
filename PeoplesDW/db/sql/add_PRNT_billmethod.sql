--
-- $Id: add_QTYM_billmethod.sql 1 2005-05-26 12:20:03Z ed $
--
insert into BillingMethod values('PRNT','PARENT PLATE','Parent Plate','N','SUP',sysdate);     

insert into activity (code, descr, abbrev, glacct, lastuser, lastupdate)
values ('0', 'Unknown', 'Unknown', 'N/A', 'SYNAPSE', sysdate);
                                                                                               
commit;

exit;
