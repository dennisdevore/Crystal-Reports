create or replace view subtasksview
(TASKID,                       
TASKTYPE,                     
FACILITY,                     
FROMSECTION,                  
FROMLOC,                      
FROMPROFILE,                  
TOSECTION,                    
TOLOC,                        
TOPROFILE,                    
TOUSERID,                     
CUSTID,                       
ITEM,                         
LPID,                         
UOM,                          
QTY,
LOCSEQ,                       
LOADNO,                       
STOPNO,                       
SHIPNO,                       
ORDERID,
SHIPID,                       
ORDERITEM,                    
ORDERLOT,                     
PRIORITY,                     
PREVPRIORITY,
CURRUSERID,
LASTUSER,
LASTUPDATE,
tasktypeabbrev,
priorityabbrev,
wave,
pickuom,
pickuomabbrev,
pickqty,
picktotype,
picktotypeabbrev,
cartontype,
cartontypeabbrev,
pickingzone,
weight,
cube,
staffhrs,
fmtstaffhrs,
subtasksrowid,
shippinglpid,
shippingtype,
cartonseq,
cartongroup,
labeluom,
weight_kgs,
crush_factor,
uom_pick_seq
)
as
select
TASKID,
TASKTYPE,                     
FACILITY,                     
FROMSECTION,                  
FROMLOC,
FROMPROFILE,                  
TOSECTION,
TOLOC,                        
TOPROFILE,                    
TOUSERID,                     
CUSTID,                       
ITEM,                         
LPID,                         
UOM,                          
QTY,                          
LOCSEQ,
LOADNO,                       
STOPNO,
SHIPNO,
ORDERID,
SHIPID,
ORDERITEM,
ORDERLOT,
PRIORITY,
PREVPRIORITY,                 
CURRUSERID,
subtasks.LASTUSER,                     
subtasks.LASTUPDATE,
tasktypes.abbrev,
taskpriorities.abbrev,
wave,
pickuom,
unitsofmeasure.abbrev,
pickqty,
picktotype,
picktotypes.abbrev,
cartontype,
cartontypes.abbrev,
pickingzone,
weight,
cube,
staffhrs,
substr(zlb.formatted_staffhrs(staffhrs),1,12),
subtasks.rowid,
subtasks.shippinglpid,
subtasks.shippingtype,
subtasks.cartonseq,
subtasks.cartongroup,
subtasks.labeluom,
zwt.from_lbs_to_kgs(subtasks.custid,subtasks.weight),
ztk.task_crush_factor(subtasks.taskid,subtasks.tasktype,subtasks.custid,subtasks.item),
ztk.task_uom_pick_seq(subtasks.tasktype,subtasks.custid,subtasks.pickuom)
from subtasks, tasktypes, taskpriorities, unitsofmeasure,
  picktotypes, cartontypes
where subtasks.tasktype = tasktypes.code(+)
and subtasks.priority = taskpriorities.code(+)
and subtasks.pickuom = unitsofmeasure.code(+)
and subtasks.picktotype = picktotypes.code(+)
and subtasks.cartontype = cartontypes.code(+);

comment on table subtasksview is '$Id$';

exit;