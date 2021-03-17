--
-- $Id:  $
--
alter table facility add
(
    gross_stg_cost_per_sqft   number(6,2),
    space_utilization_pct     number(4,0),
    dock_mgmt_error_minutes   number(4,0),
    dock_mgmt_warn_minutes    number(4,0)
);

exit;
