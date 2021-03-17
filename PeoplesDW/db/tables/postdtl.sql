--
-- $Id$
--
drop table postdtl;

create table postdtl
(
 invoice        number(8) not null,
 account        varchar2(75) not null,
 debit          number,
 credit         number,
 reference      varchar2(30)
);

create index  postdtl_idx on
       postdtl(
             invoice,
             account);
