CREATE OR REPLACE VIEW DRE_RPT_ORDERDTLCMTVIEWA
(ORDERID, SHIPID, ITEM, LOTNUMBER, LOTNUMBER_NULL, 
 OD_ROWID, OD_COMMENT)
AS 
select
orderid,
shipid,
item,
lotnumber,
lotnumber_null,
od_rowid,
drebol.dre_odcomments(orderid, shipid, item, lotnumber_null) as od_comment
from
dre_rpt_orderdtlcmtview;

comment on table DRE_RPT_ORDERDTLCMTVIEWA is '$Id$';

exit;

