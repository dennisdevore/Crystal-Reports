create or replace view availchildbaseview
(facility
,custid
,item
,lotnumber
,minlot
,maxlot
,invstatus
,inventoryclass
,lpid
,location
,loctype
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,weight
)
as
select
child.facility,
child.custid,
child.item,
child.lotnumber,
child.lotnumber,
child.lotnumber,
child.invstatus,
child.inventoryclass,
decode(custitemview.rcpt_qty_is_full_qty,'Y',child.lpid,child.parentlpid),
child.location,
location.loctype,
location.pickingzone,
min(child.manufacturedate),
min(child.useritem1),
min(child.useritem2),
min(child.useritem3),
min(child.serialnumber),
min(child.countryof),
min(child.expirationdate),
min(child.creationdate),
min(child.anvdate),
sum(child.quantity -
    decode(custitemview.rcpt_qty_is_full_qty,
           'Y',nvl((select sum(qty)
                      from batchtasks
                     where batchtasks.lpid=child.lpid),0),
           0)),
sum(child.weight -
    decode(custitemview.rcpt_qty_is_full_qty,
           'Y',nvl((select sum(weight)
                      from batchtasks
                     where batchtasks.lpid=child.lpid),0),
           0))
from location, plate child, custitemview, plate parent
where child.facility = location.facility
  and child.location = location.locid
  and child.custid = custitemview.custid
  and child.item = custitemview.item 
  and location.status != 'O'
  and 'N' = zasn.plate_has_asn_data(child.lpid)
  and child.status = 'A'
  and child.type = 'PA'
  and ((child.childfacility = child.facility
  and   (custitemview.lotrequired not in('O','S')
   or    exists (select 1
                   from plate parent
                  where parent.lpid = child.parentlpid
                    and parent.lotnumber is not null)
   or    not exists (select 1
                     from plate sibling
                    where sibling.parentlpid = child.parentlpid
                      and (sibling.item != child.item                      
                       or nvl(sibling.lotnumber,'(none)') != nvl(child.lotnumber,'(none)')))))
   or (custitemview.rcpt_qty_is_full_qty = 'Y'
  and  not exists (select 1
                     from subtasks
                    where child.parentlpid = subtasks.lpid
                      and subtasks.picktotype = 'FULL')))
  and not exists (select 1
                    from subtasks
                   where child.lpid = subtasks.lpid)
  and parent.lpid = child.parentlpid
  and nvl(parent.virtuallp,'N') != 'Y'
group by child.facility,child.custid,child.item,
  child.lotnumber,child.invstatus,child.inventoryclass,
  decode(custitemview.rcpt_qty_is_full_qty,'Y',child.lpid,child.parentlpid),
  child.location,location.loctype,location.pickingzone
union all
select
child.facility,
child.custid,
child.item,
child.lotnumber,
child.lotnumber,
child.lotnumber,
child.invstatus,
child.inventoryclass,
child.lpid,
child.location,
location.loctype,
location.pickingzone,
min(child.manufacturedate),
min(child.useritem1),
min(child.useritem2),
min(child.useritem3),
min(child.serialnumber),
min(child.countryof),
min(child.expirationdate),
min(child.creationdate),
min(child.anvdate),
sum(child.quantity),
sum(child.weight)
from location, plate child, custitemview, plate parent
where child.facility = location.facility
  and child.location = location.locid
  and child.custid = custitemview.custid
  and child.item = custitemview.item 
  and location.status != 'O'
  and 'N' = zasn.plate_has_asn_data(child.lpid)
  and child.status = 'A'
  and child.type = 'PA'
  and ((child.childfacility = child.facility
  and   (custitemview.lotrequired not in('O','S')
   or    exists (select 1
                   from plate parent
                  where parent.lpid = child.parentlpid
                    and parent.lotnumber is not null)
   or    not exists (select 1
                       from plate sibling
                      where sibling.parentlpid = child.parentlpid
                        and (sibling.item != child.item
                         or nvl(sibling.lotnumber,'(none)') != nvl(child.lotnumber,'(none)')))))
   or custitemview.rcpt_qty_is_full_qty = 'Y')
  and not exists (select 1
                    from subtasks
                   where child.lpid = subtasks.lpid)
  and parent.lpid = child.parentlpid
  and nvl(parent.virtuallp,'N') = 'Y'
group by child.facility,child.custid,child.item,
  child.lotnumber,child.invstatus,child.inventoryclass,
  child.lpid,child.location,location.loctype,
  location.pickingzone
union all
select
child.facility,
child.custid,
child.item,
child.lotnumber,
child.lotnumber,
child.lotnumber,
child.invstatus,
child.inventoryclass,
decode(custitemview.rcpt_qty_is_full_qty,'Y',child.lpid,child.parentlpid),
child.location,
location.loctype,
location.pickingzone,
child.manufacturedate,
child.useritem1,
child.useritem2,
child.useritem3,
child.serialnumber,
child.countryof,
child.expirationdate,
child.creationdate,
child.anvdate,
child.quantity -
decode(custitemview.rcpt_qty_is_full_qty,
       'Y',nvl((select sum(qty)
                  from batchtasks
                 where batchtasks.lpid=child.lpid),0),
       0),
child.weight -
decode(custitemview.rcpt_qty_is_full_qty,
       'Y',nvl((select sum(weight)
                  from batchtasks
                 where batchtasks.lpid=child.lpid),0),
       0)
from location, plate child, custitemview, plate parent
where child.facility = location.facility
  and child.location = location.locid
  and child.custid = custitemview.custid
  and child.item = custitemview.item 
  and location.status != 'O'
  and 'N' = zasn.plate_has_asn_data(child.lpid)
  and child.status = 'A'
  and child.type = 'PA'
  and ((child.childfacility = child.facility
  and   custitemview.lotrequired in('O','S')
  and   not exists (select 1
                      from plate parent
                     where parent.lpid = child.parentlpid
                       and parent.lotnumber is not null))
   or  (custitemview.rcpt_qty_is_full_qty = 'Y'
  and   not exists (select 1
                    from subtasks
                   where child.parentlpid = subtasks.lpid
                     and subtasks.picktotype = 'FULL')))
  and exists (select 1
                from plate sibling
               where sibling.parentlpid = child.parentlpid
                 and (sibling.item != child.item
                   or nvl(sibling.lotnumber,'(none)') != nvl(child.lotnumber,'(none)')))
  and not exists (select 1
                    from subtasks
                   where child.lpid = subtasks.lpid)
  and parent.lpid = child.parentlpid
  and nvl(parent.virtuallp,'N') != 'Y'
union all
select
child.facility,
child.custid,
child.item,
child.lotnumber,
child.lotnumber,
child.lotnumber,
child.invstatus,
child.inventoryclass,
child.lpid,
child.location,
location.loctype,
location.pickingzone,
child.manufacturedate,
child.useritem1,
child.useritem2,
child.useritem3,
child.serialnumber,
child.countryof,
child.expirationdate,
child.creationdate,
child.anvdate,
child.quantity,
child.weight
from location, plate child, custitemview, plate parent
where child.facility = location.facility
  and child.location = location.locid
  and child.custid = custitemview.custid
  and child.item = custitemview.item 
  and location.status != 'O'
  and 'N' = zasn.plate_has_asn_data(child.lpid)
  and child.status = 'A'
  and child.type = 'PA'
  and ((child.childfacility = child.facility
  and   custitemview.lotrequired in('O','S')
  and   not exists (select 1
                    from plate parent
                   where parent.lpid = child.parentlpid
                     and parent.lotnumber is not null))
   or  custitemview.rcpt_qty_is_full_qty = 'Y')
  and exists (select 1
                from plate sibling
               where sibling.parentlpid = child.parentlpid
                 and (sibling.item != child.item
                  or nvl(sibling.lotnumber,'(none)') != nvl(child.lotnumber,'(none)')))
  and not exists (select 1
                    from subtasks
                   where child.lpid = subtasks.lpid)
  and parent.lpid = child.parentlpid
  and nvl(parent.virtuallp,'N') = 'Y'
union all
select
child.facility,
child.custid,
child.item,
child.lotnumber,
child.lotnumber,
child.lotnumber,
child.invstatus,
child.inventoryclass,
decode(custitemview.rcpt_qty_is_full_qty,'Y',child.lpid,child.parentlpid),
child.location,
location.loctype,
location.pickingzone,
min(child.manufacturedate),
min(child.useritem1),
min(child.useritem2),
min(child.useritem3),
min(child.serialnumber),
min(child.countryof),
min(child.expirationdate),
min(child.creationdate),
min(child.anvdate),
sum(child.quantity -
    decode(custitemview.rcpt_qty_is_full_qty,
           'Y',nvl((select sum(qty)
                      from batchtasks
                     where batchtasks.lpid=child.lpid),0),
           0)),
sum(child.weight -
    decode(custitemview.rcpt_qty_is_full_qty,
           'Y',nvl((select sum(weight)
                      from batchtasks
                     where batchtasks.lpid=child.lpid),0),
           0))
from location, plate child, custitemview
where child.facility = location.facility
  and child.location = location.locid
  and child.custid = custitemview.custid
  and child.item = custitemview.item
  and child.childfacility is null
  and child.childitem is null
  and location.status != 'O'
  and 'N' = zasn.plate_has_asn_data(child.lpid)
  and child.status = 'A'
  and child.type = 'PA'
  and parentlpid is not null
  and not exists (select 1
                    from subtasks
                   where child.lpid = subtasks.lpid)
  and ((custitemview.lotrequired in('O','S')
  and   (exists (select 1
                   from plate parent
                  where parent.lpid = child.parentlpid
                    and parent.lotnumber is not null)
   or    not exists (select 1
                       from plate sibling
                      where sibling.parentlpid = child.parentlpid
                        and (sibling.item != child.item
                         or nvl(sibling.lotnumber,'(none)') <> nvl(child.lotnumber,'(none)')))))
   or  (custitemview.rcpt_qty_is_full_qty = 'Y'
  and   not exists (select 1
                    from subtasks
                   where child.parentlpid = subtasks.lpid
                     and subtasks.picktotype = 'FULL')))
group by child.facility,child.custid,child.item,
  child.lotnumber,child.invstatus,child.inventoryclass,
  decode(custitemview.rcpt_qty_is_full_qty,'Y',child.lpid,child.parentlpid),
  child.location,location.loctype,location.pickingzone
union all
select
child.facility,
child.custid,
child.item,
child.lotnumber,
child.lotnumber,
child.lotnumber,
child.invstatus,
child.inventoryclass,
child.lpid,
child.location,
location.loctype,
location.pickingzone,
child.manufacturedate,
child.useritem1,
child.useritem2,
child.useritem3,
child.serialnumber,
child.countryof,
child.expirationdate,
child.creationdate,
child.anvdate,
child.quantity,
child.weight
from location, plate child, custitemview
where child.facility = location.facility
  and child.location = location.locid
  and child.custid = custitemview.custid
  and child.item = custitemview.item
  and child.childfacility is null
  and child.childitem is null
  and location.status != 'O'
  and 'N' = zasn.plate_has_asn_data(child.lpid)
  and child.status = 'A'
  and child.type = 'PA'
  and parentlpid is not null
  and not exists (select 1
                    from subtasks
                   where child.lpid = subtasks.lpid)
  and ((custitemview.lotrequired in('O','S')
  and   not exists (select 1
                      from plate parent
                     where parent.lpid = child.parentlpid
                       and parent.lotnumber is not null))
   or  custitemview.rcpt_qty_is_full_qty = 'Y')
  and exists (select 1
                from plate sibling
               where sibling.parentlpid = child.parentlpid
                 and (sibling.item != child.item
                  or nvl(sibling.lotnumber,'(none)') != nvl(child.lotnumber,'(none)')));
                     
comment on table availchildbaseview is '$Id$';

create or replace view availchildbaseviewnolot
(facility
,custid
,item
,lotnumber
,minlot
,maxlot
,invstatus
,inventoryclass
,lpid
,location
,loctype
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,weight
)
as
select
plate.facility,
plate.custid,
plate.item,
null,
null,
null,
plate.invstatus,
plate.inventoryclass,
decode(custitemview.rcpt_qty_is_full_qty,'Y',plate.lpid,plate.parentlpid),
plate.location,
location.loctype,
location.pickingzone,
min(plate.manufacturedate),
min(plate.useritem1),
min(plate.useritem2),
min(plate.useritem3),
min(plate.serialnumber),
min(plate.countryof),
min(plate.expirationdate),
min(plate.creationdate),
min(plate.anvdate),
sum(plate.quantity),
sum(plate.weight)
from location, plate, custitemview
where plate.facility = location.facility
  and plate.location = location.locid
  and plate.custid = custitemview.custid
  and plate.item = custitemview.item
  and location.status != 'O'
  and 'N' = zasn.plate_has_asn_data(plate.lpid)
  and plate.status = 'A'
  and plate.type = 'PA'
  and parentlpid is not null
  and ((plate.childfacility = location.facility
  and   plate.childitem = plate.item)
   or  (custitemview.rcpt_qty_is_full_qty = 'Y'
  and   not exists (select 1
                    from subtasks
                   where plate.parentlpid = subtasks.lpid
                     and subtasks.picktotype = 'FULL')))
  and not exists (select 1
                    from subtasks
                   where plate.lpid = subtasks.lpid)
group by plate.facility,plate.custid,plate.item,
  plate.invstatus,plate.inventoryclass,
  decode(custitemview.rcpt_qty_is_full_qty,'Y',plate.lpid,plate.parentlpid),
  plate.location,location.loctype,location.pickingzone
union all
select
child.facility,
child.custid,
child.item,
null,
null,
null,
child.invstatus,
child.inventoryclass,
decode(custitemview.rcpt_qty_is_full_qty,'Y',child.lpid,child.parentlpid),
child.location,
location.loctype,
location.pickingzone,
min(child.manufacturedate),
min(child.useritem1),
min(child.useritem2),
min(child.useritem3),
min(child.serialnumber),
min(child.countryof),
min(child.expirationdate),
min(child.creationdate),
min(child.anvdate),
sum(child.quantity -
    decode(custitemview.rcpt_qty_is_full_qty,
           'Y',nvl((select sum(qty)
                      from batchtasks
                     where batchtasks.lpid=child.lpid),0),
           0)),
sum(child.weight -
    decode(custitemview.rcpt_qty_is_full_qty,
           'Y',nvl((select sum(weight)
                      from batchtasks
                     where batchtasks.lpid=child.lpid),0),
           0))
from location, plate child, custitemview
where child.facility = location.facility
  and child.location = location.locid
  and child.custid = custitemview.custid
  and child.item = custitemview.item
  and child.childfacility is null
  and child.childitem is null
  and location.status != 'O'
  and 'N' = zasn.plate_has_asn_data(child.lpid)
  and child.status = 'A'
  and child.type = 'PA'
  and parentlpid is not null
  and not exists (select 1
                    from subtasks
                   where child.lpid = subtasks.lpid)
  and ((custitemview.lotrequired in('O','S')
  and   not exists (select 1
                      from plate parent
                     where parent.lpid = child.parentlpid
                       and (parent.item is not null
                        or parent.lotnumber is not null)))
   or  (custitemview.rcpt_qty_is_full_qty = 'Y'
  and   not exists (select 1
                    from subtasks
                   where child.parentlpid = subtasks.lpid
                     and subtasks.picktotype = 'FULL')))
group by child.facility,child.custid,child.item,
  child.invstatus,child.inventoryclass,
  decode(custitemview.rcpt_qty_is_full_qty,'Y',child.lpid,child.parentlpid),
  child.location,location.loctype,location.pickingzone;

comment on table availchildbaseviewnolot is '$Id$';

create or replace view availstatusclassbaseview
(facility
,custid
,item
,lotnumber
,minlot
,maxlot
,invstatus
,inventoryclass
,lpid
,location
,loctype
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,qtytasked
,weight
)
as
select
pl1.facility,
pl1.custid,
pl1.item,
pl1.lotnumber,
decode(pl1.type,'PA',pl1.lotnumber,
        (select min(lotnumber)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) minlot,
decode(pl1.type,'PA',pl1.lotnumber,
        (select max(lotnumber)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) maxlot,
pl1.invstatus,
pl1.inventoryclass,
pl1.lpid,
pl1.location,
location.loctype,
location.pickingzone,
decode(pl1.type,'PA',pl1.manufacturedate,
        (select min(manufacturedate)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) manufacturedate,
decode(pl1.type,'PA',pl1.useritem1,
        (select min(useritem1)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) useritem1,
decode(pl1.type,'PA',pl1.useritem2,
        (select min(useritem2)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) useritem2,
decode(pl1.type,'PA',pl1.useritem3,
        (select min(useritem3)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) useritem3,
decode(pl1.type,'PA',pl1.serialnumber,
        (select min(serialnumber)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) serialnumber,
decode(pl1.type,'PA',pl1.countryof,
        (select min(countryof)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) countryof,
decode(pl1.type,'PA',pl1.expirationdate,
        (select min(expirationdate)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) expirationdate,
pl1.creationdate,
pl1.anvdate,
pl1.quantity - nvl(pl1.qtytasked,0),
nvl(pl1.qtytasked,0),
(pl1.quantity - nvl(pl1.qtytasked,0)) * nvl(zcwt.lp_item_weight(pl1.lpid, pl1.custid, pl1.item, pl1.unitofmeasure),0)
from location, plate pl1, custitemview
where pl1.facility = location.facility
  and pl1.location = location.locid
  and pl1.custid = custitemview.custid
  and pl1.item = custitemview.item
  and custitemview.lotrequired not in('O','S')
  and location.status != 'O'
  and 'N' = zasn.plate_has_asn_data(pl1.lpid)
  and pl1.status = 'A'
  and pl1.type in ('MP','PA')
  and parentlpid is null
  and not exists (select 1
                    from subtasks
                   where pl1.lpid = subtasks.lpid
                     and tasktype in ('MV','PA'))
  and pl1.quantity > nvl(pl1.qtytasked,0)
  and (custitemview.rcpt_qty_is_full_qty <> 'Y'
   or  not exists (select 1
                     from plate
                    where plate.parentlpid = pl1.lpid))
union all
select
pl1.facility,
pl1.custid,
pl1.item,
pl1.lotnumber,
decode(pl1.type,'PA',pl1.lotnumber,
        (select min(lotnumber)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) minlot,
decode(pl1.type,'PA',pl1.lotnumber,
        (select max(lotnumber)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) maxlot,
pl1.invstatus,
pl1.inventoryclass,
pl1.lpid,
pl1.location,
location.loctype,
location.pickingzone,
decode(pl1.type,'PA',pl1.manufacturedate,
        (select min(manufacturedate)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) manufacturedate,
decode(pl1.type,'PA',pl1.useritem1,
        (select min(useritem1)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) useritem1,
decode(pl1.type,'PA',pl1.useritem2,
        (select min(useritem2)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) useritem2,
decode(pl1.type,'PA',pl1.useritem3,
        (select min(useritem3)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) useritem3,
decode(pl1.type,'PA',pl1.serialnumber,
        (select min(serialnumber)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) serialnumber,
decode(pl1.type,'PA',pl1.countryof,
        (select min(countryof)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) countryof,
decode(pl1.type,'PA',pl1.expirationdate,
        (select min(expirationdate)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) expirationdate,
pl1.creationdate,
pl1.anvdate,
pl1.quantity - nvl(pl1.qtytasked,0),
nvl(pl1.qtytasked,0),
(pl1.quantity - nvl(pl1.qtytasked,0)) * nvl(zcwt.lp_item_weight(pl1.lpid, pl1.custid, pl1.item, pl1.unitofmeasure),0)
from location, plate pl1, custitemview
where pl1.facility = location.facility
  and pl1.location = location.locid
  and pl1.custid = custitemview.custid
  and pl1.item = custitemview.item
  and custitemview.lotrequired in('O','S')
  and (pl1.lotnumber is not null
   or  pl1.type = 'PA')
  and location.status != 'O'
  and 'N' = zasn.plate_has_asn_data(pl1.lpid)
  and pl1.status = 'A'
  and pl1.type in ('MP','PA')
  and parentlpid is null
  and not exists (select 1
                    from subtasks
                   where pl1.lpid = subtasks.lpid
                     and tasktype in ('MV','PA'))
  and pl1.quantity > nvl(pl1.qtytasked,0)
  and (custitemview.rcpt_qty_is_full_qty <> 'Y'
   or  not exists (select 1
                     from plate
                    where plate.parentlpid = pl1.lpid));

comment on table availstatusclassbaseview is '$Id$';

create or replace view availstatusclassbaseviewnolot
(facility
,custid
,item
,lotnumber
,minlot
,maxlot
,invstatus
,inventoryclass
,lpid
,location
,loctype
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,qtytasked
,weight
)
as
select
pl1.facility,
pl1.custid,
pl1.item,
null,
null,
null,
pl1.invstatus,
pl1.inventoryclass,
pl1.lpid,
pl1.location,
location.loctype,
location.pickingzone,
decode(pl1.type,'PA',pl1.manufacturedate,
        (select min(manufacturedate)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) manufacturedate,
decode(pl1.type,'PA',pl1.useritem1,
        (select min(useritem1)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) useritem1,
decode(pl1.type,'PA',pl1.useritem2,
        (select min(useritem2)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) useritem2,
decode(pl1.type,'PA',pl1.useritem3,
        (select min(useritem3)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) useritem3,
decode(pl1.type,'PA',pl1.serialnumber,
        (select min(serialnumber)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) serialnumber,
decode(pl1.type,'PA',pl1.countryof,
        (select min(countryof)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) countryof,
decode(pl1.type,'PA',pl1.expirationdate,
        (select min(expirationdate)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) expirationdate,
pl1.creationdate,
pl1.anvdate,
pl1.quantity - nvl(pl1.qtytasked,0),
nvl(pl1.qtytasked,0),
(pl1.quantity - nvl(pl1.qtytasked,0)) * nvl(zcwt.lp_item_weight(pl1.lpid, pl1.custid, pl1.item, pl1.unitofmeasure),0)
from location, plate pl1, custitemview
where pl1.facility = location.facility
  and pl1.location = location.locid
  and pl1.custid = custitemview.custid
  and pl1.item = custitemview.item
  and custitemview.lotrequired not in('O','S')
  and location.status != 'O'
  and 'N' = zasn.plate_has_asn_data(pl1.lpid)
  and pl1.status = 'A'
  and pl1.type in ('MP','PA')
  and parentlpid is null
  and not exists (select 1
                    from subtasks
                   where pl1.lpid = subtasks.lpid
                     and tasktype in ('MV','PA'))
  and pl1.quantity > nvl(pl1.qtytasked,0)
  and (custitemview.rcpt_qty_is_full_qty <> 'Y'
   or  not exists (select 1
                     from plate
                    where plate.parentlpid = pl1.lpid))
union all
select
pl1.facility,
pl1.custid,
pl1.item,
null,
null,
null,
pl1.invstatus,
pl1.inventoryclass,
pl1.lpid,
pl1.location,
location.loctype,
location.pickingzone,
decode(pl1.type,'PA',pl1.manufacturedate,
        (select min(manufacturedate)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) manufacturedate,
decode(pl1.type,'PA',pl1.useritem1,
        (select min(useritem1)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) useritem1,
decode(pl1.type,'PA',pl1.useritem2,
        (select min(useritem2)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) useritem2,
decode(pl1.type,'PA',pl1.useritem3,
        (select min(useritem3)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) useritem3,
decode(pl1.type,'PA',pl1.serialnumber,
        (select min(serialnumber)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) serialnumber,
decode(pl1.type,'PA',pl1.countryof,
        (select min(countryof)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) countryof,
decode(pl1.type,'PA',pl1.expirationdate,
        (select min(expirationdate)
         from plate
         where type = 'PA'
         start with lpid = pl1.lpid
         connect by prior lpid = parentlpid)) expirationdate,
pl1.creationdate,
pl1.anvdate,
pl1.quantity - nvl(pl1.qtytasked,0),
nvl(pl1.qtytasked,0),
(pl1.quantity - nvl(pl1.qtytasked,0)) * nvl(zcwt.lp_item_weight(pl1.lpid, pl1.custid, pl1.item, pl1.unitofmeasure),0)
from location, plate pl1, custitemview
where pl1.facility = location.facility
  and pl1.location = location.locid
  and pl1.custid = custitemview.custid
  and pl1.item = custitemview.item
  and custitemview.lotrequired in('O','S')
  and (pl1.lotnumber is not null
   or  pl1.type = 'PA')
  and location.status != 'O'
  and 'N' = zasn.plate_has_asn_data(pl1.lpid)
  and pl1.status = 'A'
  and pl1.type in ('MP','PA')
  and parentlpid is null
  and not exists (select 1
                    from subtasks
                   where pl1.lpid = subtasks.lpid
                     and tasktype in ('MV','PA'))
  and pl1.quantity > nvl(pl1.qtytasked,0)
  and (custitemview.rcpt_qty_is_full_qty <> 'Y'
   or not exists (select 1
                    from plate
                   where plate.parentlpid = pl1.lpid));

comment on table availstatusclassbaseviewnolot is '$Id$';

create or replace view availchildview
(facility
,custid
,item
,lotnumber
,minlot
,maxlot
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,weight
)
as
select
facility
,custid
,item
,lotnumber
,minlot
,maxlot
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,weight
from availchildbaseview a1
where loctype = 'STO'
  and not exists (select 1
                    from itempickfronts
                   where facility = a1.facility
                     and pickfront = a1.location
                     and custid = a1.custid
                     and item = a1.item);

comment on table availchildview is '$Id$';

create or replace view availchildviewnolot
(facility
,custid
,item
,lotnumber
,minlot
,maxlot
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,weight
)
as
select
facility
,custid
,item
,null
,null
,null
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,weight
from availchildbaseviewnolot a1
where loctype = 'STO'
  and not exists (select 1
                    from itempickfronts
                   where facility = a1.facility
                     and pickfront = a1.location
                     and custid = a1.custid
                     and item = a1.item);

comment on table availchildviewnolot is '$Id$';

create or replace view availstatusclassview
(facility
,custid
,item
,lotnumber
,minlot
,maxlot
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,qtytasked
,weight
)
as
select
facility
,custid
,item
,lotnumber
,minlot
,maxlot
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,qtytasked
,weight
from availstatusclassbaseview a1
where loctype = 'STO'
  and not exists (select 1
                    from itempickfronts
                   where facility = a1.facility
                     and pickfront = a1.location
                     and custid = a1.custid
                     and item = a1.item)
union all
select
 acv.facility
,acv.custid
,acv.item
,acv.lotnumber
,acv.minlot
,acv.maxlot
,acv.invstatus
,acv.inventoryclass
,acv.lpid
,acv.location
,acv.pickingzone
,acv.manufacturedate
,acv.useritem1
,acv.useritem2
,acv.useritem3
,acv.serialnumber
,acv.countryof
,acv.expirationdate
,acv.creationdate
,acv.anvdate
,acv.quantity - zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item)
,zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item)
,(acv.quantity - zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item)) * nvl(zcwt.lp_item_weight(acv.lpid, acv.custid, acv.item, ci.baseuom),0)
from availchildview acv, custitem ci
where acv.custid = ci.custid
and acv.item = ci.item
and acv.quantity > zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item);

comment on table availstatusclassview is '$Id$';

create or replace view availstatusclassviewnolot
(facility
,custid
,item
,lotnumber
,minlot
,maxlot
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,qtytasked
,weight
)
as
select
facility
,custid
,item
,null
,null
,null
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,qtytasked
,weight
from availstatusclassbaseviewnolot a1
where loctype = 'STO'
  and not exists (select 1
                    from itempickfronts
                   where facility = a1.facility
                     and pickfront = a1.location
                     and custid = a1.custid
                     and item = a1.item)
union all
select
 acv.facility
,acv.custid
,acv.item
,null
,null
,null
,acv.invstatus
,acv.inventoryclass
,acv.lpid
,acv.location
,acv.pickingzone
,acv.manufacturedate
,acv.useritem1
,acv.useritem2
,acv.useritem3
,acv.serialnumber
,acv.countryof
,acv.expirationdate
,acv.creationdate
,acv.anvdate
,acv.quantity - zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item)
,zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item)
,(acv.quantity - zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item)) * nvl(zcwt.lp_item_weight(acv.lpid, acv.custid, acv.item, ci.baseuom),0)
from availchildviewnolot acv, custitem ci
where acv.custid = ci.custid
and acv.item = ci.item
and acv.quantity > zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item);

comment on table availstatusclassviewnolot is '$Id$';

create or replace view availstagechildview
(facility
,custid
,item
,lotnumber
,minlot
,maxlot
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,weight
)
as
select
facility
,custid
,item
,lotnumber
,minlot
,maxlot
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,weight
from availchildbaseview
where loctype = 'STG';

comment on table availstagechildview is '$Id$';

create or replace view availstagechildviewnolot
(facility
,custid
,item
,lotnumber
,minlot
,maxlot
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,weight
)
as
select
facility
,custid
,item
,null
,null
,null
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,weight
from availchildbaseviewnolot
where loctype = 'STG';

comment on table availstagechildviewnolot is '$Id$';

create or replace view availstagestatusclassview
(facility
,custid
,item
,lotnumber
,minlot
,maxlot
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,qtytasked
,weight
)
as
select
facility
,custid
,item
,lotnumber
,minlot
,maxlot
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,qtytasked
,weight
from availstatusclassbaseview
where loctype = 'STG'
union all
select
 acv.facility
,acv.custid
,acv.item
,acv.lotnumber
,acv.minlot
,acv.maxlot
,acv.invstatus
,acv.inventoryclass
,acv.lpid
,acv.location
,acv.pickingzone
,acv.manufacturedate
,acv.useritem1
,acv.useritem2
,acv.useritem3
,acv.serialnumber
,acv.countryof
,acv.expirationdate
,acv.creationdate
,acv.anvdate
,acv.quantity - zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item)
,zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item)
,(acv.quantity - zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item)) * nvl(zcwt.lp_item_weight(acv.lpid, acv.custid, acv.item, ci.baseuom),0)
from availstagechildview acv, custitem ci
where acv.custid = ci.custid
and acv.item = ci.item
and acv.quantity > zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item);

comment on table availstagestatusclassview is '$Id$';

create or replace view availstagestatusclassviewnolot
(facility
,custid
,item
,lotnumber
,minlot
,maxlot
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,qtytasked
,weight
)
as
select
facility
,custid
,item
,null
,null
,null
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,qtytasked
,weight
from availstatusclassbaseviewnolot
where loctype = 'STG'
union all
select
 acv.facility
,acv.custid
,acv.item
,null
,null
,null
,acv.invstatus
,acv.inventoryclass
,acv.lpid
,acv.location
,acv.pickingzone
,acv.manufacturedate
,acv.useritem1
,acv.useritem2
,acv.useritem3
,acv.serialnumber
,acv.countryof
,acv.expirationdate
,acv.creationdate
,acv.anvdate
,quantity - zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item)
,zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item)
,(acv.quantity - zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item)) * nvl(zcwt.lp_item_weight(acv.lpid, acv.custid, acv.item, ci.baseuom),0)
from availstagechildviewnolot acv, custitem ci
where acv.custid = ci.custid
and acv.item = ci.item
and acv.quantity > zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item);

comment on table availstagestatusclassviewnolot is '$Id$';

create or replace view availpfchildview
(facility
,custid
,item
,lotnumber
,minlot
,maxlot
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,weight
)
as
select
facility
,custid
,item
,lotnumber
,minlot
,maxlot
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,weight
from availchildbaseview
where loctype = 'PF';

comment on table availpfchildview is '$Id$';

create or replace view availpfchildviewnolot
(facility
,custid
,item
,lotnumber
,minlot
,maxlot
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,weight
)
as
select
facility
,custid
,item
,null
,null
,null
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,weight
from availchildbaseviewnolot
where loctype = 'PF';

comment on table availpfchildviewnolot is '$Id$';

create or replace view availpfstatusclassview
(facility
,custid
,item
,lotnumber
,minlot
,maxlot
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,qtytasked
,weight
)
as
select
facility
,custid
,item
,lotnumber
,minlot
,maxlot
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,qtytasked
,weight
from availstatusclassbaseview
where loctype = 'PF'
union all
select
 acv.facility
,acv.custid
,acv.item
,acv.lotnumber
,acv.minlot
,acv.maxlot
,acv.invstatus
,acv.inventoryclass
,acv.lpid
,acv.location
,acv.pickingzone
,acv.manufacturedate
,acv.useritem1
,acv.useritem2
,acv.useritem3
,acv.serialnumber
,acv.countryof
,acv.expirationdate
,acv.creationdate
,acv.anvdate
,acv.quantity - zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item)
,zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item)
,(acv.quantity - zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item)) * nvl(zcwt.lp_item_weight(acv.lpid, acv.custid, acv.item, ci.baseuom),0)
from availpfchildview acv, custitem ci
where acv.custid = ci.custid
and acv.item = ci.item
and acv.quantity > zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item);

comment on table availpfstatusclassview is '$Id$';

create or replace view availpfstatusclassviewnolot
(facility
,custid
,item
,lotnumber
,minlot
,maxlot
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,qtytasked
,weight
)
as
select
facility
,custid
,item
,null
,null
,null
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,qtytasked
,weight
from availstatusclassbaseviewnolot
where loctype = 'PF'
union all
select
 acv.facility
,acv.custid
,acv.item
,null
,null
,null
,acv.invstatus
,acv.inventoryclass
,acv.lpid
,acv.location
,acv.pickingzone
,acv.manufacturedate
,acv.useritem1
,acv.useritem2
,acv.useritem3
,acv.serialnumber
,acv.countryof
,acv.expirationdate
,acv.creationdate
,acv.anvdate
,acv.quantity - zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item)
,zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item)
,(acv.quantity - zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item)) * nvl(zcwt.lp_item_weight(acv.lpid, acv.custid, acv.item, ci.baseuom),0)
from availpfchildviewnolot acv, custitem ci
where acv.custid = ci.custid
and acv.item = ci.item
and acv.quantity > zwv.subtask_total_by_lip(acv.lpid,acv.custid,acv.item);

comment on table availpfstatusclassviewnolot is '$Id$';

create or replace view availstatusplateselectview
(facility
,custid
,item
,lotnumber
,invstatus
,inventoryclass
,lpid
,location
,pickingzone
,manufacturedate
,useritem1
,useritem2
,useritem3
,serialnumber
,countryof
,expirationdate
,creationdate
,anvdate
,quantity
,qtytasked
,weight
)
as
select
plate.facility,
plate.custid,
plate.item,
plate.lotnumber,
plate.invstatus,
plate.inventoryclass,
plate.lpid,
plate.location,
location.pickingzone,
plate.manufacturedate,
plate.useritem1,
plate.useritem2,
plate.useritem3,
plate.serialnumber,
plate.countryof,
plate.expirationdate,
plate.creationdate,
plate.anvdate,
plate.quantity,
plate.qtytasked,
plate.weight
from plate, location
where plate.facility = location.facility
  and plate.location = location.locid
  and location.status != 'O'
  and 'N' = zasn.plate_has_asn_data(plate.lpid)
  and plate.status = 'A'
  and plate.type = 'PA'
  and location.loctype = 'STO'
  and nvl(quantity,0) - nvl(qtytasked,0) > 0
  and not exists (select 1
                    from subtasks
                  where plate.lpid = subtasks.lpid
                    and tasktype in ('PA','MV'));

comment on table availstatusplateselectview is '$Id$';

create or replace view availpickfrontfifoview
(facility
,custid
,item
,pickuom
,pickfront
,pickingzone
,subtask_total
,location_lastupdate
,dynamic
,minmfgdate
,maxmfgdate
,minexpdate
,maxexpdate
,mincrtdate
,maxcrtdate
,minlotnumber
,maxlotnumber
)
as
  select facility,
         custid,
         item,
         pickuom,
         pickfront,
         pickingzone,
         zwv.subtask_total(facility,
                       pickfront,item) subtask_total,
         zwv.location_lastupdate(facility,
                       pickfront) location_lastupdate,
         nvl(dynamic,'N') dynamic,
         (select min(trunc(manufacturedate))
            from plate
           where facility = ipf.facility
             and location = ipf.pickfront
             and custid = ipf.custid
             and item = ipf.item
             and status = 'A') minmfgdate,
         (select max(trunc(manufacturedate))
            from plate
           where facility = ipf.facility
             and location = ipf.pickfront
             and custid = ipf.custid
             and item = ipf.item
             and status = 'A') maxmfgdate,
         (select min(trunc(expirationdate))
            from plate
           where facility = ipf.facility
             and location = ipf.pickfront
             and custid = ipf.custid
             and item = ipf.item
             and status = 'A') minexpdate,
         (select max(trunc(expirationdate))
            from plate
           where facility = ipf.facility
             and location = ipf.pickfront
             and custid = ipf.custid
             and item = ipf.item
             and status = 'A') maxexpdate,
         (select min(least(trunc(creationdate),nvl(trunc(anvdate),trunc(creationdate))))
            from plate
           where facility = ipf.facility
             and location = ipf.pickfront
             and custid = ipf.custid
             and item = ipf.item
             and status = 'A') mincrtdate,
         (select max(least(trunc(creationdate),nvl(trunc(anvdate),trunc(creationdate))))
            from plate
           where facility = ipf.facility
             and location = ipf.pickfront
             and custid = ipf.custid
             and item = ipf.item
             and status = 'A') maxcrtdate,
         (select min(lotnumber)
            from plate
           where facility = ipf.facility
             and location = ipf.pickfront
             and custid = ipf.custid
             and item = ipf.item
             and lotnumber is not null
             and status = 'A') minlotnumber,
         (select max(lotnumber)
            from plate
           where facility = ipf.facility
             and location = ipf.pickfront
             and custid = ipf.custid
             and item = ipf.item
             and lotnumber is not null
             and status = 'A') maxlotnumber
    from itempickfrontsview ipf
   where locationstatus != 'O'
     and pickfront is not null;

comment on table availpickfrontfifoview is '$Id$';

exit;
