create or replace PACKAGE BODY alps.backorder
IS
--
-- $Id$
--


-- Private procedures


procedure try_existing
   (in_orderid     in number,
    in_custid      in varchar2,
    in_item        in varchar2,
    in_lotnumber   in varchar2,
    in_qtyentered  in number,
    in_qtyorder    in number,
    in_weightorder in number,
    in_cubeorder   in number,
    in_amtorder    in number,
    in_userid      in varchar2,
    in_weight_entered_lbs number,
    in_weight_entered_kgs number,
    io_shipid      in out varchar2,
    io_errorno     in out number,
    io_msg         in out varchar2)
is
   cursor c_oh(p_orderid number) is
      select shipid
         from orderhdr
         where orderid = p_orderid
           and nvl(backorderyn,'N') = 'Y'
           and orderstatus = '0'
           and commitstatus = '0';
   oh c_oh%rowtype;
   cursor c_od(p_orderid number, p_shipid number, p_item varchar2, p_lot varchar2) is
      select rowid
         from orderdtl
         where orderid = p_orderid
           and shipid = p_shipid
           and item = p_item
           and nvl(lotnumber,'(none)') = nvl(p_lot,'(none)');
   od c_od%rowtype;
   cursor c_cus(p_custid varchar2) is
      select linenumbersyn
         from customer
         where custid = p_custid;
   cus c_cus%rowtype := null;
   cursor c_odl(p_orderid number, p_shipid number, p_item varchar2, p_lot varchar2) is
      select rowid
         from orderdtlline
         where orderid = p_orderid
           and shipid = p_shipid
           and item = p_item
           and nvl(lotnumber,'(none)') = nvl(p_lot,'(none)')
           and nvl(xdock,'N') = 'N'
         order by linenumber;

   l_found boolean;
begin
   io_msg := 'NONE';

   open c_oh(in_orderid);
   fetch c_oh into oh;
   l_found := c_oh%found;
   close c_oh;
   if not l_found then        -- no existing order to use
      return;
   end if;

   open c_od(in_orderid, oh.shipid, in_item, in_lotnumber);
   fetch c_od into od;
   l_found := c_od%found;
   close c_od;

   if l_found then            -- item detail already part of order
      update orderdtl
         set qtyentered = nvl(qtyentered,0) + nvl(in_qtyentered,0),
             weight_entered_lbs = nvl(weight_entered_lbs,0) + nvl(in_weight_entered_lbs,0),
             weight_entered_kgs = nvl(weight_entered_kgs,0) + nvl(in_weight_entered_kgs,0),
             qtyorder = nvl(qtyorder,0) + nvl(in_qtyorder,0),
             weightorder = nvl(weightorder,0) + nvl(in_weightorder,0),
             cubeorder = nvl(cubeorder,0) + nvl(in_cubeorder,0),
             amtorder = nvl(amtorder,0) + nvl(in_amtorder,0),
             lastuser = in_userid,
             lastupdate = sysdate
         where rowid = od.rowid;

      open c_cus(in_custid);
      fetch c_cus into cus;
      close c_cus;
      if cus.linenumbersyn = 'Y' then -- note weight_entered entries not allowed for pick by line numbers
         for odl in c_odl(in_orderid, oh.shipid, in_item, in_lotnumber) loop
            update orderdtlline
               set qty = nvl(qty,0) + nvl(in_qtyorder,0),
                   qtyentered = nvl(qtyentered,0) + nvl(in_qtyentered,0),
                   lastuser = in_userid,
                   lastupdate = sysdate
               where rowid = odl.rowid;
            exit;
         end loop;
      end if;

      io_msg := 'OKAY';
   else

      io_msg := 'DETAIL';
   end if;
   io_shipid := oh.shipid;

exception
   when OTHERS then
      io_errorno := sqlcode;
      io_msg := substr(sqlerrm, 1, 80);
end try_existing;


-- Public procedures


procedure create_back_order_item
(in_orderid varchar2
,in_shipid varchar2
,in_orderitem varchar2
,in_orderlot varchar2
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor curOrderDtl is
  select *
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)');
od curOrderDtl%rowtype;

cursor curOrderHdr is
  select *
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curOrderDtlLine(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select *
    from orderdtlline
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and nvl(xdock,'N') = 'N'
   order by linenumber;
ol curOrderDtlLine%rowtype;

cursor curCustomer(in_custid varchar2) is
  select linenumbersyn
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

qtyShip integer;
qtyLine integer;
qtyHazardous integer;
qtyHot integer;
lbsRemain number;

errmsg varchar2(255);

begin

out_errorno := 0;
out_msg := '';

od := null;
open curOrderDtl;
fetch curOrderDtl into od;
close curOrderDtl;
if od.orderid is null then
  out_errorno := -1;
  out_msg := 'Order Line not found: ' || in_orderid || ' ' ||
    in_shipid || ' ' || in_orderitem || ' ' || in_orderlot;
  return;
end if;

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.orderid is null then
  out_errorno := -2;
  out_msg := 'Order not found: ' || in_orderid || ' ' || in_shipid;
  return;
end if;

--get a new shipment id
begin
  select max(shipid)
    into oh.shipid
    from orderhdr
   where orderid = in_orderid;
exception when others then
  null;
end;
oh.shipid := oh.shipid + 1;
od.shipid := oh.shipid;
if nvl(od.qtyentered,0) != 0 then -- ordered by units
  if nvl(od.qtyship,0) != 0 then
    od.qtyorder := nvl(od.qtyorder,0) - nvl(od.qtyship,0);
    if od.qtyorder < 0 then
      od.qtyorder := 0;
    end if;
    od.weightorder := zci.item_weight(od.custid,od.item,od.uom) * od.qtyorder;
    od.cubeorder := zci.item_cube(od.custid,od.item,od.uom) * od.qtyorder;
    od.amtorder := zci.item_amt(od.custid,od.orderid,od.shipid,od.item,od.lotnumber) * od.qtyorder;
    od.uomentered := od.uom;
    od.qtyentered := od.qtyorder;
  end if;
  if nvl(od.qtyorder,0) = 0 then
    out_msg := 'OKAY--no back order required';
    return;
  end if;
else -- ordered by weight
  if nvl(od.weight_entered_kgs,0) != 0 then
    lbsRemain := zwt.from_kgs_to_lbs(od.custid,nvl(od.weight_entered_kgs,0));
  else
    lbsRemain := nvl(od.weight_entered_lbs,0);
  end if;
  if nvl(od.weightship,0) != 0 then
    lbsRemain := lbsRemain - od.weightship;
    if lbsRemain < 0 then
      lbsRemain := 0;
      od.qtyorder := 0;
    else
      od.qtyorder := zwt.calc_order_by_weight_qty(od.custid,od.item,od.uom,
                                                  lbsRemain,0,od.qtytype);
      if nvl(od.weight_entered_kgs,0) != 0 then
        od.weight_entered_kgs := zwt.from_lbs_to_kgs(od.custid,lbsRemain);
      else
        od.weight_entered_lbs := lbsRemain;
      end if;
      od.weightorder := zci.item_weight(od.custid,od.item,od.uom) * od.qtyorder;
      od.cubeorder := zci.item_cube(od.custid,od.item,od.uom) * od.qtyorder;
      od.amtorder := zci.item_amt(od.custid,od.orderid,od.shipid,od.item,od.lotnumber) * od.qtyorder;
      od.uomentered := od.uom;
    end if;
  end if;
  if od.qtyOrder = 0 then
    out_msg := 'OKAY--no back order required';
    return;
  end if;
end if;

try_existing(oh.orderid, od.custid, od.item, od.lotnumber, od.qtyentered, od.qtyorder,
      od.weightorder, od.cubeorder, od.amtorder, in_userid, od.weight_entered_lbs,
      od.weight_entered_kgs, oh.shipid, out_errorno, out_msg);
if (out_msg = 'OKAY') or (out_msg not in ('NONE','DETAIL')) then
   return;
end if;

if out_msg = 'NONE' then
   out_msg := '';
   qtyShip := nvl(od.qtyship,0);

   zcl.clone_orderhdr(in_orderid, in_shipid, oh.orderid, oh.shipid,
                   null,in_userid,errmsg);

   update  orderhdr
      set  orderstatus = '0',
           commitstatus = '0',
           loadno = null,
           stopno = null,
           shipno = null,
           qtyorder = 0,
           weightorder = 0,
           cubeorder = 0,
           amtorder = 0,
           qtycommit = null,
           weightcommit = null,
           cubecommit = null,
           amtcommit = null,
           qtyship = null,
           weightship = null,
           cubeship = null,
           amtship = null,
           qtytotcommit = null,
           weighttotcommit = null,
           cubetotcommit = null,
           amttotcommit = null,
           qtyrcvd = null,
           weightrcvd = null,
           cubercvd = null,
           amtrcvd = null,
           statusupdate = sysdate,
           lastupdate = sysdate,
           wave = null,
           qtypick = null,
           weightpick = null,
           cubepick = null,
           amtpick = null,
           staffhrs = null,
           qty2sort = null,
           weight2sort = null,
           cube2sort = null,
           amt2sort = null,
           qty2pack = null,
           weight2pack = null,
           cube2pack = null,
           amt2pack = null,
           qty2check = null,
           weight2check = null,
           cube2check = null,
           amt2check = null,
           confirmed = null,
           rejectcode = null,
           rejecttext = null,
           dateshipped = null,
           origorderid = null,
           origshipid = null,
           bulkretorderid = null,
           bulkretshipid = null,
           returntrackingno = null,
           packlistshipdate = null,
           edicancelpending = null,
           backorderyn = 'Y',
           tms_status = decode(nvl(oh.tms_status,'X'),'X','X','1'),
           tms_status_update = sysdate,
           tms_shipment_id = null,
           tms_release_id = null,
           shippingcost = null
    where orderid = oh.orderid
      and shipid = oh.shipid;

   if substr(zci.hazardous_item_on_order(oh.orderid,oh.shipid),1,1) = 'Y' then
      qtyHazardous := 1;
   else
      qtyHazardous := 0;
   end if;
   if oh.priority = '0' then
      qtyHot := 1;
   else
      qtyHot := 0;
   end if;
   /*
   update waves
      set cntorder = nvl(cntorder,0) + 1,
          qtyorder = nvl(qtyorder,0) + nvl(oh.qtyorder,0),
          weightorder = nvl(weightorder,0) + nvl(oh.weightorder,0),
          cubeorder = nvl(cubeorder,0) + nvl(oh.cubeorder,0),
          qtycommit = nvl(qtycommit,0) + nvl(oh.qtycommit,0),
          weightcommit = nvl(weightcommit,0) + nvl(oh.weightcommit,0),
          cubecommit = nvl(cubecommit,0) + nvl(oh.cubecommit,0),
          staffhrs = nvl(staffhrs,0) + nvl(oh.staffhrs,0),
          qtyHazardousOrders = nvl(qtyHazardousOrders,0) + qtyHazardous,
          qtyHotOrders = nvl(qtyHotOrders,0) + qtyHot
      where wave = oh.wave;
	 */
else
   out_msg := '';
   od.shipid := oh.shipid;
end if;

zcl.clone_orderdtl(in_orderid, in_shipid, in_orderitem, in_orderlot,
                   od.orderid, od.shipid, in_orderitem, in_orderlot,
                   null, in_userid, errmsg);


update  orderdtl
   set  linestatus = 'A',
        commitstatus = null,
        qtyentered = od.qtyentered,
        uomentered = od.uomentered,
        qtyorder = od.qtyorder,
        weightorder = od.weightorder,
        cubeorder = od.cubeorder,
        amtorder = od.amtorder,
        qtycommit = null,
        weightcommit = null,
        cubecommit = null,
        amtcommit = null,
        qtyship = null,
        weightship = null,
        cubeship = null,
        amtship = null,
        qtytotcommit = null,
        weighttotcommit = null,
        cubetotcommit = null,
        amttotcommit = null,
        qtyrcvd = null,
        weightrcvd = null,
        cubercvd = null,
        amtrcvd = null,
        qtyrcvdgood = null,
        weightrcvdgood = null,
        cubercvdgood = null,
        amtrcvdgood = null,
        qtyrcvddmgd = null,
        weightrcvddmgd = null,
        cubercvddmgd = null,
        amtrcvddmgd = null,
        qtypick = null,
        weightpick = null,
        cubepick = null,
        amtpick = null,
        childorderid = null,
        childshipid = null,
        staffhrs = null,
        qty2sort = null,
        weight2sort = null,
        cube2sort = null,
        amt2sort = null,
        qty2pack = null,
        weight2pack = null,
        cube2pack = null,
        amt2pack = null,
        qty2check = null,
        weight2check = null,
        cube2check = null,
        amt2check = null,
        asnvariance = null,
        weight_entered_lbs = od.weight_entered_lbs,
        weight_entered_kgs = od.weight_entered_kgs
 where orderid = oh.orderid
   and shipid = oh.shipid
   and item = in_orderitem
   and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)');


cu := null;
open curCustomer(oh.custid);
fetch curCustomer into cu;
close curCustomer;
if cu.linenumbersyn = 'Y' then
  for ol in curOrderDtlLine(in_orderid,in_shipid,in_orderitem,in_orderlot)
  loop
    if qtyShip > ol.qty then
      qtyLine := 0;
      qtyShip := qtyShip - ol.qty;
    else
      update orderdtlline
         set qty = qtyShip
       where orderid = in_orderid
         and shipid = in_shipid
         and item = in_orderitem
         and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)')
         and linenumber = ol.linenumber;
      qtyLine := ol.qty - qtyShip;
      qtyShip := 0;
    end if;

    if qtyLine = 0 then
      goto continue_line_loop;
    end if;

    zcl.clone_table_row('ORDERDTLLINE',
        'ORDERID = '|| in_orderid ||' and SHIPID = '||in_shipid
            ||' and ITEM = '''||in_orderitem||''''
            ||' and nvl(LOTNUMBER,''(none)'') = '''
                ||nvl(in_orderlot,'(none)')||''''
            ||' and LINENUMBER = '|| ol.linenumber,
        oh.orderid||','||oh.shipid||','''||ol.item
            ||''','''||ol.lotnumber||''','||ol.linenumber||','||qtyLine,
        'ORDERID,SHIPID,ITEM,LOTNUMBER,LINENUMBER,QTY',
        null, in_userid, errmsg);

    if errmsg != 'OKAY' then
        zut.prt('ODL failed :'||errmsg);

    end if;

  << continue_line_loop >>
    null;
  end loop;

  delete orderdtlline
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and qty = 0;

end if;

out_errorno := 0;
out_msg := 'OKAY';

exception when others then
  out_errorno := sqlcode;
  out_msg := 'zboboi ' || sqlerrm;
end create_back_order_item;

end backorder;
/
show error package body backorder;
exit;
