--
-- $Id$
--
set serveroutput on;

declare

cursor curItemFacility is
  select distinct
         facility,
         custid
    from plate
   where type = 'PA'
     and status in ('A','M')
   order by facility,custid;

cursor curCustItem(in_custid varchar2) is
  select item,
         allocrule,
         profid
    from custitem
   where custid = in_custid
   order by item;

cursor curCustItemFacility(in_custid varchar2, in_item varchar2,
  in_facility varchar2) is
  select custid,
         facility,
         allocrule,
         profid
    from custitemfacility
   where custid = in_custid
     and item = in_item
     and facility = in_facility;
civ curCustItemFacility%rowtype;

out_msg varchar2(255);
out_errorno integer;
cntTot integer;
cntOky integer;
strCustId customer.custid%type;
strFacility facility.facility%type;

begin

out_msg := '';
out_errorno := 0;
cntTot := 0;
cntOky := 0;
strCustId := 'x';
strFacility := 'x';

for itf in curItemFacility
loop
  zut.prt('Processing Customer ' || itf.custid || ' Facility ' || itf.facility);
  if (strCustId <> itf.custid) or
     (strFacility <> itf.facility) then
    strCustId := itf.custid;
    strFacility := itf.facility;
  end if;
  for ci in curCustItem(itf.custid)
  loop
    zut.prt('item ' || ci.item);
    cntTot := cntTot + 1;
    civ := null;
    open curCustItemFacility(itf.custid,ci.item,itf.facility);
    fetch curCustItemFacility into civ;
    close curCustItemFacility;
    if civ.custid is null then -- no custitemfacility on file, so add one
      insert into custitemfacility
       (custid,item,facility,profid,allocrule,lastuser,lastupdate)
       values
       (itf.custid,ci.item,itf.facility,
         nvl(ci.profid,'C'),nvl(ci.allocrule,'C'),'ZCONVERT',sysdate);
      zut.prt('Item add ' || itf.custid || ' ' || ci.item || ' ' || itf.facility || ' ' ||
        ci.profid || ' ' || ci.allocrule);
    else
      zut.prt('already set ' || civ.profid || ' ' || civ.allocrule);
      zut.prt('old item    ' || ci.profid || ' ' || civ.profid);
    end if;
  << continue_item_facility_loop >>
    null;
  end loop;
end loop;

zut.prt('tot ' || cntTot);
zut.prt('oky ' || cntOky);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
--exit;
