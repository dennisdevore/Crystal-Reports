--
-- $Id$
--
alter table customer_aux add
(
no_full_shippingplates char(1) default 'N'
);

exit;
