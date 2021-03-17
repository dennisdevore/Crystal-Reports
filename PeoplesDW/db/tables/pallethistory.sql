--
-- $Id$
--
drop table pallethistory cascade constraints;

create table pallethistory (
  custid      varchar2 (10)  not null,
  facility    varchar2 (3)  not null,
  pallettype  varchar2 (12)  not null,
  adjreason   varchar2 (12),
  loadno      number (7),
  lastuser    varchar2 (12)  not null,
  lastupdate  date          not null,
  carrier     varchar2 (4)  not null,
  comment1    varchar2 (80),
  orderid     number (7),
  shipid      number (2),
  inpallets   number (7),
  outpallets  number (7));

exit;
