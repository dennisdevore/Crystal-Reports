create or replace trigger shippingplate_aiud
--
-- $Id$
--
after insert or update or delete
on shippingplate
for each row

declare
userid varchar2(12);
lipcount number(15);
l_keep_history varchar2(10);
chgdate date;

begin
   if ( (deleting) or
       ((updating) and
        ((nvl(:old.type,'x') != nvl(:new.type,'x')) or
         (nvl(:old.quantity,0) != nvl(:new.quantity,0)) or
         (nvl(:old.weight,0) != nvl(:new.weight,0)) or
         (nvl(:old.facility,'x') != nvl(:new.facility,'x')) or
         (nvl(:old.custid,'x') != nvl(:new.custid,'x')) or
         (nvl(:old.item,'x') != nvl(:new.item,'x')) or
         (nvl(:old.inventoryclass,'RG') != nvl(:new.inventoryclass,'RG')) or
         (nvl(:old.invstatus,'x') != nvl(:new.invstatus,'x')) or
         (nvl(:old.lotnumber,'(none)') != nvl(:new.lotnumber,'(none)')) or
         (nvl(:old.unitofmeasure,'x') != nvl(:new.unitofmeasure,'x')) or
         (nvl(:old.status,'x') != nvl(:new.status,'x')))) ) and
      (:old.status in ('P','S','L','FA')) and
      (:old.type in ('F','P'))  then
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
           and status = 'PN'
           and lotnumber = nvl(:old.lotnumber,'(none)')
           and uom = nvl(:old.unitofmeasure,'x');
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
           and status = 'PN'
           and lotnumber = nvl(:old.lotnumber,'(none)')
           and uom = nvl(:old.unitofmeasure,'x');
      elsif lipcount <> -1 then
        update custitemtot
           set lipcount = lipcount - 1,
               qty = qty - nvl(:old.quantity,0),
               weight = nvl(weight,0) - nvl(:old.weight,0),
               lastuser = userid,
               lastupdate = sysdate
         where facility = nvl(:old.facility,'x')
           and custid = nvl(:old.custid,'x')
           and item = nvl(:old.item,'x')
           and inventoryclass = nvl(:old.inventoryclass,'RG')
           and invstatus = nvl(:old.invstatus,'x')
           and status = 'PN'
           and lotnumber = nvl(:old.lotnumber,'(none)')
           and uom = nvl(:old.unitofmeasure,'x');
      end if;
   end if;

   if ( (inserting) or
       ((updating) and
        ((nvl(:old.type,'x') != nvl(:new.type,'x')) or
         (nvl(:old.quantity,0) != nvl(:new.quantity,0)) or
         (nvl(:old.weight,0) != nvl(:new.weight,0)) or
         (nvl(:old.facility,'x') != nvl(:new.facility,'x')) or
         (nvl(:old.custid,'x') != nvl(:new.custid,'x')) or
         (nvl(:old.item,'x') != nvl(:new.item,'x')) or
         (nvl(:old.inventoryclass,'RG') != nvl(:new.inventoryclass,'RG')) or
         (nvl(:old.invstatus,'x') != nvl(:new.invstatus,'x')) or
         (nvl(:old.lotnumber,'(none)') != nvl(:new.lotnumber,'(none)')) or
         (nvl(:old.unitofmeasure,'x') != nvl(:new.unitofmeasure,'x')) or
         (nvl(:old.status,'x') != nvl(:new.status,'x')))) ) and
      (:new.status in ('P','S','L','FA')) and
      (:new.type in ('F','P')) then
      update custitemtot
         set lipcount = lipcount + 1,
             qty = qty + nvl(:new.quantity,0),
             weight = nvl(weight,0) + nvl(:new.weight,0),
             lastuser = :new.lastuser,
             lastupdate = sysdate
       where facility = nvl(:new.facility,'x')
         and custid = nvl(:new.custid,'x')
         and item = nvl(:new.item,'x')
         and inventoryclass = nvl(:new.inventoryclass,'RG')
         and invstatus = nvl(:new.invstatus,'x')
         and status = 'PN'
         and lotnumber = nvl(:new.lotnumber,'(none)')
         and uom = nvl(:new.unitofmeasure,'x');
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
              nvl(:new.unitofmeasure,'x'), nvl(:new.invstatus,'x'), 'PN',
              1, nvl(:new.quantity,0),
              :new.lastuser, sysdate, nvl(:new.weight,0));
      end if;
   end if;

   chgdate := sysdate;
   if (updating
   and ((nvl(:old.lpid, 'x') != nvl(:new.lpid, 'x'))
    or  (nvl(:old.item, 'x') != nvl(:new.item, 'x'))
    or  (nvl(:old.custid, 'x') != nvl(:new.custid, 'x'))
    or  (nvl(:old.facility, 'x') != nvl(:new.facility, 'x'))
    or  (nvl(:old.location, 'x') != nvl(:new.location, 'x'))
    or  (nvl(:old.status, 'x') != nvl(:new.status, 'x'))
    or  (nvl(:old.holdreason, 'x') != nvl(:new.holdreason, 'x'))
    or  (nvl(:old.unitofmeasure, 'x') != nvl(:new.unitofmeasure, 'x'))
    or  (nvl(:old.quantity, 0) != nvl(:new.quantity, 0))
    or  (nvl(:old.type, 'x') != nvl(:new.type, 'x'))
    or  (nvl(:old.fromlpid, 'x') != nvl(:new.fromlpid, 'x'))
    or  (nvl(:old.serialnumber, 'x') != nvl(:new.serialnumber, 'x'))
    or  (nvl(:old.lotnumber, '(none)') != nvl(:new.lotnumber, '(none)'))
    or  (nvl(:old.parentlpid, 'x') != nvl(:new.parentlpid, 'x'))
    or  (nvl(:old.useritem1, 'x') != nvl(:new.useritem1, 'x'))
    or  (nvl(:old.useritem2, 'x') != nvl(:new.useritem2, 'x'))
    or  (nvl(:old.useritem3, 'x') != nvl(:new.useritem3, 'x'))
    or  (nvl(:old.lastuser, 'x') != nvl(:new.lastuser, 'x'))
    or  (nvl(:old.invstatus, 'x') != nvl(:new.invstatus, 'x'))
    or  (nvl(:old.qtyentered, 0) != nvl(:new.qtyentered, 0))
    or  (nvl(:old.orderitem, 'x') != nvl(:new.orderitem, 'x'))
    or  (nvl(:old.uomentered, 'x') != nvl(:new.uomentered, 'x'))
    or  (nvl(:old.inventoryclass, 'x') != nvl(:new.inventoryclass, 'x'))
    or  (nvl(:old.loadno, 0) != nvl(:new.loadno, 0))
    or  (nvl(:old.stopno, 0) != nvl(:new.stopno, 0))
    or  (nvl(:old.shipno, 0) != nvl(:new.shipno, 0))
    or  (nvl(:old.orderid, 0) != nvl(:new.orderid, 0))
    or  (nvl(:old.shipid, 0) != nvl(:new.shipid, 0))
    or  (nvl(:old.weight, 0) != nvl(:new.weight, 0))
    or  (nvl(:old.ucc128, 'x') != nvl(:new.ucc128, 'x'))
    or  (nvl(:old.taskid, 0) != nvl(:new.taskid, 0))
    or  (nvl(:old.orderlot, '(none)') != nvl(:new.orderlot, '(none)'))
    or  (nvl(:old.pickuom, 'x') != nvl(:new.pickuom, 'x'))
    or  (nvl(:old.pickqty, 0) != nvl(:new.pickqty, 0))
    or  (nvl(:old.trackingno, 'x') != nvl(:new.trackingno, 'x'))
    or  (nvl(:old.cartonseq, 0) != nvl(:new.cartonseq, 0))
    or  (nvl(:old.totelpid, 'x') != nvl(:new.totelpid, 'x'))
    or  (nvl(:old.cartontype, 'x') != nvl(:new.cartontype, 'x'))
    or  (nvl(:old.pickedfromloc, 'x') != nvl(:new.pickedfromloc, 'x'))
    or  (nvl(:old.shippingcost, 0) != nvl(:new.shippingcost, 0))
    or  (nvl(:old.carriercodeused, 'x') != nvl(:new.carriercodeused, 'x'))
    or  (nvl(:old.satdeliveryused, 'x') != nvl(:new.satdeliveryused, 'x'))
    or  (nvl(:old.openfacility, 'x') != nvl(:new.openfacility, 'x'))
    or  (nvl(:old.manufacturedate, chgdate) != nvl(:new.manufacturedate, chgdate))
    or  (nvl(:old.length, 0) != nvl(:new.length, 0))
    or  (nvl(:old.width, 0) != nvl(:new.width, 0))
    or  (nvl(:old.height, 0) != nvl(:new.height, 0))
    or  (nvl(:old.pallet_weight, 0) != nvl(:new.pallet_weight, 0))
    or  (nvl(:old.expirationdate, chgdate) != nvl(:new.expirationdate, chgdate)))) then
      begin
         select upper(nvl(defaultvalue, 'Y')) into l_keep_history
            from systemdefaults
            where defaultid = 'ENABLE_SHIPPINGPLATEHISTORY';
      exception
         when OTHERS then
            l_keep_history := 'Y';
      end;
      if l_keep_history <> 'N' then
         insert into shippingplatehistory
            (lpid, whenoccurred, item, custid,
             facility, location, status, holdreason,
             unitofmeasure, quantity, type, fromlpid,
             serialnumber, lotnumber, parentlpid, useritem1,
             useritem2, useritem3, lastuser, lastupdate,
             invstatus, qtyentered, orderitem, uomentered,
             inventoryclass, loadno, stopno, shipno,
             orderid, shipid, weight, ucc128,
             taskid, orderlot, pickuom, pickqty,
             trackingno, cartonseq, totelpid, cartontype,
             pickedfromloc, shippingcost, carriercodeused, satdeliveryused,
             openfacility, manufacturedate, expirationdate,
             length, width, height, pallet_weight)
         values
            (:old.lpid, sysdate, :old.item, :old.custid,
             :old.facility, :old.location, :old.status, :old.holdreason,
             :old.unitofmeasure, :old.quantity, :old.type, :old.fromlpid,
             :old.serialnumber, :old.lotnumber, :old.parentlpid, :old.useritem1,
             :old.useritem2, :old.useritem3, :old.lastuser, :old.lastupdate,
             :old.invstatus, :old.qtyentered, :old.orderitem, :old.uomentered,
             :old.inventoryclass, :old.loadno, :old.stopno, :old.shipno,
             :old.orderid, :old.shipid, :old.weight, :old.ucc128,
             :old.taskid, :old.orderlot, :old.pickuom, :old.pickqty,
             :old.trackingno, :old.cartonseq, :old.totelpid, :old.cartontype,
             :old.pickedfromloc, :old.shippingcost, :old.carriercodeused, :old.satdeliveryused,
             :old.openfacility, :old.manufacturedate, :old.expirationdate,
             :old.length, :old.width, :old.height, :old.pallet_weight);
      end if;
   end if;

   if (deleting and (nvl(zci.default_value('ENABLE_SHIPPINGPLATEHISTORY'),'N') = 'Y')) then
         insert into shippingplatehistory
            (lpid, whenoccurred, item, custid,
             facility, location, status, holdreason,
             unitofmeasure, quantity, type, fromlpid,
             serialnumber, lotnumber, parentlpid, useritem1,
             useritem2, useritem3, lastuser, lastupdate,
             invstatus, qtyentered, orderitem, uomentered,
             inventoryclass, loadno, stopno, shipno,
             orderid, shipid, weight, ucc128,
             taskid, orderlot, pickuom, pickqty,
             trackingno, cartonseq, totelpid, cartontype,
             pickedfromloc, shippingcost, carriercodeused, satdeliveryused,
             openfacility, manufacturedate, expirationdate)
         values
            (:old.lpid, sysdate, :old.item, :old.custid,
             :old.facility, '(Delete)', :old.status, :old.holdreason,
             :old.unitofmeasure, :old.quantity, :old.type, :old.fromlpid,
             :old.serialnumber, :old.lotnumber, :old.parentlpid, :old.useritem1,
             :old.useritem2, :old.useritem3, 'ZETHCON', SYSDATE,
             :old.invstatus, :old.qtyentered, :old.orderitem, :old.uomentered,
             :old.inventoryclass, :old.loadno, :old.stopno, :old.shipno,
             :old.orderid, :old.shipid, :old.weight, :old.ucc128,
             :old.taskid, :old.orderlot, :old.pickuom, :old.pickqty,
             :old.trackingno, :old.cartonseq, :old.totelpid, :old.cartontype,
             :old.pickedfromloc, :old.shippingcost, :old.carriercodeused, :old.satdeliveryused,
             :old.openfacility, :old.manufacturedate, :old.expirationdate);
   end if;

   if (inserting and (nvl(:new.shippingcost,0) != 0)) then
      update orderhdr
         set shippingcost = nvl(shippingcost,0) + :new.shippingcost
         where orderid = :new.orderid
           and shipid = :new.shipid
           and shiptype = 'S';
   end if;

   if (deleting and (nvl(:old.shippingcost,0) != 0)) then
      update orderhdr
         set shippingcost = nvl(shippingcost,0) - least(nvl(shippingcost,0), :old.shippingcost)
         where orderid = :old.orderid
           and shipid = :old.shipid
           and shiptype = 'S';
   end if;

   if (updating
   and ((nvl(:old.orderid, 0) != nvl(:new.orderid, 0))
    or  (nvl(:old.shipid, 0) != nvl(:new.shipid, 0))
    or  (nvl(:old.shippingcost, 0) != nvl(:new.shippingcost, 0)))) then

      if (nvl(:old.shippingcost,0) != 0) then
         update orderhdr
            set shippingcost = nvl(shippingcost,0) - least(nvl(shippingcost,0), :old.shippingcost)
            where orderid = :old.orderid
              and shipid = :old.shipid
              and shiptype = 'S';
      end if;

      if (nvl(:new.shippingcost,0) != 0) then
         update orderhdr
            set shippingcost = nvl(shippingcost,0) + :new.shippingcost
            where orderid = :new.orderid
              and shipid = :new.shipid
              and shiptype = 'S';
      end if;
   end if;
end;
/
create or replace trigger shippingplate_biu
--
-- $Id$
--
before insert or update
on shippingplate
for each row

begin
  if (:new.status != 'SH') then
    :new.openfacility := :new.facility;
  else
    :new.openfacility := null;
  end if;
end;
/
show error trigger shippingplate_biu;
show error trigger shippingplate_aiud;
exit;
