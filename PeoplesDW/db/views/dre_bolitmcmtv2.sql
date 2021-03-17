create or replace view  dre_bolitmcmtv2 as 
select a.ORDERID,        
 a.SHIPID,         
 a.ITEM,           
 a.LOTNUMBER,      
 a.ODC_ITEM,       
 a.ODC_COMMENT,    
 a.CI_ITEM,        
 a.CI_COMMENT,     
 a.CID_ITEM,       
 a.CID_COMMENT,
 b.ORDERID as ORDERID_1,        
 b.SHIPID as SHIPID_1,         
 b.ITEM as ITEM_1,           
 b.LOTNUMBER as LOTNUMBER_1,      
 b.ODC_ITEM as ODC_ITEM_1,       
 b.ODC_COMMENT as ODC_COMMENT_1,    
 b.CI_ITEM as CI_ITEM_1,        
 b.CI_COMMENT as CI_COMMENT_1,     
 b.CID_ITEM as CID_ITEM_1,       
 b.CID_COMMENT as CID_COMMENT_1
 from bolitmcmtview a, dre_bolitmcmtv1 b
 where a.orderid = b.orderid and 
 	   a.shipid = b.shipid;
      
comment on table dre_bolitmcmtv2 is '$Id$';

exit; 
