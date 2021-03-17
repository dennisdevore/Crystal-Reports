create or replace view invadjactivityview
(whenoccurred
,lpid
,facility
,custid
,item
,lotnumber
,inventoryclass
,invstatus
,uom
,adjqty
,adjreason
,tasktype
,adjuser
,lastuser
,lastupdate
,itemdescr
,adjusername
,adjreasonabbrev
,adjreasondescr
,company
,warehouse
,serialnumber
,useritem1
,useritem2
,useritem3
,adjweight
,adjcube
,custreference
,adjweight_kgs
,suppress_edi_yn
,comments
)
as
select
invadjactivity.whenoccurred,
invadjactivity.lpid,
invadjactivity.facility,
invadjactivity.custid
,invadjactivity.item
,invadjactivity.lotnumber
,invadjactivity.inventoryclass
,invadjactivity.invstatus
,invadjactivity.uom
,invadjactivity.adjqty
,invadjactivity.adjreason
,invadjactivity.tasktype
,invadjactivity.adjuser
,invadjactivity.lastuser
,invadjactivity.lastupdate
,custitem.descr
,userheader.username
,adjustmentreasons.abbrev
,adjustmentreasons.descr
,'CMP'
,'WHSE'
,invadjactivity.serialnumber
,invadjactivity.useritem1
,invadjactivity.useritem2
,invadjactivity.useritem3
,nvl(invadjactivity.adjweight, invadjactivity.adjqty * nvl(custitem.weight,0))
,invadjactivity.adjqty * nvl(custitem.cube,0)
,custreference
,zwt.from_lbs_to_kgs(invadjactivity.custid,invadjactivity.adjweight)
,invadjactivity.suppress_edi_yn
,invadjactivity.comments
from custitem, userheader, adjustmentreasons, invadjactivity
where invadjactivity.custid = custitem.custid(+)
and invadjactivity.item = custitem.item(+)
and invadjactivity.adjuser = userheader.nameid(+)
and invadjactivity.adjreason = adjustmentreasons.code(+);

comment on table invadjactivityview is '$Id$';

create or replace view pho_invadjactivityview
(whenoccurred
,lpid
,facility
,custid
,item
,lotnumber
,inventoryclass
,invstatus
,uom
,adjqty
,adjreason
,tasktype
,adjuser
,lastuser
,lastupdate
,itemdescr
,adjusername
,adjreasonabbrev
,adjreasondescr
,company
,warehouse
,serialnumber
,useritem1
,useritem2
,useritem3
,adjweight
,adjcube
,custreference
,adjweight_kgs
,adjqtypcs
,adjqtyctn
,suppress_edi_yn
,campus
)
as
select
invadjactivity.whenoccurred,
invadjactivity.lpid,
invadjactivity.facility,
invadjactivity.custid
,invadjactivity.item
,invadjactivity.lotnumber
,invadjactivity.inventoryclass
,invadjactivity.invstatus
,invadjactivity.uom
,invadjactivity.adjqty
,invadjactivity.adjreason
,invadjactivity.tasktype
,invadjactivity.adjuser
,invadjactivity.lastuser
,invadjactivity.lastupdate
,custitem.descr
,userheader.username
,adjustmentreasons.abbrev
,adjustmentreasons.descr
,'CMP'
,'WHSE'
,invadjactivity.serialnumber
,invadjactivity.useritem1
,invadjactivity.useritem2
,invadjactivity.useritem3
,nvl(invadjactivity.adjweight, invadjactivity.adjqty * nvl(custitem.weight,0))
,invadjactivity.adjqty * nvl(custitem.cube,0)
,custreference
,zwt.from_lbs_to_kgs(invadjactivity.custid,invadjactivity.adjweight)
,zlbl.uom_qty_conv(invadjactivity.custid,invadjactivity.item,invadjactivity.adjqty,invadjactivity.uom,'PCS')
,zlbl.uom_qty_conv(invadjactivity.custid,invadjactivity.item,invadjactivity.adjqty,invadjactivity.uom,'CTN'),
invadjactivity.suppress_edi_yn,
facility.campus
from invadjactivity, custitem, userheader, adjustmentreasons, facility
where invadjactivity.custid = custitem.custid(+)
and invadjactivity.item = custitem.item(+)
and invadjactivity.adjuser = userheader.nameid(+)
and invadjactivity.adjreason = adjustmentreasons.code(+)
and invadjactivity.facility = facility.facility;

comment on table pho_invadjactivityview is '$Id$';

exit;
