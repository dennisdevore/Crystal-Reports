create or replace view dre_bolitmcmtv1 as
select  a.ORDERID,        
 a.SHIPID,         
 a.ITEM,           
 'PRE-ORDER                     ' as LOTNUMBER,      
 a.ODC_ITEM,       
 a.ODC_COMMENT,    
 a.CI_ITEM,        
 a.CI_COMMENT,     
 a.CID_ITEM,       
 a.CID_COMMENT
from bolitmcmtview a, orderdtl b
where a.orderid = b.orderid and
	  a.shipid  = b.shipid and
	  a.item    = b.item and
	  nvl(b.qtyship,0) = 0; 
     
comment on table dre_bolitmcmtv1 is '$Id$';
     
exit;
