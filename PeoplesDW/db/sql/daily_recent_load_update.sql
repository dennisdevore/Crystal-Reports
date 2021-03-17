set serveroutput on;
set flush on;

declare

cursor curLoads is
  select rowid,loadno, loadstatus,statusupdate
    from loads
   where recent_loadno >= 0;

cursor curCustomer(in_loadno number) is
  select max(nvl(recent_order_days,30)) as recent_order_days
    from customer
   where custid in
 (select custid
    from orderhdr
   where loadno = in_loadno) ;
cu curCustomer%rowtype;

cntTot integer;
cntOky integer;
strMsg varchar2(255);

begin

zut.prt('begin recent_loadno update');

cntTot := 0;
cntOky := 0;

zms.log_msg('RECENT', null, null,
            'Begin Recent LoadNo Update',
            'I', 'RECENT', strMsg);
commit;

for ld in curLoads
loop

  cntTot := cntTot + 1;

  if ld.loadstatus in ('9','X','R') then

    cu.recent_order_days := 30;
    open curCustomer(ld.loadno);
    fetch curCustomer into cu;
    close curCustomer;

    if ld.statusupdate < sysdate - cu.recent_order_days then

      update loads
         set recent_loadno = null
       where rowid = ld.rowid;

      cntOky := cntOky + 1;

      if mod(cntTot,1000) = 0 then
        commit;
        zut.prt('Update count ' || cntTot || '...');
      end if;

    end if;

  end if;

end loop;

commit;

zms.log_msg('RECENT', null, null,
            'End Recent Load Update (Processed: ' || cntTot || ' Updated: ' || cntOky || ')',
            'I', 'RECENT', strMsg);

commit;

zut.prt('Total records processed: ' || cntTot);
zut.prt('Total records updated:   ' || cntOky);

zut.prt('end recent_load update');

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit;
