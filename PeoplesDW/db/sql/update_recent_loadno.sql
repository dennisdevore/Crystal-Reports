set serveroutput on;
set flush on;

declare

cursor curLoads is
  select rowid
    from loads
   where recent_loadno is null
     and (  (loadstatus < '9') or (loadstatus = 'A') or
            (loadstatus in ('9','X','R') and statusupdate > sysdate - 30)  );

cntTot integer;

begin

zut.prt('begin recent_load update');

cntTot := 0;

for ld in curLoads
loop

  update loads
     set recent_loadno = loadno
   where rowid = ld.rowid;

  cntTot := cntTot + 1;

  if mod(cntTot,1000) = 0 then
    commit;
    zut.prt('Update count ' || cntTot || '...');
  end if;

end loop;

commit;

zut.prt('Total records updated: ' || cntTot);

zut.prt('end recent_loadno update');

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
--exit;
