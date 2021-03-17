--
-- $Id$
--
alter table userhistory add
(
   orderid     number(7),
   shipid      number(2),
   location    varchar2(10),
   lpid        varchar2(15),
   item varchar2(50),
   uom         varchar2(4)
);
exit;
