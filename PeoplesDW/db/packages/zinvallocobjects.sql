drop table allocableinv;

create table allocableinv
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
,shiptoname      varchar2(40)
,onetimeshiptoname varchar2(40)
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
);

create index allocableinv_sessionid_idx
 on allocableinv(sessionid,facility,custid,item,orderid,shipid);

create index allocableinv_lastupdate_idx
 on allocableinv(lastupdate);

drop table allocableinvorders;

create table allocableinvorders
(sessionid       number
,facility        varchar2(3)
,custid          varchar2(10)
,orderid         number(9)
,shipid          number(2)
,reference       varchar2(20)
,shiptoname      varchar2(40)
,onetimeshiptoname varchar2(40)
,qtyorder        number(10)
,qtyorderpcs     number(10)
,qtyorderctn     number(10)
,weigtorder      number(16,4)
,lastupdate      date
);

create index allocinvords_sessionid_idx
 on allocableinvorders(sessionid,facility,custid,orderid,shipid);

create index allocinvords_lastupdate_idx
 on allocableinvorders(lastupdate);

create or replace package ALLOCABLEINVPKG
as type ai_type is ref cursor return allocableinv%rowtype;
	 type aio_type is ref cursor return allocableinvorders%rowtype;
	procedure ALLOCABLEINVBASEPROC
	(ai_cursor IN OUT allocableinvpkg.ai_type
	,in_custid IN varchar2
	,in_facility IN varchar2
	,in_invstatus IN varchar2
	,in_inventoryclass IN varchar2
	,in_debug_yn IN varchar2);
end allocableinvpkg;
/

CREATE OR REPLACE PACKAGE Body ALLOCABLEINVPKG AS
--
-- $Id: zinvallocobjects.sql 1704 2007-03-02 22:58:34Z bobw $
--

procedure ALLOCABLEINVBASEPROC
(ai_cursor IN OUT allocableinvpkg.ai_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_invstatus IN varchar2
,in_inventoryclass IN varchar2
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
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, 'CTN')),0) as qtyorderctn,
         nvl(sum(nvl(od.weight_entered_lbs,nvl(od.weightorder,0))),0) as weightorder
    from orderhdr oh, orderdtl od
   where oh.recent_order_id like 'Y%'
     and oh.fromfacility = in_facility
     and oh.orderstatus in ('0','1')
     and oh.custid = in_custid
     and oh.ordertype = 'O'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item;
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
     and (instr(','||in_invstatus||',', ','||invstatus||',', 1, 1) > 0
      or in_invstatus='ALL')
     and (instr(','||in_inventoryclass||',', ','||inventoryclass||',', 1, 1) > 0
      or in_inventoryclass='ALL')
     and invstatus <> 'SU'
     and status in ('A','CM');
caq curAllocableQty%rowtype;

cursor curDueInQty(in_facility IN varchar, in_item IN varchar2, in_baseuom IN varchar2) is
  select nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0) - nvl(od.qtyrcvd,0), od.uom, in_baseuom)),0) as qtyduein,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0) - nvl(od.qtyrcvd,0), od.uom, 'PCS')),0) as qtydueinpcs,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0) - nvl(od.qtyrcvd,0), od.uom, 'CTN')),0) as qtydueinctn,
         nvl(sum(nvl(od.weight_entered_lbs,nvl(od.weightorder,0)) - nvl(od.weightrcvd,0)),0) as weightduein
    from orderhdr oh, orderdtl od
   where oh.recent_order_id like 'Y%'
     and oh.tofacility = in_facility
     and oh.orderstatus in ('0','1','3','A')
     and oh.custid = in_custid
     and oh.ordertype = 'R'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item;
cdi curDueInQty%rowtype;

cursor curOrders(in_custid IN varchar, in_facility IN varchar, in_item IN varchar2, in_baseuom IN varchar2) is
  select oh.orderid, oh.shipid, oh.reference,
         nvl(oh.shiptoname, cn.name) shiptoname, oh.shiptoname onetimeshiptoname,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, in_baseuom)),0) as qtyorder,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, 'PCS')),0) as qtyorderpcs,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, 'CTN')),0) as qtyorderctn,
         nvl(sum(nvl(od.weight_entered_lbs,nvl(od.weightorder,0))),0) as weightorder
    from orderhdr oh, orderdtl od, consignee cn
   where oh.recent_order_id like 'Y%'
     and oh.fromfacility = in_facility
     and oh.orderstatus in ('0','1')
     and oh.custid = in_custid
     and oh.ordertype = 'O'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and oh.shipto = cn.consignee(+)
   group by oh.orderid, oh.shipid, oh.reference, oh.shiptoname, cn.name
   order by oh.orderid, oh.shipid;
cord curOrders%rowtype;

numSessionId number;
dtlCount number;


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

delete from allocableinv
where sessionid = numSessionId;
commit;

delete from allocableinv
where lastupdate < trunc(sysdate);
commit;

select count(1)
into dtlCount
from allocableinv
where lastupdate < sysdate;

if dtlCount = 0 then
  EXECUTE IMMEDIATE 'truncate table allocableinv';
end if;

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
    	insert into allocableinv values(numSessionId, cf.facility, cf.name,
    	  in_custid, cu.name, cit.item, cit.descr, 0, 0, null, null, null,
    	  coq.qtyorder, caq.qtyallocable, cdi.qtyduein, cit.baseuom,
    	  coq.qtyorderpcs, caq.qtyallocablepcs, cdi.qtydueinpcs,
    	  coq.qtyorderctn, caq.qtyallocablectn, cdi.qtydueinctn, coq.weightorder, caq.weightallocable,
    	  cdi.weightduein, sysdate);
    	  
      for cord in curOrders(in_custid, cf.facility, cit.item, cit.baseuom)
      loop
      	select count(1)
      	  into dtlCount
      	  from allocableinv
      	 where sessionid = numSessionId
      	   and facility = cf.facility
      	   and custid = in_custid
      	   and item = cit.item
      	   and orderid = cord.orderid
      	   and shipid = cord.shipid;
      	
      	if (dtlCount = 0) then
        	insert into allocableinv values(numSessionId, cf.facility, cf.name,
        	  in_custid, cu.name, cit.item, cit.descr, cord.orderid, cord.shipid,
        	  cord.reference, cord.shiptoname, cord.onetimeshiptoname, cord.qtyorder,
        	  0, 0, cit.baseuom, cord.qtyorderpcs, 0, 0, cord.qtyorderctn, 0, 0, cord.weightorder,
        	  0.0, 0.0, sysdate);
        end if;
      end loop;
    end if;
  end loop;
  commit;
end loop;

commit;


open ai_cursor for
select *
   from allocableinv
  where sessionid = numSessionId
  order by facility, custid, item, orderid, shipid;

end ALLOCABLEINVBASEPROC;
end ALLOCABLEINVPKG;
/

create or replace procedure ALLOCABLEINVPROC
(ai_cursor IN OUT allocableinvpkg.ai_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_debug_yn IN varchar2)
as
begin
	ALLOCABLEINVPKG.ALLOCABLEINVBASEPROC(ai_cursor, in_custid, in_facility, 'ALL', 'ALL', in_debug_yn);
end ALLOCABLEINVPROC;
/

create or replace procedure ALLOCABLEINVAVRGPROC
(ai_cursor IN OUT allocableinvpkg.ai_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_debug_yn IN varchar2)
as
begin
	ALLOCABLEINVPKG.ALLOCABLEINVBASEPROC(ai_cursor, in_custid, in_facility, 'AV', 'RG', in_debug_yn);
end ALLOCABLEINVAVRGPROC;
/

create or replace procedure D2K_ALLOCABLEINVPROC
(ai_cursor IN OUT allocableinvpkg.ai_type
,in_custid IN varchar2
,in_facility IN varchar2
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
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, 'CTN')),0) as qtyorderctn,
         nvl(sum(nvl(od.weight_entered_lbs,nvl(od.weightorder,0))),0) as weightorder
    from orderhdr oh, orderdtl od
   where oh.recent_order_id like 'Y%'
     and oh.fromfacility = in_facility
     and oh.orderstatus in ('0','1')
     and oh.custid = in_custid
     and oh.ordertype = 'O'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item;
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
     and invstatus not in ('QC','SU')
     and status in ('A','CM');
caq curAllocableQty%rowtype;

cursor curDueInQty(in_facility IN varchar, in_item IN varchar2, in_baseuom IN varchar2) is
  select nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0) - nvl(od.qtyrcvd,0), od.uom, in_baseuom)),0) as qtyduein,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0) - nvl(od.qtyrcvd,0), od.uom, 'PCS')),0) as qtydueinpcs,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0) - nvl(od.qtyrcvd,0), od.uom, 'CTN')),0) as qtydueinctn,
         nvl(sum(nvl(nvl(od.weight_entered_lbs,nvl(od.weightorder,0)),0) - nvl(od.weightrcvd,0)),0) as weightduein
    from orderhdr oh, orderdtl od
   where oh.recent_order_id like 'Y%'
     and oh.tofacility = in_facility
     and oh.orderstatus in ('0','1','3','A')
     and oh.custid = in_custid
     and oh.ordertype = 'R'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item;
cdi curDueInQty%rowtype;

cursor curOrders(in_custid IN varchar, in_facility IN varchar, in_item IN varchar2, in_baseuom IN varchar2) is
  select oh.orderid, oh.shipid, oh.reference,
         nvl(oh.shiptoname, cn.name) shiptoname, oh.shiptoname onetimeshiptoname,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, in_baseuom)),0) as qtyorder,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, 'PCS')),0) as qtyorderpcs,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, 'CTN')),0) as qtyorderctn,
         nvl(sum(nvl(od.weight_entered_lbs,nvl(od.weightorder,0))),0) as weightorder
    from orderhdr oh, orderdtl od, consignee cn
   where oh.recent_order_id like 'Y%'
     and oh.fromfacility = in_facility
     and oh.orderstatus in ('0','1')
     and oh.custid = in_custid
     and oh.ordertype = 'O'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and oh.shipto = cn.consignee(+)
   group by oh.orderid, oh.shipid, oh.reference, oh.shiptoname, cn.name
   order by oh.orderid, oh.shipid;
cord curOrders%rowtype;

numSessionId number;
dtlCount number;


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

delete from allocableinv
where sessionid = numSessionId;
commit;

delete from allocableinv
where lastupdate < trunc(sysdate);
commit;

select count(1)
into dtlCount
from allocableinv
where lastupdate < sysdate;

if dtlCount = 0 then
  EXECUTE IMMEDIATE 'truncate table allocableinv';
end if;

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
    	insert into allocableinv values(numSessionId, cf.facility, cf.name,
    	  in_custid, cu.name, cit.item, cit.descr, 0, 0, null, null, null,
    	  coq.qtyorder, caq.qtyallocable, cdi.qtyduein, cit.baseuom,
    	  coq.qtyorderpcs, caq.qtyallocablepcs, cdi.qtydueinpcs, coq.qtyorderctn,
    	  caq.qtyallocablectn, cdi.qtydueinctn, coq.weightorder, caq.weightallocable,
    	  cdi.weightduein, sysdate);
    	  
      for cord in curOrders(in_custid, cf.facility, cit.item, cit.baseuom)
      loop
      	select count(1)
      	  into dtlCount
      	  from allocableinv
      	 where sessionid = numSessionId
      	   and facility = cf.facility
      	   and custid = in_custid
      	   and item = cit.item
      	   and orderid = cord.orderid
      	   and shipid = cord.shipid;
      	
      	if (dtlCount = 0) then
        	insert into allocableinv values(numSessionId, cf.facility, cf.name,
        	  in_custid, cu.name, cit.item, cit.descr, cord.orderid, cord.shipid,
        	  cord.reference, cord.qtyorder, cord.shiptoname, cord.onetimeshiptoname,
        	  0, 0, cit.baseuom, cord.qtyorderpcs, 0, 0, cord.qtyorderctn, 0, 0, cord.weightorder,
        	  0.0, 0.0, sysdate);
        end if;
      end loop;
    end if;
  end loop;
  commit;
end loop;

commit;


open ai_cursor for
select *
   from allocableinv
  where sessionid = numSessionId
  order by facility, custid, item, orderid, shipid;

end D2K_ALLOCABLEINVPROC;
/
create or replace procedure ALLOCABLEINVWEIGHTPROC
(ai_cursor IN OUT allocableinvpkg.ai_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_variance IN number
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
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, 'CTN')),0) as qtyorderctn,
         nvl(sum(nvl(od.weight_entered_lbs,nvl(od.weightorder,0))),0) as weightorder
    from orderhdr oh, orderdtl od
   where oh.recent_order_id like 'Y%'
     and oh.fromfacility = in_facility
     and oh.orderstatus in ('0','1')
     and oh.custid = in_custid
     and oh.ordertype = 'O'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item;
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
   where oh.recent_order_id like 'Y%'
     and oh.tofacility = in_facility
     and oh.orderstatus in ('0','1','3','A')
     and oh.custid = in_custid
     and oh.ordertype = 'R'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item;
cdi curDueInQty%rowtype;
cursor curOrders(in_custid IN varchar, in_facility IN varchar, in_item IN varchar2, in_baseuom IN varchar2) is
  select oh.orderid, oh.shipid, oh.reference,
         nvl(oh.shiptoname, cn.name) shiptoname, oh.shiptoname onetimeshiptoname,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, in_baseuom)),0) as qtyorder,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, 'PCS')),0) as qtyorderpcs,
         nvl(sum(zlbl.uom_qty_conv(in_custid, in_item, nvl(od.qtyorder,0), od.uom, 'CTN')),0) as qtyorderctn,
         nvl(sum(nvl(od.weight_entered_lbs,nvl(od.weightorder,0))),0) as weightorder
    from orderhdr oh, orderdtl od, consignee cn
   where oh.recent_order_id like 'Y%'
     and oh.fromfacility = in_facility
     and oh.orderstatus in ('0','1')
     and oh.custid = in_custid
     and oh.ordertype = 'O'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and oh.shipto = cn.consignee(+)
   group by oh.orderid, oh.shipid, oh.reference, oh.shiptoname, cn.name
   order by oh.orderid, oh.shipid;
cord curOrders%rowtype;
numSessionId number;
dtlCount number;
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
delete from allocableinv
where sessionid = numSessionId;
commit;
delete from allocableinv
where lastupdate < trunc(sysdate);
commit;
select count(1)
into dtlCount
from allocableinv
where lastupdate < sysdate;
if dtlCount = 0 then
  EXECUTE IMMEDIATE 'truncate table allocableinv';
end if;
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
    	insert into allocableinv values(numSessionId, cf.facility, cf.name,
    	  in_custid, cu.name, cit.item, cit.descr, 0, 0, null, null, null,
    	  coq.qtyorder, caq.qtyallocable, cdi.qtyduein, cit.baseuom,
    	  coq.qtyorderpcs, caq.qtyallocablepcs, cdi.qtydueinpcs,
    	  coq.qtyorderctn, caq.qtyallocablectn, cdi.qtydueinctn, coq.weightorder, caq.weightallocable,
    	  cdi.weightduein, sysdate);
      for cord in curOrders(in_custid, cf.facility, cit.item, cit.baseuom)
      loop
      	select count(1)
      	  into dtlCount
      	  from allocableinv
      	 where sessionid = numSessionId
      	   and facility = cf.facility
      	   and custid = in_custid
      	   and item = cit.item
      	   and orderid = cord.orderid
      	   and shipid = cord.shipid;
      	if (dtlCount = 0) then
        	insert into allocableinv values(numSessionId, cf.facility, cf.name,
        	  in_custid, cu.name, cit.item, cit.descr, cord.orderid, cord.shipid,
        	  cord.reference, cord.shiptoname, cord.onetimeshiptoname, cord.qtyorder,
        	  0, 0, cit.baseuom, cord.qtyorderpcs, 0, 0, cord.qtyorderctn, 0, 0, cord.weightorder,
        	  0.0, 0.0, sysdate);
        end if;
      end loop;
    end if;
  end loop;
  commit;
end loop;
commit;
open ai_cursor for
select *
   from allocableinv
  where sessionid = numSessionId
  order by facility, custid, item, orderid, shipid;
end ALLOCABLEINVWEIGHTPROC;
/

create or replace procedure ALLOCABLEINVORDERSPROC
(aio_cursor IN OUT allocableinvpkg.aio_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_debug_yn IN varchar2)
as

cursor curAllocableInv(in_session IN number) is
  select distinct custid, facility, item
    from allocableinv
   where sessionid = in_session
   order by custid, facility, item;
cai curAllocableInv%rowtype;

cursor curOrderedQty(in_custid IN varchar, in_facility IN varchar, in_item IN varchar2) is
  select oh.orderid, oh.shipid, oh.reference,
         nvl(oh.shiptoname, cn.name) shiptoname, oh.shiptoname onetimeshiptoname,
         nvl(sum(zlbl.uom_qty_conv(in_custid, od1.item, nvl(od1.qtyorder,0), od1.uom, ci.baseuom)),0) as qtyorder,
         nvl(sum(zlbl.uom_qty_conv(in_custid, od1.item, nvl(od1.qtyorder,0), od1.uom, 'PCS')),0) as qtyorderpcs,
         nvl(sum(zlbl.uom_qty_conv(in_custid, od1.item, nvl(od1.qtyorder,0), od1.uom, 'CTN')),0) as qtyorderctn,
         nvl(sum(nvl(od1.weight_entered_lbs,nvl(od1.weightorder,0))),0) as weightorder
    from orderhdr oh, orderdtl od1, custitem ci, consignee cn
   where oh.recent_order_id like 'Y%'
     and oh.fromfacility = in_facility
     and oh.orderstatus in ('0','1')
     and oh.custid = in_custid
     and oh.ordertype = 'O'
     and od1.orderid = oh.orderid
     and od1.shipid = oh.shipid
     and ci.custid = in_custid
     and ci.item = od1.item
     and exists (select 1
                   from orderdtl od2
                  where od2.orderid = od1.orderid
                    and od2.shipid = od1.shipid
                    and od2.item = in_item)
     and oh.shipto = cn.consignee(+)
   group by oh.orderid, oh.shipid, oh.reference, oh.shiptoname, cn.name
   order by oh.orderid, oh.shipid;
coq curOrderedQty%rowtype;

numSessionId number;
dtlCount number;


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

delete from allocableinvorders
where sessionid = numSessionId;
commit;

delete from allocableinvorders
where lastupdate < trunc(sysdate);
commit;

select count(1)
into dtlCount
from allocableinvorders
where lastupdate < sysdate;

if dtlCount = 0 then
  EXECUTE IMMEDIATE 'truncate table allocableinvorders';
end if;

for cai in curAllocableInv(numSessionId)
loop
  for coq in curOrderedQty(cai.custid, cai.facility, cai.item)
  loop
  	select count(1)
  	  into dtlCount
  	  from allocableinvorders
  	 where sessionid = numSessionId
  	   and facility = cai.facility
  	   and custid = cai.custid
  	   and orderid = coq.orderid
  	   and shipid = coq.shipid;
  	
  	if (dtlCount = 0) then
      insert into allocableinvorders values(numSessionId, cai.facility, cai.custid,
        coq.orderid, coq.shipid, coq.reference, coq.shiptoname, coq.onetimeshiptoname,
        coq.qtyorder, coq.qtyorderpcs, coq.qtyorderctn, coq.weightorder, sysdate);
    end if;
  end loop;
end loop;

commit;


open aio_cursor for
select *
   from allocableinvorders
  where sessionid = numSessionId
  order by facility, custid, orderid, shipid;

end ALLOCABLEINVORDERSPROC;
/

show errors package ALLOCABLEINVPKG;
show errors procedure ALLOCABLEINVPROC;
show errors procedure ALLOCABLEINVAVRGPROC;
show errors procedure D2K_ALLOCABLEINVPROC;
show errors procedure ALLOCABLEINVWEIGHTPROC;
show errors procedure ALLOCABLEINVORDERSPROC;
show errors package body ALLOCABLEINVPKG;
exit;
