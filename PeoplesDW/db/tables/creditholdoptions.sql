-- $Id:$

create table creditholdoptions
  (code	 varchar2(12) not null,
   descr varchar2(32) not null,
   abbrev varchar2(12) not null,
   dtlupdate varchar2(1),
   lastuser varchar2(12),
   lastupdate date);

insert into creditholdoptions (code, descr, abbrev, dtlupdate, lastuser, lastupdate)
values('Y', 'Yes', 'Yes', 'N', 'SUP',sysdate);
insert into creditholdoptions (code, descr, abbrev, dtlupdate, lastuser, lastupdate)
values('N', 'No', 'No', 'N', 'SUP',sysdate);
insert into creditholdoptions (code, descr, abbrev, dtlupdate, lastuser, lastupdate)
values('W', 'Warn', 'Warn', 'N', 'SUP',sysdate);

insert into tabledefs values('CreditHoldOptions','Y','Y','>A;0;_','SYNAPSE',sysdate);                                                                                                      
commit;

exit;
