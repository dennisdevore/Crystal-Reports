create or replace view plateitemlotview
(
FACILITY,                     
CUSTID,                       
ITEM,                         
LOTNUMBER,                    
LOCATION,                     
invstatus,
inventoryclass,
UNITOFMEASURE,                
creationdate,
count,
QUANTITY,                    
weight
)
as
select
FACILITY,                     
CUSTID,                       
ITEM,                         
LOTNUMBER,                    
LOCATION,                     
invstatus,
inventoryclass,
UNITOFMEASURE,                
trunc(creationdate),
count(lpid),
sum(QUANTITY), 
sum(weight)
from plate
group by facility,custid,item,lotnumber,location,
invstatus,inventoryclass,trunc(creationdate),unitofmeasure;

comment on table plateitemlotview is '$Id$';

create or replace view plateitemlotsumview
(
FACILITY,                     
CUSTID,
customername,                       
ITEM,
itemdesc,                 
LOTNUMBER,                    
LOCATION,                     
invstatusabbrev,
inventoryclassabbrev,
UNITOFMEASURE,                
creationdate,
count,
QUANTITY,                    
weight,
stdweight
)
as
select
v.FACILITY,                     
v.CUSTID,
c.name,                       
v.ITEM,
d.descr,                         
v.LOTNUMBER,                    
v.LOCATION,                     
a.abbrev,
b.abbrev,
v.UNITOFMEASURE,                
v.creationdate,
v.count,
v.QUANTITY, 
v.weight,
d.weight
from plateitemlotview v, customer c, inventorystatus a,
inventoryclass b, custitem d
where v.custid = c.custid (+)
and v.invstatus = a.code (+)
and v.inventoryclass = b.code (+)
and v.custid = d.custid (+)
and v.item = d.item (+);

comment on table plateitemlotsumview is '$Id$';

exit;
