create or replace view userheaderview
(
NAMEID,                       
USERNAME,                     
USERTYPE,                     
FACILITY,                     
GROUPID,                      
CHGFACILITY,                  
DESC1,                        
DESC2,                        
LASTUSER,                     
LASTUPDATE,                   
LBLPRINTER,                   
RPTPRINTER,                   
LASTLOCATION,                 
CUSTID,                       
EQUIPMENT,                    
OPMODE,                       
PICKMODE,                     
ALLCUSTS,                     
MBLPRINTER,                   
SBLPRINTER,                   
DEFAULTPRINTER,               
POCONFIRMPRINTER,             
BOLPRINTER,                   
usertypeabbrev,
userstatus,
userstatusabbrev
)
as
select
NAMEID,                       
USERNAME,                     
USERTYPE,                     
FACILITY,                     
GROUPID,                      
CHGFACILITY,                  
DESC1,                        
DESC2,                        
userheader.LASTUSER,                     
userheader.LASTUPDATE,                   
LBLPRINTER,                   
RPTPRINTER,                   
LASTLOCATION,                 
CUSTID,                       
EQUIPMENT,                    
OPMODE,                       
PICKMODE,                     
ALLCUSTS,                     
MBLPRINTER,                   
SBLPRINTER,                   
DEFAULTPRINTER,               
POCONFIRMPRINTER,             
BOLPRINTER,                   
decode(usertype,'G','Group','User'),
userstatus,
userstatus.abbrev
from userheader, userstatus
where userheader.userstatus = userstatus.code(+);

comment on table userheaderview is '$Id$';

exit;
