--
-- $Id$
--
set serveroutput on;

declare

cursor curCustItem is
  select rowid,
         custid,
         item,
         ctostoprefix
    from custitem
   where custid = 'HP';

intCtoStoPrefix integer;
out_errorno integer;
updflag char(1);
cntTot integer;
cntUpd integer;

begin

updflag := upper('&1');

cntTot := 0;
cntUpd := 0;

for ci in curCustItem
loop

  cntTot := cntTot + 1;

  zmi3.get_cto_sto_prefix(ci.CustId,ci.item,intCtoStoPrefix);
  if nvl(ci.CtoStoPrefix,0) <> nvl(intCtoStoPrefix,0) then
    cntUpd := cntUpd + 1;
    if updflag = 'Y' then
      update custitem
         set ctostoprefix = intCtoStoPrefix
       where rowid = ci.rowid;
    end if;
  end if;

end loop;

zut.prt('Total   ' || cntTot);
zut.prt('Updated ' || cntUpd);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
--exit;
