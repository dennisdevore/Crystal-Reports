drop table invaccrpt;

create table invaccrpt
(sessionid             number
,facility              varchar2(3)
,custid                varchar2(10)
,beginningbalance      number(17)
,adjusteditems         number(10)
,adjustmentqty         number(17)
,totaladjustments      number(10)
,totallines            number(10)
,receiptcount          number(10)
,shipmentcount         number(10)
,transactioncount      number(10)
,totalquantityshipped  number(17)
,totalquantityreceived number(17)
,uniqueitems           number(10)
,uniquelots            number(10)
,endingbalance         number(17)
,lastupdate            date
);

create index invaccrpt_sessionid_idx
 on invaccrpt(sessionid);

create index invaccrpt_lastupdate_idx
 on invaccrpt(lastupdate);

create or replace package INVACCRPTPKG
as type iar_type is ref cursor return invaccrpt%rowtype;
end INVACCRPTPKG;
/

create or replace procedure INVACCRPTPROC
(iar_cursor IN OUT INVACCRPTPKG.iar_type
,in_facility IN varchar2
,in_custid IN varchar2
,in_begdate IN date
,in_enddate IN date)
as

lBegDate date;
lEndDate date;

cursor curFacility is
  select facility
    from facility fa
   where (instr(','||upper(in_facility)||',', ','||facility||',', 1, 1) > 0
      or  upper(in_facility)='ALL')
     and facilitystatus='A'
     and exists(select 1
                  from asofinventory
                 where facility = fa.facility
                   and effdate < lEndDate
                   and rownum = 1);
cf curFacility%rowtype;

cursor curCustomer(in_facility varchar2) is
  select custid,name,addr1,addr2,city,state,postalcode
    from customer cu
   where (instr(','||upper(in_custid)||',', ','||custid||',', 1, 1) > 0
      or upper(in_custid)='ALL')
     and status='ACTV'
     and exists(select 1
                  from asofinventory
                 where facility = in_facility
                   and custid = cu.custid
                   and effdate < lEndDate
                   and rownum = 1);
cu curCustomer%rowtype;

cursor curCustItems(in_custid varchar2, in_facility varchar2) is
  select item,descr,status,upper(nvl(hazardous,'N')) hazardous
    from custitem ci
   where custid = in_custid
     and exists(select 1
                  from asofinventory
                 where facility = in_facility
                   and custid = in_custid
                   and item = ci.item
                   and effdate < lEndDate
                   and rownum = 1);

cursor curAsOf(in_facility IN varchar2, in_custid IN varchar2, in_item IN varchar2) is
  select distinct uom,inventoryclass,invstatus,lotnumber
    from asofinventory
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and effdate < lEndDate;
cao curAsOf%rowtype;
   
cursor curAsOfBeginSearch(in_facility IN varchar2, in_custid IN varchar2, in_item IN varchar2,
  in_uom IN varchar2, in_inventoryclass IN varchar2, in_invstatus IN varchar2, in_lotnumber IN varchar2) is
select nvl(currentqty,0) as currentqty
  from asofinventory aoi1,
  (select max(effdate) effdate
     from asofinventory aoi2
    where facility = in_facility
      and custid = in_custid
      and item = in_item
      and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
      and uom = in_uom
      and effdate < lBegDate
      and inventoryclass = in_inventoryclass
      and invstatus = in_invstatus) aoi2
 where facility = in_facility
   and custid = in_custid
   and item = in_item
   and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
   and uom = in_uom
   and aoi1.effdate = aoi2.effdate
   and inventoryclass = in_inventoryclass
   and invstatus = in_invstatus
   and nvl(currentqty,0) <> 0
 union all
select 0 as currentqty
  from asofinventory aoi1,
  (select min(effdate) effdate
     from asofinventory aoi2
    where facility = in_facility
      and custid = in_custid
      and item = in_item
      and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
      and uom = in_uom
      and effdate >= lBegDate
      and effdate < lEndDate
      and inventoryclass = in_inventoryclass
      and invstatus = in_invstatus) aoi2
 where facility = in_facility
   and custid = in_custid
   and item = in_item
   and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
   and uom = in_uom
   and aoi1.effdate = aoi2.effdate
   and inventoryclass = in_inventoryclass
   and invstatus = in_invstatus
   and nvl(previousqty,0) = 0;
aob curAsOfBeginSearch%rowtype;

cursor curAsOfEndSearch(in_facility IN varchar2, in_custid IN varchar2, in_item IN varchar2, in_uom IN varchar2, in_invstatus IN varchar2, in_inventoryclass IN varchar2, in_lotnumber IN varchar2) is
select nvl(aoi1.currentqty,0) as currentqty
     from asofinventory aoi1,
     (select max(effdate) effdate
        from asofinventory
       where facility = in_facility
         and custid = in_custid
         and item = in_item
         and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
         and uom = in_uom
         and effdate < lEndDate
         and inventoryclass = in_inventoryclass
         and invstatus = in_invstatus) aoi2
     where facility = in_facility
       and custid = in_custid
       and item = in_item
       and nvl(aoi1.lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
       and uom = in_uom
       and aoi1.effdate = aoi2.effdate
       and inventoryclass = in_inventoryclass
       and invstatus = in_invstatus;
aoe curAsOfEndSearch%rowtype;

cursor curAdjustments(in_facility varchar2, in_custid varchar2) is
select count(distinct item) items, sum(nvl(adjqty,0)) qty,
       count(distinct lpid) adjustments, count(distinct lotnumber) lines
  from invadjactivity
 where whenoccurred >= lBegDate
   and whenoccurred < lEndDate
   and facility = in_facility
   and custid = in_custid;
adj curAdjustments%rowtype;

cursor curShipments(in_facility varchar2, in_custid varchar2) is
select count(distinct oh.orderid) orders, sum(nvl(od.qtyship,0)) qtyship
  from orderhdr oh, orderdtl od
 where oh.fromfacility = in_facility
   and oh.custid = in_custid
   and oh.orderstatus = '9'
   and oh.dateshipped >= lBegDate
   and oh.dateshipped < lEndDate
   and od.orderid = oh.orderid
   and od.shipid = oh.shipid;
shp curShipments%rowtype;
   
cursor curReceipts(in_facility varchar2, in_custid varchar2) is
select count(distinct oh.orderid) orders, sum(nvl(od.qtyrcvd,0)) qtyrcvd
  from orderhdr oh, orderdtl od
 where oh.tofacility = in_facility
   and oh.custid = in_custid
   and oh.orderstatus = 'R'
   and oh.statusupdate >= lBegDate
   and oh.statusupdate < lEndDate
   and od.orderid = oh.orderid
   and od.shipid = oh.shipid;
rcp curReceipts%rowtype;
   
cursor curAsOfItems(in_facility varchar2, in_custid varchar2) is
select count(distinct item) items, count(distinct lotnumber) lots
from(
  select item, lotnumber
    from asofinventory aoi1
   where facility = in_facility
     and custid = in_custid
     and nvl(currentqty,0) <> 0
     and effdate =
    (select max(effdate) effdate
       from asofinventory
      where facility = in_facility
        and custid = in_custid
        and item = aoi1.item
        and nvl(lotnumber,'(none)') = nvl(aoi1.lotnumber,'(none)')
        and uom = aoi1.uom
        and effdate < lBegDate
        and inventoryclass = aoi1.inventoryclass
        and invstatus = aoi1.invstatus)
   union all
  select item, lotnumber
    from asofinventory
   where facility = in_facility
     and custid = in_custid
     and effdate >= lBegDate
     and effdate < lEndDate);
aoi curAsOfItems%rowtype;
   
numSessionId number;
dtlCount integer;
wrk invaccrpt%rowtype;

begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from asofinvact
where sessionid = numSessionId;
commit;

delete from asofinvact
where lastupdate < trunc(sysdate);
commit;

select count(1)
into dtlCount
from asofinvact
where lastupdate < sysdate;

if dtlCount = 0 then
  EXECUTE IMMEDIATE 'truncate table asofinvact';
end if;

delete from invaccrpt
where sessionid = numSessionId;
commit;

delete from invaccrpt
where lastupdate < trunc(sysdate);
commit;

select count(1)
into dtlCount
from invaccrpt
where lastupdate < sysdate;

if dtlCount = 0 then
  EXECUTE IMMEDIATE 'truncate table invaccrpt';
end if;


lBegDate := in_begdate;
lEndDate := in_enddate;

for cf in curFacility
loop
  for cu in curCustomer(cf.facility)
  loop
    wrk.beginningbalance := 0;
    wrk.adjusteditems := 0;
    wrk.adjustmentqty := 0;
    wrk.totaladjustments := 0;
    wrk.totallines := 0;
    wrk.receiptcount := 0;
    wrk.shipmentcount := 0;
    wrk.transactioncount := 0;
    wrk.totalquantityshipped := 0;
    wrk.totalquantityreceived := 0;
    wrk.uniqueitems := 0;
    wrk.uniquelots := 0;
    wrk.endingbalance := 0;
    
    for cit in curCustItems(cu.custid, cf.facility)
    loop
      for cao in curAsOf(cf.facility, cu.custid, cit.item)
      loop
        for aob in curAsOfBeginSearch(cf.facility, cu.custid, cit.item, cao.uom, cao.inventoryclass, cao.invstatus, cao.lotnumber)
        loop
          if aob.currentqty is null then
            goto skip_to_next;
          end if;

          wrk.beginningbalance := wrk.beginningbalance + aob.currentqty;
          
          aoe := null;
          open curAsOfEndSearch(cf.facility, cu.custid, cit.item, cao.uom, cao.invstatus, cao.inventoryclass, cao.lotnumber);
          fetch curAsOfEndSearch into aoe;
          close curAsOfEndSearch;
  
          wrk.endingbalance := wrk.endingbalance + aoe.currentqty;
<< skip_to_next >>
          null;
        end loop;
      end loop;
    end loop;
    
    adj := null;
    open curAdjustments(cf.facility, cu.custid);
    fetch curAdjustments into adj;
    close curAdjustments;

    wrk.adjusteditems := wrk.adjusteditems + nvl(adj.items,0);
    wrk.adjustmentqty := wrk.adjustmentqty + nvl(adj.qty,0);
    wrk.totaladjustments := wrk.totaladjustments + nvl(adj.adjustments,0);
    wrk.totallines := wrk.totallines + nvl(adj.lines,0);
    
    rcp := null;
    open curReceipts(cf.facility, cu.custid);
    fetch curReceipts into rcp;
    close curReceipts;

    wrk.receiptcount := wrk.receiptcount + nvl(rcp.orders,0);
    wrk.totalquantityreceived := wrk.totalquantityreceived + nvl(rcp.qtyrcvd,0);
    
    shp := null;
    open curShipments(cf.facility, cu.custid);
    fetch curShipments into shp;
    close curShipments;

    wrk.shipmentcount := wrk.shipmentcount + nvl(shp.orders,0);
    wrk.totalquantityshipped := wrk.totalquantityshipped + nvl(shp.qtyship,0);

    wrk.transactioncount := wrk.transactioncount + nvl(rcp.orders,0) + nvl(shp.orders,0);
    
    aoi := null;
    open curAsOfItems(cf.facility, cu.custid);
    fetch curAsOfItems into aoi;
    close curAsOfItems;

    wrk.uniqueitems := wrk.uniqueitems + nvl(aoi.items,0);
    wrk.uniquelots := wrk.uniquelots + nvl(aoi.lots,0);

    insert into invaccrpt
    (sessionid, facility, custid, beginningbalance, adjusteditems, adjustmentqty,
     totaladjustments, totallines, receiptcount, shipmentcount,
     transactioncount, totalquantityshipped, totalquantityreceived,
     uniqueitems, uniquelots, endingbalance, lastupdate)
    values
    (numSessionId, cf.facility, cu.custid, wrk.beginningbalance, wrk.adjusteditems, wrk.adjustmentqty,
     wrk.totaladjustments, wrk.totallines, wrk.receiptcount, wrk.shipmentcount,
     wrk.transactioncount, wrk.totalquantityshipped, wrk.totalquantityreceived,
     wrk.uniqueitems, wrk.uniquelots, wrk.endingbalance, sysdate);
  end loop;
end loop;


open iar_cursor for
select *
   from invaccrpt
  where sessionid = numSessionId;

end INVACCRPTPROC;
/

show errors package INVACCRPTPKG;
show errors procedure INVACCRPTPROC;
exit;
