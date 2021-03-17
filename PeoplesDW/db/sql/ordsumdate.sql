set serveroutput on
set heading off
set pagesize 0
set linesize 32000
set trimspool on
break on report
break on to_char(statusupdate,'yymm')
compute sum of count(1) on to_char(statusupdate,'yymm')
compute sum of sum(nvl(qtyorder,0)) on to_char(statusupdate,'yymm')
compute sum of count(1) on report
compute sum of sum(nvl(qtyorder,0)) on report
spool ordsumdate.out

select
to_char(statusupdate,'yymm'),nvl(fromfacility,tofacility),oh.custid,cu.name,orderstatus,count(1),sum(nvl(qtyorder,0))
from customer cu, orderhdr oh
where oh.custid = cu.custid(+)
group by to_char(statusupdate,'yymm'),nvl(fromfacility,tofacility),oh.custid,cu.name,orderstatus
order by to_char(statusupdate,'yymm'),nvl(fromfacility,tofacility),oh.custid,cu.name,orderstatus;
exit;
spool off;

exit;

