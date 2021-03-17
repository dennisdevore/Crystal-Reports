drop table returnsrpt;

create table returnsrpt
(sessionid       number
,facility        varchar2(3)
,custid          varchar2(10)
,item            varchar2(50)
,lotnumber       varchar2(30)
,uom             varchar2(4)
,invstatus       varchar2(2)
,inventoryclass  varchar2(2)
,serialnumber    varchar2(30)
,rma             varchar2(20)
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
,return_month    varchar2(6)
,return_month_pr varchar2(7)
,reason          varchar2(12)
,datediff        number(6)
,lastupdate      date
);

create index returnsrpt_sessionid_idx
 on returnsrpt(sessionid,item,serialnumber);

create index returnsrpt_lastupdate_idx
 on returnsrpt(lastupdate);

create or replace package RETURNSRPTPKG
--
-- $Id: zreturnsrptobjects.sql 0 2007-03-09 00:00:00Z eric $
--
as type rr_type is ref cursor return returnsrpt%rowtype;
  procedure RETURNSRPTPROC
    (aoi_cursor  IN OUT returnsrptpkg.rr_type
    ,in_custid   IN varchar2
    ,in_facility IN varchar2
    ,in_begdate  IN date
    ,in_enddate  IN date
    ,in_reason   IN varchar2
    ,in_debug_yn IN varchar2);
end RETURNSRPTPKG;
/

create or replace procedure RETURNSRPTPROC
(aoi_cursor  IN OUT returnsrptpkg.rr_type
,in_custid   IN varchar2
,in_facility IN varchar2
,in_begdate  IN date
,in_enddate  IN date
,in_reason   IN varchar2
,in_debug_yn IN varchar2)
as

cursor curFacility is
  select facility
    from facility
   where instr(','||upper(in_facility)||',', ','||facility||',', 1, 1) > 0
      or upper(in_facility)='ALL'
   order by facility;
cf curFacility%rowtype;

cursor curCustomer is
  select *
    from customer
   where instr(','||upper(in_custid)||',', ','||custid||',', 1, 1) > 0
      or upper(in_custid)='ALL'
   order by custid;
cu curCustomer%rowtype;

cursor curItem(in_custid IN varchar2) is
  select *
    from custitem
   where custid = in_custid
   order by custid, item;
cit curItem%rowtype;

cursor curItemDescr(in_custid IN varchar2, in_item IN varchar2) is
  select descr
    from custitem
   where custid = in_custid
     and item = in_item;
citd curItemDescr%rowtype;

cursor curAsOfDtlActivity(in_facility IN varchar, in_custid IN varchar2, in_item IN varchar2) is
  select aoi1.uom,
         aoi1.invstatus,
         aoi1.inventoryclass,
         aoi1.lotnumber,
         aoi1.effdate,
         aoi1.trantype,
         nvl(aoi1.lpid, '(none)') as lpid,
         count(1) as thecount
    from asofinventorydtl aoi1
   where aoi1.facility = in_facility
     and aoi1.custid = in_custid
     and aoi1.item = in_item
     and aoi1.effdate between trunc(in_begdate) and trunc(in_enddate)
     and aoi1.invstatus != 'SU'
     and (upper(in_reason) = upper(aoi1.reason)
      or  upper(in_reason) = 'ALL')
     and (aoi1.adjustment < 0 
      or  upper(aoi1.reason) = 'RETURNS')
     and upper(aoi1.reason) in('RETURNS','REIDENTIFY','DAMAGED')
     and exists (select 1
                   from asofinventorydtl aoi2
                  where aoi2.facility = in_facility
                    and aoi2.custid = in_custid
                    and aoi2.item = in_item
                    and nvl(aoi2.lotnumber,'(none)') = nvl(aoi1.lotnumber,'(none)')
                    and aoi2.uom = aoi1.uom
                    and aoi2.effdate <= aoi1.effdate
                    and nvl(aoi2.invstatus,'(none)') = nvl(aoi1.invstatus,'(none)')
                    and nvl(aoi2.inventoryclass,'(none)') = nvl(aoi1.inventoryclass,'(none)')
                    and trantype = 'RT')
group by aoi1.uom,
         aoi1.invstatus,
         aoi1.inventoryclass,
         aoi1.lotnumber,
         aoi1.effdate,
         aoi1.trantype,
         nvl(aoi1.lpid, '(none)');
casof curAsOfDtlActivity%rowtype;

cursor curAsOfRcptActivity(in_facility IN varchar2, in_custid IN varchar2, in_item IN varchar2, in_lotnumber IN varchar2,
  in_uom IN varchar2, in_invstatus IN varchar2, in_inventoryclass IN varchar2, in_effdate IN date, in_lpid IN varchar2) is
  select effdate,
         trunc(lastupdate) as lastupdate,
         sum(adjustment) adjustment,
         sum(nvl(weightadjustment,zci.item_weight(custid,item,uom)*adjustment)) weightadjustment
    from asofinventorydtl aoi
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
     and uom = in_uom
     and effdate <= trunc(in_effdate)
     and nvl(invstatus,'(none)') = nvl(in_invstatus,'(none)')
     and nvl(inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
     and trantype = 'RT'
     and nvl(lpid,'(none)') = in_lpid
     and in_lpid = '(none)'
   group by effdate,
            trunc(lastupdate)
union
  select effdate,
         trunc(lastupdate) as lastupdate,
         sum(adjustment) adjustment,
         sum(nvl(weightadjustment,zci.item_weight(custid,item,uom)*adjustment)) weightadjustment
    from asofinventorydtl aoi
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
     and uom = in_uom
     and effdate <= trunc(in_effdate)
     and trantype = 'RT'
     and nvl(lpid,'(none)') = in_lpid
     and in_lpid <> '(none)'
   group by effdate,
            trunc(lastupdate)
   order by effdate desc;
casofr curAsOfRcptActivity%rowtype;

cursor curReturnPlates(in_facility IN varchar2, in_custid IN varchar2, in_item IN varchar2, in_lotnumber IN varchar2,
  in_uom IN varchar2, in_invstatus IN varchar2, in_inventoryclass IN varchar2,
  in_lastupdate IN date, in_effdate IN date, in_lpid IN varchar2) is
  select oh.orderid,oh.shipid,oh.rma,odr.serialnumber,trunc(ld.rcvddate) as rcvddate,odr.lpid,
         nvl(sum(odr.qtyrcvd),0) as quantity,
         nvl(sum(odr.weight),0) as weight
    from loads ld, orderhdr oh, orderdtl od, orderdtlrcpt odr
   where trunc(ld.lastupdate) = in_lastupdate
     and trunc(ld.rcvddate) = in_effdate
     and ld.loadtype in ('INC','INT')
     and ld.loadstatus = 'R'
     and ld.facility = in_facility
     and oh.loadno = ld.loadno
     and oh.custid = in_custid
     and oh.tofacility = ld.facility
     and oh.orderstatus = 'R'
     and oh.ordertype = 'Q'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and nvl(od.qtyrcvd,0) != 0
     and odr.orderid = od.orderid
     and odr.shipid = od.shipid
     and odr.item = od.item
     and nvl(odr.orderlot,'(none)') = nvl(od.lotnumber,'(none)')
     and nvl(odr.lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
     and nvl(odr.invstatus,'(none)') = nvl(in_invstatus,'(none)')
     and nvl(odr.inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
     and odr.uom = in_uom
     and nvl(odr.lpid,'(none)') = in_lpid
     and in_lpid = '(none)'
   group by oh.orderid,oh.shipid,oh.rma,odr.serialnumber,trunc(ld.rcvddate),odr.lpid
   union
  select oh.orderid,oh.shipid,oh.rma,odr.serialnumber,trunc(od.statusupdate) as rcvddate,odr.lpid,
         nvl(sum(odr.qtyrcvd),0) as quantity,
         nvl(sum(odr.weight),0) as weight
    from orderhdr oh, orderdtl od, orderdtlrcpt odr
   where trunc(oh.lastupdate) = in_lastupdate
     and oh.loadno is null
     and oh.ordertype='Q'
     and oh.orderstatus = 'R'
     and oh.custid = in_custid
     and oh.tofacility = in_facility
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and trunc(od.statusupdate) = in_effdate
     and nvl(od.qtyrcvd,0) != 0
     and odr.orderid = od.orderid
     and odr.shipid = od.shipid
     and odr.item = od.item
     and nvl(odr.orderlot,'(none)') = nvl(od.lotnumber,'(none)')
     and nvl(odr.lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
     and nvl(odr.invstatus,'(none)') = nvl(in_invstatus,'(none)')
     and nvl(odr.inventoryclass,'(none)') = nvl(in_inventoryclass,'(none)')
     and odr.uom = in_uom
     and nvl(odr.lpid,'(none)') = in_lpid
     and in_lpid = '(none)'
   group by oh.orderid,oh.shipid,oh.rma,odr.serialnumber,trunc(od.statusupdate),odr.lpid
union
  select oh.orderid,oh.shipid,oh.rma,odr.serialnumber,trunc(ld.rcvddate) as rcvddate,odr.lpid,
         nvl(sum(odr.qtyrcvd),0) as quantity,
         nvl(sum(odr.weight),0) as weight
    from loads ld, orderhdr oh, orderdtl od, orderdtlrcpt odr
   where trunc(ld.lastupdate) = in_lastupdate
     and trunc(ld.rcvddate) = in_effdate
     and ld.loadtype in ('INC','INT')
     and ld.loadstatus = 'R'
     and ld.facility = in_facility
     and oh.loadno = ld.loadno
     and oh.custid = in_custid
     and oh.tofacility = ld.facility
     and oh.orderstatus = 'R'
     and oh.ordertype = 'Q'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and nvl(od.qtyrcvd,0) != 0
     and odr.orderid = od.orderid
     and odr.shipid = od.shipid
     and odr.item = od.item
     and nvl(odr.orderlot,'(none)') = nvl(od.lotnumber,'(none)')
     and nvl(odr.lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
     and odr.uom = in_uom
     and nvl(odr.lpid,'(none)') = in_lpid
     and in_lpid <> '(none)'
   group by oh.orderid,oh.shipid,oh.rma,odr.serialnumber,trunc(ld.rcvddate),odr.lpid
union
  select oh.orderid,oh.shipid,oh.rma,odr.serialnumber,trunc(od.statusupdate) as rcvddate,odr.lpid,
         nvl(sum(odr.qtyrcvd),0) as quantity,
         nvl(sum(odr.weight),0) as weight
    from orderhdr oh, orderdtl od, orderdtlrcpt odr
   where trunc(oh.lastupdate) = in_lastupdate
     and oh.loadno is null
     and oh.ordertype='Q'
     and oh.orderstatus = 'R'
     and oh.custid = in_custid
     and oh.tofacility = in_facility
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and trunc(od.statusupdate) = in_effdate
     and nvl(od.qtyrcvd,0) != 0
     and odr.orderid = od.orderid
     and odr.shipid = od.shipid
     and odr.item = od.item
     and nvl(odr.orderlot,'(none)') = nvl(od.lotnumber,'(none)')
     and nvl(odr.lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
     and odr.uom = in_uom
     and nvl(odr.lpid,'(none)') = in_lpid
     and in_lpid <> '(none)'
   group by oh.orderid,oh.shipid,oh.rma,odr.serialnumber,trunc(od.statusupdate),odr.lpid
   order by orderid, shipid;
rt curReturnPlates%rowtype;

cursor curReturnReason(in_lpid IN varchar2) is
  select pl.condition, crr.abbrev
    from plate pl, custreturnreasons crr
   where pl.lpid = in_lpid
     and pl.custid = crr.custid
     and pl.condition = crr.code
   union
  select pl.condition, crr.abbrev
    from deletedplate pl, custreturnreasons crr
   where pl.lpid = in_lpid
     and pl.custid = crr.custid
     and pl.condition = crr.code;
crr curReturnReason%rowtype;
    
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
	       
cursor curOtherShippingPlates(in_facility IN varchar2, in_orderid IN number, in_shipid IN number, in_item IN varchar2, in_serialnumber IN varchar2,
  in_numSessionID IN number) is
	select sp.item, sp.serialnumber,
         nvl(sum(sp.quantity),0) as quantity,
         nvl(sum(sp.weight),0) as weight
    from shippingplate sp, orderhdr oh
   where sp.orderid = in_orderid
     and sp.shipid = in_shipid
     and oh.orderid = sp.orderid
     and oh.shipid = sp.shipid
     and (sp.item <> in_item
      or  sp.serialnumber <> in_serialnumber)
     and exists(select 1
                  from orderhdr ohr, orderdtl od, orderdtlrcpt odr, asofinventorydtl aoi
                 where trunc(ohr.lastupdate) > trunc(oh.dateshipped)
                   and ohr.ordertype='Q'
                   and ohr.orderstatus = 'R'
                   and ohr.custid = sp.custid
                   and oh.tofacility = in_facility
                   and od.orderid = ohr.orderid
                   and od.shipid = ohr.shipid
                   and od.item = sp.item
                   and trunc(od.statusupdate) > trunc(oh.dateshipped)
                   and nvl(od.qtyrcvd,0) != 0
                   and odr.orderid = od.orderid
                   and odr.shipid = od.shipid
                   and odr.item = od.item
                   and nvl(odr.orderlot,'(none)') = nvl(od.lotnumber,'(none)')
                   and odr.serialnumber = sp.serialnumber
                   and (trunc(od.statusupdate) < trunc(in_begdate)
                    or  trunc(od.statusupdate) > trunc(in_enddate))
                   and aoi.facility = in_facility
                   and aoi.custid = sp.custid
                   and aoi.item = sp.item
                   and nvl(aoi.lotnumber,'(none)') = nvl(sp.lotnumber,'(none)')
                   and nvl(aoi.invstatus,'(none)') = nvl(sp.invstatus,'(none)')
                   and nvl(aoi.inventoryclass,'(none)') = nvl(sp.inventoryclass,'(none)')
                   and aoi.uom = sp.unitofmeasure
                   and aoi.effdate >= trunc(ohr.lastupdate)
                   and aoi.invstatus != 'SU'
                   and instr(','||upper(in_reason)||',',','||upper(aoi.reason)||',') > 0
                   and (aoi.adjustment < 0 
                    or  upper(aoi.reason) = 'RETURNS'))
     and not exists(select 1
                      from returnsrpt
                     where sessionid = in_numSessionID
                       and facility = in_facility
                       and custid = sp.custid
                       and item = sp.item
                       and serialnumber = sp.serialnumber
                       and ship_orderid = in_orderid
                       and ship_shipid = in_shipid)
   group by sp.item, sp.serialnumber
   order by sp.item, sp.serialnumber;
osp curOtherShippingPlates%rowtype;
	       
cursor curOtherReturnPlates(in_facility IN varchar2, in_custid IN varchar2, in_item IN varchar2,
  in_serialnumber IN varchar2, in_dateshipped IN date) is
  select oh.orderid,oh.shipid,oh.rma,trunc(ld.rcvddate) as rcvddate,
         odr.uom, odr.invstatus, odr.inventoryclass, odr.lotnumber,odr.lpid,
         nvl(sum(odr.qtyrcvd),0) as quantity,
         nvl(sum(odr.weight),0) as weight
    from loads ld, orderhdr oh, orderdtl od, orderdtlrcpt odr
   where trunc(ld.lastupdate) > in_dateshipped
     and trunc(ld.rcvddate) > in_dateshipped
     and ld.facility = in_facility
     and ld.loadtype in ('INC','INT')
     and ld.loadstatus = 'R'
     and oh.loadno = ld.loadno
     and oh.custid = in_custid
     and oh.tofacility = ld.facility
     and oh.orderstatus = 'R'
     and oh.ordertype = 'Q'
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and nvl(od.qtyrcvd,0) != 0
     and odr.orderid = od.orderid
     and odr.shipid = od.shipid
     and odr.item = od.item
     and nvl(odr.orderlot,'(none)') = nvl(od.lotnumber,'(none)')
     and odr.serialnumber = in_serialnumber
   group by oh.orderid,oh.shipid,oh.rma,trunc(ld.rcvddate),
         odr.uom, odr.invstatus, odr.inventoryclass, odr.lotnumber,odr.lpid
   union
  select oh.orderid,oh.shipid,oh.rma,trunc(od.statusupdate) as rcvddate,
         odr.uom, odr.invstatus, odr.inventoryclass, odr.lotnumber,odr.lpid,
         nvl(sum(odr.qtyrcvd),0) as quantity,
         nvl(sum(odr.weight),0) as weight
    from orderhdr oh, orderdtl od, orderdtlrcpt odr
   where trunc(oh.lastupdate) > in_dateshipped
     and oh.loadno is null
     and oh.ordertype='Q'
     and oh.orderstatus = 'R'
     and oh.custid = in_custid
     and oh.tofacility = in_facility
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and od.item = in_item
     and trunc(od.statusupdate) > in_dateshipped
     and nvl(od.qtyrcvd,0) != 0
     and odr.orderid = od.orderid
     and odr.shipid = od.shipid
     and odr.item = od.item
     and nvl(odr.orderlot,'(none)') = nvl(od.lotnumber,'(none)')
     and odr.serialnumber = in_serialnumber
   group by oh.orderid,oh.shipid,oh.rma,trunc(od.statusupdate),
         odr.uom, odr.invstatus, odr.inventoryclass, odr.lotnumber,odr.lpid
   order by orderid, shipid;
ort curOtherReturnPlates%rowtype;

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

delete from returnsrpt
where sessionid = numSessionId;
commit;

delete from returnsrpt
where lastupdate < trunc(sysdate);
commit;

select count(1)
into dtlCount
from returnsrpt
where lastupdate < sysdate;

if dtlCount = 0 then
  EXECUTE IMMEDIATE 'truncate table returnsrpt';
end if;

cu := null;
cit := null;

for cf in curFacility
loop
	for cu in curCustomer
	loop
	  for cit in curItem(cu.custid)
	  loop
      for casof in curAsOfDtlActivity(cf.facility, cu.custid, cit.item)
      loop
        casofr := null;
        open curAsOfRcptActivity(cf.facility,cu.custid,cit.item,casof.lotnumber,
          casof.uom,casof.invstatus,casof.inventoryclass,casof.effdate,casof.lpid);
        fetch curAsOfRcptActivity into casofr;
        close curAsOfRcptActivity;
    
        for rt in curReturnPlates(cf.facility,cu.custid,cit.item,casof.lotnumber,
          casof.uom,casof.invstatus,casof.inventoryclass,casofr.lastupdate,
          casofr.effdate,casof.lpid)
        loop
          if nvl(rt.quantity,0) != 0 then
            sp := null;
            open curShippingPlates(cit.item, rt.serialnumber, rt.rcvddate);
            fetch curShippingPlates into sp;
            close curShippingPlates;
          	
          	crr := null;
            open curReturnReason(rt.lpid);
            fetch curReturnReason into crr;
            close curReturnReason;

            insert into returnsrpt values
            (numSessionId,cf.facility,cu.custid,cit.item,casof.lotnumber,casof.uom,casof.invstatus,
             casof.inventoryclass,rt.serialnumber,rt.rma,cit.descr,
             cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
             sp.orderid,sp.shipid,sp.dateshipped,sp.quantity,sp.weight,
             rt.orderid,rt.shipid,rt.rcvddate,rt.quantity,rt.weight,to_char(rt.rcvddate,'YYYYMM'),to_char(rt.rcvddate,'MM/YYYY'),
             crr.abbrev,(rt.rcvddate-sp.dateshipped),sysdate);
             
            for osp in curOtherShippingPlates(cf.facility,sp.orderid,sp.shipid,cit.item,rt.serialnumber, numSessionId)
            loop
              for ort in curOtherReturnPlates(cf.facility,cu.custid,osp.item,osp.serialnumber,sp.dateshipped)
              loop
                citd := null;
                open curItemDescr(cu.custid, osp.item);
                fetch curItemDescr into citd;
                close curItemDescr;
          	    
          	    crr := null;
                open curReturnReason(ort.lpid);
                fetch curReturnReason into crr;
                close curReturnReason;
                
                insert into returnsrpt values
                (numSessionId,cf.facility,cu.custid,osp.item,ort.lotnumber,ort.uom,ort.invstatus,
                 ort.inventoryclass,osp.serialnumber,ort.rma,citd.descr,
                 cu.name,cu.addr1,cu.addr2,cu.city,cu.state,cu.postalcode,
                 sp.orderid,sp.shipid,sp.dateshipped,osp.quantity,osp.weight,
                 ort.orderid,ort.shipid,ort.rcvddate,ort.quantity,ort.weight,to_char(ort.rcvddate,'YYYYMM'),to_char(ort.rcvddate,'MM/YYYY'),
                 crr.abbrev,(ort.rcvddate-sp.dateshipped),sysdate);
              end loop;
            end loop;
          end if;
        end loop;
        commit;
      end loop;
    end loop;
  end loop;
end loop;

commit;

open aoi_cursor for
select *
   from returnsrpt
  where sessionid = numSessionId
  order by facility,custid,return_month,item;

end RETURNSRPTPROC;
/

CREATE OR REPLACE PACKAGE Body RETURNSRPTPKG AS
procedure RETURNSRPTPROC
(aoi_cursor  IN OUT returnsrptpkg.rr_type
,in_custid   IN varchar2
,in_facility IN varchar2
,in_begdate  IN date
,in_enddate  IN date
,in_reason   IN varchar2
,in_debug_yn IN varchar2)
as
begin
	RETURNSRPTPROC(aoi_cursor, in_custid, in_facility, in_begdate, in_enddate, in_reason, in_debug_yn);
end RETURNSRPTPROC;
end RETURNSRPTPKG;
/

show errors package RETURNSRPTPKG;
show errors procedure RETURNSRPTPROC;
show errors package body RETURNSRPTPKG;
exit;
