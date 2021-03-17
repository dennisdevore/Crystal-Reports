--
-- $Id$
--
drop index consshipwghtzip;

alter table consigneecarriers
  modify (shiptype null);

alter table consigneecarriers add
(
  assigned_ship_type varchar2(1),
  servicecode        varchar2(4)
);

create unique index consshipwghtzip on consigneecarriers
(consignee, shiptype, assigned_ship_type, fromweight, begzip);
