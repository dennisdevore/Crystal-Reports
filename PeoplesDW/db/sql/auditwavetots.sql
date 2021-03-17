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
okyflag varchar2(1);
out_msg varchar2(255);

cursor curWaves is
  select wave,
         nvl(cntorder,0) as cntorder,
         nvl(qtyorder,0) as qtyorder,
         nvl(weightorder,0) as weightorder,
         nvl(cubeorder,0) as cubeorder,
         nvl(qtycommit,0) as qtycommit,
         nvl(weightcommit,0) as weightcommit,
         nvl(cubecommit,0) as cubecommit,
         nvl(staffhrs,0) as staffhrs
    from waves
   order by wave;
wv curWaves%rowtype;

cursor curOrderHdrSum(in_wave number) is
  select count(1) as cntorder,
         nvl(sum(qtyorder),0) as qtyorder,
         nvl(sum(weightorder),0) as weightorder,
         nvl(sum(cubeorder),0) as cubeorder,
         nvl(sum(qtycommit),0) as qtycommit,
         nvl(sum(weightcommit),0) as weightcommit,
         nvl(sum(cubecommit),0) as cubecommit,
         nvl(sum(staffhrs),0) as staffhrs
    from orderhdr
   where wave = in_wave;
ohs curOrderHdrSum%rowtype;

cursor curOrderHdrWaves is
  select wave,
         count(1) as cntorder,
         nvl(sum(qtyorder),0) as qtyorder,
         nvl(sum(weightorder),0) as weightorder,
         nvl(sum(cubeorder),0) as cubeorder,
         nvl(sum(qtycommit),0) as qtycommit,
         nvl(sum(weightcommit),0) as weightcommit,
         nvl(sum(cubecommit),0) as cubecommit,
         nvl(sum(staffhrs),0) as staffhrs
    from orderhdr
   where nvl(wave,0) != 0
   group by wave
   order by wave;
ohw curOrderHdrWaves%rowtype;

cursor curWavesDtl(in_wave number) is
  select wave,
         nvl(cntorder,0) as cntorder,
         nvl(qtyorder,0) as qtyorder,
         nvl(weightorder,0) as weightorder,
         nvl(cubeorder,0) as cubeorder,
         nvl(qtycommit,0) as qtycommit,
         nvl(weightcommit,0) as weightcommit,
         nvl(cubecommit,0) as cubecommit,
         nvl(staffhrs,0) as staffhrs
    from waves
   where wave = in_wave;
wvd curWavesDtl%rowtype;

begin

updflag := upper('&&1');
totcount := 0;
okycount := 0;
ntfcount := 0;
qtycount := 0;
dtlcount := 0;

zut.prt('comparing waves to order header...');
open curWaves;
while(1=1)
loop
  fetch curWaves into wv;
  if curWaves%notfound then
    exit;
  end if;
  totcount := totcount + 1;
  open curOrderHdrSum(wv.wave);
  fetch curOrderHdrSum into ohs;
  if curOrderHdrSum%notfound then
    if  wv.cntorder != 0 or
        wv.qtyorder != 0 or
        wv.weightorder != 0 or
        wv.cubeorder != 0 or
        wv.qtycommit != 0 or
        wv.weightcommit != 0 or
        wv.cubecommit != 0 or
        wv.staffhrs != 0 then
      zut.prt('orderhdr not found for wave: ' || wv.wave);
      ntfcount := ntfcount + 1;
      if updflag = 'Y' then
        update waves
           set cntorder = 0,
               qtyorder = 0,
               weightorder = 0,
               cubeorder = 0,
               qtycommit = 0,
               weightcommit = 0,
               cubecommit = 0
         where wave = wv.wave;
        commit;
      end if;
    else
      dtlcount := dtlcount + 1;
    end if;
  else
    okyflag := 'Y';
    if (wv.cntorder != ohs.cntorder) then
      zut.prt('cntorder mismatch: ');
      zut.prt(wv.wave || ' ' ||
        wv.cntorder || ' ' || ohs.cntorder);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update waves
           set cntorder = ohs.cntorder
         where wave = wv.wave;
        commit;
      end if;
    end if;
    if (wv.qtyorder != ohs.qtyorder) then
      zut.prt('qtyorder mismatch: ');
      zut.prt(wv.wave || ' ' ||
        wv.qtyorder || ' ' || ohs.qtyorder);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update waves
           set qtyorder = ohs.qtyorder
         where wave = wv.wave;
        commit;
      end if;
    end if;
    if (wv.weightorder != ohs.weightorder) then
      zut.prt('weightorder mismatch: ');
      zut.prt(wv.wave || ' ' ||
        wv.weightorder || ' ' || ohs.weightorder);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update waves
           set weightorder = ohs.weightorder
         where wave = wv.wave;
        commit;
      end if;
    end if;
    if (wv.cubeorder != ohs.cubeorder) then
      zut.prt('cubeorder mismatch: ');
      zut.prt(wv.wave || ' ' ||
        wv.cubeorder || ' ' || ohs.cubeorder);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update waves
           set cubeorder = ohs.cubeorder
         where wave = wv.wave;
        commit;
      end if;
    end if;
    if (wv.qtycommit != ohs.qtycommit) then
      zut.prt('qtycommit mismatch: ');
      zut.prt(wv.wave || ' ' ||
        wv.qtycommit || ' ' || ohs.qtycommit);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update waves
           set qtycommit = ohs.qtycommit
         where wave = wv.wave;
        commit;
      end if;
    end if;
    if (wv.weightcommit != ohs.weightcommit) then
      zut.prt('weightcommit mismatch: ');
      zut.prt(wv.wave || ' ' ||
        wv.weightcommit || ' ' || ohs.weightcommit);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update waves
           set weightcommit = ohs.weightcommit
         where wave = wv.wave;
        commit;
      end if;
    end if;
    if (wv.cubecommit != ohs.cubecommit) then
      zut.prt('cubecommit mismatch: ');
      zut.prt(wv.wave || ' ' ||
        wv.cubecommit || ' ' || ohs.cubecommit);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update waves
           set cubecommit = ohs.cubecommit
         where wave = wv.wave;
        commit;
      end if;
    end if;
    if (wv.staffhrs != ohs.staffhrs) then
      zut.prt('staffhrs mismatch: ');
      zut.prt(wv.wave || ' ' ||
        wv.staffhrs || ' ' || ohs.staffhrs);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update waves
           set staffhrs = ohs.staffhrs
         where wave = wv.wave;
        commit;
      end if;
    end if;
    if okyflag = 'Y' then
      okycount := okycount + 1;
    end if;
  end if;
  close curOrderHdrSum;
end loop;
close curWaves;

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

zut.prt('Comparing order header to order waves...');
open curOrderHdrWaves;
while(1=1)
loop
  fetch curOrderHdrWaves into ohw;
  if curOrderHdrWaves%notfound then
    exit;
  end if;
  totcount := totcount + 1;
  open curWavesDtl(ohw.wave);
  fetch curWavesDtl into wvd;
  if curWavesDtl%notfound then
    zut.prt('wave not found: ' || ohw.wave);
    ntfcount := ntfcount + 1;
  else
    okyflag := 'Y';
    if (ohw.cntorder != wvd.cntorder) then
      zut.prt('cntorder mismatch: ');
      zut.prt(ohw.wave || ' ' ||
        ohw.cntorder || ' ' || wvd.cntorder);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
    end if;
    if (ohw.qtyorder != wvd.qtyorder) then
      zut.prt('qtyorder mismatch: ');
      zut.prt(ohw.wave || ' ' ||
        ohw.qtyorder || ' ' || wvd.qtyorder);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
    end if;
    if (ohw.weightorder != wvd.weightorder) then
      zut.prt('weightorder mismatch: ');
      zut.prt(ohw.wave || ' ' ||
        ohw.weightorder || ' ' || wvd.weightorder);
      okyflag := 'N';
      qtycount := qtycount + 1;
    end if;
    if (ohw.cubeorder != wvd.cubeorder) then
      zut.prt('cubeorder mismatch: ');
      zut.prt(ohw.wave || ' ' ||
        ohw.cubeorder || ' ' || wvd.cubeorder);
      qtycount := qtycount + 1;
      okyflag := 'N';
    end if;
    if (ohw.qtycommit != wvd.qtycommit) then
      zut.prt('qtycommit mismatch: ');
      zut.prt(ohw.wave || ' ' ||
        ohw.qtycommit || ' ' || wvd.qtycommit);
      qtycount := qtycount + 1;
      okyflag := 'N';
    end if;
    if (ohw.weightcommit != wvd.weightcommit) then
      zut.prt('weightcommit mismatch: ');
      zut.prt(ohw.wave || ' ' ||
        ohw.weightcommit || ' ' || wvd.weightcommit);
      okyflag := 'N';
      qtycount := qtycount + 1;
    end if;
    if (ohw.cubecommit != wvd.cubecommit) then
      zut.prt('cubecommit mismatch: ');
      zut.prt(ohw.wave || ' ' ||
        ohw.cubecommit || ' ' || wvd.cubecommit);
      qtycount := qtycount + 1;
      okyflag := 'N';
    end if;
    if (ohw.staffhrs != wvd.staffhrs) then
      zut.prt('staffhrs mismatch: ');
      zut.prt(ohw.wave || ' ' ||
        ohw.staffhrs || ' ' || wvd.staffhrs);
      qtycount := qtycount + 1;
      okyflag := 'N';
    end if;
    if okyflag = 'Y' then
      okycount := okycount + 1;
    end if;
  end if;
  close curWavesDtl;
end loop;
close curOrderHdrWaves;

zut.prt('totcount: ' || totcount);
zut.prt('okycount: ' || okycount);
zut.prt('ntfcount: ' || ntfcount);
zut.prt('qtycount: ' || qtycount);
zut.prt('dtlcount: ' || dtlcount);

zut.prt('end of wave total audit');

exception when others then
  zut.prt(sqlerrm);
end;
/
exit;