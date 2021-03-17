create or replace view pho_rpt_custitemtotview
(facility, custid, item, invstatus, status,
 lotnumber, qty, rcvddate)
as
select
facility
,custitemtot.custid
,custitemtot.item
,custitemtot.invstatus
,custitemtot.status
,custitemtot.lotnumber
,qty * zci.custitem_sign(custitemtot.status)
,null
from custitemtot
where custitemtot.status not in ('A', 'D', 'P')
union
select
plate.facility
,plate.custid
,plate.item
,plate.invstatus
,plate.status
,plate.lotnumber
,sum(plate.quantity)
,max(asofinventorydtl.effdate)
from plate, asofinventorydtl
where plate.status = 'A'
  and plate.lpid = asofinventorydtl.lpid (+)
  and 'RC' = asofinventorydtl.trantype (+)
group by plate.facility
,plate.custid
,plate.item
,plate.invstatus
,plate.status
,plate.lotnumber
,null
union
select
facility.facility
,custitem.custid
,custitem.item
,'AV'
,'A'
,'(none)'
,0
,null
from custitem, facility
where custitem.status = 'ACTV'
  and not exists
    (select * from custitemtot
      where custitem.custid = custitemtot.custid
        and custitem.item = custitemtot.item)
  and exists
    (select * from custitemtot
      where facility.facility = custitemtot.facility
        and custitem.custid = custitemtot.custid)

/
