create or replace view stock_status_nsd
(facility
,custid
,item
,nsd_status
,qty)
as
select
facility,
custid,
item,
'N',
sum(nvl(qty,0))
from custitemtot
where item not in ('UNKNOWN','RETURNS','x')
  and invstatus != 'SU'
  and ( (invstatus = 'AV' and status in ('CM','I','PN')) or
        (invstatus not in ('AV','DM') and status in ('A','M','PN') ) )
group by facility,custid,item,'N'
union
select
facility,
custid,
item,
'S',
sum(nvl(qty,0) * zci.custitem_sign(status))
from custitemtot
where item not in ('UNKNOWN','RETURNS','x')
  and invstatus = 'AV'
  and status in ('A','M','CM','PN')
group by facility,custid,item,'S'
union
select
facility,
custid,
item,
'D',
sum(nvl(qty,0))
from custitemtot
where item not in ('UNKNOWN','RETURNS','x')
  and invstatus != 'SU'
  and invstatus = 'DM'
  and status in ('A','M','PN')
group by facility,custid,item,'D';

comment on table stock_status_nsd is '$Id$';

--exit;
