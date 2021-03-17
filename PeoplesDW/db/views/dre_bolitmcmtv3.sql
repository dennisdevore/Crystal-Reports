create or replace view dre_bolitmcmtv3 as
select ORDERID,        
 SHIPID,         
 ITEM,           
decode(item,item_1,LOTNUMBER_1,LOTNUMBER) as LOTNUMBER, 
 ODC_ITEM,       
 ODC_COMMENT,    
 CI_ITEM,        
 CI_COMMENT,     
 CID_ITEM,       
 CID_COMMENT from dre_bolitmcmtv2;

comment on table dre_bolitmcmtv3 is '$Id$';


create or replace view dre_bolitmcmtv3A
(
    orderid,
    shipid,
    item,
    bolitmcomment
) as
select
    OD.orderid,
    OD.shipid,
    OD.item,
    drebol.dre_bolitmcmtv3comments(OD.orderid, OD.shipid,OD.item) as bolitmcomment
from
	orderdtl OD;

comment on table dre_bolitmcmtv3A is '$Id$';

exit;
