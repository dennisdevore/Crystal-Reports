--
-- $Id$
--
alter table custconsignee add
(
export_format_856  varchar2(35)
);

set serveroutput on;
set flush on;

declare
cntRows integer;

begin

cntRows := 0;

for cc in (select rowid
             from custconsignee
            where export_format_856 is null)
loop
  update custconsignee
     set export_format_856 = 'Use SIP Default'
   where rowid = cc.rowid;
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
