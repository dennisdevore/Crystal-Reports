--
-- $Id$
--
create table ptinvoicenames
(code varchar2(12) not null
,descr varchar2(32) not null
,abbrev varchar2(12) not null
,dtlupdate varchar2(1)
,lastuser varchar2(12)
,lastupdate date
);

create unique index ptinvoicenames_unique
   on ptinvoicenames(code);

insert into ptinvoicenames values('A','Outbound Access','OA','Y','SYSTEM',sysdate);
insert into ptinvoicenames values('C','Credit Memo','CM','Y','SYSTEM',sysdate);
insert into ptinvoicenames values('M','Misc','M','Y','SYSTEM',sysdate);
insert into ptinvoicenames values('R','Whse Rcpt','R','Y','SYSTEM',sysdate);
insert into ptinvoicenames values('S','Renewal','RE','Y','SYSTEM',sysdate);

insert into tabledefs values('PTInvoiceNames','Y','Y','>A;0;_','SYSTEM',sysdate);

exit;
