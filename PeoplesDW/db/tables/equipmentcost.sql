--
-- $Id: equipmentcost.sql 1 2005-05-26 12:20:03Z sanjay $
--
create table equipmentcost
  (
    facility   varchar2(3 byte) not null
    ,equipid    varchar2(2 byte) not null
    ,hourlycost number(10,2)
    ,lastuser   varchar2(12 byte)
    ,lastupdate date
  );

alter table equipmentcost add
constraint pk_equipment_cost primary key(facility, equipid);

exit;