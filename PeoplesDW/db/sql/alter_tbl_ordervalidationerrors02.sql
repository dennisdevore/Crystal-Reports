--
-- $Id: alter_tbl_ordervalidationerrors02.sql
--
insert into ordervalidationerrors(code,descr,abbrev,dtlupdate,
        lastuser,lastupdate)
values ('140','One value allowed (Qty,Lbs,Kgs)','OneOrderVal','Y','SYNAPSE',sysdate);
insert into ordervalidationerrors(code,descr,abbrev,dtlupdate,
        lastuser,lastupdate)
values ('141','No order value (Qty,Lbs,Kgs)','NoOrderVal','Y','SYNAPSE',sysdate);

insert into ordervalidationerrors(code,descr,abbrev,dtlupdate,
        lastuser,lastupdate)
values ('145','No Order By Weight - Order Type','NoOBWTye','Y','SYNAPSE',sysdate);

insert into ordervalidationerrors(code,descr,abbrev,dtlupdate,
        lastuser,lastupdate)
values ('146','No Order By Weight for Kits','NoOBWKit','Y','SYNAPSE',sysdate);

insert into ordervalidationerrors(code,descr,abbrev,dtlupdate,
        lastuser,lastupdate)
values ('147','No Order By Weight for LineNo','NoOBWLine','Y','SYNAPSE',sysdate);

exit;
