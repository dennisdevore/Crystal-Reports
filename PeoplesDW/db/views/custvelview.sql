create or replace view custvelview(
    custid,
    velocity,
    cnt
)
as
select
    custid,
    velocity,
    count(*)
from custitem
where status = 'ACTV'
group by custid, velocity;

comment on table custvelview is '$Id$';

exit;
