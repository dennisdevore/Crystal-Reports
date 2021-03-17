CREATE OR REPLACE VIEW USERFACILITYVIEW
(
FACILITY,
NAME,
NAMEID )
AS
select
facility.FACILITY,
facility.NAME,
userfacility.NAMEID
from facility, userfacility
where facility.FACILITY = userfacility.FACILITY (+);

comment on table USERFACILITYVIEW is '$Id$';

exit;
