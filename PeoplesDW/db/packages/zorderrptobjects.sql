--
-- $Id$
--

drop table orderrpt;

create table orderrpt
(sessionid       number
,facility        varchar2(3)
,custid          varchar2(10)
,item            varchar2(50)
,lotnumber       varchar2(30)
,lpid            varchar2(15)
,rcptorderid     number(9)
,rcptshipid      number(2)
,rcptdate        date
,rcptqty         number(10)
,rcptwght        number(17,8)
,shiporderid     number(9)
,shipshipid      number(2)
,shipdate        date
,shipqty         number(10)
,shipwght        number(17,8)
,remainqty       number(10)
,remainwght      number(17,8)
,billmethod      varchar2(4)
,uom             varchar2(4)
,rate            number(12,6)
,calctype        varchar2(1)
,contact5fax     varchar2(25)
,remainperuom    number(10)
,baseuomper      number(10)
,totremainqty    number(10)
,totremainwght   number(17,8)
,lastupdate      date
);

create index orderrpt_session_idx
 on orderrpt(sessionid,lpid);

create index orderrpt_lastupdate_idx
 on orderrpt(lastupdate);

create or replace package ORDERRPTPKG
as type orpt_type is ref cursor return orderrpt%rowtype;
end orderrptpkg;
/

create or replace procedure ORDERRPTBILLPROC
(or_cursor IN OUT orderrptpkg.orpt_type
,in_facility IN varchar2
,in_custid IN varchar2
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_revenuegroup IN varchar2)
as

cursor curFacility is
  select facility
    from facility
   where instr(','||in_facility||',', ','||facility||',', 1, 1) > 0
      or in_facility='ALL';
cf curFacility%rowtype;

cursor curCustomer is
  select custid, contact5fax
    from customer
   where instr(','||in_custid||',', ','||custid||',', 1, 1) > 0
      or in_custid='ALL';
cu curCustomer%rowtype;

cursor curCustItems(in_facility IN varchar2, in_custid IN varchar2) is
  select distinct orderid, shipid, item, lotnumber, invstatus, inventoryclass, uom, effdate, lpid
    from(
      select orderid, shipid, item, lotnumber, invstatus, inventoryclass, uom, effdate, lpid
        from asofinventorydtl
       where facility=in_facility
         and custid=in_custid
         and (instr(','||in_item||',', ','||item||',', 1, 1) > 0
          or  in_item = 'ALL')
         and (instr(','||in_lotnumber||',', ','||lotnumber||',', 1, 1) > 0
          or  in_lotnumber = 'ALL')
         and effdate>=trunc(in_begdate)
         and effdate<=trunc(in_enddate)
         and trantype in('RC','RT'))
   where (instr(','||in_item||',', ','||item||',', 1, 1) > 0
      or  in_item = 'ALL')
     and (instr(','||in_lotnumber||',', ','||lotnumber||',', 1, 1) > 0
      or  in_lotnumber = 'ALL');
cit curCustItems%rowtype;
cursor curCustRate(in_custid IN varchar2, in_item IN varchar2, in_effdate IN date, in_revenuegroup IN varchar2) is
  select billmethod, uom, rate, calctype
    from custitem cit, custrate cr, activity a
   where cit.custid = in_custid
     and cit.item = in_item
     and cr.custid = cit.custid
     and cr.rategroup = cit.rategroup
     and cr.effdate<=trunc(in_effdate)
     and a.code = cr.activity 
     and a.revenuegroup = in_revenuegroup
     and billmethod <> 'PCHG'
   order by cr.effdate desc;
cr curCustRate%rowtype;

cursor curReceipts(in_orderid IN number, in_shipid IN number, in_item IN varchar2, in_lotnumber IN varchar2, in_lpid IN varchar2) is
  select trunc(oh.statusupdate) rcptdate,
         sum(nvl(odr.qtyrcvdgood,0)) quantity, sum(nvl(odr.weight,0)) weight
    from orderhdr oh, orderdtlrcpt odr
   where oh.orderid = in_orderid
     and oh.shipid = in_shipid
     and oh.orderstatus = 'R'
     and odr.orderid = oh.orderid
     and odr.shipid = oh.shipid
     and odr.item = in_item
     and nvl(odr.lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
     and odr.lpid = in_lpid
   group by trunc(oh.statusupdate);
crcpt curReceipts%rowtype;

cursor curShipments(in_lpid IN varchar2, in_facility varchar2, in_custid varchar2,
       in_item varchar2, in_lotnumber varchar2, in_uom varchar2, in_invstatus varchar2,
       in_inventoryclass varchar2) is
  select oh.orderid, oh.shipid, trunc(oh.dateshipped) shipdate,
         sum(nvl(sp.quantity,0)) quantity, sum(nvl(sp.weight,0)) weight
    from orderhdr oh,(
      select sp1.orderid,
             sp1.shipid,
             nvl(sp1.quantity,0) quantity,
             nvl(sp1.weight,0) weight
        from shippingplate sp1
       where sp1.fromlpid = in_lpid
         and sp1.type in ('F','P')
         and sp1.status = 'SH'
       union
      select sp1.orderid,
             sp1.shipid,
             nvl(sp1.quantity,0) quantity,
             nvl(sp1.weight,0) weight
        from shippingplate sp1
       where sp1.fromlpid in
         (select lpid
            from plate
           where facility = in_facility
             and custid = in_custid
             and item = in_item
             and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
             and invstatus = in_invstatus
             and inventoryclass = in_inventoryclass
             and unitofmeasure = in_uom
             and fromlpid = in_lpid
           union
          select lpid
            from deletedplate
           where facility = in_facility
             and custid = in_custid
             and item = in_item
             and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
             and invstatus = in_invstatus
             and inventoryclass = in_inventoryclass
             and unitofmeasure = in_uom
             and fromlpid = in_lpid)
         and sp1.type in ('F','P')
         and sp1.status = 'SH') sp
       where oh.orderid = sp.orderid
     and oh.shipid=sp.shipid
     and oh.orderstatus='9'
     and trunc(dateshipped)>=trunc(in_begdate)
     and trunc(dateshipped)<=trunc(in_enddate)
       group by oh.orderid, oh.shipid, trunc(oh.dateshipped)
   order by trunc(oh.dateshipped), oh.orderid, oh.shipid;
cship curShipments%rowtype;

numSessionId number;
dtlCount integer;
lQuantity number(10);
lWeight number(17,8);

begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from orderrpt
where sessionid = numSessionId;
commit;

delete from orderrpt
where lastupdate < trunc(sysdate);
commit;

select count(1)
into dtlCount
from orderrpt
where lastupdate < sysdate;

if dtlCount = 0 then
  EXECUTE IMMEDIATE 'truncate table orderrpt';
end if;

cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;

for cf in curFacility
loop
  for cu in curCustomer
  loop
    for cit in curCustItems(cf.facility, cu.custid)
    loop
      cr := null;
      open curCustRate(cu.custid, cit.item, cit.effdate, in_revenuegroup);
      fetch curCustRate into cr;
      close curCustRate;
      for crcpt in curReceipts(cit.orderid, cit.shipid, cit.item, cit.lotnumber, cit.lpid)
      loop
        lQuantity := crcpt.quantity;
        lWeight := crcpt.weight;
        dtlCount := 0;
        for cship in curShipments(cit.lpid, cf.facility, cu.custid, cit.item, cit.lotnumber,
          cit.uom, cit.invstatus, cit.inventoryclass)
        loop
          lQuantity := lQuantity - cship.quantity;
          lWeight := lWeight - cship.weight;
          insert into orderrpt values
          (numSessionId,cf.facility,cu.custid,cit.item,cit.lotnumber,cit.lpid,
           cit.orderid,cit.shipid,crcpt.rcptdate,crcpt.quantity,crcpt.weight,
           cship.orderid,cship.shipid,cship.shipdate,cship.quantity,cship.weight,
           lQuantity,lWeight,cr.billmethod,cr.uom,cr.rate,cr.calctype,cu.contact5fax,
           nvl(zlbl.uom_qty_conv(cu.custid,cit.item,lQuantity,cit.uom,cr.uom),0),
           nvl(zlbl.uom_qty_conv(cu.custid,cit.item,1,cr.uom,cit.uom),0),0,0,
           sysdate);
           dtlCount := dtlCount + 1;
        end loop;
        if (dtlCount = 0) then
          insert into orderrpt values
          (numSessionId,cf.facility,cu.custid,cit.item,cit.lotnumber,cit.lpid,
           cit.orderid,cit.shipid,crcpt.rcptdate,crcpt.quantity,crcpt.weight,
           null,null,null,null,null,
           crcpt.quantity,crcpt.weight,cr.billmethod,cr.uom,cr.rate,cr.calctype,cu.contact5fax,
           nvl(zlbl.uom_qty_conv(cu.custid,cit.item,crcpt.quantity,cit.uom,cr.uom),0),
           nvl(zlbl.uom_qty_conv(cu.custid,cit.item,1,cr.uom,cit.uom),0),0,0,
           sysdate);
        end if;
        dtlCount := 0;
        select count(1)
          into dtlCount
          from deletedplate
         where lpid = cit.lpid
           and lastupdate >= trunc(in_begdate)
           and trunc(lastupdate) <= trunc(in_enddate);
        if (dtlCount >= 1) then
           lQuantity := 0;
           lWeight := 0;
        end if;
        update orderrpt
           set totremainqty = lQuantity,
               totremainwght = lWeight
         where sessionid = numSessionId
           and lpid = cit.lpid;
      end loop;
    end loop;
    commit;
  end loop;
end loop;

open or_cursor for
select *
   from orderrpt
  where sessionid = numSessionId;

end ORDERRPTBILLPROC;
/

create or replace procedure ORDERRPTPROC
(or_cursor IN OUT orderrptpkg.orpt_type
,in_facility IN varchar2
,in_custid IN varchar2
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_begdate IN date
,in_enddate IN date)
as
begin
	ORDERRPTBILLPROC(or_cursor, in_facility, in_custid, in_item, in_lotnumber, in_begdate, in_enddate, 'HNDG');
end ORDERRPTPROC;
/

show errors package ORDERRPTPKG;
show errors procedure ORDERRPTBILLPROC;
show errors procedure ORDERRPTPROC;
exit;
