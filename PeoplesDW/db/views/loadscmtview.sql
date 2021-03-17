create or replace view loadscmtview
(loadsrowid
,comment1
)
as
select
loads.rowid,                     
loads.comment1
from loads;
comment on table loadscmtview is '$Id';

create or replace view loadscmtviewA
(
    loadsrowid,
    comment1
)
as
select
   loads.rowid,
   zbol.loadscmt(loads.rowid)
from
    loads;
comment on table loadscmtviewA is '$Id';

exit;
