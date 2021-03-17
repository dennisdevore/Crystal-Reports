--
-- $Id$
--
set serveroutput on;
spool auditloadstopship.out

declare

cursor curLoadStopShip is
  select *
    from loadstopship
   order by loadno,stopno,shipno;

cursor curOrderHdrSum(in_loadno number, in_stopno number, in_shipno number) is
  select nvl(sum(nvl(qtyorder,0)),0) as qtyorder,
         nvl(sum(nvl(cubeorder,0)),0) as cubeorder,
         nvl(sum(nvl(weightorder,0)),0) as weightorder,
         nvl(sum(nvl(amtorder,0)),0) as amtorder,
         nvl(sum(nvl(qtyship,0)),0) as qtyship,
         nvl(sum(nvl(cubeship,0)),0) as cubeship,
         nvl(sum(nvl(weightship,0)),0) as weightship,
         nvl(sum(nvl(amtship,0)),0) as amtship
    from orderhdr
   where loadno = in_loadno
     and stopno = in_stopno
     and shipno = in_shipno;
ohs curOrderHdrSum%rowtype;
cntTot integer;
cntOky integer;
cntErr integer;
updflag varchar2(1);

begin

cntTot := 0;
cntOky := 0;
cntErr := 0;

updflag := upper('&in_updflag');

for lss in curLoadStopShip
loop

  cntTot := cntTot + 1;

  ohs := null;
  open curOrderHdrSum(lss.loadno,lss.stopno,lss.shipno);
  fetch curOrderHdrSum into ohs;
  close curOrderHdrSum;

  if nvl(lss.qtyship,0) != nvl(ohs.qtyship,0) or
     nvl(lss.qtyorder,0) != nvl(ohs.qtyorder,0) then
    if nvl(lss.qtyorder,0) != nvl(ohs.qtyorder,0) then
      zut.prt(lss.loadno || '/' || lss.stopno || '/' || lss.shipno ||
        ' lss qtyorder: ' || lss.qtyorder || ' order qtyorder: ' ||
        ohs.qtyorder || ' ' || lss.lastupdate);
    end if;
    if nvl(lss.qtyship,0) != nvl(ohs.qtyship,0) then
      zut.prt(lss.loadno || '/' || lss.stopno || '/' || lss.shipno ||
        ' lss qtyship: ' || lss.qtyship || ' order qtyship: ' ||
        ohs.qtyship || ' ' || lss.lastupdate);
    end if;
    cntErr := cntErr + 1;
    if updflag = 'Y' then
      update loadstopship
         set qtyorder = ohs.qtyorder,
             cubeorder = ohs.cubeorder,
             weightorder = ohs.weightorder,
             amtorder = ohs.amtorder,
             qtyship = ohs.qtyship,
             cubeship = ohs.cubeship,
             weightship = ohs.weightship,
             amtship = ohs.amtship
       where loadno = lss.loadno
         and stopno = lss.stopno
         and shipno = lss.shipno;
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
