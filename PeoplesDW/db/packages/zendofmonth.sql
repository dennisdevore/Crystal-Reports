drop table endofmonth;

create table endofmonth
(sessionid       number
,facility        varchar2(3)
,custid          varchar2(10)
,item            varchar2(50)
,itemdesc        varchar2(255)
,codedate        varchar2(20)
,lotnumber       varchar2(30)
,uom             varchar2(4)
,qtytotal        number(10)
,qtyhold         number(10)
,lastupdate      date
);

create index endofmonthsesessnid_idx
 on endofmonth(sessionid,facility,custid,item,codedate,lotnumber);

create index endofmonthlstpdt_idx
 on endofmonth(lastupdate);


create or replace package zendofmonthPKG 
as type eom_type is ref cursor return endofmonth%rowtype;
end zendofmonthpkg;
/

create or replace procedure zendofmonthPROC
(eom_cursor IN OUT zendofmonthpkg.eom_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_enddate IN date
,in_debug_yn IN varchar2)
as

cursor curCustItems is
   select item,descr,baseuom
    from custitem
   where custid = in_custid
   order by item;
cci curCustItems%rowtype;

cursor curAsOfInventory(in_item IN varchar2) is
  select invstatus,lotnumber,sum(zci.item_base_qty(custid,item,uom,currentqty)) as currentqty
    from asofinventory
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and trunc(effdate) <= trunc(in_enddate)
   group by invstatus,lotnumber
   order by invstatus,lotnumber;
caoi curAsOfInventory%rowtype;

cursor curPlate(in_item IN varchar2, in_lotnumber IN varchar2) is
  select useritem1 as codedate
    from dre_allplateview
   where item = in_item
     and custid = in_custid
     and facility = in_facility
     and nvl(lotnumber,'x') = nvl(in_lotnumber,'x');
cp curPlate%rowtype;

numSessionId number;
holdQty number;
eomCount number;

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

delete from endofmonth
where sessionid = numSessionId;
commit;

delete from endofmonth
where lastupdate < trunc(sysdate);
commit;

for cci in curCustItems
loop
  debugmsg('processing item for begin bal ' || cci.item);
  for caoi in curAsOfInventory(cci.item)
  loop
  	if ( caoi.invstatus in ('OH', 'QA', 'QC') ) then
  		holdQty := caoi.currentqty;
  	else
  		holdQty := 0;
  	end if;
  	
    open curPlate(cci.item, caoi.lotnumber);
    fetch curPlate into cp;
    close curPlate;
    
    select count(1)
      into eomCount
      from endofmonth
     where sessionid = numSessionId
       and facility = in_facility
       and custid = in_custid
       and item = cci.item
       and nvl(codedate,'x') = nvl(cp.codedate,'x')
       and nvl(lotnumber,'x') = nvl(caoi.lotnumber,'x');
       
 	  if ( eomCount = 0 ) then
 	    insert into endofmonth values
          (numSessionId
          ,in_facility
          ,in_custid
          ,cci.item
          ,cci.descr
          ,cp.codedate
          ,caoi.lotnumber
          ,cci.baseuom
          ,caoi.currentqty
          ,holdQty
          ,sysdate);
    else
    	update endofmonth
    	   set qtytotal = qtytotal + caoi.currentqty,
    	       qtyhold = qtyhold + holdQty,
    	       lastupdate = sysdate
    	 where sessionid = numSessionId
 	       and facility = in_facility
 	       and custid = in_custid
 	       and item = cci.item
 	       and nvl(codedate,'x') = nvl(cp.codedate,'x')
 	       and nvl(lotnumber,'x') = nvl(caoi.lotnumber,'x');
    end if;
  end loop;
  commit;
end loop;

open eom_cursor for
select sessionid
,facility
,custid
,item
,itemdesc
,codedate
,lotnumber
,uom
,qtytotal
,qtyhold
,lastupdate
   from endofmonth
  where sessionid = numSessionId
    and (qtytotal <> 0 or
         qtyhold <> 0)
  order by item,codedate,lotnumber;

end zendofmonthPROC;
/
show errors package zendofmonthPKG;
show errors procedure zendofmonthPROC;
exit;
