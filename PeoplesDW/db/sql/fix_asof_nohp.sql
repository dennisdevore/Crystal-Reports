--
-- $Id$
--
set serveroutput on

declare
errmsg varchar2(400);
rc integer;
  
  CURSOR C_ITEMS IS
      select distinct facility, custid, item, lotnumber, unitofmeasure
        from plate where type = 'PA'
   union
      select distinct facility, custid, item, lotnumber, uom unitofmeasure
        from asofinventory
   union
      select distinct facility, custid, item, lotnumber, unitofmeasure
        from deletedplate where type = 'PA'
   union
     select distinct  facility, custid, item, lotnumber, unitofmeasure
        from shippingplate where status in ('L','P','S')
        and type in ('F','P');


  CURSOR C_PLATE(in_facility varchar2, in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2) IS
    SELECT sum(quantity)
      FROM ORDERHDR OH, PLATE P
     WHERE P.status not in ('P','U', 'D')
       AND P.type = 'PA'
       AND P.orderid = OH.orderid(+)
       AND P.shipid = OH.shipid(+)
       AND nvl(OH.orderstatus,'R') = 'R'
       AND P.custid = in_custid
       AND P.facility = in_facility
       AND P.item = in_item
       AND nvl(P.lotnumber,'<NONE>') = nvl(in_lotnumber,'<NONE>')
       AND P.unitofmeasure = in_uom;

  CURSOR C_SHIPPINGPLATE(in_facility varchar2, 
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2) IS
    SELECT sum(quantity)
      FROM SHIPPINGPLATE SP
     WHERE SP.status in ('L','P', 'S')
       AND SP.type in ('F', 'P')
       AND SP.custid = in_custid
       AND SP.facility = in_facility
       AND SP.item = in_item
       AND nvl(SP.lotnumber,'<NONE>') = nvl(in_lotnumber,'<NONE>')
       AND SP.unitofmeasure = in_uom;

  CURSOR C_LASTASOF(in_facility varchar2, 
         in_custid varchar2, in_item varchar2,
         in_lotnumber varchar2, in_uom varchar2)
    IS
   SELECT *
     FROM asofinventory
    WHERE facility = in_facility
      AND custid = in_custid
      AND item = in_item
      and nvl(lotnumber,'<NONE>') = nvl(in_lotnumber,'<NONE>')
      and uom = in_uom
      and effdate =
      (select max(effdate)
        from asofinventory
        where facility = in_facility
          AND custid = in_custid
          AND item = in_item
          and nvl(lotnumber,'<NONE>') = nvl(in_lotnumber,'<NONE>')
          and uom = in_uom);

asof C_LASTASOF%rowtype;

qty number;
qty_sp number;
qty_adj number;

begin

        dbms_output.enable(1000000);


   for crec in C_ITEMS loop
    if crec.custid != 'HP' then
       qty := 0;
       OPEN C_PLATE(crec.facility, crec.custid, crec.item, crec.lotnumber,
            crec.unitofmeasure);
       FETCH C_PLATE into qty;
       CLOSE C_PLATE;

       qty_sp := 0;
       OPEN C_SHIPPINGPLATE(crec.facility, crec.custid, crec.item, crec.lotnumber,
            crec.unitofmeasure);
       FETCH C_SHIPPINGPLATE into qty_sp;
       CLOSE C_SHIPPINGPLATE;

       if qty is null then
          qty := 0;
       end if;
       if qty_sp is null then
          qty_sp := 0;
       end if;

       asof := null;
       OPEN C_LASTASOF(crec.facility, crec.custid, crec.item, crec.lotnumber,
            crec.unitofmeasure);
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
                  ||' = '||to_char(qty)
                  ||' + '||to_char(qty_sp)
                  ||' CQ='||to_char(asof.currentqty));

          qty_adj := (qty + qty_sp) - asof.currentqty;


         zbill.add_asof_inventory(
                crec.facility,
                crec.custid,
                crec.item,
                crec.lotnumber,
                crec.unitofmeasure,
                to_date('20000719','YYYYMMDD'),
                qty_adj,
                'INITIAL',
                'RONG',
                errmsg
           );

       end if;
    end if;

   end loop;

end;
/
