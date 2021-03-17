--
-- $Id: invoiceterms.sql 2441 2007-12-28 18:04:19Z ed $
--
create table invoiceterms (
    code              varchar2(12) not null,
    descr             varchar2(32) not null,
    abbrev            varchar2(12) not null,
    dtlupdate         varchar2(1),
    lastuser          varchar2(12),
    lastupdate        date
);

alter table invoiceterms add (
  constraint pk_invoiceterms
  primary key (code)
);

insert into tabledefs (codemask , tableid, hdrupdate, dtlupdate, lastuser, lastupdate)
values( '>Aaaa;0;_', 'InvoiceTerms', 'Y','Y', 'SYNAPSE', SYSDATE);

insert into invoiceterms values (1, 'Net 1','Net1','1','SYNAPSE',sysdate);
insert into invoiceterms values (2, 'NET 1 NO FIN CHG','NET1NOFINCHG','1','SYNAPSE',sysdate);
insert into invoiceterms values (3, 'NET 7 NO FIN CHG','NET7NOFINCHG','1','SYNAPSE',sysdate);
insert into invoiceterms values (4, 'Net 30','Net30','1','SYNAPSE',sysdate);

exit;
