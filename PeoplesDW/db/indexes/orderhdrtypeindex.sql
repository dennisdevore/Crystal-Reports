--
-- $Id$
--
drop index orderhdr_type_idx;

create index orderhdr_type_idx
    on orderhdr (ordertype, orderid, shipid);

exit;
