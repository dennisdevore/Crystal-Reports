drop table preorder;

create table preorder
(sessionid       number
,facility        varchar2(3)
,custid          varchar2(10)
,consignee       varchar2(10)
,shipto          varchar2(10)
,orderid         number
,shipid          number
,shipdate        date
,item            varchar2(50)
,lotnumber       varchar2(30)
,qtyneeded       number
,qtyallocated    number
,qtypreorder     number
,reference       varchar2(20)
,po              varchar2(20)
,carrier         varchar2(10)
,apptdate        date
,lastupdate      date
);

create index preordersessnid_idx
 on preorder(sessionid,orderid,shipid,item);

create index preorderlstpdt_idx
 on preorder(lastupdate);


create or replace package preorderPKG 
as type po_type is ref cursor return preorder%rowtype;
end preorderpkg;
/

create or replace procedure preorderPROC
(po_cursor IN OUT preorderPKG.po_type
,in_custid IN varchar2
,in_orderid IN varchar2
,in_item IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2)
as

cursor curCustomer is
  select custid
    from customer
   where custid = in_custid
      or in_custid = 'ALL';
cu curCustomer%rowtype;

cursor curAllOrders(in_custid IN varchar2) is
  select oh.fromfacility,oh.custid,oh.consignee,nvl(oh.shipto,substr(oh.shiptoname,1,8)) as shipto,
         oh.orderid,oh.shipid,oh.shipdate,od.item,od.lotnumber,oh.reference,oh.po,oh.carrier,
         (nvl(od.qtyorder,0) - nvl(od.qtypick,0)) as qty,nvl(oh.apptdate,oh.shipdate) as apptdate
    from orderhdr oh, orderdtl od
   where oh.orderstatus = '4'
     and oh.custid = in_custid
     and (od.item = in_item
      or  in_item = 'ALL')
     and oh.orderid = od.orderid
     and oh.shipid = od.shipid
     and nvl(od.qtyorder,0) <> nvl(od.qtypick,0)
     and oh.shipdate >= trunc(in_begdate)
     and trunc(oh.shipdate) <= trunc(in_enddate)
   order by oh.wave, oh.orderid, oh.shipid;
cao curAllOrders%rowtype;

cursor curOneOrder(in_orderid IN number) is
  select oh.fromfacility,oh.custid,oh.consignee,nvl(oh.shipto,substr(oh.shiptoname,1,8)) as shipto,
         oh.orderid,oh.shipid,oh.shipdate,od.item,od.lotnumber,oh.reference,oh.po,oh.carrier,
         (nvl(od.qtyorder,0) - nvl(od.qtypick,0)) as qty,nvl(oh.apptdate,oh.shipdate) as apptdate
    from orderhdr oh, orderdtl od
   where oh.orderid = in_orderid
     and oh.orderstatus = '4'
     and (oh.custid = in_custid
      or  in_custid = 'ALL')
     and (od.item = in_item
      or  in_item = 'ALL')
     and oh.orderid = od.orderid
     and oh.shipid = od.shipid
     and nvl(od.qtyorder,0) <> nvl(od.qtypick,0)
     and oh.shipdate >= trunc(in_begdate)
     and trunc(oh.shipdate) <= trunc(in_enddate)
   order by oh.wave, oh.orderid, oh.shipid;
coo curOneOrder%rowtype;

numSessionId number;
preorderQty number;
unpickedQty number;
neededQty number;
availableQty number;
allocatedQty number;
numOrderId number;

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

delete from preorder
where sessionid = numSessionId;
commit;

delete from preorder
where lastupdate < trunc(sysdate);
commit;

if in_orderid = 'ALL' then
	debugmsg('Processing ALL orders');
	for cu in curCustomer
	loop
    debugmsg('Processing custid ' || cu.custid);
			for coa in curAllOrders(cu.custid)
			loop
        debugmsg('Order ' || to_char(coa.orderid) || '-' || to_char(coa.shipid) || ' item ' || coa.item  || ' found. qty ' || to_char(coa.qty));
				preorderQty := coa.qty;
				
				select nvl(sum(quantity),0)
				  into unpickedQty
				  from shippingplate
				 where facility = coa.fromfacility
				   and custid = coa.custid
				   and orderid = coa.orderid
				   and shipid = coa.shipid
				   and item = coa.item
				   and nvl(orderlot,'(none)') = nvl(coa.lotnumber,'(none)')
				   and status = 'U';
				
        debugmsg('Removing ' || to_char(unpickedQty) || ' unpicked');
				preorderQty := preorderQty - unpickedQty;
				neededQty := preorderQty;
				
				if neededQty > 0 then
					select nvl(sum(qty),0)
					  into availableQty
					  from custitemtotsumavailview
					 where custid = coa.custid
					   and facility = coa.fromfacility
					   and item = coa.item
				     and nvl(lotnumber,'(none)') = nvl(coa.lotnumber,'(none)')
					   and invstatus='AV';
					
          debugmsg(to_char(availableQty) || ' available');
          
					select nvl(sum(qtyallocated),0)
   				  into allocatedQty
    			  from preorder
		  		 where numSessionId = numSessionId
		  		   and custid = coa.custid
			  	   and facility = coa.fromfacility
				     and item = coa.item
				     and nvl(lotnumber,'(none)') = nvl(coa.lotnumber,'(none)');
				     
          debugmsg(to_char(allocatedQty) || ' allocated');
          
					availableQty := availableQty - allocatedQty;
					
					if availableQty > 0 then
            debugmsg('Removing ' || to_char(availableQty) || ' available');
					  preorderQty := preOrderQty - availableQty;
					end if;
					
					if preorderQty < 0 then
						preorderQty := 0;
					end if;
					
          debugmsg('Preorder ' || to_char(preorderQty));
      
					insert into preorder
					  values (
              numSessionId,
              coa.fromfacility,
              coa.custid,
              coa.consignee,
              coa.shipto,
              coa.orderid,
              coa.shipid,
              coa.shipdate,
              coa.item,
              coa.lotnumber,
              neededQty,
              neededQty - preorderQty,
              preorderQty,
              coa.reference,
              coa.po,
              coa.carrier,
              coa.apptdate,
              sysdate);
				end if;
		end loop;
	end loop;
else
	numOrderId := to_number(in_orderid);
	debugmsg('Processing order ' || in_orderid);
	for coo in curOneOrder(numOrderId)
	loop
    debugmsg('Order ' || to_char(coo.orderid) || '-' || to_char(coo.shipid) || ' item ' || coo.item || ' found. qty ' || to_char(coo.qty));
		preorderQty := coo.qty;
		
		select nvl(sum(quantity),0)
		  into unpickedQty
		  from shippingplate
		 where facility = coo.fromfacility
		   and custid = coo.custid
		   and orderid = coo.orderid
		   and shipid = coo.shipid
		   and item = coo.item
			 and nvl(orderlot,'(none)') = nvl(coo.lotnumber,'(none)')
		   and status = 'U';
		
    debugmsg('Removing ' || to_char(unpickedQty) || ' unpicked');
		preorderQty := preOrderQty - unpickedQty;
		neededQty := preorderQty;
		
		if neededQty > 0 then
			select nvl(sum(qty),0)
			  into availableQty
			  from custitemtotsumavailview
			 where custid = coo.custid
			   and facility = coo.fromfacility
			   and item = coo.item
			   and nvl(lotnumber,'(none)') = nvl(coo.lotnumber,'(none)')
			   and invstatus='AV';
			   
      debugmsg(to_char(availableQty) || ' available');
      
			select nvl(sum(qtyallocated),0)
			  into allocatedQty
			  from preorder
  		 where numSessionId = numSessionId
		  	 and custid = coo.custid
	  	   and facility = coo.fromfacility
		     and item = coo.item
			   and nvl(lotnumber,'(none)') = nvl(coo.lotnumber,'(none)');
		     
      debugmsg(to_char(allocatedQty) || ' allocated');
      
			availableQty := availableQty - allocatedQty;
			
			if availableQty > 0 then
        debugmsg('Removing ' || to_char(availableQty) || ' available');
			  preorderQty := preOrderQty - availableQty;
		  end if;
			
			if preorderQty < 0 then
				preorderQty := 0;
			end if;

      debugmsg('Preorder ' || to_char(preorderQty));
      
			insert into preorder
			  values (
          numSessionId,
          coo.fromfacility,
          coo.custid,
          coo.consignee,
          coo.shipto,
          coo.orderid,
          coo.shipid,
          coo.shipdate,
          coo.item,
          coo.lotnumber,
          neededQty,
          neededQty - preorderQty,
          preorderQty,
          coo.reference,
          coo.po,
          coo.carrier,
          coo.apptdate,
          sysdate);

		end if;
  end loop;
end if;


open po_cursor for
select sessionid
,facility
,custid
,consignee
,shipto
,orderid
,shipid
,shipdate
,item
,null lotnumber
,sum(qtyneeded) qtyneeded
,sum(qtyallocated) qtyallocated
,sum(qtypreorder) qtypreorder
,reference
,po
,carrier
,apptdate
,sysdate lastupdate
   from preorder
  where sessionid = numSessionId
    and qtypreorder > 0
  group by sessionid,facility,custid,consignee,shipto,orderid,shipid,shipdate,
           item,reference,po,carrier,apptdate
  order by custid,orderid,shipid,item,shipdate;

exception when others then
  null;
end preorderPROC;
/
show errors package preorderPKG;
show errors procedure preorderPROC;
exit;
