--
-- $Id$
--
set feedback off verify off;
break on report;
compute sum of order_count on report;
spool shipped_orders1.txt;
select '08/07/2000 hpshopping.com' as orders_by_fedex_service from dual;
select substr(hdrpassthruchar07,1,8) as service,
       count(1) as order_count
  from orderhdr
 where orderhdr.custid = 'HP'
	and ordertype = 'O'
	and orderstatus = '9'
   and orderhdr.dateshipped >= to_date('20000807030000', 'yyyymmddhh24miss')
   and orderhdr.dateshipped <  to_date('20000808030000', 'yyyymmddhh24miss')
 group by hdrpassthruchar07
 order by hdrpassthruchar07;
spool off;
exit;
