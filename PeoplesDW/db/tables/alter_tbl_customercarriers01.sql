--
-- $Id$
--
drop index custshipwghtzip;

alter table customercarriers
  modify (shiptype null);

alter table customercarriers add
(
  assigned_ship_type varchar2(1),
  servicecode        varchar2(4)
);

create unique index custshipwghtzip on customercarriers
(custid, shiptype, assigned_ship_type, fromweight, begzip);
