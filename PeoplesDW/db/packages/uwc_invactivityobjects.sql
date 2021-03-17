create or replace procedure UWC_ASOFINVACTBYITEMPROC
(aoi_cursor IN OUT asofinvactpkg.aoi_type
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
  select facility
    from facility
   where instr(','||in_facility||',', ','||facility||',', 1, 1) > 0
      or in_facility='ALL'
   order by facility;
cf curFacility%rowtype;

cursor curCustItems is
  select item,descr,status,upper(nvl(hazardous,'N')) hazardous
    from custitem
   where custid = in_custid
     and (instr(','||in_item||',', ','||item||',', 1, 1) > 0
      or  in_item = 'ALL')
   order by item;

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
     and oh.ordertype in ('O','V','T')
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
     and oh.ordertype in('R','T','C')
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
wrk asofinvact%rowtype;
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

procedure get_asof_detail(in_facility IN varchar, in_item IN varchar)
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
            from asofinvact
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
           insert into asofinvact 
           (sessionid,facility,custid,item,lotnumber,uom,invstatus,
            inventoryclass,trantype,dtltrantype,effdate,
            qty,itemdesc,hazardous,invstatusabbrev,inventoryclassabbrev,
            custname,custaddr1,custaddr2,custcity,custstate,custzip,reporttitle,
            orderid,shipid,reason,consignee_or_supplier,consignee_or_supplier_name,lastupdate,
            reference,po,billoflading,
            weight) values
           (numSessionId,in_facility,in_custid,in_item,null,aod.uom,aod.invstatus,
            aod.inventoryclass,'DT',aod.trantype,aod.effdate,
            sp.quantity,wrk.itemdesc,wrk.hazardous,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
            cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
            cso.orderid,cso.shipid,aod.reason,cso.shipto,cso.shiptoname,sysdate,
            cso.reference,cso.po,cso.billoflading,
            sp.weight);
          else
           update asofinvact
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
      from asofinvact
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
     insert into asofinvact 
     (sessionid,facility,custid,item,lotnumber,uom,invstatus,
      inventoryclass,trantype,dtltrantype,effdate,
      qty,itemdesc,hazardous,invstatusabbrev,inventoryclassabbrev,
      custname,custaddr1,custaddr2,custcity,custstate,custzip,reporttitle,
      orderid,shipid,reason,consignee_or_supplier,consignee_or_supplier_name,lastupdate,
      reference,po,billoflading,
      weight) values
     (numSessionId,in_facility,in_custid,in_item,null,aod.uom,aod.invstatus,
      aod.inventoryclass,'DT',aod.trantype,aod.effdate,
      aod.adjustment,wrk.itemdesc,wrk.hazardous,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
      cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
      co.orderid,co.shipid,aod.reason,co.shipto,co.shiptoname,sysdate,
      co.reference,co.po,co.billoflading,
      aod.weightadjustment);
    else
     update asofinvact
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
          from asofinvact
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
         insert into asofinvact 
         (sessionid,facility,custid,item,lotnumber,uom,invstatus,
          inventoryclass,trantype,dtltrantype,effdate,
          qty,itemdesc,hazardous,invstatusabbrev,inventoryclassabbrev,
          custname,custaddr1,custaddr2,custcity,custstate,custzip,reporttitle,
          orderid,shipid,reason,consignee_or_supplier,consignee_or_supplier_name,lastupdate,
          reference,po,billoflading,
          weight) values
         (numSessionId,in_facility,in_custid,in_item,null,aod.uom,aod.invstatus,
          aod.inventoryclass,'DT',aod.trantype,aod.effdate,
          rp.quantity,wrk.itemdesc,wrk.hazardous,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
          cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
          rp.orderid,rp.shipid,aod.reason,rp.shipper,rp.shippername,sysdate,
          rp.reference,rp.po,rp.billoflading,
          rp.weight);
        else
         update asofinvact
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
          from asofinvact
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
         insert into asofinvact 
         (sessionid,facility,custid,item,lotnumber,uom,invstatus,
          inventoryclass,trantype,dtltrantype,effdate,
          qty,itemdesc,hazardous,invstatusabbrev,inventoryclassabbrev,
          custname,custaddr1,custaddr2,custcity,custstate,custzip,reporttitle,
          orderid,shipid,reason,consignee_or_supplier,consignee_or_supplier_name,lastupdate,
          reference,po,billoflading,
          weight) values
         (numSessionId,in_facility,in_custid,in_item,null,aod.uom,aod.invstatus,
          aod.inventoryclass,'DT',aod.trantype,aod.effdate,
          ordp.quantity,wrk.itemdesc,wrk.hazardous,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
          cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
          aod.orderid,aod.shipid,aod.reason,ordp.shipper,ordp.shippername,sysdate,
          ordp.reference,ordp.po, ordp.billoflading,
          ordp.weight);
        else
         update asofinvact
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
     insert into asofinvact 
     (sessionid,facility,custid,item,lotnumber,uom,invstatus,
      inventoryclass,trantype,dtltrantype,effdate,
      qty,itemdesc,hazardous,invstatusabbrev,inventoryclassabbrev,
      custname,custaddr1,custaddr2,custcity,custstate,custzip,reporttitle,
      orderid,shipid,reason,consignee_or_supplier,consignee_or_supplier_name,lastupdate,
      reference,po,billoflading,
      weight) values
     (numSessionId,in_facility,in_custid,in_item,null,aod.uom,aod.invstatus,
      aod.inventoryclass,'DT',aod.trantype,aod.effdate,
      rt.quantity,wrk.itemdesc,wrk.hazardous,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
      cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
      rt.orderid,rt.shipid,aod.reason,rt.shipper,rt.shippername,sysdate,
      rt.reference,rt.po,rt.billoflading,
      rt.weight);
    end if;
  end loop;

  goto continue_aod_loop;

<< check_adjustment>>

  if aod.trantype != 'AD' then
    goto unknown_type;
  end if;

  if aod.adjustment <> 0 then
    insert into asofinvact 
    (sessionid,facility,custid,item,lotnumber,uom,invstatus,
     inventoryclass,trantype,dtltrantype,effdate,
     qty,itemdesc,hazardous,invstatusabbrev,inventoryclassabbrev,
     custname,custaddr1,custaddr2,custcity,custstate,custzip,reporttitle,
     orderid,shipid,reason,consignee_or_supplier,consignee_or_supplier_name,lastupdate,
     reference,po,billoflading,
     weight) values
    (numSessionId,in_facility,in_custid,in_item,null,aod.uom,aod.invstatus,
     aod.inventoryclass,'DT',aod.trantype,aod.effdate,
     aod.adjustment,wrk.itemdesc,wrk.hazardous,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
     cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
     null,null,aod.reason,null,null,sysdate,null,null,null,
     aod.weightadjustment);
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
    wrk.hazardous := cit.hazardous;

    debugmsg('processing item for begin bal ' || cit.item);
    for aob in curAsOfBeginSearch(cf.facility, cit.item)
    loop
      debugmsg('processing status/class for begin bal ' ||
           aob.invstatus ||
           '/' || aob.inventoryclass ||
           '/' || aob.uom);
      wrk.invstatusabbrev := invstatus_abbrev(aob.invstatus);
      wrk.inventoryclassabbrev := inventoryclass_abbrev(aob.inventoryclass);
      insert into asofinvact 
      (sessionid,facility,custid,item,lotnumber,uom,invstatus,
       inventoryclass,trantype,dtltrantype,effdate,
       qty,itemdesc,hazardous,invstatusabbrev,inventoryclassabbrev,
       custname,custaddr1,custaddr2,custcity,custstate,custzip,reporttitle,
       orderid,shipid,reason,consignee_or_supplier,consignee_or_supplier_name,lastupdate,
       reference,po,billoflading,
       weight) values
      (numSessionId,cf.facility,in_custid,cit.item,null,aob.uom,aob.invstatus,
       aob.inventoryclass,'AA','XX',trunc(in_begdate),aob.currentqty,cit.descr,cit.hazardous,
       wrk.invstatusabbrev,wrk.inventoryclassabbrev,
       cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
       wrk.reporttitle,null,null,null,null,null,sysdate,null,null,null,
       aob.currentweight);
    end loop;
    commit;

    get_asof_detail(cf.facility, cit.item);
    commit;

    for aoe in curAsOfEndSearch(cf.facility, cit.item)
    loop
        wrk.invstatusabbrev := invstatus_abbrev(wrk.invstatus);
        wrk.inventoryclassabbrev := inventoryclass_abbrev(wrk.inventoryclass);
        insert into asofinvact 
        (sessionid,facility,custid,item,lotnumber,uom,invstatus,
         inventoryclass,trantype,dtltrantype,effdate,
         qty,itemdesc,hazardous,invstatusabbrev,inventoryclassabbrev,
         custname,custaddr1,custaddr2,custcity,custstate,custzip,reporttitle,
         orderid,shipid,reason,consignee_or_supplier,consignee_or_supplier_name,lastupdate,
         reference,po,billoflading,
         weight) values
        (numSessionId,cf.facility,in_custid,cit.item,null,aoe.uom,aoe.invstatus,
         aoe.inventoryclass,'ZZ','XX',trunc(in_enddate),aoe.currentqty,cit.descr,cit.hazardous,
         wrk.invstatusabbrev,wrk.inventoryclassabbrev,
         cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
         wrk.reporttitle,null,null,null,null,null,sysdate,null,null,null,
         aoe.currentweight);
    end loop;
    commit;
  end loop;
end loop;

commit;

open aoi_cursor for
select *
   from asofinvact
  where sessionid = numSessionId
  order by facility,item,uom,invstatus,inventoryclass,trantype,dtltrantype,effdate;

end UWC_ASOFINVACTBYITEMPROC;
/

show errors procedure UWC_ASOFINVACTBYITEMPROC;
exit;
