CREATE OR REPLACE VIEW DRE_RPT_BOLITMCMTV4A
(ORDERID, SHIPID, ITEM, LOTNUMBER,BOLITMCOMMENT)
AS 
select
    OD.orderid,
    OD.shipid,
    OD.item,
    nvl(nvl((select sp.lotnumber from shippingplate sp
			where od.orderid = sp.orderid and
			od.shipid = sp.shipid and
			od.item = sp.item and
			od.lotnumber = sp.orderlot and
			od.comment1 is not null and
			sp.lotnumber <> sp.orderlot),
		OD.lotnumber),'**NULL**') as lotnumber,
    drebol.dre_bolitmcmtv4comments(OD.orderid, OD.shipid,OD.item, OD.lotnumber) as bolitmcomment
from orderdtl OD;

comment on table DRE_RPT_BOLITMCMTV4A is '$Id$';

exit;



