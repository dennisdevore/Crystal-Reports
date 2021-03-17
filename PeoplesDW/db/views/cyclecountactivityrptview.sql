create or replace view cyclecountactivityrptview
(
 FACILITY
,LOCATION
,LPID
,CUSTID
,ITEM
,LOTNUMBER
,UOM
,QUANTITY
,ENTLOCATION
,ENTCUSTID
,ENTITEM
,ENTLOTNUMBER
,ENTQUANTITY
,TASKID
,ADJUSTMENTTYPE
,WHENOCCURRED
,LASTUSER
,LASTUPDATE
)
as
select
 facility
, location
, lpid
, custid
, item
, lotnumber
, uom
, quantity
, entlocation
, entcustid
, entitem
, entlotnumber
, entquantity
, taskid
, adjustmenttype
, whenoccurred
, lastuser
, lastupdate
from cyclecountactivity cc1
where lpid is not null
   or nvl(cc1.quantity,0) <> nvl((
      select sum(cc2.quantity)
        from cyclecountactivity cc2
       where cc2.taskid = cc1.taskid
         and nvl(cc2.custid,'(none)') = nvl(cc1.custid,'(none)')
         and nvl(cc2.item,'(none)') = nvl(cc1.item,'(none)')
         and nvl(cc2.lotnumber,'(none)') = nvl(cc1.lotnumber,'(none)')
         and cc2.facility = cc1.facility
         and nvl(cc2.location,'(none)') = nvl(cc1.location,'(none)')
         and nvl(cc2.uom,'(none)') = nvl(cc1.uom,'(none)')
         and nvl(cc2.entlocation,'(none)') = nvl(cc1.entlocation,'(none)')
         and nvl(cc2.entcustid,'(none)') = nvl(cc1.entcustid,'(none)')
         and nvl(cc2.entitem,'(none)') = nvl(cc1.entitem,'(none)')
         and nvl(cc2.entlotnumber,'(none)') = nvl(cc1.entlotnumber,'(none)')
         and cc2.adjustmenttype = cc1.adjustmenttype
         and cc2.lpid is not null),0);
   
comment on table cyclecountactivityrptview is '$Id$';
   
exit;
