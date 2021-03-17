create or replace view custrategroupview
(
CUSTID,                       
RATEGROUP,                    
DESCR,                        
ABBREV,                       
STATUS,                       
LASTUSER,                     
LASTUPDATE,                   
statusabbrev
)
as
select
CUSTID,                       
RATEGROUP,                    
custrategroup.DESCR,                        
custrategroup.ABBREV,                       
STATUS,                       
custrategroup.LASTUSER,                     
custrategroup.LASTUPDATE,                   
ratestatus.abbrev
from custrategroup, ratestatus
where status = code (+);

comment on table custrategroupview is '$Id$';

exit;
