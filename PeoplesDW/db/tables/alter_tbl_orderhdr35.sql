alter table ORDERHDR add
(
  is_returns_order  varchar2(18)
);

set serveroutput on;
set flush on;

declare
cntRows integer;
chrFacility char(3);

begin

cntRows := 0;

for oh in (select rowid,tofacility
             from orderhdr
            where ordertype = 'Q'
              and is_returns_order is null)
loop
  chrFacility := oh.tofacility;
  update orderhdr
     set is_returns_order = 'Y' || chrFacility || ltrim(to_char(orderid,'09999999999')) || '-' || ltrim(to_char(shipid,'09'))
   where rowid = oh.rowid;
  cntRows := cntRows + 1;
  if mod(cntRows, 1000) = 0 then
    zut.prt('rows processed ' || cntRows || '...');
    commit;
  end if;
end loop;

zut.prt('rows updated: ' || cntRows);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit;