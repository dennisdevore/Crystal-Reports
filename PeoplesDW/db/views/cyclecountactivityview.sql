create or replace view cyclecountactivityview
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
,CUSTIDKEY
,ITEMKEY
)
as
select
 FACILITY
, LOCATION
, LPID
, CUSTID
, ITEM
, LOTNUMBER
, UOM
, QUANTITY
, ENTLOCATION
, ENTCUSTID
, ENTITEM
, ENTLOTNUMBER
, ENTQUANTITY
, TASKID
, ADJUSTMENTTYPE
, WHENOCCURRED
, LASTUSER
, LASTUPDATE
, nvl(custid,entcustid)
, nvl(item,entitem)
from cyclecountactivity
where nvl(custid,entcustid) = nvl(entcustid,custid)
  and nvl(item,entitem) = nvl(entitem,item)
union all
select
 FACILITY
, LOCATION
, LPID
, CUSTID
, ITEM
, LOTNUMBER
, UOM
, QUANTITY
, nvl(ENTLOCATION,LOCATION)
, nvl(ENTCUSTID,custid)
, nvl(ENTITEM,item)
, nvl(ENTLOTNUMBER,lotnumber)
, nvl(ENTQUANTITY,quantity)
, TASKID
, ADJUSTMENTTYPE
, WHENOCCURRED
, LASTUSER
, LASTUPDATE
, custid
, item
from cyclecountactivity
where nvl(custid,entcustid) != nvl(entcustid,custid)
   or nvl(item,entitem) != nvl(entitem,item)
union all
select
 FACILITY
, LOCATION
, LPID
, CUSTID
, ITEM
, LOTNUMBER
, UOM
, 0
, nvl(ENTLOCATION,LOCATION)
, nvl(ENTCUSTID,custid)
, nvl(ENTITEM,item)
, nvl(ENTLOTNUMBER,lotnumber)
, ENTQUANTITY
, TASKID
, ADJUSTMENTTYPE
, WHENOCCURRED
, LASTUSER
, LASTUPDATE
, entcustid
, entitem
from cyclecountactivity
where custid is null
and entcustid is null
and entitem is null
and item is null;

comment on table cyclecountactivityview is '$Id$';
   
exit;
