--
-- $Id$
--
alter table shippingplate add
(
    shippingcost        number(10,2),
    carriercodeused     varchar2(10),
    satdeliveryused     varchar2(1)
);

exit;