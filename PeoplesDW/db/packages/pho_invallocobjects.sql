drop table pho_allocableinv;

create table pho_allocableinv
(sessionid       number
,facility        varchar2(3)
,facilityname    varchar2(40)
,custid          varchar2(10)
,custname        varchar2(40)
,item            varchar2(50)
,itemdescr       varchar2(255)
,orderid         number(9)
,shipid          number(2)
,reference       varchar2(20)
,shipdate        date
,entrydate       date
,canceldate      date
,po              varchar2(20)
,dueinpo         varchar2(20)
,qtyorder        number(10)
,qtyallocable    number(10)
,qtyduein        number(10)
,uom             varchar2(4)
,qtyorderpcs     number(10)
,qtyallocablepcs number(10)
,qtydueinpcs     number(10)
,qtyorderctn     number(10)
,qtyallocablectn number(10)
,qtydueinctn     number(10)
,lastupdate      date
);

create index pho_allocableinv_sessionid_idx
 on pho_allocableinv(sessionid,facility,custid,item,orderid,shipid);

create index pho_allocableinv_lastupd_idx
 on pho_allocableinv(lastupdate);

create or replace package PHO_ALLOCABLEINVPKG
as type ai_type is ref cursor return pho_allocableinv%rowtype;
end pho_allocableinvpkg;
/

--
-- $Id: pho_invallocobjects.sql 0 2007-09-21 00:00:00Z bobw $
--

create or replace procedure PHO_ALLOCABLEINVPROC
(ai_cursor IN OUT pho_allocableinvpkg.ai_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_thru_date IN date
,in_debug_yn IN varchar2)
as

cursor curCustomer is
  select name
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curFacility is
  select facility, name
    from facility
   where instr(','||in_facility||',', ','||facility||',', 1, 1) > 0
      or in_facility='ALL';
cf curFacility%rowtype;

cursor curCustItems is
  select item,descr,baseuom
    from custitem
   where custid = in_custid
   order by item;
cit curCustItems%rowtype;

cursor curOrderedQty(in_facility IN varchar, in_item IN varchar2, in_baseuom IN varchar2) is
  select nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, in_baseuom)),0) as qtyorder,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, 'PCS')),0) as qtyorderpcs,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, 'CTN')),0) as qtyorderctn
    from orderhdr oh, orderdtl od
   where oh.fromfacility = in_facility
     and oh.orderstatus in ('0','1')
     and oh.custid = in_custid
     and oh.ordertype = 'O'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and oh.shipdate <= in_thru_date;
coq curOrderedQty%rowtype;

cursor curAllocableQty(in_facility IN varchar, in_item IN varchar2, in_baseuom IN varchar2) is
  select nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(qty,0), uom, in_baseuom)),0) as qtyallocable,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(qty,0), uom, 'PCS')),0) as qtyallocablepcs,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(qty,0), uom, 'CTN')),0) as qtyallocablectn
    from custitemtotview
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and invstatus <> 'SU'
     and status in ('A','CM');
caq curAllocableQty%rowtype;

cursor curDueInQty(in_facility IN varchar, in_item IN varchar2, in_baseuom IN varchar2) is
  select nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0) - nvl(od.qtyrcvd,0), od.uom, in_baseuom)),0) as qtyduein,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0) - nvl(od.qtyrcvd,0), od.uom, 'PCS')),0) as qtydueinpcs,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0) - nvl(od.qtyrcvd,0), od.uom, 'CTN')),0) as qtydueinctn
    from orderhdr oh, orderdtl od
   where oh.tofacility = in_facility
     and oh.orderstatus in ('0','1','3','A')
     and oh.custid = in_custid
     and oh.ordertype = 'R'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item;
cdi curDueInQty%rowtype;

cursor curOrders(in_custid IN varchar, in_facility IN varchar, in_item IN varchar2, in_baseuom IN varchar2) is
  select oh.orderid, oh.shipid, oh.reference, oh.shipdate, oh.entrydate, oh.cancel_if_not_delivered_by, oh.po,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, in_baseuom)),0) as qtyorder,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, 'PCS')),0) as qtyorderpcs,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, 'CTN')),0) as qtyorderctn
    from orderhdr oh, orderdtl od
   where oh.fromfacility = in_facility
     and oh.orderstatus in ('0','1')
     and oh.custid = in_custid
     and oh.ordertype = 'O'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and oh.shipdate <= in_thru_date
   group by oh.orderid, oh.shipid, oh.reference, oh.shipdate, oh.entrydate, oh.cancel_if_not_delivered_by, oh.po
   order by oh.orderid, oh.shipid;
cord curOrders%rowtype;

cursor curOrdersDueIn(in_custid IN varchar, in_facility IN varchar, in_item IN varchar2, in_baseuom IN varchar2, in_orderid IN number, in_shipid IN number) is
  select oh.orderid, oh.shipid, oh.po, nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0) - nvl(od.qtyrcvd,0), od.uom, in_baseuom)),0) as qtyduein,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0) - nvl(od.qtyrcvd,0), od.uom, 'PCS')),0) as qtydueinpcs,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0) - nvl(od.qtyrcvd,0), od.uom, 'CTN')),0) as qtydueinctn
    from orderhdr oh, orderdtl od
   where oh.tofacility = in_facility
     and oh.orderstatus in ('0','1','3','A')
     and oh.custid = in_custid
     and oh.ordertype = 'R'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and (oh.orderid > in_orderid
      or  (oh.orderid = in_orderid
     and   oh.shipid > in_shipid))
   group by oh.orderid, oh.shipid, oh.po
   order by oh.orderid, oh.shipid;
codi curOrdersDueIn%rowtype;

numSessionId number;
dtlCount number;
orderID number;
shipID number;


procedure debugmsg(in_text varchar2) is
begin
  if upper(rtrim(in_debug_yn)) = 'Y' then
    zut.prt(in_text);
  end if;
exception when others then
  null;
end;

begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from pho_allocableinv
where sessionid = numSessionId;
commit;

delete from pho_allocableinv
where lastupdate < trunc(sysdate);
commit;

select count(1)
into dtlCount
from pho_allocableinv
where lastupdate < sysdate;

if dtlCount = 0 then
  EXECUTE IMMEDIATE 'truncate table pho_allocableinv';
end if;

cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;

for cf in curFacility
loop
  for cit in curCustItems
  loop
  	coq := null;
  	open curOrderedQty(cf.facility, cit.item, cit.baseuom);
  	fetch curOrderedQty into coq;
  	close curOrderedQty;
  	
  	caq := null;
  	open curAllocableQty(cf.facility, cit.item, cit.baseuom);
  	fetch curAllocableQty into caq;
  	close curAllocableQty;

  	cdi := null;
  	open curDueInQty(cf.facility, cit.item, cit.baseuom);
  	fetch curDueInQty into cdi;
  	close curDueInQty;
  	
    if coq.qtyorder > caq.qtyallocable then
    	insert into pho_allocableinv values(numSessionId, cf.facility, cf.name,
    	  in_custid, cu.name, cit.item, cit.descr, 0, 0, null, null, null, null, null, null,
    	  coq.qtyorder, caq.qtyallocable, cdi.qtyduein, cit.baseuom, coq.qtyorderpcs,
    	  caq.qtyallocablepcs, cdi.qtydueinpcs, coq.qtyorderctn,
    	  caq.qtyallocablectn, cdi.qtydueinctn, sysdate);

      orderID := 0;
      shipID := 0;
      
      for cord in curOrders(in_custid, cf.facility, cit.item, cit.baseuom)
      loop
      	select count(1)
      	  into dtlCount
      	  from pho_allocableinv
      	 where sessionid = numSessionId
      	   and facility = cf.facility
      	   and custid = in_custid
      	   and item = cit.item
      	   and orderid = cord.orderid
      	   and shipid = cord.shipid;
      	
      	if (dtlCount = 0) then
        	codi := null;
        	open curOrdersDueIn(in_custid, cf.facility, cit.item, cit.baseuom, orderID, shipID);
    	    fetch curOrdersDueIn into codi;
    	    close curOrdersDueIn;
    	    
          orderID := codi.orderid;
          shipID := codi.shipid;

        	insert into pho_allocableinv values(numSessionId, cf.facility, cf.name,
        	  in_custid, cu.name, cit.item, cit.descr, cord.orderid, cord.shipid,
        	  cord.reference, cord.shipdate, cord.entrydate, cord.cancel_if_not_delivered_by,
        	  cord.po, codi.po, cord.qtyorder, 0, codi.qtyduein, cit.baseuom, cord.qtyorderpcs,
        	  0, nvl(codi.qtydueinpcs,0), cord.qtyorderctn, 0, nvl(codi.qtydueinctn,0), sysdate);
        end if;
      end loop;
    end if;
  end loop;
  commit;
end loop;

commit;


open ai_cursor for
select *
   from pho_allocableinv
  where sessionid = numSessionId
  order by facility, custid, item;

end PHO_ALLOCABLEINVPROC;
/


create or replace procedure PHO_ALLOCABLEINVPROC2
(ai_cursor IN OUT pho_allocableinvpkg.ai_type
,in_custid IN varchar2
,in_campus IN varchar2
,in_facility IN varchar2
,in_thru_date IN date
,in_debug_yn IN varchar2)
as

cursor curCustomer is
  select name
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curFacility is
  select facility, name
    from facility
   where (instr(','||in_facility||',', ','||facility||',', 1, 1) > 0
      or in_facility='ALL')
     and campus=in_campus;
cf curFacility%rowtype;

cursor curItems(in_facility IN varchar2) is
  select od.item, ci.descr, ci.baseuom,
         nvl(sum(zlbl.uom_qty_conv(oh.custid, od.item, nvl(od.qtyorder,0), od.uom, ci.baseuom)),0) as qtyorder,
         nvl(sum(zlbl.uom_qty_conv(oh.custid, od.item, nvl(od.qtyorder,0), od.uom, 'PCS')),0) as qtyorderpcs,
         nvl(sum(zlbl.uom_qty_conv(oh.custid, od.item, nvl(od.qtyorder,0), od.uom, 'CTN')),0) as qtyorderctn
    from orderhdr oh, orderdtl od, custitem ci
   where oh.fromfacility = in_facility
     and oh.orderstatus in ('0','1')
     and oh.custid = in_custid
     and oh.ordertype = 'O'
     and oh.shipdate <= trunc(in_thru_date)
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and ci.custid = oh.custid
     and ci.item = od.item
   group by od.item, ci.descr, ci.baseuom;
cit curItems%rowtype;

cursor curAllocableQty(in_facility IN varchar, in_item IN varchar2) is
  select nvl(sum(zlbl.uom_qty_conv(cit.custid, cit.item, nvl(qty,0), uom, ci.baseuom)),0) as qtyallocable,
         nvl(sum(zlbl.uom_qty_conv(cit.custid, cit.item, nvl(qty,0), uom, 'PCS')),0) as qtyallocablepcs,
         nvl(sum(zlbl.uom_qty_conv(cit.custid, cit.item, nvl(qty,0), uom, 'CTN')),0) as qtyallocablectn
    from custitemtotview cit, custitem ci
   where cit.facility = in_facility
     and cit.custid = in_custid
     and cit.item = in_item
     and cit.invstatus <> 'SU'
     and cit.status in ('A','CM')
     and ci.custid = cit.custid
     and ci.item = cit.item;
caq curAllocableQty%rowtype;

cursor curOrders(in_facility IN varchar2, in_item IN varchar2) is
  select oh.orderid, oh.shipid, oh.reference, oh.shipdate, oh.entrydate, oh.cancel_if_not_delivered_by, oh.po,
         nvl(sum(zlbl.uom_qty_conv(oh.custid, od.item, nvl(od.qtyorder,0), od.uom, ci.baseuom)),0) as qtyorder,
         nvl(sum(zlbl.uom_qty_conv(oh.custid, od.item, nvl(od.qtyorder,0), od.uom, 'PCS')),0) as qtyorderpcs,
         nvl(sum(zlbl.uom_qty_conv(oh.custid, od.item, nvl(od.qtyorder,0), od.uom, 'CTN')),0) as qtyorderctn
    from orderhdr oh, orderdtl od, custitem ci
   where oh.fromfacility = in_facility
     and oh.orderstatus in ('0','1')
     and oh.custid = in_custid
     and oh.ordertype = 'O'
     and oh.shipdate <= in_thru_date
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and ci.custid = oh.custid
     and ci.item = od.item
   group by oh.orderid, oh.shipid, oh.reference, oh.shipdate, oh.entrydate, oh.cancel_if_not_delivered_by, oh.po;
cord curOrders%rowtype;

cursor curOrderQty(in_orderid IN number, in_shipid IN number) is
  select nvl(sum(zlbl.uom_qty_conv(oh.custid, od.item, nvl(od.qtyorder,0), od.uom, ci.baseuom)),0) as qtyorder,
         nvl(sum(zlbl.uom_qty_conv(oh.custid, od.item, nvl(od.qtyorder,0), od.uom, 'PCS')),0) as qtyorderpcs,
         nvl(sum(zlbl.uom_qty_conv(oh.custid, od.item, nvl(od.qtyorder,0), od.uom, 'CTN')),0) as qtyorderctn
    from orderhdr oh, orderdtl od, custitem ci
   where oh.orderid = in_orderid
     and oh.shipid = in_shipid
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and ci.custid = oh.custid
     and ci.item = od.item;
coq curOrderQty%rowtype;

cursor curDueInQty(in_facility IN varchar, in_item IN varchar2) is
  select nvl(sum(zlbl.uom_qty_conv(oh.custid, od.item, nvl(od.qtyorder,0) - nvl(od.qtyrcvd,0), od.uom, ci.baseuom)),0) as qtyduein,
         nvl(sum(zlbl.uom_qty_conv(oh.custid, od.item, nvl(od.qtyorder,0) - nvl(od.qtyrcvd,0), od.uom, 'PCS')),0) as qtydueinpcs,
         nvl(sum(zlbl.uom_qty_conv(oh.custid, od.item, nvl(od.qtyorder,0) - nvl(od.qtyrcvd,0), od.uom, 'CTN')),0) as qtydueinctn
    from orderhdr oh, orderdtl od, custitem ci
   where oh.tofacility = in_facility
     and oh.orderstatus in ('0','1','3','A')
     and oh.custid = in_custid
     and oh.ordertype = 'R'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and ci.custid = oh.custid
     and ci.item = od.item;
cdi curDueInQty%rowtype;

numSessionId number;
dtlCount number;
orderID number;
shipID number;


procedure debugmsg(in_text varchar2) is
begin
  if upper(rtrim(in_debug_yn)) = 'Y' then
    zut.prt(in_text);
  end if;
exception when others then
  null;
end;

begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from pho_allocableinv
where sessionid = numSessionId;
commit;

delete from pho_allocableinv
where lastupdate < trunc(sysdate);
commit;

select count(1)
into dtlCount
from pho_allocableinv
where lastupdate < sysdate;

if dtlCount = 0 then
  EXECUTE IMMEDIATE 'truncate table pho_allocableinv';
end if;

cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;

for cf in curFacility
loop
  for cit in curItems(cf.facility)
  loop
  	caq := null;
  	open curAllocableQty(cf.facility, cit.item);
  	fetch curAllocableQty into caq;
  	close curAllocableQty;
      	
    if cit.qtyorder > caq.qtyallocable then
      for cord in curOrders(cf.facility, cit.item)
      loop
        select count(1)
          into dtlCount
          from pho_allocableinv
         where sessionid = numSessionId
           and facility = cf.facility
           and custid = in_custid
           and item is null
           and orderid = cord.orderid
           and shipid = cord.shipid;
        	
      	if (dtlCount = 0) then
        	coq := null;
        	open curOrderQty(cord.orderid, cord.shipid);
        	fetch curOrderQty into coq;
        	close curOrderQty;
        
        	insert into pho_allocableinv values(numSessionId, cf.facility, cf.name,
        	  in_custid, cu.name, null, null, cord.orderid, cord.shipid,
        	  cord.reference, cord.shipdate, cord.entrydate, cord.cancel_if_not_delivered_by, cord.po,
        	  '1', coq.qtyorder, 0, 0, null, coq.qtyorderpcs,  0, 0, coq.qtyorderctn, 0, 0, sysdate);
        end if;

      	cdi := null;
      	open curDueInQty(cf.facility, cit.item);
      	fetch curDueInQty into cdi;
      	close curDueInQty;

        select count(1)
          into dtlCount
          from pho_allocableinv
         where sessionid = numSessionId
           and facility = cf.facility
           and custid = in_custid
           and item = cit.item
           and orderid = 0
           and shipid = 0;
        	
      	if (dtlCount = 0) then
        	insert into pho_allocableinv values(numSessionId, cf.facility, cf.name,
        	  in_custid, cu.name, cit.item, cit.descr, 0, 0,
        	  null, null, null, null, null, null, cord.qtyorder,
        	  caq.qtyallocable, cdi.qtyduein, cit.baseuom, cord.qtyorderpcs,
        	  caq.qtyallocablepcs, cdi.qtydueinpcs, cord.qtyorderctn,
        	  caq.qtyallocablectn, cdi.qtydueinctn, sysdate);
        else
          update pho_allocableinv
             set qtyorder = qtyorder + cord.qtyorder,
                 qtyorderpcs = qtyorderpcs + cord.qtyorderpcs,
                 qtyorderctn = qtyorderctn + cord.qtyorderctn
           where sessionid = numSessionId
             and facility = cf.facility
             and custid = in_custid
             and item = cit.item
             and orderid = 0
             and shipid = 0;
        end if;
        
      	insert into pho_allocableinv values(numSessionId, cf.facility, cf.name,
      	  in_custid, cu.name, cit.item, cit.descr, cord.orderid, cord.shipid,
      	  cord.reference, cord.shipdate, cord.entrydate, cord.cancel_if_not_delivered_by,
      	  cord.po, '2', cord.qtyorder, caq.qtyallocable, cdi.qtyduein, cit.baseuom,
      	  cord.qtyorderpcs, caq.qtyallocablepcs, cdi.qtydueinpcs, cord.qtyorderctn,
      	  caq.qtyallocablectn, cdi.qtydueinctn, sysdate);
      end loop;
    end if;
  end loop;
  commit;
end loop;

open ai_cursor for
select *
   from pho_allocableinv
  where sessionid = numSessionId;

end PHO_ALLOCABLEINVPROC2;
/

show errors package PHO_ALLOCABLEINVPKG;
show errors procedure PHO_ALLOCABLEINVPROC;
show errors procedure PHO_ALLOCABLEINVPROC2;
exit;
