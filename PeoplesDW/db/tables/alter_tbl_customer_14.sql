--
-- $Id$
--
alter table customer add (
    tms_planned_shipments_format varchar2(255),
    tms_item_format varchar2(255),
    tms_orders_to_plan_format varchar2(255),
    tms_status_changes_format varchar2(255),
    tms_actual_ship_format varchar2(255)
);

exit;

