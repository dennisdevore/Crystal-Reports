CREATE OR REPLACE VIEW DRE_RPT_BOLITMCMTV4B
(ORDERID, SHIPID, ITEM, LOTNUMBER,BOLITMCOMMENT)
AS 
select
    orderid,
    shipid,
    item,
    lotnumber,
    min(bolitmcomment)
from DRE_RPT_BOLITMCMTV4A
group by 
	orderid,
    shipid,
    item,
    lotnumber;

comment on table DRE_RPT_BOLITMCMTV4B is '$Id$';

exit;



