--
-- $Id$
--
alter table asncartondtl add
(
   outbound_orderid  number(9),
   outbound_shipid   number(7)
);

exit;
