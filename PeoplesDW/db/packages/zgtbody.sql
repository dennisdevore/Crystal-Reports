create or replace package body alps.gentasks as
--
-- $Id$
--

procedure move_request
(in_facility          in varchar2
,in_lpid              in varchar2
,in_taskpriority      in varchar2
,in_destloc           in varchar2
,in_userid            in varchar2
,out_errorno          in out number
,out_msg              in out varchar2
,in_type              in varchar2 := 'MV'
)
is

cursor curPlate is
  select facility,
         location,
         item,
         quantity,
         custid,
         type,
         unitofmeasure,
         status,
         weight,
         parentlpid
    from plate
   where lpid = in_lpid;
lp curPlate%rowtype;

cursor curLocation(in_facility varchar2,in_locid varchar2) is
  select section,
         equipprof,
         pickingzone,
         nvl(pickingseq,0) as pickingseq,
         loctype
    from location
   where facility = in_facility
     and locid = in_locid;

fromloc curLocation%rowtype;
toloc curLocation%rowtype;
tk tasks%rowtype;
cntRows integer;
begin

out_errorno := -999;
out_msg := '';

open curPlate;
fetch curPlate into lp;
if curPlate%notfound then
  close curPlate;
  out_errorno := -1;
  out_msg := 'LiP ' || in_lpid || ' not found';
  return;
end if;
close curPlate;

if lp.status != 'A' then
  out_errorno := -2;
  out_msg := 'LiP ' || in_lpid || ' invalid status: '  || lp.status;
  return;
end if;

if lp.type not in ('MP','PA') then
  out_errorno := -3;
  out_msg := 'LiP ' || in_lpid || ' invalid type: '  || lp.type;
  return;
end if;

if lp.facility != in_facility then
  out_errorno := -4;
  out_msg := 'LiP ' || in_lpid || ' not at your facility: '  || lp.facility;
  return;
end if;

if (lp.type = 'PA') and (lp.parentlpid is not null) then
  out_errorno := -22;
  out_msg := 'LiP ' || in_lpid || ' has a parent (' || lp.parentlpid || ')';
  return;
end if;

open curLocation(lp.facility,in_destloc);
fetch curLocation into toloc;
if curLocation%notfound then
  close curLocation;
  out_errorno := -5;
  out_msg := 'LiP ' || in_lpid || ' invalid destination location: '  || in_destloc;
  return;
end if;
close curLocation;
if toloc.loctype = 'DOR' then
  out_errorno := -6;
  out_msg := 'LiP ' || in_lpid || ' invalid ''to location'' type: '  || toloc.loctype;
  return;
end if;

open curLocation(lp.facility,lp.location);
fetch curLocation into fromloc;
close curLocation;
if fromloc.loctype = 'DOR' then
  out_errorno := -7;
  out_msg := 'LiP ' || in_lpid || ' invalid ''from location'' type: '  || fromloc.loctype;
  return;
end if;

cntRows := 0;
select count(1)
  into cntRows
  from subtasks
 where lpid = in_lpid;
if cntRows != 0 then
  out_errorno := -8;
  out_msg := 'LiP ' || in_lpid || ' already has associated tasks';
  return;
end if;

ztsk.get_next_taskid(tk.taskid,out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  out_errorno := -9;
  out_msg := 'LiP ' || in_lpid || ' cannot assign taskid: '  || out_msg;
  return;
end if;

tk.tasktype := in_type;
tk.picktotype := null;
tk.cartontype := null;
insert into tasks
  (taskid, tasktype, facility, fromsection, fromloc,
   fromprofile,tosection,toloc,toprofile,touserid,
   custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
   orderid,shipid,orderitem,orderlot,priority,
   prevpriority,curruserid,lastuser,lastupdate,
   pickuom, pickqty, picktotype, wave,
   pickingzone, cartontype, weight, cube, staffhrs)
  values
  (tk.taskid, tk.tasktype, lp.facility, fromloc.section,lp.location,
   fromloc.equipprof,toloc.section,in_destloc,
   toloc.equipprof,null,lp.custid,lp.item,in_lpid,
   lp.unitofmeasure,lp.quantity,fromloc.pickingseq,null,null,
   null,null,null,null,null,
   in_taskpriority,in_taskpriority,null,in_userid,sysdate,
   lp.unitofmeasure,lp.quantity,tk.picktotype,null,
   fromloc.pickingzone,tk.cartontype,
   lp.weight,
   zci.item_cube(lp.custid,lp.item,lp.unitofmeasure) * lp.quantity,
   zlb.staff_hours(in_facility,lp.custid,lp.item,tk.tasktype,
   fromloc.pickingzone,lp.unitofmeasure,lp.quantity));
insert into subtasks
  (taskid, tasktype, facility, fromsection, fromloc,
   fromprofile,tosection,toloc,toprofile,touserid,
   custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
   orderid,shipid,orderitem,orderlot,priority,
   prevpriority,curruserid,lastuser,lastupdate,
   pickuom, pickqty, picktotype, wave,
   pickingzone, cartontype, weight, cube, staffhrs, cartonseq,
   shippinglpid, shippingtype, cartongroup)
  values
  (tk.taskid,tk.tasktype,lp.facility,fromloc.section,lp.location,
   fromloc.equipprof,toloc.section,in_destloc,
   toloc.equipprof,null,lp.custid,lp.item,in_lpid,
   lp.unitofmeasure,lp.quantity,fromloc.pickingseq,null,null,
   null,null,null,null,null,
   in_taskpriority,in_taskpriority,null,in_userid,sysdate,
   lp.unitofmeasure,lp.quantity,tk.picktotype,null,
   fromloc.pickingzone,tk.cartontype,
   lp.weight,
   zci.item_cube(lp.custid,lp.item,lp.unitofmeasure) * lp.quantity,
   zlb.staff_hours(in_facility,lp.custid,lp.item,tk.tasktype,
   fromloc.pickingzone,lp.unitofmeasure,lp.quantity),1,
   null, 'F',
   zwv.cartontype_group(tk.cartontype));

out_errorno := 0;
out_msg := 'OKAY';

exception when OTHERS then
  out_msg := 'zgtmr ' || substr(sqlerrm, 1, 80);
  out_errorno := sqlcode;
end move_request;

procedure pick_by_lip_request
(in_facility          in varchar2
,in_lpid              in varchar2
,in_taskpriority      in varchar2
,in_stageloc          in varchar2
,in_orderid           in number
,in_shipid            in number
,in_userid            in varchar2
,out_errorno          in out number
,out_msg              in out varchar2)
is

cursor curPlate is
  select facility,
         location,
         item,
         quantity,
         custid,
         type,
         unitofmeasure,
         status,
         parentlpid,
         childfacility,
         lotnumber
    from plate
   where lpid = in_lpid;
lp curPlate%rowtype;

cursor curCustItem(in_custid varchar2,in_item varchar2) is
  select lotrequired
    from custitemview
   where custid = in_custid
     and item = in_item;

cursor curLocation(in_facility varchar2,in_locid varchar2) is
  select section,
         equipprof,
         pickingzone,
         nvl(pickingseq,0) as pickingseq,
         loctype
    from location
   where facility = in_facility
     and locid = in_locid;

cursor curOrderHdr is
  select ordertype,
         orderstatus,
         stageloc,
         custid,
         priority,
         loadno,
         stopno,
         shipno,
         fromfacility,
         componenttemplate
    from orderhdrview
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

curLips integer;
cmdSql varchar2(2000);
llotrequired custitem.lotrequired%type;
fromloc curLocation%rowtype;
toloc curLocation%rowtype;
tk tasks%rowtype;
sp shippingplate%rowtype;
pl plate%rowtype;
cntRows integer;

begin

out_errorno := -999;
out_msg := '';

open curPlate;
fetch curPlate into lp;
if curPlate%notfound then
  close curPlate;
  out_errorno := -1;
  out_msg := 'LiP ' || in_lpid || ' not found';
  return;
end if;
close curPlate;

if lp.status != 'A' then
  out_errorno := -2;
  out_msg := 'LiP ' || in_lpid || ' invalid status: '  || lp.status;
  return;
end if;

if lp.type not in ('MP','PA') then
  out_errorno := -3;
  out_msg := 'LiP ' || in_lpid || ' invalid type: '  || lp.type;
  return;
end if;

if lp.facility != in_facility then
  out_errorno := -4;
  out_msg := 'LiP ' || in_lpid || ' not at your facility: '  || lp.facility;
  return;
end if;

if (lp.type = 'PA') and (lp.parentlpid is not null) then
  out_errorno := -22;
  out_msg := 'LiP ' || in_lpid || ' has a parent (' || lp.parentlpid || ')';
  return;
end if;

open curLocation(lp.facility,lp.location);
fetch curLocation into fromloc;
close curLocation;
if fromloc.loctype = 'DOR' then
  out_errorno := -7;
  out_msg := 'LiP ' || in_lpid || ' invalid ''from location'' type: '  || fromloc.loctype;
  return;
end if;

cntRows := 0;
select count(1)
  into cntRows
  from subtasks
 where lpid = in_lpid;
if cntRows != 0 then
  out_errorno := -8;
  out_msg := 'LiP ' || in_lpid || ' already has associated tasks';
  return;
end if;

-- Cannot pick any plate if the following exists:
-- for type 'U' order, the receiving(inbound) order must be complete with a status of 'R'
-- for type 'T', since the same order is shipped(outbound) and then received(inbound), 
--   that order must also be complete with a status of 'R'
cntRows := 0; 
select count(1)
  into cntRows
  from shippingplate sp, orderhdr oh
 where oh.orderid = sp.orderid
   and oh.shipid = sp.shipid
   and sp.fromlpid = in_lpid
   and (exists(select orderid 
          from orderhdr
         where orderid = nvl(oh.ownerxferorderid,0)
           and shipid = nvl(oh.ownerxfershipid,0)
           and ordertype = 'U' 
           and orderstatus != 'R') or
       (oh.orderstatus != 'R' and oh.ordertype = 'T'));              

if cntRows != 0 then
  out_errorno := -11;
  out_msg := 'LiP ' || in_lpid || ' already picked on another Transfer order';
  return;
end if;

open curOrderHdr;
fetch curOrderHdr into oh;
if curOrderHdr%notfound then
  close curOrderHdr;
  out_errorno := -9;
  out_msg := 'LiP ' || in_lpid || ' order not found: ' ||
    in_orderid || '-' || in_shipid;
  return;
end if;
close curOrderHdr;

if oh.orderstatus > '8' then
  out_errorno := -50;
  out_msg := 'LiP ' || in_lpid || ' invalid order status: ' || oh.orderstatus;
  return;
end if;

if (oh.ordertype not in ('V','T','U')) and
   (oh.ordertype != 'O' or oh.componenttemplate is null) then
  out_errorno := -10;
  out_msg := 'LiP ' || in_lpid || ' invalid order type: ' || oh.ordertype;
  return;
end if;

if (oh.ordertype = 'T') and
   (oh.fromfacility != in_facility) then
  out_errorno := -51;
  out_msg := 'LiP ' || in_lpid || ' not an outbound transfer';
  return;
end if;

if rtrim(in_stageloc) is not null then
  oh.stageloc := rtrim(in_stageloc);
end if;


if (oh.ordertype != 'O' or oh.componenttemplate is null or oh.stageloc is not null) then
  open curLocation(lp.facility,oh.stageloc);
  fetch curLocation into toloc;
  if curLocation%notfound then
    close curLocation;
    out_errorno := -5;
    out_msg := 'LiP ' || in_lpid || ' invalid destination location: '  || oh.stageloc;
    return;
  end if;
  close curLocation;
  if toloc.loctype != 'STG' then
    out_errorno := -6;
    out_msg := 'LiP ' || in_lpid || ' invalid ''to location'' type: '  || toloc.loctype;
    return;
  end if;
end if;

if lp.custid != oh.custid then
  out_errorno := -30;
  out_msg := 'LiP/Order Customer mismatch: ' || lp.custid || '/' || oh.custid;
  return;
end if;

llotrequired := null;
if oh.ordertype = 'U' then
  open curCustItem(lp.custid,lp.item);
  fetch curCustItem into llotrequired;
  close curCustItem;
end if;

ztsk.get_next_taskid(tk.taskid,out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  out_errorno := -20;
  out_msg := 'LiP ' || in_lpid || ' cannot assign taskid: '  || out_msg;
  return;
end if;

tk.tasktype := 'PK';
tk.picktotype := 'FULL';
tk.cartontype := null;
insert into tasks
  (taskid, tasktype, facility, fromsection, fromloc,
   fromprofile,tosection,toloc,toprofile,touserid,
   custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
   orderid,shipid,orderitem,orderlot,priority,
   prevpriority,curruserid,lastuser,lastupdate,
   pickuom, pickqty, picktotype, wave,
   pickingzone, cartontype, weight, cube, staffhrs)
  values
  (tk.taskid, tk.tasktype, lp.facility, fromloc.section,lp.location,
   fromloc.equipprof,toloc.section,oh.stageloc,
   toloc.equipprof,null,lp.custid,lp.item,in_lpid,
   lp.unitofmeasure,lp.quantity,fromloc.pickingseq,oh.loadno,oh.stopno,
   oh.shipno,in_orderid,in_shipid,lp.item,
   decode(llotrequired,'O',lp.lotnumber,'P',lp.lotnumber,null),
   in_taskpriority,in_taskpriority,null,in_userid,sysdate,
   lp.unitofmeasure,lp.quantity,tk.picktotype,null,
   fromloc.pickingzone,tk.cartontype,
   zcwt.lp_item_weight(in_lpid,lp.custid,lp.item,lp.unitofmeasure) * lp.quantity,
   zci.item_cube(lp.custid,lp.item,lp.unitofmeasure) * lp.quantity,
   zlb.staff_hours(in_facility,lp.custid,lp.item,tk.tasktype,
   fromloc.pickingzone,lp.unitofmeasure,lp.quantity));

if oh.ordertype in ('V','O') then
  insert into subtasks
    (taskid, tasktype, facility, fromsection, fromloc,
     fromprofile,tosection,toloc,toprofile,touserid,
     custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
     orderid,shipid,orderitem,orderlot,priority,
     prevpriority,curruserid,lastuser,lastupdate,
     pickuom, pickqty, picktotype, wave,
     pickingzone, cartontype, weight, cube, staffhrs, cartonseq,
     shippinglpid, shippingtype, cartongroup)
    values
    (tk.taskid,tk.tasktype,lp.facility,fromloc.section,lp.location,
     fromloc.equipprof,toloc.section,oh.stageloc,
     toloc.equipprof,null,lp.custid,lp.item,in_lpid,
     lp.unitofmeasure,lp.quantity,fromloc.pickingseq,oh.loadno,oh.stopno,
     oh.shipno,in_orderid,in_shipid,lp.item,
     decode(llotrequired,'O',lp.lotnumber,'P',lp.lotnumber,null),
     in_taskpriority,in_taskpriority,null,in_userid,sysdate,
     lp.unitofmeasure,lp.quantity,tk.picktotype,null,
     fromloc.pickingzone,tk.cartontype,
     zcwt.lp_item_weight(in_lpid,lp.custid,lp.item,lp.unitofmeasure) * lp.quantity,
     zci.item_cube(lp.custid,lp.item,lp.unitofmeasure) * lp.quantity,
     zlb.staff_hours(in_facility,lp.custid,lp.item,tk.tasktype,
     fromloc.pickingzone,lp.unitofmeasure,lp.quantity),1,
     null, 'F', zwv.cartontype_group(tk.cartontype));
end if;

if (lp.parentlpid is null) or
   ( (lp.parentlpid is not null) and
     (lp.childfacility is not null) ) then
  update plate
     set qtytasked = nvl(qtytasked,0) + lp.quantity
   where lpid = in_lpid;
else
  update plate
     set qtytasked = nvl(qtytasked,0) + lp.quantity
   where lpid = lp.parentlpid;
end if;

begin
cmdSql := 'select inventoryclass, invstatus, lotnumber, ' ||
 ' quantity, item, unitofmeasure, location, holdreason, lpid, ' ||
 ' serialnumber, useritem1, useritem2, useritem3, manufacturedate, expirationdate ' ||
 ' from plate ' ||
 'where type = ''PA'' and ';
if lp.type = 'MP' then
 cmdSql := cmdSql || 'parent';
end if;
cmdSql := cmdSql || 'lpid = ''' || in_lpid || '''';
cmdSql := cmdsql || ' order by lpid';
curLips := dbms_sql.open_cursor;
dbms_sql.parse(curLips, cmdsql, dbms_sql.native);
dbms_sql.define_column(curLips,1,pl.inventoryclass,2);
dbms_sql.define_column(curLips,2,pl.invstatus,2);
dbms_sql.define_column(curLips,3,pl.lotnumber,30);
dbms_sql.define_column(curLips,4,pl.quantity);
dbms_sql.define_column(curLips,5,pl.item,20);
dbms_sql.define_column(curLips,6,pl.unitofmeasure,4);
dbms_sql.define_column(curLips,7,pl.location,10);
dbms_sql.define_column(curLips,8,pl.holdreason,2);
dbms_sql.define_column(curLips,9,pl.lpid,15);
dbms_sql.define_column(curLips,10,pl.serialnumber,30);
dbms_sql.define_column(curLips,11,pl.useritem1,20);
dbms_sql.define_column(curLips,12,pl.useritem2,20);
dbms_sql.define_column(curLips,13,pl.useritem3,20);
dbms_sql.define_column(curLips,14,pl.manufacturedate);
dbms_sql.define_column(curLips,15,pl.expirationdate);
cntRows := dbms_sql.execute(curLips);
while (1=1)
loop
  cntRows := dbms_sql.fetch_rows(curLips);
  if cntRows <= 0 then
    exit;
  end if;
  dbms_sql.column_value(curLips,1,pl.inventoryclass);
  dbms_sql.column_value(curLips,2,pl.invstatus);
  dbms_sql.column_value(curLips,3,pl.lotnumber);
  dbms_sql.column_value(curLips,4,pl.quantity);
  dbms_sql.column_value(curLips,5,pl.item);
  dbms_sql.column_value(curLips,6,pl.unitofmeasure);
  dbms_sql.column_value(curLips,7,pl.location);
  dbms_sql.column_value(curLips,8,pl.holdreason);
  dbms_sql.column_value(curLips,9,pl.lpid);
  dbms_sql.column_value(curLips,10,pl.serialnumber);
  dbms_sql.column_value(curLips,11,pl.useritem1);
  dbms_sql.column_value(curLips,12,pl.useritem2);
  dbms_sql.column_value(curLips,13,pl.useritem3);
  dbms_sql.column_value(curLips,14,pl.manufacturedate);
  dbms_sql.column_value(curLips,15,pl.expirationdate);
  if oh.ordertype in ('V','T','U') then
    begin
      insert into orderdtl
        (orderid,shipid,item,lotnumber,uom,linestatus,
        qtyentered,itementered,uomentered,
        qtyorder,weightorder,cubeorder,amtorder,
        lastuser,lastupdate,
        backorder,allowsub,qtytype,invstatusind,invstatus,invclassind,
        inventoryclass,consigneesku,statususer
        )
        values
        (in_orderid,in_shipid,pl.item,
        decode(llotrequired,'O',lp.lotnumber,'P',lp.lotnumber,null),
        pl.unitofmeasure,'A',pl.quantity,pl.item,pl.unitofmeasure,
        pl.quantity,
        zcwt.lp_item_weight(in_lpid,oh.custid,pl.item,pl.unitofmeasure) * pl.quantity,
        zci.item_cube(oh.custid,pl.item,pl.unitofmeasure) * pl.quantity,
        zci.item_amt(oh.custid,null,null,pl.item,null) * pl.quantity, -- prn 25133 - this is equivalent to the old way of calling
        in_userid, sysdate,
        'N','N','E','I',null,'I',
        null,null,in_userid
        );
    exception when dup_val_on_index then
      update orderdtl
         set linestatus = 'A',
             qtyentered = qtyentered + pl.quantity,
             qtyorder = qtyorder + pl.quantity,
             weightorder = weightorder +
              zcwt.lp_item_weight(in_lpid,oh.custid,pl.item,pl.unitofmeasure) * pl.quantity,
             cubeorder = cubeorder +
              zci.item_cube(oh.custid,pl.item,pl.unitofmeasure) * pl.quantity,
             amtorder = amtorder +
              zci.item_amt(custid,orderid,shipid,item,lotnumber) * pl.quantity, --prn 25133
             lastuser = in_userid,
             lastupdate = sysdate
       where orderid = in_orderid
         and shipid = in_shipid
         and item = pl.item
         and nvl(decode(llotrequired,'O',lotnumber,'P',lotnumber,null),'(none)') =
             nvl(decode(llotrequired,'O',lp.lotnumber,'P',lp.lotnumber,null),'(none)');
    end;
    begin
      insert into commitments
      (facility, custid, item, inventoryclass,
       invstatus, status, lotnumber, uom,
       qty, orderid, shipid, orderitem, orderlot,
       priority, lastuser, lastupdate)
      values
      (in_facility, lp.custid, pl.item, pl.inventoryclass,
       pl.invstatus, 'CM',
       decode(llotrequired,'O',lp.lotnumber,'P',lp.lotnumber,null),
       pl.unitofmeasure, pl.quantity, in_orderid, in_shipid, pl.item,
       decode(llotrequired,'O',lp.lotnumber,'P',lp.lotnumber,null),
       oh.priority, in_userid, sysdate);
    exception when dup_val_on_index then
      update commitments
         set qty = qty + pl.quantity,
             priority = oh.priority,
             lastuser = in_userid,
             lastupdate = sysdate
       where facility = in_facility
         and custid = lp.custid
         and item = pl.item
         and inventoryclass = pl.inventoryclass
         and invstatus = pl.invstatus
         and status = 'CM'
         and nvl(decode(llotrequired,'O',lotnumber,'P',lotnumber,null),'(none)') =
             nvl(decode(llotrequired,'O',lp.lotnumber,'P',lp.lotnumber,null),'(none)')
         and orderid = in_orderid
         and shipid = in_shipid
         and orderitem = pl.item
         and nvl(decode(llotrequired,'O',orderlot,'P',orderlot,null),'(none)') =
             nvl(decode(llotrequired,'O',lp.lotnumber,'P',lp.lotnumber,null),'(none)');
    end;
  end if;
  zsp.get_next_shippinglpid(sp.lpid,out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    out_errorno := -21;
    out_msg := 'LiP ' || in_lpid || ' cannot assign shipping lip: '  || out_msg;
    return;
  end if;
  insert into shippingplate
    (lpid, item, custid, facility, location, status, holdreason,
    unitofmeasure, quantity, type, fromlpid, serialnumber,
    lotnumber, parentlpid, useritem1, useritem2, useritem3,
    lastuser, lastupdate, invstatus, qtyentered, orderitem,
    uomentered, inventoryclass, loadno, stopno, shipno,
    orderid, shipid, weight, ucc128, labelformat, taskid, orderlot,
    pickuom, pickqty, cartonseq, manufacturedate, expirationdate)
    values
    (sp.lpid, pl.item, lp.custid, in_facility, pl.location,
     'U', pl.holdreason, pl.unitofmeasure, pl.quantity,
     'F', pl.lpid, pl.serialnumber, pl.lotnumber, null,
     pl.useritem1, pl.useritem2, pl.useritem3,
     in_userid, sysdate, pl.invstatus, pl.quantity,
     pl.item, pl.unitofmeasure, pl.inventoryclass,
     oh.loadno, oh.stopno, oh.shipno, in_orderid, in_shipid,
     zcwt.lp_item_weight(pl.lpid,lp.custid,pl.item,pl.unitofmeasure) * pl.quantity,
     null, null, tk.taskid, decode(llotrequired,'O',lp.lotnumber,'P',lp.lotnumber,null),
     pl.unitofmeasure, pl.quantity, null, pl.manufacturedate, pl.expirationdate);
  if oh.ordertype in ('T','U') then
    insert into subtasks
    (taskid, tasktype, facility, fromsection, fromloc,
     fromprofile,tosection,toloc,toprofile,touserid,
     custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
     orderid,shipid,orderitem,orderlot,priority,
     prevpriority,curruserid,lastuser,lastupdate,
     pickuom, pickqty, picktotype, wave,
     pickingzone, cartontype, weight, cube, staffhrs, cartonseq,
     shippinglpid, shippingtype, cartongroup)
    values
    (tk.taskid,tk.tasktype,lp.facility,fromloc.section,lp.location,
     fromloc.equipprof,toloc.section,oh.stageloc,
     toloc.equipprof,null,lp.custid,pl.item,pl.lpid,
     pl.unitofmeasure,pl.quantity,fromloc.pickingseq,oh.loadno,oh.stopno,
     oh.shipno,in_orderid,in_shipid,pl.item,
     decode(llotrequired,'O',lp.lotnumber,'P',lp.lotnumber,null),
     in_taskpriority,in_taskpriority,null,in_userid,sysdate,
     pl.unitofmeasure,pl.quantity,tk.picktotype,null,
     fromloc.pickingzone,tk.cartontype,
     zcwt.lp_item_weight(pl.lpid,lp.custid,pl.item,pl.unitofmeasure) * pl.quantity,
     zci.item_cube(lp.custid,pl.item,pl.unitofmeasure) * pl.quantity,
     zlb.staff_hours(in_facility,lp.custid,pl.item,tk.tasktype,
     fromloc.pickingzone,pl.unitofmeasure,pl.quantity),1,
     sp.lpid, 'F', zwv.cartontype_group(tk.cartontype));
  else
    if lp.type = 'PA' then
      update subtasks
         set shippinglpid = sp.lpid
       where taskid = tk.taskid;
    end if;
  end if;
end loop;
dbms_sql.close_cursor(curLips);
exception when no_data_found then
  dbms_sql.close_cursor(curLips);
  out_errorno := -40;
  out_msg := 'Unable to process lips: ' || in_lpid;
  return;
end;

update orderhdr
   set orderstatus = '4',
       lastuser = in_userid,
       lastupdate = sysdate
 where orderid = in_orderid
   and shipid = in_shipid
   and orderstatus < '4';

out_errorno := 0;
out_msg := 'OKAY';

exception when OTHERS then
  out_msg := 'zgtpbl ' || substr(sqlerrm, 1, 80);
  out_errorno := sqlcode;
end pick_by_lip_request;

end gentasks;
/
show error package body gentasks;
exit;
