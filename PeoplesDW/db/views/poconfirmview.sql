create or replace view poconfirmview
(
PORMA,                           
ORDERID,                      
SHIPID,                       
CUSTID,                       
loadsbilloflading,
orderhdrBILLOFLADING,                 
QTYRCVD,                      
QTYORDER,                     
LOADNO
)
as
select 
decode(orderhdrview.ordertype,'R',orderhdrview.po,'C',orderhdrview.po,orderhdrview.rma),
orderhdrview.ORDERID,                      
orderhdrview.SHIPID,                       
orderhdrview.CUSTID,                       
loadsview.billoflading,
orderhdrview.BILLOFLADING,                 
orderhdrview.QTYRCVD,                      
orderhdrview.QTYorder,                      
orderhdrview.LOADNO
from orderhdrview, loadsview, orderdtlview, customer
where orderhdrview.loadno = loadsview.loadno
  and orderhdrview.orderid = orderdtlview.orderid
  and orderhdrview.shipid = orderdtlview.shipid
  and orderhdrview.custid = customer.custid;

comment on table poconfirmview is '$Id$';

exit;
