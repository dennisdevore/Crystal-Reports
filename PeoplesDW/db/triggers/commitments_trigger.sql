create or replace trigger commitments_aiud
--
-- $Id$
--
after insert or update or delete
on commitments
for each row

declare
cursor curItem(in_custid varchar2, in_item varchar2) is
  select nvl(useramt1,0) as useramt1
    from custitem
   where custid = in_custid
     and item = in_item;
ci curItem%rowtype;

cursor curOrderDtl(in_orderid number, in_shipid number,
               in_orderitem varchar2, in_orderlot varchar2) is
  select nvl(qtycommit,0) as qtycommit,
         nvl(qtytotcommit,0) as qtytotcommit
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)');
od curOrderDtl%rowtype;

userid varchar2(12);
lipcount number(15);

begin
   if (deleting) or
      ( (updating) and
        ((nvl(:old.qty,0) != nvl(:new.qty,0)) or
         (nvl(:old.facility,'x') != nvl(:new.facility,'x')) or
         (nvl(:old.custid,'x') != nvl(:new.custid,'x')) or
         (nvl(:old.orderid,-1) != nvl(:new.orderid,-1)) or
         (nvl(:old.shipid,-1) != nvl(:new.shipid,-1)) or
         (nvl(:old.item,'x') != nvl(:new.item,'x')) or
         (nvl(:old.orderitem,'x') != nvl(:new.orderitem,'x')) or
         (nvl(:old.inventoryclass,'RG') != nvl(:new.inventoryclass,'RG')) or
         (nvl(:old.invstatus,'x') != nvl(:new.invstatus,'x')) or
         (nvl(:old.lotnumber,'(none)') != nvl(:new.lotnumber,'(none)')) or
         (nvl(:old.orderlot,'(none)') != nvl(:new.orderlot,'(none)')) or
         (nvl(:old.uom,'x') != nvl(:new.uom,'x'))) ) then
      if (deleting) then
        userid := :old.lastuser;
      else
        userid := :new.lastuser;
      end if;
      begin
        select lipcount
          into lipcount
          from custitemtot
         where facility = nvl(:old.facility,'x')
           and custid = nvl(:old.custid,'x')
           and item = nvl(:old.item,'x')
           and inventoryclass = nvl(:old.inventoryclass,'RG')
           and invstatus = nvl(:old.invstatus,'x')
           and status = 'CM'
           and lotnumber = nvl(:old.lotnumber,'(none)')
           and uom = nvl(:old.uom,'x');
      exception when no_data_found then
        lipcount := -1;
      end;
      if lipcount = 1 then
        delete
          from custitemtot
         where facility = nvl(:old.facility,'x')
           and custid = nvl(:old.custid,'x')
           and item = nvl(:old.item,'x')
           and inventoryclass = nvl(:old.inventoryclass,'RG')
           and invstatus = nvl(:old.invstatus,'x')
           and status = 'CM'
           and lotnumber = nvl(:old.lotnumber,'(none)')
           and uom = nvl(:old.uom,'x');
      elsif lipcount <> -1 then
        update custitemtot
           set lipcount = lipcount - 1,
               qty = qty - nvl(:old.qty,0),
               weight = nvl(weight,0) - nvl(zci.item_weight(:old.custid,:old.item,:old.uom) * nvl(:old.qty,0),0),
               lastuser = userid,
               lastupdate = sysdate
         where facility = nvl(:old.facility,'x')
           and custid = nvl(:old.custid,'x')
           and item = nvl(:old.item,'x')
           and inventoryclass = nvl(:old.inventoryclass,'RG')
           and invstatus = nvl(:old.invstatus,'x')
           and status = 'CM'
           and lotnumber = nvl(:old.lotnumber,'(none)')
           and uom = nvl(:old.uom,'x');
      end if;
      if((nvl(:old.qty,0) != nvl(:new.qty,0)) or
         (nvl(:old.custid,'x') != nvl(:new.custid,'x')) or
         (nvl(:old.orderid,-1) != nvl(:new.orderid,-1)) or
         (nvl(:old.shipid,-1) != nvl(:new.shipid,-1)) or
         (nvl(:old.item,'x') != nvl(:new.item,'x')) or
         (nvl(:old.orderitem,'x') != nvl(:new.orderitem,'x')) or
         (nvl(:old.orderlot,'(none)') != nvl(:new.orderlot,'(none)')) or
         (nvl(:old.uom,'x') != nvl(:new.uom,'x')) ) then
         open curItem(:old.custid,:old.item);
         fetch curItem into ci;
         if curItem%notfound then
           ci.useramt1 := 0;
         end if;
         close curItem;
         update orderdtl
            set qtycommit = nvl(qtycommit,0) - nvl(:old.qty,0),
                weightcommit = nvl(weightcommit,0) - (zci.item_weight(:old.custid,:old.item,:old.uom) * nvl(:old.qty,0)),
                cubecommit = nvl(cubecommit,0) - (zci.item_cube(:old.custid,:old.item,:old.uom) * nvl(:old.qty,0)),
                amtcommit = nvl(amtcommit,0) - (nvl(:old.qty,0) * zci.item_amt(custid, orderid, shipid, item, lotnumber))
          where orderid = :old.orderid
            and shipid = :old.shipid
            and item = :old.orderitem
            and nvl(lotnumber,'(none)') = nvl(:old.orderlot,'(none)');
      end if;
   end if;

   if (inserting) or
      ( (updating) and
        ((nvl(:old.qty,0) != nvl(:new.qty,0)) or
         (nvl(:old.facility,'x') != nvl(:new.facility,'x')) or
         (nvl(:old.custid,'x') != nvl(:new.custid,'x')) or
         (nvl(:old.orderid,-1) != nvl(:new.orderid,-1)) or
         (nvl(:old.shipid,-1) != nvl(:new.shipid,-1)) or
         (nvl(:old.item,'x') != nvl(:new.item,'x')) or
         (nvl(:old.orderitem,'x') != nvl(:new.orderitem,'x')) or
         (nvl(:old.inventoryclass,'RG') != nvl(:new.inventoryclass,'RG')) or
         (nvl(:old.invstatus,'x') != nvl(:new.invstatus,'x')) or
         (nvl(:old.lotnumber,'(none)') != nvl(:new.lotnumber,'(none)')) or
         (nvl(:old.orderlot,'(none)') != nvl(:new.orderlot,'(none)')) or
         (nvl(:old.uom,'x') != nvl(:new.uom,'x'))) ) then
      update custitemtot
         set lipcount = lipcount + 1,
             qty = qty + nvl(:new.qty,0),
             weight = nvl(weight,0) + nvl(zci.item_weight(:new.custid,:new.item,:new.uom) * nvl(:new.qty,0),0),
             lastuser = :new.lastuser,
             lastupdate = sysdate
       where facility = nvl(:new.facility,'x')
         and custid = nvl(:new.custid,'x')
         and item = nvl(:new.item,'x')
         and inventoryclass = nvl(:new.inventoryclass,'RG')
         and invstatus = nvl(:new.invstatus,'x')
         and status = 'CM'
         and lotnumber = nvl(:new.lotnumber,'(none)')
         and uom = nvl(:new.uom,'x');
      if sql%rowcount = 0 then
        insert into custitemtot
             (facility, custid, item,
              lotnumber, inventoryclass,
              uom, invstatus, status,
              lipcount, qty,
              lastuser, lastupdate, weight)
        values
             (nvl(:new.facility,'x'), nvl(:new.custid,'x'), nvl(:new.item,'x'),
              nvl(:new.lotnumber,'(none)'), nvl(:new.inventoryclass,'RG'),
              nvl(:new.uom,'x'), nvl(:new.invstatus,'x'), 'CM',
              1, nvl(:new.qty,0),
              :new.lastuser, sysdate, nvl(zci.item_weight(:new.custid,:new.item,:new.uom) * nvl(:new.qty,0),0));
      end if;
      if((nvl(:old.qty,0) != nvl(:new.qty,0)) or
         (nvl(:old.custid,'x') != nvl(:new.custid,'x')) or
         (nvl(:old.orderid,-1) != nvl(:new.orderid,-1)) or
         (nvl(:old.shipid,-1) != nvl(:new.shipid,-1)) or
         (nvl(:old.item,'x') != nvl(:new.item,'x')) or
         (nvl(:old.orderitem,'x') != nvl(:new.orderitem,'x')) or
         (nvl(:old.orderlot,'(none)') != nvl(:new.orderlot,'(none)')) or
         (nvl(:old.uom,'x') != nvl(:new.uom,'x')) ) then
         open curItem(:new.custid,:new.item);
         fetch curItem into ci;
         if curItem%notfound then
           ci.useramt1 := 0;
         end if;
         close curItem;
         open curOrderDtl(:new.orderid,:new.shipid,:new.orderitem,:new.orderlot);
         fetch curOrderDtl into od;
         if curOrderDtl%notfound then
           od.qtycommit := 0;
         end if;
         close curOrderDtl;
         if (od.qtycommit + nvl(:new.qty,0)) > od.qtytotcommit then
           update orderdtl
              set qtycommit = nvl(qtycommit,0) + nvl(:new.qty,0),
                  weightcommit = nvl(weightcommit,0) + (zci.item_weight(:new.custid,:new.item,:new.uom) * nvl(:new.qty,0)),
                  cubecommit = nvl(cubecommit,0) + (zci.item_cube(:new.custid,:new.item,:new.uom) * nvl(:new.qty,0)),
                  amtcommit = nvl(amtcommit,0) + (nvl(:new.qty,0) * zci.item_amt(custid,orderid,shipid,item,lotnumber)),
                  qtytotcommit = (od.qtycommit + nvl(:new.qty,0)),
                  weighttotcommit = (od.qtycommit + nvl(:new.qty,0)) * zci.item_weight(:new.custid,:new.item,:new.uom),
                  cubetotcommit = (od.qtycommit + nvl(:new.qty,0)) * zci.item_cube(:new.custid,:new.item,:new.uom),
                  amttotcommit = (od.qtycommit + nvl(:new.qty,0)) * zci.item_amt(custid,orderid,shipid,item,lotnumber)
            where orderid = :new.orderid
              and shipid = :new.shipid
              and item = :new.orderitem
              and nvl(lotnumber,'x') = nvl(:new.orderlot,'x');
         else
           update orderdtl
              set qtycommit = nvl(qtycommit,0) + nvl(:new.qty,0),
                  weightcommit = nvl(weightcommit,0) + (zci.item_weight(:new.custid,:new.item,:new.uom) * nvl(:new.qty,0)),
                  cubecommit = nvl(cubecommit,0) + (zci.item_cube(:new.custid,:new.item,:new.uom) * nvl(:new.qty,0)),
                  amtcommit = nvl(amtcommit,0) + (nvl(:new.qty,0) * zci.item_amt(custid,orderid,shipid,item,lotnumber))
            where orderid = :new.orderid
              and shipid = :new.shipid
              and item = :new.orderitem
              and nvl(lotnumber,'x') = nvl(:new.orderlot,'x');
         end if;
      end if;
   end if;

end;
/
show error trigger commitments_aiud;
exit;
