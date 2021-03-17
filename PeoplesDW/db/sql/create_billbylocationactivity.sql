--
-- $Id$
--
insert into BillingMethod values('LUCT','LOCATION USAGE COUNT','LOC USE CNT','N','SUP',sysdate);                                                                                                    

create table BillByLocationActivity( code varchar2(3) not null, descr varchar2(32) not null, abbrev varchar2(12) not null, dtlupdate varchar2(1), lastuser varchar2(12), lastupdate date);            

create unique index BillByLocationActivity_idx  on BillByLocationActivity(code);                                                                                                                      
insert into tabledefs values('BillByLocationActivity','Y','Y','>Aaa;0;_','SUP',sysdate);                                                                                                      
commit;

exit;


