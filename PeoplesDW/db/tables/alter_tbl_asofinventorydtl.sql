--
-- $Id$
--
set serveroutput on;

alter table asofinventorydtl
modify
(reason varchar2(12)
);

declare
  cursor curAsOfDtl is
    select rowid,reason
      from asofinventorydtl
     where trantype = 'AD'
       and length(trim(reason)) = 2;

strReasonAbbrev adjustmentreasons.abbrev%type;
cntRows integer;
begin

zut.prt('begin asof reason conversion...');

cntRows := 0;

for ao in curAsOfDtl
loop
  begin
    select abbrev
      into strReasonAbbrev
      from adjustmentreasons
     where code = ao.reason;
  exception when others then
    strReasonAbbrev := ao.reason;
  end;
  update asofinventorydtl
     set reason = strReasonAbbrev
   where rowid = ao.rowid;
  cntRows := cntRows + 1;
  if mod(cntRows, 1000) = 0 then
    commit;
    zut.prt('Rows processed: ' || cntRows || '...');
  end if;
end loop;

commit;
zut.prt('Totals rows processed: ' || cntRows);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
--exit;