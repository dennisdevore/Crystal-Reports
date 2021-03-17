create or replace view loadstopcmtview
(loadstoprowid
,comment1
)
as
select
loadstop.rowid,                     
loadstop.comment1
from loadstop;
comment on table loadstopcmtview is '$Id';

create or replace view loadstopcmtviewA
(
    loadstoprowid,
    comment1
)
as
select
   loadstop.rowid,
   zbol.loadstopcmt(loadstop.rowid)
from
    loadstop;
comment on table loadstopcmtviewA is '$Id';
exit;
