--
-- $Id$
--
--drop table qcrequest;

create table qcrequest(
   id                number(7) not null,
   facility          varchar2(3) not null,
   custid            varchar2(10) not null,
   status            varchar2(2),
   item varchar2(50),
   lotnumber         varchar2(30),
   supplier          varchar2(10),
   type              varchar2(4),
   orderid           number(7),
   shipid            number(2),
   begindate         date,
   enddate           date,
   sampletype        varchar2(4),
   samplesize        number(7),
   sampleuom         varchar2(4),
   passpercent       number(3),
   inspectrouting    varchar2(3),   -- RF, CRT
   instructions      long,
   lastuser          varchar2(12),
   lastupdate        date
);

create unique index pk_qcrequest
  on qcrequest(id);

-- exit;


