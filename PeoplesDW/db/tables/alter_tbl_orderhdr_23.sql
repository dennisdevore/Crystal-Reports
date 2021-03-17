--
-- $Id$
--
alter table orderhdr add (
    tms_status varchar2(1),
    tms_status_update   date,
    tms_shipment_id     varchar2(20),
    tms_release_id      varchar2(20)
);

exit;

