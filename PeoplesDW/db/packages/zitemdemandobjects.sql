drop table itemdemandrpt;

create global temporary table itemdemandrpt
(sessionid       number
,facility        varchar2(3)
,custid          varchar2(10)
,item            varchar2(50)
,invstatus       varchar2(12)
,qtyavailable    number(10)
,qtyorder1       number(10)
,qtyorder2       number(10)
,qtyorder3       number(10)
,qtyorder4       number(10)
,lastupdate      date
) on commit preserve rows;

create index itemdemandrpt_sessionid_idx
 on itemdemandrpt(sessionid,facility,custid,item,invstatus);

create index itemdemandrpt_lastupdate_idx
 on itemdemandrpt(lastupdate);

create or replace package itemdemandrptPKG
as type id_type is ref cursor return itemdemandrpt%rowtype;
end itemdemandrptPKG;
/

--
-- $Id
--

create or replace procedure itemdemandrptPROC
(ai_cursor IN OUT itemdemandrptPKG.id_type
,in_facility IN varchar2
,in_custid IN varchar2
,in_item IN varchar2
,in_invstatus IN varchar2)
as

cursor curCust is
  select custid
    from customer
   where (instr(','||upper(in_custid)||',', ','||upper(custid)||',', 1, 1) > 0
      or  upper(in_custid)='ALL');
cu curCust%rowtype;

cursor curItems(in_custid IN varchar2) is
  select distinct od.item, od.invstatus
    from orderhdr oh, orderdtl od
   where oh.recent_order_id like 'Y%'
     and oh.fromfacility = in_facility
   	 and (oh.orderstatus > '9'
   	  or  oh.orderstatus < '9')
   	 and (oh.orderstatus > 'X'
   	  or  oh.orderstatus < 'X')
     and oh.ordertype = 'O'
     and oh.custid = in_custid
     and oh.orderid = od.orderid
     and oh.shipid = od.shipid
     and (instr(','||upper(in_item)||',', ','||upper(od.item)||',', 1, 1) > 0
      or  upper(in_item)='ALL')
     and (instr(','||upper(in_invstatus)||',', ','||upper(od.invstatus)||',', 1, 1) > 0
      or  upper(in_invstatus)='ALL')
   	 and (od.linestatus > 'X'
   	  or  od.linestatus < 'X');
ci curItems%rowtype;

cursor curDemand(in_custid varchar2, in_item varchar2, in_invstatus varchar2) is
  select trunc(oh.shipdate) as shipdate, sum(nvl(od.qtyorder,0)) qtyorder
    from orderhdr oh, orderdtl od
   where oh.recent_order_id like 'Y%'
     and oh.fromfacility = in_facility
   	 and (oh.orderstatus > '9'
   	  or  oh.orderstatus < '9')
   	 and (oh.orderstatus > 'X'
   	  or  oh.orderstatus < 'X')
     and oh.ordertype = 'O'
     and oh.custid = in_custid
     and oh.orderid = od.orderid
     and oh.shipid = od.shipid
     and od.item = in_item
     and od.invstatus = in_invstatus
   	 and (od.linestatus > 'X'
   	  or  od.linestatus < 'X')
   group by trunc(oh.shipdate);
cd curDemand%rowtype;

cursor curAvailable(in_custid varchar2, in_item varchar2, in_invstatusdem varchar2) is
  select sum(nvl(quantity,0)) as quantity
    from plate
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and (instr(','||upper(in_invstatusdem)||',', ','||upper(invstatus)||',', 1, 1) > 0)
     and (instr(','||upper(in_invstatus)||',', ','||upper(invstatus)||',', 1, 1) > 0
      or  upper(in_invstatus)='ALL')
     and type in ('MP','PA');
ca curAvailable%rowtype;

cursor curPicked(in_custid varchar2, in_item varchar2, in_invstatusdem varchar2) is
  select sum(nvl(quantity,0)) as quantity
    from shippingplate
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and (instr(','||upper(in_invstatusdem)||',', ','||upper(invstatus)||',', 1, 1) > 0)
     and (instr(','||upper(in_invstatus)||',', ','||upper(invstatus)||',', 1, 1) > 0
      or  upper(in_invstatus)='ALL')
     and type = 'P'
     and status in ('P','S','L');
cpk curPicked%rowtype;

cursor curPlate(in_sessionid number) is
  select custid, item, invstatus, sum(nvl(quantity,0)) as quantity
    from plate pl
   where facility = in_facility
     and (instr(','||upper(in_invstatus)||',', ','||upper(invstatus)||',', 1, 1) > 0
      or  upper(in_invstatus)='ALL')
     and type in ('MP','PA')
     and (pl.facility, pl.custid, pl.item) in
         (select nvl(id1.facility, id1.facility), 
                 nvl(id1.custid, id1.custid), 
                 nvl(id1.item, id1.item) 
            from itemdemandrpt id1 
           where id1.sessionid = in_sessionid) 
     and not exists(select 1
                       from itemdemandrpt id2 
                      where id2.sessionid = in_sessionid 
                        and id2.facility = pl.facility 
                        and id2.custid = pl.custid 
                        and id2.item = pl.item 
                        and instr(',' || upper(id2.invstatus) || ',', ',' || upper(pl.invstatus) || ',', 1, 1) > 0) 
   group by custid, item, invstatus;
cp curPlate%rowtype;

numSessionId number;
dtlCount number;
qty1 number;
qty2 number;
qty3 number;
qty4 number;
rundate date;


begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from itemdemandrpt
where sessionid = numSessionId;
commit;

delete from itemdemandrpt
where lastupdate < trunc(sysdate);
commit;

select count(1)
into dtlCount
from itemdemandrpt
where lastupdate < sysdate;

if dtlCount = 0 then
  EXECUTE IMMEDIATE 'truncate table itemdemandrpt';
end if;

select trunc(sysdate)
  into rundate
  from dual;

for cu in curCust
loop
  for ci in curItems(cu.custid)
loop
  dtlCount := 0;
  cd := null;
    for cd in curDemand(cu.custid, ci.item, ci.invstatus)
  loop
    qty1 := 0;
    qty2 := 0;
    qty3 := 0;
    qty4 := 0;
    
    if (to_char(rundate,'D') in ('1','2','3','4')) then
      if(cd.shipdate < rundate) then
        qty1 := cd.qtyorder;
      elsif(cd.shipdate = rundate) then
        qty2 := cd.qtyorder;
      elsif(cd.shipdate = (rundate+1)) then
        qty3 := cd.qtyorder;
      elsif(cd.shipdate = (rundate+2)) then
        qty4 := cd.qtyorder;
      end if;
    elsif (to_char(rundate,'D') = '5') then
      if(cd.shipdate < rundate) then
        qty1 := cd.qtyorder;
      elsif(cd.shipdate = rundate) then
        qty2 := cd.qtyorder;
      elsif(cd.shipdate = (rundate+1)) then
        qty3 := cd.qtyorder;
      elsif(cd.shipdate = (rundate+4)) then
        qty4 := cd.qtyorder;
      end if;
    elsif (to_char(rundate,'D') = '6') then
      if(cd.shipdate < rundate) then
        qty1 := cd.qtyorder;
      elsif(cd.shipdate = rundate) then
        qty2 := cd.qtyorder;
      elsif(cd.shipdate = (rundate+3)) then
        qty3 := cd.qtyorder;
      elsif(cd.shipdate = (rundate+4)) then
        qty4 := cd.qtyorder;
      end if;
    elsif (to_char(rundate,'D') = '7') then
      if(cd.shipdate < rundate) then
        qty1 := cd.qtyorder;
      elsif(cd.shipdate = rundate) then
        qty2 := cd.qtyorder;
      elsif(cd.shipdate = (rundate+2)) then
        qty3 := cd.qtyorder;
      elsif(cd.shipdate = (rundate+3)) then
        qty4 := cd.qtyorder;
      end if;
    end if;
      
    if (dtlCount = 0) then
      ca := null;
        open curAvailable(cu.custid, ci.item, ci.invstatus);
      fetch curAvailable into ca;
      close curAvailable;

      if (ca.quantity is null) then
        ca.quantity := 0;
      end if;
      
      cpk := null;
        open curPicked(cu.custid, ci.item, ci.invstatus);
      fetch curPicked into cpk;
      close curPicked;

      if (cpk.quantity is null) then
        cpk.quantity := 0;
      end if;
      
        insert into itemdemandrpt values(numSessionId, in_facility, cu.custid,
          ci.item, ci.invstatus, ca.quantity + cpk.quantity, qty1, qty2, qty3, qty4,
          sysdate);
    else
      update itemdemandrpt
         set qtyorder1 = qtyorder1 + qty1,
             qtyorder2 = qtyorder2 + qty2,
             qtyorder3 = qtyorder3 + qty3,
             qtyorder4 = qtyorder4 + qty4
       where sessionid = numSessionId
         and facility = in_facility
           and custid = cu.custid
         and item = ci.item
         and invstatus = ci.invstatus;
    end if;
    
    dtlCount := dtlCount + 1;
  end loop;
end loop;
end loop;

delete from itemdemandrpt
 where sessionid = numSessionId
   and qtyorder1 = 0
   and qtyorder2 = 0
   and qtyorder3 = 0
   and qtyorder4 = 0
   and qtyavailable = 0;

for cp in curPlate(numSessionId)
loop
  insert into itemdemandrpt values(numSessionId, in_facility, cp.custid,
    cp.item, cp.invstatus, cp.quantity, 0, 0, 0, 0, sysdate);
end loop;

open ai_cursor for
select *
   from itemdemandrpt
  where sessionid = numSessionId;

end itemdemandrptPROC;
/

show errors procedure itemdemandrptPROC;
exit;
