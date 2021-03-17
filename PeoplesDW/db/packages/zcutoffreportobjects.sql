drop table cutoffrpt;

-- trantype column values:
--    AA-Shipped Orders
--    CO-cutoff time
--    SH-Shipment
--    ZZ-open orders

create table cutoffrpt
(sessionid       number
,shipdate        date
,entrydate        date
,trantype        varchar2(2)
,facility        varchar2(3)
,custid          varchar2(10)
,loadno          number(7)
,orderid         number(9)
,shipid          number(2)
,orderstatus     varchar2(1)
,orderstatusabbrev varchar2(12)
,reference       varchar2(20)
,po              varchar2(20)
,orderedby       varchar2(12)
,item            varchar2(50)
,qtyorder        number(7)
,qtyship         number(7)
,cutoffmsg       varchar2(255)  -- for trantype 'CO'
,shipmentmsg     varchar2(255)  -- for trantype 'SH'
,reporttitle     varchar2(255)
,lastupdate      date
);

create index cutoffrpt_sessionid_idx
 on cutoffrpt(sessionid);

create index cutoffrpt_lastupdate_idx
 on cutoffrpt(lastupdate);

create or replace package cutoffrptpkg
as type cof_type is ref cursor return cutoffrpt%rowtype;
end cutoffrptpkg;
/
create or replace procedure cutoffrptproc
(cof_cursor IN OUT cutoffrptpkg.cof_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_shipdate IN date
,in_cutoff1 IN varchar2
,in_cutoff2 IN varchar2
,in_cutoff3 IN varchar2
,in_cutoff4 IN varchar2
,in_shipment1 IN varchar2
,in_shipment2 IN varchar2
,in_shipment3 IN varchar2
,in_shipment4 IN varchar2
,in_debug_yn IN varchar2)
as
--
-- $Id$
--

cursor curSelectShippedOrders is
  select nvl(fromfacility,'x') as fromfacility,
         custid,statusupdate,loadno,orderid,shipid,
         reference,po,entrydate,orderstatus
    from orderhdr
   where statusupdate >= trunc(in_shipdate)
     and statusupdate < (trunc(in_shipdate) + 1)
   order by statusupdate,loadno,entrydate;

cursor curSelectOpenOrders is
  select nvl(fromfacility,'x') as fromfacility,
         custid,statusupdate,loadno,orderid,shipid,
         reference,po,entrydate,orderstatus
    from orderhdr
   where fromfacility = in_facility
     and ordertype = 'O'
     and orderstatus < '9'
     and entrydate < (trunc(in_shipdate) + 1)
   order by loadno,entrydate;

cursor curSelectItems(in_orderid number, in_shipid number) is
  select item,qtyorder,nvl(qtyship,0) as qtyship
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X';

cursor curOrderHistory(in_orderid number, in_shipid number) is
  select userid
    from orderhistory
   where orderid = in_orderid
     and shipid = in_shipid
     and action = 'ADD';

type date_rcd is record (
  datetime date
);

type date_tbl is table of date_rcd
  index by binary_integer;

shipments date_tbl;
sx integer;
numSessionId number;
wrk cutoffrpt%rowtype;
cntLoads integer;
qtyOrderTot integer;
qtyShipTot integer;

function orderstatus_abbrev(in_code varchar2) return varchar2
is
out orderstatus%rowtype;
begin

out.abbrev := in_code;

select abbrev
  into out.abbrev
  from orderstatus
 where code = in_code;

return out.abbrev;

exception when others then
  return out.abbrev;
end;

procedure validate_cutoff(in_cutoff varchar2, in_cutoffno number) is
begin

  if rtrim(in_cutoff) is null then
    return;
  end if;

  if upper(in_debug_yn) = 'Y' then
    zut.prt('attempting cutoff <' || in_cutoff || '>');
  end if;
  wrk.entrydate := to_date(
    to_char(in_shipdate, 'MM/DD/YYYY') || ' ' || in_cutoff,
    'MM/DD/YYYY HH24:MI');
  if in_cutoffno <= shipments.count then
    wrk.shipdate := shipments(in_cutoffno).datetime;
  else
    wrk.shipdate := wrk.entrydate;
  end if;

  if upper(in_debug_yn) = 'Y' then
    zut.prt('wrk.shipdate is <' ||
      to_char(wrk.shipdate, 'mm/dd/yyyy hh24:mi') || '>');
  end if;

  wrk.cutoffmsg := 'Entered after ' ||
    to_char(wrk.entrydate, 'HH:MIAM') ||
    ' cutoff';
  insert into cutoffrpt values
    (numSessionId,wrk.shipdate,wrk.entrydate,'CO',wrk.facility,wrk.custid,
     0,0,0,null,null,null,null,null,
     null,null,null,wrk.cutoffmsg,null,
     wrk.reporttitle,sysdate);
  wrk.cutoffmsg := 'Entered before ' ||
    to_char(wrk.entrydate, 'HH:MIAM') ||
    ' cutoff';
  wrk.entrydate := to_date('19900101','yyyymmdd');
  insert into cutoffrpt values
    (numSessionId,wrk.shipdate,wrk.entrydate,'CO',wrk.facility,wrk.custid,
     0,0,0,null,null,null,null,null,
     null,null,null,wrk.cutoffmsg,null,
     wrk.reporttitle,sysdate);
exception when others then
  if upper(in_debug_yn) = 'Y' then
    zut.prt(sqlerrm);
  end if;
end;

procedure validate_shipment(in_shipment varchar2, in_shipmentno number) is
begin

  if rtrim(in_shipment) is null then
    return;
  end if;

  if upper(in_debug_yn) = 'Y' then
    zut.prt('attempting shipment <' || in_shipment || '>');
  end if;
  wrk.shipdate := to_date(
    to_char(in_shipdate, 'MM/DD/YYYY') || ' ' || in_shipment,
    'MM/DD/YYYY HH24:MI');
  if upper(in_debug_yn) = 'Y' then
    zut.prt('wrk.shipdate is <' ||
      to_char(wrk.shipdate, 'mm/dd/yyyy hh24:mi') || '>');
  end if;

  wrk.shipmentmsg := 'End of Shipment ' || in_shipmentno;
  insert into cutoffrpt values
    (numSessionId,wrk.shipdate,wrk.shipdate,'SH',wrk.facility,wrk.custid,
     0,null,null,null,null,null,null,null,null,null,null,null,
     wrk.shipmentmsg,wrk.reporttitle,sysdate);

  shipments(in_shipmentno).datetime := wrk.shipdate;

exception when others then
  if upper(in_debug_yn) = 'Y' then
    zut.prt(sqlerrm);
  end if;
end;

begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from cutoffrpt
where sessionid = numSessionId;
commit;

delete from cutoffrpt
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

validate_shipment(in_shipment1,1);
validate_shipment(in_shipment2,2);
validate_shipment(in_shipment3,3);
validate_shipment(in_shipment4,4);

validate_cutoff(in_cutoff1,1);
validate_cutoff(in_cutoff2,2);
validate_cutoff(in_cutoff3,3);
validate_cutoff(in_cutoff4,4);

commit;

cntLoads := 0;
wrk.Loadno := 0;
for oh in curSelectShippedOrders
loop
  if oh.custid != in_custid then
    goto continue_shipped_order_loop;
  end if;
  if oh.fromfacility != in_facility then
    goto continue_shipped_order_loop;
  end if;
  if oh.orderstatus != '9' then
    goto continue_shipped_order_loop;
  end if;
  wrk.shipdate := null;
  for sx in 1..shipments.count
  loop
    if oh.statusupdate <= shipments(sx).datetime then
      wrk.shipdate := shipments(sx).datetime;
      exit;
    end if;
  end loop;
  if wrk.shipdate is null then
    wrk.shipdate := oh.statusupdate;
  end if;
  wrk.entrydate := oh.entrydate;
  wrk.trantype := 'AA'; --shipped orders sorted first
  wrk.facility := oh.fromfacility;
  wrk.custid := oh.custid;
  wrk.orderid := oh.orderid;
  wrk.shipid := oh.shipid;
  wrk.orderstatus := oh.orderstatus;
  wrk.orderstatusabbrev := orderstatus_abbrev(wrk.orderstatus);
  wrk.reference := oh.reference;
  wrk.po := oh.po;
  wrk.orderedby := '';
  open curOrderHistory(wrk.orderid,wrk.shipid);
  fetch curOrderHistory into wrk.orderedby;
  close curOrderHistory;
  qtyOrderTot := 0;
  qtyShipTot := 0;
  for od in curSelectItems(wrk.orderid,wrk.shipid)
  loop
    insert into cutoffrpt values
    (numSessionId,wrk.shipdate,wrk.entrydate,'AA',wrk.facility,wrk.custid,
     wrk.loadno,wrk.orderid,wrk.shipid,wrk.orderstatus,wrk.orderstatusabbrev,
     wrk.reference,wrk.po,wrk.orderedby,
     od.item,od.qtyorder,od.qtyship,null,null,
     wrk.reporttitle,sysdate);
    qtyOrderTot := qtyOrderTot + od.qtyorder;
    qtyShipTot := qtyShipTot + od.qtyship;
  end loop;
  insert into cutoffrpt values
  (numSessionId,wrk.shipdate,wrk.entrydate,'AA',wrk.facility,wrk.custid,
   wrk.loadno,wrk.orderid,wrk.shipid,wrk.orderstatus,wrk.orderstatusabbrev,
   wrk.reference,wrk.po,wrk.orderedby,
   'ZZZZZZZZZZ',qtyordertot,qtyshiptot,null,null,
   wrk.reporttitle,sysdate);
<< continue_shipped_order_loop >>
  commit;
end loop;

commit;

for oh in curSelectOpenOrders
loop
  if oh.custid != in_custid then
    goto continue_open_order_loop;
  end if;
  wrk.shipdate := to_date('20881231','yyyymmdd');
  wrk.entrydate := oh.entrydate;
  wrk.trantype := 'ZZ'; --open orders sorted last
  wrk.facility := oh.fromfacility;
  wrk.custid := oh.custid;
  wrk.orderid := oh.orderid;
  wrk.shipid := oh.shipid;
  wrk.orderstatus := oh.orderstatus;
  wrk.orderstatusabbrev := orderstatus_abbrev(wrk.orderstatus);
  wrk.reference := oh.reference;
  wrk.po := oh.po;
  wrk.orderedby := '';
  open curOrderHistory(wrk.orderid,wrk.shipid);
  fetch curOrderHistory into wrk.orderedby;
  close curOrderHistory;
  qtyOrderTot := 0;
  qtyShipTot := 0;
  for od in curSelectItems(wrk.orderid,wrk.shipid)
  loop
    insert into cutoffrpt values
    (numSessionId,wrk.shipdate,wrk.entrydate,'ZZ',wrk.facility,wrk.custid,
     wrk.loadno,wrk.orderid,wrk.shipid,wrk.orderstatus,wrk.orderstatusabbrev,
     wrk.reference,wrk.po,wrk.orderedby,
     od.item,od.qtyorder,od.qtyship,null,null,
     wrk.reporttitle,sysdate);
    qtyOrderTot := qtyOrderTot + od.qtyorder;
    qtyShipTot := qtyShipTot + od.qtyship;
  end loop;
  insert into cutoffrpt values
  (numSessionId,wrk.shipdate,wrk.entrydate,'ZZ',wrk.facility,wrk.custid,
   wrk.loadno,wrk.orderid,wrk.shipid,wrk.orderstatus,wrk.orderstatusabbrev,
   wrk.reference,wrk.po,wrk.orderedby,
   'ZZZZZZZZZZ',qtyordertot,qtyshiptot,null,null,
   wrk.reporttitle,sysdate);
<< continue_open_order_loop >>
  commit;
end loop;

commit;

open cof_cursor for
 select *
   from cutoffrpt
  where sessionid = numSessionId
  order by shipdate,entrydate,trantype,orderid,shipid,item;

end cutoffrptproc;
/
show errors package cutoffrptpkg;
show errors procedure cutoffrptproc;
--exit;
