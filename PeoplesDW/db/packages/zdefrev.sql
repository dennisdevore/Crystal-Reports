drop table defrev;

create table defrev
(sessionid       number
,trantype        varchar2(2)
,facility        varchar2(3)
,custid          varchar2(10)
,custname        varchar2(40)
,defhandlingpct  number(3)
,uom             varchar2(4)
,qty             number(12)
,revamt          number(16,2)
,defamt          number(16,2)
,reporttitle     varchar2(255)
,lastupdate      date
);

create index defrev_sessionid_idx
 on defrev(sessionid,facility,custid,uom);

create index defrev_lastupdate_idx
 on defrev(lastupdate);

drop table defhandling;

CREATE TABLE defhandling
(
  SESSIONID                   NUMBER,
  FACILITY                    VARCHAR2(3),
  CUSTID                      VARCHAR2(10),
  ITEM                        VARCHAR2(50),
  ITEMDESC                    VARCHAR2(255),
  UOM                         VARCHAR2(4),
  DEFHANDLINGPCT              NUMBER(3),
  QUANTITY1                   NUMBER(10),
  GROSS_WEIGHT1               NUMBER(15,2),
  HUNDRED_WEIGHT1             NUMBER(15,2),
  CUBIC_FEET1									NUMBER(15,2),
  DEFAMT1 										NUMBER(15,2),
  REVAMT1 										NUMBER(15,2),
  QUANTITY2                   NUMBER(10),
  GROSS_WEIGHT2               NUMBER(15,2),
  HUNDRED_WEIGHT2             NUMBER(15,2),
  CUBIC_FEET2									NUMBER(15,2),
  DEFAMT2   									NUMBER(15,2),
  REVAMT2   									NUMBER(15,2),
  LASTUPDATE                  DATE
);

create index defhandlingsession_idx
 on defhandling(sessionid,facility,custid,uom);

create index defhandlinglstupdt_idx
 on defhandling(lastupdate);


create or replace package defrevpkg
as type dfr_type is ref cursor return defrev%rowtype;
	 type dh_type is ref cursor return defhandling%rowtype;
	 	
procedure defrevPROC
	(dfr_cursor IN OUT defrevpkg.dfr_type
	,in_facility IN varchar2
	,in_asofdate IN date
	,in_debug_yn IN varchar2);
end defrevpkg;
/

create or replace procedure defrevproc
(dfr_cursor IN OUT defrevpkg.dfr_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_asofdate IN date
,in_debug_yn IN varchar2)
as
--
-- $Id$
--

cursor curFacility is
  select facility
    from facility
   order by facility;

cursor curCustomer is
  select custid,name,defhandlingpct
    from customer;

cursor curCustItems(in_custid varchar2) is
  select item,descr,status
    from custitem
   where custid = in_custid
   order by item;

cursor curAsOfBeginSearch(in_facility varchar2, in_custid varchar2, in_item varchar2) is
  select lotnumber,invstatus,inventoryclass,uom,max(effdate) as effdate
    from asofinventory
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and effdate < trunc(in_asofdate)
     and invstatus != 'SU'
   group by lotnumber,invstatus,inventoryclass,uom
   order by lotnumber,invstatus,inventoryclass,uom;

numSessionId number;
wrk defrev%rowtype;
dtlQty defrev.qty%type;
aobCount integer;
aoeCount integer;
dtlCount integer;
recQty integer;
recLoop integer;
recDate date;
begBal integer;
clcBal integer;
numRate number(16,2);
numWeight number(16,2);

procedure debugmsg(in_msg varchar2)
is
begin
  if upper(in_debug_yn) = 'Y' then
    zut.prt(in_msg);
  end if;
exception when others then
  null;
end;

function handling_rev(in_custid varchar2, in_item varchar2,
                      in_uom varchar2, in_qty number)
return number
is

cursor curCustRate(in_rategroup varchar2) is
  select *
    from custrate
   where custid = in_custid
     and rategroup = in_rategroup
     and substr(activity,3,2) = 'H1'
   order by activity;
cr curCustRate%rowtype;

out_revenue invoicedtl.billedamt%type;
strRateGroup custitem.rategroup%type;
qtyUom number;
qtyRate number;
errmsg varchar2(255);

begin

out_revenue := 0;

select rategroup
  into strRateGroup
  from custitem
 where custid = in_custid
   and item = in_item;

cr := null;
open curCustRate(strRateGroup);
fetch curCustRate into cr;
close curCustRate;

if cr.custid is null then
  return 0;
end if;

if cr.billmethod = 'CWT' then
  debugmsg('cwt ' || cr.rate);
  out_revenue := zci.item_weight(in_custid,in_item,in_uom)
               * in_qty * cr.rate / 100;
  return out_revenue;
end if;

debugmsg(cr.uom || ' ' || cr.rate);
zbut.translate_uom(in_custid, in_item, in_qty, in_uom,
                   cr.uom, qtyUom, errmsg);
if errmsg != 'OKAY' then
  qtyUom := 0;
end if;

qtyUom := round(qtyUom,20);
if cr.calctype = 'U' then
   qtyRate := ceil(qtyUom);
elsif cr.calctype = 'D' then
   qtyRate := trunc(qtyUom);
else
   qtyRate := qtyUom;
end if;

out_revenue := qtyRate * cr.rate;
return out_revenue;

exception when others then
  debugmsg('handling_rev function: ' || sqlerrm);
  return 0;
end;

procedure compute_deferred_rev(in_item varchar2)
is
begin

wrk.revamt := handling_rev(wrk.custid,in_item,wrk.uom,wrk.qty);
wrk.defamt := wrk.revamt * wrk.defhandlingpct / 100;
debugmsg(wrk.custid || ' ' || in_item || ' ' || wrk.uom || ' ' ||
         wrk.qty || ' ' || wrk.revamt || ' ' || wrk.defamt);
update defrev
  set qty = qty + wrk.qty,
      revamt = revamt + wrk.revamt,
      defamt = defamt + wrk.defamt
where sessionid = numSessionId
  and facility = wrk.facility
  and custid = wrk.custid
  and uom = wrk.uom;
if sql%rowcount = 0 then
 insert into defrev values
   (numSessionId, 'AA', wrk.facility, wrk.custid, wrk.custname,
    wrk.defhandlingpct, wrk.uom, wrk.qty, wrk.revamt, wrk.defamt,
    wrk.reporttitle, sysdate);
end if;

commit;

exception when others then
  debugmsg(sqlerrm);
end;

begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from defrev
where sessionid = numSessionId;
commit;

delete from defrev
where lastupdate < trunc(sysdate);
commit;

wrk := null;
begin
 select reporttitle
   into wrk.reporttitle
   from reporttitleview;
exception when others then
 null;
end;

for cus in curCustomer
loop
  if upper(in_custid) != 'ALL' then
    if upper(in_custid) != cus.custid then
      goto continue_custid_loop;
    end if;
  end if;
  wrk.custid := cus.custid;
  wrk.custname := cus.name;
  wrk.defhandlingpct := cus.defhandlingpct;
  debugmsg('processing customer: ' || cus.custid);
  for fac in curFacility
  loop
    if upper(in_facility) != 'ALL' then
      if upper(in_facility) != fac.facility then
        goto continue_facility_loop;
      end if;
    end if;
    wrk.facility := fac.facility;
    debugmsg('processing facility: ' || fac.facility);
    for cit in curCustItems(cus.custid)
    loop
     debugmsg('processing item for begin bal ' || cit.item);
     wrk.qty := 0;
     wrk.uom := null;
     aobcount := 0;
     for aob in curAsOfBeginSearch(fac.facility,cus.custid,cit.item)
     loop
       if (nvl(wrk.uom,'x') != aob.uom) then
         if nvl(wrk.uom,'x') != 'x' then
           compute_deferred_rev(cit.item);
         end if;
         wrk.uom := aob.uom;
         wrk.qty := 0;
       end if;
       debugmsg('effective date ' || aob.effdate);
       dtlQty := 0;
       select currentqty
         into dtlQty
         from asofinventory
        where facility = fac.facility
          and custid = cus.custid
          and item = cit.item
          and effdate = aob.effdate
          and nvl(lotnumber,'x') = nvl(aob.lotnumber,'x')
          and invstatus = aob.invstatus
          and inventoryclass = aob.inventoryclass
          and uom = aob.uom;
       wrk.qty := wrk.qty + dtlQty;
     end loop;
     if (wrk.qty <> 0) then
       compute_deferred_rev(cit.item);
     end if;
    end loop;
  << continue_facility_loop >>
    null;
  end loop;
<< continue_custid_loop >>
  null;
end loop;

open dfr_cursor for
select sessionid
,trantype
,facility
,custid
,custname
,defhandlingpct
,uom
,qty
,revamt
,defamt
,reporttitle
,lastupdate
   from defrev
  where sessionid = numSessionId
  order by trantype,facility,custid,uom;

end defrevproc;
/




CREATE OR REPLACE procedure defhandlingPROC
(df_cursor IN OUT defrevpkg.dh_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_date1 IN date
,in_date2 IN date
,in_debug_yn IN varchar2)
as


cursor curCustomer is
  select custid,name,defhandlingpct
    from customer;
cus curCustomer%rowtype;

cursor curFacility is
  select facility
    from facility
   order by facility;
fac curFacility%rowtype;

cursor curCustItems(in_custid varchar2) is
  select *
    from custitem
   where custid = in_custid
   order by item;

cursor curAsOfBeginSearch(in_facility varchar2, in_custid varchar2, in_item varchar2, in_date date) is
  select lotnumber,invstatus,inventoryclass,uom,max(effdate) as effdate
    from asofinventory
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and effdate < trunc(in_date)
     and invstatus != 'SU'
   group by lotnumber,invstatus,inventoryclass,uom
   order by lotnumber,invstatus,inventoryclass,uom;

numSessionId number;
wrk defhandling%rowtype;
dtlQty defhandling.quantity1%type;
dtlWght defhandling.gross_weight1%type;
aobCount integer;
aoeCount integer;
dtlCount integer;
recQty integer;
recLoop integer;
recDate date;
begBal integer;
clcBal integer;
numRate number(16,2);
numWeight number(16,2);

procedure debugmsg(in_text varchar2) is
begin
  if upper(rtrim(in_debug_yn)) = 'Y' then
    zut.prt(in_text);
  end if;
exception when others then
  null;
end;

function handling_rev(in_custid varchar2, in_item varchar2,
                      in_uom varchar2, in_qty number)
return number
is

cursor curCustRate(in_rategroup varchar2) is
  select *
    from custrate
   where custid = in_custid
     and rategroup = in_rategroup
     and substr(activity,3,2) = 'H1'
   order by activity;
cr curCustRate%rowtype;

out_revenue invoicedtl.billedamt%type;
strRateGroup custitem.rategroup%type;
qtyUom number;
qtyRate number;
errmsg varchar2(255);

begin

out_revenue := 0;

select rategroup
  into strRateGroup
  from custitem
 where custid = in_custid
   and item = in_item;

cr := null;
open curCustRate(strRateGroup);
fetch curCustRate into cr;
close curCustRate;

if cr.custid is null then
  return 0;
end if;

if cr.billmethod = 'CWT' then
  debugmsg('cwt ' || cr.rate);
  out_revenue := zci.item_weight(in_custid,in_item,in_uom)
               * in_qty * cr.rate / 100;
  return out_revenue;
end if;

debugmsg(cr.uom || ' ' || cr.rate);
zbut.translate_uom(in_custid, in_item, in_qty, in_uom,
                   cr.uom, qtyUom, errmsg);
if errmsg != 'OKAY' then
  qtyUom := 0;
end if;

qtyUom := round(qtyUom,20);
if cr.calctype = 'U' then
   qtyRate := ceil(qtyUom);
elsif cr.calctype = 'D' then
   qtyRate := trunc(qtyUom);
else
   qtyRate := qtyUom;
end if;

out_revenue := qtyRate * cr.rate;
return out_revenue;

exception when others then
  debugmsg('handling_rev function: ' || sqlerrm);
  return 0;
end;

begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from defhandling
where sessionid = numSessionId;
commit;

delete from defhandling
where lastupdate < trunc(sysdate);
commit;

for cus in curCustomer
loop
  if upper(in_custid) != 'ALL' then
    if upper(in_custid) != cus.custid then
      goto continue_custid_loop;
    end if;
  end if;
  debugmsg('processing customer: ' || cus.custid);
  for fac in curFacility
  loop
    if upper(in_facility) != 'ALL' then
      if upper(in_facility) != fac.facility then
        goto continue_facility_loop;
      end if;
    end if;
    debugmsg('processing facility: ' || fac.facility);
    for cit in curCustItems(cus.custid)
    loop
      debugmsg('processing item for begin bal ' || cit.item);
      aobcount := 0;
      for aob in curAsOfBeginSearch(fac.facility,cus.custid,cit.item,in_date1)
      loop
        debugmsg('effective date ' || aob.effdate);
        dtlQty := 0;
        dtlWght := 0.0;
        select nvl(zci.item_base_qty(cus.custid, cit.item, uom, currentqty),0),
               nvl(currentweight,0.0)
          into dtlQty, dtlWght
          from asofinventory
         where facility = fac.facility
           and custid = cus.custid
           and item = cit.item
           and effdate = aob.effdate
           and nvl(lotnumber,'x') = nvl(aob.lotnumber,'x')
           and invstatus = aob.invstatus
           and inventoryclass = aob.inventoryclass
           and uom = aob.uom;
           
        wrk.hundred_weight1 := nvl((dtlWght/100.0),0.0);
        wrk.cubic_feet1 := nvl(zci.item_cube(cus.custid, cit.item, cit.baseuom)*dtlQty,0.0);
        wrk.revamt1 := nvl(handling_rev(cus.custid,cit.item,cit.baseuom,dtlQty),0.0);
        wrk.defamt1 := nvl((wrk.revamt1 * cus.defhandlingpct / 100), 0.0);
         
        debugmsg(cus.custid || ' ' || cit.item || ' ' || cit.baseuom || ' ' ||
                 dtlQty || ' ' || wrk.revamt1 || ' ' || wrk.defamt1);
                 
        update defhandling
          set quantity1 = quantity1 + dtlQty,
              gross_weight1 = gross_weight1 + dtlWght,
              hundred_weight1 = hundred_weight1 + wrk.hundred_weight1,
              cubic_feet1 = cubic_feet1 + wrk.cubic_feet1,
              revamt1 = revamt1 + wrk.revamt1,
              defamt1 = defamt1 + wrk.defamt1
        where sessionid = numSessionId
          and facility = fac.facility
          and custid = cus.custid
          and item = cit.item;
          
        if sql%rowcount = 0 then
          insert into defhandling values
           (numSessionId, fac.facility, cus.custid, cit.item, cit.descr, cit.baseuom, cus.defhandlingpct,
            dtlQty, dtlWght, wrk.hundred_weight1, wrk.cubic_feet1, wrk.revamt1, wrk.revamt1,
            0, 0.0, 0.0, 0.0, 0.0, 0.0,
            sysdate);
        end if;
      end loop;
      for aob in curAsOfBeginSearch(fac.facility,cus.custid,cit.item,in_date2)
      loop
        debugmsg('effective date ' || aob.effdate);
        dtlQty := 0;
        dtlWght := 0.0;
        select nvl(zci.item_base_qty(cus.custid, cit.item, uom, currentqty),0),
               nvl(currentweight,0.0)
          into dtlQty, dtlWght
          from asofinventory
         where facility = fac.facility
           and custid = cus.custid
           and item = cit.item
           and effdate = aob.effdate
           and nvl(lotnumber,'x') = nvl(aob.lotnumber,'x')
           and invstatus = aob.invstatus
           and inventoryclass = aob.inventoryclass
           and uom = aob.uom;
           
        wrk.hundred_weight2 := nvl((dtlWght/100.0),0.0);
        wrk.cubic_feet2 := nvl(zci.item_cube(cus.custid, cit.item, cit.baseuom)*dtlQty,0.0);
        wrk.revamt2 := nvl(handling_rev(cus.custid,cit.item,cit.baseuom,dtlQty),0.0);
        wrk.defamt2 := nvl((wrk.revamt2 * cus.defhandlingpct / 100),0.0);
        
        debugmsg(cus.custid || ' ' || cit.item || ' ' || cit.baseuom || ' ' ||
                 dtlQty || ' ' || wrk.revamt2 || ' ' || wrk.defamt2);
        
        update defhandling
          set quantity2 = quantity2 + dtlQty,
              gross_weight2 = gross_weight2 + dtlWght,
              hundred_weight2 = hundred_weight2 + wrk.hundred_weight2,
              cubic_feet2 = cubic_feet2 + wrk.cubic_feet2,
              revamt2 = revamt2 + wrk.revamt2,
              defamt2 = defamt2 + wrk.defamt2
        where sessionid = numSessionId
          and facility = fac.facility
          and custid = cus.custid
          and item = cit.item;
          
        if sql%rowcount = 0 then
          insert into defhandling values
           (numSessionId, fac.facility, cus.custid, cit.item, cit.descr, cit.baseuom, cus.defhandlingpct,
            0, 0.0, 0.0, 0.0, 0.0, 0.0,
            dtlQty, dtlWght, wrk.hundred_weight2, wrk.cubic_feet2, wrk.revamt2, wrk.revamt2,
            sysdate);
        end if;
      end loop;
    end loop;
  << continue_facility_loop >>
    null;
  end loop;
<< continue_custid_loop >>
  null;
end loop;

open df_cursor for
select *
   from defhandling
  where sessionid = numSessionId
  order by facility,custid,item;

end defhandlingPROC;
/
show errors package defrevpkg;
show errors procedure defrevproc;
show errors procedure defhandlingproc;
show errors package body defrevpkg;
exit;
