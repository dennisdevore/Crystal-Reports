--
-- $Id$
--
set serveroutput on;

declare
notfound boolean;
totcount integer;
qtycount integer;
dtlcount integer;
ntfcount integer;
okycount integer;
updflag varchar2(1);
out_msg varchar2(255);

cursor curOrderLaborSum is
  select orderid,
         shipid,
         item,
         lotnumber,
         sum(nvl(staffhrs,0)) as staffhrs
    from orderlabor
   group by orderid, shipid, item, lotnumber
   order by orderid, shipid, item, lotnumber;
ols curOrderLaborSum%rowtype;

cursor curOrderDtl is
  select nvl(staffhrs,0) as staffhrs
    from orderdtl
   where orderid = ols.orderid
     and shipid = ols.shipid
     and item = ols.item
     and nvl(lotnumber,'(none)') = nvl(ols.lotnumber,'(none)');
od curOrderDtl%rowtype;

cursor curOrderDtlSum is
  select orderid,
         shipid,
         item,
         lotnumber,
         nvl(staffhrs,0) as staffhrs
    from OrderDtl
   where nvl(staffhrs,0) != 0
   order by orderid, shipid, item, lotnumber;
ods curOrderDtlSum%rowtype;

cursor curOrderLabor is
  select sum(nvl(staffhrs,0)) as staffhrs
    from orderlabor
   where orderid = ods.orderid
     and shipid = ods.shipid
     and item = ods.item
     and nvl(lotnumber,'(none)') = nvl(ods.lotnumber,'(none)');
ol curOrderLabor%rowtype;


begin

updflag := upper('&&1');
totcount := 0;
okycount := 0;
ntfcount := 0;
qtycount := 0;
dtlcount := 0;

zut.prt('Comparing labor summary to order detail...');
open curOrderLaborSum;
while(1=1)
loop
  fetch curOrderLaborSum into ols;
  if curOrderLaborSum%notfound then
    exit;
  end if;
  totcount := totcount + 1;
  open curOrderDtl;
  fetch curOrderDtl into od;
  if curOrderDtl%notfound then
    zut.prt('orderdtl not found: ');
    zut.prt(ols.orderid || ' ' ||
      ols.shipid || ' ' ||
      ols.item || ' ' ||
      nvl(ols.lotnumber,'(none)') || ' ' ||
      ols.staffhrs);
    ntfcount := ntfcount + 1;
    if updflag = 'Y' then
      delete from orderlabor
       where orderid = ols.orderid
         and shipid = ols.shipid
         and item = ols.item
         and nvl(lotnumber,'(none)') = nvl(ols.lotnumber,'(none)');
      commit;
    end if;
  else
    if (ols.staffhrs = od.staffhrs) then
      okycount := okycount + 1;
    else
      zut.prt('staffhrs mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.item || ' ' ||
        nvl(ols.lotnumber,'(none)') || ' ' ||
        ols.staffhrs || ' ' || od.staffhrs);
      qtycount := qtycount + 1;
      if updflag = 'Y' then
        update orderdtl
           set staffhrs = ols.staffhrs
         where orderid = ols.orderid
           and shipid = ols.shipid
           and item = ols.item
           and nvl(lotnumber,'(none)') = nvl(ols.lotnumber,'(none)');
        commit;
      end if;
    end if;
  end if;
  close curOrderDtl;
end loop;
close curOrderLaborSum;

zut.prt('totcount: ' || totcount);
zut.prt('okycount: ' || okycount);
zut.prt('ntfcount: ' || ntfcount);
zut.prt('qtycount: ' || qtycount);
zut.prt('dtlcount: ' || dtlcount);

totcount := 0;
okycount := 0;
ntfcount := 0;
qtycount := 0;
dtlcount := 0;

zut.prt('Comparing order detail to labor summary...');
open curOrderDtlSum;
while(1=1)
loop
  fetch curOrderDtlSum into ods;
  if curOrderDtlSum%notfound then
    exit;
  end if;
  totcount := totcount + 1;
  open curOrderLabor;
  fetch curOrderLabor into ol;
  if curOrderLabor%notfound then
    zut.prt('orderlabor not found: ');
    zut.prt(ods.orderid || ' ' ||
      ods.shipid || ' ' ||
      ods.item || ' ' ||
      nvl(ods.lotnumber,'(none)') || ' ' ||
      ods.staffhrs);
    ntfcount := ntfcount + 1;
    if updflag = 'Y' then
      update orderdtl
         set staffhrs = 0
       where orderid = ods.orderid
         and shipid = ods.shipid
         and item = ods.item
         and nvl(lotnumber,'(none)') = nvl(ods.lotnumber,'(none)');
      commit;
    end if;
  else
    if (ods.staffhrs = ol.staffhrs) then
      okycount := okycount + 1;
    else
      zut.prt('staffhrs mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.item || ' ' ||
        nvl(ods.lotnumber,'(none)') || ' ' ||
        ods.staffhrs || ' ' || ol.staffhrs);
      qtycount := qtycount + 1;
      if updflag = 'Y' then
        update orderdtl
           set staffhrs = ol.staffhrs
         where orderid = ods.orderid
           and shipid = ods.shipid
           and item = ods.item
           and nvl(lotnumber,'(none)') = nvl(ods.lotnumber,'(none)');
        commit;
      end if;
    end if;
  end if;
  close curOrderLabor;
end loop;
close curOrderDtlSum;

zut.prt('totcount: ' || totcount);
zut.prt('okycount: ' || okycount);
zut.prt('ntfcount: ' || ntfcount);
zut.prt('qtycount: ' || qtycount);
zut.prt('dtlcount: ' || dtlcount);

zut.prt('end of orderlabor audit');

exception when others then
  zut.prt(sqlerrm);
end;
/
exit;