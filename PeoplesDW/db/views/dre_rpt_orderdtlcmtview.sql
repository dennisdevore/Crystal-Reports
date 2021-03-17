CREATE OR REPLACE VIEW DRE_RPT_ORDERDTLCMTVIEW
(ORDERID, SHIPID, ITEM, LOTNUMBER, LOTNUMBER_NULL, 
 OD_ROWID, OD_COMMENT)
AS 
select
orderid,
shipid,
item,
lotnumber,
nvl(lotnumber,'**NULL**'),
rowid,
comment1
from orderdtl;

comment on table DRE_RPT_ORDERDTLCMTVIEW is '$Id$';

exit;
