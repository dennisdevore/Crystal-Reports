/*
Note that daysonhandproc appears in this file twice. 
Make any modifications in both places.
*/


drop table daysonhand;

create table daysonhand
(sessionid       number
,fromdate        date
,todate          date
,daysinperiod    number
,facility        varchar2(3)
,custid          varchar2(10)
,item            varchar2(50)
,itemdesc        varchar2(255)
,qtyorder        number(10)
,cntorder        number(10)
,qtyship         number(10)
,qtyinventory    number(10)
,useramt1        number(10,2)
,amtavgorder     number(10,2)
,amtinventory    number(10,2)
,daysonhand      number(10,1)
,amtdaysonhand   number(10,2)
,reporttitle     varchar2(255)
,lastupdate      date
,itemstatus      varchar2(4)
,productgroup    varchar2(4)
);

create index daysonhand_sessionid_idx
 on daysonhand(sessionid,item);

create index daysonhand_lastupdate_idx
 on daysonhand(lastupdate);

create or replace package daysonhandpkg
as type doh_type is ref cursor return daysonhand%rowtype;
	procedure daysonhandproc
		(doh_cursor IN OUT daysonhandpkg.doh_type
		,in_custid IN varchar2
		,in_facility IN varchar2
		,in_begdate IN date
		,in_enddate IN date
		,in_activity_only_yn varchar2
		,in_nonactive_only_yn varchar2
		,in_sort_doh_ascend_descend varchar2
		,in_report_percent number
		,in_debug_yn IN varchar2);
end daysonhandpkg;
/

CREATE OR REPLACE PACKAGE Body daysonhandpkg AS
--
-- $Id$
--

procedure daysonhandproc
(doh_cursor IN OUT daysonhandpkg.doh_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_activity_only_yn varchar2
,in_nonactive_only_yn varchar2
,in_sort_doh_ascend_descend varchar2
,in_report_percent number
,in_debug_yn IN varchar2)
as

cursor curShipmentOrders(in_begdate IN date, in_enddate IN date) is
  select orderid,shipid,ordertype,custid,fromfacility,consignee,shiptoname,
         orderstatus
    from orderhdr
   where statusupdate >= trunc(in_begdate)
     and statusupdate <  trunc(in_enddate) + 1;

cursor curShipmentLines(in_orderid number, in_shipid number) is
  select item,lotnumber,qtyorder,nvl(qtyship,0) as qtyship
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X';

cursor curCustItem(in_item varchar2) is
  select descr,status,useramt1,baseuom,productgroup
    from custitem
   where custid = upper(in_custid)
     and item = in_item;
ci curCustItem%rowtype;

cursor curAsOfEndSearch(in_item IN varchar2) is
  select invstatus,inventoryclass,lotnumber,max(effdate) as effdate
    from asofinventory
   where facility = upper(in_facility)
     and custid = upper(in_custid)
     and item = in_item
     and effdate <= trunc(in_enddate)
     and invstatus != 'SU'
   group by invstatus,inventoryclass,lotnumber
   order by invstatus,inventoryclass,lotnumber;

cursor curDaysOnHand(in_sessionid number) is
  select *
    from daysonhand
   where sessionid = in_sessionid
   order by item;

cursor curDaysOnHandDescend(in_sessionid number) is
  select *
    from daysonhand
   where sessionid = in_sessionid
   order by daysonhand desc,item;

cursor curDaysOnHandAscend(in_sessionid number) is
  select *
    from daysonhand
   where sessionid = in_sessionid
   order by daysonhand,item;

numSessionId number;
wrk daysonhand%rowtype;
cntTotal integer;
cntRowNum integer;
qtyInventory integer;

begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from daysonhand
where sessionid = numSessionId;
commit;

delete from daysonhand
where lastupdate < trunc(sysdate);
commit;

wrk.reporttitle := null;
begin
 select reporttitle
   into wrk.reporttitle
   from reporttitleview;
exception when others then
 null;
end;

for so in curShipmentOrders(in_begdate, in_enddate)
loop

  if so.ordertype not in ('O','T','V','U') then
    goto continue_shipment_loop;
  end if;
  if so.custid != upper(in_custid) then
    goto continue_shipment_loop;
  end if;
  if so.fromfacility != upper(in_facility) then
    goto continue_shipment_loop;
  end if;
  if so.orderstatus != '9' then
    goto continue_shipment_loop;
  end if;

  for sl in curShipmentLines(so.orderid,so.shipid)
  loop
    ci.descr := sl.item;
    ci.status := 'INAC';
    open curCustItem(sl.item);
    fetch curCustItem into ci;
    close curCustItem;
    if (upper(in_nonactive_only_yn) = 'Y') and
       (ci.status = 'ACTV') then
      goto continue_line_loop;
    end if;
    update daysonhand
       set qtyorder = qtyorder + sl.qtyorder,
           qtyship = qtyship + sl.qtyship,
           cntOrder = cntOrder + 1
     where sessionid = numSessionId
       and item = sl.item;
    if sql%rowcount = 0 then
      insert into daysonhand values
      (numSessionId,trunc(in_begdate),trunc(in_enddate),
       (trunc(in_enddate) - trunc(in_begdate)) + 1,
       upper(in_facility),upper(in_custid),
       sl.item,ci.descr,sl.qtyorder,1,sl.qtyship,0,zci.item_amt(so.custid,so.orderid,so.shipid,sl.item,sl.lotnumber),0,0,0,0,
       wrk.reporttitle,sysdate,ci.status,ci.productgroup);
      commit;
    end if;
  << continue_line_loop >>
    null;
  end loop;

<< continue_shipment_loop >>
  null;
end loop;

if upper(in_activity_only_yn) = 'N' then
  if upper(in_nonactive_only_yn) = 'Y' then
    insert into daysonhand
      select numSessionId,trunc(in_begdate),trunc(in_enddate),
      (trunc(in_enddate) - trunc(in_begdate)) + 1,
      upper(in_facility),upper(in_custid),
      custitem.item,custitem.descr,0,0,0,0,custitem.useramt1,0,0,0,0,
      wrk.reporttitle,sysdate,custitem.status,custitem.productgroup
      from custitem
      where custid = upper(in_custid)
        and not exists
       (select * from daysonhand
         where sessionid = numSessionId
           and item = custitem.item
           and custitem.status <> 'ACTV');
  else
    insert into daysonhand
      select numSessionId,trunc(in_begdate),trunc(in_enddate),
      (trunc(in_enddate) - trunc(in_begdate)) + 1,
      upper(in_facility),upper(in_custid),
      custitem.item, custitem.descr,0,0,0,0,custitem.useramt1,0,0,0,0,
      wrk.reporttitle,sysdate,custitem.status,custitem.productgroup
      from custitem
      where custid = upper(in_custid)
        and not exists
       (select * from daysonhand
         where sessionid = numSessionId
           and item = custitem.item);
  end if;
  commit;
end if;

for doh in curDaysOnHand(numSessionId)
loop
 for aoe in curAsOfEndSearch(doh.item)
 loop
   if upper(in_debug_yn) = 'Y' then
     zut.prt('asof for ' || doh.item || ' ' || aoe.effdate || ' ' ||
     aoe.invstatus || ' ' || aoe.inventoryclass || ' ' ||
     aoe.lotnumber);
   end if;
   ci := null;
   open curCustItem(doh.item);
   fetch curCustItem into ci;
   close curCustItem;
   if ci.baseuom is null then
     ci.baseuom := 'EA';
   end if;
   qtyInventory := 0;
   begin
     select currentqty
       into qtyInventory
       from asofinventory
      where facility = upper(in_facility)
        and custid = upper(in_custid)
        and item = doh.item
        and effdate = aoe.effdate
        and invstatus = aoe.invstatus
        and inventoryclass = aoe.inventoryclass
        and nvl(lotnumber,'x') = nvl(aoe.lotnumber,'x')
        and uom = ci.baseuom;
   exception when others then
     qtyInventory := 0;
   end;
   doh.qtyinventory := doh.qtyinventory + qtyInventory;
 end loop;
 doh.amtinventory := doh.qtyinventory * doh.useramt1;
 if doh.cntorder != 0 then
   doh.amtavgorder := (doh.qtyorder * doh.useramt1) / doh.cntorder;
 else
   doh.amtavgorder := 0;
 end if;
 if doh.qtyorder != 0 then
   doh.daysonhand := doh.qtyinventory / (doh.qtyorder / doh.daysinperiod);
   doh.amtdaysonhand := doh.daysonhand * doh.useramt1;
 else
   doh.daysonhand := 0;
   doh.amtdaysonhand := 0;
 end if;
 update daysonhand
    set qtyinventory = doh.qtyinventory,
        amtinventory = doh.amtinventory,
        amtavgorder = doh.amtavgorder,
        daysonhand = doh.daysonhand,
        amtdaysonhand = doh.amtdaysonhand
  where sessionid = numSessionId
    and item = doh.item;
end loop;

if in_report_percent != 100 then
  select count(1)
    into cntTotal
    from daysonhand
   where sessionid = numSessionId;
  cntTotal := cntTotal * in_report_percent / 100;
  cntRowNum := 0;
  if upper(substr(in_sort_doh_ascend_descend,1,1)) = 'D' then
    for cnt in curDaysOnHandDescend(numSessionId)
    loop
      cntRowNum := cntRowNum + 1;
      if cntRowNum > cntTotal then
        delete from daysonhand
         where sessionid = numSessionId
           and item = cnt.item;
        commit;
      end if;
    end loop;
  else
    for cnt in curDaysOnHandAscend(numSessionId)
    loop
      cntRowNum := cntRowNum + 1;
      if cntRowNum > cntTotal then
        delete from daysonhand
         where sessionid = numSessionId
           and item = cnt.item;
        commit;
      end if;
    end loop;
  end if;
end if;

commit;

if upper(substr(in_sort_doh_ascend_descend,1,1)) = 'D' then
  open doh_cursor for
   select *
     from daysonhand
    where sessionid = numSessionId
    order by daysonhand desc,item;
else
  open doh_cursor for
   select *
     from daysonhand
    where sessionid = numSessionId
    order by daysonhand,item;
end if;

end daysonhandproc;
end daysonhandpkg;
/
create or replace procedure daysonhandproc
(doh_cursor IN OUT daysonhandpkg.doh_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_activity_only_yn varchar2
,in_nonactive_only_yn varchar2
,in_sort_doh_ascend_descend varchar2
,in_report_percent number
,in_debug_yn IN varchar2)
as
--
-- $Id$
--

cursor curShipmentOrders(in_begdate IN date, in_enddate IN date) is
  select orderid,shipid,ordertype,custid,fromfacility,consignee,shiptoname,
         orderstatus
    from orderhdr
   where statusupdate >= trunc(in_begdate)
     and statusupdate <  trunc(in_enddate) + 1;

cursor curShipmentLines(in_orderid number, in_shipid number) is
  select item,lotnumber,qtyorder,nvl(qtyship,0) as qtyship
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X';

cursor curCustItem(in_item varchar2) is
  select descr,status,useramt1,baseuom,productgroup
    from custitem
   where custid = upper(in_custid)
     and item = in_item;
ci curCustItem%rowtype;

cursor curAsOfEndSearch(in_item IN varchar2) is
  select invstatus,inventoryclass,lotnumber,max(effdate) as effdate
    from asofinventory
   where facility = upper(in_facility)
     and custid = upper(in_custid)
     and item = in_item
     and effdate <= trunc(in_enddate)
     and invstatus != 'SU'
   group by invstatus,inventoryclass,lotnumber
   order by invstatus,inventoryclass,lotnumber;

cursor curDaysOnHand(in_sessionid number) is
  select *
    from daysonhand
   where sessionid = in_sessionid
   order by item;

cursor curDaysOnHandDescend(in_sessionid number) is
  select *
    from daysonhand
   where sessionid = in_sessionid
   order by daysonhand desc,item;

cursor curDaysOnHandAscend(in_sessionid number) is
  select *
    from daysonhand
   where sessionid = in_sessionid
   order by daysonhand,item;

numSessionId number;
wrk daysonhand%rowtype;
cntTotal integer;
cntRowNum integer;
qtyInventory integer;

begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from daysonhand
where sessionid = numSessionId;
commit;

delete from daysonhand
where lastupdate < trunc(sysdate);
commit;

wrk.reporttitle := null;
begin
 select reporttitle
   into wrk.reporttitle
   from reporttitleview;
exception when others then
 null;
end;

for so in curShipmentOrders(in_begdate, in_enddate)
loop

  if so.ordertype not in ('O','T','V','U') then
    goto continue_shipment_loop;
  end if;
  if so.custid != upper(in_custid) then
    goto continue_shipment_loop;
  end if;
  if so.fromfacility != upper(in_facility) then
    goto continue_shipment_loop;
  end if;
  if so.orderstatus != '9' then
    goto continue_shipment_loop;
  end if;

  for sl in curShipmentLines(so.orderid,so.shipid)
  loop
    ci.descr := sl.item;
    ci.status := 'INAC';
    open curCustItem(sl.item);
    fetch curCustItem into ci;
    close curCustItem;
    if (upper(in_nonactive_only_yn) = 'Y') and
       (ci.status = 'ACTV') then
      goto continue_line_loop;
    end if;
    update daysonhand
       set qtyorder = qtyorder + sl.qtyorder,
           qtyship = qtyship + sl.qtyship,
           cntOrder = cntOrder + 1
     where sessionid = numSessionId
       and item = sl.item;
    if sql%rowcount = 0 then
      insert into daysonhand values
      (numSessionId,trunc(in_begdate),trunc(in_enddate),
       (trunc(in_enddate) - trunc(in_begdate)) + 1,
       upper(in_facility),upper(in_custid),
       sl.item,ci.descr,sl.qtyorder,1,sl.qtyship,0,zci.item_amt(so.custid,so.orderid,so.shipid,sl.item,sl.lotnumber),0,0,0,0,
       wrk.reporttitle,sysdate,ci.status,ci.productgroup);
      commit;
    end if;
  << continue_line_loop >>
    null;
  end loop;

<< continue_shipment_loop >>
  null;
end loop;

if upper(in_activity_only_yn) = 'N' then
  if upper(in_nonactive_only_yn) = 'Y' then
    insert into daysonhand
      select numSessionId,trunc(in_begdate),trunc(in_enddate),
      (trunc(in_enddate) - trunc(in_begdate)) + 1,
      upper(in_facility),upper(in_custid),
      custitem.item,custitem.descr,0,0,0,0,custitem.useramt1,0,0,0,0,
      wrk.reporttitle,sysdate,custitem.status,custitem.productgroup
      from custitem
      where custid = upper(in_custid)
        and not exists
       (select * from daysonhand
         where sessionid = numSessionId
           and item = custitem.item
           and custitem.status <> 'ACTV');
  else
    insert into daysonhand
      select numSessionId,trunc(in_begdate),trunc(in_enddate),
      (trunc(in_enddate) - trunc(in_begdate)) + 1,
      upper(in_facility),upper(in_custid),
      custitem.item, custitem.descr,0,0,0,0,custitem.useramt1,0,0,0,0,
      wrk.reporttitle,sysdate,custitem.status,custitem.productgroup
      from custitem
      where custid = upper(in_custid)
        and not exists
       (select * from daysonhand
         where sessionid = numSessionId
           and item = custitem.item);
  end if;
  commit;
end if;

for doh in curDaysOnHand(numSessionId)
loop
 for aoe in curAsOfEndSearch(doh.item)
 loop
   if upper(in_debug_yn) = 'Y' then
     zut.prt('asof for ' || doh.item || ' ' || aoe.effdate || ' ' ||
     aoe.invstatus || ' ' || aoe.inventoryclass || ' ' ||
     aoe.lotnumber);
   end if;
   ci := null;
   open curCustItem(doh.item);
   fetch curCustItem into ci;
   close curCustItem;
   if ci.baseuom is null then
     ci.baseuom := 'EA';
   end if;
   qtyInventory := 0;
   begin
     select currentqty
       into qtyInventory
       from asofinventory
      where facility = upper(in_facility)
        and custid = upper(in_custid)
        and item = doh.item
        and effdate = aoe.effdate
        and invstatus = aoe.invstatus
        and inventoryclass = aoe.inventoryclass
        and nvl(lotnumber,'x') = nvl(aoe.lotnumber,'x')
        and uom = ci.baseuom;
   exception when others then
     qtyInventory := 0;
   end;
   doh.qtyinventory := doh.qtyinventory + qtyInventory;
 end loop;
 doh.amtinventory := doh.qtyinventory * doh.useramt1;
 if doh.cntorder != 0 then
   doh.amtavgorder := (doh.qtyorder * doh.useramt1) / doh.cntorder;
 else
   doh.amtavgorder := 0;
 end if;
 if doh.qtyorder != 0 then
   doh.daysonhand := doh.qtyinventory / (doh.qtyorder / doh.daysinperiod);
   doh.amtdaysonhand := doh.daysonhand * doh.useramt1;
 else
   doh.daysonhand := 0;
   doh.amtdaysonhand := 0;
 end if;
 update daysonhand
    set qtyinventory = doh.qtyinventory,
        amtinventory = doh.amtinventory,
        amtavgorder = doh.amtavgorder,
        daysonhand = doh.daysonhand,
        amtdaysonhand = doh.amtdaysonhand
  where sessionid = numSessionId
    and item = doh.item;
end loop;

if in_report_percent != 100 then
  select count(1)
    into cntTotal
    from daysonhand
   where sessionid = numSessionId;
  cntTotal := cntTotal * in_report_percent / 100;
  cntRowNum := 0;
  if upper(substr(in_sort_doh_ascend_descend,1,1)) = 'D' then
    for cnt in curDaysOnHandDescend(numSessionId)
    loop
      cntRowNum := cntRowNum + 1;
      if cntRowNum > cntTotal then
        delete from daysonhand
         where sessionid = numSessionId
           and item = cnt.item;
        commit;
      end if;
    end loop;
  else
    for cnt in curDaysOnHandAscend(numSessionId)
    loop
      cntRowNum := cntRowNum + 1;
      if cntRowNum > cntTotal then
        delete from daysonhand
         where sessionid = numSessionId
           and item = cnt.item;
        commit;
      end if;
    end loop;
  end if;
end if;

commit;

if upper(substr(in_sort_doh_ascend_descend,1,1)) = 'D' then
  open doh_cursor for
   select *
     from daysonhand
    where sessionid = numSessionId
    order by daysonhand desc,item;
else
  open doh_cursor for
   select *
     from daysonhand
    where sessionid = numSessionId
    order by daysonhand,item;
end if;

end daysonhandproc;
/
show errors package daysonhandpkg;
show errors procedure daysonhandproc;
show errors package body daysonhandpkg;
exit;
