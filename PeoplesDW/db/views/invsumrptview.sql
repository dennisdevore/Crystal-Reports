create or replace view invsumrpt
(
invoice,
masterinvoice,
activity,
activityabbrev,
calceduom,
billedrate,
billmethod,
numentries,
sumqty,
sumamount
)
as
select
       ID.invoice,
       IH.masterinvoice,
       ID.activity,
       AC.abbrev,
       ID.calceduom,
       ID.billedrate,
       BM.abbrev,
       count(1),
       sum(ID.billedqty),
       sum(NVL(ID.billedamt,0))
  from invoicehdr IH, invoicedtl ID, customer C, billingmethod BM, activity AC
 where IH.invoice = ID.invoice
   and ID.activity = AC.code 
   and ID.billmethod = BM.code
   and C.custid = ID.custid
   and ((ID.invoice > 0 and ID.billstatus !='4') or (ID.invoice < 0 and ID.billstatus in ('4','E')))
   and ID.invtype = 'A'
   and NVL(C.sumassessorial,'N') = 'Y'
group by
       ID.invoice,
       IH.masterinvoice,
       ID.activity,
       AC.abbrev,
       ID.calceduom,
       ID.billedrate,
       BM.abbrev
UNION
select
       ID.invoice,
       IH.masterinvoice,
       '',
       '',
       '',
       0,
       '',
       0,
       0,
       0
  from invoicehdr IH, invoicedtl ID, customer C
 where  IH.invoice = ID.invoice
   and C.custid = ID.custid
   and ((ID.invoice > 0 and ID.billstatus !='4') or (ID.invoice < 0 and ID.billstatus in ('4','E')))
   and (ID.invtype != 'A'
       or NVL(C.sumassessorial,'N') != 'Y')
group by
       ID.invoice,
       IH.masterinvoice;

comment on table invsumrpt is '$Id$';

create or replace view pho_invsumrptview
(facility, custid, item, invstatus, status, lotnumber,
 qty, rcvddate)
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
  and plate.facility = asofinventorydtl.facility (+)
  and plate.custid = asofinventorydtl.custid (+)
  and plate.item = asofinventorydtl.item (+)
  and nvl(plate.lotnumber, '(none)') = nvl(asofinventorydtl.lotnumber (+), '(none)')
  and plate.unitofmeasure = asofinventorydtl.uom (+)
  and nvl(plate.invstatus, '(none)') = nvl(asofinventorydtl.invstatus (+), '(none)')
  and nvl(plate.inventoryclass, '(none)') = nvl(asofinventorydtl.inventoryclass (+), '(none)')
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
        and custitem.custid = custitemtot.custid);

comment on table pho_invsumrptview is '$Id$';

exit;
