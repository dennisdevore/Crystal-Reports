--
-- $Id$
--
set serveroutput on;
set flush on;

declare

cursor curOrderHdr is
  select rowid
    from orderhdr
   where recent_order_id is null
     and (  (orderstatus < '9') or
            (orderstatus >= '9' and statusupdate > sysdate - 30)  );

cntTot integer;

begin

zut.prt('begin recent_order update');

cntTot := 0;

for oh in curOrderHdr
loop

  update orderhdr
     set recent_order_id = 'Y' || orderid || '-' || shipid
   where rowid = oh.rowid;

  cntTot := cntTot + 1;

  if mod(cntTot,1000) = 0 then
    commit;
    zut.prt('Update count ' || cntTot || '...');
  end if;

end loop;

commit;

zut.prt('Total records updated: ' || cntTot);

zut.prt('end recent_order update');

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
--exit;
