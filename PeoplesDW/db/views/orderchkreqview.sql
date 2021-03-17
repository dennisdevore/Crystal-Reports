
CREATE OR REPLACE VIEW ORDERCHKREQVIEW ( ORDERID, 
SHIPID, CUSTID, LOADNO ) AS select orderid,shipid,a.custid,loadno 
from orderhdr a, customer b 
where a.custid = b.custid 
and ordercheckrequired = 'Y' 
and loadno is not null;

comment on table ORDERCHKREQVIEW is '$Id$';

exit;
