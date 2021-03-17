set serveroutput on
set heading off
set pagesize 0
set linesize 32000
set trimspool on
break on report
compute sum of count(1) on report
compute sum of sum(nvl(qtyorder,0)) on report
spool ordsum.out

select
nvl(fromfacility,tofacility),oh.custid,cu.name,orderstatus,count(1),sum(nvl(qtyorder,0))
from customer cu, orderhdr oh
where oh.custid = cu.custid(+)
group by nvl(fromfacility,tofacility),oh.custid,cu.name,orderstatus
order by nvl(fromfacility,tofacility),oh.custid,cu.name,orderstatus;
exit;
spool off;

exit;

