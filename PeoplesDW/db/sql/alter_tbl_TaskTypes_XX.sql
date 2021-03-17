--
-- $Id$
--
insert into TaskTypes values('SP','Ship To Production','Production','N','SUP',sysdate);
insert into TaskTypes values('BP','Batch Pick','Batch Pick','N','SUP',sysdate);
insert into TaskTypes values('CC','Cycle Count','Cycle Count','N','SUP',sysdate);
insert into TaskTypes values('MV','Move Task','Move','N','SUP',sysdate);
insert into TaskTypes values('OP','Order Pick','Order Pick','N','SUP',sysdate);
insert into TaskTypes values('PA','Putaway Task','Putaway','N','SUP',sysdate);
insert into TaskTypes values('PI','Physical Inventory','PhyInventory','N','SUP',sysdate);
insert into TaskTypes values('PK','Pick Task','Pick','N','SUP',sysdate);
insert into TaskTypes values('RP','Replenish Pick','Replenish','N','SUP',sysdate);
insert into TaskTypes values('SO','Sortation Pick','Sortation','N','SUP',sysdate);

exit;
