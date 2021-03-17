--
-- $Id$
--
alter table asofinventorydtl add(
   orderid  number(9),
   shipid   number(2),
   lpid     varchar2(15)
);

exit;
