create or replace view platesumview
(
FACILITY,                     
CUSTID,                       
ITEM,
DESCR,                         
UNITOFMEASURE,                     
TYPE,                         
INVENTORYCLASS,                
QUANTITY,
WEIGHT
)
as
select
plate.FACILITY,                     
plate.CUSTID,                       
plate.ITEM,
custitem.DESCR,                         
plate.UNITOFMEASURE,                
plate.TYPE,                         
plate.INVENTORYCLASS,
sum(nvl(plate.QUANTITY,0)),                     
sum(nvl(plate.WEIGHT,0))
from plate, custitem
where plate.custid = custitem.custid (+)
and plate.item = custitem.item (+)
group by
plate.FACILITY,                     
plate.CUSTID,                       
plate.ITEM,
custitem.DESCR,                         
plate.UNITOFMEASURE,                
plate.TYPE,                         
plate.INVENTORYCLASS;

comment on table platesumview is '$Id: platesumview.sql 2637 2008-03-31 15:26:24Z ed $';

-- exit;
