drop table orderdemandrpt;

create global temporary table orderdemandrpt
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
,weightorder     number(16,4)
,weightallocable number(16,4)
,weightduein     number(16,4)
,lastupdate      date
) on commit preserve rows;

create index orderdemandrpt_sessionid_idx
 on orderdemandrpt(sessionid,facility,custid,item,orderid,shipid);

drop table orderdemandrpt2;

create global temporary table orderdemandrpt2
(sessionid       number
,facility        varchar2(3)
,custid          varchar2(10)
,orderid         number(9)
,shipid          number(2)
,reference       varchar2(20)
,shipdate        date
,qtyorder        number(10)
,qtyorderpcs     number(10)
,qtyorderctn     number(10)
,weigtorder      number(16,4)
,lastupdate      date
) on commit preserve rows;

create index orderdemandrpt2_sessionid_idx
 on orderdemandrpt2(sessionid,facility,custid,orderid,shipid);

create or replace package orderdemandrptpkg
as type ai_type is ref cursor return orderdemandrpt%rowtype;
	 type aio_type is ref cursor return orderdemandrpt2%rowtype;
end orderdemandrptpkg;
/

--
-- $Id: zorderdemandobjects.sql 1704 2007-03-02 22:58:34Z bobw $
--

create or replace procedure orderdemandrptproc
(ai_cursor IN OUT orderdemandrptpkg.ai_type
,in_custid IN varchar2
,in_facility IN varchar2)
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
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, 'CTN')),0) as qtyorderctn,
         nvl(sum(nvl(od.weight_entered_lbs,nvl(od.weightorder,0))),0) as weightorder
    from orderhdr oh, orderdtl od
   where oh.fromfacility = in_facility
     and oh.orderstatus not in ('9','X')
     and oh.custid = in_custid
     and oh.ordertype = 'O'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and od.linestatus not in ('9','X');
coq curOrderedQty%rowtype;

cursor curAllocableQty(in_facility IN varchar, in_item IN varchar2, in_baseuom IN varchar2) is
  select nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(qty,0), uom, in_baseuom)),0) as qtyallocable,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(qty,0), uom, 'PCS')),0) as qtyallocablepcs,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(qty,0), uom, 'CTN')),0) as qtyallocablectn,
         nvl(sum(weight),0) as weightallocable
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
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0) - nvl(od.qtyrcvd,0), od.uom, 'CTN')),0) as qtydueinctn,
         nvl(sum(nvl(od.weight_entered_lbs,nvl(od.weightorder,0)) - nvl(od.weightrcvd,0)),0) as weightduein
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
  select oh.orderid, oh.shipid, oh.reference, oh.shipdate,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, in_baseuom)),0) as qtyorder,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, 'PCS')),0) as qtyorderpcs,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, 'CTN')),0) as qtyorderctn,
         nvl(sum(nvl(od.weight_entered_lbs,nvl(od.weightorder,0))),0) as weightorder
    from orderhdr oh, orderdtl od
   where oh.fromfacility = in_facility
     and oh.orderstatus not in ('9','X')
     and oh.custid = in_custid
     and oh.ordertype = 'O'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and od.linestatus not in ('9','X')
   group by oh.orderid, oh.shipid, oh.reference, oh.shipdate
   order by oh.orderid, oh.shipid;
cord curOrders%rowtype;

numSessionId number;
dtlCount number;


begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from orderdemandrpt
where sessionid = numSessionId;
commit;

cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;

for cf in curFacility
loop
  for cit in curCustItems
  loop
  	open curOrderedQty(cf.facility, cit.item, cit.baseuom);
  	fetch curOrderedQty into coq;
  	close curOrderedQty;
  	
  	open curAllocableQty(cf.facility, cit.item, cit.baseuom);
  	fetch curAllocableQty into caq;
  	close curAllocableQty;

  	open curDueInQty(cf.facility, cit.item, cit.baseuom);
  	fetch curDueInQty into cdi;
  	close curDueInQty;
  	
    if coq.qtyorder > caq.qtyallocable then
    	insert into orderdemandrpt values(numSessionId, cf.facility, cf.name,
    	  in_custid, cu.name, cit.item, cit.descr, 0, 0, null, null, coq.qtyorder,
    	  caq.qtyallocable, cdi.qtyduein, cit.baseuom, coq.qtyorderpcs,
    	  caq.qtyallocablepcs, cdi.qtydueinpcs, coq.qtyorderctn,
    	  caq.qtyallocablectn, cdi.qtydueinctn, coq.weightorder, caq.weightallocable,
    	  cdi.weightduein, sysdate);
    	  
      for cord in curOrders(in_custid, cf.facility, cit.item, cit.baseuom)
      loop
      	select count(1)
      	  into dtlCount
      	  from orderdemandrpt
      	 where sessionid = numSessionId
      	   and facility = cf.facility
      	   and custid = in_custid
      	   and item = cit.item
      	   and orderid = cord.orderid
      	   and shipid = cord.shipid;
      	
      	if (dtlCount = 0) then
        	insert into orderdemandrpt values(numSessionId, cf.facility, cf.name,
        	  in_custid, cu.name, cit.item, cit.descr, cord.orderid, cord.shipid,
        	  cord.reference, cord.shipdate, cord.qtyorder, 0, 0, cit.baseuom,
        	  cord.qtyorderpcs, 0, 0, cord.qtyorderctn, 0, 0, cord.weightorder,
        	  0.0, 0.0, sysdate);
        end if;
      end loop;
    end if;
  end loop;
  commit;
end loop;

open ai_cursor for
select *
   from orderdemandrpt
  where sessionid = numSessionId
  order by facility, custid, item;

end orderdemandrptproc;
/


create or replace procedure orderdemandrptweightproc
(ai_cursor IN OUT orderdemandrptpkg.ai_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_variance IN number)
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
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, 'CTN')),0) as qtyorderctn,
         nvl(sum(nvl(od.weight_entered_lbs,nvl(od.weightorder,0))),0) as weightorder
    from orderhdr oh, orderdtl od
   where oh.fromfacility = in_facility
     and oh.orderstatus not in ('9','X')
     and oh.custid = in_custid
     and oh.ordertype = 'O'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and od.linestatus not in ('9','X');
coq curOrderedQty%rowtype;

cursor curAllocableQty(in_facility IN varchar, in_item IN varchar2, in_baseuom IN varchar2) is
  select nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(qty,0), uom, in_baseuom)),0) as qtyallocable,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(qty,0), uom, 'PCS')),0) as qtyallocablepcs,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(qty,0), uom, 'CTN')),0) as qtyallocablectn,
         nvl(sum(weight),0) as weightallocable
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
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0) - nvl(od.qtyrcvd,0), od.uom, 'CTN')),0) as qtydueinctn,
         nvl(sum(nvl(od.weight_entered_lbs,nvl(od.weightorder,0)) - nvl(od.weightrcvd,0)),0) as weightduein
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
  select oh.orderid, oh.shipid, oh.reference, oh.shipdate,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, in_baseuom)),0) as qtyorder,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, 'PCS')),0) as qtyorderpcs,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, 'CTN')),0) as qtyorderctn,
         nvl(sum(nvl(od.weight_entered_lbs,nvl(od.weightorder,0))),0) as weightorder
    from orderhdr oh, orderdtl od
   where oh.fromfacility = in_facility
     and oh.orderstatus not in ('9','X')
     and oh.custid = in_custid
     and oh.ordertype = 'O'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and od.linestatus not in ('9','X')
   group by oh.orderid, oh.shipid, oh.reference, oh.shipdate
   order by oh.orderid, oh.shipid;
cord curOrders%rowtype;

numSessionId number;
dtlCount number;


begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from orderdemandrpt
where sessionid = numSessionId;
commit;

cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;

for cf in curFacility
loop
  for cit in curCustItems
  loop
  	open curOrderedQty(cf.facility, cit.item, cit.baseuom);
  	fetch curOrderedQty into coq;
  	close curOrderedQty;
  	
  	open curAllocableQty(cf.facility, cit.item, cit.baseuom);
  	fetch curAllocableQty into caq;
  	close curAllocableQty;

  	open curDueInQty(cf.facility, cit.item, cit.baseuom);
  	fetch curDueInQty into cdi;
  	close curDueInQty;
  	
    if (coq.qtyorder > caq.qtyallocable) or
       ((coq.weightorder*(1+(nvl(in_variance,0)/100))) > caq.weightallocable) then
    	insert into orderdemandrpt values(numSessionId, cf.facility, cf.name,
    	  in_custid, cu.name, cit.item, cit.descr, 0, 0, null, null, coq.qtyorder,
    	  caq.qtyallocable, cdi.qtyduein, cit.baseuom, coq.qtyorderpcs,
    	  caq.qtyallocablepcs, cdi.qtydueinpcs, coq.qtyorderctn,
    	  caq.qtyallocablectn, cdi.qtydueinctn, coq.weightorder, caq.weightallocable,
    	  cdi.weightduein, sysdate);
    	  
      for cord in curOrders(in_custid, cf.facility, cit.item, cit.baseuom)
      loop
      	select count(1)
      	  into dtlCount
      	  from orderdemandrpt
      	 where sessionid = numSessionId
      	   and facility = cf.facility
      	   and custid = in_custid
      	   and item = cit.item
      	   and orderid = cord.orderid
      	   and shipid = cord.shipid;
      	
      	if (dtlCount = 0) then
        	insert into orderdemandrpt values(numSessionId, cf.facility, cf.name,
        	  in_custid, cu.name, cit.item, cit.descr, cord.orderid, cord.shipid,
        	  cord.reference, cord.shipdate, cord.qtyorder, 0, 0, cit.baseuom,
        	  cord.qtyorderpcs, 0, 0, cord.qtyorderctn, 0, 0, cord.weightorder,
        	  0.0, 0.0, sysdate);
        end if;
      end loop;
    end if;
  end loop;
  commit;
end loop;

open ai_cursor for
select *
   from orderdemandrpt
  where sessionid = numSessionId
  order by facility, custid, item;

end orderdemandrptweightproc;
/


create or replace procedure orderdemandrptproc2
(aio_cursor IN OUT orderdemandrptpkg.aio_type
,in_custid IN varchar2
,in_facility IN varchar2)
as

cursor curAllocableInv(in_session IN number) is
  select distinct custid, facility, item
    from orderdemandrpt
   where sessionid = in_session
   order by custid, facility, item;
cai curAllocableInv%rowtype;

cursor curOrderedQty(in_custid IN varchar, in_facility IN varchar, in_item IN varchar2) is
  select oh.orderid, oh.shipid, oh.reference, oh.shipdate,
         nvl(sum(zlbl.uom_qty_conv(in_custid, od1.item, nvl(od1.qtyorder,0), od1.uom, ci.baseuom)),0) as qtyorder,
         nvl(sum(zlbl.uom_qty_conv(in_custid, od1.item, nvl(od1.qtyorder,0), od1.uom, 'PCS')),0) as qtyorderpcs,
         nvl(sum(zlbl.uom_qty_conv(in_custid, od1.item, nvl(od1.qtyorder,0), od1.uom, 'CTN')),0) as qtyorderctn,
         nvl(sum(nvl(od1.weight_entered_lbs,nvl(od1.weightorder,0))),0) as weightorder
    from orderhdr oh, orderdtl od1, custitem ci
   where oh.fromfacility = in_facility
     and oh.orderstatus not in ('9','X')
     and oh.custid = in_custid
     and oh.ordertype = 'O'
     and od1.orderid = oh.orderid
     and od1.shipid = oh.shipid
     and od1.linestatus not in ('9','X')
     and ci.custid = in_custid
     and ci.item = od1.item
     and exists (select 1
                   from orderdtl od2
                  where od2.orderid = od1.orderid
                    and od2.shipid = od1.shipid
                    and od2.item = in_item)
   group by oh.orderid, oh.shipid, oh.reference, oh.shipdate
   order by oh.orderid, oh.shipid;
coq curOrderedQty%rowtype;

numSessionId number;
dtlCount number;


begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from orderdemandrpt2
where sessionid = numSessionId;
commit;

for cai in curAllocableInv(numSessionId)
loop
  for coq in curOrderedQty(cai.custid, cai.facility, cai.item)
  loop
  	select count(1)
  	  into dtlCount
  	  from orderdemandrpt2
  	 where sessionid = numSessionId
  	   and facility = cai.facility
  	   and custid = cai.custid
  	   and orderid = coq.orderid
  	   and shipid = coq.shipid;
  	
  	if (dtlCount = 0) then
      insert into orderdemandrpt2 values(numSessionId, cai.facility, cai.custid,
        coq.orderid, coq.shipid, coq.reference, coq.shipdate, coq.qtyorder,
        coq.qtyorderpcs, coq.qtyorderctn, coq.weightorder, sysdate);
    end if;
  end loop;
end loop;

open aio_cursor for
select *
   from orderdemandrpt2
  where sessionid = numSessionId
  order by facility, custid, orderid, shipid;

end orderdemandrptproc2;
/


show errors package orderdemandrptpkg;
show errors procedure orderdemandrptproc;
show errors procedure orderdemandrptweightproc;
show errors procedure orderdemandrptproc2;
exit;
