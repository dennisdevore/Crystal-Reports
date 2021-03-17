create or replace trigger orderdtl_biud
--
-- $Id$
--
before insert or update or delete
on orderdtl
for each row
declare
chgdate date;
nulldate date;
l_bolcomment varchar2(400);
l_ordtype orderhdr.ordertype%type;
l_shiptype orderhdr.shiptype%type;
l_type varchar2(10);
l_hazardous custitem.hazardous%type;
cursor curBOLComment(in_custid varchar2, in_item varchar2, in_type varchar2) is
  select bolcomment1
    from custitemchembolview
   where custid = in_custid
     and item = in_item
     and type = in_type;

cursor curCustomer(in_custid varchar2) is
  select decode(nvl(reduceorderqtybycancel,'D'),'D',nvl(zci.default_value('REDUCEORDERQTYBYCANCEL'),'N'),'Y','Y','N') reduceorderqtybycancel
    from customer cu, customer_aux ca
   where cu.custid = in_custid
     and ca.custid = cu.custid;
cu curCustomer%rowtype;

oh_msg varchar2(2000);
v_new_multiplier number;
v_old_multiplier number;

procedure add_msg(in_msg IN OUT varchar2, in_fn IN varchar2,
          in_old IN varchar2, in_new IN varchar2)
is
  cont varchar2(2);
begin
    if in_msg is null then
       cont := ' ';
       in_msg := 'Change order detail fields:';
    else
        cont := ', ';
    end if;

    if nvl(length(in_msg),0) + nvl(length(in_old),0) + nvl(length(in_new),0) + 50 > 2000 then
       if substr(in_msg, -3) != '...' then
          in_msg := in_msg || ' ...';
       end if;
       return;
    end if;
    in_msg := in_msg||cont||in_fn
           ||'=['||
           nvl(in_old,'(null)')||
           ']->['||
           nvl(in_new,'(null)')||']';
end;

begin
  chgdate := sysdate;
  nulldate := to_date('01012000','mmddyyyy');
  
  open curCustomer(:new.custid);
  fetch curCustomer into cu;
  close curCustomer;

  if (inserting) then
    begin
      select custid, fromfacility, priority, ordertype, shiptype
        into :new.custid, :new.fromfacility, :new.priority,
             l_ordtype, l_shiptype
        from orderhdr
       where orderid = :new.orderid
         and shipid = :new.shipid;
    exception when others then
      null;
    end;
    if l_ordtype not in ('R','Q','C','I') then
       begin
          select nvl(hazardous,'N') into l_hazardous
             from custitem
             where custid = :new.custid
               and item = :new.item;
       exception when others then
         l_hazardous := 'N';
       end;
       if l_hazardous = 'Y' then
         if l_shiptype = 'A' then
            l_type := 'IATA';
         elsif l_shiptype = 'C' then
            l_type := 'IMO';
         else
            l_type := 'DOT';
         end if;
         l_bolcomment := null;
         OPEN curBOLComment(:new.custid, :new.item, l_type);
         FETCH curBOLComment into l_bolcomment;
         CLOSE curBOLComment;
         if l_bolcomment is not null then
            begin
               insert into orderdtlbolcomments
               (orderid,shipid,item,lotnumber,bolcomment,lastuser,lastupdate)
               values
               (:new.orderid,:new.shipid,:new.item,rtrim(:new.lotnumber),
               rtrim(l_bolcomment),
               :new.lastuser,sysdate);
            exception when dup_val_on_index then
              update orderdtlbolcomments
                 set bolcomment = rtrim(l_bolcomment),
                     lastuser = :new.lastuser,
                     lastupdate = sysdate
               where orderid = :new.orderid
                 and shipid = :new.shipid
                 and item = :new.item
                 and nvl(lotnumber,'(none)') = nvl(rtrim(:new.lotnumber),'(none)');
            end;
         end if;
       end if;
     end if;

    insert into orderhistory
      (chgdate, orderid, shipid, item, lot, userid, action, msg)
    values
      (chgdate, :new.orderid, :new.shipid, :new.item, :new.lotnumber,
           :new.lastuser,
           'ADD DTL', 'Add Order Detail. Qty:'||:new.qtyorder
           ||decode(nvl(:new.qtyorderdiff,0),0,'',' * Order Active *'));

  

  end if;
  if (deleting) or
     ((updating) and
      ( (:old.orderid <> :new.orderid) or
        (:old.shipid  <> :new.shipid ) )) then
    
    update orderhdr
       set qtyorder = case when (cu.reduceorderqtybycancel = 'N' or :old.linestatus <> 'X') then nvl(qtyorder,0) - nvl(:old.qtyorder,0) else qtyorder end,
           weightorder = case when (cu.reduceorderqtybycancel = 'N' or :old.linestatus <> 'X') then nvl(weightorder,0) - nvl(:old.weightorder,0) else weightorder end,
           cubeorder = case when (cu.reduceorderqtybycancel = 'N' or :old.linestatus <> 'X') then nvl(cubeorder,0) - nvl(:old.cubeorder,0) else cubeorder end,
           amtorder = case when (cu.reduceorderqtybycancel = 'N' or :old.linestatus <> 'X') then nvl(amtorder,0) - nvl(:old.amtorder,0) else amtorder end,
           qtycommit = nvl(qtycommit,0) - nvl(:old.qtycommit,0),
           weightcommit = nvl(weightcommit,0) - nvl(:old.weightcommit,0),
           cubecommit = nvl(cubecommit,0) - nvl(:old.cubecommit,0),
           amtcommit = nvl(amtcommit,0) - nvl(:old.amtcommit,0),
           qtyship = nvl(qtyship,0) - nvl(:old.qtyship,0),
           weightship = nvl(weightship,0) - nvl(:old.weightship,0),
           cubeship = nvl(cubeship,0) - nvl(:old.cubeship,0),
           amtship = nvl(amtship,0) - nvl(:old.amtship,0),
           qtytotcommit = nvl(qtytotcommit,0) - nvl(:old.qtytotcommit,0),
           weighttotcommit = nvl(weighttotcommit,0) - nvl(:old.weighttotcommit,0),
           cubetotcommit = nvl(cubetotcommit,0) - nvl(:old.cubetotcommit,0),
           amttotcommit = nvl(amttotcommit,0) - nvl(:old.amttotcommit,0),
           qtyrcvd = nvl(qtyrcvd,0) - nvl(:old.qtyrcvd,0),
           weightrcvd = nvl(weightrcvd,0) - nvl(:old.weightrcvd,0),
           cubercvd = nvl(cubercvd,0) - nvl(:old.cubercvd,0),
           amtrcvd = nvl(amtrcvd,0) - nvl(:old.amtrcvd,0),
           qty2sort = nvl(qty2sort,0) - nvl(:old.qty2sort,0),
           weight2sort = nvl(weight2sort,0) - nvl(:old.weight2sort,0),
           cube2sort = nvl(cube2sort,0) - nvl(:old.cube2sort,0),
           amt2sort = nvl(amt2sort,0) - nvl(:old.amt2sort,0),
           qty2pack = nvl(qty2pack,0) - nvl(:old.qty2pack,0),
           weight2pack = nvl(weight2pack,0) - nvl(:old.weight2pack,0),
           cube2pack = nvl(cube2pack,0) - nvl(:old.cube2pack,0),
           amt2pack = nvl(amt2pack,0) - nvl(:old.amt2pack,0),
           qty2check = nvl(qty2check,0) - nvl(:old.qty2check,0),
           weight2check = nvl(weight2check,0) - nvl(:old.weight2check,0),
           cube2check = nvl(cube2check,0) - nvl(:old.cube2check,0),
           amt2check = nvl(amt2check,0) - nvl(:old.amt2check,0),
           qtypick = nvl(qtypick,0) - nvl(:old.qtypick,0),
           weightpick = nvl(weightpick,0) - nvl(:old.weightpick,0),
           cubepick = nvl(cubepick,0) - nvl(:old.cubepick,0),
           amtpick = nvl(amtpick,0) - nvl(:old.amtpick,0),
           staffhrs = nvl(staffhrs,0) - nvl(:old.staffhrs,0),
           weight_entered_lbs = nvl(weight_entered_lbs,0) - nvl(:old.weight_entered_lbs,0),
           weight_entered_kgs = nvl(weight_entered_kgs,0) - nvl(:old.weight_entered_kgs,0)
     where orderid = :old.orderid
       and shipid = :old.shipid;
  end if;
  if (inserting) or
     ((updating) and      ( (:old.orderid <> :new.orderid) or
        (:old.shipid  <> :new.shipid ) )) then
   
    update orderhdr
       set qtyorder = case when (cu.reduceorderqtybycancel = 'N' or :new.linestatus <> 'X') then nvl(qtyorder,0) + nvl(:new.qtyorder,0) else qtyorder end,
           weightorder = case when (cu.reduceorderqtybycancel = 'N' or :new.linestatus <> 'X') then nvl(weightorder,0) + nvl(:new.weightorder,0) else weightorder end,
           cubeorder = case when (cu.reduceorderqtybycancel = 'N' or :new.linestatus <> 'X') then nvl(cubeorder,0) + nvl(:new.cubeorder,0) else cubeorder end,
           amtorder = case when (cu.reduceorderqtybycancel = 'N' or :new.linestatus <> 'X') then nvl(amtorder,0) + nvl(:new.amtorder,0) else amtorder end,
           qtycommit = nvl(qtycommit,0) + nvl(:new.qtycommit,0),
           weightcommit = nvl(weightcommit,0) + nvl(:new.weightcommit,0),
           cubecommit = nvl(cubecommit,0) + nvl(:new.cubecommit,0),
           amtcommit = nvl(amtcommit,0) + nvl(:new.amtcommit,0),
           qtyship = nvl(qtyship,0) + nvl(:new.qtyship,0),
           weightship = nvl(weightship,0) + nvl(:new.weightship,0),
           cubeship = nvl(cubeship,0) + nvl(:new.cubeship,0),
           amtship = nvl(amtship,0) + nvl(:new.amtship,0),
           qtytotcommit = nvl(qtytotcommit,0) + nvl(:new.qtytotcommit,0),
           weighttotcommit = nvl(weighttotcommit,0) + nvl(:new.weighttotcommit,0),
           cubetotcommit = nvl(cubetotcommit,0) + nvl(:new.cubetotcommit,0),
           amttotcommit = nvl(amttotcommit,0) + nvl(:new.amttotcommit,0),
           qtyrcvd = nvl(qtyrcvd,0) + nvl(:new.qtyrcvd,0),
           weightrcvd = nvl(weightrcvd,0) + nvl(:new.weightrcvd,0),
           cubercvd = nvl(cubercvd,0) + nvl(:new.cubercvd,0),
           amtrcvd = nvl(amtrcvd,0) + nvl(:new.amtrcvd,0),
           qty2sort = nvl(qty2sort,0) + nvl(:new.qty2sort,0),
           weight2sort = nvl(weight2sort,0) + nvl(:new.weight2sort,0),
           cube2sort = nvl(cube2sort,0) + nvl(:new.cube2sort,0),
           amt2sort = nvl(amt2sort,0) + nvl(:new.amt2sort,0),
           qty2pack = nvl(qty2pack,0) + nvl(:new.qty2pack,0),
           weight2pack = nvl(weight2pack,0) + nvl(:new.weight2pack,0),
           cube2pack = nvl(cube2pack,0) + nvl(:new.cube2pack,0),
           amt2pack = nvl(amt2pack,0) + nvl(:new.amt2pack,0),
           qty2check = nvl(qty2check,0) + nvl(:new.qty2check,0),
           weight2check = nvl(weight2check,0) + nvl(:new.weight2check,0),
           cube2check = nvl(cube2check,0) + nvl(:new.cube2check,0),
           amt2check = nvl(amt2check,0) + nvl(:new.amt2check,0),
           qtypick = nvl(qtypick,0) + nvl(:new.qtypick,0),
           weightpick = nvl(weightpick,0) + nvl(:new.weightpick,0),
           cubepick = nvl(cubepick,0) + nvl(:new.cubepick,0),
           amtpick = nvl(amtpick,0) + nvl(:new.amtpick,0),
           staffhrs = nvl(staffhrs,0) + nvl(:new.staffhrs,0),
           weight_entered_lbs = nvl(weight_entered_lbs,0) + nvl(:new.weight_entered_lbs,0),
           weight_entered_kgs = nvl(weight_entered_kgs,0) + nvl(:new.weight_entered_kgs,0)
     where orderid = :new.orderid
       and shipid = :new.shipid;
  end if;
  if (updating('qtyorder') or updating('weightorder') or updating('cubeorder') or
      updating('amtorder') or updating('qtycommit') or updating('weightcommit') or
      updating('cubecommit') or updating('amtcommit') or updating('qtyship') or
      updating('weightship') or updating('cubeship') or updating('amtship') or
      updating('qtytotcommit') or updating('weighttotcommit') or updating('cubetotcommit') or
      updating('amttotcommit') or updating('qtyrcvd') or updating('weightrcvd') or
      updating('cubercvd') or updating('amtrcvd') or updating('qtypick') or
      updating('weightpick') or updating('cubepick') or updating('amtpick') or
      updating('qty2sort') or updating('weight2sort') or updating('cube2sort') or
      updating('amt2sort') or updating('qty2pack') or updating('weight2pack') or
      updating('cube2pack') or updating('amt2pack') or updating('qty2check') or
      updating('weight2check') or updating('cube2check') or updating('amt2check') or
      updating('staffhrs') or updating('weight_entered_lbs') or updating('weight_entered_kgs') or updating('linestatus')) and
      (:old.orderid = :new.orderid) and
      (:old.shipid = :new.shipid) then
     
    if (cu.reduceorderqtybycancel = 'Y' and updating('linestatus') and :new.linestatus = 'X' and nvl(:old.linestatus,'Z') <> nvl(:new.linestatus,'Z')) then
      v_new_multiplier := 0;
      v_old_multiplier := 1;
    elsif (cu.reduceorderqtybycancel = 'Y' and updating('linestatus') and :new.linestatus <> 'X' and nvl(:old.linestatus,'Z') <> nvl(:new.linestatus,'Z')) then
      v_new_multiplier := 1;
      v_old_multiplier := 0;
    elsif (cu.reduceorderqtybycancel = 'Y' and :new.linestatus = 'X') then
      v_new_multiplier := 0;
      v_old_multiplier := 0;
    else
      v_new_multiplier := 1;
      v_old_multiplier := 1;
    end if; 
    
    update orderhdr
       set qtyorder = nvl(qtyorder,0) + (nvl(:new.qtyorder,0) * v_new_multiplier) - (nvl(:old.qtyorder,0) * v_old_multiplier),
           weightorder = nvl(weightorder,0) + (nvl(:new.weightorder,0) * v_new_multiplier) -  (nvl(:old.weightorder,0) * v_old_multiplier),
           cubeorder = nvl(cubeorder,0) + (nvl(:new.cubeorder,0) * v_new_multiplier) - (nvl(:old.cubeorder,0) * v_old_multiplier),
           amtorder = nvl(amtorder,0) + (nvl(:new.amtorder,0) * v_new_multiplier) - (nvl(:old.amtorder,0) * v_old_multiplier),
           qtycommit = nvl(qtycommit,0) + nvl(:new.qtycommit,0) - nvl(:old.qtycommit,0),
           weightcommit = nvl(weightcommit,0) + nvl(:new.weightcommit,0) - nvl(:old.weightcommit,0),
           cubecommit = nvl(cubecommit,0) + nvl(:new.cubecommit,0) - nvl(:old.cubecommit,0),
           amtcommit = nvl(amtcommit,0) + nvl(:new.amtcommit,0) - nvl(:old.amtcommit,0),
           qtyship = nvl(qtyship,0) + nvl(:new.qtyship,0) - nvl(:old.qtyship,0),
           weightship = nvl(weightship,0) + nvl(:new.weightship,0) - nvl(:old.weightship,0),
           cubeship = nvl(cubeship,0) + nvl(:new.cubeship,0) - nvl(:old.cubeship,0),
           amtship = nvl(amtship,0) + nvl(:new.amtship,0) - nvl(:old.amtship,0),
           qtytotcommit = nvl(qtytotcommit,0) + nvl(:new.qtytotcommit,0) - nvl(:old.qtytotcommit,0),
           weighttotcommit = nvl(weighttotcommit,0) + nvl(:new.weighttotcommit,0) - nvl(:old.weighttotcommit,0),
           cubetotcommit = nvl(cubetotcommit,0) + nvl(:new.cubetotcommit,0) - nvl(:old.cubetotcommit,0),
           amttotcommit = nvl(amttotcommit,0) + nvl(:new.amttotcommit,0) - nvl(:old.amttotcommit,0),
           qtyrcvd = nvl(qtyrcvd,0) + nvl(:new.qtyrcvd,0) - nvl(:old.qtyrcvd,0),
           weightrcvd = nvl(weightrcvd,0) + nvl(:new.weightrcvd,0) - nvl(:old.weightrcvd,0),
           cubercvd = nvl(cubercvd,0) + nvl(:new.cubercvd,0) - nvl(:old.cubercvd,0),
           amtrcvd = nvl(amtrcvd,0) + nvl(:new.amtrcvd,0) - nvl(:old.amtrcvd,0),
           qty2sort = nvl(qty2sort,0) + nvl(:new.qty2sort,0) - nvl(:old.qty2sort,0),
           weight2sort = nvl(weight2sort,0) + nvl(:new.weight2sort,0) - nvl(:old.weight2sort,0),
           cube2sort = nvl(cube2sort,0) + nvl(:new.cube2sort,0) - nvl(:old.cube2sort,0),
           amt2sort = nvl(amt2sort,0) + nvl(:new.amt2sort,0) - nvl(:old.amt2sort,0),
           qty2pack = nvl(qty2pack,0) + nvl(:new.qty2pack,0) - nvl(:old.qty2pack,0),
           weight2pack = nvl(weight2pack,0) + nvl(:new.weight2pack,0) - nvl(:old.weight2pack,0),
           cube2pack = nvl(cube2pack,0) + nvl(:new.cube2pack,0) - nvl(:old.cube2pack,0),
           amt2pack = nvl(amt2pack,0) + nvl(:new.amt2pack,0) - nvl(:old.amt2pack,0),
           qty2check = nvl(qty2check,0) + nvl(:new.qty2check,0) - nvl(:old.qty2check,0),
           weight2check = nvl(weight2check,0) + nvl(:new.weight2check,0) - nvl(:old.weight2check,0),
           cube2check = nvl(cube2check,0) + nvl(:new.cube2check,0) - nvl(:old.cube2check,0),
           amt2check = nvl(amt2check,0) + nvl(:new.amt2check,0) - nvl(:old.amt2check,0),
           qtypick = nvl(qtypick,0) + nvl(:new.qtypick,0) - nvl(:old.qtypick,0),
           weightpick = nvl(weightpick,0) + nvl(:new.weightpick,0) - nvl(:old.weightpick,0),
           cubepick = nvl(cubepick,0) + nvl(:new.cubepick,0) - nvl(:old.cubepick,0),
           amtpick = nvl(amtpick,0) + nvl(:new.amtpick,0) - nvl(:old.amtpick,0),
           staffhrs = nvl(staffhrs,0) + nvl(:new.staffhrs,0) - nvl(:old.staffhrs,0),
           weight_entered_lbs = nvl(weight_entered_lbs,0) + nvl(:new.weight_entered_lbs,0) -  nvl(:old.weight_entered_lbs,0),
           weight_entered_kgs = nvl(weight_entered_kgs,0) + nvl(:new.weight_entered_kgs,0) -  nvl(:old.weight_entered_kgs,0)
     where orderid = :new.orderid
       and shipid = :new.shipid;
  end if;
  
  if (updating) then
    :new.statususer := case when updating('linestatus') then :new.lastuser else :new.statususer end;
    :new.statusupdate := case when updating('linestatus') then sysdate else :new.statusupdate end;
  end if;

  if (deleting) then

    insert into orderhistory
      (chgdate, orderid, shipid, item, lot, userid, action, msg)
    values
      (chgdate, :old.orderid, :old.shipid, :old.item, :old.lotnumber,
           :old.lastuser,
           'DELETE DTL', 'Delete Order Detail. Qty:'||:old.qtyorder);

  end if;

  if (updating) then

     if :old.qtyorder <> :new.qtyorder and
        :new.lastuser <> 'IMPORDER' then
       oh_msg := 'Quantity ';
       if :new.qtyorder < :old.qtyorder then
         oh_msg := oh_msg || 'decrease';
       else
         oh_msg := oh_msg || 'increase';
       end if;
       oh_msg := oh_msg || ' from ' || :old.qtyorder || ' to ' || :new.qtyorder ||
                           ' ('  || (:new.qtyorder - :old.qtyorder) || ')';
       insert into orderhistory
         (chgdate, orderid, shipid, item, lot, userid, action, msg)
       values
         (chgdate, :new.orderid, :new.shipid, :new.item, :new.lotnumber,
              :new.lastuser,
              'Quantity Change',
              oh_msg);
     end if;

     oh_msg := null;

     if (nvl(:old.orderid,0) <> nvl(:new.orderid,0))
     then
           add_msg(oh_msg,'orderid',
               :old.orderid,
               :new.orderid);
     end if;

     if (nvl(:old.shipid,0) <> nvl(:new.shipid,0))
     then
           add_msg(oh_msg,'shipid',
               :old.shipid,
               :new.shipid);
     end if;

     if (nvl(:old.item,'x') <> nvl(:new.item,'x'))
     then
           add_msg(oh_msg,'item',
               :old.item,
               :new.item);
     end if;

     if (nvl(:old.custid,'x') <> nvl(:new.custid,'x'))
     then
           add_msg(oh_msg,'custid',
               :old.custid,
               :new.custid);
     end if;

     if (nvl(:old.uom,'x') <> nvl(:new.uom,'x'))
     then
           add_msg(oh_msg,'uom',
               :old.uom,
               :new.uom);
     end if;

     if (nvl(:old.linestatus,'x') <> nvl(:new.linestatus,'x'))
     then
           add_msg(oh_msg,'linestatus',
               :old.linestatus,
               :new.linestatus);
     end if;

     if (nvl(:old.qtyentered,0) <> nvl(:new.qtyentered,0))
     then
           add_msg(oh_msg,'qtyentered',
               :old.qtyentered,
               :new.qtyentered);
     end if;

     if (nvl(:old.itementered,'x') <> nvl(:new.itementered,'x'))
     then
           add_msg(oh_msg,'itementered',
               :old.itementered,
               :new.itementered);
     end if;

     if (nvl(:old.uomentered,'x') <> nvl(:new.uomentered,'x'))
     then
           add_msg(oh_msg,'uomentered',
               :old.uomentered,
               :new.uomentered);
     end if;

     if (nvl(:old.weight_entered_lbs,0) <> nvl(:new.weight_entered_lbs,0))
     then
           add_msg(oh_msg,'weight_entered_lbs',
               :old.weight_entered_lbs,
               :new.weight_entered_lbs);
     end if;

     if (nvl(:old.weight_entered_kgs,0) <> nvl(:new.weight_entered_kgs,0))
     then
           add_msg(oh_msg,'weight_entered_kgs',
               :old.weight_entered_kgs,
               :new.weight_entered_kgs);
     end if;

     if (nvl(:old.lotnumber,'x') <> nvl(:new.lotnumber,'x'))
     then
           add_msg(oh_msg,'lotnumber',
               :old.lotnumber,
               :new.lotnumber);
     end if;


     if (nvl(:old.dtlpassthruchar01,'x') <> nvl(:new.dtlpassthruchar01,'x'))
     then
           add_msg(oh_msg,'dtlpassthruchar01',
               :old.dtlpassthruchar01,
               :new.dtlpassthruchar01);
     end if;

     if (nvl(:old.dtlpassthruchar02,'x') <> nvl(:new.dtlpassthruchar02,'x'))
     then
           add_msg(oh_msg,'dtlpassthruchar02',
               :old.dtlpassthruchar02,
               :new.dtlpassthruchar02);
     end if;

     if (nvl(:old.dtlpassthruchar03,'x') <> nvl(:new.dtlpassthruchar03,'x'))
     then
           add_msg(oh_msg,'dtlpassthruchar03',
               :old.dtlpassthruchar03,
               :new.dtlpassthruchar03);
     end if;

     if (nvl(:old.dtlpassthruchar04,'x') <> nvl(:new.dtlpassthruchar04,'x'))
     then
           add_msg(oh_msg,'dtlpassthruchar04',
               :old.dtlpassthruchar04,
               :new.dtlpassthruchar04);
     end if;

     if (nvl(:old.dtlpassthruchar05,'x') <> nvl(:new.dtlpassthruchar05,'x'))
     then
           add_msg(oh_msg,'dtlpassthruchar05',
               :old.dtlpassthruchar05,
               :new.dtlpassthruchar05);
     end if;

     if (nvl(:old.dtlpassthruchar06,'x') <> nvl(:new.dtlpassthruchar06,'x'))
     then
           add_msg(oh_msg,'dtlpassthruchar06',
               :old.dtlpassthruchar06,
               :new.dtlpassthruchar06);
     end if;

     if (nvl(:old.dtlpassthruchar07,'x') <> nvl(:new.dtlpassthruchar07,'x'))
     then
           add_msg(oh_msg,'dtlpassthruchar07',
               :old.dtlpassthruchar07,
               :new.dtlpassthruchar07);
     end if;

     if (nvl(:old.dtlpassthruchar08,'x') <> nvl(:new.dtlpassthruchar08,'x'))
     then
           add_msg(oh_msg,'dtlpassthruchar08',
               :old.dtlpassthruchar08,
               :new.dtlpassthruchar08);
     end if;

     if (nvl(:old.dtlpassthruchar09,'x') <> nvl(:new.dtlpassthruchar09,'x'))
     then
           add_msg(oh_msg,'dtlpassthruchar09',
               :old.dtlpassthruchar09,
               :new.dtlpassthruchar09);
     end if;

     if (nvl(:old.dtlpassthruchar10,'x') <> nvl(:new.dtlpassthruchar10,'x'))
     then
           add_msg(oh_msg,'dtlpassthruchar10',
               :old.dtlpassthruchar10,
               :new.dtlpassthruchar10);
     end if;

     if (nvl(:old.dtlpassthruchar11,'x') <> nvl(:new.dtlpassthruchar11,'x'))
     then
           add_msg(oh_msg,'dtlpassthruchar11',
               :old.dtlpassthruchar11,
               :new.dtlpassthruchar11);
     end if;

     if (nvl(:old.dtlpassthruchar12,'x') <> nvl(:new.dtlpassthruchar12,'x'))
     then
           add_msg(oh_msg,'dtlpassthruchar12',
               :old.dtlpassthruchar12,
               :new.dtlpassthruchar12);
     end if;

     if (nvl(:old.dtlpassthruchar13,'x') <> nvl(:new.dtlpassthruchar13,'x'))
     then
           add_msg(oh_msg,'dtlpassthruchar13',
               :old.dtlpassthruchar13,
               :new.dtlpassthruchar13);
     end if;

     if (nvl(:old.dtlpassthruchar14,'x') <> nvl(:new.dtlpassthruchar14,'x'))
     then
           add_msg(oh_msg,'dtlpassthruchar14',
               :old.dtlpassthruchar14,
               :new.dtlpassthruchar14);
     end if;

     if (nvl(:old.dtlpassthruchar15,'x') <> nvl(:new.dtlpassthruchar15,'x'))
     then
           add_msg(oh_msg,'dtlpassthruchar15',
               :old.dtlpassthruchar15,
               :new.dtlpassthruchar15);
     end if;

     if (nvl(:old.dtlpassthruchar16,'x') <> nvl(:new.dtlpassthruchar16,'x'))
     then
           add_msg(oh_msg,'dtlpassthruchar16',
               :old.dtlpassthruchar16,
               :new.dtlpassthruchar16);
     end if;

     if (nvl(:old.dtlpassthruchar17,'x') <> nvl(:new.dtlpassthruchar17,'x'))
     then
           add_msg(oh_msg,'dtlpassthruchar17',
               :old.dtlpassthruchar17,
               :new.dtlpassthruchar17);
     end if;

     if (nvl(:old.dtlpassthruchar18,'x') <> nvl(:new.dtlpassthruchar18,'x'))
     then
           add_msg(oh_msg,'dtlpassthruchar18',
               :old.dtlpassthruchar18,
               :new.dtlpassthruchar18);
     end if;

     if (nvl(:old.dtlpassthruchar19,'x') <> nvl(:new.dtlpassthruchar19,'x'))
     then
           add_msg(oh_msg,'dtlpassthruchar19',
               :old.dtlpassthruchar19,
               :new.dtlpassthruchar19);
     end if;

     if (nvl(:old.dtlpassthruchar20,'x') <> nvl(:new.dtlpassthruchar20,'x'))
     then
           add_msg(oh_msg,'dtlpassthruchar20',
               :old.dtlpassthruchar20,
               :new.dtlpassthruchar20);
     end if;


     if (nvl(:old.dtlpassthrunum01,0) <> nvl(:new.dtlpassthrunum01,0))
     then
           add_msg(oh_msg,'dtlpassthrunum01',
               :old.dtlpassthrunum01,
               :new.dtlpassthrunum01);
     end if;

     if (nvl(:old.dtlpassthrunum02,0) <> nvl(:new.dtlpassthrunum02,0))
     then
           add_msg(oh_msg,'dtlpassthrunum02',
               :old.dtlpassthrunum02,
               :new.dtlpassthrunum02);
     end if;

     if (nvl(:old.dtlpassthrunum03,0) <> nvl(:new.dtlpassthrunum03,0))
     then
           add_msg(oh_msg,'dtlpassthrunum03',
               :old.dtlpassthrunum03,
               :new.dtlpassthrunum03);
     end if;

     if (nvl(:old.dtlpassthrunum04,0) <> nvl(:new.dtlpassthrunum04,0))
     then
           add_msg(oh_msg,'dtlpassthrunum04',
               :old.dtlpassthrunum04,
               :new.dtlpassthrunum04);
     end if;

     if (nvl(:old.dtlpassthrunum05,0) <> nvl(:new.dtlpassthrunum05,0))
     then
           add_msg(oh_msg,'dtlpassthrunum05',
               :old.dtlpassthrunum05,
               :new.dtlpassthrunum05);
     end if;

     if (nvl(:old.dtlpassthrunum06,0) <> nvl(:new.dtlpassthrunum06,0))
     then
           add_msg(oh_msg,'dtlpassthrunum06',
               :old.dtlpassthrunum06,
               :new.dtlpassthrunum06);
     end if;

     if (nvl(:old.dtlpassthrunum07,0) <> nvl(:new.dtlpassthrunum07,0))
     then
           add_msg(oh_msg,'dtlpassthrunum07',
               :old.dtlpassthrunum07,
               :new.dtlpassthrunum07);
     end if;

     if (nvl(:old.dtlpassthrunum08,0) <> nvl(:new.dtlpassthrunum08,0))
     then
           add_msg(oh_msg,'dtlpassthrunum08',
               :old.dtlpassthrunum08,
               :new.dtlpassthrunum08);
     end if;

     if (nvl(:old.dtlpassthrunum09,0) <> nvl(:new.dtlpassthrunum09,0))
     then
           add_msg(oh_msg,'dtlpassthrunum09',
               :old.dtlpassthrunum09,
               :new.dtlpassthrunum09);
     end if;

     if (nvl(:old.dtlpassthrunum10,0) <> nvl(:new.dtlpassthrunum10,0))
     then
           add_msg(oh_msg,'dtlpassthrunum10',
               :old.dtlpassthrunum10,
               :new.dtlpassthrunum10);
     end if;

     if (nvl(:old.dtlpassthrudate01,nulldate) <> nvl(:new.dtlpassthrudate01,nulldate))
     then
           add_msg(oh_msg,'dtlpassthrudate01',
                   to_char(:old.dtlpassthrudate01, 'MM-DD-YY HH:MI:SSAM'),
                   to_char(:new.dtlpassthrudate01, 'MM-DD-YY HH:MI:SSAM'));
     end if;

     if (nvl(:old.dtlpassthrudate02,nulldate) <> nvl(:new.dtlpassthrudate02,nulldate))
     then
           add_msg(oh_msg,'dtlpassthrudate02',
                   to_char(:old.dtlpassthrudate02, 'MM-DD-YY HH:MI:SSAM'),
                   to_char(:new.dtlpassthrudate02, 'MM-DD-YY HH:MI:SSAM'));
     end if;

     if (nvl(:old.dtlpassthrudate03,nulldate) <> nvl(:new.dtlpassthrudate03,nulldate))
     then
           add_msg(oh_msg,'dtlpassthrudate03',
                   to_char(:old.dtlpassthrudate03, 'MM-DD-YY HH:MI:SSAM'),
                   to_char(:new.dtlpassthrudate03, 'MM-DD-YY HH:MI:SSAM'));
     end if;

     if (nvl(:old.dtlpassthrudate04,nulldate) <> nvl(:new.dtlpassthrudate04,nulldate))
     then
           add_msg(oh_msg,'dtlpassthrudate04',
                   to_char(:old.dtlpassthrudate04, 'MM-DD-YY HH:MI:SSAM'),
                   to_char(:new.dtlpassthrudate04, 'MM-DD-YY HH:MI:SSAM'));
     end if;

     if (nvl(:old.dtlpassthrudoll01,0) <> nvl(:new.dtlpassthrudoll01,0))
     then
           add_msg(oh_msg,'dtlpassthrudoll01',
               :old.dtlpassthrudoll01,
               :new.dtlpassthrudoll01);
     end if;

     if (nvl(:old.dtlpassthrudoll02,0) <> nvl(:new.dtlpassthrudoll02,0))
     then
           add_msg(oh_msg,'dtlpassthrudoll02',
               :old.dtlpassthrudoll02,
               :new.dtlpassthrudoll02);
     end if;

     if (nvl(:old.variancepct,0) <> nvl(:new.variancepct,0))
     then
           add_msg(oh_msg,'variancepct',
               :old.variancepct,
               :new.variancepct);
     end if;

     if (nvl(:old.weightorder,0) <> nvl(:new.weightorder,0))
     then
           add_msg(oh_msg,'weightorder',
               :old.weightorder,
               :new.weightorder);
     end if;

     if ((nvl(:old.qtyship,0) <> nvl(:new.qtyship,0)) and
         (nvl(:new.qtyship,0) > nvl(:new.qtyorder,0)))
     then
           add_msg(oh_msg,'qtyorder',
               :old.qtyorder,
               :new.qtyorder);
     end if;

     if (nvl(:old.min_days_to_expiration,0) <> nvl(:new.min_days_to_expiration,0))
     then
           add_msg(oh_msg,'min_days_to_expiration',
               :old.min_days_to_expiration,
               :new.min_days_to_expiration);
     end if;

    if oh_msg is not null then
       insert into orderhistory
         (chgdate, orderid, shipid, item, lot, userid, action, msg)
       values
         (chgdate, :new.orderid, :new.shipid, :new.item, :new.lotnumber,
              :new.lastuser,
              'CHANGE DTL',
              oh_msg||decode(nvl(:new.qtyorderdiff,0),0,'',' * Order Active *'));
    end if;



  end if;
end;
/
create or replace trigger orderdtl_bi
before insert
on orderdtl
for each row
declare
function getDetailCount(in_orderid IN number, in_shipid IN number)
return number
is
  dtlCount number;
pragma AUTONOMOUS_TRANSACTION;
begin
    select count(1)
      into dtlCount
      from orderdtl
     where orderid = in_orderid
       and shipid = in_shipid;
    return dtlCount;
end;
begin
    if :new.lineorder is null then
      :new.lineorder := getDetailCount(:new.orderid, :new.shipid) + 1;
    end if;

    if :new.min_days_to_expiration is null then
      :new.min_days_to_expiration :=
        zoe.get_min_days_to_expiration(:new.orderid, :new.shipid, :new.item);
    end if;
end;
/
show error trigger orderdtl_biud;
show error trigger orderdtl_bi;
exit;



