create or replace view putawayprofview
(
FACILITY,                     
PROFID,                       
DESCR,                        
ABBREV,                       
DISPOSITION,                  
LASTUSER,                     
LASTUPDATE,                                     
dispositionabbrev
)
as
select
FACILITY,                     
PROFID,                       
putawayprof.DESCR,                        
putawayprof.ABBREV,                       
DISPOSITION,                  
putawayprof.LASTUSER,                     
putawayprof.LASTUPDATE,                   
putawayunitdispositions.abbrev
from putawayprof, putawayunitdispositions
where disposition = code (+);

comment on table putawayprofview is '$Id$';

exit;
