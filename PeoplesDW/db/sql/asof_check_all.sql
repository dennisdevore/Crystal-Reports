--
-- $Id$
--
set serveroutput on

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
    SELECT sum(quantity)
      FROM PLATE P
     WHERE P.status not in ('P','D','I')
       AND P.type = 'PA'
       AND P.custid = in_custid
       AND P.facility = in_facility
       AND P.item = in_item
       AND nvl(P.lotnumber,'<NONE>') = nvl(in_lotnumber,'<NONE>')
       AND nvl(P.invstatus,'<NONE>') = nvl(in_invstatus,'<NONE>')
       AND nvl(P.inventoryclass,'<NONE>') = nvl(in_inventoryclass,'<NONE>')
       AND P.unitofmeasure = in_uom;

  CURSOR C_SHIPPINGPLATE(in_facility varchar2,
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2,in_invstatus varchar2,
         in_inventoryclass varchar2) IS
    SELECT sum(quantity)
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

  CURSOR C_CHECKRECV(in_facility varchar2,
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2)
   IS
  SELECT distinct OH.orderid, OH.shipid, OH.ordertype
    FROM orderdtl OD, orderhdr OH
   WHERE OH.custid = in_custid
     AND OH.tofacility = in_facility
     AND (OH.ordertype in ('R', 'T', 'C', 'U')
         AND OH.orderstatus = 'A'
      OR OH.ordertype = 'Q'
         AND OH.orderstatus in ('A','1'))
     AND OH.orderid = OD.orderid
     AND OH.shipid = OD.shipid
     AND OD.item = in_item
     AND nvl(OD.lotnumber,'<none>') = nvl(in_lotnumber, '<none>');

   asof C_LASTASOF%rowtype;

   od_cnt integer;
   qty number;
   qty_sp number;

begin

   dbms_output.enable(1000000);

   for crec in C_ITEMS loop
      qty := 0;
      OPEN C_PLATE(crec.facility, crec.custid, crec.item, crec.lotnumber,
            crec.unitofmeasure, crec.invstatus, crec.inventoryclass);
      FETCH C_PLATE into qty;
      CLOSE C_PLATE;
      if qty is null then
         qty := 0;
      end if;

      qty_sp := 0;
      OPEN C_SHIPPINGPLATE(crec.facility, crec.custid, crec.item, crec.lotnumber,
            crec.unitofmeasure, crec.invstatus, crec.inventoryclass);
      FETCH C_SHIPPINGPLATE into qty_sp;
      CLOSE C_SHIPPINGPLATE;
      if qty_sp is null then
         qty_sp := 0;
      end if;

      asof := null;
      OPEN C_LASTASOF(crec.facility, crec.custid, crec.item, crec.lotnumber,
            crec.unitofmeasure, crec.invstatus, crec.inventoryclass);
      FETCH C_LASTASOF into asof;
      CLOSE C_LASTASOF;
      if asof.currentqty is null then
         asof.currentqty := 0;
      end if;

      if (asof.currentqty != qty + qty_sp) then
         zut.prt('FOR: '||crec.facility||'/'||crec.custid
               ||'/'||crec.item
               ||'/'||crec.lotnumber
               ||'/'||crec.unitofmeasure
               ||'/'||crec.invstatus
               ||'/'||crec.inventoryclass
               ||' = '||to_char(qty)
               ||' + '||to_char(qty_sp)
               ||' CQ='||to_char(asof.currentqty));

         od_cnt := 0;
         for cord in  C_CHECKRECV(crec.facility, crec.custid,  crec.item, crec.lotnumber) loop
            od_cnt := od_cnt + 1;
            if cord.ordertype in ('R', 'C') then
               zut.prt('     SKIPPED because open receipt:' ||cord.orderid||'-'||cord.shipid);
            elsif cord.ordertype = 'T' then
               zut.prt('     SKIPPED because open transfer:' ||cord.orderid||'-'||cord.shipid);
            elsif cord.ordertype = 'U' then
               zut.prt('     SKIPPED because open cross cust:' ||cord.orderid||'-'||cord.shipid);
            else
               zut.prt('     SKIPPED because open returns:' ||cord.orderid||'-'||cord.shipid);
            end if;
         end loop;
         if od_cnt > 0 then
            zut.prt('  SKIPPED because open receipts:'||od_cnt);
         end if;
      end if;
   end loop;
end;
/
