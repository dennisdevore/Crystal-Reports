create or replace view custitemnolipview
(facility
,custid
,custname
,item
,inventoryclass
,invstatus
,status
,lotnumber
,uom
,lipcount
,qty
,lastuser
,lastupdate
,itemabbrev
,itemdescr
,stdweight
,invstatusabbrev
,statusabbrev
,custitemsign
,uomabbrev
,projected
,inventoryclassabbrev
,hazardous
,weight
,weight_kgs
,cube
)
as
select
facility
,custitem.custid
,customer.name
,custitem.item
,'RG'
,'AV'
,'A'
,'(none)'
,custitem.baseuom
,0
,0
,'SYSTEM'
,sysdate
,custitem.abbrev
,custitem.descr
,custitem.weight
,substr(zlp.invstatus_abbrev('AV'),1,12)
,substr(zci.custitem_status_abbrev('A'),1,12)
,zci.custitem_sign('A')
,unitsofmeasure.abbrev
,zci.custitem_projected('A')
,inventoryclass.abbrev
,substr(zci.hazardous_item(custitem.custid,custitem.item),1,1)
,0
,0
,0
from unitsofmeasure, inventoryclass, facility, customer, custitem
where custitem.status = 'ACTV'
  and custitem.custid = customer.custid(+)
  and custitem.baseuom = unitsofmeasure.code(+)
  and 'RG' = inventoryclass.code(+)
  and not exists
    (select * from custitemtot
      where custitem.custid = custitemtot.custid
        and custitem.item = custitemtot.item)
  and exists
    (select * from custitemtot
      where facility.facility = custitemtot.facility
        and custitem.custid = custitemtot.custid);

comment on table custitemnolipview is '$Id$';

create or replace view custitemtotview
(facility
,custid
,custname
,item
,inventoryclass
,invstatus
,status
,lotnumber
,uom
,lipcount
,qty
,lastuser
,lastupdate
,itemabbrev
,itemdescr
,stdweight
,invstatusabbrev
,statusabbrev
,custitemsign
,uomabbrev
,projected
,inventoryclassabbrev
,hazardous
,weight
,weight_kgs
,cube
)
as
select
facility
,custitemtot.custid
,customer.name
,custitemtot.item
,custitemtot.inventoryclass
,custitemtot.invstatus
,custitemtot.status
,custitemtot.lotnumber
,uom
,lipcount * zci.custitem_sign(custitemtot.status)
,qty * zci.custitem_sign(custitemtot.status)
,custitemtot.lastuser
,custitemtot.lastupdate
,custitem.abbrev
,custitem.descr
,custitem.weight
,substr(zlp.invstatus_abbrev(custitemtot.invstatus),1,12)
,substr(zci.custitem_status_abbrev(custitemtot.status),1,12)
,zci.custitem_sign(custitemtot.status)
,unitsofmeasure.abbrev
,zci.custitem_projected(custitemtot.status)
,inventoryclass.abbrev
,substr(zci.hazardous_item(custitemtot.custid,custitemtot.item),1,1)
,custitemtot.weight * zci.custitem_sign(custitemtot.status)
,zwt.from_lbs_to_kgs(custitemtot.custid,custitemtot.weight) * zci.custitem_sign(custitemtot.status)
,qty * zci.item_cube(custitemtot.custid,custitemtot.item,custitemtot.uom) * zci.custitem_sign(custitemtot.status)
from unitsofmeasure, inventoryclass, customer, custitem, custitemtot
where custitemtot.custid = custitem.custid(+)
and custitemtot.item = custitem.item(+)
and custitemtot.custid = customer.custid(+)
and custitemtot.uom = unitsofmeasure.code(+)
and custitemtot.inventoryclass = inventoryclass.code(+)
and custitemtot.status not in ('D', 'P')
union
select
facility
,custitem.custid
,customer.name
,custitem.item
,'RG'
,'AV'
,'A'
,'(none)'
,custitem.baseuom
,0
,0
,'SYSTEM'
,sysdate
,custitem.abbrev
,custitem.descr
,custitem.weight
,substr(zlp.invstatus_abbrev('AV'),1,12)
,substr(zci.custitem_status_abbrev('A'),1,12)
,zci.custitem_sign('A')
,unitsofmeasure.abbrev
,zci.custitem_projected('A')
,inventoryclass.abbrev
,substr(zci.hazardous_item(custitem.custid,custitem.item),1,1)
,0
,0
,0
from unitsofmeasure, inventoryclass, facility, customer, custitem
where custitem.status = 'ACTV'
  and custitem.custid = customer.custid(+)
  and custitem.baseuom = unitsofmeasure.code(+)
  and 'RG' = inventoryclass.code(+)
  and not exists
    (select * from custitemtot
      where custitem.custid = custitemtot.custid
        and custitem.item = custitemtot.item
        and custitemtot.status not in ('D', 'P')
        and custitemtot.invstatus != 'SU')
  and exists
    (select * from custitemtot
      where facility.facility = custitemtot.facility
        and custitem.custid = custitemtot.custid);

comment on table custitemtotview is '$Id$';

create or replace view custitemtotallview
(facility
,custid
,item
,inventoryclass
,invstatus
,status
,uom
,lotnumber
,inventoryclassabbrev
,invstatusabbrev
,statusabbrev
,uomabbrev
,lipcount
,qty
,weight
,weight_kgs
,cube
)
as
select
facility
,custid
,item
,inventoryclass
,invstatus
,decode(custitemtotview.status,'I','I','CM','CM','PN','PN','R','R','-') as status
,uom
,lotnumber
,inventoryclassabbrev
,invstatusabbrev
,nvl(itemlipstatus.abbrev,'----------')
,uomabbrev
,sum(lipcount)
,sum(qty)
,sum(weight)
,sum(weight_kgs)
,sum(cube)
from itemlipstatus, custitemtotview
where decode(custitemtotview.status,'I','I','CM','CM','PN','PN','R','R','-')
    = itemlipstatus.code(+)
group by facility,custid,item,inventoryclass,invstatus,status,uom,lotnumber,
  inventoryclassabbrev,invstatusabbrev,itemlipstatus.abbrev,uomabbrev;

comment on table custitemtotallview is '$Id$';

create or replace view custitemtotsumview
(facility
,custid
,item
,inventoryclass
,invstatus
,status
,uom
,lotnumber
,inventoryclassabbrev
,invstatusabbrev
,statusabbrev
,uomabbrev
,lipcount
,qty
,weight
,weight_kgs
,cube
)
as
select
facility
,custid
,item
,inventoryclass
,invstatus
,decode(custitemtotview.status,'I','I','CM','CM','PN','PN','R','R','-') as status
,uom
,lotnumber
,inventoryclassabbrev
,invstatusabbrev
,nvl(itemlipstatus.abbrev,'----------')
,uomabbrev
,sum(lipcount)
,sum(qty)
,sum(weight)
,sum(weight_kgs)
,sum(cube)
from itemlipstatus, custitemtotview
where decode(custitemtotview.status,'I','I','CM','CM','PN','PN','R','R','-')
    = itemlipstatus.code(+)
  and custitemsign > 0
  and invstatus != 'SU'
group by facility,custid,item,inventoryclass,invstatus,status,uom,lotnumber,
  inventoryclassabbrev,invstatusabbrev,itemlipstatus.abbrev,uomabbrev
union
select
facility
,custid
,item
,'RG' as inventoryclass
,'AV' as invstatus
,'A' as status
,uom
,lotnumber
,substr(zlp.inventoryclass_abbrev('RG'),1,12)
,substr(zlp.invstatus_abbrev('AV'),1,12)
,'----------'
,uomabbrev
,0
,0
,0
,0
,0
from custitemtotview cit
where not exists(
select 1
from custitemtotview
where facility=cit.facility
and custid=cit.custid
and item=cit.item
and invstatus=cit.invstatus
and inventoryclass=cit.inventoryclass
and uom=cit.uom
and nvl(lotnumber,'(none)')=nvl(cit.lotnumber,'(none)')
and custitemsign > 0
and invstatus != 'SU');

comment on table custitemtotsumview is '$Id$';

create or replace view custitemtotsumavailview
(facility
,custid
,item
,inventoryclass
,invstatus
,status
,uom
,lotnumber
,inventoryclassabbrev
,invstatusabbrev
,statusabbrev
,uomabbrev
,lipcount
,qty
,weight
,weight_kgs
,cube
)
as
select
facility
,custid
,item
,inventoryclass
,invstatus
,status
,uom
,lotnumber
,inventoryclassabbrev
,invstatusabbrev
,nvl(itemlipstatus.abbrev,'----------')
,uomabbrev
,sum(lipcount)
,sum(qty)
,sum(weight)
,sum(weight_kgs)
,sum(cube)
from itemlipstatus, custitemtotview
where projected = 1
  and decode(custitemtotview.status,'I','I','CM','CM','PN','PN','R','R','-')
  = itemlipstatus.code(+)
  and invstatus != 'SU'
group by facility,custid,item,inventoryclass,invstatus,status,uom,lotnumber,
  inventoryclassabbrev,invstatusabbrev,itemlipstatus.abbrev,uomabbrev
union
select
facility
,custid
,item
,'RG' as inventoryclass
,'AV' as invstatus
,'A' as status
,uom
,lotnumber
,substr(zlp.inventoryclass_abbrev('RG'),1,12)
,substr(zlp.invstatus_abbrev('AV'),1,12)
,'----------'
,uomabbrev
,0
,0
,0
,0
,0
from custitemtotview cit
where projected = 1
and invstatus = 'SU'
and not exists(
select 1
from custitemtotview
where facility=cit.facility
and custid=cit.custid
and item=cit.item
and inventoryclass=cit.inventoryclass
and uom=cit.uom
and nvl(lotnumber,'(none)')=nvl(cit.lotnumber,'(none)')
and projected = 1
and invstatus <> 'SU');

comment on table custitemtotsumavailview is '$Id$';

create or replace view custitemtotcommitview
(facility
,custid
,item
,inventoryclass
,invstatus
,uom
,lotnumber
,qty
,mincreationdate
,maxcreationdate
,minmanufacturedate
,maxmanufacturedate
,minexpirationdate
,maxexpirationdate
)
as
select facility, custid, item, inventoryclass, invstatus, uom, lotnumber, qty,
(select min(least(trunc(creationdate),nvl(trunc(anvdate),trunc(creationdate))))
   from plate pl
  where pl.facility=cit.facility
    and pl.custid=cit.custid
	and pl.item=cit.item
	and pl.invstatus=cit.invstatus
	and pl.inventoryclass=cit.inventoryclass),
(select max(least(trunc(creationdate),nvl(trunc(anvdate),trunc(creationdate))))
   from plate pl
  where pl.facility=cit.facility
    and pl.custid=cit.custid
	and pl.item=cit.item
	and pl.invstatus=cit.invstatus
	and pl.inventoryclass=cit.inventoryclass),
(select min(trunc(manufacturedate))
   from plate pl
  where pl.facility=cit.facility
    and pl.custid=cit.custid
	and pl.item=cit.item
	and pl.invstatus=cit.invstatus
	and pl.inventoryclass=cit.inventoryclass),
(select max(trunc(manufacturedate))
   from plate pl
  where pl.facility=cit.facility
    and pl.custid=cit.custid
	and pl.item=cit.item
	and pl.invstatus=cit.invstatus
	and pl.inventoryclass=cit.inventoryclass),
(select min(trunc(expirationdate))
   from plate pl
  where pl.facility=cit.facility
    and pl.custid=cit.custid
	and pl.item=cit.item
	and pl.invstatus=cit.invstatus
	and pl.inventoryclass=cit.inventoryclass),
(select max(trunc(expirationdate))
   from plate pl
  where pl.facility=cit.facility
    and pl.custid=cit.custid
	and pl.item=cit.item
	and pl.invstatus=cit.invstatus
	and pl.inventoryclass=cit.inventoryclass)
from custitemtotsumavailview cit;

comment on table custitemtotcommitview is '$Id$';

create or replace view custitemtotallocatedview
(facility
,custid
,item
,itemdescr
,inventoryclass
,invstatus
,uom
,lotnumber
,qty
,weight
,cube
,orderstatus)
as
select
hdr.fromfacility as facility
,dtl.custid
,dtl.item
,ci.descr
,dtl.inventoryclass
,dtl.invstatus
,dtl.uom
,dtl.lotnumber
,sum(dtl.qtyorder) as qty
,sum(dtl.weightorder) as weight
,sum(dtl.cubeorder) as cube
,hdr.orderstatus
from orderhdr hdr, orderdtl dtl, custitem ci
where hdr.orderid = dtl.orderid
  and hdr.shipid = dtl.shipid 
  and hdr.ordertype = 'O'
  and hdr.orderstatus in ('0','1', '2', '3', '4', '5', '6', '7', '8')
  and dtl.custid = ci.custid
  and dtl.item = ci.item
group by hdr.fromfacility,dtl.custid,dtl.item,ci.descr,dtl.inventoryclass,dtl.invstatus,dtl.uom,dtl.lotnumber,hdr.orderstatus;

comment on table custitemtotallocatedview is '$Id$';

create or replace view custitemtotsumallview
(facility
,custid
,item
,itemdescr
,inventoryclass
,invstatus
,status
,uom
,lotnumber
,inventoryclassabbrev
,invstatusabbrev
,statusabbrev
,uomabbrev
,lipcount
,qty
,weight
,weight_kgs
,cube
)
as
select
facility
,custid
,item
,custitemtotview.itemdescr
,inventoryclass
,invstatus
,decode(custitemtotview.status,'I','I','CM','CM','PN','PN','R','R','-') as status
,uom
,lotnumber
,inventoryclassabbrev
,invstatusabbrev
,nvl(itemlipstatus.abbrev,'----------')
,uomabbrev
,sum(lipcount)
,sum(qty)
,sum(weight)
,sum(weight_kgs)
,sum(cube)
from itemlipstatus, custitemtotview
where decode(custitemtotview.status,'I','I','CM','CM','PN','PN','R','R','-')
    = itemlipstatus.code(+)
  and custitemsign > 0
group by facility,custid,item, itemdescr, inventoryclass,invstatus,status,uom,lotnumber,
  inventoryclassabbrev,invstatusabbrev,itemlipstatus.abbrev,uomabbrev;

comment on table custitemtotsumallview is '$Id$';

exit;
