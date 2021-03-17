--
-- $Id$
--
create table invoiceorders
(
    invoice     number(8) not null,
    orderid     number(7),
    shipid      number(2),
    loadno      number(7)
);

exit;
