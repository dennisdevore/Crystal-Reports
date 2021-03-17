break on report;
compute sum of cntorder qtyorder on report;
compute avg of qtyperorder on report;
set pagesize 100
spool ohenteredsum.out;
select 'summary since last 30 days' from dual;
select 'snapshot summary by status' from dual;
select
orderstatus as orderstatus,
count(1) as cntorder,
sum(nvl(qtyorder,0)) as qtyorder,
round(decode(count(1), 0, 0, sum(nvl(qtyorder,0)) / count(1)),2) as qtyperorder
from orderhdr
where entrydate > sysdate - 30
  and ordertype = 'O'
group by orderstatus
order by orderstatus;
select 'activity summary by entry dates' from dual;
select
trunc(entrydate) as entrydate,
count(1) as cntorder,
sum(nvl(qtyorder,0)) as qtyorder,
round(decode(count(1), 0, 0, sum(nvl(qtyorder,0)) / count(1)),2) as qtyperorder
from orderhdr
where entrydate > sysdate - 30
  and ordertype = 'O'
group by trunc(entrydate)
order by trunc(entrydate);
select 'orders shipped activity summary' from dual;
select
trunc(dateshipped) as dateshipped,
orderstatus,
count(1) as cntorder,
sum(nvl(qtyorder,0)) as qtyorder,
round(decode(count(1), 0, 0, sum(nvl(qtyorder,0)) / count(1)),2) as qtyperorder
from orderhdr
where entrydate > sysdate - 30
and orderstatus = '9' 
and ordertype = 'O'
group by trunc(dateshipped), orderstatus
order by trunc(dateshipped), orderstatus;
exit;
