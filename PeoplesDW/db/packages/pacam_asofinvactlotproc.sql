--
-- $Id$
--
CREATE OR REPLACE PACKAGE pacamasofinvactlotpkg AS
function uom_qty_conv
   (in_custid   in varchar2,
    in_item     in varchar2,
    in_qty      in number,
    in_from_uom in varchar2,
    in_to_uom   in varchar2)
return number;
pragma restrict_references (uom_qty_conv, wnds);
procedure pacam_asofinvactlotproc
(aoi_cursor IN OUT asofinvactpkg.aoi_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2);
procedure pacam_asofinvactlotpltproc
(aoi_cursor IN OUT asofinvactpkg.aoi_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2);
procedure pacam_asofinvactitemlotproc
(aoi_cursor IN OUT asofinvactpkg.aoi_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2);
end pacamasofinvactlotpkg;
/

create or replace procedure pacam_asofinvactitemproc
(aoi_cursor IN OUT asofinvactpkg.aoi_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_topallet IN varchar2
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
      or in_facility='ALL';
cf curFacility%rowtype;

cursor curCustItems is
  select item,descr,status,upper(nvl(hazardous,'N')) hazardous
    from custitem
   where custid = in_custid
     and (in_item = 'ALL'
      or  item = in_item)
   order by item;

cursor curAsOfBeginSearch(in_facility IN varchar, in_item IN varchar2) is
  select uom,invstatus,inventoryclass,lotnumber,currentqty,
         nvl(currentweight,zci.item_weight(custid,item,uom)*currentqty) as currentweight
    from asofinventory aoi1
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and effdate = (select max(effdate)
                      from asofinventory aoi2
                     where aoi2.facility = aoi1.facility
                       and aoi2.custid = aoi1.custid
                       and aoi2.item = aoi1.item
                       and nvl(aoi2.lotnumber,'(none)') = nvl(aoi1.lotnumber,'(none)')
                       and aoi2.uom = aoi1.uom
                       and nvl(aoi2.inventoryclass,'(none)') = nvl(aoi1.inventoryclass,'(none)')
                       and nvl(aoi2.invstatus,'(none)') = nvl(aoi1.invstatus,'(none)')
                       and aoi2.effdate < trunc(in_begdate))
     and (lotnumber like '%'||in_lotnumber||'%'
      or  nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
      or  in_lotnumber = 'ALL')
     and invstatus != 'SU'
   union
  select uom,invstatus,inventoryclass,lotnumber,0 as currentqty,0 as currentweight
    from asofinventory aoi1
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and effdate = (select min(effdate)
                      from asofinventory aoi2
                     where aoi2.facility = aoi1.facility
                       and aoi2.custid = aoi1.custid
                       and aoi2.item = aoi1.item
                       and nvl(aoi2.lotnumber,'(none)') = nvl(aoi1.lotnumber,'(none)')
                       and aoi2.uom = aoi1.uom
                       and nvl(aoi2.inventoryclass,'(none)') = nvl(aoi1.inventoryclass,'(none)')
                       and nvl(aoi2.invstatus,'(none)') = nvl(aoi1.invstatus,'(none)')
                       and aoi2.effdate >= trunc(in_begdate)
                       and aoi2.effdate <= trunc(in_enddate))
     and invstatus != 'SU'
     and not exists (select 1
                       from asofinventory aoi2
                      where aoi2.facility = aoi1.facility
                        and aoi2.custid = aoi1.custid
                        and aoi2.item = aoi1.item
                        and nvl(aoi2.lotnumber,'(none)') = nvl(aoi1.lotnumber,'(none)')
                        and aoi2.uom = aoi1.uom
                        and nvl(aoi2.inventoryclass,'(none)') = nvl(aoi1.inventoryclass,'(none)')
                        and nvl(aoi2.invstatus,'(none)') = nvl(aoi1.invstatus,'(none)')
                        and aoi2.effdate < trunc(in_begdate))
     and (lotnumber like '%'||in_lotnumber||'%'
      or  nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
      or  in_lotnumber = 'ALL')
   order by uom,lotnumber,invstatus,inventoryclass;

cursor curAsOfDtlActivity(in_facility IN varchar, in_item IN varchar2) is
  select effdate as effdate,
         trunc(lastupdate) as lastupdate,
         decode(trantype,'RR','RC',trantype) trantype,
         decode(trantype,'RR','Received',reason) reason,
         uom,invstatus,inventoryclass,lotnumber,
         nvl(decode(trantype,'AD',0,orderid),0) as orderid,
         nvl(decode(trantype,'AD',0,shipid),0) as shipid,
         sum(adjustment) adjustment,
         sum(nvl(weightadjustment,zci.item_weight(custid,item,uom)*adjustment)) weightadjustment
    from asofinventorydtl
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and effdate >= trunc(in_begdate)
     and effdate <= trunc(in_enddate)
     and invstatus != 'SU'
     and (lotnumber like '%'||in_lotnumber||'%'
      or  nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
      or  in_lotnumber = 'ALL')
   group by effdate,
            trunc(lastupdate),
            decode(trantype,'RR','RC',trantype),
            decode(trantype,'RR','Received',reason),
            uom,invstatus,inventoryclass,lotnumber,
            nvl(decode(trantype,'AD',0,orderid),0),
            nvl(decode(trantype,'AD',0,shipid),0)
   order by uom,lotnumber,invstatus,inventoryclass;

cursor curShipmentOrders(in_facility IN varchar, in_item IN varchar2, in_lastupdate IN date, in_effdate IN date, in_lot IN varchar2) is
  select oh.orderid,oh.shipid,oh.ordertype,oh.custid,oh.fromfacility,oh.shipto,
         oh.shiptoname,oh.orderstatus,oh.reference,oh.po,
         nvl(oh.billoflading,ld.billoflading) as billoflading
    from orderhdr oh, orderdtl od, loads ld
   where trunc(oh.statusupdate) = in_lastupdate
     and trunc(oh.dateshipped) = in_effdate
     and oh.orderid = od.orderid
     and oh.shipid = od.shipid
     and od.item = in_item
     and oh.loadno = ld.loadno(+)
     and oh.ordertype in ('O','V','T','U')
     and oh.custid = in_custid
     and oh.fromfacility = in_facility
     and oh.orderstatus = '9'
     and od.lotnumber is not null
     and nvl(od.lotnumber,'(none)') = nvl(in_lot,'(none)')
   union
  select oh.orderid,oh.shipid,oh.ordertype,oh.custid,oh.fromfacility,oh.shipto,
         oh.shiptoname,oh.orderstatus,oh.reference,oh.po,
         nvl(oh.billoflading,ld.billoflading) as billoflading
    from orderhdr oh, orderdtl od, loads ld
   where trunc(oh.statusupdate) = in_lastupdate
     and trunc(oh.dateshipped) = in_effdate
     and oh.orderid = od.orderid
     and oh.shipid = od.shipid
     and od.item = in_item
     and oh.loadno = ld.loadno(+)
     and oh.ordertype in ('O','V','T','U')
     and oh.custid = in_custid
     and oh.fromfacility = in_facility
     and oh.orderstatus = '9'
     and od.lotnumber is null
     and not exists (select 1
                       from orderhdr oh, orderdtl od
                      where trunc(oh.statusupdate) = in_lastupdate
                        and trunc(oh.dateshipped) = in_effdate
                        and oh.orderid = od.orderid
                        and oh.shipid = od.shipid
                        and od.item = in_item
                        and oh.ordertype in ('O','V','T','U')
                        and oh.custid = in_custid
                        and oh.fromfacility = in_facility
                        and oh.orderstatus = '9'
                        and od.lotnumber is not null
                        and nvl(od.lotnumber,'(none)') = nvl(in_lot,'(none)'))
   order by orderid,shipid;
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
  select uom,invstatus,inventoryclass,lotnumber,currentqty,
         nvl(currentweight,zci.item_weight(custid,item,uom)*currentqty) as currentweight
    from asofinventory aoi1
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and effdate = (select max(effdate)
                      from asofinventory aoi2
                     where aoi2.facility = aoi1.facility
                       and aoi2.custid = aoi1.custid
                       and aoi2.item = aoi1.item
                       and nvl(aoi2.lotnumber,'(none)') = nvl(aoi1.lotnumber,'(none)')
                       and aoi2.uom = aoi1.uom
                       and nvl(aoi2.inventoryclass,'(none)') = nvl(aoi1.inventoryclass,'(none)')
                       and nvl(aoi2.invstatus,'(none)') = nvl(aoi1.invstatus,'(none)')
                       and aoi2.effdate <= trunc(in_enddate))
     and invstatus != 'SU'
     and (lotnumber like '%'||in_lotnumber||'%'
      or  nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
      or  in_lotnumber = 'ALL')
   order by uom,lotnumber,invstatus,inventoryclass;

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

procedure get_asof_detail(in_facility IN varchar, in_item IN varchar)
is
begin

for aod in curAsOfDtlActivity(in_facility, in_item)
loop

  debugmsg('processing dtl ' || aod.trantype || ' item ' || in_item || ' uom ' || aod.uom);

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
             and nvl(lotnumber,'(none)') = nvl(aod.lotnumber,'(none)')
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
           (numSessionId,in_facility,in_custid,in_item,aod.lotnumber,aod.uom,'-',
            '-','DT',aod.trantype,aod.effdate,
            sp.quantity,wrk.itemdesc,wrk.hazardous,'--','--',
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
              and nvl(lotnumber,'(none)') = nvl(aod.lotnumber,'(none)')
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

    for sp in curShippingPlates(aod.orderid,aod.shipid,in_item,
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
           and nvl(lotnumber,'(none)') = nvl(aod.lotnumber,'(none)')
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
         (numSessionId,in_facility,in_custid,in_item,aod.lotnumber,aod.uom,'-',
          '-','DT',aod.trantype,aod.effdate,
          sp.quantity,wrk.itemdesc,wrk.hazardous,'--','--',
          cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
          co.orderid,co.shipid,aod.reason,co.shipto,co.shiptoname,sysdate,
          co.reference,co.po,co.billoflading,
          sp.weight);
        else
         update asofinvact
            set qty = qty + sp.quantity,
                weight = weight + sp.weight
          where sessionid = numSessionId
            and item = in_item
            and nvl(uom,'(none)') = nvl(aod.uom,'(none)')
            and nvl(lotnumber,'(none)') = nvl(aod.lotnumber,'(none)')
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

<< check_receipt >>

  if aod.trantype != 'RC' then
    goto check_return;
  end if;

  debugmsg('processing rc ' || aod.lastupdate);

  if aod.orderid = 0 or aod.shipid = 0 then
    for rp in curReceiptPlates(in_facility,in_item,aod.lotnumber,
      aod.uom,aod.invstatus,aod.inventoryclass, aod.lastupdate, aod.effdate)
    loop
      if rtrim(rp.carrier) is not null then
        open curCarrier(rp.carrier);
        fetch curCarrier into rp.shippername;
        close curCarrier;
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
           and nvl(lotnumber,'(none)') = nvl(aod.lotnumber,'(none)')
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
         (numSessionId,in_facility,in_custid,in_item,aod.lotnumber,aod.uom,'-',
          '-','DT',aod.trantype,aod.effdate,
          rp.quantity,wrk.itemdesc,wrk.hazardous,'--','--',
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
            and nvl(lotnumber,'(none)') = nvl(aod.lotnumber,'(none)')
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
      if rtrim(ordp.carrier) is not null then
        open curCarrier(ordp.carrier);
        fetch curCarrier into ordp.shippername;
        close curCarrier;
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
           and nvl(lotnumber,'(none)') = nvl(aod.lotnumber,'(none)')
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
         (numSessionId,in_facility,in_custid,in_item,aod.lotnumber,aod.uom,'-',
          '-','DT',aod.trantype,aod.effdate,
          ordp.quantity,wrk.itemdesc,wrk.hazardous,'--','--',
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
            and nvl(lotnumber,'(none)') = nvl(aod.lotnumber,'(none)')
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
    if rtrim(rt.carrier) is not null then
      open curCarrier(rt.carrier);
      fetch curCarrier into rt.shippername;
      close curCarrier;
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
     (numSessionId,in_facility,in_custid,in_item,aod.lotnumber,aod.uom,'-',
      '-','DT',aod.trantype,aod.effdate,
      rt.quantity,wrk.itemdesc,wrk.hazardous,'--','--',
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
    (numSessionId,in_facility,in_custid,in_item,aod.lotnumber,aod.uom,'-',
     '-','DT',aod.trantype,aod.effdate,
     aod.adjustment,wrk.itemdesc,wrk.hazardous,'--','--',
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
    wrk.qty := 0;
    wrk.weight := 0;
    wrk.itemdesc := cit.descr;
    wrk.hazardous := cit.hazardous;

    debugmsg('processing item for begin bal ' || cit.item);
    for aob in curAsOfBeginSearch(cf.facility, cit.item)
    loop
      debugmsg('processing status/class for begin bal ' ||
           aob.lotnumber || ' ' ||
           aob.invstatus ||
           '/' || aob.inventoryclass);
      if aobCount = 0 then
        wrk.lotnumber := aob.lotnumber;
        wrk.uom := aob.uom;
      end if;
      aobCount := aobCount + 1;
      if (nvl(wrk.lotnumber,'(none)') <> nvl(aob.lotnumber,'(none)')) or
         (wrk.uom <> aob.uom) then
        insert into asofinvact 
        (sessionid,facility,custid,item,lotnumber,uom,invstatus,
         inventoryclass,trantype,dtltrantype,effdate,
         qty,itemdesc,hazardous,invstatusabbrev,inventoryclassabbrev,
         custname,custaddr1,custaddr2,custcity,custstate,custzip,reporttitle,
         orderid,shipid,reason,consignee_or_supplier,consignee_or_supplier_name,lastupdate,
         reference,po,billoflading,
         weight) values
        (numSessionId,cf.facility,in_custid,cit.item,wrk.lotnumber,wrk.uom,'-',
         '-','AA',null,trunc(in_begdate),wrk.qty,wrk.itemdesc,wrk.hazardous,'--','--',
         cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
         wrk.reporttitle,null,null,null,null,null,sysdate,null,null,null,
         wrk.weight);
        wrk.lotnumber := aob.lotnumber;
        wrk.uom := aob.uom;
        wrk.qty := 0;
        wrk.weight := 0;
      end if;
      wrk.qty := wrk.qty + aob.currentqty;
      wrk.weight := wrk.weight + aob.currentweight;
    end loop;
    if (aobCount <> 0) then
      insert into asofinvact 
      (sessionid,facility,custid,item,lotnumber,uom,invstatus,
       inventoryclass,trantype,dtltrantype,effdate,
       qty,itemdesc,hazardous,invstatusabbrev,inventoryclassabbrev,
       custname,custaddr1,custaddr2,custcity,custstate,custzip,reporttitle,
       orderid,shipid,reason,consignee_or_supplier,consignee_or_supplier_name,lastupdate,
       reference,po,billoflading,
       weight) values
      (numSessionId,cf.facility,in_custid,cit.item,wrk.lotnumber,wrk.uom,'-',
       '-','AA',null,trunc(in_begdate),wrk.qty,wrk.itemdesc,wrk.hazardous,'--','--',
       cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
       wrk.reporttitle,null,null,null,null,null,sysdate,null,null,null,
       wrk.weight);
    end if;

    get_asof_detail(cf.facility, cit.item);
    commit;

    aoeCount := 0;
    wrk.qty := 0;
    wrk.weight := 0;

    for aoe in curAsOfEndSearch(cf.facility, cit.item)
    loop
      if aoeCount = 0 then
        wrk.lotnumber := aoe.lotnumber;
        wrk.uom := aoe.uom;
      end if;
      aoeCount := aoeCount + 1;
      if (nvl(wrk.lotnumber,'(none)') <> nvl(aoe.lotnumber,'(none)')) or
         (wrk.uom <> aoe.uom) then
        insert into asofinvact 
        (sessionid,facility,custid,item,lotnumber,uom,invstatus,
         inventoryclass,trantype,dtltrantype,effdate,
         qty,itemdesc,hazardous,invstatusabbrev,inventoryclassabbrev,
         custname,custaddr1,custaddr2,custcity,custstate,custzip,reporttitle,
         orderid,shipid,reason,consignee_or_supplier,consignee_or_supplier_name,lastupdate,
         reference,po,billoflading,
         weight) values
        (numSessionId,cf.facility,in_custid,cit.item,wrk.lotnumber,wrk.uom,'-',
         '-','ZZ',null,trunc(in_enddate),wrk.qty,wrk.itemdesc,wrk.hazardous,'--','--',
         cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
         wrk.reporttitle,null,null,null,null,null,sysdate,null,null,null,
         wrk.weight);
        wrk.lotnumber := aoe.lotnumber;
        wrk.uom := aoe.uom;
        wrk.qty := 0;
        wrk.weight := 0;
      end if;
      wrk.qty := wrk.qty + aoe.currentqty;
      wrk.weight := wrk.weight + aoe.currentweight;
    end loop;
    if (aoeCount <> 0) then
      insert into asofinvact 
      (sessionid,facility,custid,item,lotnumber,uom,invstatus,
       inventoryclass,trantype,dtltrantype,effdate,
       qty,itemdesc,hazardous,invstatusabbrev,inventoryclassabbrev,
       custname,custaddr1,custaddr2,custcity,custstate,custzip,reporttitle,
       orderid,shipid,reason,consignee_or_supplier,consignee_or_supplier_name,lastupdate,
       reference,po,billoflading,
       weight) values
      (numSessionId,cf.facility,in_custid,cit.item,wrk.lotnumber,wrk.uom,'-',
       '-','ZZ',null,trunc(in_enddate),wrk.qty,wrk.itemdesc,wrk.hazardous,'--','--',
       cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
       wrk.reporttitle,null,null,null,null,null,sysdate,null,null,null,
       wrk.weight);
    end if;
    commit;
  end loop;
end loop;

commit;

delete from asofinvact ao1
      where sessionid = numSessionId
        and trantype in('AA','ZZ')
        and qty = 0
        and not exists
         (select 1
            from asofinvact  ao2
           where ao2.sessionid = ao1.sessionid
             and ao2.facility = ao1.facility
             and ao2.custid = ao1.custid
             and ao2.item = ao1.item
             and nvl(ao2.uom,'(none)') = nvl(ao1.uom,'(none)')
             and nvl(ao2.lotnumber,'(none)') = nvl(ao1.lotnumber,'(none)')
             and ao2.trantype = 'DT');
commit;

if (nvl(in_topallet,'N') = 'Y') then
	update asofinvact
	set uom = 'PT',
	    qty = nvl(pacamasofinvactlotpkg.uom_qty_conv(custid, item, qty, 'EA', 'PT'),0),
	    weight = nvl(pacamasofinvactlotpkg.uom_qty_conv(custid, item, weight, 'EA', 'PT'),0)
  where sessionid = numSessionId
    and uom = 'EA';
  commit;
end if;

open aoi_cursor for
select sessionid
,facility
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
,hazardous
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
   from asofinvact
  where sessionid = numSessionId
  order by facility,item,lotnumber,uom,trantype,dtltrantype,effdate;

end pacam_asofinvactitemproc;
/

create or replace procedure pacam_asofinvactitemproc2
(aoi_cursor IN OUT asofinvactpkg.aoi_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_topallet IN varchar2
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
      or in_facility='ALL';
cf curFacility%rowtype;

cursor curCustItems is
  select item,descr,status,upper(nvl(hazardous,'N')) hazardous
    from custitem
   where custid = in_custid
     and (instr(','||in_item||',', ','||item||',', 1, 1) > 0
      or  in_item = 'ALL');

cursor curAsOfBeginSearch(in_facility IN varchar, in_item IN varchar2) is
SELECT uom,
       invstatus,
       inventoryclass,
       lotnumber,
       NVL(currentqty, 0) AS currentqty,
       NVL(NVL(currentweight, zci.item_weight(custid, item, uom) * currentqty), 0) AS currentweight
  FROM asofinventory AOI11
 WHERE facility = in_facility
   AND custid = in_custid
   AND item = in_item
   AND effdate = (SELECT MAX(effdate)
                    FROM asofinventory AOI21
                   WHERE AOI21.facility = in_facility
                     AND AOI21.custid = NVL(in_custid, UID)
                     AND AOI21.item = in_item
                     AND NVL(AOI21.lotnumber, '(none)') = NVL(AOI11.lotnumber, '(none)')
                     AND AOI21.uom = AOI11.uom
                     AND NVL(AOI21.inventoryclass, '(none)') = NVL(AOI11.inventoryclass, '(none)')
                     AND NVL(AOI21.invstatus, '(none)') = NVL(AOI11.invstatus, '(none)')
                     AND AOI21.effdate < TRUNC(in_begdate))
   AND invstatus <> 'SU'
   AND (lotnumber LIKE '%' || in_lotnumber || '%'
         OR NVL(lotnumber, '(none)') = NVL(in_lotnumber, '(none)')
         OR in_lotnumber = 'ALL')
   AND effdate < TRUNC(in_begdate)
   AND (currentqty <> 0
         OR EXISTS (SELECT 1
                      FROM asofinventorydtl aoid
                     WHERE aoid.facility = in_facility
                       AND aoid.custid = in_custid
                       AND aoid.item = in_item
                       AND NVL(aoid.lotnumber, '(none)') = NVL(AOI11.lotnumber, '(none)')
                       AND aoid.effdate >= TRUNC(in_begdate)
                       AND aoid.effdate <= TRUNC(in_enddate)
                       AND aoid.uom = AOI11.uom
                       AND NVL(aoid.inventoryclass, '(none)') = NVL(AOI11.inventoryclass, '(none)')
                       AND NVL(aoid.invstatus, '(none)') = NVL(AOI11.invstatus, '(none)')
                       AND ROWNUM = 1))
UNION
SELECT uom,
       invstatus,
       inventoryclass,
       lotnumber,
       0 AS currentqty,
       0 AS currentweight
  FROM asofinventory AOI12
 WHERE facility = in_facility
   AND custid = in_custid
   AND item = in_item
   AND effdate = (SELECT MIN(effdate)
                    FROM asofinventory AOI22
                   WHERE AOI22.facility = in_facility
                     AND AOI22.custid = in_custid
                     AND AOI22.item = in_item
                     AND NVL(AOI22.lotnumber, '(none)') = NVL(AOI12.lotnumber, '(none)')
                     AND AOI22.uom = AOI12.uom
                     AND AOI22.effdate >= TRUNC(in_begdate)
                     AND AOI22.effdate <= TRUNC(in_enddate)
                     AND NVL(AOI22.inventoryclass, '(none)') = NVL(AOI12.inventoryclass, '(none)')
                     AND NVL(AOI22.invstatus, '(none)') = NVL(AOI12.invstatus, '(none)'))
   AND invstatus <> 'SU'
   AND (lotnumber LIKE '%' || in_lotnumber || '%'
         OR NVL(lotnumber, '(none)') = NVL(in_lotnumber, '(none)')
         OR in_lotnumber = 'ALL')
   AND effdate >= TRUNC(in_begdate)
   AND effdate <= TRUNC(in_enddate)
   AND NOT EXISTS (SELECT 1
                     FROM asofinventory AOI23
                    WHERE AOI23.facility = in_facility
                      AND AOI23.custid = in_custid
                      AND AOI23.item = in_item
                      AND NVL(AOI23.lotnumber, '(none)') = NVL(AOI12.lotnumber, '(none)')
                      AND AOI23.uom = AOI12.uom
                      AND AOI23.effdate < TRUNC(in_begdate)
                      AND NVL(AOI23.inventoryclass, '(none)') = NVL(AOI12.inventoryclass, '(none)')
                      AND NVL(AOI23.invstatus, '(none)') = NVL(AOI12.invstatus, '(none)')
                      AND ROWNUM = 1);

cursor curAsOfDtlActivity(in_facility IN varchar, in_item IN varchar2, in_uom IN varchar2,
       in_invstatus IN varchar2, in_inventoryclass IN varchar2, in_lotnumber IN varchar2) is
  select effdate as effdate,
         trunc(lastupdate) as lastupdate,
         decode(trantype,'RR','RC',trantype) trantype,
         decode(trantype,'RR','Received',reason) reason,
         nvl(decode(trantype,'AD',0,orderid),0) as orderid,
         nvl(decode(trantype,'AD',0,shipid),0) as shipid,
         sum(nvl(adjustment,0)) adjustment,
         sum(nvl(nvl(weightadjustment,zci.item_weight(custid,item,uom)*adjustment),0)) weightadjustment
    from asofinventorydtl
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
     and nvl(uom,'(none)') = nvl(in_uom,'(none)')
     and effdate >= trunc(in_begdate)
     and effdate <= trunc(in_enddate)
     and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
     and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
   group by effdate,
            trunc(lastupdate),
            decode(trantype,'RR','RC',trantype),
            decode(trantype,'RR','Received',reason),
            nvl(decode(trantype,'AD',0,orderid),0),
            nvl(decode(trantype,'AD',0,shipid),0);

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
     and nvl(od.qtyrcvd,0) <> 0
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
         nvl(ld.carrier,oh.carrier);

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
     and nvl(od.qtyrcvd,0) <> 0
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
     and nvl(od.qtyrcvd,0) <> 0
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
         oh.billoflading,oh.carrier;

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

cursor curAsOfEndSearch(in_facility IN varchar, in_item IN varchar2, in_uom IN varchar2,
       in_invstatus IN varchar2, in_inventoryclass IN varchar2, in_lotnumber IN varchar2) is
  select sum(nvl(currentqty,0)) as currentqty,
         sum(nvl(nvl(currentweight,zci.item_weight(custid,item,uom)*currentqty),0)) as currentweight
    from asofinventory aoi1
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
     and uom = in_uom
     and effdate = (select max(effdate)
                      from asofinventory aoi2
                     where aoi2.facility = in_facility
                       and aoi2.custid = in_custid
                       and aoi2.item = in_item
                       and nvl(aoi2.lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
                       and aoi2.uom = in_uom
                       and aoi2.effdate <= trunc(in_enddate)
                       and nvl(aoi2.inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
                       and nvl(aoi2.invstatus,'(none)') = nvl(in_invstatus,'(none)'))
     and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
     and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)');
aoe curAsOfEndSearch%rowtype;

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

procedure get_asof_detail(in_facility IN varchar, in_item IN varchar, in_uom IN varchar2,
       in_invstatus IN varchar2, in_inventoryclass IN varchar2, in_lotnumber IN varchar2)
is
begin

for aod in curAsOfDtlActivity(in_facility, in_item, in_uom, in_invstatus, in_inventoryclass, in_lotnumber)
loop

  debugmsg('processing dtl ' || aod.trantype || ' item ' || in_item || ' uom ' || in_uom);

  if aod.trantype <> 'SH' then
    goto check_receipt;
  end if;

  if aod.orderid = 0 or aod.shipid = 0 then
    for cso in curShipmentOrders(in_facility,in_item,aod.lastupdate,aod.effdate,in_lotnumber)
    loop
      debugmsg('processing order ' || cso.orderid || '-' || cso.shipid);
      if rtrim(cso.shipto) is not null then
        open curConsignee(cso.shipto);
        fetch curConsignee into cso.shiptoname;
        close curConsignee;
      end if;

      for sp in curShippingPlates(cso.orderid,cso.shipid,in_item,
        in_lotnumber,in_uom,in_invstatus,in_inventoryclass)
      loop
        if nvl(sp.quantity,0) <> 0 then
          recCount := 0;
          select count(1)
            into recCount
            from asofinvact
           where sessionid = numSessionId
             and item = in_item
             and nvl(uom,'(none)') = nvl(in_uom,'(none)')
             and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
             and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
             and trantype = 'DT'
             and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
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
           (numSessionId,in_facility,in_custid,in_item,in_lotnumber,in_uom,in_invstatus,
            in_inventoryclass,'DT',aod.trantype,aod.effdate,
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
              and nvl(uom,'(none)') = nvl(in_uom,'(none)')
              and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
              and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
              and trantype = 'DT'
              and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
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
       and nvl(uom,'(none)') = nvl(in_uom,'(none)')
       and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
       and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
       and trantype = 'DT'
       and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
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
     (numSessionId,in_facility,in_custid,in_item,in_lotnumber,in_uom,in_invstatus,
      in_inventoryclass,'DT',aod.trantype,aod.effdate,
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
        and nvl(uom,'(none)') = nvl(in_uom,'(none)')
        and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
        and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
        and trantype = 'DT'
        and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
        and dtltrantype = aod.trantype
        and effdate = aod.effdate
        and orderid = aod.orderid
        and shipid = aod.shipid;
    end if;
  end if;

  goto continue_aod_loop;

<< check_receipt >>

  if aod.trantype <> 'RC' then
    goto check_return;
  end if;

  debugmsg('processing rc ' || aod.lastupdate);

  if aod.orderid = 0 or aod.shipid = 0 then
    for rp in curReceiptPlates(in_facility,in_item,in_lotnumber,
      in_uom,in_invstatus,in_inventoryclass, aod.lastupdate, aod.effdate)
    loop
      if rtrim(rp.Shipper) is not null then
        open curShipper(rp.Shipper);
        fetch curShipper into rp.shippername;
        close curShipper;
      end if;
      debugmsg('processing rc plate ' || rp.quantity);
      if nvl(rp.quantity,0) <> 0 then
        recCount := 0;
        select count(1)
          into recCount
          from asofinvact
         where sessionid = numSessionId
           and item = in_item
           and nvl(uom,'(none)') = nvl(in_uom,'(none)')
           and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
           and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
           and trantype = 'DT'
           and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
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
         (numSessionId,in_facility,in_custid,in_item,in_lotnumber,in_uom,in_invstatus,
          in_inventoryclass,'DT',aod.trantype,aod.effdate,
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
            and nvl(uom,'(none)') = nvl(in_uom,'(none)')
            and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
            and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
            and trantype = 'DT'
            and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
            and dtltrantype = aod.trantype
            and effdate = aod.effdate
            and orderid = rp.orderid
            and shipid = rp.shipid;
        end if;
      end if;
    end loop;
  else
    for ordp in curOrderDtlRcptPlates(aod.orderid,aod.shipid,in_item,
      in_lotnumber,in_uom,in_invstatus,in_inventoryclass)
    loop
      if rtrim(ordp.Shipper) is not null then
        open curShipper(ordp.Shipper);
        fetch curShipper into ordp.shippername;
        close curShipper;
      end if;
      debugmsg('processing rc plate ' || ordp.quantity);
      if nvl(ordp.quantity,0) <> 0 then
        recCount := 0;
        select count(1)
          into recCount
          from asofinvact
         where sessionid = numSessionId
           and item = in_item
           and nvl(uom,'(none)') = nvl(in_uom,'(none)')
           and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
           and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
           and trantype = 'DT'
           and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
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
         (numSessionId,in_facility,in_custid,in_item,in_lotnumber,in_uom,in_invstatus,
          in_inventoryclass,'DT',aod.trantype,aod.effdate,
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
            and nvl(uom,'(none)') = nvl(in_uom,'(none)')
            and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
            and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
            and trantype = 'DT'
            and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
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

  if aod.trantype <> 'RT' then
    goto check_adjustment;
  end if;

  debugmsg('processing rt ' || aod.lastupdate);

  if aod.orderid = 0 or aod.shipid = 0 then
    for rt in curReturnPlates(in_facility,in_item,in_lotnumber,
      in_uom,in_invstatus,in_inventoryclass, aod.lastupdate, aod.effdate)
    loop
      if rtrim(rt.Shipper) is not null then
        open curShipper(rt.Shipper);
        fetch curShipper into rt.shippername;
        close curShipper;
      end if;
      debugmsg('processing rt plate ' || rt.quantity);
      if nvl(rt.quantity,0) <> 0 then
       insert into asofinvact 
       (sessionid,facility,custid,item,lotnumber,uom,invstatus,
        inventoryclass,trantype,dtltrantype,effdate,
        qty,itemdesc,hazardous,invstatusabbrev,inventoryclassabbrev,
        custname,custaddr1,custaddr2,custcity,custstate,custzip,reporttitle,
        orderid,shipid,reason,consignee_or_supplier,consignee_or_supplier_name,lastupdate,
        reference,po,billoflading,
        weight) values
       (numSessionId,in_facility,in_custid,in_item,in_lotnumber,in_uom,in_invstatus,
        in_inventoryclass,'DT',aod.trantype,aod.effdate,
        rt.quantity,wrk.itemdesc,wrk.hazardous,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
        cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
        rt.orderid,rt.shipid,aod.reason,rt.shipper,rt.shippername,sysdate,
        rt.reference,rt.po,rt.billoflading,
        rt.weight);
      end if;
    end loop;
  else
    for ordp in curOrderDtlRcptPlates(aod.orderid,aod.shipid,in_item,
      in_lotnumber,in_uom,in_invstatus,in_inventoryclass)
    loop
      if rtrim(ordp.Shipper) is not null then
        open curShipper(ordp.Shipper);
        fetch curShipper into ordp.shippername;
        close curShipper;
      end if;
      debugmsg('processing rt plate ' || ordp.quantity);
      if nvl(ordp.quantity,0) <> 0 then
        insert into asofinvact 
        (sessionid,facility,custid,item,lotnumber,uom,invstatus,
         inventoryclass,trantype,dtltrantype,effdate,
         qty,itemdesc,hazardous,invstatusabbrev,inventoryclassabbrev,
         custname,custaddr1,custaddr2,custcity,custstate,custzip,reporttitle,
         orderid,shipid,reason,consignee_or_supplier,consignee_or_supplier_name,lastupdate,
         reference,po,billoflading,
         weight) values
        (numSessionId,in_facility,in_custid,in_item,in_lotnumber,in_uom,in_invstatus,
         in_inventoryclass,'DT',aod.trantype,aod.effdate,
         ordp.quantity,wrk.itemdesc,wrk.hazardous,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
         cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
         aod.orderid,aod.shipid,aod.reason,ordp.shipper,ordp.shippername,sysdate,
         ordp.reference,ordp.po, ordp.billoflading,
         ordp.weight);
      end if;
    end loop;
  end if;

  goto continue_aod_loop;

<< check_adjustment>>

  if aod.trantype <> 'AD' then
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
    (numSessionId,in_facility,in_custid,in_item,in_lotnumber,in_uom,in_invstatus,
     in_inventoryclass,'DT',aod.trantype,aod.effdate,
     aod.adjustment,wrk.itemdesc,wrk.hazardous,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
     cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
     null,null,aod.reason,null,null,sysdate,null,null,null,
     aod.weightadjustment);
  end if;

  goto continue_aod_loop;

<< unknown_type >>

  debugmsg('unknown asofdtl type');
  debugmsg(in_item || ' ' ||
            in_lotnumber || ' ' ||
            in_uom || ' ' ||
            in_invstatus || ' ' ||
            in_inventoryclass || ' ' ||
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
           '/' || aob.uom ||
           '/' || aob.lotnumber);
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
      (numSessionId,cf.facility,in_custid,cit.item,aob.lotnumber,aob.uom,aob.invstatus,
       aob.inventoryclass,'AA','XX',trunc(in_begdate),aob.currentqty,cit.descr,cit.hazardous,
       wrk.invstatusabbrev,wrk.inventoryclassabbrev,
       cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
       wrk.reporttitle,null,null,null,null,null,sysdate,null,null,null,
       aob.currentweight);

      get_asof_detail(cf.facility, cit.item, aob.uom, aob.invstatus, aob.inventoryclass, aob.lotnumber);

      open curAsOfEndSearch(cf.facility, cit.item, aob.uom, aob.invstatus, aob.inventoryclass, aob.lotnumber);
      fetch curAsOfEndSearch into aoe;
      close curAsOfEndSearch;

      insert into asofinvact 
      (sessionid,facility,custid,item,lotnumber,uom,invstatus,
       inventoryclass,trantype,dtltrantype,effdate,
       qty,itemdesc,hazardous,invstatusabbrev,inventoryclassabbrev,
       custname,custaddr1,custaddr2,custcity,custstate,custzip,reporttitle,
       orderid,shipid,reason,consignee_or_supplier,consignee_or_supplier_name,lastupdate,
       reference,po,billoflading,
       weight) values
      (numSessionId,cf.facility,in_custid,cit.item,aob.lotnumber,aob.uom,aob.invstatus,
       aob.inventoryclass,'ZZ','XX',trunc(in_enddate),aoe.currentqty,cit.descr,cit.hazardous,
       wrk.invstatusabbrev,wrk.inventoryclassabbrev,
       cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
       wrk.reporttitle,null,null,null,null,null,sysdate,null,null,null,
       aoe.currentweight);
    end loop;
  end loop;
end loop;

if (nvl(in_topallet,'N') = 'Y') then
    update asofinvact
    set uom = 'PT',
        qty = nvl(pacamasofinvactlotpkg.uom_qty_conv(custid, item, qty, 'EA', 'PT'),0),
        weight = nvl(pacamasofinvactlotpkg.uom_qty_conv(custid, item, weight, 'EA', 'PT'),0)
  where sessionid = numSessionId
    and uom = 'EA';
end if;

commit;

open aoi_cursor for
select *
   from asofinvact
  where sessionid = numSessionId;

end pacam_asofinvactitemproc2;
/

create or replace procedure pacam_asofinvactitemlotproc
(aoi_cursor IN OUT asofinvactpkg.aoi_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2)
as
begin
	pacam_asofinvactitemproc(aoi_cursor,in_custid,in_facility,in_item,in_lotnumber,in_begdate,in_enddate,'N',in_debug_yn);
end pacam_asofinvactitemlotproc;
/

create or replace procedure pacam_asofinvactlotproc
(aoi_cursor IN OUT asofinvactpkg.aoi_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2)
as
begin
	pacam_asofinvactitemproc(aoi_cursor,in_custid,in_facility,'ALL','ALL',in_begdate,in_enddate,'N',in_debug_yn);
end pacam_asofinvactlotproc;
/

CREATE OR REPLACE PACKAGE Body pacamasofinvactlotpkg AS


-- Private procedures


PROCEDURE from_uom_to_uom
   (in_custid   in varchar2,
    in_item     in varchar2,
    in_qty      in number,
    in_from_uom in varchar2,
    in_to_uom   in varchar2,
    in_skips    in varchar2,
    io_level    in out integer,
    io_qty      in out number,
    io_errmsg   in out varchar2)
is
begin

   zbut.from_uom_to_uom(in_custid, in_item, in_qty, in_from_uom, in_to_uom, in_skips,
      io_level, io_qty, io_errmsg);
   return;

end from_uom_to_uom;


-- Public functions


function uom_qty_conv
   (in_custid   in varchar2,
    in_item     in varchar2,
    in_qty      in number,
    in_from_uom in varchar2,
    in_to_uom   in varchar2)
return number
is
   msg varchar2(200);
   factor number;
   start_level integer := 1;
   rtnqty number := 0;
begin

   from_uom_to_uom(in_custid, in_item, 1, in_from_uom, in_to_uom, '', start_level, factor, msg);
   if msg = 'OKAY' then
   	  if in_qty >= 0 then
         rtnqty := ceil(in_qty * factor);
      else
         rtnqty := floor(in_qty * factor);
      end if;
   end if;
   return rtnqty;

exception
   when OTHERS then
      return 0;
end uom_qty_conv;


procedure pacam_asofinvactlotproc
(aoi_cursor IN OUT asofinvactpkg.aoi_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2)
as
begin
	pacam_asofinvactitemproc(aoi_cursor,in_custid,in_facility,'ALL','ALL',in_begdate,in_enddate,'N',in_debug_yn);
end pacam_asofinvactlotproc;


procedure pacam_asofinvactlotpltproc
(aoi_cursor IN OUT asofinvactpkg.aoi_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2)
as
numSessionId number;
begin
	pacam_asofinvactitemproc(aoi_cursor,in_custid,in_facility,'ALL','ALL',in_begdate,in_enddate,'Y',in_debug_yn);
end pacam_asofinvactlotpltproc;


procedure pacam_asofinvactitemlotproc
(aoi_cursor IN OUT asofinvactpkg.aoi_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2)
as
begin
	pacam_asofinvactitemproc(aoi_cursor,in_custid,in_facility,in_item,in_lotnumber,in_begdate,in_enddate,'N',in_debug_yn);
end pacam_asofinvactitemlotproc;
end pacamasofinvactlotpkg;
/

show errors package pacamasofinvactlotpkg;
show errors procedure pacam_asofinvactitemproc;
show errors procedure pacam_asofinvactitemlotproc;
show errors procedure pacam_asofinvactlotproc;
show errors package body pacamasofinvactlotpkg;
exit;

