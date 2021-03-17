--
-- $Id$
--
drop table invoicehdr;

create table invoicehdr
(
 invoice        number(8) not null,
 invdate        date not null,
 invtype        varchar2(1) not null, -- Receipt,Storage,Assessorial,Misc
 invstatus      varchar2(1) not null, -- Entered, Reviewed, Posted, Printed
 custid         varchar2(10) not null,
 facility       varchar2(3) not null,
 postdate       date,
 printdate      date,
 lastuser       varchar2(12),
 lastupdate     date
);


create unique index invoicehdr_idx on
       invoicehdr(invoice);


