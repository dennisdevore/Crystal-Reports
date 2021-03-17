--
-- $Id$
--
alter table asofinventory add(
   orderid  number(9),
   shipid   number(2),
   lpid     varchar2(15)
);

exit;
