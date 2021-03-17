create or replace view platehistoryview
(
LPID,                         
WHENOCCURRED,                 
ITEM,                         
CUSTID,                       
FACILITY,                     
LOCATION,                     
STATUS,                       
HOLDREASON,                   
UNITOFMEASURE,                
QUANTITY,                     
TYPE,                         
SERIALNUMBER,                 
LOTNUMBER,                    
MANUFACTUREDATE,              
EXPIRATIONDATE,               
EXPIRYACTION,                 
PO,                           
RECMETHOD,                    
CONDITION,                    
LASTOPERATOR,                 
LASTTASK,                     
COUNTRYOF,                    
PARENTLPID,                   
USERITEM1,                    
USERITEM2,                    
USERITEM3,                    
DISPOSITION,                  
LASTUSER,                     
LASTUPDATE,                   
INVSTATUS,                    
QTYENTERED,                   
ITEMENTERED,                  
UOMENTERED,                   
INVENTORYCLASS,
platestatusabbrev,               
unitofmeasureabbrev,
recmethodabbrev,
invstatusabbrev,
inventoryclassabbrev,
platetypeabbrev,
conditionabbrev,
tasktypeabbrev,
expiryactionabbrev,
holdreasonabbrev,
adjreason,
adjreasonabbrev,
weight,
weight_kgs,
anvdate,
qtytasked,
length,
width,
height,
pallet_weight
)
as
select
LPID,                         
WHENOCCURRED,                 
ITEM,                         
CUSTID,                       
FACILITY,                     
LOCATION,                     
STATUS,                       
HOLDREASON,                   
UNITOFMEASURE,                
QUANTITY,                     
TYPE,                         
SERIALNUMBER,                 
LOTNUMBER,                    
MANUFACTUREDATE,              
EXPIRATIONDATE,               
EXPIRYACTION,                 
PO,                           
RECMETHOD,                    
CONDITION,                    
LASTOPERATOR,                 
LASTTASK,                     
COUNTRYOF,                    
PARENTLPID,                   
USERITEM1,                    
USERITEM2,                    
USERITEM3,
DISPOSITION,                  
LASTUSER,                     
LASTUPDATE,                   
INVSTATUS,                    
QTYENTERED,                   
ITEMENTERED,                  
UOMENTERED,
INVENTORYCLASS,
substr(zlp.platestatus_abbrev(status),1,12),
substr(zit.uom_abbrev(unitofmeasure),1,12),
substr(zlp.handlingtype_abbrev(recmethod),1,12),
substr(zlp.invstatus_abbrev(invstatus),1,12),
substr(zlp.inventoryclass_abbrev(inventoryclass),1,12),
substr(zlp.platetype_abbrev(type),1,12),
substr(zlp.condition_abbrev(condition),1,12),
substr(zlp.tasktype_abbrev(lasttask),1,12),
substr(zlp.expiryaction_abbrev(expiryaction),1,12),
substr(zlp.holdreason_abbrev(holdreason),1,12),
adjreason,
substr(zlp.adjreason_abbrev(holdreason),1,12),
weight,
zwt.from_lbs_to_kgs(custid,weight),
anvdate,
qtytasked,
length,
width,
height,
pallet_weight
from platehistory;

comment on table platehistoryview is '$Id$';

exit;