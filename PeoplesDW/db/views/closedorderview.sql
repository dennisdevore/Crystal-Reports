CREATE OR REPLACE VIEW alps.closed_order_view
(reference
,status
,statusdate
)
as
select
reference,
decode(orderstatus,'X','CANCELLED','SHIPPED'),
decode(orderstatus,'X',statusupdate,dateshipped)
from orderhdr
where custid = 'HP'
  and ordertype = 'O'
  and orderstatus in ('9','X');
  
comment on table closed_order_view is '$Id$';
  
exit;

