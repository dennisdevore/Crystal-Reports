--
-- $Id$
--
set serveroutput on
set verify off
accept p_effdate prompt 'Enter effdate (YYYYMMDD): '

declare
  CURSOR C_ITEMS
  IS
      select distinct facility, custid, item, lotnumber, unitofmeasure,
        invstatus, inventoryclass
        from plate
       where type = 'PA'
   union
      select distinct facility, custid, item, lotnumber, uom unitofmeasure,
        invstatus, inventoryclass
        from asofinventory
   union
      select distinct facility, custid, item, lotnumber, unitofmeasure,
        invstatus, inventoryclass
        from deletedplate
       where type = 'PA'
   union
     select distinct  facility, custid, item, lotnumber, unitofmeasure,
        invstatus, inventoryclass
        from shippingplate
       where status in ('L','P','S','FA')
         and type in ('F','P')
   order by facility, custid, item, lotnumber;


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

  CURSOR C_CHECKRECV(in_facility varchar2,
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2)
   IS
  SELECT distinct OH.orderid, OH.shipid, OH.ordertype
    FROM orderdtl OD, orderhdr OH
   WHERE OH.custid = in_custid
     AND OH.tofacility = in_facility
     AND ((OH.ordertype in ('R', 'T', 'C', 'U')
         AND OH.orderstatus = 'A')
      OR (OH.ordertype = 'Q'
         AND OH.orderstatus not in ('X','R')
         AND nvl(OH.qtyrcvd,0) > 0))
     AND OH.orderid = OD.orderid
     AND OH.shipid = OD.shipid
     AND OD.item = in_item
     AND nvl(OD.lotnumber,'<none>') = nvl(in_lotnumber, '<none>');

   asof C_LASTASOF%rowtype;

   od_cnt integer;
   qty_adj number;
   wt_adj number;
   prev_qty number;
   prev_wt number;
   errmsg varchar2(400);
   sv_max_asof_backdate customer_aux.max_asof_backdate_days%type;
   prev_custid customer.custid%type;

begin

   dbms_output.enable(1000000);

   prev_custid := '';
   sv_max_asof_backdate := 0;

   for crec in C_ITEMS loop

	  -- to make sure the add_asof_inventory doesn't fail on an older effdate,
	  -- we turn off the customer_aux.max_asof_backdate_days, making it 0.
	  -- at end of this custid we restore its original value if it wasn't 0.
	  if crec.custid != prev_custid then
	    if sv_max_asof_backdate > 0 and prev_custid != '' then
		  update customer_aux set max_asof_backdate_days = sv_max_asof_backdate 
			where custid = prev_custid;
	    end if;
        prev_custid := crec.custid;
        BEGIN
	      select nvl(max_asof_backdate_days,0)
	        into sv_max_asof_backdate
	        from customer_aux
	       where custid = crec.custid;
	    EXCEPTION 
	     WHEN NO_DATA_FOUND THEN
		   sv_max_asof_backdate := 0;
	    END;
	    update customer_aux set max_asof_backdate_days = 0 where custid = crec.custid;
	  end if;

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
   
            od_cnt := 0;
            for cord in  C_CHECKRECV(crec.facility, crec.custid,  crec.item, crec.lotnumber) loop
               od_cnt := od_cnt + 1;
               if cord.ordertype in ('R', 'C') then
                  zut.prt('     SKIPPED because open receipt: ' ||cord.orderid||'-'||cord.shipid);
               elsif cord.ordertype = 'T' then
                  zut.prt('     SKIPPED because open transfer:' ||cord.orderid||'-'||cord.shipid);
               elsif cord.ordertype = 'U' then
                  zut.prt('     SKIPPED because open cross cust:' ||cord.orderid||'-'||cord.shipid);
               else
                  zut.prt('     SKIPPED because open returns: ' ||cord.orderid||'-'||cord.shipid);
               end if;
            end loop;
            if od_cnt > 0 then
               zut.prt('  SKIPPED because open receipts: '||od_cnt);
            else
               zbill.add_asof_inventory(
                     crec.facility,
                     crec.custid,
                     crec.item,
                     crec.lotnumber,
                     crec.unitofmeasure,
                     to_date('&&p_effdate','YYYYMMDD'),
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
      end if;
   end loop;
   if sv_max_asof_backdate > 0 and prev_custid != '' then
		update customer_aux set max_asof_backdate_days = sv_max_asof_backdate 
			where custid = prev_custid;
   end if;
end;
/
