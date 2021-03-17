--
-- $Id$
--
set serveroutput on;

declare

cursor curSelectXrefs is
  select *
    from plate
   where type in ('XP')
     and ( (parentfacility is not null) or
           (parentitem is not null) or
           (childfacility is not null) or
           (childitem is not null) );

cursor curSelectParents is
  select *
    from plate
   where type in ('MP','PA','TO')
     and parentlpid is null
     and status = 'A'
     and exists (select * from location
                  where plate.facility = location.facility
                    and plate.location = location.locid
                    and location.loctype = 'STO');

cursor curChildrenSum(in_parentlpid varchar2) is
  select facility,
			custid,
         item,
         lotnumber,
         invstatus,
         inventoryclass,
         sum(quantity) as quantity
    from plate
   where parentlpid = in_parentlpid
     and status = 'A'
     and type = 'PA'
   group by facility,custid,item,lotnumber,invstatus,inventoryclass;

cursor curChildrenDtl(in_parentlpid varchar2) is
  select *
    from plate
   where parentlpid = in_parentlpid
     and status = 'A'
     and type = 'PA'
     and exists (select * from location
                  where plate.facility = location.facility
                    and plate.location = location.locid
                    and location.loctype = 'STO');

cursor curOrphans is
  select *
    from plate pa
   where type = 'PA'
     and status = 'A'
     and parentlpid is not null
     and not exists
       (select *
          from plate mp
         where mp.lpid = pa.parentlpid
           and mp.type = 'MP');



out_msg varchar2(255);
out_errorno integer;
cntRows integer;
cntTot integer;
cntErr integer;
cntOky integer;
qtyTot integer;
qtyErr integer;
qtyOky integer;
cntLip integer;
qtyLip integer;
cntQty integer;
qtyQty integer;
lotrequired varchar2(1);
hazardous varchar2(1);
out_item varchar2(255);
updflag char(1);
lastfacility plate.facility%type;
lastitem plate.item%type;

begin

updflag := upper('&1');

cntTot := 0;
cntErr := 0;
cntOky := 0;
qtyTot := 0;
qtyErr := 0;
qtyOky := 0;

zut.prt('begin xref loop. . .');

for xr in curSelectXrefs
loop

  zut.prt(xr.type || ' LiP has parent/child values: ' || xr.lpid);
  cntErr := cntErr + 1;
  qtyErr := qtyErr + xr.quantity;
  if updflag = 'Y' then
    update plate
       set parentfacility = null,
           parentitem = null,
           childfacility = null,
           childitem = null
     where lpid = xr.lpid;
    commit;
  end if;

end loop;

zut.prt('non-null xref error count: ' || cntErr || ' error quantity: ' || qtyErr);

cntTot := 0;
cntErr := 0;
cntOky := 0;
qtyTot := 0;
qtyErr := 0;
qtyOky := 0;
cntQty := 0;
qtyQty := 0;

zut.prt('begin parent loop. . .');

for mp in curSelectParents
loop

  cntTot := cntTot + 1;
  qtyTot := qtyTot + mp.quantity;

  if mp.type = 'PA' then -- "stand-alone" lip
    if mp.facility = mp.parentfacility and
       mp.item = mp.parentitem then
      cntOky := cntOky + 1;
      qtyOky := qtyOky + mp.quantity;
    else
      zut.prt('facility/item mismatch on parent PA: ' ||
        mp.lpid || ' facility: ' || mp.facility || '/' || mp.parentfacility ||
        ' item: ' || mp.item || '/' || mp.parentitem);
      cntErr := cntErr + 1;
      qtyErr := qtyErr + 1;
      if updflag = 'Y' then
        update plate
           set parentfacility = facility,
               parentitem = item
         where lpid = mp.lpid;
        commit;
      end if;
    end if;
    goto continue_parent_loop;
  end if;

-- Multi-Lip Check
  cntLip := 0;
  qtyLip := 0;
  for cs in curChildrenSum(mp.lpid)
  loop
    cntLip := cntLip + 1;
    qtyLip := qtyLip + cs.quantity;
	 lastfacility := cs.facility;
	 lastitem := cs.item;
  end loop;

  if qtyLiP != mp.quantity then
    cntQty := cntQty + 1;
    qtyQty := qtyQty + qtyLip;
    zut.prt('qty mismatch--parent ' || mp.lpid || ': ' || mp.quantity ||
      '  children: ' || qtyLip);
    if updflag = 'Y' then
      update plate
         set quantity = qtyLip,
             lasttask = 'AJ',
             lastuser = 'SYSADJ'
       where lpid = mp.lpid;
      commit;
    end if;
  end if;

  if cntLip = 1 then -- "single-item Multi-Lip"
    if nvl(mp.parentfacility,'x') = nvl(lastfacility,'y') and
       nvl(mp.parentitem,'x') = nvl(lastitem,'y') and
       nvl(mp.facility,'x') = nvl(lastfacility,'y') and
       nvl(mp.item,'x') = nvl(lastitem,'y') then
      cntOky := cntOky + 1;
      qtyOky := qtyOky + mp.quantity;
    else
      zut.prt('facility/item mismatch on parent MP: ' ||
        mp.lpid || ' facility: ' || mp.facility || '/' || lastfacility ||
        ' item: ' || mp.item || '/' || lastitem);
      cntErr := cntErr + 1;
      qtyErr := qtyErr + 1;
      if updflag = 'Y' then
        update plate
           set parentfacility = lastfacility,
               parentitem = lastitem,
					facility = lastfacility,
					item = lastitem
         where lpid = mp.lpid;
        commit;
      end if;
    end if;
    for cd in curChildrenDtl(mp.lpid)  -- validate children
    loop
      if cd.parentfacility is not null or
         cd.parentitem is not null then
        zut.prt('child has parent values: ' || cd.lpid || ' '
          || cd.parentfacility || ' ' || cd.parentitem);
        cntErr := cntErr + 1;
        qtyErr := qtyErr + 1;
        if updflag = 'Y' then
          update plate
             set parentfacility = null,
                 parentitem = null
           where lpid = cd.lpid;
          commit;
        end if;
      end if;
      if cd.childfacility is not null or
         cd.childitem is not null then
        zut.prt('single-item child has child values: ' || cd.lpid);
        cntErr := cntErr + 1;
        qtyErr := qtyErr + 1;
        if updflag = 'Y' then
          update plate
             set childfacility = null,
                 childitem = null
           where lpid = cd.lpid;
          commit;
        end if;
      end if;
    end loop;
  else -- "multiple-item Multi-LiP"
    if mp.parentfacility is not null or
       mp.parentitem is not null then
      zut.prt('multiple-item Multi contains parent values: ' ||
        mp.lpid || ' facility: ' || mp.facility || '/' || mp.parentfacility ||
        ' item: ' || mp.item || '/' || mp.parentitem);
      cntErr := cntErr + 1;
      qtyErr := qtyErr + 1;
      if updflag = 'Y' then
        update plate
           set parentfacility = null,
               parentitem = null
         where lpid = mp.lpid;
        commit;
      end if;
    else
      cntOky := cntOky + 1;
      qtyOky := qtyOky + mp.quantity;
    end if;
    for cd in curChildrenDtl(mp.lpid)  -- validate children
    loop
      if cd.parentfacility is not null or
         cd.parentitem is not null then
        zut.prt(mp.lpid || ' child has parent values: ' || cd.lpid);
        cntErr := cntErr + 1;
        qtyErr := qtyErr + 1;
        if updflag = 'Y' then
          update plate
             set parentfacility = null,
                 parentitem = null
           where lpid = cd.lpid;
          commit;
        end if;
      end if;
      if cd.facility = cd.childfacility and
         cd.item = cd.childitem then
        null;
      else
        zut.prt(mp.lpid || ' multiple-item child mismatch: ' || cd.lpid);
        cntErr := cntErr + 1;
        qtyErr := qtyErr + 1;
        if updflag = 'Y' then
          update plate
             set childfacility = facility,
                 childitem = item
           where lpid = cd.lpid;
          commit;
        end if;
      end if;
    end loop;
  end if;
<<continue_parent_loop>>
  null;
end loop;

zut.prt('tot count: ' || cntTot || ' tot quantity: ' || qtyTot);
zut.prt('err count: ' || cntErr || ' err quantity: ' || qtyErr);
zut.prt('oky count: ' || cntOky || ' oky quantity: ' || qtyOky);
zut.prt('qty count: ' || cntQty || ' qty quantity: ' || qtyQty);

cntTot := 0;
qtyTot := 0;
for xx in curOrphans
loop
  zut.prt('Orphan LiP: ' || xx.lpid || ' parent: ' || xx.parentlpid);
  cntTot := cntTot + 1;
  qtyTot := qtyTot + xx.quantity;
end loop;
zut.prt('tot count: ' || cntTot || ' tot quantity: ' || qtyTot);

exception when others then
  zut.prt('when others');
  zut.prt(sqlerrm);
end;
/
exit;

