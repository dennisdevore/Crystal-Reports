CREATE OR REPLACE VIEW DRE_RPT_BOLITMCMTV5A
(ORDERID, SHIPID, ITEM,BOLITMCOMMENT)
AS 
select
    OD.orderid,
    OD.shipid,
    OD.item,
    drebol.dre_bolitmcmtv5comments(OD.orderid, OD.shipid,OD.item) as bolitmcomment
from
	orderdtl OD where lotnumber is null;


comment on table DRE_RPT_BOLITMCMTV5A is '$Id$';

exit;
