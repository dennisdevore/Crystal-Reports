--
-- $Id$
--
select count(1)
from orderhdr
where ordertype = 'O'
and custid = 'HP'
and orderstatus = '9'
and dateshipped >= to_date('20000822030000','yyyymmddhh24miss')
and dateshipped <  to_date('20000823030000','yyyymmddhh24miss');
select count(1)
from orderhdr
where ordertype = 'O'
and custid = 'HP'
and orderstatus = 'X'
and statusupdate >= to_date('20000822030000','yyyymmddhh24miss')
and statusupdate <  to_date('20000823030000','yyyymmddhh24miss');
select count(1) as count, sum(weight) as weight
from shippingplate s
where parentlpid is null
  and status = 'SH'
  and type in ('M','C')
  and exists
(select *
from orderhdr o
where ordertype = 'O'
and custid = 'HP'
and orderstatus = '9'
and dateshipped >= to_date('20000822030000','yyyymmddhh24miss')
and dateshipped <  to_date('20000823030000','yyyymmddhh24miss')
and s.orderid = o.orderid
and s.shipid = o.shipid);
select count(1) as count, sum(qtyorder) as qtyorder,
       sum(qtyship) as qtyship, sum(weightship) as weightship
from orderdtl s
where linestatus != 'X'
  and exists
(select *
from orderhdr o
where ordertype = 'O'
and custid = 'HP'
and orderstatus = '9'
and dateshipped >= to_date('20000822030000','yyyymmddhh24miss')
and dateshipped <  to_date('20000823030000','yyyymmddhh24miss')
and s.orderid = o.orderid
and s.shipid = o.shipid);
break on report;
compute sum of lbs on report;
SELECT 
    "SHIP_NOTIFY_HDR"."CUSTID", "SHIP_NOTIFY_HDR"."DATESHIPPED", "SHIP_NOTIFY_CONTAINER"."TRACKINGNO", "SHIP_NOTIFY_CONTAINER"."SERVICECODE", "SHIP_NOTIFY_CONTAINER"."LBS", "SHIP_NOTIFY_CONTENTS"."ORDERID", "SHIP_NOTIFY_CONTENTS"."SHIPID", "SHIP_NOTIFY_CONTENTS"."TRACKINGNO", "SHIP_NOTIFY_CONTENTS"."ITEM", "SHIP_NOTIFY_CONTENTS"."QTY"
FROM
    "ALPS"."SHIP_NOTIFY_HDR" "SHIP_NOTIFY_HDR",
    "ALPS"."SHIP_NOTIFY_CONTAINER" "SHIP_NOTIFY_CONTAINER",
    "ALPS"."SHIP_NOTIFY_CONTENTS" "SHIP_NOTIFY_CONTENTS"
WHERE
    "SHIP_NOTIFY_HDR"."ORDERID" = "SHIP_NOTIFY_CONTAINER"."ORDERID" AND
    "SHIP_NOTIFY_HDR"."SHIPID" = "SHIP_NOTIFY_CONTAINER"."SHIPID" AND
    "SHIP_NOTIFY_CONTAINER"."ORDERID" = "SHIP_NOTIFY_CONTENTS"."ORDERID" AND
    "SHIP_NOTIFY_CONTAINER"."SHIPID" = "SHIP_NOTIFY_CONTENTS"."SHIPID" AND
    "SHIP_NOTIFY_CONTAINER"."TRACKINGNO" = "SHIP_NOTIFY_CONTENTS"."TRACKINGNO" AND
    "SHIP_NOTIFY_HDR"."CUSTID" = 'HP' AND
    SHIP_NOTIFY_HDR."DATESHIPPED" >= TO_DATE ('22-AUG-2000 03:00:00', 'DD-MON-YYYY HH24:MI:SS') AND
    SHIP_NOTIFY_HDR."DATESHIPPED" < TO_DATE ('23-AUG-2000 03:00:00', 'DD-MON-YYYY HH24:MI:SS')
ORDER BY
    "SHIP_NOTIFY_HDR"."CUSTID" ASC;
exit;

