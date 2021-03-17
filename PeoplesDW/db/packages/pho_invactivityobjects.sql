drop table pho_asofinvact;

-- trantype column values:
--    AA-BegBal
--    DT-Detail
--       dtl_trantype column values:
--           SH-Shipment;
--           RC-Receipt;
--           RT-Return;
--           AD-Adjustmnent;
--    ZZ-EndBal

--
-- $Id: pho_invactivityobjects.sql 1704 2007-06-02 00:00:00Z eric $
--

create table pho_asofinvact
(sessionid       number
,facility        varchar2(3)
,campus          varchar2(15)
,custid          varchar2(10)
,item            varchar2(50)
,lotnumber       varchar2(30)
,uom             varchar2(4)
,invstatus       varchar2(2)
,inventoryclass  varchar2(2)
,trantype        varchar2(2)
,dtltrantype     varchar2(2)
,effdate         date
,qty             number(10)
,itemdesc        varchar2(255)
,invstatusabbrev varchar2(12)
,inventoryclassabbrev  varchar2(12)
,custname        varchar2(40)
,custaddr1       varchar2(40)
,custaddr2       varchar2(40)
,custcity        varchar2(30)
,custstate       varchar2(5)
,custzip         varchar2(12)
,reporttitle     varchar2(255)
,orderid         number(9)
,shipid          number(2)
,reason          varchar2(12)
,consignee_or_supplier varchar2(10)
,consignee_or_supplier_name varchar2(40)
,lastupdate      date
,reference       varchar2(20)
,po              varchar2(20)
,billoflading    varchar2(40)
,weight          number(17,8)
,qtypcs          number(10)
,qtyctn          number(10)
);

create index pho_asof_sessionid_idx
 on pho_asofinvact(sessionid,item,uom,invstatus,inventoryclass,trantype);

create index pho_asof_lastupdate_idx
 on pho_asofinvact(lastupdate);

create or replace package pho_asofinvactPKG
as type aoi_type is ref cursor return pho_asofinvact%rowtype;
end pho_asofinvactpkg;
/

create or replace procedure pho_asofinvactBYITEMPROC
(aoi_cursor IN OUT pho_asofinvactpkg.aoi_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_item IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2)
as

cursor curCustomer is
  select name,addr1,addr2,city,state,postalcode
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curFacility is
  select facility, campus
    from facility
   where instr(','||in_facility||',', ','||facility||',', 1, 1) > 0
      or in_facility='ALL';
cf curFacility%rowtype;

cursor curCustItems is
  select item,descr,status
    from custitem
   where custid = in_custid
     and (instr(','||in_item||',', ','||item||',', 1, 1) > 0
      or  in_item = 'ALL');

cursor curAsOfBeginSearch(in_facility IN varchar, in_item IN varchar2) is
select uom,invstatus,inventoryclass,sum(currentqty) as currentqty,sum(currentweight) as currentweight
from
(select uom,invstatus,inventoryclass,lotnumber,nvl(currentqty,0) as currentqty,
         nvl(nvl(currentweight,zci.item_weight(custid,item,uom)*currentqty),0) as currentweight
    from asofinventory aoi1
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and effdate < trunc(in_begdate)
     and invstatus != 'SU'
     and effdate = (select max(effdate)
                      from asofinventory aoi2
                     where aoi2.facility = in_facility
                       and aoi2.custid = in_custid
                       and aoi2.item = in_item
                       and nvl(aoi2.lotnumber,'(none)') = nvl(aoi1.lotnumber,'(none)')
                       and aoi2.uom = aoi1.uom
                       and nvl(aoi2.inventoryclass,'(none)') = nvl(aoi1.inventoryclass,'(none)')
                       and nvl(aoi2.invstatus,'(none)') = nvl(aoi1.invstatus,'(none)')
                       and aoi2.effdate < trunc(in_begdate))
     and (currentqty <> 0 or
          exists (select 1
                    from asofinventorydtl aoid
                   where aoid.facility = in_facility
                     and aoid.custid = in_custid
                     and aoid.item = in_item
                     and nvl(aoid.lotnumber,'(none)') = nvl(aoi1.lotnumber,'(none)')
                     and aoid.effdate >= trunc(in_begdate)
                     and aoid.effdate <= trunc(in_enddate)
                     and aoid.uom = aoi1.uom
                     and nvl(aoid.inventoryclass,'(none)') = nvl(aoi1.inventoryclass,'(none)')
                     and nvl(aoid.invstatus,'(none)') = nvl(aoi1.invstatus,'(none)')))
   union
  select uom,invstatus,inventoryclass,lotnumber,0 as currentqty,0 as currentweight
    from asofinventory aoi1
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and effdate >= trunc(in_begdate)
     and effdate <= trunc(in_enddate)
     and invstatus != 'SU'
     and not exists (select 1
                       from asofinventory aoi2
                      where aoi2.facility = in_facility
                        and aoi2.custid = in_custid
                        and aoi2.item = in_item
                        and nvl(aoi2.lotnumber,'(none)') = nvl(aoi1.lotnumber,'(none)')
                        and aoi2.uom = aoi1.uom
                        and nvl(aoi2.inventoryclass,'(none)') = nvl(aoi1.inventoryclass,'(none)')
                        and nvl(aoi2.invstatus,'(none)') = nvl(aoi1.invstatus,'(none)')
                        and aoi2.effdate < trunc(in_begdate))
     and effdate = (select min(effdate)
                      from asofinventory aoi2
                     where aoi2.facility = in_facility
                       and aoi2.custid = in_custid
                       and aoi2.item = in_item
                       and nvl(aoi2.lotnumber,'(none)') = nvl(aoi1.lotnumber,'(none)')
                       and aoi2.uom = aoi1.uom
                       and nvl(aoi2.inventoryclass,'(none)') = nvl(aoi1.inventoryclass,'(none)')
                       and nvl(aoi2.invstatus,'(none)') = nvl(aoi1.invstatus,'(none)')
                       and aoi2.effdate >= trunc(in_begdate)
                       and aoi2.effdate <= trunc(in_enddate)))
   group by uom,invstatus,inventoryclass;

cursor curAsOfDtlActivity(in_facility IN varchar, in_item IN varchar2) is
  select effdate as effdate,
         trunc(lastupdate) as lastupdate,
         decode(trantype,'RR','RC',trantype) trantype,
         decode(trantype,'RR','Received',reason) reason,
         uom,invstatus,inventoryclass,lotnumber,
         nvl(decode(trantype,'AD',0,orderid),0) as orderid,
         nvl(decode(trantype,'AD',0,shipid),0) as shipid,
         sum(nvl(adjustment,0)) adjustment,
         sum(nvl(nvl(weightadjustment,zci.item_weight(custid,item,uom)*adjustment),0)) weightadjustment
    from asofinventorydtl
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and effdate >= trunc(in_begdate)
     and effdate <= trunc(in_enddate)
     and invstatus != 'SU'
   group by effdate,
            trunc(lastupdate),
            decode(trantype,'RR','RC',trantype),
            decode(trantype,'RR','Received',reason),
            uom,invstatus,inventoryclass,lotnumber,
            nvl(decode(trantype,'AD',0,orderid),0),
            nvl(decode(trantype,'AD',0,shipid),0)
   order by uom,invstatus,inventoryclass,lotnumber;

cursor curShipmentOrders(in_facility IN varchar, in_item IN varchar2, in_lastupdate IN date, in_effdate IN date, in_lot IN varchar2) is
  select distinct oh.orderid,oh.shipid,oh.ordertype,oh.custid,oh.fromfacility,oh.shipto,
         oh.shiptoname,oh.orderstatus,oh.reference,oh.po,
         nvl(oh.billoflading,ld.billoflading) as billoflading
    from shippingplate sp, orderhdr oh, loads ld
   where sp.facility = in_facility
     and sp.custid = in_custid
     and sp.item = in_item
     and nvl(sp.lotnumber,'(none)') = nvl(in_lot,'(none)')
     and sp.type in ('F','P')
     and trunc(sp.lastupdate) = in_lastupdate
     and oh.orderid = sp.orderid
     and oh.shipid = sp.shipid
     and ((oh.lastuser <> 'MULTISHIP'
     and   trunc(oh.dateshipped) = in_effdate)
      or  (oh.lastuser = 'MULTISHIP'
     and   trunc(oh.statusupdate) = in_effdate))
     and oh.ordertype in ('O','V','T','U')
     and oh.orderstatus = '9'
     and oh.loadno = ld.loadno(+);
cso curShipmentOrders%rowtype;

cursor curOrder(in_orderid number, in_shipid number) is
  select oh.orderid,oh.shipid,oh.ordertype,oh.custid,oh.fromfacility,oh.shipto,
         oh.shiptoname,oh.orderstatus,oh.reference,oh.po,
         nvl(ld.billoflading,oh.billoflading) as billoflading
    from orderhdr oh, loads ld
   where oh.orderid = in_orderid
     and oh.shipid = in_shipid
     and oh.loadno = ld.loadno (+);
co curOrder%rowtype;

cursor curShippingPlates(in_orderid number, in_shipid number,
  in_item varchar2, in_lotnumber varchar2, in_uom varchar2, in_invstatus varchar2,
  in_inventoryclass varchar2) is
  select nvl(sum(quantity),0) * -1 as quantity,
         nvl(sum(weight),0) * -1 as weight
    from asofshippingplateview shippingplate
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
     and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
     and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
     and unitofmeasure = in_uom
     and status = 'SH'
     and type in ('F','P');

cursor curReceiptPlates(in_facility IN varchar2, in_item IN varchar2, in_lotnumber IN varchar2,
  in_uom IN varchar2, in_invstatus IN varchar2, in_inventoryclass IN varchar2,
  in_lastupdate IN date, in_effdate IN date) is
  select oh.orderid,oh.shipid,oh.ordertype,oh.shipper,
         oh.shippername,oh.reference,oh.po,
         nvl(ld.billoflading,oh.billoflading) as billoflading,
         nvl(ld.carrier,oh.carrier) as carrier,
         nvl(sum(odr.qtyrcvd),0) as quantity,
         nvl(sum(odr.weight),0) as weight
    from loads ld, orderhdr oh, orderdtl od, orderdtlrcpt odr
   where trunc(ld.lastupdate) = in_lastupdate
     and trunc(ld.rcvddate) = in_effdate
     and ld.loadtype in ('INC','INT')
     and ld.loadstatus = 'R'
     and ld.facility = in_facility
     and oh.loadno = ld.loadno
     and oh.custid = in_custid
     and oh.tofacility = ld.facility
     and oh.orderstatus = 'R'
     and oh.ordertype in('R','T','C','U')
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and nvl(od.qtyrcvd,0) != 0
     and odr.orderid = od.orderid
     and odr.shipid = od.shipid
     and odr.item = od.item
     and nvl(odr.orderlot,'(none)') = nvl(od.lotnumber,'(none)')
     and nvl(odr.lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
     and nvl(odr.invstatus,'(none)') = nvl(in_invstatus,'(none)')
     and nvl(odr.inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
     and odr.uom = in_uom
   group by oh.orderid,oh.shipid,oh.ordertype,oh.shipper,
         oh.shippername,oh.reference,oh.po,
         nvl(ld.billoflading,oh.billoflading),
         nvl(ld.carrier,oh.carrier)
   order by orderid,shipid;

cursor curReturnPlates(in_facility IN varchar2, in_item IN varchar2, in_lotnumber IN varchar2,
  in_uom IN varchar2, in_invstatus IN varchar2, in_inventoryclass IN varchar2,
  in_lastupdate IN date, in_effdate IN date) is
  select oh.orderid,oh.shipid,oh.ordertype,oh.shipper,
         oh.shippername,oh.reference,oh.po,
         nvl(ld.billoflading,oh.billoflading) as billoflading,
         nvl(ld.carrier,oh.carrier) as carrier,
         nvl(sum(odr.qtyrcvd),0) as quantity,
         nvl(sum(odr.weight),0) as weight
    from loads ld, orderhdr oh, orderdtl od, orderdtlrcpt odr
   where trunc(ld.lastupdate) = in_lastupdate
     and trunc(ld.rcvddate) = in_effdate
     and ld.loadtype in ('INC','INT')
     and ld.loadstatus = 'R'
     and ld.facility = in_facility
     and oh.loadno = ld.loadno
     and oh.custid = in_custid
     and oh.tofacility = ld.facility
     and oh.orderstatus = 'R'
     and oh.ordertype = 'Q'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and nvl(od.qtyrcvd,0) != 0
     and odr.orderid = od.orderid
     and odr.shipid = od.shipid
     and odr.item = od.item
     and nvl(odr.orderlot,'(none)') = nvl(od.lotnumber,'(none)')
     and nvl(odr.lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
     and nvl(odr.invstatus,'(none)') = nvl(in_invstatus,'(none)')
     and nvl(odr.inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
     and odr.uom = in_uom
   group by oh.orderid,oh.shipid,oh.ordertype,oh.shipper,
         oh.shippername,oh.reference,oh.po,
         nvl(ld.billoflading,oh.billoflading),
         nvl(ld.carrier,oh.carrier)
   union
  select oh.orderid,oh.shipid,oh.ordertype,oh.shipper,
         oh.shippername,oh.reference,oh.po,
         oh.billoflading,oh.carrier,
         nvl(sum(odr.qtyrcvd),0) as quantity,
         nvl(sum(odr.weight),0) as weight
    from orderhdr oh, orderdtl od, orderdtlrcpt odr
   where trunc(oh.lastupdate) = in_lastupdate
     and oh.loadno is null
     and oh.ordertype='Q'
     and oh.orderstatus = 'R'
     and oh.custid = in_custid
     and oh.tofacility = in_facility
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and trunc(od.statusupdate) = in_effdate
     and nvl(od.qtyrcvd,0) != 0
     and odr.orderid = od.orderid
     and odr.shipid = od.shipid
     and odr.item = od.item
     and nvl(odr.orderlot,'(none)') = nvl(od.lotnumber,'(none)')
     and nvl(odr.lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
     and nvl(odr.invstatus,'(none)') = nvl(in_invstatus,'(none)')
     and nvl(odr.inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
     and odr.uom = in_uom
   group by oh.orderid,oh.shipid,oh.ordertype,oh.shipper,
         oh.shippername,oh.reference,oh.po,
         oh.billoflading,oh.carrier
   order by orderid, shipid;

cursor curOrderDtlRcptPlates(in_orderid number, in_shipid number, in_item IN varchar2,
  in_lotnumber IN varchar2, in_uom IN varchar2, in_invstatus IN varchar2,
  in_inventoryclass IN varchar2) is
  select oh.orderid,oh.shipid,oh.ordertype,oh.shipper,
         oh.shippername,oh.reference,oh.po,
         nvl(ld.billoflading,oh.billoflading) as billoflading,
         nvl(ld.carrier,oh.carrier) as carrier,
         nvl(sum(odr.qtyrcvd),0) as quantity,
         nvl(sum(odr.weight),0) as weight
    from orderhdr oh, orderdtlrcpt odr, loads ld
   where oh.orderid = in_orderid
     and oh.shipid = in_shipid
     and oh.loadno = ld.loadno (+)
     and odr.orderid = oh.orderid
     and odr.shipid = oh.shipid
     and odr.item = in_item
     and nvl(odr.lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
     and nvl(odr.invstatus,'(none)') = nvl(in_invstatus,'(none)')
     and nvl(odr.inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
     and odr.uom = in_uom
   group by oh.orderid,oh.shipid,oh.ordertype,oh.shipper,
         oh.shippername,oh.reference,oh.po,
         nvl(ld.billoflading,oh.billoflading),
         nvl(ld.carrier,oh.carrier);

cursor curAsOfEndSearch(in_facility IN varchar, in_item IN varchar2) is
  select uom,invstatus,inventoryclass,sum(nvl(currentqty,0)) as currentqty,
         sum(nvl(nvl(currentweight,zci.item_weight(custid,item,uom)*currentqty),0)) as currentweight
    from asofinventory aoi1
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and effdate <= trunc(in_enddate)
     and invstatus != 'SU'
     and effdate = (select max(effdate)
                      from asofinventory aoi2
                     where aoi2.facility = in_facility
                       and aoi2.custid = in_custid
                       and aoi2.item = in_item
                       and nvl(aoi2.lotnumber,'(none)') = nvl(aoi1.lotnumber,'(none)')
                       and aoi2.uom = aoi1.uom
                       and nvl(aoi2.inventoryclass,'(none)') = nvl(aoi1.inventoryclass,'(none)')
                       and nvl(aoi2.invstatus,'(none)') = nvl(aoi1.invstatus,'(none)')
                       and aoi2.effdate <= trunc(in_enddate))
     and (currentqty <> 0 or
          exists (select 1
                    from asofinventorydtl aoid
                   where aoid.facility = in_facility
                     and aoid.custid = in_custid
                     and aoid.item = in_item
                     and nvl(aoid.lotnumber,'(none)') = nvl(aoi1.lotnumber,'(none)')
                     and aoid.effdate >= trunc(in_begdate)
                     and aoid.effdate <= trunc(in_enddate)
                     and aoid.uom = aoi1.uom
                     and nvl(aoid.inventoryclass,'(none)') = nvl(aoi1.inventoryclass,'(none)')
                     and nvl(aoid.invstatus,'(none)') = nvl(aoi1.invstatus,'(none)')))
   group by uom,invstatus,inventoryclass;

cursor curConsignee(in_consignee varchar2) is
  select name
    from consignee
   where consignee = in_consignee;

cursor curshipper(in_shipper varchar2) is
  select name
    from shipper
   where shipper = in_shipper;

cursor curCarrier(in_carrier varchar2) is
  select name
    from carrier
   where carrier = in_carrier;

numSessionId number;
wrk pho_asofinvact%rowtype;
aobCount integer;
aoeCount integer;
dtlCount integer;
recCount integer;


procedure debugmsg(in_text varchar2) is
begin
  if upper(rtrim(in_debug_yn)) = 'Y' then
    zut.prt(in_text);
  end if;
exception when others then
  null;
end;

function invstatus_abbrev(in_code varchar2) return varchar2
is
out inventorystatus%rowtype;
begin

out.abbrev := in_code;

select abbrev
  into out.abbrev
  from inventorystatus
 where code = in_code;

return out.abbrev;

exception when others then
  return out.abbrev;
end;

function inventoryclass_abbrev(in_code varchar2) return varchar2
is
out inventoryclass%rowtype;
begin

out.abbrev := in_code;

select abbrev
  into out.abbrev
  from inventoryclass
 where code = in_code;

return out.abbrev;

exception when others then
  return out.abbrev;
end;

procedure get_asof_detail(in_facility IN varchar, in_campus IN varchar, in_item IN varchar)
is
begin

for aod in curAsOfDtlActivity(in_facility, in_item)
loop

  debugmsg('processing dtl ' || aod.trantype || ' item ' || in_item || ' uom ' || aod.uom);

  wrk.invstatusabbrev := invstatus_abbrev(aod.invstatus);
  wrk.inventoryclassabbrev := inventoryclass_abbrev(aod.inventoryclass);
  
  if aod.trantype != 'SH' then
    goto check_receipt;
  end if;
 
  if aod.orderid = 0 or aod.shipid = 0 then
    for cso in curShipmentOrders(in_facility,in_item,aod.lastupdate,aod.effdate,aod.lotnumber)
    loop
      debugmsg('processing order ' || cso.orderid || '-' || cso.shipid);
      if rtrim(cso.shipto) is not null then
        open curConsignee(cso.shipto);
        fetch curConsignee into cso.shiptoname;
        close curConsignee;
      end if;
      
      for sp in curShippingPlates(cso.orderid,cso.shipid,in_item,
        aod.lotnumber,aod.uom,aod.invstatus,aod.inventoryclass)
      loop
        if nvl(sp.quantity,0) != 0 then
          recCount := 0;
          select count(1)
            into recCount
            from pho_asofinvact
           where sessionid = numSessionId
             and item = in_item
             and nvl(uom,'(none)') = nvl(aod.uom,'(none)')
             and nvl(invstatus,'(none)') = nvl(aod.invstatus,'(none)')
             and nvl(inventoryclass,'(none)') = nvl(aod.inventoryclass,'(none)')
             and trantype = 'DT'
             and dtltrantype = aod.trantype
             and effdate = aod.effdate
             and orderid = cso.orderid
             and shipid = cso.shipid;
          if nvl(recCount,0) = 0 then
           insert into pho_asofinvact values
           (numSessionId,in_facility,in_campus,in_custid,in_item,null,aod.uom,aod.invstatus,
            aod.inventoryclass,'DT',aod.trantype,aod.effdate,
            sp.quantity,wrk.itemdesc,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
            cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
            cso.orderid,cso.shipid,aod.reason,cso.shipto,cso.shiptoname,sysdate,
            cso.reference,cso.po,cso.billoflading,
            sp.weight,0,0);
          else
           update pho_asofinvact
              set qty = qty + sp.quantity,
                  weight = weight + sp.weight
            where sessionid = numSessionId
              and item = in_item
              and nvl(uom,'(none)') = nvl(aod.uom,'(none)')
              and nvl(invstatus,'(none)') = nvl(aod.invstatus,'(none)')
              and nvl(inventoryclass,'(none)') = nvl(aod.inventoryclass,'(none)')
              and trantype = 'DT'
              and dtltrantype = aod.trantype
              and effdate = aod.effdate
              and orderid = cso.orderid
              and shipid = cso.shipid;
          end if;
        end if;
      end loop;
    end loop;
  else
    debugmsg('processing order ' || aod.orderid || '-' || aod.shipid);

    co := null;
    open curOrder(aod.orderid,aod.shipid);
    fetch curOrder into co;
    close curOrder;

    if rtrim(co.shipto) is not null then
      open curConsignee(co.shipto);
      fetch curConsignee into co.shiptoname;
      close curConsignee;
    end if;

    recCount := 0;
    select count(1)
      into recCount
      from pho_asofinvact
     where sessionid = numSessionId
       and item = in_item
       and nvl(uom,'(none)') = nvl(aod.uom,'(none)')
       and nvl(invstatus,'(none)') = nvl(aod.invstatus,'(none)')
       and nvl(inventoryclass,'(none)') = nvl(aod.inventoryclass,'(none)')
       and trantype = 'DT'
       and dtltrantype = aod.trantype
       and effdate = aod.effdate
       and orderid = aod.orderid
       and shipid = aod.shipid;
    if nvl(recCount,0) = 0 then
     insert into pho_asofinvact values
     (numSessionId,in_facility,in_campus,in_custid,in_item,null,aod.uom,aod.invstatus,
      aod.inventoryclass,'DT',aod.trantype,aod.effdate,
      aod.adjustment,wrk.itemdesc,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
      cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
      co.orderid,co.shipid,aod.reason,co.shipto,co.shiptoname,sysdate,
      co.reference,co.po,co.billoflading,
      aod.weightadjustment,0,0);
    else
     update pho_asofinvact
        set qty = qty + aod.adjustment,
            weight = weight + aod.weightadjustment
      where sessionid = numSessionId
        and item = in_item
        and nvl(uom,'(none)') = nvl(aod.uom,'(none)')
        and nvl(invstatus,'(none)') = nvl(aod.invstatus,'(none)')
        and nvl(inventoryclass,'(none)') = nvl(aod.inventoryclass,'(none)')
        and trantype = 'DT'
        and dtltrantype = aod.trantype
        and effdate = aod.effdate
        and orderid = aod.orderid
        and shipid = aod.shipid;
    end if;
  end if;
  
  goto continue_aod_loop;
  
<< check_receipt >>

  if aod.trantype != 'RC' then
    goto check_return;
  end if;

  debugmsg('processing rc ' || aod.lastupdate);

  if aod.orderid = 0 or aod.shipid = 0 then
    for rp in curReceiptPlates(in_facility,in_item,aod.lotnumber,
      aod.uom,aod.invstatus,aod.inventoryclass, aod.lastupdate, aod.effdate)
    loop
      if rtrim(rp.Shipper) is not null then
        open curShipper(rp.Shipper);
        fetch curShipper into rp.shippername;
        close curShipper;
      end if;
      debugmsg('processing rc plate ' || rp.quantity);
      if nvl(rp.quantity,0) != 0 then
        recCount := 0;
        select count(1)
          into recCount
          from pho_asofinvact
         where sessionid = numSessionId
           and item = in_item
           and nvl(uom,'(none)') = nvl(aod.uom,'(none)')
           and nvl(invstatus,'(none)') = nvl(aod.invstatus,'(none)')
           and nvl(inventoryclass,'(none)') = nvl(aod.inventoryclass,'(none)')
           and trantype = 'DT'
           and dtltrantype = aod.trantype
           and effdate = aod.effdate
           and orderid = rp.orderid
           and shipid = rp.shipid;
        if recCount = 0 then
         insert into pho_asofinvact values
         (numSessionId,in_facility,in_campus,in_custid,in_item,null,aod.uom,aod.invstatus,
          aod.inventoryclass,'DT',aod.trantype,aod.effdate,
          rp.quantity,wrk.itemdesc,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
          cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
          rp.orderid,rp.shipid,aod.reason,rp.shipper,rp.shippername,sysdate,
          rp.reference,rp.po,rp.billoflading,
          rp.weight,0,0);
        else
         update pho_asofinvact
            set qty = qty + rp.quantity,
                weight = weight + rp.weight
          where sessionid = numSessionId
            and item = in_item
            and nvl(uom,'(none)') = nvl(aod.uom,'(none)')
            and nvl(invstatus,'(none)') = nvl(aod.invstatus,'(none)')
            and nvl(inventoryclass,'(none)') = nvl(aod.inventoryclass,'(none)')
            and trantype = 'DT'
            and dtltrantype = aod.trantype
            and effdate = aod.effdate
            and orderid = rp.orderid
            and shipid = rp.shipid;
        end if;
      end if;
    end loop;
  else
    for ordp in curOrderDtlRcptPlates(aod.orderid,aod.shipid,in_item,
      aod.lotnumber,aod.uom,aod.invstatus,aod.inventoryclass)
    loop
      if rtrim(ordp.Shipper) is not null then
        open curShipper(ordp.Shipper);
        fetch curShipper into ordp.shippername;
        close curShipper;
      end if;
      debugmsg('processing rc plate ' || ordp.quantity);
      if nvl(ordp.quantity,0) != 0 then
        recCount := 0;
        select count(1)
          into recCount
          from pho_asofinvact
         where sessionid = numSessionId
           and item = in_item
           and nvl(uom,'(none)') = nvl(aod.uom,'(none)')
           and nvl(invstatus,'(none)') = nvl(aod.invstatus,'(none)')
           and nvl(inventoryclass,'(none)') = nvl(aod.inventoryclass,'(none)')
           and trantype = 'DT'
           and dtltrantype = aod.trantype
           and effdate = aod.effdate
           and orderid = aod.orderid
           and shipid = aod.shipid;
        if recCount = 0 then
         insert into pho_asofinvact values
         (numSessionId,in_facility,in_campus,in_custid,in_item,null,aod.uom,aod.invstatus,
          aod.inventoryclass,'DT',aod.trantype,aod.effdate,
          ordp.quantity,wrk.itemdesc,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
          cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
          aod.orderid,aod.shipid,aod.reason,ordp.shipper,ordp.shippername,sysdate,
          ordp.reference,ordp.po, ordp.billoflading,
          ordp.weight,0,0);
        else
         update pho_asofinvact
            set qty = qty + ordp.quantity,
                weight = weight + ordp.weight
          where sessionid = numSessionId
            and item = in_item
            and nvl(uom,'(none)') = nvl(aod.uom,'(none)')
            and nvl(invstatus,'(none)') = nvl(aod.invstatus,'(none)')
            and nvl(inventoryclass,'(none)') = nvl(aod.inventoryclass,'(none)')
            and trantype = 'DT'
            and dtltrantype = aod.trantype
            and effdate = aod.effdate
            and orderid = aod.orderid
            and shipid = aod.shipid;
        end if;
      end if;
    end loop;
  end if;

  goto continue_aod_loop;

<< check_return >>

  if aod.trantype != 'RT' then
    goto check_adjustment;
  end if;

  debugmsg('processing rt ' || aod.lastupdate);

  if aod.orderid = 0 or aod.shipid = 0 then
    for rt in curReturnPlates(in_facility,in_item,aod.lotnumber,
      aod.uom,aod.invstatus,aod.inventoryclass, aod.lastupdate, aod.effdate)
    loop
      if rtrim(rt.Shipper) is not null then
        open curShipper(rt.Shipper);
        fetch curShipper into rt.shippername;
        close curShipper;
      end if;
      debugmsg('processing rt plate ' || rt.quantity);
      if nvl(rt.quantity,0) != 0 then
       insert into pho_asofinvact values
       (numSessionId,in_facility,in_campus,in_custid,in_item,null,aod.uom,aod.invstatus,
        aod.inventoryclass,'DT',aod.trantype,aod.effdate,
        rt.quantity,wrk.itemdesc,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
        cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
        rt.orderid,rt.shipid,aod.reason,rt.shipper,rt.shippername,sysdate,
        rt.reference,rt.po,rt.billoflading,
        rt.weight,0,0);
      end if;
    end loop;
  else
    for ordp in curOrderDtlRcptPlates(aod.orderid,aod.shipid,in_item,
      aod.lotnumber,aod.uom,aod.invstatus,aod.inventoryclass)
    loop
      if rtrim(ordp.Shipper) is not null then
        open curShipper(ordp.Shipper);
        fetch curShipper into ordp.shippername;
        close curShipper;
      end if;
      debugmsg('processing rt plate ' || ordp.quantity);
      if nvl(ordp.quantity,0) != 0 then
        insert into pho_asofinvact values
        (numSessionId,in_facility,in_campus,in_custid,in_item,null,aod.uom,aod.invstatus,
         aod.inventoryclass,'DT',aod.trantype,aod.effdate,
         ordp.quantity,wrk.itemdesc,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
         cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
         aod.orderid,aod.shipid,aod.reason,ordp.shipper,ordp.shippername,sysdate,
         ordp.reference,ordp.po, ordp.billoflading,
         ordp.weight,0,0);
      end if;
    end loop;
  end if;

  goto continue_aod_loop;

<< check_adjustment>>

  if aod.trantype != 'AD' then
    goto unknown_type;
  end if;

  if aod.adjustment <> 0 then
    insert into pho_asofinvact values
    (numSessionId,in_facility,in_campus,in_custid,in_item,null,aod.uom,aod.invstatus,
     aod.inventoryclass,'DT',aod.trantype,aod.effdate,
     aod.adjustment,wrk.itemdesc,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
     cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
     null,null,aod.reason,null,null,sysdate,null,null,null,
     aod.weightadjustment,0,0);
  end if;

  goto continue_aod_loop;

<< unknown_type >>

  debugmsg('unknown asofdtl type');
  debugmsg(in_item || ' ' ||
            aod.lotnumber || ' ' ||
            aod.uom || ' ' ||
            aod.invstatus || ' ' ||
            aod.inventoryclass || ' ' ||
            aod.trantype || ' ' ||
            aod.effdate || ' ' ||
            aod.reason);

<< continue_aod_loop >>
  null;
end loop;

exception when others then
  null;
end;

begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from pho_asofinvact
where sessionid = numSessionId;
commit;

delete from pho_asofinvact
where lastupdate < trunc(sysdate);
commit;

select count(1)
into dtlCount
from pho_asofinvact
where lastupdate < sysdate;

if dtlCount = 0 then
  EXECUTE IMMEDIATE 'truncate table pho_asofinvact';
end if;

cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;

wrk.reporttitle := null;
begin
 select reporttitle
   into wrk.reporttitle
   from reporttitleview;
exception when others then
 null;
end;

for cf in curFacility
loop
  for cit in curCustItems
  loop
    aobCount := 0;
    wrk.itemdesc := cit.descr;

    debugmsg('processing item for begin bal ' || cit.item);
    for aob in curAsOfBeginSearch(cf.facility, cit.item)
    loop
      debugmsg('processing status/class for begin bal ' ||
           aob.invstatus ||
           '/' || aob.inventoryclass ||
           '/' || aob.uom);
      wrk.invstatusabbrev := invstatus_abbrev(aob.invstatus);
      wrk.inventoryclassabbrev := inventoryclass_abbrev(aob.inventoryclass);
      insert into pho_asofinvact values
      (numSessionId,cf.facility,cf.campus,in_custid,cit.item,null,aob.uom,aob.invstatus,
       aob.inventoryclass,'AA','XX',trunc(in_begdate),aob.currentqty,cit.descr,
       wrk.invstatusabbrev,wrk.inventoryclassabbrev,
       cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
       wrk.reporttitle,null,null,null,null,null,sysdate,null,null,null,
       aob.currentweight,0,0);
    end loop;
    commit;

    get_asof_detail(cf.facility, cf.campus, cit.item);
    commit;

    for aoe in curAsOfEndSearch(cf.facility, cit.item)
    loop
        wrk.invstatusabbrev := invstatus_abbrev(wrk.invstatus);
        wrk.inventoryclassabbrev := inventoryclass_abbrev(wrk.inventoryclass);
        insert into pho_asofinvact values
        (numSessionId,cf.facility,cf.campus,in_custid,cit.item,null,aoe.uom,aoe.invstatus,
         aoe.inventoryclass,'ZZ','XX',trunc(in_enddate),aoe.currentqty,cit.descr,
         wrk.invstatusabbrev,wrk.inventoryclassabbrev,
         cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
         wrk.reporttitle,null,null,null,null,null,sysdate,null,null,null,
         aoe.currentweight,0,0);
    end loop;
    commit;
  end loop;
end loop;

commit;

delete from pho_asofinvact ao1
      where sessionid = numSessionId
        and trantype in('AA','ZZ')
        and qty = 0
        and not exists
         (select 1
            from pho_asofinvact  ao2
           where ao2.sessionid = ao1.sessionid
             and ao2.facility = ao1.facility
             and ao2.custid = ao1.custid
             and ao2.item = ao1.item
             and nvl(ao2.uom,'(none)') = nvl(ao1.uom,'(none)')
             and nvl(ao2.invstatus,'(none)') = nvl(ao1.invstatus,'(none)')
             and nvl(ao2.inventoryclass,'(none)') = nvl(ao1.inventoryclass,'(none)')
             and ao2.trantype = 'DT');
commit;

open aoi_cursor for
select sessionid
,facility
,campus
,custid
,item
,lotnumber
,uom
,invstatus
,inventoryclass
,nvl(trantype,'XX') as trantype
,nvl(dtltrantype,'XX') as dtltrantype
,effdate
,qty as qty
,itemdesc
,invstatusabbrev
,inventoryclassabbrev
,custname
,custaddr1
,custaddr2
,custcity
,custstate
,custzip
,reporttitle
,orderid
,shipid
,reason
,consignee_or_supplier
,consignee_or_supplier_name
,lastupdate as lastupdate
,reference
,po
,billoflading
,weight as weight
,nvl(zlbl.uom_qty_conv(custid, item, nvl(qty,0), uom, 'PCS'),0) as qtypcs
,nvl(zlbl.uom_qty_conv(custid, item, nvl(qty,0), uom, 'CTN'),0) as qtyctn
   from pho_asofinvact
  where sessionid = numSessionId
  order by facility,item,uom,invstatus,inventoryclass,trantype,dtltrantype,effdate;

end pho_asofinvactBYITEMPROC;
/

create or replace procedure pho_asofinvactPROC
(aoi_cursor IN OUT pho_asofinvactpkg.aoi_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2)
as
begin
	pho_asofinvactBYITEMPROC(aoi_cursor, in_custid, in_facility, 'ALL', in_begdate, in_enddate, in_debug_yn);
end pho_asofinvactPROC;
/

create or replace package pho_asofinvactlotPKG
AS
end pho_asofinvactlotpkg;
/

create or replace procedure pho_asofinvactLOTBYCAMPUSPROC
(aoi_cursor IN OUT pho_asofinvactpkg.aoi_type
,in_custid IN varchar2
,in_campus IN varchar2
,in_facility IN varchar2
,in_item IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2)
as

cursor curCustomer is
  select name,addr1,addr2,city,state,postalcode
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curFacility is
  select facility, campus
    from facility
   where (instr(','||in_facility||',', ','||facility||',', 1, 1) > 0
      or in_facility='ALL')
     and (instr(','||in_campus||',', ','||campus||',', 1, 1) > 0
      or  in_campus='ALL');
cf curFacility%rowtype;

cursor curCustItems is
  select item,descr,status
    from custitem
   where custid = in_custid
     and (instr(','||in_item||',', ','||item||',', 1, 1) > 0
      or  in_item='ALL');

cursor curAsOfBeginSearch(in_facility IN varchar, in_item IN varchar2) is
  select uom,invstatus,inventoryclass,lotnumber,nvl(currentqty,0) as currentqty,
         nvl(nvl(currentweight,zci.item_weight(custid,item,uom)*currentqty),0) as currentweight
    from asofinventory aoi1
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and effdate < trunc(in_begdate)
     and invstatus != 'SU'
     and effdate = (select max(effdate)
                      from asofinventory aoi2
                     where aoi2.facility = in_facility
                       and aoi2.custid = in_custid
                       and aoi2.item = in_item
                       and nvl(aoi2.lotnumber,'(none)') = nvl(aoi1.lotnumber,'(none)')
                       and aoi2.uom = aoi1.uom
                       and nvl(aoi2.inventoryclass,'(none)') = nvl(aoi1.inventoryclass,'(none)')
                       and nvl(aoi2.invstatus,'(none)') = nvl(aoi1.invstatus,'(none)')
                       and aoi2.effdate < trunc(in_begdate))
     and (currentqty <> 0 or
          exists (select 1
                    from asofinventorydtl aoid
                   where aoid.facility = in_facility
                     and aoid.custid = in_custid
                     and aoid.item = in_item
                     and nvl(aoid.lotnumber,'(none)') = nvl(aoi1.lotnumber,'(none)')
                     and aoid.effdate >= trunc(in_begdate)
                     and aoid.effdate <= trunc(in_enddate)
                     and aoid.uom = aoi1.uom
                     and nvl(aoid.inventoryclass,'(none)') = nvl(aoi1.inventoryclass,'(none)')
                     and nvl(aoid.invstatus,'(none)') = nvl(aoi1.invstatus,'(none)')))
   union
  select uom,invstatus,inventoryclass,lotnumber,0 as currentqty,0 as currentweight
    from asofinventory aoi1
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and effdate >= trunc(in_begdate)
     and effdate <= trunc(in_enddate)
     and invstatus != 'SU'
     and not exists (select 1
                       from asofinventory aoi2
                      where aoi2.facility = in_facility
                        and aoi2.custid = in_custid
                        and aoi2.item = in_item
                        and nvl(aoi2.lotnumber,'(none)') = nvl(aoi1.lotnumber,'(none)')
                        and aoi2.uom = aoi1.uom
                        and nvl(aoi2.inventoryclass,'(none)') = nvl(aoi1.inventoryclass,'(none)')
                        and nvl(aoi2.invstatus,'(none)') = nvl(aoi1.invstatus,'(none)')
                        and aoi2.effdate < trunc(in_begdate))
     and effdate = (select min(effdate)
                      from asofinventory aoi2
                     where aoi2.facility = in_facility
                       and aoi2.custid = in_custid
                       and aoi2.item = in_item
                       and nvl(aoi2.lotnumber,'(none)') = nvl(aoi1.lotnumber,'(none)')
                       and aoi2.uom = aoi1.uom
                       and nvl(aoi2.inventoryclass,'(none)') = nvl(aoi1.inventoryclass,'(none)')
                       and nvl(aoi2.invstatus,'(none)') = nvl(aoi1.invstatus,'(none)')
                       and aoi2.effdate >= trunc(in_begdate)
                       and aoi2.effdate <= trunc(in_enddate))
   group by uom,invstatus,inventoryclass,lotnumber;

cursor curAsOfDtlActivity(in_facility IN varchar, in_item IN varchar2) is
  select effdate as effdate,
         trunc(lastupdate) as lastupdate,
         decode(trantype,'RR','RC',trantype) trantype,
         decode(trantype,'RR','Received',reason) reason,
         uom,invstatus,inventoryclass,lotnumber,
         nvl(decode(trantype,'AD',0,orderid),0) as orderid,
         nvl(decode(trantype,'AD',0,shipid),0) as shipid,
         sum(nvl(adjustment,0)) adjustment,
         sum(nvl(nvl(weightadjustment,zci.item_weight(custid,item,uom)*adjustment),0)) weightadjustment
    from asofinventorydtl
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and effdate >= trunc(in_begdate)
     and effdate <= trunc(in_enddate)
     and invstatus != 'SU'
   group by effdate,
            trunc(lastupdate),
            decode(trantype,'RR','RC',trantype),
            decode(trantype,'RR','Received',reason),
            uom,invstatus,inventoryclass,lotnumber,
            nvl(decode(trantype,'AD',0,orderid),0),
            nvl(decode(trantype,'AD',0,shipid),0)
   order by uom,invstatus,inventoryclass,lotnumber;

cursor curShipmentOrders(in_facility IN varchar, in_item IN varchar2, in_lastupdate IN date, in_effdate IN date, in_lot IN varchar2) is
  select distinct oh.orderid,oh.shipid,oh.ordertype,oh.custid,oh.fromfacility,oh.shipto,
         oh.shiptoname,oh.orderstatus,oh.reference,oh.po,
         nvl(oh.billoflading,ld.billoflading) as billoflading
    from shippingplate sp, orderhdr oh, loads ld
   where sp.facility = in_facility
     and sp.custid = in_custid
     and sp.item = in_item
     and nvl(sp.lotnumber,'(none)') = nvl(in_lot,'(none)')
     and sp.type in ('F','P')
     and trunc(sp.lastupdate) = in_lastupdate
     and oh.orderid = sp.orderid
     and oh.shipid = sp.shipid
     and ((oh.lastuser <> 'MULTISHIP'
     and   trunc(oh.dateshipped) = in_effdate)
      or  (oh.lastuser = 'MULTISHIP'
     and   trunc(oh.statusupdate) = in_effdate))
     and oh.ordertype in ('O','V','T','U')
     and oh.orderstatus = '9'
     and oh.loadno = ld.loadno(+);
cso curShipmentOrders%rowtype;

cursor curOrder(in_orderid number, in_shipid number) is
  select oh.orderid,oh.shipid,oh.ordertype,oh.custid,oh.fromfacility,oh.shipto,
         oh.shiptoname,oh.orderstatus,oh.reference,oh.po,
         nvl(ld.billoflading,oh.billoflading) as billoflading
    from orderhdr oh, loads ld
   where oh.orderid = in_orderid
     and oh.shipid = in_shipid
     and oh.loadno = ld.loadno (+);
co curOrder%rowtype;

cursor curShippingPlates(in_orderid number, in_shipid number,
  in_item varchar2, in_lotnumber varchar2, in_uom varchar2, in_invstatus varchar2,
  in_inventoryclass varchar2) is
  select nvl(sum(quantity),0) * -1 as quantity,
         nvl(sum(weight),0) * -1 as weight
    from asofshippingplateview shippingplate
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
     and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
     and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
     and unitofmeasure = in_uom
     and status = 'SH'
     and type in ('F','P');

cursor curReceiptPlates(in_facility IN varchar2, in_item IN varchar2, in_lotnumber IN varchar2,
  in_uom IN varchar2, in_invstatus IN varchar2, in_inventoryclass IN varchar2,
  in_lastupdate IN date, in_effdate IN date) is
  select oh.orderid,oh.shipid,oh.ordertype,oh.shipper,
         oh.shippername,oh.reference,oh.po,
         nvl(ld.billoflading,oh.billoflading) as billoflading,
         nvl(ld.carrier,oh.carrier) as carrier,
         nvl(sum(odr.qtyrcvd),0) as quantity,
         nvl(sum(odr.weight),0) as weight
    from loads ld, orderhdr oh, orderdtl od, orderdtlrcpt odr
   where trunc(ld.lastupdate) = in_lastupdate
     and trunc(ld.rcvddate) = in_effdate
     and ld.loadtype in ('INC','INT')
     and ld.loadstatus = 'R'
     and ld.facility = in_facility
     and oh.loadno = ld.loadno
     and oh.custid = in_custid
     and oh.tofacility = ld.facility
     and oh.orderstatus = 'R'
     and oh.ordertype in('R','T','C','U')
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and nvl(od.qtyrcvd,0) != 0
     and odr.orderid = od.orderid
     and odr.shipid = od.shipid
     and odr.item = od.item
     and nvl(odr.orderlot,'(none)') = nvl(od.lotnumber,'(none)')
     and nvl(odr.lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
     and nvl(odr.invstatus,'(none)') = nvl(in_invstatus,'(none)')
     and nvl(odr.inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
     and odr.uom = in_uom
   group by oh.orderid,oh.shipid,oh.ordertype,oh.shipper,
         oh.shippername,oh.reference,oh.po,
         nvl(ld.billoflading,oh.billoflading),
         nvl(ld.carrier,oh.carrier)
   order by orderid,shipid;

cursor curReturnPlates(in_facility IN varchar2, in_item IN varchar2, in_lotnumber IN varchar2,
  in_uom IN varchar2, in_invstatus IN varchar2, in_inventoryclass IN varchar2,
  in_lastupdate IN date, in_effdate IN date) is
  select oh.orderid,oh.shipid,oh.ordertype,oh.shipper,
         oh.shippername,oh.reference,oh.po,
         nvl(ld.billoflading,oh.billoflading) as billoflading,
         nvl(ld.carrier,oh.carrier) as carrier,
         nvl(sum(odr.qtyrcvd),0) as quantity,
         nvl(sum(odr.weight),0) as weight
    from loads ld, orderhdr oh, orderdtl od, orderdtlrcpt odr
   where trunc(ld.lastupdate) = in_lastupdate
     and trunc(ld.rcvddate) = in_effdate
     and ld.loadtype in ('INC','INT')
     and ld.loadstatus = 'R'
     and ld.facility = in_facility
     and oh.loadno = ld.loadno
     and oh.custid = in_custid
     and oh.tofacility = ld.facility
     and oh.orderstatus = 'R'
     and oh.ordertype = 'Q'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and nvl(od.qtyrcvd,0) != 0
     and odr.orderid = od.orderid
     and odr.shipid = od.shipid
     and odr.item = od.item
     and nvl(odr.orderlot,'(none)') = nvl(od.lotnumber,'(none)')
     and nvl(odr.lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
     and nvl(odr.invstatus,'(none)') = nvl(in_invstatus,'(none)')
     and nvl(odr.inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
     and odr.uom = in_uom
   group by oh.orderid,oh.shipid,oh.ordertype,oh.shipper,
         oh.shippername,oh.reference,oh.po,
         nvl(ld.billoflading,oh.billoflading),
         nvl(ld.carrier,oh.carrier)
   union
  select oh.orderid,oh.shipid,oh.ordertype,oh.shipper,
         oh.shippername,oh.reference,oh.po,
         oh.billoflading,oh.carrier,
         nvl(sum(odr.qtyrcvd),0) as quantity,
         nvl(sum(odr.weight),0) as weight
    from orderhdr oh, orderdtl od, orderdtlrcpt odr
   where trunc(oh.lastupdate) = in_lastupdate
     and oh.loadno is null
     and oh.ordertype='Q'
     and oh.orderstatus = 'R'
     and oh.custid = in_custid
     and oh.tofacility = in_facility
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and trunc(od.statusupdate) = in_effdate
     and nvl(od.qtyrcvd,0) != 0
     and odr.orderid = od.orderid
     and odr.shipid = od.shipid
     and odr.item = od.item
     and nvl(odr.orderlot,'(none)') = nvl(od.lotnumber,'(none)')
     and nvl(odr.lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
     and nvl(odr.invstatus,'(none)') = nvl(in_invstatus,'(none)')
     and nvl(odr.inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
     and odr.uom = in_uom
   group by oh.orderid,oh.shipid,oh.ordertype,oh.shipper,
         oh.shippername,oh.reference,oh.po,
         oh.billoflading,oh.carrier
   order by orderid, shipid;

cursor curOrderDtlRcptPlates(in_orderid number, in_shipid number, in_item IN varchar2,
  in_lotnumber IN varchar2, in_uom IN varchar2, in_invstatus IN varchar2,
  in_inventoryclass IN varchar2) is
  select oh.orderid,oh.shipid,oh.ordertype,oh.shipper,
         oh.shippername,oh.reference,oh.po,
         nvl(ld.billoflading,oh.billoflading) as billoflading,
         nvl(ld.carrier,oh.carrier) as carrier,
         nvl(sum(odr.qtyrcvd),0) as quantity,
         nvl(sum(odr.weight),0) as weight
    from orderhdr oh, orderdtlrcpt odr, loads ld
   where oh.orderid = in_orderid
     and oh.shipid = in_shipid
     and oh.loadno = ld.loadno (+)
     and odr.orderid = oh.orderid
     and odr.shipid = oh.shipid
     and odr.item = in_item
     and nvl(odr.lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
     and nvl(odr.invstatus,'(none)') = nvl(in_invstatus,'(none)')
     and nvl(odr.inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
     and odr.uom = in_uom
   group by oh.orderid,oh.shipid,oh.ordertype,oh.shipper,
         oh.shippername,oh.reference,oh.po,
         nvl(ld.billoflading,oh.billoflading),
         nvl(ld.carrier,oh.carrier);

cursor curAsOfEndSearch(in_facility IN varchar, in_item IN varchar2) is
  select uom,invstatus,inventoryclass,lotnumber,sum(nvl(currentqty,0)) as currentqty,
         sum(nvl(nvl(currentweight,zci.item_weight(custid,item,uom)*currentqty),0)) as currentweight
    from asofinventory aoi1
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and effdate <= trunc(in_enddate)
     and invstatus != 'SU'
     and effdate = (select max(effdate)
                      from asofinventory aoi2
                     where aoi2.facility = in_facility
                       and aoi2.custid = in_custid
                       and aoi2.item = in_item
                       and nvl(aoi2.lotnumber,'(none)') = nvl(aoi1.lotnumber,'(none)')
                       and aoi2.uom = aoi1.uom
                       and nvl(aoi2.inventoryclass,'(none)') = nvl(aoi1.inventoryclass,'(none)')
                       and nvl(aoi2.invstatus,'(none)') = nvl(aoi1.invstatus,'(none)')
                       and aoi2.effdate <= trunc(in_enddate))
     and (currentqty <> 0 or
          exists (select 1
                    from asofinventorydtl aoid
                   where aoid.facility = in_facility
                     and aoid.custid = in_custid
                     and aoid.item = in_item
                     and nvl(aoid.lotnumber,'(none)') = nvl(aoi1.lotnumber,'(none)')
                     and aoid.effdate >= trunc(in_begdate)
                     and aoid.effdate <= trunc(in_enddate)
                     and aoid.uom = aoi1.uom
                     and nvl(aoid.inventoryclass,'(none)') = nvl(aoi1.inventoryclass,'(none)')
                     and nvl(aoid.invstatus,'(none)') = nvl(aoi1.invstatus,'(none)')))
   group by uom,invstatus,inventoryclass,lotnumber;

cursor curConsignee(in_consignee varchar2) is
  select name
    from consignee
   where consignee = in_consignee;

cursor curshipper(in_shipper varchar2) is
  select name
    from shipper
   where shipper = in_shipper;

cursor curCarrier(in_carrier varchar2) is
  select name
    from carrier
   where carrier = in_carrier;

numSessionId number;
wrk pho_asofinvact%rowtype;
aobCount integer;
aoeCount integer;
dtlCount integer;
recCount integer;


procedure debugmsg(in_text varchar2) is
begin
  if upper(rtrim(in_debug_yn)) = 'Y' then
    zut.prt(in_text);
  end if;
exception when others then
  null;
end;

function invstatus_abbrev(in_code varchar2) return varchar2
is
out inventorystatus%rowtype;
begin

out.abbrev := in_code;

select abbrev
  into out.abbrev
  from inventorystatus
 where code = in_code;

return out.abbrev;

exception when others then
  return out.abbrev;
end;

function inventoryclass_abbrev(in_code varchar2) return varchar2
is
out inventoryclass%rowtype;
begin

out.abbrev := in_code;

select abbrev
  into out.abbrev
  from inventoryclass
 where code = in_code;

return out.abbrev;

exception when others then
  return out.abbrev;
end;

procedure get_asof_detail(in_facility IN varchar, in_campus IN varchar, in_item IN varchar)
is
begin

for aod in curAsOfDtlActivity(in_facility, in_item)
loop

  debugmsg('processing dtl ' || aod.trantype || ' item ' || in_item || ' uom ' || aod.uom);

  if aod.trantype != 'SH' then
    goto check_receipt;
  end if;

  wrk.invstatusabbrev := invstatus_abbrev(aod.invstatus);
  wrk.inventoryclassabbrev := inventoryclass_abbrev(aod.inventoryclass);

  if aod.orderid = 0 or aod.shipid = 0 then
    for cso in curShipmentOrders(in_facility,in_item,aod.lastupdate,aod.effdate,aod.lotnumber)
    loop
      debugmsg('processing order ' || cso.orderid || '-' || cso.shipid);
      if rtrim(cso.shipto) is not null then
        open curConsignee(cso.shipto);
        fetch curConsignee into cso.shiptoname;
        close curConsignee;
      end if;

      for sp in curShippingPlates(cso.orderid,cso.shipid,in_item,
        aod.lotnumber,aod.uom,aod.invstatus,aod.inventoryclass)
      loop
        if nvl(sp.quantity,0) != 0 then
          recCount := 0;
          select count(1)
            into recCount
            from pho_asofinvact
           where sessionid = numSessionId
             and item = in_item
             and nvl(uom,'(none)') = nvl(aod.uom,'(none)')
             and nvl(invstatus,'(none)') = nvl(aod.invstatus,'(none)')
             and nvl(inventoryclass,'(none)') = nvl(aod.inventoryclass,'(none)')
             and trantype = 'DT'
             and nvl(lotnumber,'(none)') = nvl(aod.lotnumber,'(none)')
             and dtltrantype = aod.trantype
             and effdate = aod.effdate
             and orderid = cso.orderid
             and shipid = cso.shipid;
          if nvl(recCount,0) = 0 then
           insert into pho_asofinvact values
           (numSessionId,in_facility,in_campus,in_custid,in_item,aod.lotnumber,aod.uom,aod.invstatus,
            aod.inventoryclass,'DT',aod.trantype,aod.effdate,
            sp.quantity,wrk.itemdesc,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
            cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
            cso.orderid,cso.shipid,aod.reason,cso.shipto,cso.shiptoname,sysdate,
            cso.reference,cso.po,cso.billoflading,
            sp.weight,0,0);
          else
           update pho_asofinvact
              set qty = qty + sp.quantity,
                  weight = weight + sp.weight
            where sessionid = numSessionId
              and item = in_item
              and nvl(uom,'(none)') = nvl(aod.uom,'(none)')
              and nvl(invstatus,'(none)') = nvl(aod.invstatus,'(none)')
              and nvl(inventoryclass,'(none)') = nvl(aod.inventoryclass,'(none)')
              and trantype = 'DT'
              and nvl(lotnumber,'(none)') = nvl(aod.lotnumber,'(none)')
              and dtltrantype = aod.trantype
              and effdate = aod.effdate
              and orderid = cso.orderid
              and shipid = cso.shipid;
          end if;
        end if;
      end loop;
    end loop;
  else
    debugmsg('processing order ' || aod.orderid || '-' || aod.shipid);

    co := null;
    open curOrder(aod.orderid,aod.shipid);
    fetch curOrder into co;
    close curOrder;

    if rtrim(co.shipto) is not null then
      open curConsignee(co.shipto);
      fetch curConsignee into co.shiptoname;
      close curConsignee;
    end if;

    recCount := 0;
    select count(1)
      into recCount
      from pho_asofinvact
     where sessionid = numSessionId
       and item = in_item
       and nvl(uom,'(none)') = nvl(aod.uom,'(none)')
       and nvl(invstatus,'(none)') = nvl(aod.invstatus,'(none)')
       and nvl(inventoryclass,'(none)') = nvl(aod.inventoryclass,'(none)')
       and trantype = 'DT'
       and nvl(lotnumber,'(none)') = nvl(aod.lotnumber,'(none)')
       and dtltrantype = aod.trantype
       and effdate = aod.effdate
       and orderid = aod.orderid
       and shipid = aod.shipid;
    if nvl(recCount,0) = 0 then
     insert into pho_asofinvact values
     (numSessionId,in_facility,in_campus,in_custid,in_item,aod.lotnumber,aod.uom,aod.invstatus,
      aod.inventoryclass,'DT',aod.trantype,aod.effdate,
      aod.adjustment,wrk.itemdesc,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
      cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
      co.orderid,co.shipid,aod.reason,co.shipto,co.shiptoname,sysdate,
      co.reference,co.po,co.billoflading,
      aod.weightadjustment,0,0);
    else
     update pho_asofinvact
        set qty = qty + aod.adjustment,
            weight = weight + aod.weightadjustment
      where sessionid = numSessionId
        and item = in_item
        and nvl(uom,'(none)') = nvl(aod.uom,'(none)')
        and nvl(invstatus,'(none)') = nvl(aod.invstatus,'(none)')
        and nvl(inventoryclass,'(none)') = nvl(aod.inventoryclass,'(none)')
        and trantype = 'DT'
        and nvl(lotnumber,'(none)') = nvl(aod.lotnumber,'(none)')
        and dtltrantype = aod.trantype
        and effdate = aod.effdate
        and orderid = aod.orderid
        and shipid = aod.shipid;
    end if;
  end if;

  goto continue_aod_loop;

<< check_receipt >>

  if aod.trantype != 'RC' then
    goto check_return;
  end if;

  debugmsg('processing rc ' || aod.lastupdate);

  if aod.orderid = 0 or aod.shipid = 0 then
    for rp in curReceiptPlates(in_facility,in_item,aod.lotnumber,
      aod.uom,aod.invstatus,aod.inventoryclass, aod.lastupdate, aod.effdate)
    loop
      if rtrim(rp.Shipper) is not null then
        open curShipper(rp.Shipper);
        fetch curShipper into rp.shippername;
        close curShipper;
      end if;
      debugmsg('processing rc plate ' || rp.quantity);
      if nvl(rp.quantity,0) != 0 then
        recCount := 0;
        select count(1)
          into recCount
          from pho_asofinvact
         where sessionid = numSessionId
           and item = in_item
           and nvl(uom,'(none)') = nvl(aod.uom,'(none)')
           and nvl(invstatus,'(none)') = nvl(aod.invstatus,'(none)')
           and nvl(inventoryclass,'(none)') = nvl(aod.inventoryclass,'(none)')
           and trantype = 'DT'
           and nvl(lotnumber,'(none)') = nvl(aod.lotnumber,'(none)')
           and dtltrantype = aod.trantype
           and effdate = aod.effdate
           and orderid = rp.orderid
           and shipid = rp.shipid;
        if recCount = 0 then
         insert into pho_asofinvact values
         (numSessionId,in_facility,in_campus,in_custid,in_item,aod.lotnumber,aod.uom,aod.invstatus,
          aod.inventoryclass,'DT',aod.trantype,aod.effdate,
          rp.quantity,wrk.itemdesc,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
          cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
          rp.orderid,rp.shipid,aod.reason,rp.shipper,rp.shippername,sysdate,
          rp.reference,rp.po,rp.billoflading,
          rp.weight,0,0);
        else
         update pho_asofinvact
            set qty = qty + rp.quantity,
                weight = weight + rp.weight
          where sessionid = numSessionId
            and item = in_item
            and nvl(uom,'(none)') = nvl(aod.uom,'(none)')
            and nvl(invstatus,'(none)') = nvl(aod.invstatus,'(none)')
            and nvl(inventoryclass,'(none)') = nvl(aod.inventoryclass,'(none)')
            and trantype = 'DT'
            and nvl(lotnumber,'(none)') = nvl(aod.lotnumber,'(none)')
            and dtltrantype = aod.trantype
            and effdate = aod.effdate
            and orderid = rp.orderid
            and shipid = rp.shipid;
        end if;
      end if;
    end loop;
  else
    for ordp in curOrderDtlRcptPlates(aod.orderid,aod.shipid,in_item,
      aod.lotnumber,aod.uom,aod.invstatus,aod.inventoryclass)
    loop
      if rtrim(ordp.Shipper) is not null then
        open curShipper(ordp.Shipper);
        fetch curShipper into ordp.shippername;
        close curShipper;
      end if;
      debugmsg('processing rc plate ' || ordp.quantity);
      if nvl(ordp.quantity,0) != 0 then
        recCount := 0;
        select count(1)
          into recCount
          from pho_asofinvact
         where sessionid = numSessionId
           and item = in_item
           and nvl(uom,'(none)') = nvl(aod.uom,'(none)')
           and nvl(invstatus,'(none)') = nvl(aod.invstatus,'(none)')
           and nvl(inventoryclass,'(none)') = nvl(aod.inventoryclass,'(none)')
           and trantype = 'DT'
           and nvl(lotnumber,'(none)') = nvl(aod.lotnumber,'(none)')
           and dtltrantype = aod.trantype
           and effdate = aod.effdate
           and orderid = aod.orderid
           and shipid = aod.shipid;
        if recCount = 0 then
         insert into pho_asofinvact values
         (numSessionId,in_facility,in_campus,in_custid,in_item,aod.lotnumber,aod.uom,aod.invstatus,
          aod.inventoryclass,'DT',aod.trantype,aod.effdate,
          ordp.quantity,wrk.itemdesc,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
          cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
          aod.orderid,aod.shipid,aod.reason,ordp.shipper,ordp.shippername,sysdate,
          ordp.reference,ordp.po, ordp.billoflading,
          ordp.weight,0,0);
        else
         update pho_asofinvact
            set qty = qty + ordp.quantity,
                weight = weight + ordp.weight
          where sessionid = numSessionId
            and item = in_item
            and nvl(uom,'(none)') = nvl(aod.uom,'(none)')
            and nvl(invstatus,'(none)') = nvl(aod.invstatus,'(none)')
            and nvl(inventoryclass,'(none)') = nvl(aod.inventoryclass,'(none)')
            and trantype = 'DT'
            and nvl(lotnumber,'(none)') = nvl(aod.lotnumber,'(none)')
            and dtltrantype = aod.trantype
            and effdate = aod.effdate
            and orderid = aod.orderid
            and shipid = aod.shipid;
        end if;
      end if;
    end loop;
  end if;

  goto continue_aod_loop;

<< check_return >>

  if aod.trantype != 'RT' then
    goto check_adjustment;
  end if;

  debugmsg('processing rt ' || aod.lastupdate);

  if aod.orderid = 0 or aod.shipid = 0 then
    for rt in curReturnPlates(in_facility,in_item,aod.lotnumber,
      aod.uom,aod.invstatus,aod.inventoryclass, aod.lastupdate, aod.effdate)
    loop
      if rtrim(rt.Shipper) is not null then
        open curShipper(rt.Shipper);
        fetch curShipper into rt.shippername;
        close curShipper;
      end if;
      debugmsg('processing rt plate ' || rt.quantity);
      if nvl(rt.quantity,0) != 0 then
       insert into pho_asofinvact values
       (numSessionId,in_facility,in_campus,in_custid,in_item,aod.lotnumber,aod.uom,aod.invstatus,
        aod.inventoryclass,'DT',aod.trantype,aod.effdate,
        rt.quantity,wrk.itemdesc,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
        cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
        rt.orderid,rt.shipid,aod.reason,rt.shipper,rt.shippername,sysdate,
        rt.reference,rt.po,rt.billoflading,
        rt.weight,0,0);
      end if;
    end loop;
  else
    for ordp in curOrderDtlRcptPlates(aod.orderid,aod.shipid,in_item,
      aod.lotnumber,aod.uom,aod.invstatus,aod.inventoryclass)
    loop
      if rtrim(ordp.Shipper) is not null then
        open curShipper(ordp.Shipper);
        fetch curShipper into ordp.shippername;
        close curShipper;
      end if;
      debugmsg('processing rt plate ' || ordp.quantity);
      if nvl(ordp.quantity,0) != 0 then
        insert into pho_asofinvact values
        (numSessionId,in_facility,in_campus,in_custid,in_item,aod.lotnumber,aod.uom,aod.invstatus,
         aod.inventoryclass,'DT',aod.trantype,aod.effdate,
         ordp.quantity,wrk.itemdesc,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
         cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
         aod.orderid,aod.shipid,aod.reason,ordp.shipper,ordp.shippername,sysdate,
         ordp.reference,ordp.po, ordp.billoflading,
         ordp.weight,0,0);
      end if;
    end loop;
  end if;

  goto continue_aod_loop;

<< check_adjustment>>

  if aod.trantype != 'AD' then
    goto unknown_type;
  end if;

  if aod.adjustment <> 0 then
    insert into pho_asofinvact values
    (numSessionId,in_facility,in_campus,in_custid,in_item,aod.lotnumber,aod.uom,'-',
     '-','DT',aod.trantype,aod.effdate,
     aod.adjustment,wrk.itemdesc,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
     cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
     null,null,aod.reason,null,null,sysdate,null,null,null,
     aod.weightadjustment,0,0);
  end if;

  goto continue_aod_loop;

<< unknown_type >>

  debugmsg('unknown asofdtl type');
  debugmsg(in_item || ' ' ||
            aod.lotnumber || ' ' ||
            aod.uom || ' ' ||
            aod.invstatus || ' ' ||
            aod.inventoryclass || ' ' ||
            aod.trantype || ' ' ||
            aod.effdate || ' ' ||
            aod.reason);

<< continue_aod_loop >>
  null;
end loop;

exception when others then
  null;
end;

begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from pho_asofinvact
where sessionid = numSessionId;
commit;

delete from pho_asofinvact
where lastupdate < trunc(sysdate);
commit;

select count(1)
into dtlCount
from pho_asofinvact
where lastupdate < sysdate;

if dtlCount = 0 then
  EXECUTE IMMEDIATE 'truncate table pho_asofinvact';
end if;

cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;

wrk.reporttitle := null;
begin
 select reporttitle
   into wrk.reporttitle
   from reporttitleview;
exception when others then
 null;
end;

for cf in curFacility
loop
  for cit in curCustItems
  loop
    aobCount := 0;
    wrk.itemdesc := cit.descr;

    debugmsg('processing item for begin bal ' || cit.item);
    for aob in curAsOfBeginSearch(cf.facility, cit.item)
    loop
      debugmsg('processing status/class for begin bal ' ||
           aob.invstatus ||
           '/' || aob.inventoryclass ||
           '/' || aob.uom ||
           '/' || aob.lotnumber);
      wrk.invstatusabbrev := invstatus_abbrev(aob.invstatus);
      wrk.inventoryclassabbrev := inventoryclass_abbrev(aob.inventoryclass);
      insert into pho_asofinvact values
      (numSessionId,cf.facility,cf.campus,in_custid,cit.item,aob.lotnumber,aob.uom,aob.invstatus,
       aob.inventoryclass,'AA','XX',trunc(in_begdate),aob.currentqty,cit.descr,
       wrk.invstatusabbrev,wrk.inventoryclassabbrev,
       cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
       wrk.reporttitle,null,null,null,null,null,sysdate,null,null,null,
       aob.currentweight,0,0);
    end loop;
    commit;

    get_asof_detail(cf.facility, cf.campus, cit.item);
    commit;

    for aoe in curAsOfEndSearch(cf.facility, cit.item)
    loop
        wrk.invstatusabbrev := invstatus_abbrev(wrk.invstatus);
        wrk.inventoryclassabbrev := inventoryclass_abbrev(wrk.inventoryclass);
        insert into pho_asofinvact values
        (numSessionId,cf.facility,cf.campus,in_custid,cit.item,aoe.lotnumber,aoe.uom,aoe.invstatus,
         aoe.inventoryclass,'ZZ','XX',trunc(in_enddate),aoe.currentqty,cit.descr,
         wrk.invstatusabbrev,wrk.inventoryclassabbrev,
         cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
         wrk.reporttitle,null,null,null,null,null,sysdate,null,null,null,
         aoe.currentweight,0,0);
    end loop;
    commit;
  end loop;
end loop;

commit;

 delete from pho_asofinvact ao1
      where sessionid = numSessionId
        and trantype in('AA','ZZ')
        and qty = 0
        and not exists
         (select 1
            from pho_asofinvact  ao2
           where ao2.sessionid = ao1.sessionid
             and ao2.facility = ao1.facility
             and ao2.custid = ao1.custid
             and ao2.item = ao1.item
             and nvl(ao2.uom,'(none)') = nvl(ao1.uom,'(none)')
             and nvl(ao2.lotnumber,'(none)') = nvl(ao1.lotnumber,'(none)')
             and ao2.trantype = 'DT');
commit;

open aoi_cursor for
select sessionid
,facility
,campus
,custid
,item
,lotnumber
,uom
,invstatus
,inventoryclass
,nvl(trantype,'XX') as trantype
,nvl(dtltrantype,'XX') as dtltrantype
,effdate
,qty
,itemdesc
,invstatusabbrev
,inventoryclassabbrev
,custname
,custaddr1
,custaddr2
,custcity
,custstate
,custzip
,reporttitle
,orderid
,shipid
,reason
,consignee_or_supplier
,consignee_or_supplier_name
,lastupdate
,reference
,po
,billoflading
,weight
,nvl(zlbl.uom_qty_conv(custid, item, nvl(qty,0), uom, 'PCS'),0) as qtypcs
,nvl(zlbl.uom_qty_conv(custid, item, nvl(qty,0), uom, 'CTN'),0) as qtyctn
   from pho_asofinvact
  where sessionid = numSessionId
  order by campus,facility,item,lotnumber,uom,trantype,dtltrantype,effdate;

end pho_asofinvactLOTBYCAMPUSPROC;
/

create or replace procedure pho_asofinvactlotbyitemPROC
(aoi_cursor IN OUT pho_asofinvactpkg.aoi_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_item IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2)
as
begin
	pho_asofinvactLOTBYCAMPUSPROC(aoi_cursor, in_custid, 'ALL', in_facility, in_item, in_begdate, in_enddate, in_debug_yn);
end pho_asofinvactlotbyitemPROC;
/

create or replace procedure pho_asofinvactLOTPROC
(aoi_cursor IN OUT pho_asofinvactpkg.aoi_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2)
as
begin
	pho_asofinvactLOTBYITEMPROC(aoi_cursor, in_custid, in_facility, 'ALL', in_begdate, in_enddate, in_debug_yn);
end pho_asofinvactLOTPROC;
/
show errors package pho_asofinvactPKG;
show errors procedure pho_asofinvactBYITEMPROC;
show errors procedure pho_asofinvactPROC;
show errors package pho_asofinvactLOTPKG;
show errors procedure pho_asofinvactLOTBYITEMPROC;
show errors procedure pho_asofinvactLOTPROC;
exit;
