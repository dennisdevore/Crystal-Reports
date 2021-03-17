--
-- $Id$
--
set serveroutput on
set verify off

declare
  CURSOR C_FAC
  IS
  	  select facility
  	    from facility
  	   order by facility;
  fa C_FAC%rowtype;
  	   
  CURSOR C_CUSTITEM
  IS
  	  select custid, item, lotrequired
  	    from custitemview
  	   order by custid, item;
  cit C_CUSTITEM%rowtype;
  	   
  CURSOR C_ITEMS(in_facility varchar2, in_custid varchar2,
    in_item varchar2, in_lotrequired varchar2, in_startdate date)
  IS
      select /*+ index(pl PLATE_CUSTITEM_IDX) */ pl.lotnumber, pl.unitofmeasure, pl.invstatus, pl.inventoryclass
        from plate pl
       where pl.facility = in_facility
         and pl.custid = in_custid
         and pl.item = in_item
         and pl.type = 'PA'
         and pl.lastupdate >= trunc(in_startdate)
   union
      select /*+ index(pl DELETEDPLATE_CUSTITEM_IDX) */ pl.lotnumber, pl.unitofmeasure, pl.invstatus, pl.inventoryclass
        from deletedplate pl
       where pl.facility = in_facility
         and pl.custid = in_custid
         and pl.item = in_item
         and pl.type = 'PA'
         and pl.lastupdate >= trunc(in_startdate)
   union
      select /*+ index(aoi ASOFINVENTORY_ITEM_IDX) */ aoi.lotnumber, aoi.uom unitofmeasure, aoi.invstatus, aoi.inventoryclass
        from asofinventory aoi
       where aoi.facility = in_facility
         and aoi.custid = in_custid
         and aoi.item = in_item
         and aoi.lastupdate >= trunc(in_startdate)
   union
      select /*+ index(sp SHIPPINGPLATE_CUSTITEM) */ decode(in_lotrequired,'P',null,sp.lotnumber) lotnumber, sp.unitofmeasure, sp.invstatus, sp.inventoryclass
        from shippingplate sp
       where sp.facility = in_facility
         and sp.custid = in_custid
         and sp.item = in_item
         and sp.status in ('L','P','S','FA')
         and sp.type in ('F','P')
         and sp.lastupdate >= trunc(in_startdate)
   order by lotnumber;
  
  CURSOR C_NOEFFDATE(in_facility varchar2,
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2,in_invstatus varchar2,
         in_inventoryclass varchar2)
    IS
   select /*+ index(asofinventorydtl ASOFINVENTORYDTL_ITEM_IDX) */ rowid, lastupdate, lastuser, nvl(adjustment,0) as adjustment,
          nvl(weightadjustment,0) as weightadjustment
     from asofinventorydtl
    where facility = in_facility
      and custid = in_custid
      and item = in_item
      and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
      and uom = in_uom
      and effdate is null
      and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
      and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)');
   noeffdate C_NOEFFDATE%rowtype;

  CURSOR C_ASOF(in_facility varchar2,
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2,in_invstatus varchar2,
         in_inventoryclass varchar2, in_effdate date)
    IS
   SELECT /*+ index(asofinventory ASOFINVENTORY_ITEM_IDX) */ rowid, effdate, currentqty, currentweight
     FROM asofinventory
    WHERE facility = in_facility
      and custid = in_custid
      and item = in_item
      and nvl(lotnumber, 'none') = nvl(in_lotnumber,'none')
      and uom = in_uom
      and nvl(invstatus,'none') = nvl(in_invstatus,'none')
      and nvl(inventoryclass,'none') = nvl(in_inventoryclass,'none')
      and effdate <= trunc(in_effdate)
      order by effdate desc;
   asof C_ASOF%rowtype;

  CURSOR C_ASOF_FUTURE(in_facility varchar2,
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2,in_invstatus varchar2,
         in_inventoryclass varchar2, in_effdate date)
    IS
   SELECT /*+ index(asofinventory ASOFINVENTORY_ITEM_IDX) */ rowid, effdate
     FROM asofinventory
    WHERE facility = in_facility
      and custid = in_custid
      and item = in_item
      and nvl(lotnumber,  '(none)') = nvl(in_lotnumber, '(none)')
      and nvl(uom, '(none)') = nvl(in_uom, '(none)')
      and nvl(invstatus, '(none)') = nvl(in_invstatus, '(none)')
      and nvl(inventoryclass, '(none)') = nvl(in_inventoryclass, '(none)')
      and effdate > trunc(in_effdate)
      order by effdate desc;
   asoff C_ASOF_FUTURE%rowtype;

  CURSOR C_SHIPPEDORDERS(in_facility varchar2,
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2,in_invstatus varchar2,
         in_inventoryclass varchar2, in_effdate IN date,
         in_lotrequired varchar2) IS
   select /*+ index(shippingplate SHIPPINGPLATE_CUSTITEM) */ distinct orderid, shipid
     from shippingplate
    where facility = in_facility 
      and custid = in_custid 
      and item = in_item 
      and nvl(decode(in_lotrequired,'P',null,lotnumber), '(none)') = nvl(in_lotnumber, '(none)') 
      and nvl(invstatus, '(none)') = nvl(in_invstatus, '(none)') 
      and nvl(inventoryclass, '(none)') = nvl(in_inventoryclass, '(none)') 
      and unitofmeasure = in_uom 
      and status = 'SH' 
      and type in ('F', 'P') 
      and trunc(lastupdate) = in_effdate;
  cshippedorders C_SHIPPEDORDERS%rowtype;

  CURSOR C_SHIPPEDPLATES(in_orderid number, in_shipid number,
         in_facility varchar2, in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2, in_invstatus varchar2,
         in_inventoryclass varchar2, in_lotrequired varchar2) IS
   select /*+ index(shippingplate SHIPPINGPLATE_CUSTITEM) */ sum(nvl(quantity, 0) * -1) as quantity, 
          sum(nvl(weight, 0) * -1) as weight 
     from shippingplate
    where orderid = in_orderid
      and shipid = in_shipid 
      and item = in_item 
      and nvl(decode(in_lotrequired,'P',null,lotnumber), '(none)') = nvl(in_lotnumber, '(none)') 
      and nvl(invstatus, '(none)') = nvl(in_invstatus, '(none)') 
      and nvl(inventoryclass, '(none)') = nvl(in_inventoryclass, '(none)') 
      and facility = in_facility 
      and custid = in_custid 
      and unitofmeasure = in_uom 
      and type in ('F', 'P') 
      and status = 'SH';
  cshippedplates C_SHIPPEDPLATES%rowtype;

  CURSOR C_SHIPPEDASOF(in_facility varchar2,
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2,in_invstatus varchar2,
         in_inventoryclass varchar2, in_orderid number, in_shipid number)
    IS
   select /*+ index(asofinventorydtl ASOFINVENTORYDTL_ITEM_IDX) */ sum(nvl(adjustment,0)) as adjustment, sum(nvl(weightadjustment,0)) as weightadjustment
     from asofinventorydtl
    where facility = in_facility
      and custid = in_custid
      and item = in_item
      and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
      and uom = in_uom
      and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
      and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
      and (trantype = 'SH'
       or (trantype = 'AD'
      and  reason = 'Depicked'))
      and orderid = in_orderid
      and shipid = in_shipid;
  cshipasof C_SHIPPEDASOF%rowtype;
      
  CURSOR C_RECEIVEDORDERS(in_facility varchar2,
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2,in_invstatus varchar2,
         in_inventoryclass varchar2, in_effdate IN date) IS
    select /*+ index(od ORDERDTLRCPT_ORDERDTL_IDX)*/ oh.orderid, oh.shipid, sum(nvl(od.qtyrcvd,0)) as qtyrcvd,
          sum(nvl(od.weight,0)) as weight
      from orderdtlrcpt od, orderhdr oh
     where od.orderid = oh.orderid
       and od.shipid = oh.shipid
       and od.custid = in_custid
       and od.item = in_item
       and nvl(od.lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
       and nvl(od.invstatus,'(none)') = nvl(in_invstatus,'(none)')
       and nvl(od.inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
       and od.uom = in_uom
       and oh.recent_order_id like 'Y%'
       and oh.tofacility = in_facility
       and oh.ordertype in ('R','Q')
       and oh.orderstatus = 'R'
       and trunc(oh.statusupdate) = in_effdate
     group by oh.orderid, oh.shipid;
  creceivedorders C_RECEIVEDORDERS%rowtype;

  CURSOR C_RECEIVEDASOF(in_facility varchar2,
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2,in_invstatus varchar2,
         in_inventoryclass varchar2, in_orderid number, in_shipid number)
    IS
   select /*+ index(asofinventorydtl ASOFINVENTORYDTL_ITEM_IDX) */ sum(nvl(adjustment,0)) as adjustment, sum(nvl(weightadjustment,0)) as weightadjustment
     from asofinventorydtl
    where facility = in_facility
      and custid = in_custid
      and item = in_item
      and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
      and uom = in_uom
      and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
      and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
      and trantype in ('RC','RT','RR')
      and orderid = in_orderid
      and shipid = in_shipid;
  crcptasof C_RECEIVEDASOF%rowtype;
      
  CURSOR C_PLATE(in_facility varchar2, in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2,in_invstatus varchar2,
         in_inventoryclass varchar2) IS
    select  /*+ index(pl PLATE_CUSTITEM_IDX) */ nvl(sum(quantity), 0) as quantity, nvl(sum(weight), 0) as weight
      from plate pl
     where facility = in_facility
       and custid = in_custid
       and item = in_item
       and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
       and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
       and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
       and unitofmeasure = in_uom
       and status not in ('P','D','I')
       and type = 'PA'
       and (status <> 'M'
        or  not exists(
              select 1
                from shippingplate sh
               where sh.fromlpid = pl.lpid
                 and sh.status = 'P'));
  lp C_PLATE%rowtype;
  simlp C_PLATE%rowtype;

  CURSOR C_SHIPPINGPLATE(in_facility varchar2,
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2,in_invstatus varchar2,
         in_inventoryclass varchar2, in_lotrequired varchar2) IS
    select /*+ index(shippingplate SHIPPINGPLATE_CUSTITEM) */ nvl(sum(quantity), 0) as quantity, nvl(sum(weight), 0) as weight
      from shippingplate
     where facility = in_facility
       and custid = in_custid
       and item = in_item
       and nvl(decode(in_lotrequired,'P',null,lotnumber),'(none)') = nvl(in_lotnumber,'(none)')
       and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
       and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
       and unitofmeasure = in_uom
       and status in ('L','P', 'S', 'FA')
       and type in ('F', 'P');
  sp C_SHIPPINGPLATE%rowtype;
  simsp C_SHIPPINGPLATE%rowtype;
  
  CURSOR C_LASTASOF(in_facility varchar2,
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2,in_invstatus varchar2,
         in_inventoryclass varchar2)
    IS
   select /*+ index(asofinventory ASOFINVENTORY_ITEM_IDX) */ effdate, nvl(currentqty,0) as currentqty, nvl(currentweight,0) as currentweight,
          nvl(previousqty,0) as previousqty, nvl(previousweight,0) as previousweight
     from asofinventory
    where facility = in_facility
      and custid = in_custid
      and item = in_item
      and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
      and uom = in_uom
      and effdate =
      (select max(effdate)
         from asofinventory
        where facility = in_facility
          and custid = in_custid
          and item = in_item
          and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
          and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
          and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
          and uom = in_uom)
      and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
      and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)');

  CURSOR C_ASOFTRANS(in_facility varchar2,
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2,in_invstatus varchar2,
         in_inventoryclass varchar2)
    IS
   select /*+ index(asofinventorydtl ASOFINVENTORYDTL_ITEM_IDX) */ sum(nvl(adjustment,0)) as adjustment, sum(nvl(weightadjustment,0)) as weightadjustment
     from asofinventorydtl
    where facility = in_facility
      and custid = in_custid
      and item = in_item
      and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
      and uom = in_uom
      and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
      and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)');

  CURSOR C_ASOFDAILY(in_facility varchar2,
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2,in_invstatus varchar2,
         in_inventoryclass varchar2)
    IS
   select  /*+ index(asofinventory ASOFINVENTORY_ITEM_IDX) */ effdate, nvl(previousqty,0) as previousqty, nvl(currentqty,0) as currentqty,
      nvl(previousweight,0) as previousweight, nvl(currentweight,0) as currentweight
     from asofinventory
    where facility = in_facility
      and custid = in_custid
      and item = in_item
      and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
      and uom = in_uom
      and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
      and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
    order by effdate desc;
  casofdaily C_ASOFDAILY%rowtype;

  CURSOR C_ASOF_PREV(in_facility varchar2,
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2,in_invstatus varchar2,
         in_inventoryclass varchar2, in_effdate date)
    IS
   SELECT  /*+ index(asofinventory ASOFINVENTORY_ITEM_IDX) */ nvl(currentqty,0) as currentqty, nvl(currentweight,0) as currentweight
     FROM asofinventory
    WHERE facility = in_facility
      and custid = in_custid
      and item = in_item
      and nvl(lotnumber,  '(none)') = nvl(in_lotnumber, '(none)')
      and nvl(uom, '(none)') = nvl(in_uom, '(none)')
      and nvl(invstatus, '(none)') = nvl(in_invstatus, '(none)')
      and nvl(inventoryclass, '(none)') = nvl(in_inventoryclass, '(none)')
      and effdate =
      (select max(effdate)
         from asofinventory
        where facility = in_facility
          and custid = in_custid
          and item = in_item
          and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
          and uom = in_uom
          and effdate < in_effdate
          and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
          and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)'));
   casofp C_ASOF_PREV%rowtype;

  CURSOR C_ASOFDAILY_TRANS(in_facility varchar2,
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2,in_invstatus varchar2,
         in_inventoryclass varchar2, in_effdate date)
    IS
   select /*+ index(aoid ASOFINVENTORYDTL_ITEM_IDX) */ sum(nvl(adjustment,0)) as adjustment, sum(nvl(weightadjustment,0)) as weightadjustment
     from asofinventorydtl aoid
    where facility = in_facility
      and custid = in_custid
      and item = in_item
      and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
      and uom = in_uom
      and effdate = in_effdate
      and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
      and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)');
  casofdailytrans C_ASOFDAILY_TRANS%rowtype;
      
  CURSOR C_SIMASOF(in_facility varchar2,
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2,in_invstatus varchar2,
         in_inventoryclass varchar2)
    IS
   select  /*+ index(aoil ASOFINVENTORY_ITEM_IDX) */ lotnumber, invstatus, nvl(currentqty,0) as currentqty, nvl(currentweight,0) as currentweight
     from asofinventory aoi1
    where facility = in_facility
      and custid = in_custid
      and item = in_item
      and uom = in_uom
      and effdate =
      (select  /*+ index(asofinventory ASOFINVENTORY_ITEM_IDX) */ max(effdate)
        from asofinventory aoi2
        where facility = in_facility
          and custid = in_custid
          and item = in_item
          and nvl(aoi2.lotnumber,'(none)') = nvl(aoi1.lotnumber,'(none)')
          and nvl(aoi2.invstatus,'(none)') = nvl(aoi1.invstatus,'(none)')
          and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
          and uom = in_uom)
      and (nvl(lotnumber,'(none)') <> nvl(in_lotnumber,'(none)')
       or  nvl(invstatus,'(none)') <> nvl(in_invstatus,'(none)'))
      and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)');
  simasof C_SIMASOF%rowtype;

  CURSOR C_NEGATIVEASOF(in_facility varchar2,
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2,in_invstatus varchar2,
         in_inventoryclass varchar2)
    IS
   select  /*+ index(asofinventory ASOFINVENTORY_ITEM_IDX) */ effdate
     from asofinventory
    where facility = in_facility
      and custid = in_custid
      and item = in_item
      and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
      and uom = in_uom
      and effdate =
      (select  /*+ index(asofinventory ASOFINVENTORY_ITEM_IDX) */ min(effdate)
        from asofinventory
        where facility = in_facility
          and custid = in_custid
          and item = in_item
          and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
          and uom = in_uom
          and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
          and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
          and nvl(currentqty,0) < 0)
      and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
      and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)');

  CURSOR C_CHECKOPEN(in_facility varchar2,
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_lotrequired varchar2)
   IS
   select /*+ index(od ORDERDTLRCPT_ORDERDTL_IDX) index(oh ORDERHDR_IDX) */ oh.orderid, 
          oh.shipid, 
          ot.abbrev
     from orderdtlrcpt od,
	        orderhdr oh,
	        ordertypes ot
    where od.custid = in_custid
      and od.item = in_item
      and nvl(od.lotnumber, '(none)') = nvl(in_lotnumber, '(none)') 
      and oh.orderid = od.orderid 
      and oh.shipid = od.shipid 
      and oh.tofacility = in_facility
      and oh.orderstatus not in ('9','R','X')
      and oh.ordertype=ot.code
union
   select /*+ index(sp SHIPPINGPLATE_CUSTITEM)  index(oh ORDERHDR_IDX) */ oh.orderid, 
          oh.shipid, 
          ot.abbrev
     from shippingplate sp,
	        orderhdr oh,
	        ordertypes ot
    where sp.facility = in_facility
      and sp.custid = in_custid
      and sp.item = in_item
      and nvl(decode(in_lotrequired,'P',null,sp.lotnumber), '(none)') = nvl(in_lotnumber, '(none)') 
      and sp.status = 'SH'
      and oh.orderid = sp.orderid 
      and oh.shipid = sp.shipid 
      and oh.fromfacility = sp.facility
      and oh.orderstatus not in ('R','X','9')
      and oh.ordertype=ot.code;

   lastasof C_LASTASOF%rowtype;
   asoftrans C_ASOFTRANS%rowtype;

   oh_cnt integer;
   od_cnt integer;
   qty_adj number;
   qty_sim number;
   wt_adj number;
   wt_sim number;
   errmsg varchar2(400);
   strMsg varchar2(255);
   currdate date;
   adjdate date;
   startdate date;

begin

   dbms_output.enable(1000000);
   strMsg := '';
   
   select trunc(sysdate) - 1
     into currdate
     from dual;
	 
   select trunc(sysdate) - 30
     into startdate
	 from dual;
	 
   for fa in C_FAC loop   
      for cit in C_CUSTITEM loop   
         for crec in C_ITEMS(fa.facility, cit.custid, cit.item, cit.lotrequired, startdate) loop
            for cnoeffdate in C_NOEFFDATE(fa.facility, cit.custid, cit.item,
                  crec.lotnumber, crec.unitofmeasure, crec.invstatus,
                  crec.inventoryclass) loop
      			   update asofinventorydtl
      			      set effdate = trunc(cnoeffdate.lastupdate)
      			    where rowid = cnoeffdate.rowid;
      
      			   delete from asofinventory
      			    where facility = fa.facility
      			      and custid = cit.custid
      			      and item = cit.item
      			      and nvl(lotnumber, 'none') = nvl(crec.lotnumber,'none')
      			      and uom = crec.unitofmeasure
      			      and nvl(invstatus,'none') = nvl(crec.invstatus,'none')
      			      and nvl(inventoryclass,'none') = nvl(crec.inventoryclass,'none')
      			      and effdate is null;
      
               asof := null;
               OPEN C_ASOF(fa.facility, cit.custid, cit.item,
                  crec.lotnumber, crec.unitofmeasure, crec.invstatus,
                  crec.inventoryclass, trunc(cnoeffdate.lastupdate));
               FETCH C_ASOF INTO asof;
               CLOSE C_ASOF;
            
               if asof.effdate = trunc(cnoeffdate.lastupdate) then
                  UPDATE asofinventory
                     SET currentqty = currentqty + cnoeffdate.adjustment,
                         currentweight = nvl(currentweight,0) + cnoeffdate.weightadjustment
                   WHERE rowid = asof.rowid;
                  null;
               elsif asof.effdate < trunc(cnoeffdate.lastupdate) then
                 INSERT INTO asofinventory(
                     facility,
                     custid,
                     item,
                     lotnumber,
                     uom,
                     effdate,
                     inventoryclass,
                     invstatus,
                     previousqty,
                     currentqty,
                     previousweight,
                     currentweight,
                     lastuser,
                     lastupdate
                 )
                 values (
                     fa.facility,
                     cit.custid,
                     cit.item,
                     crec.lotnumber,
                     crec.unitofmeasure,
                     trunc(cnoeffdate.lastupdate),
                     crec.inventoryclass,
                     crec.invstatus,
                     asof.currentqty,
                     asof.currentqty + cnoeffdate.adjustment,
                     asof.currentweight,
                     asof.currentweight + cnoeffdate.weightadjustment,
                     cnoeffdate.lastuser,
                     cnoeffdate.lastupdate
                 );
               elsif asof.effdate is null then
                 INSERT INTO asofinventory(
                     facility,
                     custid,
                     item,
                     lotnumber,
                     uom,
                     effdate,
                     inventoryclass,
                     invstatus,
                     previousqty,
                     currentqty,
                     previousweight,
                     currentweight,
                     lastuser,
                     lastupdate
                 )
                 values (
                     fa.facility,
                     cit.custid,
                     cit.item,
                     crec.lotnumber,
                     crec.unitofmeasure,
                     trunc(cnoeffdate.lastupdate),
                     crec.inventoryclass,
                     crec.invstatus,
                     0,
                     cnoeffdate.adjustment,
                     0,
                     cnoeffdate.weightadjustment,
                     cnoeffdate.lastuser,
                     cnoeffdate.lastupdate
                 );
               end if;
          
               for asoff in C_ASOF_FUTURE(fa.facility, cit.custid, cit.item,
                  crec.lotnumber, crec.unitofmeasure, crec.invstatus,
                  crec.inventoryclass, trunc(cnoeffdate.lastupdate)) loop
                  UPDATE asofinventory
                     SET currentqty = currentqty + cnoeffdate.adjustment,
                         previousqty = previousqty + decode(effdate, trunc(cnoeffdate.lastupdate), 0, cnoeffdate.adjustment),
                         currentweight = currentweight + cnoeffdate.weightadjustment,
                         previousweight = previousweight + decode(effdate, trunc(cnoeffdate.lastupdate), 0, cnoeffdate.weightadjustment),
                         lastuser = cnoeffdate.lastuser,
                         lastupdate = cnoeffdate.lastupdate
                   WHERE rowid = asoff.rowid;
               end loop;
      			end loop;

            for cshippedorders in C_SHIPPEDORDERS(fa.facility, cit.custid, cit.item,
                  crec.lotnumber, crec.unitofmeasure, crec.invstatus,
                  crec.inventoryclass, currdate, cit.lotrequired) loop

               select /*+ index(orderhdr ORDERHDR_IDX) */ count(1)
                 into oh_cnt
                 from orderhdr
                where orderid = cshippedorders.orderid
                  and shipid = cshippedorders.shipid
                  and ordertype = 'O'
                  and orderstatus = '9';
               if(oh_cnt > 0) then
                  cshippedplates := null;
                  OPEN C_SHIPPEDPLATES(cshippedorders.orderid, cshippedorders.shipid,
                     fa.facility, cit.custid, cit.item, crec.lotnumber,
                     crec.unitofmeasure, crec.invstatus, crec.inventoryclass,
                     cit.lotrequired);
                  FETCH C_SHIPPEDPLATES into cshippedplates;
                  CLOSE C_SHIPPEDPLATES;

                  cshipasof := null;
                  OPEN C_SHIPPEDASOF(fa.facility, cit.custid, cit.item,
                     crec.lotnumber, crec.unitofmeasure, crec.invstatus,
                     crec.inventoryclass, cshippedorders.orderid,
                     cshippedorders.shipid);
                  FETCH C_SHIPPEDASOF into cshipasof;
                  CLOSE C_SHIPPEDASOF;
                  
                  if (cshipasof.adjustment is null) then
                     cshipasof.adjustment := 0;
                  end if;
                  if (cshipasof.weightadjustment is null) then
                     cshipasof.weightadjustment := 0;
                  end if;
                  
                  if (cshipasof.adjustment != cshippedplates.quantity) then
                     qty_adj := cshippedplates.quantity - cshipasof.adjustment;
                     wt_adj := cshippedplates.weight - cshipasof.weightadjustment;
                     
                     strMsg := 'ADD ASOF SHIPMENT FOR: '||fa.facility||'/'||cit.custid
                        ||'/'||cit.item
                        ||'/'||crec.lotnumber
                        ||'/'||crec.unitofmeasure
                        ||'/'||crec.invstatus
                        ||'/'||crec.inventoryclass
                        ||'/'||to_char(currdate,'YYYYMMDD')
                        ||'/'||to_char(cshippedorders.orderid)
                        ||'-'||to_char(cshippedorders.shipid);
                        
                     zut.prt(strMsg);
                     zms.log_msg('AUDIT', fa.facility, cit.custid,
                        substr(strMsg,1,254), 'W', 'SYNAPSE', errmsg);
   
                     zbill.add_asof_inventory(
                           fa.facility,
                           cit.custid,
                           cit.item,
                           crec.lotnumber,
                           crec.unitofmeasure,
                           currdate,
                           qty_adj,
                           wt_adj,
                           'Shipped',
                           'SH',
                           crec.inventoryclass,
                           crec.invstatus,
                           cshippedorders.orderid,
                           cshippedorders.shipid,
                           null,
                           'SYNAPSE',
                           errmsg);
                     if errmsg != 'OKAY' then
                        zut.prt('  Error adding asof: '||errmsg);
                     end if;
                  end if;
               end if;
            end loop;

            for creceivedorders in C_RECEIVEDORDERS(fa.facility, cit.custid, cit.item,
                  crec.lotnumber, crec.unitofmeasure, crec.invstatus,
                  crec.inventoryclass, currdate) loop

               crcptasof := null;
               OPEN C_RECEIVEDASOF(fa.facility, cit.custid, cit.item,
                  crec.lotnumber, crec.unitofmeasure, crec.invstatus,
                  crec.inventoryclass, creceivedorders.orderid,
                  creceivedorders.shipid);
               FETCH C_RECEIVEDASOF into crcptasof;
               CLOSE C_RECEIVEDASOF;
               
               if (crcptasof.adjustment is null) then
                  crcptasof.adjustment := 0;
               end if;
               if (crcptasof.weightadjustment is null) then
                  crcptasof.weightadjustment := 0;
               end if;
               
               if (crcptasof.adjustment != creceivedorders.qtyrcvd) then                  
                  qty_adj := creceivedorders.qtyrcvd - crcptasof.adjustment;
                  wt_adj := creceivedorders.weight - crcptasof.weightadjustment;
                  
                  strMsg := 'ADD ASOF RECEIPT FOR: '||fa.facility||'/'||cit.custid
                     ||'/'||cit.item
                     ||'/'||crec.lotnumber
                     ||'/'||crec.unitofmeasure
                     ||'/'||crec.invstatus
                     ||'/'||crec.inventoryclass
                     ||'/'||to_char(currdate,'YYYYMMDD')
                     ||'/'||to_char(creceivedorders.orderid)
                     ||'-'||to_char(creceivedorders.shipid);
                     
                  zut.prt(strMsg);
                  zms.log_msg('AUDIT', fa.facility, cit.custid,
                     substr(strMsg,1,254), 'W', 'SYNAPSE', errmsg);

                  zbill.add_asof_inventory(
                        fa.facility,
                        cit.custid,
                        cit.item,
                        crec.lotnumber,
                        crec.unitofmeasure,
                        currdate,
                        qty_adj,
                        wt_adj,
                        'Received',
                        'RC',
                        crec.inventoryclass,
                        crec.invstatus,
                        creceivedorders.orderid,
                        creceivedorders.shipid,
                        null,
                        'SYNAPSE',
                        errmsg);
                  if errmsg != 'OKAY' then
                     zut.prt('  Error adding asof: '||errmsg);
                  end if;
               end if;
            end loop;
            
            lp := null;
            OPEN C_PLATE(fa.facility, cit.custid, cit.item, crec.lotnumber,
                  crec.unitofmeasure, crec.invstatus, crec.inventoryclass);
            FETCH C_PLATE into lp;
            CLOSE C_PLATE;
            
            sp := null;
            OPEN C_SHIPPINGPLATE(fa.facility, cit.custid, cit.item, crec.lotnumber,
                  crec.unitofmeasure, crec.invstatus, crec.inventoryclass,
                  cit.lotrequired);
            FETCH C_SHIPPINGPLATE into sp;
            CLOSE C_SHIPPINGPLATE;
      
            lastasof := null;
            OPEN C_LASTASOF(fa.facility, cit.custid, cit.item, crec.lotnumber,
                  crec.unitofmeasure, crec.invstatus, crec.inventoryclass);
            FETCH C_LASTASOF into lastasof;
            CLOSE C_LASTASOF;
            
            if lastasof.currentqty is null then
               lastasof.currentqty := 0;
            end if;
            if lastasof.currentweight is null then
               lastasof.currentweight := 0;
            end if;
            if lastasof.previousqty is null then
               lastasof.previousqty := 0;
            end if;
            if lastasof.previousweight is null then
               lastasof.previousweight := 0;
            end if;
      
            if (lastasof.currentqty != lp.quantity + sp.quantity) then
               asoftrans := null;
               OPEN C_ASOFTRANS(fa.facility, cit.custid, cit.item, crec.lotnumber,
                     crec.unitofmeasure, crec.invstatus, crec.inventoryclass);
               FETCH C_ASOFTRANS into asoftrans;
               CLOSE C_ASOFTRANS;
               
               if asoftrans.adjustment is null then
                  asoftrans.adjustment := 0;
               end if;
               if asoftrans.weightadjustment is null then
                  asoftrans.weightadjustment := 0;
               end if;

               if(asoftrans.adjustment != lastasof.currentqty) then
                  for casofdaily in C_ASOFDAILY(fa.facility, cit.custid, cit.item,
                     crec.lotnumber, crec.unitofmeasure, crec.invstatus,
                     crec.inventoryclass) loop
                     
                     casofp := null;
                     open C_ASOF_PREV(fa.facility, cit.custid, cit.item,
                        crec.lotnumber, crec.unitofmeasure, crec.invstatus,
                        crec.inventoryclass, casofdaily.effdate);
                     fetch C_ASOF_PREV into casofp;
                     close C_ASOF_PREV;
                     
                     if (casofp.currentqty is not null) and (casofp.currentqty != casofdaily.previousqty) then
                        zut.prt('ASOF: '||fa.facility||'/'||cit.custid
                              ||'/'||cit.item
                              ||'/'||crec.lotnumber
                              ||'/'||crec.unitofmeasure
                              ||'/'||to_char(casofdaily.effdate,'YYYYMMDD')
                              ||'/'||crec.invstatus
                              ||'/'||crec.inventoryclass
                              ||' CQ= '||to_char(casofp.currentqty)
                              ||' PQ= '||to_char(casofdaily.previousqty));
      
                        qty_adj := casofp.currentqty - casofdaily.previousqty;
                        wt_adj := casofp.currentweight - casofdaily.previousweight;
                        lastasof.currentqty := lastasof.currentqty + qty_adj;
                        lastasof.currentweight := lastasof.currentweight + wt_adj;
      
                        update asofinventory
                           set currentqty = nvl(currentqty,0) + qty_adj,
                               currentweight = nvl(currentweight,0) + wt_adj,
                               previousqty = nvl(previousqty,0) + qty_adj,
                               previousweight = nvl(previousweight,0) + wt_adj
                         where facility = fa.facility
                           and custid = cit.custid
                           and item = cit.item
                           and nvl(lotnumber,'(none)') = nvl(crec.lotnumber,'(none)')
                           and uom = crec.unitofmeasure
                           and effdate >= casofdaily.effdate
                           and nvl(invstatus,'(none)') = nvl(crec.invstatus,'(none)')
                           and nvl(inventoryclass,'(none)') = nvl(crec.inventoryclass,'(none)');
                     end if;
                     
                     casofdailytrans := null;
                     open C_ASOFDAILY_TRANS(fa.facility, cit.custid, cit.item,
                        crec.lotnumber, crec.unitofmeasure, crec.invstatus,
                        crec.inventoryclass, casofdaily.effdate);
                     fetch C_ASOFDAILY_TRANS into casofdailytrans;
                     close C_ASOFDAILY_TRANS;
                     
                     if (casofdaily.currentqty - casofdaily.previousqty) != casofdailytrans.adjustment then
                        zut.prt('ASOF: '||fa.facility||'/'||cit.custid
                              ||'/'||cit.item
                              ||'/'||crec.lotnumber
                              ||'/'||crec.unitofmeasure
                              ||'/'||to_char(casofdaily.effdate,'YYYYMMDD')
                              ||'/'||crec.invstatus
                              ||'/'||crec.inventoryclass
                              ||' PQ= '||to_char(casofdaily.previousqty)
                              ||' + '||to_char(casofdailytrans.adjustment)
                              ||' CQ='||to_char(casofdaily.currentqty));
      
                        qty_adj := casofdailytrans.adjustment - (casofdaily.currentqty - casofdaily.previousqty);
                        wt_adj := casofdailytrans.weightadjustment - (casofdaily.currentweight - casofdaily.previousweight);
                        lastasof.currentqty := lastasof.currentqty + qty_adj;
                        lastasof.currentweight := lastasof.currentweight + wt_adj;
      
                        update asofinventory
                           set currentqty = nvl(currentqty,0) + qty_adj,
                               currentweight = nvl(currentweight,0) + wt_adj,
                               previousqty = nvl(previousqty,0) + decode(effdate, casofdaily.effdate, 0, qty_adj),
                               previousweight = nvl(previousweight,0) + decode(effdate, casofdaily.effdate, 0, wt_adj)
                         where facility = fa.facility
                           and custid = cit.custid
                           and item = cit.item
                           and nvl(lotnumber,'(none)') = nvl(crec.lotnumber,'(none)')
                           and uom = crec.unitofmeasure
                           and effdate >= casofdaily.effdate
                           and nvl(invstatus,'(none)') = nvl(crec.invstatus,'(none)')
                           and nvl(inventoryclass,'(none)') = nvl(crec.inventoryclass,'(none)');
                     end if;
                  end loop;
               end if;
            end if;

            if (lastasof.currentqty != lp.quantity + sp.quantity) then
      
               zut.prt('FOR: '||fa.facility||'/'||cit.custid
                     ||'/'||cit.item
                     ||'/'||crec.lotnumber
                     ||'/'||crec.unitofmeasure
                     ||'/'||crec.invstatus
                     ||'/'||crec.inventoryclass
                     ||' = '||to_char(lp.quantity)
                     ||' + '||to_char(sp.quantity)
                     ||' CQ='||to_char(lastasof.currentqty));
               qty_adj := (nvl(lp.quantity,0) + nvl(sp.quantity,0)) - nvl(lastasof.currentqty,0);
               wt_adj := (nvl(lp.weight,0) + nvl(sp.weight,0)) - nvl(lastasof.currentweight,0);

               od_cnt := 0;
               for cord in  C_CHECKOPEN(fa.facility, cit.custid,  cit.item, crec.lotnumber, cit.lotrequired) loop
                  od_cnt := od_cnt + 1;
                  zut.prt('     SKIPPED because open '||cord.abbrev||': ' ||cord.orderid||'-'||cord.shipid);
               end loop;
               if od_cnt > 0 then
                  zut.prt('  SKIPPED because open orders: '||od_cnt);
               else
                  adjdate := currdate;

                  for simasof in C_SIMASOF(fa.facility, cit.custid, cit.item,
                      crec.lotnumber, crec.unitofmeasure, crec.invstatus,
                      crec.inventoryclass) loop

                     OPEN C_PLATE(fa.facility, cit.custid, cit.item, simasof.lotnumber,
                           crec.unitofmeasure, simasof.invstatus, crec.inventoryclass);
                     FETCH C_PLATE into simlp;
                     CLOSE C_PLATE;
               
                     OPEN C_SHIPPINGPLATE(fa.facility, cit.custid, cit.item, simasof.lotnumber,
                           crec.unitofmeasure, simasof.invstatus, crec.inventoryclass, cit.lotrequired);
                     FETCH C_SHIPPINGPLATE into simsp;
                     CLOSE C_SHIPPINGPLATE;
                     
                     qty_sim :=  nvl(simasof.currentqty,0) - (nvl(simlp.quantity,0) + nvl(simsp.quantity,0));
                     wt_sim := nvl(simasof.currentweight,0) - (nvl(simlp.weight,0) + nvl(simsp.weight,0));
                     
                     if (qty_adj = qty_sim) then
                        zut.prt('Found similar discrepency:'||simasof.lotnumber||'/'||simasof.invstatus);
                        if (qty_adj > 0) then
                           OPEN C_NEGATIVEASOF(fa.facility, cit.custid, cit.item, crec.lotnumber,
                                crec.unitofmeasure, crec.invstatus, crec.inventoryclass);
                           FETCH C_NEGATIVEASOF into adjdate;
                           CLOSE C_NEGATIVEASOF;
                           
                           if (adjdate is null) then
                              adjdate := currdate;
                           end if;
                        else
                           OPEN C_NEGATIVEASOF(fa.facility, cit.custid, cit.item, simasof.lotnumber,
                                crec.unitofmeasure, simasof.invstatus, crec.inventoryclass);
                           FETCH C_NEGATIVEASOF into adjdate;
                           CLOSE C_NEGATIVEASOF;
                           
                           if (adjdate is null) then
                              adjdate := currdate;
                           end if;
                        end if;
                     
                        strMsg := 'Add asof AdjustIC record for: ' ||
                           to_char(adjdate,'YYYYMMDD')||' '||fa.facility||'/'||cit.custid
                              ||'/'||cit.item
                              ||'/'||crec.lotnumber
                              ||'/'||crec.unitofmeasure
                              ||'/'||crec.invstatus
                              ||'/'||crec.inventoryclass
                              ||'/'||to_char(qty_adj)
                              ||'/'||to_char(wt_adj);
                         
                        zut.prt(strMsg);
                        zms.log_msg('AUDIT', fa.facility, cit.custid,
                           substr(strMsg,1,254), 'W', 'SYNAPSE', errmsg);
                        zbill.add_asof_inventory(
                              fa.facility,
                              cit.custid,
                              cit.item,
                              crec.lotnumber,
                              crec.unitofmeasure,
                              adjdate,
                              qty_adj,
                              wt_adj,
                              'AdjustIC',
                              'AD',
                              crec.inventoryclass,
                              crec.invstatus,
                              null,
                              null,
                              null,
                              'SYNAPSE',
                              errmsg);
                        if errmsg != 'OKAY' then
                           zut.prt('  Error adding asof: '||errmsg);
                        end if;
                     
                        strMsg := 'Add asof AdjustIC record for: ' ||
                           to_char(adjdate,'YYYYMMDD')||' '||fa.facility||'/'||cit.custid
                              ||'/'||cit.item
                              ||'/'||simasof.lotnumber
                              ||'/'||crec.unitofmeasure
                              ||'/'||simasof.invstatus
                              ||'/'||crec.inventoryclass
                              ||'/'||to_char(qty_adj*-1)
                              ||'/'||to_char(wt_adj*-1);
                           
                        zut.prt(strMsg);
                        zms.log_msg('AUDIT', fa.facility, cit.custid,
                           substr(strMsg,1,254), 'W', 'SYNAPSE', errmsg);
                        zbill.add_asof_inventory(
                              fa.facility,
                              cit.custid,
                              cit.item,
                              simasof.lotnumber,
                              crec.unitofmeasure,
                              adjdate,
                              qty_sim * -1,
                              wt_sim * -1,
                              'AdjustIC',
                              'AD',
                              crec.inventoryclass,
                              simasof.invstatus,
                              null,
                              null,
                              null,
                              'SYNAPSE',
                              errmsg);
                        if errmsg != 'OKAY' then
                           zut.prt('  Error adding asof: '||errmsg);
                        end if;
                        
                        goto continue_item_loop;
                     end if;
                  end loop;
                  
                  if (qty_adj > 0) then
                     OPEN C_NEGATIVEASOF(fa.facility, cit.custid, cit.item, crec.lotnumber,
                          crec.unitofmeasure, crec.invstatus, crec.inventoryclass);
                     FETCH C_NEGATIVEASOF into adjdate;
                     CLOSE C_NEGATIVEASOF;
                     
                     if (adjdate is null) then
                        adjdate := currdate;
                     end if;
                  end if;
                  
                  strMsg := 'Add asof AdjustIC record for: ' ||
                     to_char(adjdate,'YYYYMMDD')||' '||fa.facility||'/'||cit.custid
                        ||'/'||cit.item
                        ||'/'||crec.lotnumber
                        ||'/'||crec.unitofmeasure
                        ||'/'||crec.invstatus
                        ||'/'||crec.inventoryclass
                        ||'/'||to_char(qty_adj)
                        ||'/'||to_char(wt_adj);
                     
                  zut.prt(strMsg);
                  zms.log_msg('AUDIT', fa.facility, cit.custid,
                     substr(strMsg,1,254), 'W', 'SYNAPSE', errmsg);
                  zbill.add_asof_inventory(
                        fa.facility,
                        cit.custid,
                        cit.item,
                        crec.lotnumber,
                        crec.unitofmeasure,
                        adjdate,
                        qty_adj,
                        wt_adj,
                        'AdjustIC',
                        'AD',
                        crec.inventoryclass,
                        crec.invstatus,
                        null,
                        null,
                        null,
                        'SYNAPSE',
                        errmsg);
                  if errmsg != 'OKAY' then
                     zut.prt('  Error adding asof: '||errmsg);
                  end if;
               end if;
            end if;

<< continue_item_loop >>
            null;

         end loop;
      end loop;
   end loop;
end;
/
exit;
