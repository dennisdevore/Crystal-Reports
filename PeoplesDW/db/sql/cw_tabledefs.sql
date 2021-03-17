--
-- $Id$
--
insert into tabledefs(tableid, hdrupdate, dtlupdate, codemask,
    lastuser, lastupdate)
values ('LateShipReasons','N','Y','>Aa;0;_','SUP',sysdate);
insert into tabledefs(tableid, hdrupdate, dtlupdate, codemask,
    lastuser, lastupdate)
values ('ShipShortReasons','N','Y','>Aa;0;_','SUP',sysdate);

commit;
exit;
