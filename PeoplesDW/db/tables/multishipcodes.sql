--
-- $Id$
--
drop table multishipcodes;

create table multishipcodes
(
    code            varchar2(4) not null,
    convcode        varchar2(4) not null,
    descr           varchar2(200),
    lastuser        varchar2(12),
    lastupdate      date
);

create unique index pk_multishipcodes
       on multishipcodes(code);

