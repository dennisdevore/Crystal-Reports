drop table asofsummarylot;

create table asofsummarylot
(sessionid       number
,custid          varchar2(10)
,item            varchar2(50)
,currentqty      number(10)
,currentweight   number(10)
,lotnumber       varchar2(30)
,invstatus       varchar2(30)
,useritem        varchar2(4000)
,expdate         date
,mfgdate         date
,descr           varchar2(40)
,lastupdate      date
);

create index asofsummarylot_sessionid_idx
 on asofsummarylot(sessionid);

create index asofsummary_lastupdate_idx
 on asofsummarylot(lastupdate);

create or replace package ASOFSUMMARYLOTPKG
as type aos_type is ref cursor return asofsummarylot%rowtype;
  function get_useritem(in_custid varchar2, in_item varchar2, in_lot varchar2) return varchar2;
  function get_expdate(in_custid varchar2, in_item varchar2, in_lot varchar2) return date;
  function get_mfgdate(in_custid varchar2, in_item varchar2, in_lot varchar2) return date;
end asofsummarylotpkg;
/

CREATE OR REPLACE PACKAGE Body ASOFSUMMARYLOTPKG AS
function get_useritem(in_custid varchar2, in_item varchar2, in_lot varchar2) return varchar2
is
CURSOR curPlate(in_custid varchar2, in_item varchar2, in_lot varchar2) IS
select useritem1, useritem2
  from plate
 where custid = in_custid
   and item = in_item
   and nvl(lotnumber,'x') = nvl(in_lot,'x')
order by lastupdate;

PL curPlate%rowtype;

CURSOR curDPlate(in_custid varchar2, in_item varchar2, in_lot varchar2) IS
select useritem1, useritem2
  from deletedplate
 where custid = in_custid
   and item = in_item
   and nvl(lotnumber,'x') = nvl(in_lot,'x')
order by lastupdate;

DPL curDPlate%rowtype;

useritem varchar2(50);
begin

useritem := '';

OPEN curPlate(in_custid, in_item, in_lot);
LOOP
  FETCH curPlate INTO PL;
  EXIT WHEN curPlate%NOTFOUND;
  
  if PL.useritem1 is not null then
	useritem := PL.useritem1;
  elsif PL.useritem2 is not null then
	useritem := PL.useritem2;
  end if;

  EXIT WHEN useritem <> '';
END LOOP;
CLOSE curPlate;

if useritem = '' then
  OPEN curDPlate(in_custid, in_item, in_lot);
  LOOP
    FETCH curDPlate INTO DPL;
    EXIT WHEN curDPlate%NOTFOUND;
  
    if DPL.useritem1 is not null then
      useritem := DPL.useritem1;
    elsif DPL.useritem2 is not null then
      useritem := DPL.useritem2;
    end if;

    EXIT WHEN useritem <> '';
  END LOOP;
  CLOSE curDPlate;
end if;

return useritem;

exception when others then
  return '';
end;

function get_expdate(in_custid varchar2, in_item varchar2, in_lot varchar2) return date
is
CURSOR curPlate(in_custid varchar2, in_item varchar2, in_lot varchar2) IS
select expirationdate
  from plate
 where custid = in_custid
   and item = in_item
   and nvl(lotnumber,'x') = nvl(in_lot,'x')
order by lastupdate;

PL curPlate%rowtype;

CURSOR curDPlate(in_custid varchar2, in_item varchar2, in_lot varchar2) IS
select expirationdate
  from deletedplate
 where custid = in_custid
   and item = in_item
   and nvl(lotnumber,'x') = nvl(in_lot,'x')
order by lastupdate;

DPL curDPlate%rowtype;

expdate date;
begin

expdate := null;

OPEN curPlate(in_custid, in_item, in_lot);
LOOP
  FETCH curPlate INTO PL;
  EXIT WHEN curPlate%NOTFOUND;
  
  if PL.expirationdate is not null then
	expdate := PL.expirationdate;
  end if;

  EXIT WHEN expdate is not null;
END LOOP;
CLOSE curPlate;

if expdate is null then
  OPEN curDPlate(in_custid, in_item, in_lot);
  LOOP
    FETCH curDPlate INTO DPL;
    EXIT WHEN curDPlate%NOTFOUND;
  
    if DPL.expirationdate is not null then
      expdate := DPL.expirationdate;
    end if;

    EXIT WHEN expdate is not null;
  END LOOP;
  CLOSE curDPlate;
end if;

return expdate;

exception when others then
  return null;
end;

function get_mfgdate(in_custid varchar2, in_item varchar2, in_lot varchar2) return date
is
CURSOR curPlate(in_custid varchar2, in_item varchar2, in_lot varchar2) IS
select manufacturedate
  from plate
 where custid = in_custid
   and item = in_item
   and nvl(lotnumber,'x') = nvl(in_lot,'x')
order by lastupdate;

PL curPlate%rowtype;

CURSOR curDPlate(in_custid varchar2, in_item varchar2, in_lot varchar2) IS
select manufacturedate
  from deletedplate
 where custid = in_custid
   and item = in_item
   and nvl(lotnumber,'x') = nvl(in_lot,'x')
order by lastupdate;

DPL curDPlate%rowtype;

mfgdate date;
begin

mfgdate := null;

OPEN curPlate(in_custid, in_item, in_lot);
LOOP
  FETCH curPlate INTO PL;
  EXIT WHEN curPlate%NOTFOUND;
  
  if PL.manufacturedate is not null then
	mfgdate := PL.manufacturedate;
  end if;

  EXIT WHEN mfgdate is not null;
END LOOP;
CLOSE curPlate;

if mfgdate is null then
  OPEN curDPlate(in_custid, in_item, in_lot);
  LOOP
    FETCH curDPlate INTO DPL;
    EXIT WHEN curDPlate%NOTFOUND;
  
    if DPL.manufacturedate is not null then
      mfgdate := DPL.manufacturedate;
    end if;

    EXIT WHEN mfgdate is not null;
  END LOOP;
  CLOSE curDPlate;
end if;

return mfgdate;

exception when others then
  return null;
end;

end ASOFSUMMARYLOTPKG;
/

create or replace procedure ASOFSUMMARYLOTPROC
(aos_cursor IN OUT asofsummarylotpkg.aos_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_effdate IN date
,in_invstatus IN varchar2
,in_debug_yn IN varchar2)
as

cursor curCustomer is
  select custid
    from customer
   where (custid = in_custid
   	   or in_custid = 'ALL')
   order by custid;
cu curCustomer%rowtype;

cursor curFacility is
  select facility
    from facility
   where instr(','||in_facility||',', ','||facility||',', 1, 1) > 0
     	or in_facility = 'ALL'
   order by facility;
cf curFacility%rowtype;

cursor curCustItems(in_custid IN varchar2) is
  select item,descr
    from custitem
   where custid = in_custid
   order by item;

cursor curAsOfSearch(in_custid IN varchar2, in_facility IN varchar2, in_item IN varchar2) is
SELECT
    A1.CURRENTQTY,
    nvl(nvl(A1.CURRENTWEIGHT,(zci.item_weight(A1.custid,A1.item,A1.uom) * A1.CURRENTWEIGHT)),0) AS CURRENTWEIGHT,
    nvl(A1.LOTNUMBER,'NONE') as LOTNUMBER,
    nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')) as INVSTATUS, 1 as truelink,
    ASOFSUMMARYLOTPKG.get_useritem(A1.CUSTID,A1.ITEM,A1.LOTNUMBER) as USERITEM,
    ASOFSUMMARYLOTPKG.get_expdate(A1.CUSTID,A1.ITEM,A1.LOTNUMBER) as EXPDATE,
    ASOFSUMMARYLOTPKG.get_mfgdate(A1.CUSTID,A1.ITEM,A1.LOTNUMBER) as MFGDATE
FROM ASOFINVENTORY A1, INVENTORYSTATUS
where A1.facility = in_facility
and A1.custid = in_custid
and A1.item = in_item
and A1.effdate = (select max(A2.effdate)
                    from ASOFINVENTORY A2
                   where A1.facility = A2.facility
                     and A1.custid = A2.custid
                     and A1.item = A2.item
                     and A2.effdate <= trunc(in_effdate)
                     and nvl(A1.lotnumber,'xxx') = nvl(A2.lotnumber,'xxx')
                     and A1.invstatus = A2.invstatus
                     and A1.inventoryclass = A2.inventoryclass)
and A1.inventoryclass = 'RG'
and A1.INVSTATUS = INVENTORYSTATUS.CODE (+)
and (in_invstatus = 'ALL'
	or nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')) = in_invstatus)
and A1.currentqty <> 0
union
SELECT
    A1.CURRENTQTY as CURRENTQTY,
    nvl(nvl(A1.CURRENTWEIGHT,(zci.item_weight(A1.custid,A1.item,A1.uom) * A1.CURRENTQTY)),0) AS CURRENTWEIGHT,
    nvl(A1.LOTNUMBER,'NONE') as LOTNUMBER,
    decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) as INVSTATUS, 2 as truelink,
    ASOFSUMMARYLOTPKG.get_useritem(A1.CUSTID,A1.ITEM,A1.LOTNUMBER) as USERITEM,
    ASOFSUMMARYLOTPKG.get_expdate(A1.CUSTID,A1.ITEM,A1.LOTNUMBER) as EXPDATE,
    ASOFSUMMARYLOTPKG.get_mfgdate(A1.CUSTID,A1.ITEM,A1.LOTNUMBER) as MFGDATE
FROM ASOFINVENTORY A1, INVENTORYSTATUS
where A1.facility = in_facility
and A1.custid = in_custid
and A1.item = in_item
and A1.effdate = (select max(A2.effdate)
                    from ASOFINVENTORY A2
                   where A1.facility = A2.facility
                     and A1.custid = A2.custid
                     and A1.item = A2.item
                     and A2.effdate <= trunc(in_effdate)
                     and nvl(A1.lotnumber,'xxx') = nvl(A2.lotnumber,'xxx')
                     and A1.invstatus = A2.invstatus
                     and A1.inventoryclass = A2.inventoryclass)
and A1.inventoryclass <> 'RG'
and A1.INVSTATUS = INVENTORYSTATUS.CODE (+)
and (in_invstatus = 'ALL'
	or decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) = in_invstatus)
and A1.currentqty <> 0
union
select
    nvl(sum(rd.qtyentered),0) as currentqty, nvl(sum(rd.weightorder),0) as currentweight,
    nvl(rd.lotnumber,'NONE') as lotnumber, 'Arrived' as invstatus, 3 as truelink,
    ASOFSUMMARYLOTPKG.get_useritem(rh.CUSTID,rd.ITEM,rd.LOTNUMBER) as USERITEM,
    ASOFSUMMARYLOTPKG.get_expdate(rh.CUSTID,rd.ITEM,rd.LOTNUMBER) as EXPDATE,
    ASOFSUMMARYLOTPKG.get_mfgdate(rh.CUSTID,rd.ITEM,rd.LOTNUMBER) as MFGDATE
from RECEIVERHDRVIEW rh, RECEIVERDTLVIEW rd, orderhdr oh
where rh.tofacility = in_facility
and rh.custid = in_custid
and rd.item = in_item
and trunc(oh.entrydate) <= trunc(in_effdate)
and rh.ordertype = 'R'
and rh.orderstatus = 'A'
and rh.orderid = rd.orderid
and rh.shipid = rd.shipid
and rh.ORDERHDRROWID = oh.rowid
and in_invstatus in ('ALL','Arrived')
group by rh.CUSTID,rd.ITEM,rd.lotnumber;

numSessionId number;
aosCount number;

begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from asofsummarylot
where sessionid = numSessionId;
commit;

delete from asofsummarylot
where lastupdate < trunc(sysdate);
commit;

for cu in curCustomer
loop
 for cf in curFacility
 loop
  for cit in curCustItems(cu.custid)
  loop
   for caos in curAsOfSearch(cu.custid, cf.facility, cit.item)
   loop
     select count(1)
       into aosCount
       from asofsummarylot
      where sessionid = numSessionId
      	and custid = in_custid
        and item = cit.item
        and nvl(lotnumber,'NONE') = caos.lotnumber
        and invstatus = caos.invstatus;
     if aosCount = 0 then
      insert into asofsummarylot values(numSessionId, in_custid, cit.item,
                                        caos.currentqty, caos.currentweight, caos.lotnumber,
                                        caos.invstatus, caos.useritem, caos.expdate,
                                        caos.mfgdate, cit.descr, sysdate);
     else
      update asofsummarylot
         set currentqty = currentqty + caos.currentqty,
             currentweight = currentweight + caos.currentweight
       where sessionid = numSessionId
       	 and custid = in_custid
         and item = cit.item
         and nvl(lotnumber,'NONE') = caos.lotnumber
         and invstatus = caos.invstatus;
     end if;
   end loop;
   commit;
  end loop;
 end loop;
end loop;

delete from asofsummarylot
      where sessionid = numSessionId
        and currentqty = 0;
commit;

open aos_cursor for
select distinct sessionid
,custid
,item
,currentqty
,currentweight
,lotnumber
,invstatus
,useritem
,expdate
,mfgdate
,descr
,lastupdate
   from asofsummarylot
  where sessionid = numSessionId
  order by item,invstatus;

end ASOFSUMMARYLOTPROC;


/
show errors package ASOFSUMMARYLOTPKG;
show errors procedure ASOFSUMMARYLOTPROC;
show errors package body ASOFSUMMARYLOTPKG;
exit;
