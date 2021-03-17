create or replace view custworkorderinstructionsview
(
   seq,
   subseq,
   parent,
   action,
   notes,
   title,
   qty,
   component,
   status,
   completedqty,
   destfacility,
   destlocation,
   destloctype
)
as
select
   WIN.seq,
   WIN.subseq,
   WIN.parent,
   WIN.action,
   WIN.notes,
   WIN.title,
   WIN.qty,
   WIN.component,
   WIN.status,
   WIN.completedqty,
   WDS.facility,
   WDS.location,
   WDS.loctype
from custworkorderinstructions WIN, custworkorderdestinations WDS
where WIN.seq = WDS.seq (+)
  and WIN.subseq = WDS.subseq (+);

comment on table custworkorderinstructionsview is '$Id';

exit;
