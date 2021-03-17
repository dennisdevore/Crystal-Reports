create or replace package dre_asofinvactlot2PKG 
as type aoi_type is ref cursor return dre_asofinvactlot%rowtype;
	procedure dre_asofinvactlot2PROC
	(aoi_cursor IN OUT dre_asofinvactlot2PKG.aoi_type
	,in_custid IN varchar2
	,in_facility IN varchar2
	,in_item IN varchar2
	,in_lot IN varchar2
	,in_begdate IN date
	,in_enddate IN date
	,in_debug_yn IN varchar2);
end dre_asofinvactlot2PKG;
/

create or replace procedure dre_asofinvactlot2PROC
(aoi_cursor IN OUT dre_asofinvactlot2PKG.aoi_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_item IN varchar2
,in_lot IN varchar2
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
   		 and item = in_item
   order by item;

cursor curAsOfBeginSearch(in_item IN varchar2) is
  select uom,invstatus,inventoryclass,lotnumber,max(effdate) as effdate
    from asofinventory
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and effdate < trunc(in_begdate)
     and invstatus != 'SU'
     and nvl(lotnumber,'X') = nvl(in_lot,'X')
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
     and nvl(lotnumber,'X') = nvl(in_lot,'X')
     and not exists
         (select * from dre_asofinvactlot act
           where act.sessionid = in_sessionid
             and act.item = in_item
             and nvl(act.lotnumber,'x') = nvl(aod.lotnumber,'x')
             and act.uom = aod.uom
             and act.invstatus = '--'
             and act.inventoryclass = '--'
             and nvl(act.lotnumber,'X') = nvl(in_lot,'X'))
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
     and nvl(lotnumber,'X') = nvl(in_lot,'X')
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
     and nvl(lotnumber,'X') = nvl(in_lot,'X')
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

  debugmsg('processing dtl ' || aod.trantype);

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
-- suppress zero-balance invactive items
 if cit.status <> 'ACTV' then
   for zb in
     (select lotnumber,invstatus,inventoryclass,uom
        from dre_asofinvactlot
       where SessionId = numSessionId
         and item = cit.item
         and trantype = 'ZZ'
         and qty = 0
         and invstatus != 'AV'
         and inventoryclass != 'RG')
   loop
     delete from dre_asofinvactlot ao1
           where SessionId = numSessionId
            and item = cit.item
            and nvl(lotnumber,'x') = nvl(zb.lotnumber,'x')
            and invstatus = zb.invstatus
            and inventoryclass = zb.inventoryclass
            and uom = zb.uom
            and trantype = 'AA'
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
 end if;
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

end dre_asofinvactlot2PROC;
/
CREATE OR REPLACE PACKAGE Body dre_asofinvactlot2PKG AS

procedure dre_asofinvactlot2PROC
(aoi_cursor IN OUT dre_asofinvactlot2PKG.aoi_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_item IN varchar2
,in_lot IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2)
as
begin
	dre_asofinvactlot2PROC(aoi_cursor, in_custid, in_facility, in_item, in_lot, in_begdate, in_enddate, in_debug_yn);
end dre_asofinvactlot2PROC;
end dre_asofinvactlot2PKG;
/
show errors package dre_asofinvactlot2PKG;
show errors procedure dre_asofinvactlot2PROC;
show errors package body dre_asofinvactlot2PKG;
exit;
