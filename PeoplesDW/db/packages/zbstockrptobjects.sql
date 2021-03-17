drop table bstockrpt;

create table bstockrpt
(sessionid       number
,facility        varchar2(3)
,custid          varchar2(10)
,item            varchar2(50)
,lotnumber       varchar2(30)
,uom             varchar2(4)
,invstatus       varchar2(2)
,inventoryclass  varchar2(2)
,serialnumber    varchar2(30)
,itemdesc        varchar2(255)
,custname        varchar2(40)
,custaddr1       varchar2(40)
,custaddr2       varchar2(40)
,custcity        varchar2(30)
,custstate       varchar2(5)
,custzip         varchar2(12)
,ship_orderid    number(9)
,ship_shipid     number(2)
,ship_date       date
,ship_qty        number(10)
,ship_weight     number(17,8)
,return_orderid  number(9)
,return_shipid   number(2)
,return_date     date
,return_qty      number(10)
,return_weight   number(17,8)
,bstock_date     date
,bstock_month    varchar2(8)
,bstock_month_pr varchar2(10)
,bstock_qty      number(7)
,datediff        number(6)
,lastupdate      date
);

create index bstockrpt_sessionid_idx
 on bstockrpt(sessionid,item,serialnumber);

create index bstockrpt_lastupdate_idx
 on bstockrpt(lastupdate);

create or replace package BSTOCKRPTPKG
--
-- $Id: zbstockrptobjects.sql 0 2007-03-13 00:00:00Z eric $
--
as type bsr_type is ref cursor return bstockrpt%rowtype;
end BSTOCKRPTPKG;
/

create or replace procedure BSTOCKRPTPROC
(aoi_cursor  IN OUT bstockrptpkg.bsr_type
,in_facility IN varchar2
,in_custid   IN varchar2
,in_begdate  IN date
,in_enddate  IN date
,in_debug_yn IN varchar2)
as

cursor curFacility is
  select facility
    from facility
   where instr(','||upper(in_facility)||',', ','||facility||',', 1, 1) > 0
      or upper(in_facility)='ALL';
cf curFacility%rowtype;

cursor curCustomer is
  select *
    from customer
   where instr(','||upper(in_custid)||',', ','||custid||',', 1, 1) > 0
      or upper(in_custid)='ALL';
cu curCustomer%rowtype;

cursor curInvAdjActivity(in_facility IN varchar2, in_custid IN varchar2) is
	select whenoccurred,
	       lpid,
	       custid,
	       item,
	       uom,
	       invstatus,
	       inventoryclass,
	       lotnumber,
	       adjreason,
	       adjqty
    from invadjactivity iaa 
   where iaa.facility = in_facility
     and iaa.custid = in_custid
     and iaa.item like 'B%'
     and iaa.whenoccurred >= trunc(in_begdate)
     and iaa.whenoccurred <= trunc(in_enddate)
     and invstatus != 'SU'
     and adjreason = 'RI'
     and adjqty > 0 
   order by custid, item;
ciaa curInvAdjActivity%rowtype;

cursor curRcptPlate(in_lpid IN varchar2, in_whenoccurred IN date) is
  select oh.orderid, oh.shipid, odr.serialnumber,trunc(ld.rcvddate) as rcvddate,
         nvl(sum(odr.qtyrcvd),0) as quantity,
         nvl(sum(odr.weight),0) as weight 
    from loads ld, orderhdr oh, orderdtl od, orderdtlrcpt odr
   where ld.loadno = oh.loadno
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and odr.orderid = od.orderid
     and odr.shipid = od.shipid
     and odr.item = od.item
     and nvl(odr.orderlot,'(none)') = nvl(od.lotnumber,'(none)')
     and odr.lpid = in_lpid
     and odr.lastupdate <= in_whenoccurred
   group by oh.orderid,oh.shipid,odr.serialnumber,trunc(ld.rcvddate)
   union
  select oh.orderid, oh.shipid, odr.serialnumber,trunc(od.statusupdate) as rcvddate,
         nvl(sum(odr.qtyrcvd),0) as quantity,
         nvl(sum(odr.weight),0) as weight 
    from orderhdr oh, orderdtl od, orderdtlrcpt odr
   where oh.loadno is null
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and odr.orderid = oh.orderid
     and odr.shipid = oh.shipid
     and odr.item = od.item
     and nvl(odr.orderlot,'(none)') = nvl(od.lotnumber,'(none)')
     and odr.lpid = in_lpid
     and odr.lastupdate <= in_whenoccurred
   group by oh.orderid,oh.shipid,odr.serialnumber,trunc(od.statusupdate)
   order by rcvddate desc;
crp curRcptPlate%rowtype;

cursor curItem(in_custid IN varchar2, in_item IN varchar2) is
  select *
    from custitem
   where custid = in_custid
     and item = in_item;
cit curItem%rowtype;

cursor curShippingPlates(in_item IN varchar2, in_serialnumber IN varchar2, in_rcvddate IN date) is
	select oh.orderid, oh.shipid, trunc(oh.dateshipped) as dateshipped,
         nvl(sum(sp.quantity),0) as quantity,
         nvl(sum(sp.weight),0) as weight
    from shippingplate sp, orderhdr oh
   where sp.serialnumber = in_serialnumber
     and sp.item = in_item
     and oh.orderid = sp.orderid
     and oh.shipid = sp.shipid
     and trunc(oh.dateshipped) < in_rcvddate
   group by oh.orderid, oh.shipid, trunc(oh.dateshipped)
   order by oh.orderid, oh.shipid;
sp curShippingPlates%rowtype;
	       
numSessionId number;
wrk returnsrpt%rowtype;
dtlCount integer;
recCount integer;


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

delete from bstockrpt
where sessionid = numSessionId;
commit;

delete from bstockrpt
where lastupdate < trunc(sysdate);
commit;

select count(1)
into dtlCount
from bstockrpt
where lastupdate < sysdate;

if dtlCount = 0 then
  EXECUTE IMMEDIATE 'truncate table bstockrpt';
end if;

cu := null;
cit := null;

for cf in curFacility
loop
	for cu in curCustomer
	loop
    for ciaa in curInvAdjActivity(cf.facility,cu.custid)
    loop
    	if ciaa.item <> cit.item then
    		open curItem(ciaa.custid, ciaa.item);
        fetch curItem into cit;
        close curItem;
      end if;
      
      crp := null;
      open curRcptPlate(ciaa.lpid, ciaa.whenoccurred);
      fetch curRcptPlate into crp;
      close curRcptPlate;
  
    	 open curShippingPlates(substr(ciaa.item,2), crp.serialnumber, crp.rcvddate);
    	 fetch curShippingPlates into sp;
    	 close curShippingPlates;
    	 
    	 insert into bstockrpt values
       (numSessionId,cf.facility,ciaa.custid,ciaa.item,ciaa.lotnumber,ciaa.uom,ciaa.invstatus,
        ciaa.inventoryclass,crp.serialnumber,cit.descr,
        cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
        sp.orderid,sp.shipid,sp.dateshipped,sp.quantity,sp.weight,
        crp.orderid,crp.shipid,crp.rcvddate,crp.quantity,crp.weight,
        trunc(ciaa.whenoccurred),to_char(ciaa.whenoccurred,'YYYYMM'),to_char(ciaa.whenoccurred,'MM/YYYY'),
        ciaa.adjqty,(crp.rcvddate-sp.dateshipped),sysdate);
      commit;
    end loop;
  end loop;
end loop;

commit;

open aoi_cursor for
select *
   from bstockrpt
  where sessionid = numSessionId
  order by facility,custid,item,bstock_month,serialnumber;

end BSTOCKRPTPROC;
/

show errors package BSTOCKRPTPKG;
show errors procedure BSTOCKRPTPROC;
exit;
