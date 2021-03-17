create or replace view loadstopshipcmtview
(loadstopshiprowid
,comment1
)
as
select
loadstopship.rowid,                     
loadstopship.comment1
from loadstopship;
comment on table loadstopshipcmtview is '$Id';

create or replace view loadstopshipcmtviewA
(
    loadstopshiprowid,
    comment1
)
as
select
   loadstopship.rowid,
   zbol.loadstopshipcmt(loadstopship.rowid)
from
    loadstopship;
comment on table loadstopshipcmtviewA is '$Id';
    
exit;
