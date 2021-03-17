delete from custrenewal
 where renewal is null;
insert into custbillschedule
select custid, 'Renewal', renewal, lastuser, lastupdate
from custrenewal
where not exists
(select * from custbillschedule
  where custbillschedule.custid = custrenewal.custid
    and custbillschedule.type = 'Renewal'
    and custbillschedule.billdate = custrenewal.renewal);
commit;

exit;
