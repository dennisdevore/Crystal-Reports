--
-- $Id$
--
drop table invsession;

create table invsession
(
userid      varchar2(12) not null,
facility    varchar2(3),
custid      varchar2(10),
csr         varchar2(10),
invdate     date,
reference   number(8),
invtype     varchar2(1),
orderid     number(7),
onlydueinv  varchar2(1)
);

create unique index pk_invoicesession on invsession(userid);

exit;
