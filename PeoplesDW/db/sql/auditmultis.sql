--
-- $Id$
--
set serveroutput on;

begin

declare

cursor curMultiSelect is
  select lpid,
         facility,
         location,
         quantity
    from plate
   where type = 'MP'
     and status = 'A';

cursor curMultiDtl(in_parentlpid varchar2) is
  select facility,
         location,
         sum(quantity) as quantity
    from plate
   where parentlpid = in_parentlpid
     and status = 'A'
   group by facility,location;

cursor curChildSelect is
  select parentlpid as lpid,
         facility,
         location,
         sum(quantity) as quantity
    from plate
   where type = 'PA'
     and status = 'A'
     and parentlpid is not null
   group by parentlpid,facility,location;

cursor curChildDtl(in_parentlpid varchar2) is
  select facility,
         location,
         quantity
    from plate
   where lpid = in_parentlpid
     and status = 'A';

out_msg varchar2(255);
out_errorno integer;
updflag char(1);
cntRows integer;
cntTot integer;
qtyTot integer;
cntErr integer;
qtyErr integer;
cntOky integer;
qtyOky integer;
cntSkp integer;
qtySkp integer;
qtyMulti integer;
qtyDtl integer;
begdate date;

function recently_updated(in_lpid varchar2)
return boolean is

cntRows integer;

begin

select count(1)
  into cntRows
  from plate
 where lpid = in_lpid
   and lastupdate >= begdate - .006944;

if cntRows = 0 then
  return False;
else
  return True;
end if;

exception when others then
  return True;
end recently_updated;

begin

cntTot := 0;
cntErr := 0;
cntOky := 0;
cntSkp := 0;
qtyTot := 0;
qtyErr := 0;
qtyOky := 0;
qtySkp := 0;

zut.prt('begin multi check. . .');

updflag := upper('&1');

begdate := sysdate;

for sl in curMultiSelect
loop

  cntTot := cntTot + 1;
  qtyTot := qtyTot + sl.quantity;

--  zut.prt('processing ' || sl.lpid || '-' || sl.facility ||
--    ' ' || sl.location || ' ' || sl.quantity);

  qtyMulti := sl.quantity;
  qtyDtl := 0;
  for md in curMultiDtl(sl.lpid)
  loop
    qtyMulti := qtyMulti - md.quantity;
    qtyDtl := qtyDtl + md.quantity;
  end loop;
  if qtyMulti <> 0 then
    zut.prt('** multi quantity ' || sl.lpid || '-' || sl.facility ||
    ' ' || sl.location || ' ' || sl.quantity || ' ' || qtyDtl);
    if qtyDtl = 0 then
      if recently_updated(sl.lpid) then
        zut.prt('skipped because of recent update');
        cntSkp := cntSkp + 1;
        qtySkp := qtySkp + qtyMulti;
      else
        zut.prt('multi will be deleted');
        cntErr := cntErr + 1;
        qtyErr := qtyErr + qtyMulti;
        if updflag = 'Y' then
          zlp.plate_to_deletedplate(sl.lpid,'ZDEL','AJ',out_msg);
          if out_msg is not null then
            zut.prt(out_msg);
          end if;
          commit;
        end if;
      end if;
    else
      if recently_updated(sl.lpid) then
        zut.prt('skipped because of recent update');
        cntSkp := cntSkp + 1;
        qtySkp := qtySkp + qtyMulti;
      else
        zut.prt('multi will be updated');
        cntErr := cntErr + 1;
        qtyErr := qtyErr + qtyMulti;
        if updflag = 'Y' then
          update plate
             set quantity = qtyDtl,
                 lasttask = 'AJ',
                 lastuser = 'ZADJ',
                 lastupdate = sysdate
           where lpid = sl.lpid;
          commit;
        end if;
      end if;
    end if;
  else
    cntOky := cntOky + 1;
    qtyOky := qtyOky + sl.quantity;
  end if;

end loop;

zut.prt('total count: ' || cntTot || ' total quantity: ' || qtyTot);
zut.prt('error count: ' || cntErr || ' error quantity: ' || qtyErr);
zut.prt('okay  count: ' || cntOky || ' okay  quantity: ' || qtyOky);
zut.prt('skip count: ' || cntSkp || ' error quantity: ' || qtySkp);

zut.prt('end multi loop . . .');

zut.prt('begin child check. . .');

cntTot := 0;
cntErr := 0;
cntOky := 0;
cntSkp := 0;
qtyTot := 0;
qtyErr := 0;
qtyOky := 0;
qtySkp := 0;

for sl in curChildSelect
loop

  cntTot := cntTot + 1;
  qtyTot := qtyTot + sl.quantity;

--  zut.prt('processing ' || sl.lpid || '-' || sl.facility ||
--    ' ' || sl.location || ' ' || sl.quantity);

  qtyMulti := sl.quantity;
  qtyDtl := 0;
  for md in curChildDtl(sl.lpid)
  loop
    qtyMulti := qtyMulti - md.quantity;
    qtyDtl := qtyDtl + md.quantity;
  end loop;
  if qtyMulti <> 0 then
    zut.prt('**quantity ' || sl.lpid || '-' || sl.facility ||
            ' ' || sl.location || ' ' || sl.quantity || ' ' || qtyDtl);
    if recently_updated(sl.lpid) then
      zut.prt('skipped because of recent update');
      cntSkp := cntSkp + 1;
      qtySkp := qtySkp + qtyMulti;
    else
      cntErr := cntErr + 1;
      qtyErr := qtyErr + qtyMulti;
    end if;
  else
    cntOky := cntOky + 1;
    qtyOky := qtyOky + sl.quantity;
  end if;

end loop;

zut.prt('total count: ' || cntTot || ' total quantity: ' || qtyTot);
zut.prt('error count: ' || cntErr || ' error quantity: ' || qtyErr);
zut.prt('okay  count: ' || cntOky || ' okay  quantity: ' || qtyOky);
zut.prt('skip count: ' || cntSkp || ' error quantity: ' || qtySkp);

zut.prt('end multi loop . . .');

exception when others then
  zut.prt('when others');
  zut.prt(sqlerrm);
end;

end;
/
exit;
