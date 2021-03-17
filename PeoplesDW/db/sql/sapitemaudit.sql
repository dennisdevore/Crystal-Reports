--
-- $Id$
--
create table tmp_parms
(item varchar2(50)
,fromdate date
,todate date
);

create table tmp_item_adj
(whenoccurred date
,invstatus varchar2(2)
,inventoryclass varchar2(2)
,tasktype varchar2(4)
,adjreason varchar2(2)
,movement varchar2(3)
,adjqty number(7)
);

create table tmp_item_rcv
(statusupdate date
,invstatus varchar2(2)
,inventoryclass varchar2(2)
,rcvqty number(7)
);

create table tmp_item_shp
(statusupdate date
,invstatus varchar2(2)
,inventoryclass varchar2(2)
,shpqty number(7)
);

set serveroutput on;

declare

out_msg varchar2(255);
out_errorno integer;
out_movement_code varchar2(255);
in_item varchar2(50);
in_fromdate date;
in_todate date;

cursor curInvAdj is
  select rowid,invadjactivity.*
    from invadjactivity
   where custid = 'HP'
     and item = in_item
     and whenoccurred >= in_fromdate
     and whenoccurred < in_todate
   order by whenoccurred desc;

cursor curReceipts is
  select orderid,shipid,statusupdate
    from orderhdr oh
   where oh.custid = 'HP'
     and oh.ordertype in ('R','Q','C')
     and oh.orderstatus = 'R'
     and oh.statusupdate >= in_fromdate
     and oh.statusupdate < in_todate
     and exists
       (select * from orderdtl od
         where oh.orderid = od.orderid
           and oh.shipid = od.shipid
           and od.item = in_item);

cursor curReceiptDtl(in_orderid number, in_shipid number) is
  select invstatus,
         inventoryclass,
         sum(qtyrcvd) as qtyrcvd
    from orderdtlrcpt
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
   group by invstatus,inventoryclass;

cursor curShipments is
  select orderid,shipid,statusupdate
    from orderhdr oh
   where oh.custid = 'HP'
     and oh.ordertype in ('O','V')
     and oh.orderstatus = '9'
     and oh.statusupdate >= in_fromdate
     and oh.statusupdate < in_todate
     and exists
       (select * from orderdtl od
         where oh.orderid = od.orderid
           and oh.shipid = od.shipid
           and od.item = in_item);

cursor curShipmentDtl(in_orderid number, in_shipid number) is
  select invstatus,
         inventoryclass,
         sum(quantity) as qtyship
    from shippingplate
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and type in ('F','P')
   group by invstatus,inventoryclass;

begin
out_msg := '';
out_errorno := 0;
out_movement_code := '';
in_item := upper('&1');
in_fromdate := to_date('&2', 'YYYYMMDDHH24MISS');
in_todate := to_date('&3', 'YYYYMMDDHH24MISS');


insert into tmp_parms
values
(in_item,in_fromdate,in_todate);

for aj in curInvAdj
loop
/*
  zut.prt(aj.lpid || ' ' || substr(dt(aj.whenoccurred),1,17) || ' ' ||
    aj.adjqty || ' ' || aj.adjreason || ' ' || aj.tasktype);
  zut.prt('  cur ' || aj.custid || ' ' || aj.item || ' ' ||
    aj.invstatus || ' ' || aj.inventoryclass);
  zut.prt('  old ' || aj.oldcustid || ' ' || aj.olditem || ' ' ||
    aj.oldinvstatus || ' ' || aj.oldinventoryclass);
  zut.prt('  new ' || aj.newcustid || ' ' || aj.newitem || ' ' ||
    aj.newinvstatus || ' ' || aj.newinventoryclass);
*/
  zmi3.validate_interface(aj.rowid,out_movement_code,out_errorno,out_msg);
/*
  zut.prt('out_movement_code:  [' || out_movement_code || ']');
  zut.prt('out_errorno:  [' || out_errorno || ']');
  zut.prt('out_msg:  [' || out_msg || ']');
  zut.prt(' ');
*/
  if out_errorno <> 0 then
    insert into tmp_item_adj values
     (trunc(aj.whenoccurred),aj.invstatus,aj.inventoryclass,
      aj.tasktype,aj.adjreason,'N/A',aj.adjqty);
  else
    insert into tmp_item_adj values
     (trunc(aj.whenoccurred),aj.invstatus,aj.inventoryclass,
      aj.tasktype,aj.adjreason,out_movement_code,aj.adjqty);
  end if;
  commit;
end loop;

for rch in curReceipts
loop
  for rcd in curReceiptDtl(rch.orderid,rch.shipid)
  loop
    insert into tmp_item_rcv values
     (trunc(rch.statusupdate),rcd.invstatus,rcd.inventoryclass,rcd.qtyrcvd);
    commit;
  end loop;
end loop;

for shp in curShipments
loop
  for shd in curShipmentDtl(shp.orderid,shp.shipid)
  loop
    insert into tmp_item_shp values
     (trunc(shp.statusupdate),shd.invstatus,shd.inventoryclass,shd.qtyship);
    commit;
  end loop;
end loop;

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/

break on report;
compute sum of count on report;
compute sum of qty on report;

spool &&1..txt;

select item,
       to_char(fromdate,'mm/dd/yyyy hh24:mi:ss') as fromdate,
       to_char(todate, 'mm/dd/yyyy hh24:mi:ss') as todate
  from tmp_parms;

select
statusupdate as rcvdate,
invstatus as stat,
inventoryclass as class,
count(1) as count,
sum(rcvqty) as qty
  from tmp_item_rcv
 group by statusupdate,invstatus,inventoryclass
 order by statusupdate,invstatus,inventoryclass;

select
statusupdate as shpdate,
invstatus as stat,
inventoryclass as class,
count(1) as count,
sum(shpqty) as qty
  from tmp_item_shp
 group by statusupdate,invstatus,inventoryclass
 order by statusupdate,invstatus,inventoryclass;

select
whenoccurred as adjdate,
invstatus as stat,
inventoryclass as class,
tasktype as task,
adjreason as reason,
movement as move,
count(1) as count,
sum(adjqty) as qty
  from tmp_item_adj
 group by whenoccurred,invstatus,inventoryclass,tasktype,movement,adjreason
 order by whenoccurred,invstatus,inventoryclass,tasktype,movement,adjreason;

spool off;

drop table tmp_item_adj;
drop table tmp_item_rcv;
drop table tmp_item_shp;
drop table tmp_parms;

exit;
