CREATE OR REPLACE VIEW ORDERPALLETVIEW ( ORDERID, 
SHIPID, INPALLTES, OUTPALLETS ) AS 
select orderid,shipid,sum(inpallets) as inpalltes,  
	   sum(outpallets) as outpallets  
from pallethistory 
group by orderid,shipid;

comment on table ORDERPALLETVIEW is '$Id$';

exit;
