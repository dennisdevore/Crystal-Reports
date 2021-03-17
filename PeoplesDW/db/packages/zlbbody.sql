create or replace package body alps.labor as
--
-- $Id$
--

FUNCTION staff_hours
(in_facility IN varchar2
,in_custid IN varchar2
,in_item IN varchar2
,in_category IN varchar2
,in_zoneid IN varchar2
,in_uom IN varchar2
,in_qty IN number
) return number is

cursor curLaborForUom is
  select decode(nvl(qtyperhour,0),0,12,qtyperhour) as qtyperhour
    from laborstandards
   where facility = in_facility
     and custid = in_custid
     and category = in_category
     and ( (nvl(zoneid,'x') = nvl(in_zoneid,'x')) or
           ( zoneid is null) )
     and uom = in_uom
   order by zoneid;

ls curLaborForUom%rowtype;

cursor curLaborDiffUom is
  select uom,
         qtyperhour
    from laborstandards
   where facility = in_facility
     and custid = in_custid
     and category = in_category
     and ( (nvl(zoneid,'x') = nvl(in_zoneid,'x')) or
           ( zoneid is null) )
   order by zoneid,uom;

cursor curFromUomSeq(in_fromuom varchar2) is
  select sequence
    from custitemuom
   where custid = in_custid
     and item = in_item
     and fromuom = in_fromuom;
fs curFromUomSeq%rowtype;

cursor curToUomSeq(in_touom varchar2) is
  select sequence
    from custitemuom
   where custid = in_custid
     and item = in_item
     and touom = in_touom;
ts curToUomSeq%rowtype;

cursor curUomEquivUp(in_fromseq number,in_toseq number) is
  select qty
    from custitemuom
   where custid = in_custid
     and item = in_item
     and sequence >= in_fromseq
     and sequence <= in_toseq
   order by sequence desc;

cursor curUomEquivDown(in_fromseq number,in_toseq number) is
  select qty
    from custitemuom
   where custid = in_custid
     and item = in_item
     and sequence <= in_fromseq
     and sequence >= in_toseq
   order by sequence;

cursor curDefaultQtyPerHour is
  select defaultvalue
    from systemdefaults
   where defaultid = 'LABORQTYPERHOUR';
dq curDefaultQtyPerHour%rowtype;

out_hours laborstandards.qtyperhour%type;
qtyPerHourDefault laborstandards.qtyperhour%type;
qtyPerHour laborstandards.qtyperhour%type;
out_msg appmsgs.msgtext%type;
qtyEquiv orderlabor.qty%type;

begin

qtyPerHourDefault := 12;
out_hours := 0;

open curDefaultQtyPerHour;
fetch curDefaultQtyPerHour into dq;
if curDefaultQtyPerHour%notfound then
  dq.defaultvalue := '12';
end if;
close curDefaultQtyPerHour;
begin
  qtyPerHourDefault := to_number(dq.defaultvalue);
exception when others then
  qtyPerHourDefault := 12;
end;
if qtyPerHourDefault <= 0 then
  qtyPerHourDefault := 12;
end if;

open curLaborForUom;
fetch curLaborForUom into ls;
if curLaborForUom%notfound then
  close curLaborForUom;
  open curToUomSeq(in_uom);
  fetch curToUomSeq into fs;
  if curToUomSeq%notfound then
    open curFromUomSeq(in_uom);
    fetch curFromUomSeq into fs;
    if curFromUomSeq%notfound then
      close curToUomSeq;
      close curFromUomSeq;
      out_hours := in_qty / qtyPerHourDefault;
      return out_hours;
    end if;
    close curFromUomSeq;
    fs.sequence := 0;
  end if;
  close curToUomSeq;
  qtyEquiv := 0;
  qtyperhour := qtyPerHourDefault;
  for lb in curLaborDiffUom
  loop
    open curFromUomSeq(lb.uom);
    fetch curFromUomSeq into ts;
    if curFromUomSeq%notfound then
      open curToUomSeq(lb.uom);
      fetch curToUomSeq into ts;
      if curToUomSeq%notfound then
        close curToUomSeq;
        close curFromUomSeq;
        goto continue_loop;
      end if;
      close curToUomSeq;
      ts.sequence := 999;
    end if;
    close curFromUomSeq;
    qtyEquiv := in_qty;
    if ts.sequence <= fs.sequence then
      for ue in curUomEquivUp(fs.sequence,ts.sequence)
      loop
        qtyEquiv := qtyEquiv * ue.qty;
      end loop;
    else
      for ue in curUomEquivDown(fs.sequence,ts.sequence)
      loop
        qtyEquiv := qtyEquiv / ue.qty;
      end loop;
    end if;
    qtyperhour := lb.qtyperhour;
    exit;
<<continue_loop>>
    null;
  end loop;
  if qtyEquiv != 0 then
    out_hours := qtyEquiv / qtyperhour;
  else
    out_hours := in_qty / qtyPerHourDefault;
  end if;
else
  if ls.qtyperhour <= 0 then
    ls.qtyperhour := qtyPerHourDefault;
  end if;
  out_hours := in_qty / ls.qtyperhour;
  close curLaborForUom;
end if;

return out_hours;

exception when others then
  out_hours := in_qty / qtyPerHourDefault;
  return out_hours;
end staff_hours;

/*
FUNCTION order_staffhours
(in_orderid IN number
,in_shipid IN number
) return number is

out_hours laborstandards.qtyperhour%type;

begin

out_hours := 0;

select nvl(sum(staffhours),0)
  into out_hours
  from orderlaborview
 where orderid = in_orderid
   and shipid = in_shipid;

return out_hours;

exception when others then
  return 0;
end order_staffhours;

FUNCTION line_staffhours
(in_orderid IN number
,in_shipid IN number
,in_item IN varchar2
,in_lotnumber IN varchar2
) return number is

out_hours laborstandards.qtyperhour%type;

begin

out_hours := 0;

select nvl(sum(staffhours),0)
  into out_hours
  from orderlaborview
 where orderid = in_orderid
   and shipid = in_shipid
   and item = in_item
   and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');

return out_hours;

exception when others then
  return 0;
end line_staffhours;
*/
PROCEDURE compute_line_labor
(in_orderid IN number
,in_shipid IN number
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_userid IN varchar2
,in_picktype IN varchar2
,in_facility IN varchar2
,in_delete IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor curOrderhdr is
  select custid,
         orderstatus,
         wave
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderhdr%rowtype;

cursor curOrderDtl is
  select qtyorder,
         invstatus,
         inventoryclass,
         linestatus
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');
od curOrderDtl%rowtype;

cursor curComm is
  select item as item,
         nvl(lotnumber,'(none)') as lotnumber,
         invstatus,
         inventoryclass,
         nvl(qty,0) as qty
    from commitments
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_item
     and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)')
   order by item, lotnumber;

cursor curSubTasks is
  select tasktype,
         pickingzone,
         pickuom,
         sum(nvl(pickqty,0)) as pickqty,
         sum(nvl(staffhrs,0)) as staffhrs
    from subtasks
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_item
     and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)')
   group by tasktype,pickingzone,pickuom
   union
  select tasktype,
         pickingzone,
         pickuom,
         sum(nvl(pickqty,0)) as pickqty,
         sum(nvl(staffhrs,0)) as staffhrs
    from batchtasks
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_item
     and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)')
   group by tasktype,pickingzone,pickuom;

cursor curBatchTasks is
  select pickingzone,
         pickuom,
         sum(nvl(pickqty,0)) as pickqty,
         sum(nvl(staffhrs,0)) as staffhrs
    from batchtasks
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_item
     and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)')
   group by pickingzone,pickuom;

cursor curItem(in_custid varchar2, in_item varchar2) is
  select baseuom
    from custitemview
   where custid = in_custid
     and item = in_item;
it curItem%rowtype;

cursor curItemFacility(in_custid varchar2, in_item varchar2) is
  select allocrule
    from custitemfacilityview
   where custid = in_custid
     and item = in_item
     and facility = in_facility;
itf curItemFacility%rowtype;

cursor curAllocRule(in_allocrule varchar2,
  in_invstatus varchar2, in_inventoryclass varchar2) is
  select uom,
         nvl(qtymin,0) as qtymin,
         nvl(qtymax,9999999) as qtymax,
         pickingzone,
         nvl(usefwdpick,'N') as usefwdpick,
         lifofifo,
         datetype,
         picktoclean
    from allocrulesdtl
   where facility = in_facility
     and allocrule = in_allocrule
     and ( (invstatus is null) or
           (invstatus = in_invstatus) )
     and ( (inventoryclass is null) or
            inventoryclass = nvl(in_inventoryclass,'RG') )
   order by priority;

base curAllocRule%rowtype;
qtyRemain orderdtl.qtyorder%type;
ol orderlabor%rowtype;
maxuom custitem.baseuom%type;
maxuomqty orderdtl.qtyorder%type;

begin

out_msg := '';

open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderhdr%notfound then
  close curOrderhdr;
  out_msg := 'Order ' || in_orderid || '-' || in_shipid ||
             ' not found for labor calculation';
  return;
end if;
close curOrderhdr;

open curOrderDtl;
fetch curOrderDtl into od;
if curOrderDtl%notfound then
  close curOrderDtl;
  out_msg := 'Order ' || in_orderid || '-' || in_shipid ||
             ' Line ' || in_item || '/' || in_lotnumber ||
             ' not found for labor calculation';
  return;
end if;
close curOrderDtl;

if in_delete = 'Y' then
  delete from orderlabor
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');
end if;

if od.linestatus = 'X' then
  out_msg := 'OKAY';
  return;
end if;

if oh.orderstatus = '1' then -- use an estimate
  open curItem(oh.custid,in_item);
  fetch curItem into it;
  if curItem%notfound then
    it.baseuom := 'EA';
  end if;
  close curItem;
  itf := null;
  open curItemFacility(oh.custid,in_item);
  fetch curItemFacility into itf;
  close curItemFacility;
  zit.max_uom(oh.custid,in_item,maxuom);
  maxuomqty := 0;
  qtyRemain := od.qtyorder;
  for ar in curAllocRule(itf.allocrule,od.invstatus,od.inventoryclass) loop
    zbut.translate_uom(oh.custid,in_item,ar.qtyMin,ar.uom,it.baseuom,
                       base.qtyMin,out_msg);
    if substr(out_msg,1,4) = 'OKAY' then
      if (maxuomqty = 0) and (ar.uom = maxuom) then
        maxuomqty := base.qtyMin;
      end if;
      if qtyRemain >= base.qtyMin then
        ol.qty := base.qtyMin * (floor(qtyRemain / base.qtyMin));
        qtyRemain := qtyRemain - ol.qty;
        zbut.translate_uom(oh.custid,in_item,ol.qty,
                            it.baseuom,ar.uom,ol.qty,out_msg);
        if substr(out_msg,1,4) = 'OKAY' then
          insert into orderlabor
          (wave,orderid,shipid,item,lotnumber,category,zoneid,
          uom,qty,lastuser,lastupdate,custid,staffhrs,facility)
          values
          (oh.wave,in_orderid,in_shipid,in_item,in_lotnumber,
          'PICK',ar.pickingzone,ar.uom,ol.qty,in_userid,sysdate,
          oh.custid,zlb.staff_hours(in_facility,oh.custid,
          in_item,'PICK',ar.pickingzone,ar.uom,ol.qty),
          in_facility);
          if (in_picktype = 'BAT') and (ar.uom != maxuom) then
            insert into orderlabor
            (wave,orderid,shipid,item,lotnumber,category,zoneid,
            uom,qty,lastuser,lastupdate,custid,staffhrs,facility)
            values
            (oh.wave,in_orderid,in_shipid,in_item,in_lotnumber,
            'SORT',ar.pickingzone,ar.uom,ol.qty,in_userid,sysdate,
            oh.custid,zlb.staff_hours(in_facility,oh.custid,
            in_item,'SORT',ar.pickingzone,ar.uom,ol.qty),
            in_facility);
          end if;
        end if;
      end if;
    end if;
    if qtyRemain = 0 then
      exit;
    end if;
  end loop;
/*
  if maxuomqty != 0 then
    ol.qty := floor(od.qtyorder / maxuomqty) + 1;
    insert into orderlabor
    (wave,orderid,shipid,item,lotnumber,category,zoneid,
    uom,qty,lastuser,lastupdate)
    values
    (oh.wave,in_orderid,in_shipid,in_item,in_lotnumber,
    'LOAD',null,maxuom,ol.qty,in_userid,sysdate);
  end if;
*/
elsif oh.orderstatus in ('2','3') then -- use committed qtys
  for cm in curComm loop
    open curItem(oh.custid,cm.item);
    fetch curItem into it;
    if curItem%notfound then
      it.baseuom := 'EA';
    end if;
    close curItem;
    itf := null;
    open curItemFacility(oh.custid,in_item);
    fetch curItemFacility into itf;
    close curItemFacility;
    qtyRemain := cm.qty;
    for ar in curAllocRule(itf.allocrule,cm.invstatus,cm.inventoryclass) loop
      zbut.translate_uom(oh.custid,cm.item,ar.qtyMin,
                          ar.uom,it.baseuom,base.qtyMin,out_msg);
      if substr(out_msg,1,4) = 'OKAY' then
        if qtyRemain >= base.qtyMin then
          ol.qty := base.qtyMin * (floor(qtyRemain / base.qtyMin));
          qtyRemain := qtyRemain - ol.qty;
          zbut.translate_uom(oh.custid,in_item,ol.qty,
                              it.baseuom,ar.uom,ol.qty,out_msg);
          if substr(out_msg,1,4) = 'OKAY' then
            insert into orderlabor
            (wave,orderid,shipid,item,lotnumber,category,zoneid,
            uom,qty,lastuser,lastupdate,custid,staffhrs,facility)
            values
            (oh.wave,in_orderid,in_shipid,in_item,in_lotnumber,
            'PICK',ar.pickingzone,ar.uom,ol.qty,in_userid,sysdate,
            oh.custid,zlb.staff_hours(in_facility,oh.custid,
            in_item,'PICK',ar.pickingzone,ar.uom,ol.qty),
            in_facility);
            if (in_picktype = 'BAT') and (ar.uom != maxuom) then
              insert into orderlabor
              (wave,orderid,shipid,item,lotnumber,category,zoneid,
              uom,qty,lastuser,lastupdate,custid,staffhrs,facility)
              values
              (oh.wave,in_orderid,in_shipid,in_item,in_lotnumber,
              'SORT',ar.pickingzone,ar.uom,ol.qty,in_userid,sysdate,
              oh.custid,zlb.staff_hours(in_facility,oh.custid,
              in_item,'SORT',ar.pickingzone,ar.uom,ol.qty),
              in_facility);
            end if;
          end if;
        end if;
      end if;
      if qtyRemain = 0 then
        exit;
      end if;
    end loop;
  end loop;
else -- use actuals
  for sb in curSubTasks loop
    insert into orderlabor
    (wave,orderid,shipid,item,lotnumber,category,zoneid,
    uom,qty,lastuser,lastupdate,custid,staffhrs,facility)
    values
    (oh.wave,in_orderid,in_shipid,in_item,in_lotnumber,
    sb.tasktype,sb.pickingzone,sb.pickuom,sb.pickqty,in_userid,sysdate,
    oh.custid,sb.staffhrs,in_facility);
  end loop;
  for sb in curBatchTasks loop
    insert into orderlabor
    (wave,orderid,shipid,item,lotnumber,category,zoneid,
    uom,qty,lastuser,lastupdate,custid,staffhrs,facility)
    values
    (oh.wave,in_orderid,in_shipid,in_item,in_lotnumber,
    'SORT',sb.pickingzone,sb.pickuom,sb.pickqty,in_userid,sysdate,
    oh.custid,sb.staffhrs,in_facility);
  end loop;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'zlbcll ' || sqlerrm;
end compute_line_labor;

PROCEDURE compute_order_labor
(in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor curOrderhdr is
  select orderstatus,
         custid,
         wave
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderhdr%rowtype;

cursor curWave is
  select picktype
    from waves
   where wave = oh.wave;
wv curWave%rowtype;

cursor curOrderDtl is
  select item,
         lotnumber
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X';

strMsg varchar2(255);

begin

out_errorno := 0;
out_msg := '';

open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderhdr%notfound then
  close curOrderhdr;
  out_msg := 'Order ' || in_orderid || '-' || in_shipid ||
             ' not found for labor calculation';
  out_errorno := 1;
  return;
end if;
close curOrderhdr;

if oh.wave != 0 then
  open curWave;
  fetch curWave into wv;
  if curWave%notfound then
    wv.picktype := 'BAT';
  end if;
  close curWave;
else
  wv.picktype := 'BAT';
end if;

delete from orderlabor
 where orderid = in_orderid
   and shipid = in_shipid;

for od in curOrderDtl
loop
  zlb.compute_line_labor(in_orderid,in_shipid,od.item,
    od.lotnumber,in_userid,wv.picktype,in_facility,'N',
    out_errorno, out_msg);
  if out_errorno != 0 then
    zms.log_msg('LABORCALC', in_facility, oh.custid,
      out_msg, 'E', in_userid, strMsg);
  end if;
end loop;

out_errorno := 0;
out_msg := 'OKAY';

exception when others then
  out_msg := 'zlbcol ' || sqlerrm;
end compute_order_labor;

FUNCTION formatted_staffhrs
(in_staffhrs IN number
) return varchar2 is

numRemain number(16,8);
numDays number(10);
numHours number(10);
numMinutes number(10);
numSeconds number(10);
out_StaffHrs varchar2(32);

begin

numRemain := in_staffhrs;
numDays := floor(numRemain / 24);
numRemain := numRemain - (numDays * 24);
numHours := floor(numRemain);
numRemain := (numRemain - numHours) * 3600;
numMinutes := floor(numRemain / 60);
numSeconds := floor(numRemain - (numMinutes * 60));

if numDays < 1 then
  out_Staffhrs := '    ';
elsif numDays < 10 then
  out_Staffhrs := '  ' || numDays || ':';
elsif numDays < 100 then
  out_Staffhrs := ' ' || numDays || ':';
else
  out_Staffhrs := numDays || ':';
end if;
if (numHours = 0) and (numDays < 1) then
  out_Staffhrs := out_staffhrs || '   ';
elsif numHours < 10 then
  out_Staffhrs := out_staffhrs || '0' || numHours || ':';
else
  out_StaffHrs := out_staffhrs || numHours || ':';
end if;
if numMinutes < 10 then
  out_Staffhrs := out_staffhrs || '0' || numMinutes || ':';
else
  out_StaffHrs := out_staffhrs || numMinutes || ':';
end if;
if numSeconds < 10 then
  out_Staffhrs := out_staffhrs || '0' || numSeconds;
else
  out_StaffHrs := out_staffhrs || numSeconds;
end if;

return out_staffhrs;

exception when others then
  return to_char(in_staffhrs);
end formatted_staffhrs;

end labor;

/
show error package body labor;
exit;
