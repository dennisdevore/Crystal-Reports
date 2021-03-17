--
-- $Id$
--
alter table custconsignee add
(generate_order_confirmation char(1)
,generate_ship_notice char(1)
,generate_ship_advice char(1)
);
--exit;
