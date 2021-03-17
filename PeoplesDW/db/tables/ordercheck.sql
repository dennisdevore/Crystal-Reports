--
-- $Id$
--
drop table ordercheck;

create table ordercheck
(
   facility    varchar2(3),
   location    varchar2(10),
   orderid     number(7),
   shipid      number(2),
   lpid        varchar2(15),
   lpitem varchar2(50),
   lplot       varchar2(30),
   lpqty       number(7),
   lpuom       varchar2(4),
   entlpid     varchar2(15),
   entitem varchar2(50),
   entlot      varchar2(30),
   entqty      number(7),
   entuom      varchar2(4),
   lastuser    varchar2(12),
   lastupdate  date,
	complete    varchar2(1)
);

exit;
