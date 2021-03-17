drop table dre_asofinvactlot;

-- trantype column values:
--    AA-BegBal
--    DT-Detail
--       dtl_trantype column values:
--           SH-Shipment;
--           RC-Receipt;
--           RT-Return;
--           AD-Adjustmnent;
--    ZZ-EndBal

create table dre_asofinvactlot
(sessionid       number
,facility        varchar2(3)
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
,addlinfo        varchar2(20)
,invstat         varchar2(2)
,invabbr         varchar2(12)
,useritem1       varchar2(20)
,expirationdate  date
,manufacturedate date
);

create index dreasofinvactlotsessnid_idx
 on dre_asofinvactlot(sessionid,item,uom,invstatus,inventoryclass,trantype);

create index dreasofinvactlotlstpdt_idx
 on dre_asofinvactlot(lastupdate);


create or replace package dre_asofinvactlotPKG
as type aoi_type is ref cursor return dre_asofinvactlot%rowtype;
  function get_addlinfo(in_custid varchar2, in_item varchar2, in_lot varchar2) return varchar2;
  function get_useritem(in_custid varchar2, in_item varchar2, in_lot varchar2) return varchar2;
  function get_expdate(in_custid varchar2, in_item varchar2, in_lot varchar2) return date;
  function get_mfgdate(in_custid varchar2, in_item varchar2, in_lot varchar2) return date;
  function invstatus_abbrev(in_code varchar2) return varchar2;
  function inventoryclass_abbrev(in_code varchar2) return varchar2;
	procedure dre_asofinvactlotPROC
	(aoi_cursor IN OUT dre_asofinvactlotpkg.aoi_type
	,in_custid IN varchar2
	,in_facility IN varchar2
	,in_item IN varchar2
	,in_begdate IN date
	,in_enddate IN date
	,in_debug_yn IN varchar2);
end dre_asofinvactlotpkg;
/

create or replace procedure dre_asofinvactlotPROC
(aoi_cursor IN OUT dre_asofinvactlotpkg.aoi_type
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

cursor curCustItems is
   select item,descr,status
    from custitem
   where custid = in_custid
   and not exists (select item,descr,status
    from custitem
   where custid = in_custid
   		 and item =in_item)
		union
	select item,descr,status
    from custitem
   where custid = in_custid
   		 and item =in_item
   order by item;

cursor curAsOfBeginSearch(in_item IN varchar2) is
  select uom,invstatus,inventoryclass,lotnumber,max(effdate) as effdate
    from asofinventory
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and effdate < trunc(in_begdate)
     and invstatus != 'SU'
   group by lotnumber,uom,invstatus,inventoryclass
   order by lotnumber,uom,invstatus,inventoryclass;

cursor curAsOfDtlNoBegin(in_item IN varchar2, in_sessionid number) is
  select lotnumber,uom,invstatus,inventoryclass,max(effdate)
    from asofinventorydtl aod
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and effdate >= trunc(in_begdate)
     and effdate <= trunc(in_enddate)
     and invstatus != 'SU'
     and not exists
         (select * from dre_asofinvactlot act
           where act.sessionid = in_sessionid
             and act.item = in_item
             and nvl(act.lotnumber,'x') = nvl(aod.lotnumber,'x')
             and act.uom = aod.uom
             and act.invstatus = '--'
             and act.inventoryclass = '--')
   group by lotnumber,uom,invstatus,inventoryclass;

cursor curAsOfDtlActivity(in_item IN varchar2, in_uom varchar2) is
  select effdate,
         decode(trantype,'RC',lastupdate,'RT',lastupdate,null) as lastupdate,
         trantype,lotnumber,invstatus,inventoryclass,reason,
         sum(adjustment) as adjustment
    from asofinventorydtl
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and uom = in_uom
     and effdate >= trunc(in_begdate)
     and effdate <= trunc(in_enddate)
     and invstatus != 'SU'
   group by effdate,decode(trantype,'RC',lastupdate,'RT',lastupdate,null),
            trantype,lotnumber,invstatus,inventoryclass,reason;

cursor curShipmentOrders(in_effdate IN date) is
  select oh.orderid,oh.shipid,oh.ordertype,oh.custid,oh.fromfacility,oh.shipto,
         oh.shiptoname,oh.orderstatus,oh.reference,oh.po,
         nvl(oh.billoflading,ld.billoflading) as billoflading
    from loads ld, orderhdr oh
	where oh.dateshipped >= in_effdate
       and oh.dateshipped < (in_effdate + 1)
     and oh.loadno = ld.loadno(+);

cursor curShippingPlates(in_orderid number, in_shipid number,
  in_item varchar2, in_lotnumber varchar2, in_uom varchar2, in_invstatus varchar2,
  in_inventoryclass varchar2) is
  select sum(nvl(quantity,0) * -1) as qty
    from shippingplate
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'x') = nvl(in_lotnumber,'x')
     and invstatus = in_invstatus
     and inventoryclass = in_inventoryclass
     and unitofmeasure = in_uom
     and status = 'SH'
     and type in ('F','P');

cursor curReceiptLoads(in_statusdate IN date) is
  select loadno,loadtype,facility,loadstatus,statusupdate
    from loads
   where statusupdate = in_statusdate;

cursor curReceiptOrders(in_loadno number) is
  select oh.orderid,shipid,ordertype,custid,tofacility,shipper,
         shippername,orderstatus,reference,po,
         nvl(ld.billoflading,oh.billoflading) as billoflading,
         nvl(ld.carrier,oh.carrier) as carrier
    from loads ld, orderhdr oh
   where oh.loadno = in_loadno
     and oh.loadno = ld.loadno(+);

cursor curReceiptPlates(in_orderid number, in_shipid number,
  in_item varchar2, in_lotnumber varchar2, in_uom varchar2, in_invstatus varchar2,
  in_inventoryclass varchar2) is
  select sum(nvl(qtyrcvd,0)) as qty
    from orderdtlrcpt
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'x') = nvl(in_lotnumber,'x')
     and uom = in_uom
     and invstatus = in_invstatus
     and inventoryclass = in_inventoryclass;

cursor curAsOfEndSearch(in_item IN varchar2) is
  select uom,invstatus,inventoryclass,lotnumber,max(effdate) as effdate
    from asofinventory
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and effdate <= trunc(in_enddate)
     and invstatus != 'SU'
   group by lotnumber,uom,invstatus,inventoryclass
   order by lotnumber,uom,invstatus,inventoryclass;

cursor curConsignee(in_consignee varchar2) is
  select name
    from consignee
   where consignee = in_consignee;

cursor curCarrier(in_carrier varchar2) is
  select name
    from carrier
   where carrier = in_carrier;

cursor curAudit(in_sessionid number) is
 select *
   from dre_asofinvactlot
  where sessionid = in_sessionid
  order by item,lotnumber,uom,invstatus,inventoryclass,
           trantype,dtltrantype,effdate;

numSessionId number;
wrk dre_asofinvactlot%rowtype;
dtlQty dre_asofinvactlot.qty%type;
aobCount integer;
aoeCount integer;
dtlCount integer;
recQty integer;
recLoop integer;
recDate date;
begBal integer;
clcBal integer;

procedure debugmsg(in_text varchar2) is
begin
  if upper(rtrim(in_debug_yn)) = 'Y' then
    zut.prt(in_text);
  end if;
exception when others then
  null;
end;

procedure get_asof_detail
is
begin

for aod in curAsOfDtlActivity(wrk.item,wrk.uom)
loop

  debugmsg('processing dtl curAsOfDtlActivity');
  debugmsg('processing dtl ' || aod.trantype);
  debugmsg('processing dtl dt' || aod.effdate);

  if aod.trantype != 'SH' then
    goto check_receipt;
  end if;

  for so in curShipmentOrders(aod.effdate)
  loop
    if so.ordertype not in ('O','V','T','U') then
      goto continue_shipments_loop;
    end if;
    if so.custid <> in_custid then
      goto continue_shipments_loop;
    end if;
    if so.fromfacility <> in_facility then
      goto continue_shipments_loop;
    end if;
    if so.orderstatus <> '9' then
      goto continue_shipments_loop;
    end if;
    debugmsg('processing order ' || so.orderid || '-' || so.shipid);
    if rtrim(so.shipto) is not null then
      open curConsignee(so.shipto);
      fetch curConsignee into so.shiptoname;
      close curConsignee;
    end if;
    for sp in curShippingPlates(so.orderid,so.shipid,wrk.item,
      aod.lotnumber,wrk.uom,aod.invstatus,aod.inventoryclass)
    loop
      if nvl(sp.qty,0) != 0 then
       insert into dre_asofinvactlot values
       (numSessionId,in_facility,in_custid,wrk.item,aod.lotnumber,wrk.uom,'--',
        '--','DT',aod.trantype,aod.effdate,
        sp.qty,null,null,null,
        cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
        null,
        so.orderid,so.shipid,aod.reason,so.shipto,so.shiptoname,sysdate,
        so.reference, so.po, so.billoflading,
        zci.item_weight(in_custid,wrk.item,wrk.uom) * sp.qty,
        dre_asofinvactlotPKG.get_addlinfo(in_custid,wrk.item,aod.lotnumber),
        aod.invstatus,dre_asofinvactlotPKG.invstatus_abbrev(aod.invstatus),
        dre_asofinvactlotPKG.get_useritem(in_custid,wrk.item,aod.lotnumber),
        dre_asofinvactlotPKG.get_expdate(in_custid,wrk.item,aod.lotnumber),
        dre_asofinvactlotPKG.get_mfgdate(in_custid,wrk.item,aod.lotnumber));
      end if;
    end loop;
  << continue_shipments_loop >>
    null;
  end loop;

  goto continue_aod_loop;
<< check_receipt >>

  if aod.trantype != 'RC' then
    goto check_return;
  end if;

  debugmsg('processing rc ' || aod.lastupdate);

  recQty := 0;
  recLoop := 0;
  recDate := aod.lastupdate;

  while (1=1)
  loop
    for rl in curReceiptLoads(recDate)
    loop
      debugmsg('processing rc load ' || rl.loadno || ' ' ||
          rl.loadtype || ' ' || rl.facility || ' ' || rl.loadstatus);
      if rl.statusupdate <> aod.lastupdate then
        goto continue_receipts_loop;
      end if;
      if rl.loadtype not in ('INC','INT') then
        goto continue_receipts_loop;
      end if;
      if rl.facility <> in_facility then
        goto continue_receipts_loop;
      end if;
      if rl.loadstatus <> 'R' then
        goto continue_receipts_loop;
      end if;
      for ro in curReceiptOrders(rl.loadno)
      loop
        debugmsg('processing rc order ' || ro.orderid || '-' || ro.shipid || ' '
            || ro.custid || ' ' || ro.tofacility || ' ' || ro.ordertype ||
            ' ' || ro.orderstatus);
        if ro.custid <> in_custid then
          goto continue_receiptorder_loop;
        end if;
        if ro.tofacility <> in_facility then
          goto continue_receiptorder_loop;
        end if;
        if ro.ordertype not in ('R','T','C','U') then
          goto continue_receiptorder_loop;
        end if;
        if ro.orderstatus <> 'R' then
          goto continue_receiptorder_loop;
        end if;
        if rtrim(ro.carrier) is not null then
          open curCarrier(ro.carrier);
          fetch curCarrier into ro.shippername;
          close curCarrier;
        end if;
        for rp in curReceiptPlates(ro.orderid,ro.shipid,wrk.item,
          aod.lotnumber,wrk.uom,aod.invstatus,aod.inventoryclass)
        loop
          debugmsg('processing rc plate ' || rp.qty);
          if nvl(rp.qty,0) != 0 then
           insert into dre_asofinvactlot values
           (numSessionId,in_facility,in_custid,wrk.item,aod.lotnumber,wrk.uom,'--',
            '--','DT',aod.trantype,aod.effdate,
            rp.qty,null,null,null,
            cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
            null,
            ro.orderid,ro.shipid,aod.reason,ro.shipper,ro.shippername,sysdate,
            ro.reference,ro.po,ro.billoflading,
            zci.item_weight(in_custid,wrk.item,wrk.uom) * rp.qty,
            dre_asofinvactlotPKG.get_addlinfo(in_custid,wrk.item,aod.lotnumber),
            aod.invstatus,dre_asofinvactlotPKG.invstatus_abbrev(aod.invstatus),
            dre_asofinvactlotPKG.get_useritem(in_custid,wrk.item,aod.lotnumber),
            dre_asofinvactlotPKG.get_expdate(in_custid,wrk.item,aod.lotnumber),
            dre_asofinvactlotPKG.get_mfgdate(in_custid,wrk.item,aod.lotnumber));
           recQty := recQty + nvl(rp.qty,0);
          end if;
        end loop;
      << continue_receiptorder_loop >>
        null;
      end loop;
    << continue_receipts_loop >>
      null;
    end loop;
    if (recQty >= aod.adjustment) or (recLoop = 5) then
      exit;
    else
      recLoop := recLoop + 1;
      recDate := recDate - .00001157;
    end if;
  end loop;
  goto continue_aod_loop;

<< check_return >>

  if aod.trantype != 'RT' then
    goto check_adjustment;
  end if;

  recQty := 0;
  recLoop := 0;
  recDate := aod.lastupdate;

  while (1=1)
  loop
    for rl in curReceiptLoads(recDate)
    loop
      if rl.statusupdate <> aod.lastupdate then
        goto continue_returns_loop;
      end if;
      if rl.loadtype not in ('INC','INT') then
        goto continue_returns_loop;
      end if;
      if rl.facility <> in_facility then
        goto continue_returns_loop;
      end if;
      for ro in curReceiptOrders(rl.loadno)
      loop
        if ro.custid <> in_custid then
          goto continue_returnorder_loop;
        end if;
        if ro.tofacility <> in_facility then
          goto continue_returnorder_loop;
        end if;
        if ro.ordertype not in ('Q') then
          goto continue_returnorder_loop;
        end if;
        if rtrim(ro.Carrier) is not null then
          open curCarrier(ro.Carrier);
          fetch curCarrier into ro.shippername;
          close curCarrier;
        end if;
        for rp in curReceiptPlates(ro.orderid,ro.shipid,wrk.item,
          aod.lotnumber,wrk.uom,aod.invstatus,aod.inventoryclass)
        loop
          if nvl(rp.qty,0) != 0 then
           insert into dre_asofinvactlot values
           (numSessionId,in_facility,in_custid,wrk.item,aod.lotnumber,wrk.uom,'--',
            '--','DT',aod.trantype,aod.effdate,
            rp.qty,null,null,null,
            cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
            null,
            ro.orderid,ro.shipid,aod.reason,ro.Carrier,ro.shippername,sysdate,
            ro.reference,ro.po,ro.billoflading,
            zci.item_weight(in_custid,wrk.item,wrk.uom) * rp.qty,
            dre_asofinvactlotPKG.get_addlinfo(in_custid,wrk.item,aod.lotnumber),
            aod.invstatus,dre_asofinvactlotPKG.invstatus_abbrev(aod.invstatus),
            dre_asofinvactlotPKG.get_useritem(in_custid,wrk.item,aod.lotnumber),
            dre_asofinvactlotPKG.get_expdate(in_custid,wrk.item,aod.lotnumber),
            dre_asofinvactlotPKG.get_mfgdate(in_custid,wrk.item,aod.lotnumber));
           recQty := recQty + nvl(rp.qty,0);
          end if;
        end loop;
      << continue_returnorder_loop >>
        null;
      end loop;
    << continue_returns_loop >>
      null;
    end loop;
    if (recQty >= aod.adjustment) or (recLoop = 5) then
      exit;
    else
      recLoop := recLoop + 1;
      recDate := recDate - .00001157;
    end if;
  end loop;

  goto continue_aod_loop;

<< check_adjustment>>

  if aod.trantype != 'AD' then
    goto unknown_type;
  end if;

  if aod.adjustment <> 0 then
    insert into dre_asofinvactlot values
    (numSessionId,in_facility,in_custid,wrk.item,aod.lotnumber,wrk.uom,'--',
     '--','DT',aod.trantype,aod.effdate,
     aod.adjustment,null,null,null,
     cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
     null,
     null,null,aod.reason,null,null,sysdate,null,null,null,
     zci.item_weight(in_custid,wrk.item,wrk.uom) * aod.adjustment,
     dre_asofinvactlotPKG.get_addlinfo(in_custid,wrk.item,aod.lotnumber),
     aod.invstatus,dre_asofinvactlotPKG.invstatus_abbrev(aod.invstatus),
     dre_asofinvactlotPKG.get_useritem(in_custid,wrk.item,aod.lotnumber),
     dre_asofinvactlotPKG.get_expdate(in_custid,wrk.item,aod.lotnumber),
     dre_asofinvactlotPKG.get_mfgdate(in_custid,wrk.item,aod.lotnumber));
  end if;

  goto continue_aod_loop;

<< unknown_type >>

  debugmsg('unknown asofdtl type');
  debugmsg(wrk.item || ' ' ||
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

delete from dre_asofinvactlot
where sessionid = numSessionId;
commit;

delete from dre_asofinvactlot
where lastupdate < trunc(sysdate);
commit;

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

for cit in curCustItems
loop
 aobCount := 0;
 wrk.qty := 0;
 wrk.item := cit.item;
 debugmsg('processing item for begin bal ' || wrk.item);
 for aob in curAsOfBeginSearch(cit.item)
 loop
   debugmsg('processing status/class for begin bal ' ||
        aob.lotnumber || ' ' ||
        aob.invstatus ||
        '/' || aob.inventoryclass);
   if aobCount = 0 then
     wrk.uom := aob.uom;
     wrk.lotnumber := aob.lotnumber;
   end if;
   aobCount := aobCount + 1;
   if (wrk.uom <> aob.uom) or
      (nvl(wrk.lotnumber,'x') <> nvl(aob.lotnumber,'x')) then
     wrk.invstatusabbrev := '--';
     wrk.inventoryclassabbrev := '--';
     debugmsg('insert begin bal1 ' || wrk.qty);
     insert into dre_asofinvactlot values
     (numSessionId,in_facility,in_custid,cit.item,wrk.lotnumber,wrk.uom,'--',
      '--','AA',null,trunc(in_begdate),wrk.qty,cit.descr,
      wrk.invstatusabbrev,wrk.inventoryclassabbrev,
      cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
      wrk.reporttitle,null,null,null,null,null,sysdate,null,null,null,
      zci.item_weight(in_custid,cit.item,wrk.uom) * wrk.qty,
      dre_asofinvactlotPKG.get_addlinfo(in_custid,cit.item,wrk.lotnumber),
      aob.invstatus,dre_asofinvactlotPKG.invstatus_abbrev(aob.invstatus),
      dre_asofinvactlotPKG.get_useritem(in_custid,cit.item,wrk.lotnumber),
      dre_asofinvactlotPKG.get_expdate(in_custid,cit.item,wrk.lotnumber),
      dre_asofinvactlotPKG.get_mfgdate(in_custid,cit.item,wrk.lotnumber));
     wrk.invstatus := '--';
     wrk.inventoryclass := '--';
     wrk.uom := aob.uom;
     wrk.lotnumber := aob.lotnumber;
     wrk.qty := 0;
   end if;
   dtlQty := 0;
   select currentqty
     into dtlQty
     from asofinventory
    where facility = in_facility
      and custid = in_custid
      and item = cit.item
      and nvl(lotnumber,'x') = nvl(aob.lotnumber,'x')
      and effdate = aob.effdate
      and invstatus = aob.invstatus
      and inventoryclass = aob.inventoryclass
      and uom = aob.uom;
   wrk.qty := wrk.qty + dtlQty;
 end loop;
 if (aobCount <> 0) then
   wrk.invstatusabbrev := '--';
   wrk.inventoryclassabbrev := '--';
   debugmsg('insert begin bal2 ' || wrk.qty);
   insert into dre_asofinvactlot values
   (numSessionId,in_facility,in_custid,cit.item,wrk.lotnumber,wrk.uom,'--',
    '--','AA',null,trunc(in_begdate),wrk.qty,cit.descr,
    wrk.invstatusabbrev,wrk.inventoryclassabbrev,
    cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
    wrk.reporttitle,null,null,null,null,null,sysdate,null,null,null,
    zci.item_weight(in_custid,cit.item,wrk.uom) * wrk.qty,
    dre_asofinvactlotPKG.get_addlinfo(in_custid,cit.item,wrk.lotnumber),
    '--','',dre_asofinvactlotPKG.get_useritem(in_custid,cit.item,wrk.lotnumber),
    dre_asofinvactlotPKG.get_expdate(in_custid,cit.item,wrk.lotnumber),
    dre_asofinvactlotPKG.get_mfgdate(in_custid,cit.item,wrk.lotnumber));
 end if;
 aobCount := 0;
 for ada in curAsOfDtlNoBegin(cit.item, numSessionId)
 loop
   debugmsg('processing status/class for NO begin bal ' ||
        ada.lotnumber || ' ' ||
        ada.invstatus ||
        '/' || ada.inventoryclass);
   if aobCount = 0 then
     wrk.uom := ada.uom;
     wrk.lotnumber := ada.lotnumber;
   end if;
   aobCount := aobCount + 1;
   if (wrk.uom <> ada.uom) or
      (nvl(wrk.lotnumber,'x') <> nvl(ada.lotnumber,'x')) then
     wrk.invstatusabbrev := '--';
     wrk.inventoryclassabbrev := '--';
     debugmsg('insert begin bal3 ' || wrk.qty);
     insert into dre_asofinvactlot values
     (numSessionId,in_facility,in_custid,cit.item,wrk.lotnumber,wrk.uom,'--',
      '--','AA',null,trunc(in_begdate),0,cit.descr,
      wrk.invstatusabbrev,wrk.inventoryclassabbrev,
      cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
      wrk.reporttitle,null,null,null,null,null,sysdate,null,null,null,0,
      dre_asofinvactlotPKG.get_addlinfo(in_custid,cit.item,wrk.lotnumber),
      ada.invstatus,dre_asofinvactlotPKG.invstatus_abbrev(ada.invstatus),
      dre_asofinvactlotPKG.get_useritem(in_custid,cit.item,wrk.lotnumber),
      dre_asofinvactlotPKG.get_expdate(in_custid,cit.item,wrk.lotnumber),
      dre_asofinvactlotPKG.get_mfgdate(in_custid,cit.item,wrk.lotnumber));
     wrk.invstatusabbrev := '--';
     wrk.inventoryclassabbrev := '--';
     wrk.uom := ada.uom;
     wrk.lotnumber := ada.lotnumber;
   end if;
 end loop;
 if (aobCount <> 0) then
   debugmsg('insert begin bal4 ' || wrk.qty);
   insert into dre_asofinvactlot values
   (numSessionId,in_facility,in_custid,cit.item,wrk.lotnumber,wrk.uom,'--',
    '--','AA',null,trunc(in_begdate),0,cit.descr,
    wrk.invstatusabbrev,wrk.inventoryclassabbrev,
    cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
    wrk.reporttitle,null,null,null,null,null,sysdate,null,null,null,0,
    dre_asofinvactlotPKG.get_addlinfo(in_custid,cit.item,wrk.lotnumber),
    '--','',dre_asofinvactlotPKG.get_useritem(in_custid,cit.item,wrk.lotnumber),
    dre_asofinvactlotPKG.get_expdate(in_custid,cit.item,wrk.lotnumber),
    dre_asofinvactlotPKG.get_mfgdate(in_custid,cit.item,wrk.lotnumber));
 end if;
 get_asof_detail;
 commit;
end loop;

for cit in curCustItems
loop
 debugmsg('processing item for end bal ' || wrk.item);
 aoeCount := 0;
 wrk.qty := 0;
 wrk.item := cit.item;
 for aoe in curAsOfEndSearch(cit.item)
 loop
   debugmsg('processing status/class for end bal ' ||
        aoe.lotnumber || ' ' ||
        aoe.invstatus ||
        '/' || aoe.inventoryclass || ' ' || aoeCount);
   if aoeCount = 0 then
     wrk.uom := aoe.uom;
     wrk.lotnumber := aoe.lotnumber;
   end if;
   aoeCount := aoeCount + 1;
   if (wrk.uom <> aoe.uom) or
      (nvl(wrk.lotnumber,'x') <> nvl(aoe.lotnumber,'x')) then
     wrk.invstatusabbrev := '--';
     wrk.inventoryclassabbrev := '--';
     debugmsg('insert end bal1 ' || wrk.qty);
     insert into dre_asofinvactlot values
     (numSessionId,in_facility,in_custid,cit.item,wrk.lotnumber,wrk.uom,'--',
      '--','ZZ',null,trunc(in_enddate),wrk.qty,cit.descr,
      wrk.invstatusabbrev,wrk.inventoryclassabbrev,
      cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
      null,null,null,null,null,null,sysdate,null,null,null,
      zci.item_weight(in_custid,cit.item,wrk.uom) * wrk.qty,
      dre_asofinvactlotPKG.get_addlinfo(in_custid,cit.item,wrk.lotnumber),
      aoe.invstatus,dre_asofinvactlotPKG.invstatus_abbrev(aoe.invstatus),
      dre_asofinvactlotPKG.get_useritem(in_custid,cit.item,wrk.lotnumber),
      dre_asofinvactlotPKG.get_expdate(in_custid,cit.item,wrk.lotnumber),
      dre_asofinvactlotPKG.get_mfgdate(in_custid,cit.item,wrk.lotnumber));
     wrk.invstatus := aoe.invstatus;
     wrk.inventoryclass := aoe.inventoryclass;
     wrk.uom := aoe.uom;
     wrk.lotnumber := aoe.lotnumber;
     wrk.qty := 0;
   end if;
   dtlQty := 0;
   select currentqty
     into dtlQty
     from asofinventory
    where facility = in_facility
      and custid = in_custid
      and item = cit.item
      and nvl(lotnumber,'x') = nvl(aoe.lotnumber,'x')
      and effdate = aoe.effdate
      and invstatus = aoe.invstatus
      and inventoryclass = aoe.inventoryclass
      and uom = aoe.uom;
   wrk.qty := wrk.qty + dtlQty;
 end loop;
 if (aoeCount <> 0) then
   wrk.invstatusabbrev := '--';
   wrk.inventoryclassabbrev := '--';
   debugmsg('insert end bal2 ' || wrk.qty);
   insert into dre_asofinvactlot values
   (numSessionId,in_facility,in_custid,cit.item,wrk.lotnumber,wrk.uom,'--',
    '--','ZZ',null,trunc(in_enddate),wrk.qty,cit.descr,
    wrk.invstatusabbrev,wrk.inventoryclassabbrev,
    cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
    null,null,null,null,null,null,sysdate,null,null,null,
    zci.item_weight(in_custid,cit.item,wrk.uom) * wrk.qty,
    dre_asofinvactlotPKG.get_addlinfo(in_custid,cit.item,wrk.lotnumber),
    '--','',dre_asofinvactlotPKG.get_useritem(in_custid,cit.item,wrk.lotnumber),
    dre_asofinvactlotPKG.get_expdate(in_custid,cit.item,wrk.lotnumber),
    dre_asofinvactlotPKG.get_mfgdate(in_custid,cit.item,wrk.lotnumber));
 end if;
 commit;
-- suppress zero-balance
   for zb in
     (select lotnumber,invstatus,inventoryclass,uom
        from dre_asofinvactlot
       where SessionId = numSessionId
         and item = cit.item
         and trantype = 'ZZ'
         and qty = 0
         )
   loop
     delete from dre_asofinvactlot ao1
           where SessionId = numSessionId
            and item = cit.item
            and nvl(lotnumber,'x') = nvl(zb.lotnumber,'x')
            and invstatus = zb.invstatus
            and inventoryclass = zb.inventoryclass
            and uom = zb.uom
            and qty = 0
            and not exists
              (select *
                 from dre_asofinvactlot ao2
                where ao1.sessionid = ao2.sessionid
                  and ao1.item = ao2.item
                  and nvl(ao1.lotnumber,'x') = nvl(ao2.lotnumber,'x')
                  and ao1.invstatus = ao2.invstatus
                  and ao1.inventoryclass = ao2.inventoryclass
                  and ao1.uom = ao2.uom
                  and ao2.trantype = 'DT');
   end loop;
 commit;
end loop;

if upper(in_debug_yn) = 'Y' then
  wrk.trantype := 'x';
  for aud in curAudit(numSessionId)
  loop
    if (aud.trantype = 'ZZ') then
      if clcBal <> aud.qty then
        debugmsg('out-of-balance ' || aud.item || ' calc '
          || clcBal || ' end ' || aud.qty);
      end if;
    end if;
    if aud.trantype = 'AA' then
      begBal := aud.qty;
      clcBal := begBal;
    end if;
    if aud.trantype = 'DT' then
      clcBal := clcBal + aud.qty;
    end if;
  end loop;
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
,addlinfo
,invstat
,invabbr
,useritem1
,expirationdate
,manufacturedate
   from dre_asofinvactlot
  where sessionid = numSessionId
  order by item,lotnumber,uom,invstatus,inventoryclass,
           trantype,dtltrantype,effdate;

end dre_asofinvactlotPROC;
/
CREATE OR REPLACE PACKAGE Body dre_asofinvactlotPKG AS

function get_addlinfo(in_custid varchar2, in_item varchar2, in_lot varchar2) return varchar2
is
CURSOR curPlate(in_custid varchar2, in_item varchar2, in_lot varchar2) IS
select expirationdate, manufacturedate, useritem1, useritem2
  from plate
 where custid = in_custid
   and item = in_item
   and nvl(lotnumber,'x') = nvl(in_lot,'x')
order by expirationdate, manufacturedate, useritem1, useritem2;

PL curPlate%rowtype;

CURSOR curDPlate(in_custid varchar2, in_item varchar2, in_lot varchar2) IS
select expirationdate, manufacturedate, useritem1, useritem2
  from deletedplate
 where custid = in_custid
   and item = in_item
   and nvl(lotnumber,'x') = nvl(in_lot,'x')
order by expirationdate, manufacturedate, useritem1, useritem2;

DPL curDPlate%rowtype;

addlinfo varchar2(20);
begin

addlinfo := '';

OPEN curPlate(in_custid, in_item, in_lot);
LOOP
  FETCH curPlate INTO PL;
  EXIT WHEN curPlate%NOTFOUND;

  if PL.expirationdate is not null then
	addlinfo := 'EXP '||to_char(PL.expirationdate,'MM/DD/YYYY');
  elsif PL.manufacturedate is not null then
	addlinfo := 'MFG '||to_char(PL.manufacturedate,'MM/DD/YYYY');
  elsif PL.useritem1 is not null then
	addlinfo := PL.useritem1;
  elsif PL.useritem2 is not null then
	addlinfo := PL.useritem2;
  end if;

  EXIT WHEN addlinfo <> '';
END LOOP;
CLOSE curPlate;

if addlinfo = '' then
  OPEN curDPlate(in_custid, in_item, in_lot);
  LOOP
    FETCH curDPlate INTO DPL;
    EXIT WHEN curDPlate%NOTFOUND;

    if DPL.expirationdate is not null then
      addlinfo := 'EXP '||to_char(DPL.expirationdate,'MM/DD/YYYY');
    elsif DPL.manufacturedate is not null then
      addlinfo := 'MFG '||to_char(DPL.manufacturedate,'MM/DD/YYYY');
    elsif DPL.useritem1 is not null then
      addlinfo := DPL.useritem1;
    elsif DPL.useritem2 is not null then
      addlinfo := DPL.useritem2;
    end if;

    EXIT WHEN addlinfo <> '';
  END LOOP;
  CLOSE curDPlate;
end if;

return addlinfo;

exception when others then
  return '';
end;

function get_useritem(in_custid varchar2, in_item varchar2, in_lot varchar2) return varchar2
is
CURSOR curPlate(in_custid varchar2, in_item varchar2, in_lot varchar2) IS
select useritem1, useritem2
  from plate
 where custid = in_custid
   and item = in_item
   and nvl(lotnumber,'x') = nvl(in_lot,'x')
order by lastupdate;

PL curPlate%rowtype;

CURSOR curDPlate(in_custid varchar2, in_item varchar2, in_lot varchar2) IS
select useritem1, useritem2
  from deletedplate
 where custid = in_custid
   and item = in_item
   and nvl(lotnumber,'x') = nvl(in_lot,'x')
order by lastupdate;

DPL curDPlate%rowtype;

useritem varchar2(50);
begin

useritem := '';

OPEN curPlate(in_custid, in_item, in_lot);
LOOP
  FETCH curPlate INTO PL;
  EXIT WHEN curPlate%NOTFOUND;

  if PL.useritem1 is not null then
	useritem := PL.useritem1;
  elsif PL.useritem2 is not null then
	useritem := PL.useritem2;
  end if;

  EXIT WHEN useritem <> '';
END LOOP;
CLOSE curPlate;

if useritem = '' then
  OPEN curDPlate(in_custid, in_item, in_lot);
  LOOP
    FETCH curDPlate INTO DPL;
    EXIT WHEN curDPlate%NOTFOUND;

    if DPL.useritem1 is not null then
      useritem := DPL.useritem1;
    elsif DPL.useritem2 is not null then
      useritem := DPL.useritem2;
    end if;

    EXIT WHEN useritem <> '';
  END LOOP;
  CLOSE curDPlate;
end if;

return useritem;

exception when others then
  return '';
end;

function get_expdate(in_custid varchar2, in_item varchar2, in_lot varchar2) return date
is
CURSOR curPlate(in_custid varchar2, in_item varchar2, in_lot varchar2) IS
select expirationdate
  from plate
 where custid = in_custid
   and item = in_item
   and nvl(lotnumber,'x') = nvl(in_lot,'x')
order by lastupdate;

PL curPlate%rowtype;

CURSOR curDPlate(in_custid varchar2, in_item varchar2, in_lot varchar2) IS
select expirationdate
  from deletedplate
 where custid = in_custid
   and item = in_item
   and nvl(lotnumber,'x') = nvl(in_lot,'x')
order by lastupdate;

DPL curDPlate%rowtype;

expdate date;
begin

expdate := null;

OPEN curPlate(in_custid, in_item, in_lot);
LOOP
  FETCH curPlate INTO PL;
  EXIT WHEN curPlate%NOTFOUND;

  if PL.expirationdate is not null then
	expdate := PL.expirationdate;
  end if;

  EXIT WHEN expdate is not null;
END LOOP;
CLOSE curPlate;

if expdate is null then
  OPEN curDPlate(in_custid, in_item, in_lot);
  LOOP
    FETCH curDPlate INTO DPL;
    EXIT WHEN curDPlate%NOTFOUND;

    if DPL.expirationdate is not null then
      expdate := DPL.expirationdate;
    end if;

    EXIT WHEN expdate is not null;
  END LOOP;
  CLOSE curDPlate;
end if;

return expdate;

exception when others then
  return null;
end;

function get_mfgdate(in_custid varchar2, in_item varchar2, in_lot varchar2) return date
is
CURSOR curPlate(in_custid varchar2, in_item varchar2, in_lot varchar2) IS
select manufacturedate
  from plate
 where custid = in_custid
   and item = in_item
   and nvl(lotnumber,'x') = nvl(in_lot,'x')
order by lastupdate;

PL curPlate%rowtype;

CURSOR curDPlate(in_custid varchar2, in_item varchar2, in_lot varchar2) IS
select manufacturedate
  from deletedplate
 where custid = in_custid
   and item = in_item
   and nvl(lotnumber,'x') = nvl(in_lot,'x')
order by lastupdate;

DPL curDPlate%rowtype;

mfgdate date;
begin

mfgdate := null;

OPEN curPlate(in_custid, in_item, in_lot);
LOOP
  FETCH curPlate INTO PL;
  EXIT WHEN curPlate%NOTFOUND;

  if PL.manufacturedate is not null then
	mfgdate := PL.manufacturedate;
  end if;

  EXIT WHEN mfgdate is not null;
END LOOP;
CLOSE curPlate;

if mfgdate is null then
  OPEN curDPlate(in_custid, in_item, in_lot);
  LOOP
    FETCH curDPlate INTO DPL;
    EXIT WHEN curDPlate%NOTFOUND;

    if DPL.manufacturedate is not null then
      mfgdate := DPL.manufacturedate;
    end if;

    EXIT WHEN mfgdate is not null;
  END LOOP;
  CLOSE curDPlate;
end if;

return mfgdate;

exception when others then
  return null;
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

procedure dre_asofinvactlotPROC
(aoi_cursor IN OUT dre_asofinvactlotpkg.aoi_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_item IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2)
as
begin
  dre_asofinvactlotPROC(aoi_cursor, in_custid, in_facility, in_item, in_begdate, in_enddate, in_debug_yn);
end dre_asofinvactlotPROC;
end dre_asofinvactlotPKG;
/
create or replace procedure dre_asofinvactlotbyitemPROC
(aoi_cursor IN OUT dre_asofinvactlotpkg.aoi_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_item IN varchar2
,in_lotnumber IN varchar2
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
  select item,descr,status
    from custitem
   where custid = in_custid
     and (instr(','||in_item||',', ','||item||',', 1, 1) > 0
      or  in_item = 'ALL')
   order by item;

cursor curAsOfBeginSearch(in_facility IN varchar, in_item IN varchar2) is
  select uom,invstatus,inventoryclass,lotnumber,nvl(currentqty,0) as currentqty,
         nvl(nvl(currentweight,zci.item_weight(custid,item,uom)*currentqty),0) as currentweight
    from asofinventory aoi1
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and effdate < trunc(in_begdate)
     and invstatus != 'SU'
     and (nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
      or  instr(','||in_lotnumber||',', ','||lotnumber||',', 1, 1) > 0
      or  in_lotnumber='ALL')
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
     and (nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
      or  instr(','||in_lotnumber||',', ','||lotnumber||',', 1, 1) > 0
      or  in_lotnumber='ALL')
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
     and (nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
      or  instr(','||in_lotnumber||',', ','||lotnumber||',', 1, 1) > 0
      or  in_lotnumber='ALL')
   group by effdate,
            trunc(lastupdate),
            decode(trantype,'RR','RC',trantype),
            decode(trantype,'RR','Received',reason),
            uom,invstatus,inventoryclass,lotnumber,
            nvl(decode(trantype,'AD',0,orderid),0),
            nvl(decode(trantype,'AD',0,shipid),0)
   order by uom,invstatus,inventoryclass,lotnumber;

cursor curShipmentOrders(in_facility IN varchar, in_item IN varchar2, in_lastupdate IN date, in_effdate IN date, in_lotnumber IN varchar2) is
  select distinct oh.orderid,oh.shipid,oh.ordertype,oh.custid,oh.fromfacility,oh.shipto,
         oh.shiptoname,oh.orderstatus,oh.reference,oh.po,
         nvl(oh.billoflading,ld.billoflading) as billoflading
    from shippingplate sp, orderhdr oh, loads ld
   where sp.facility = in_facility
     and sp.custid = in_custid
     and sp.item = in_item
     and nvl(sp.lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
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
     and (nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
      or  instr(','||in_lotnumber||',', ','||lotnumber||',', 1, 1) > 0
      or  in_lotnumber='ALL')
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

  wrk.invstatusabbrev := dre_asofinvactlotPKG.invstatus_abbrev(aod.invstatus);
  wrk.inventoryclassabbrev := dre_asofinvactlotPKG.inventoryclass_abbrev(aod.inventoryclass);

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
             and nvl(lotnumber,'(none)') = nvl(aod.lotnumber,'(none)')
             and dtltrantype = aod.trantype
             and effdate = aod.effdate
             and orderid = cso.orderid
             and shipid = cso.shipid;
          if nvl(recCount,0) = 0 then
           insert into dre_asofinvactlot values
           (numSessionId,in_facility,in_custid,in_item,aod.lotnumber,aod.uom,aod.invstatus,
            aod.inventoryclass,'DT',aod.trantype,aod.effdate,
            sp.quantity,wrk.itemdesc,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
            cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
            cso.orderid,cso.shipid,aod.reason,cso.shipto,cso.shiptoname,sysdate,
            cso.reference,cso.po,cso.billoflading,sp.weight,
            dre_asofinvactlotPKG.get_addlinfo(in_custid,in_item,aod.lotnumber),
            aod.invstatus,wrk.invstatusabbrev,
            dre_asofinvactlotPKG.get_useritem(in_custid,in_item,aod.lotnumber),
            dre_asofinvactlotPKG.get_expdate(in_custid,in_item,aod.lotnumber),
            dre_asofinvactlotPKG.get_mfgdate(in_custid,in_item,aod.lotnumber));
          else
           update dre_asofinvactlot
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
      from dre_asofinvactlot
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
     insert into dre_asofinvactlot values
     (numSessionId,in_facility,in_custid,in_item,aod.lotnumber,aod.uom,aod.invstatus,
      aod.inventoryclass,'DT',aod.trantype,aod.effdate,
      aod.adjustment,wrk.itemdesc,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
      cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
      co.orderid,co.shipid,aod.reason,co.shipto,co.shiptoname,sysdate,
      co.reference,co.po,co.billoflading,aod.weightadjustment,
      dre_asofinvactlotPKG.get_addlinfo(in_custid,in_item,aod.lotnumber),
      aod.invstatus,wrk.invstatusabbrev,
      dre_asofinvactlotPKG.get_useritem(in_custid,in_item,aod.lotnumber),
      dre_asofinvactlotPKG.get_expdate(in_custid,in_item,aod.lotnumber),
      dre_asofinvactlotPKG.get_mfgdate(in_custid,in_item,aod.lotnumber));
    else
     update dre_asofinvactlot
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
          from dre_asofinvactlot
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
         insert into dre_asofinvactlot values
         (numSessionId,in_facility,in_custid,in_item,aod.lotnumber,aod.uom,aod.invstatus,
          aod.inventoryclass,'DT',aod.trantype,aod.effdate,
          rp.quantity,wrk.itemdesc,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
          cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
          rp.orderid,rp.shipid,aod.reason,rp.shipper,rp.shippername,sysdate,
          rp.reference,rp.po,rp.billoflading,rp.weight,
          dre_asofinvactlotPKG.get_addlinfo(in_custid,in_item,aod.lotnumber),
          aod.invstatus,wrk.invstatusabbrev,
          dre_asofinvactlotPKG.get_useritem(in_custid,in_item,aod.lotnumber),
          dre_asofinvactlotPKG.get_expdate(in_custid,in_item,aod.lotnumber),
          dre_asofinvactlotPKG.get_mfgdate(in_custid,in_item,aod.lotnumber));
        else
         update dre_asofinvactlot
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
          from dre_asofinvactlot
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
         insert into dre_asofinvactlot values
         (numSessionId,in_facility,in_custid,in_item,aod.lotnumber,aod.uom,aod.invstatus,
          aod.inventoryclass,'DT',aod.trantype,aod.effdate,
          ordp.quantity,wrk.itemdesc,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
          cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
          aod.orderid,aod.shipid,aod.reason,ordp.shipper,ordp.shippername,sysdate,
          ordp.reference,ordp.po, ordp.billoflading,ordp.weight,
          dre_asofinvactlotPKG.get_addlinfo(in_custid,in_item,aod.lotnumber),
          aod.invstatus,wrk.invstatusabbrev,
          dre_asofinvactlotPKG.get_useritem(in_custid,in_item,aod.lotnumber),
          dre_asofinvactlotPKG.get_expdate(in_custid,in_item,aod.lotnumber),
          dre_asofinvactlotPKG.get_mfgdate(in_custid,in_item,aod.lotnumber));
        else
         update dre_asofinvactlot
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
       insert into dre_asofinvactlot values
       (numSessionId,in_facility,in_custid,in_item,aod.lotnumber,aod.uom,aod.invstatus,
        aod.inventoryclass,'DT',aod.trantype,aod.effdate,
        rt.quantity,wrk.itemdesc,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
        cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
        rt.orderid,rt.shipid,aod.reason,rt.shipper,rt.shippername,sysdate,
        rt.reference,rt.po,rt.billoflading,rt.weight,
        dre_asofinvactlotPKG.get_addlinfo(in_custid,in_item,aod.lotnumber),
        aod.invstatus,wrk.invstatusabbrev,
        dre_asofinvactlotPKG.get_useritem(in_custid,in_item,aod.lotnumber),
        dre_asofinvactlotPKG.get_expdate(in_custid,in_item,aod.lotnumber),
        dre_asofinvactlotPKG.get_mfgdate(in_custid,in_item,aod.lotnumber));
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
        insert into dre_asofinvactlot values
        (numSessionId,in_facility,in_custid,in_item,aod.lotnumber,aod.uom,aod.invstatus,
         aod.inventoryclass,'DT',aod.trantype,aod.effdate,
         ordp.quantity,wrk.itemdesc,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
         cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
         aod.orderid,aod.shipid,aod.reason,ordp.shipper,ordp.shippername,sysdate,
         ordp.reference,ordp.po, ordp.billoflading,ordp.weight,
         dre_asofinvactlotPKG.get_addlinfo(in_custid,in_item,aod.lotnumber),
         aod.invstatus,wrk.invstatusabbrev,
         dre_asofinvactlotPKG.get_useritem(in_custid,in_item,aod.lotnumber),
         dre_asofinvactlotPKG.get_expdate(in_custid,in_item,aod.lotnumber),
         dre_asofinvactlotPKG.get_mfgdate(in_custid,in_item,aod.lotnumber));
      end if;
    end loop;
  end if;

  goto continue_aod_loop;

<< check_adjustment>>

  if aod.trantype != 'AD' then
    goto unknown_type;
  end if;

  if aod.adjustment <> 0 then
    insert into dre_asofinvactlot values
    (numSessionId,in_facility,in_custid,in_item,aod.lotnumber,aod.uom,aod.invstatus,
     aod.inventoryclass,'DT',aod.trantype,aod.effdate,
     aod.adjustment,wrk.itemdesc,wrk.invstatusabbrev,wrk.inventoryclassabbrev,
     cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,wrk.reporttitle,
     null,null,aod.reason,null,null,sysdate,null,null,null,aod.weightadjustment,
     dre_asofinvactlotPKG.get_addlinfo(in_custid,in_item,aod.lotnumber),
     aod.invstatus,wrk.invstatusabbrev,
     dre_asofinvactlotPKG.get_useritem(in_custid,in_item,aod.lotnumber),
     dre_asofinvactlotPKG.get_expdate(in_custid,in_item,aod.lotnumber),
     dre_asofinvactlotPKG.get_mfgdate(in_custid,in_item,aod.lotnumber));
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

delete from dre_asofinvactlot
where sessionid = numSessionId;
commit;

delete from dre_asofinvactlot
where lastupdate < trunc(sysdate);
commit;

select count(1)
into dtlCount
from dre_asofinvactlot
where lastupdate < sysdate;

if dtlCount = 0 then
  EXECUTE IMMEDIATE 'truncate table dre_asofinvactlot';
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
      wrk.invstatusabbrev := dre_asofinvactlotPKG.invstatus_abbrev(aob.invstatus);
      wrk.inventoryclassabbrev := dre_asofinvactlotPKG.inventoryclass_abbrev(aob.inventoryclass);
      insert into dre_asofinvactlot values
      (numSessionId,cf.facility,in_custid,cit.item,aob.lotnumber,aob.uom,aob.invstatus,
       aob.inventoryclass,'AA','XX',trunc(in_begdate),aob.currentqty,cit.descr,
       wrk.invstatusabbrev,wrk.inventoryclassabbrev,
       cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
       wrk.reporttitle,null,null,null,null,null,sysdate,null,null,null,aob.currentweight,
       dre_asofinvactlotPKG.get_addlinfo(in_custid,in_item,aob.lotnumber),
       aob.invstatus,wrk.invstatusabbrev,
       dre_asofinvactlotPKG.get_useritem(in_custid,in_item,aob.lotnumber),
       dre_asofinvactlotPKG.get_expdate(in_custid,in_item,aob.lotnumber),
       dre_asofinvactlotPKG.get_mfgdate(in_custid,in_item,aob.lotnumber));
    end loop;
    commit;

    get_asof_detail(cf.facility, cit.item);
    commit;

    for aoe in curAsOfEndSearch(cf.facility, cit.item)
    loop
        wrk.invstatusabbrev := dre_asofinvactlotPKG.invstatus_abbrev(aoe.invstatus);
        wrk.inventoryclassabbrev := dre_asofinvactlotPKG.inventoryclass_abbrev(aoe.inventoryclass);
        insert into dre_asofinvactlot values
        (numSessionId,cf.facility,in_custid,cit.item,aoe.lotnumber,aoe.uom,aoe.invstatus,
         aoe.inventoryclass,'ZZ','XX',trunc(in_enddate),aoe.currentqty,cit.descr,
         wrk.invstatusabbrev,wrk.inventoryclassabbrev,
         cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
         wrk.reporttitle,null,null,null,null,null,sysdate,null,null,null,aoe.currentweight,
         dre_asofinvactlotPKG.get_addlinfo(in_custid,in_item,aoe.lotnumber),
         aoe.invstatus,wrk.invstatusabbrev,
         dre_asofinvactlotPKG.get_useritem(in_custid,in_item,aoe.lotnumber),
         dre_asofinvactlotPKG.get_expdate(in_custid,in_item,aoe.lotnumber),
         dre_asofinvactlotPKG.get_mfgdate(in_custid,in_item,aoe.lotnumber));
    end loop;
    commit;
  end loop;
end loop;

commit;

open aoi_cursor for
select *
   from dre_asofinvactlot
  where sessionid = numSessionId
  order by facility,item,uom,invstatus,inventoryclass,trantype,dtltrantype,effdate;

end dre_asofinvactlotbyitemPROC;
/

show errors package dre_asofinvactlotPKG;
show errors procedure dre_asofinvactlotPROC;
show errors package body dre_asofinvactlotPKG;
exit;
