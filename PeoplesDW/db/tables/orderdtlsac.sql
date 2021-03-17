--
-- $Id: orderdtlsac.sql 1 2005-05-26 12:20:03Z ed $
--
create table orderdtlsac
(
orderid     number(9) not null,
shipid      number(2) not null,
item varchar2(50) not null,
lotnumber   varchar2(30),
sac01       varchar2(255),
sac02       varchar2(255),
sac03       varchar2(255),
sac04       varchar2(255),
sac05       varchar2(255),
sac06       varchar2(255),
sac07       varchar2(255),
sac08       varchar2(255),
sac09       varchar2(255),
sac10       varchar2(255),
sac11       varchar2(255),
sac12       varchar2(255),
sac13       varchar2(255),
sac14       varchar2(255),
sac15       varchar2(255),
lastuser    varchar2(12),
lastupdate  date
);
create index orderdtlsac_idx on
   orderdtlsac(orderid,shipid,item,lotnumber);

exit;
