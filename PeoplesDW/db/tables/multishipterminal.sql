--
-- $Id$
--
drop table multishipterminal;

create table multishipterminal
(
    facility        varchar2(3) not null,
    termid          varchar2(4) not null,
    descr           varchar2(200),
    packprinter     varchar2(255),
    lastuser        varchar2(12),
    lastupdate      date
);

create unique index pk_multishipterminal 
       on multishipterminal(facility, termid);

exit;

