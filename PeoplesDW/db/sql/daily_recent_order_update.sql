--
-- $Id$
--
set serveroutput on;
set flush on;

declare

cursor curOrderHdr is
  select rowid,custid,orderstatus,statusupdate
    from orderhdr
   where recent_order_id like 'Y%';

cursor curCustomer(in_custid varchar2) is
  select nvl(recent_order_days,30) as recent_order_days
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cntTot integer;
cntOky integer;
strCustId customer.custid%type;
strMsg varchar2(255);

begin

zut.prt('begin recent_order update');

cntTot := 0;
cntOky := 0;
strCustid := 'x';

zms.log_msg('RECENT', null, null,
            'Begin Recent Order Update',
            'I', 'RECENT', strMsg);
commit;

for oh in curOrderHdr
loop

  cntTot := cntTot + 1;

  if oh.orderstatus >= '9' then

    if strCustid != oh.custid then
      cu.recent_order_days := 30;
      open curCustomer(oh.custid);
      fetch curCustomer into cu;
      close curCustomer;
      strCustId := oh.custid;
    end if;

    if oh.statusupdate < sysdate - cu.recent_order_days then

      update orderhdr
         set recent_order_id = null
       where rowid = oh.rowid;

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
            'End Recent Order Update (Processed: ' || cntTot || ' Updated: ' || cntOky || ')',
            'I', 'RECENT', strMsg);

commit;

zut.prt('Total records processed: ' || cntTot);
zut.prt('Total records updated:   ' || cntOky);

zut.prt('end recent_order update');

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit;
