--
-- $Id$
--
set serveroutput on;
spool auditloadstoptotals.out;

declare

cursor curLoadStop is
  select *
    from loadstop
   order by loadno,stopno;

cursor curLoadStopShipSum(in_loadno number, in_stopno number) is
  select nvl(sum(nvl(qtyorder,0)),0) as qtyorder,
         nvl(sum(nvl(cubeorder,0)),0) as cubeorder,
         nvl(sum(nvl(weightorder,0)),0) as weightorder,
         nvl(sum(nvl(amtorder,0)),0) as amtorder,
         nvl(sum(nvl(qtyship,0)),0) as qtyship,
         nvl(sum(nvl(cubeship,0)),0) as cubeship,
         nvl(sum(nvl(weightship,0)),0) as weightship,
         nvl(sum(nvl(amtship,0)),0) as amtship
    from loadstopship
   where loadno = in_loadno
     and stopno = in_stopno;
lss curLoadStopShipSum%rowtype;
cntTot integer;
cntOky integer;
cntErr integer;
updflag varchar2(1);

begin

cntTot := 0;
cntOky := 0;
cntErr := 0;

updflag := upper('&in_updflag');

for lds in curLoadStop
loop

  cntTot := cntTot + 1;

  lss := null;
  open curLoadStopShipSum(lds.loadno,lds.stopno);
  fetch curLoadStopShipSum into lss;
  close curLoadStopShipSum;

  if nvl(lds.qtyship,0) != nvl(lss.qtyship,0) or
     nvl(lds.qtyorder,0) != nvl(lss.qtyorder,0) then
    if nvl(lds.qtyorder,0) != nvl(lss.qtyorder,0) then
      zut.prt(lds.loadno ||
        ' stop qtyorder: ' || lds.qtyorder || ' ship qtyorder: ' ||
        lss.qtyorder || ' ' || lds.lastupdate);
    end if;
    if nvl(lds.qtyship,0) != nvl(lss.qtyship,0) then
      zut.prt(lds.loadno ||
        ' stop qtyship: ' || lds.qtyship || ' ship qtyship: ' ||
        lss.qtyship || ' ' || lds.lastupdate);
    end if;
    cntErr := cntErr + 1;
    if updflag = 'Y' then
      update loadstop
         set qtyorder = lss.qtyorder,
             cubeorder = lss.cubeorder,
             weightorder = lss.weightorder,
             amtorder = lss.amtorder,
             qtyship = lss.qtyship,
             cubeship = lss.cubeship,
             weightship = lss.weightship,
             amtship = lss.amtship
       where loadno = lds.loadno
         and stopno = lds.stopno;
      commit;
    end if;
  else
    cntOky := cntOky + 1;
  end if;
end loop;

zut.prt('Tot: ' || cntTot);
zut.prt('Oky: ' || cntOky);
zut.prt('Err: ' || cntErr);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit;
