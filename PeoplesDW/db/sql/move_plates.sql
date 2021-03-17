--
-- $Id$
--
set serveroutput on
set verify off
accept p_custid prompt 'Enter custid: '
accept p_fromfacility prompt 'Enter origin facility: '
accept p_tofacility prompt 'Enter destination facility: '

declare
  CURSOR C_CUST(in_custid varchar2)
  IS
      select custid
        from customer
       where custid = in_custid;
  cust C_CUST%rowtype;
  
  CURSOR C_FAC(in_facility varchar2)
  IS
      select facility
        from facility
       where facility = in_facility;
  ffac C_FAC%rowtype;
  tfac C_FAC%rowtype;
  
  CURSOR C_ORDERS(in_facility varchar2, in_custid varchar2)
  IS
      select orderid, shipid, ordertype, orderstatus
        from orderhdr
       where recent_order_id like 'Y%'
         and (fromfacility = in_facility
          or  tofacility = in_facility)
         and custid = in_custid
         and orderstatus not in ('9','R','X')
       order by orderid, shipid;
  cord C_ORDERS%rowtype;
  
  CURSOR C_SHIPPLATE(in_facility varchar2, in_custid varchar2)
  IS
      select orderid, shipid, lpid, status
        from shippingplate
       where facility = in_facility
         and custid = in_custid
         and status <> 'SH'
       order by orderid, shipid;
  csp C_SHIPPLATE%rowtype;
  
  CURSOR C_TASKS(in_facility varchar2, in_custid varchar2)
  IS
      select count(1) as taskcount
        from tasks
       where facility = in_facility
         and custid = in_custid;
  ctk C_TASKS%rowtype;
  
  CURSOR C_SUBTASKS(in_facility varchar2, in_custid varchar2)
  IS
      select count(1) as taskcount
        from subtasks
       where facility = in_facility
         and custid = in_custid;

  CURSOR C_BATCHTASKS(in_facility varchar2, in_custid varchar2)
  IS
      select count(1) as taskcount
        from batchtasks
       where facility = in_facility
         and custid = in_custid;

  CURSOR C_PLATES(in_facility varchar2, in_custid varchar2)
  IS
      select lpid, location, rowid
        from plate
       where facility = in_facility
         and custid = in_custid
       order by lpid;
  pl C_PLATES%rowtype;

  CURSOR C_LOC(in_facility varchar2, in_location varchar2)
  IS
      select locid
        from location
       where facility = in_facility
         and locid = in_location;
  loc C_LOC%rowtype;

  CURSOR C_ITEMS(in_fromfacility varchar2, in_tofacility varchar2, in_custid varchar2)
  IS
      select distinct facility, custid, item, lotnumber, unitofmeasure,
        invstatus, inventoryclass
        from plate
       where type = 'PA'
         and facility in (in_fromfacility, in_tofacility)
         and custid = in_custid
   union
      select distinct facility, custid, item, lotnumber, uom unitofmeasure,
        invstatus, inventoryclass
        from asofinventory
       where facility in (in_fromfacility, in_tofacility)
         and custid = in_custid
   union
      select distinct facility, custid, item, lotnumber, unitofmeasure,
        invstatus, inventoryclass
        from deletedplate
       where type = 'PA'
         and facility in (in_fromfacility, in_tofacility)
         and custid = in_custid
   union
     select distinct  facility, custid, item, lotnumber, unitofmeasure,
        invstatus, inventoryclass
        from shippingplate
       where status in ('L','P','S','FA')
         and facility in (in_fromfacility, in_tofacility)
         and custid = in_custid
         and type in ('F','P')
   order by facility, item, lotnumber;


  CURSOR C_PLATE(in_facility varchar2, in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2,in_invstatus varchar2,
         in_inventoryclass varchar2) IS
    SELECT nvl(sum(quantity), 0) as quantity, nvl(sum(weight), 0) as weight
      FROM PLATE P
     WHERE P.status not in ('P','D','I')
       AND P.type = 'PA'
       AND P.custid = in_custid
       AND P.facility = in_facility
       AND P.item = in_item
       AND nvl(P.lotnumber,'<NONE>') = nvl(in_lotnumber,'<NONE>')
       AND nvl(P.invstatus,'<NONE>') = nvl(in_invstatus,'<NONE>')
       AND nvl(P.inventoryclass,'<NONE>') = nvl(in_inventoryclass,'<NONE>')
       AND P.unitofmeasure = in_uom
       AND (P.status <> 'M'
        OR  NOT EXISTS(
            SELECT 1
              FROM shippingplate S
             WHERE S.fromlpid = P.lpid
			         AND S.type in ('F', 'P')
               AND S.status in ('L','P', 'S', 'FA')));
  lp C_PLATE%rowtype;

  CURSOR C_SHIPPINGPLATE(in_facility varchar2,
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2,in_invstatus varchar2,
         in_inventoryclass varchar2) IS
    SELECT nvl(sum(quantity), 0) as quantity, nvl(sum(weight), 0) as weight
      FROM SHIPPINGPLATE SP
     WHERE SP.status in ('L','P', 'S', 'FA')
       AND SP.type in ('F', 'P')
       AND SP.custid = in_custid
       AND SP.facility = in_facility
       AND SP.item = in_item
       AND nvl(SP.lotnumber,'<NONE>') = nvl(in_lotnumber,'<NONE>')
       AND nvl(SP.invstatus,'<NONE>') = nvl(in_invstatus,'<NONE>')
       AND nvl(SP.inventoryclass,'<NONE>') = nvl(in_inventoryclass,'<NONE>')
       AND SP.unitofmeasure = in_uom;
  sp C_SHIPPINGPLATE%rowtype;

  CURSOR C_LASTASOF(in_facility varchar2,
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2,in_invstatus varchar2,
         in_inventoryclass varchar2)
    IS
   SELECT *
     FROM asofinventory
    WHERE facility = in_facility
      AND custid = in_custid
      AND item = in_item
      and nvl(lotnumber,'<NONE>') = nvl(in_lotnumber,'<NONE>')
      AND nvl(invstatus,'<NONE>') = nvl(in_invstatus,'<NONE>')
      AND nvl(inventoryclass,'<NONE>') = nvl(in_inventoryclass,'<NONE>')
      and uom = in_uom
      and effdate =
      (select max(effdate)
        from asofinventory
        where facility = in_facility
          AND custid = in_custid
          AND item = in_item
          and nvl(lotnumber,'<NONE>') = nvl(in_lotnumber,'<NONE>')
          AND nvl(invstatus,'<NONE>') = nvl(in_invstatus,'<NONE>')
          AND nvl(inventoryclass,'<NONE>') = nvl(in_inventoryclass,'<NONE>')
          and uom = in_uom);

  CURSOR C_ASOFDTLS(in_facility varchar2, in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2,in_invstatus varchar2,
         in_inventoryclass varchar2) IS
    SELECT effdate, nvl(sum(adjustment), 0) as adjustment,
           nvl(sum(weightadjustment), 0) as weightadjustment
      FROM ASOFINVENTORYDTL
     WHERE facility = in_facility
       AND custid = in_custid
       AND item = in_item
       AND nvl(lotnumber,'<NONE>') = nvl(in_lotnumber,'<NONE>')
       AND nvl(invstatus,'<NONE>') = nvl(in_invstatus,'<NONE>')
       AND nvl(inventoryclass,'<NONE>') = nvl(in_inventoryclass,'<NONE>')
       AND uom = in_uom
     GROUP BY effdate
     ORDER BY effdate;
  casofdtl C_ASOFDTLS%rowtype;

  CURSOR C_ASOF(in_facility varchar2, in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2,in_invstatus varchar2,
         in_inventoryclass varchar2, in_effdate date) IS
    SELECT nvl(previousqty,0) previousqty, nvl(previousweight,0) previousweight,
           nvl(currentqty,0) currentqty, nvl(currentweight,0) currentweight,
           rowid
      FROM ASOFINVENTORY
     WHERE facility = in_facility
       AND custid = in_custid
       AND item = in_item
       AND nvl(lotnumber,'<NONE>') = nvl(in_lotnumber,'<NONE>')
       AND nvl(invstatus,'<NONE>') = nvl(in_invstatus,'<NONE>')
       AND nvl(inventoryclass,'<NONE>') = nvl(in_inventoryclass,'<NONE>')
       AND uom = in_uom
       AND effdate = in_effdate;
  casof C_ASOF%rowtype;

   asof C_LASTASOF%rowtype;

   od_cnt integer;
   qty_adj number;
   wt_adj number;
   prev_qty number;
   prev_wt number;
   errmsg varchar2(400);

begin

   dbms_output.enable(1000000);

   cust := null;
   OPEN C_CUST(upper('&&p_custid'));
   FETCH C_CUST into cust;
   CLOSE C_CUST;
   
   if nvl(cust.custid,'(none)') = '(none)' then
      zut.prt('Invalid custid: ' || upper('&&p_custid'));
      return;
   end if;

   ffac := null;
   OPEN C_FAC(upper('&&p_fromfacility'));
   FETCH C_FAC into ffac;
   CLOSE C_FAC;

   if nvl(ffac.facility,'(none)') = '(none)' then
      zut.prt('Invalid origin facility: ' || upper('&&p_fromfacility'));
      return;
   end if;

   tfac := null;
   OPEN C_FAC(upper('&&p_tofacility'));
   FETCH C_FAC into tfac;
   CLOSE C_FAC;

   if nvl(tfac.facility,'(none)') = '(none)' then
      zut.prt('Invalid destination facility: ' || upper('&&p_tofacility'));
      return;
   end if;

   od_cnt := 0;
   for cord in  C_ORDERS(ffac.facility, cust.custid) loop
      od_cnt := od_cnt + 1;
      zut.prt('   Open order: ' ||cord.orderid||'-'||cord.shipid);
   end loop;
   if od_cnt > 0 then
      zut.prt('  Unable to continue due to '||od_cnt||' open orders');
      return;
   end if;
            
   od_cnt := 0;
   for csp in  C_SHIPPLATE(ffac.facility, cust.custid) loop
      od_cnt := od_cnt + 1;
      zut.prt('   Unshipped shipping plate: ' ||csp.lpid);
   end loop;
   if od_cnt > 0 then
      zut.prt('  Unable to continue due to '||od_cnt||' unshipped shipping plates');
      return;
   end if;
            
   ctk := null;
   OPEN C_TASKS(ffac.facility,cust.custid);
   FETCH C_TASKS into ctk;
   CLOSE C_TASKS;
   
   if ctk.taskcount > 0 then
      zut.prt('  Unable to continue due to '||ctk.taskcount||' open tasks');
      return;
   end if;

   ctk := null;
   OPEN C_SUBTASKS(ffac.facility,cust.custid);
   FETCH C_SUBTASKS into ctk;
   CLOSE C_SUBTASKS;
   
   if ctk.taskcount > 0 then
      zut.prt('  Unable to continue due to '||ctk.taskcount||' open subtasks');
      return;
   end if;

   ctk := null;
   OPEN C_BATCHTASKS(ffac.facility,cust.custid);
   FETCH C_BATCHTASKS into ctk;
   CLOSE C_BATCHTASKS;
   
   if ctk.taskcount > 0 then
      zut.prt('  Unable to continue due to '||ctk.taskcount||' open batch tasks');
      return;
   end if;

   od_cnt := 0;
   for pl in  C_PLATES(ffac.facility, cust.custid) loop
      if nvl(pl.location,'(none)') != '(none)' then
         loc := null;
         OPEN C_LOC(tfac.facility,pl.location);
         FETCH C_LOC into loc;
         CLOSE C_LOC;
         
         if nvl(loc.locid,'(none)') = '(none)' then
            zut.prt('Invalid destination location '||pl.location||' for plate '||pl.lpid);
            zut.prt('All updates have been rolled back');
            od_cnt := 0;
            rollback;
            return;
         end if;
      end if;
      
      od_cnt := od_cnt + 1;
      update plate
         set facility = tfac.facility,
             lastuser = 'SYNAPSE',
             lastupdate = sysdate
       where rowid = pl.rowid;
      zut.prt('   Updated: ' ||pl.lpid);
   end loop;
   if od_cnt > 0 then
      zut.prt('  Updated '||od_cnt||' plates');
   end if;

   for crec in C_ITEMS(ffac.facility,tfac.facility,cust.custid) loop
      OPEN C_PLATE(crec.facility, crec.custid, crec.item, crec.lotnumber,
            crec.unitofmeasure, crec.invstatus, crec.inventoryclass);
      FETCH C_PLATE into lp;
      CLOSE C_PLATE;

      OPEN C_SHIPPINGPLATE(crec.facility, crec.custid, crec.item, crec.lotnumber,
            crec.unitofmeasure, crec.invstatus, crec.inventoryclass);
      FETCH C_SHIPPINGPLATE into sp;
      CLOSE C_SHIPPINGPLATE;

      asof := null;
      OPEN C_LASTASOF(crec.facility, crec.custid, crec.item, crec.lotnumber,
            crec.unitofmeasure, crec.invstatus, crec.inventoryclass);
      FETCH C_LASTASOF into asof;
      CLOSE C_LASTASOF;
      if asof.currentqty is null then
         asof.currentqty := 0;
      end if;

      if asof.currentweight is null then
         asof.currentweight := 0;
      end if;

      if (asof.currentqty != lp.quantity + sp.quantity) or
         (asof.currentweight != lp.weight + sp.weight) then
         prev_qty := 0;
         prev_wt := 0;
         
         for casofdtl in C_ASOFDTLS(crec.facility, crec.custid, crec.item,
               crec.lotnumber, crec.unitofmeasure, crec.invstatus,
               crec.inventoryclass) loop
   
            casof := null;
            OPEN C_ASOF(crec.facility, crec.custid, crec.item, crec.lotnumber,
                  crec.unitofmeasure, crec.invstatus, crec.inventoryclass,
                  casofdtl.effdate);
            FETCH C_ASOF into casof;
            CLOSE C_ASOF;
   
            if casof.previousqty is null then
               casof.previousqty := 0;
            end if;
            if casof.previousweight is null then
               casof.previousweight := 0;
            end if;
            if casof.currentqty is null then
               casof.currentqty := 0;
            end if;
            if casof.currentweight is null then
               casof.currentweight := 0;
            end if;
            
            if (casof.previousqty != prev_qty) or (casof.previousweight != prev_wt) or
               (casof.currentqty != prev_qty + casofdtl.adjustment) or
               (casof.currentweight != prev_wt + casofdtl.weightadjustment) then
               update asofinventory
                  set previousqty = prev_qty,
                      previousweight = prev_wt,
                      currentqty = prev_qty + casofdtl.adjustment,
                      currentweight = prev_wt + casofdtl.weightadjustment
                where rowid = casof.rowid;

   	           zut.prt('FOR: '||crec.facility||'/'||crec.custid
   	              ||'/'||crec.item
   	              ||'/'||crec.lotnumber
   	              ||'/'||crec.unitofmeasure
   	              ||'/'||crec.invstatus
   	              ||'/'||crec.inventoryclass
   	              ||' Adjust asof balances');
            end if;
            
            prev_qty := prev_qty + casofdtl.adjustment;
            prev_wt := prev_wt + casofdtl.weightadjustment;
         end loop;

         if (asof.currentqty != lp.quantity + sp.quantity) or
            (asof.currentweight != lp.weight + sp.weight) then
            asof := null;
            OPEN C_LASTASOF(crec.facility, crec.custid, crec.item, crec.lotnumber,
                  crec.unitofmeasure, crec.invstatus, crec.inventoryclass);
            FETCH C_LASTASOF into asof;
            CLOSE C_LASTASOF;
            if asof.currentqty is null then
               asof.currentqty := 0;
            end if;
      
            if asof.currentweight is null then
               asof.currentweight := 0;
            end if;
   
   	        if (asof.currentqty != lp.quantity + sp.quantity) then
   	           zut.prt('FOR: '||crec.facility||'/'||crec.custid
   	              ||'/'||crec.item
   	              ||'/'||crec.lotnumber
   	              ||'/'||crec.unitofmeasure
   	              ||'/'||crec.invstatus
   	              ||'/'||crec.inventoryclass
   	              ||' = '||to_char(lp.quantity)
   	              ||' + '||to_char(sp.quantity)
   	              ||' CQ='||to_char(asof.currentqty));
   	       end if;
   	
            if (asof.currentweight != lp.weight + sp.weight) then
               zut.prt('FOR: '||crec.facility||'/'||crec.custid
                  ||'/'||crec.item
                  ||'/'||crec.lotnumber
                  ||'/'||crec.unitofmeasure
                  ||'/'||crec.invstatus
                  ||'/'||crec.inventoryclass
                  ||' = '||to_char(lp.weight)
                  ||' + '||to_char(sp.weight)
                  ||' CW='||to_char(asof.currentweight));
            end if;
   
            qty_adj := (lp.quantity + sp.quantity) - asof.currentqty;
            wt_adj := (lp.weight + sp.weight) - asof.currentweight;
   
            zbill.add_asof_inventory(
                  crec.facility,
                  crec.custid,
                  crec.item,
                  crec.lotnumber,
                  crec.unitofmeasure,
                  trunc(sysdate),
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
   end loop;
end;
/
