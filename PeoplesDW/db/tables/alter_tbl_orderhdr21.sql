--
-- $Id$
--
/* non-null indicates component order */
alter table orderhdr
add
(cancel_after date
,delivery_requested date
,requested_ship date
,ship_not_before date
,ship_no_later date
,cancel_if_not_delivered_by date
,do_not_deliver_after date
,do_not_deliver_before date
);
--exit;
