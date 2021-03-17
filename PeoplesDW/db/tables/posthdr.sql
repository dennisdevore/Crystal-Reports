--
-- $Id$
--
drop table posthdr;

create table posthdr
(
 type           char(1),        -- '1' for invoice
 invoice        number(8) not null,
 poststatus     char(1),
 description    varchar2(30),
 invdate        date not null,
 postdate       date,
 transmitdate   date,
 custid         varchar2(10) not null,
 amount         number,
 lastuser       varchar2(12),
 lastupdate     date
);


