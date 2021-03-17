--
-- $Id$
--
create table lastfreightbill_all ( 
  code        varchar2 (12)  not null, 
  descr       varchar2 (32)  not null, 
  abbrev      varchar2 (12)  not null, 
  dtlupdate   varchar2 (1), 
  lastuser    varchar2 (12), 
  lastupdate  date);


create unique index lastfreightbill_all_idx on 
  lastfreightbill_all(code) ; 
  
insert into tabledefs (tableid,hdrupdate,dtlupdate,codemask)
values('LastFreightBill_ALL','y','y','>aaaaaaaa;0;_');

insert into lastfreightbill_all ( code,descr,abbrev) values ('ALLALL','Last Freight Bill Export','010101000000');

exit;
