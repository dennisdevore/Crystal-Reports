CREATE OR REPLACE VIEW STAGED_SP (
CUSTID,
FROMLPID,
ITEM,
QUANTITY,
TYPE,
ORDERID,
LPID,
PARENTLPID,
CREATIONDATE,
EXPORTDATE,
REFERENCE )
AS select
s.custid,
s.fromlpid,
s.item,
s.quantity,
s.type,
s.orderid,
s.lpid,
s.parentlpid,
sysdate,
sysdate,
oh.reference
from shippingplate s, orderhdr oh
where s.orderid = oh.orderid
  and s.shipid = oh.shipid;

comment on table STAGED_SP is '$Id: STAGED_SP.sql 135 2005-09-06 12:14:48Z ed $';

exit;
