--
-- $Id$
--
set serveroutput on;

declare
in_orderid integer;
in_shipid integer;
notfound boolean;
skpcount integer;
totcount integer;
qtycount integer;
dtlcount integer;
ntfcount integer;
okycount integer;
updflag varchar2(1);
dtlflag varchar2(1);
okyflag varchar2(1);
out_msg varchar2(255);
fromentrydate varchar2(14);
toentrydate varchar2(14);

cursor curOrderHdrSum is
  select orderid,
         shipid,
         nvl(qtyorder,0) as qtyorder,
         nvl(weightorder,0) as weightorder,
         nvl(cubeorder,0) as cubeorder,
         nvl(amtorder,0) as amtorder,
         nvl(qtycommit,0) as qtycommit,
         nvl(weightcommit,0) as weightcommit,
         nvl(cubecommit,0) as cubecommit,
         nvl(amtcommit,0) as amtcommit,
         nvl(qtyship,0) as qtyship,
         nvl(weightship,0) as weightship,
         nvl(cubeship,0) as cubeship,
         nvl(amtship,0) as amtship,
         nvl(qtytotcommit,0) as qtytotcommit,
         nvl(weighttotcommit,0) as weighttotcommit,
         nvl(cubetotcommit,0) as cubetotcommit,
         nvl(amttotcommit,0) as amttotcommit,
         nvl(qtyrcvd,0) as qtyrcvd,
         nvl(weightrcvd,0) as weightrcvd,
         nvl(cubercvd,0) as cubercvd,
         nvl(amtrcvd,0) as amtrcvd,
         nvl(qtypick,0) as qtypick,
         nvl(weightpick,0) as weightpick,
         nvl(cubepick,0) as cubepick,
         nvl(amtpick,0) as amtpick,
         nvl(qty2sort,0) as qty2sort,
         nvl(weight2sort,0) as weight2sort,
         nvl(cube2sort,0) as cube2sort,
         nvl(amt2sort,0) as amt2sort,
         nvl(qty2pack,0) as qty2pack,
         nvl(weight2pack,0) as weight2pack,
         nvl(cube2pack,0) as cube2pack,
         nvl(amt2pack,0) as amt2pack,
         nvl(qty2check,0) as qty2check,
         nvl(weight2check,0) as weight2check,
         nvl(cube2check,0) as cube2check,
         nvl(amt2check,0) as amt2check,
         nvl(staffhrs,0) as staffhrs,
			to_char(lastupdate, 'mm/dd/yyyy hh24:mi:ss') as lastupdate
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid
   order by orderid, shipid;
ols curorderhdrSum%rowtype;

cursor curOrderDtl is
  select sum(nvl(qtyorder,0)) as qtyorder,
         sum(nvl(weightorder,0)) as weightorder,
         sum(nvl(cubeorder,0)) as cubeorder,
         sum(nvl(amtorder,0)) as amtorder,
         sum(nvl(qtycommit,0)) as qtycommit,
         sum(nvl(weightcommit,0)) as weightcommit,
         sum(nvl(cubecommit,0)) as cubecommit,
         sum(nvl(amtcommit,0)) as amtcommit,
         sum(nvl(qtyship,0)) as qtyship,
         sum(nvl(weightship,0)) as weightship,
         sum(nvl(cubeship,0)) as cubeship,
         sum(nvl(amtship,0)) as amtship,
         sum(nvl(qtytotcommit,0)) as qtytotcommit,
         sum(nvl(weighttotcommit,0)) as weighttotcommit,
         sum(nvl(cubetotcommit,0)) as cubetotcommit,
         sum(nvl(amttotcommit,0)) as amttotcommit,
         sum(nvl(qtyrcvd,0)) as qtyrcvd,
         sum(nvl(weightrcvd,0)) as weightrcvd,
         sum(nvl(cubercvd,0)) as cubercvd,
         sum(nvl(amtrcvd,0)) as amtrcvd,
         sum(nvl(qtypick,0)) as qtypick,
         sum(nvl(weightpick,0)) as weightpick,
         sum(nvl(cubepick,0)) as cubepick,
         sum(nvl(amtpick,0)) as amtpick,
         sum(nvl(qty2sort,0)) as qty2sort,
         sum(nvl(weight2sort,0)) as weight2sort,
         sum(nvl(cube2sort,0)) as cube2sort,
         sum(nvl(amt2sort,0)) as amt2sort,
         sum(nvl(qty2pack,0)) as qty2pack,
         sum(nvl(weight2pack,0)) as weight2pack,
         sum(nvl(cube2pack,0)) as cube2pack,
         sum(nvl(amt2pack,0)) as amt2pack,
         sum(nvl(qty2check,0)) as qty2check,
         sum(nvl(weight2check,0)) as weight2check,
         sum(nvl(cube2check,0)) as cube2check,
         sum(nvl(amt2check,0)) as amt2check,
         sum(nvl(staffhrs,0)) as staffhrs
    from orderdtl
   where orderid = ols.orderid
     and shipid = ols.shipid;
od curOrderDtl%rowtype;

cursor curOrderDtlSum is
  select orderid,
         shipid,
         sum(nvl(qtyorder,0)) as qtyorder,
         sum(nvl(weightorder,0)) as weightorder,
         sum(nvl(cubeorder,0)) as cubeorder,
         sum(nvl(amtorder,0)) as amtorder,
         sum(nvl(qtycommit,0)) as qtycommit,
         sum(nvl(weightcommit,0)) as weightcommit,
         sum(nvl(cubecommit,0)) as cubecommit,
         sum(nvl(amtcommit,0)) as amtcommit,
         sum(nvl(qtyship,0)) as qtyship,
         sum(nvl(weightship,0)) as weightship,
         sum(nvl(cubeship,0)) as cubeship,
         sum(nvl(amtship,0)) as amtship,
         sum(nvl(qtytotcommit,0)) as qtytotcommit,
         sum(nvl(weighttotcommit,0)) as weighttotcommit,
         sum(nvl(cubetotcommit,0)) as cubetotcommit,
         sum(nvl(amttotcommit,0)) as amttotcommit,
         sum(nvl(qtyrcvd,0)) as qtyrcvd,
         sum(nvl(weightrcvd,0)) as weightrcvd,
         sum(nvl(cubercvd,0)) as cubercvd,
         sum(nvl(amtrcvd,0)) as amtrcvd,
         sum(nvl(qtypick,0)) as qtypick,
         sum(nvl(weightpick,0)) as weightpick,
         sum(nvl(cubepick,0)) as cubepick,
         sum(nvl(amtpick,0)) as amtpick,
         sum(nvl(qty2sort,0)) as qty2sort,
         sum(nvl(weight2sort,0)) as weight2sort,
         sum(nvl(cube2sort,0)) as cube2sort,
         sum(nvl(amt2sort,0)) as amt2sort,
         sum(nvl(qty2pack,0)) as qty2pack,
         sum(nvl(weight2pack,0)) as weight2pack,
         sum(nvl(cube2pack,0)) as cube2pack,
         sum(nvl(amt2pack,0)) as amt2pack,
         sum(nvl(qty2check,0)) as qty2check,
         sum(nvl(weight2check,0)) as weight2check,
         sum(nvl(cube2check,0)) as cube2check,
         sum(nvl(amt2check,0)) as amt2check,
         sum(nvl(staffhrs,0)) as staffhrs
    from OrderDtl
   where orderid = in_orderid
     and shipid = in_shipid
   group by orderid, shipid
   order by orderid, shipid;
ods curOrderDtlSum%rowtype;

cursor curOrderhdr is
  select nvl(qtyorder,0) as qtyorder,
         nvl(weightorder,0) as weightorder,
         nvl(cubeorder,0) as cubeorder,
         nvl(amtorder,0) as amtorder,
         nvl(qtycommit,0) as qtycommit,
         nvl(weightcommit,0) as weightcommit,
         nvl(cubecommit,0) as cubecommit,
         nvl(amtcommit,0) as amtcommit,
         nvl(qtyship,0) as qtyship,
         nvl(weightship,0) as weightship,
         nvl(cubeship,0) as cubeship,
         nvl(amtship,0) as amtship,
         nvl(qtytotcommit,0) as qtytotcommit,
         nvl(weighttotcommit,0) as weighttotcommit,
         nvl(cubetotcommit,0) as cubetotcommit,
         nvl(amttotcommit,0) as amttotcommit,
         nvl(qtyrcvd,0) as qtyrcvd,
         nvl(weightrcvd,0) as weightrcvd,
         nvl(cubercvd,0) as cubercvd,
         nvl(amtrcvd,0) as amtrcvd,
         nvl(qtypick,0) as qtypick,
         nvl(weightpick,0) as weightpick,
         nvl(cubepick,0) as cubepick,
         nvl(amtpick,0) as amtpick,
         nvl(qty2sort,0) as qty2sort,
         nvl(weight2sort,0) as weight2sort,
         nvl(cube2sort,0) as cube2sort,
         nvl(amt2sort,0) as amt2sort,
         nvl(qty2pack,0) as qty2pack,
         nvl(weight2pack,0) as weight2pack,
         nvl(cube2pack,0) as cube2pack,
         nvl(amt2pack,0) as amt2pack,
         nvl(qty2check,0) as qty2check,
         nvl(weight2check,0) as weight2check,
         nvl(cube2check,0) as cube2check,
         nvl(amt2check,0) as amt2check,
         nvl(staffhrs,0) as staffhrs
    from orderhdr
   where orderid = ods.orderid
     and shipid = ods.shipid;
ol curorderhdr%rowtype;
begdate date;
cntRows integer;
begin

begdate := sysdate;
updflag := upper('&1');
dtlflag := upper('&2');
in_orderid := &3;
in_shipid := &4;
totcount := 0;
skpcount := 0;
okycount := 0;
ntfcount := 0;
qtycount := 0;
dtlcount := 0;


zut.prt('Comparing order header to order detail...');
open curorderhdrSum;
while(1=1)
loop
  fetch curorderhdrSum into ols;
  if curorderhdrSum%notfound then
    exit;
  end if;
  totcount := totcount + 1;
  begin
	 select count(1)
		into cntRows
		from orderhdr
     where orderid = ols.orderid
		 and shipid = ols.shipid
		 and lastupdate >= begdate - .006944;
  exception when others then
	 cntRows := 0;
  end;
  if cntRows = 1 then
	 zut.prt('Order skipped because of recent update: ' ||
		ols.orderid || '-' || ols.shipid);
	 skpcount := skpcount + 1;
	 goto continue_loop;
  end if;
  open curOrderDtl;
  fetch curOrderDtl into od;
  if curOrderDtl%notfound then
    if  ols.qtyorder != 0 or
        ols.weightorder != 0 or
        ols.cubeorder != 0 or
        ols.amtorder != 0 or
        ols.qtycommit != 0 or
        ols.weightcommit != 0 or
        ols.cubecommit != 0 or
        ols.amtcommit != 0 or
        ols.qtyship != 0 or
        ols.weightship != 0 or
        ols.cubeship != 0 or
        ols.amtship != 0 or
        ols.qtytotcommit != 0 or
        ols.weighttotcommit != 0 or
        ols.cubetotcommit != 0 or
        ols.amttotcommit != 0 or
        ols.qtyrcvd != 0 or
        ols.weightrcvd != 0 or
        ols.cubercvd != 0 or
        ols.amtrcvd != 0 or
        ols.qtypick != 0 or
        ols.weightpick != 0 or
        ols.cubepick != 0 or
        ols.amtpick != 0 or
        ols.qty2sort != 0 or
        ols.weight2sort != 0 or
        ols.cube2sort != 0 or
        ols.amt2sort != 0 or
        ols.qty2pack != 0 or
        ols.weight2pack != 0 or
        ols.cube2pack != 0 or
        ols.amt2pack != 0 or
        ols.qty2check != 0 or
        ols.weight2check != 0 or
        ols.cube2check != 0 or
        ols.amt2check != 0 or
        ols.staffhrs != 0 then
      zut.prt('orderdtl not found: ');
      zut.prt(ols.orderid || ' ' || ols.shipid || ' ' || ols.lastupdate);
      ntfcount := ntfcount + 1;
      if updflag = 'Y' then
        update orderhdr
           set qtyorder = 0,
               weightorder = 0,
               cubeorder = 0,
               amtorder = 0,
               qtycommit = 0,
               weightcommit = 0,
               cubecommit = 0,
               amtcommit = 0,
               qtyship = 0,
               weightship = 0,
               cubeship = 0,
               amtship = 0,
               qtytotcommit = 0,
               weighttotcommit = 0,
               cubetotcommit = 0,
               amttotcommit = 0,
               qtyrcvd = 0,
               weightrcvd = 0,
               cubercvd = 0,
               amtrcvd = 0,
               qtypick = 0,
               weightpick = 0,
               cubepick = 0,
               amtpick = 0,
               qty2sort = 0,
               weight2sort = 0,
               cube2sort = 0,
               amt2sort = 0,
               qty2pack = 0,
               weight2pack = 0,
               cube2pack = 0,
               amt2pack = 0,
               qty2check = 0,
               weight2check = 0,
               cube2check = 0,
               amt2check = 0,
               staffhrs = 0
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    else
      dtlcount := dtlcount + 1;
    end if;
  else
    okyflag := 'Y';
    if (ols.qtyorder != od.qtyorder) then
      zut.prt('qtyorder mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.qtyorder || ' ' || od.qtyorder || ' ' || ols.lastupdate);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set qtyorder = od.qtyorder
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.weightorder != od.weightorder) then
      zut.prt('weightorder mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.weightorder || ' ' || od.weightorder);
      okyflag := 'N';
      qtycount := qtycount + 1;
      if updflag = 'Y' then
        update orderhdr
           set weightorder = od.weightorder
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.cubeorder != od.cubeorder) then
      zut.prt('cubeorder mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.cubeorder || ' ' || od.cubeorder);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set cubeorder = od.cubeorder
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.amtorder != od.amtorder) then
      zut.prt('amtorder mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.amtorder || ' ' || od.amtorder);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set amtorder = od.amtorder
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.qtycommit != od.qtycommit) then
      zut.prt('qtycommit mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.qtycommit || ' ' || od.qtycommit || ' ' || ols.lastupdate);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set qtycommit = od.qtycommit
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.weightcommit != od.weightcommit) then
      zut.prt('weightcommit mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.weightcommit || ' ' || od.weightcommit);
      okyflag := 'N';
      qtycount := qtycount + 1;
      if updflag = 'Y' then
        update orderhdr
           set weightcommit = od.weightcommit
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.cubecommit != od.cubecommit) then
      zut.prt('cubecommit mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.cubecommit || ' ' || od.cubecommit);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set cubecommit = od.cubecommit
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.amtcommit != od.amtcommit) then
      zut.prt('amtcommit mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.amtcommit || ' ' || od.amtcommit);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set amtcommit = od.amtcommit
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;

    if (ols.qtyship != od.qtyship) then
      zut.prt('qtyship mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.qtyship || ' ' || od.qtyship || ' ' || ols.lastupdate);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set qtyship = od.qtyship
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.weightship != od.weightship) then
      zut.prt('weightship mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.weightship || ' ' || od.weightship);
      okyflag := 'N';
      qtycount := qtycount + 1;
      if updflag = 'Y' then
        update orderhdr
           set weightship = od.weightship
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.cubeship != od.cubeship) then
      zut.prt('cubeship mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.cubeship || ' ' || od.cubeship);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set cubeship = od.cubeship
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.amtship != od.amtship) then
      zut.prt('amtship mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.amtship || ' ' || od.amtship);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set amtship = od.amtship
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;

    if (ols.qtytotcommit != od.qtytotcommit) then
      zut.prt('qtytotcommit mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.qtytotcommit || ' ' || od.qtytotcommit || ' ' || ols.lastupdate);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set qtytotcommit = od.qtytotcommit
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.weighttotcommit != od.weighttotcommit) then
      zut.prt('weighttotcommit mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.weighttotcommit || ' ' || od.weighttotcommit);
      okyflag := 'N';
      qtycount := qtycount + 1;
      if updflag = 'Y' then
        update orderhdr
           set weighttotcommit = od.weighttotcommit
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.cubetotcommit != od.cubetotcommit) then
      zut.prt('cubetotcommit mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.cubetotcommit || ' ' || od.cubetotcommit);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set cubetotcommit = od.cubetotcommit
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.amttotcommit != od.amttotcommit) then
      zut.prt('amttotcommit mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.amttotcommit || ' ' || od.amttotcommit);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set amttotcommit = od.amttotcommit
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;

    if (ols.qtyrcvd != od.qtyrcvd) then
      zut.prt('qtyrcvd mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.qtyrcvd || ' ' || od.qtyrcvd || ' ' || ols.qtyrcvd || ' ' ||
			  ols.lastupdate);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set qtyrcvd = od.qtyrcvd
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.weightrcvd != od.weightrcvd) then
      zut.prt('weightrcvd mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.weightrcvd || ' ' || od.weightrcvd);
      okyflag := 'N';
      qtycount := qtycount + 1;
      if updflag = 'Y' then
        update orderhdr
           set weightrcvd = od.weightrcvd
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.cubercvd != od.cubercvd) then
      zut.prt('cubercvd mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.cubercvd || ' ' || od.cubercvd);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set cubercvd = od.cubercvd
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.amtrcvd != od.amtrcvd) then
      zut.prt('amtrcvd mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.amtrcvd || ' ' || od.amtrcvd);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set amtrcvd = od.amtrcvd
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;

    if (ols.qtypick != od.qtypick) then
      zut.prt('qtypick mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.qtypick || ' ' || od.qtypick || ' ' || ols.lastupdate);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set qtypick = od.qtypick
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.weightpick != od.weightpick) then
      zut.prt('weightpick mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.weightpick || ' ' || od.weightpick);
      okyflag := 'N';
      qtycount := qtycount + 1;
      if updflag = 'Y' then
        update orderhdr
           set weightpick = od.weightpick
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.cubepick != od.cubepick) then
      zut.prt('cubepick mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.cubepick || ' ' || od.cubepick);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set cubepick = od.cubepick
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.amtpick != od.amtpick) then
      zut.prt('amtpick mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.amtpick || ' ' || od.amtpick);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set amtpick = od.amtpick
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;

    if (ols.qty2sort != od.qty2sort) then
      zut.prt('qty2sort mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.qty2sort || ' ' || od.qty2sort || ' ' || ols.lastupdate);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set qty2sort = od.qty2sort
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.weight2sort != od.weight2sort) then
      zut.prt('weight2sort mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.weight2sort || ' ' || od.weight2sort);
      okyflag := 'N';
      qtycount := qtycount + 1;
      if updflag = 'Y' then
        update orderhdr
           set weight2sort = od.weight2sort
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.cube2sort != od.cube2sort) then
      zut.prt('cube2sort mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.cube2sort || ' ' || od.cube2sort);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set cube2sort = od.cube2sort
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.amt2sort != od.amt2sort) then
      zut.prt('amt2sort mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.amt2sort || ' ' || od.amt2sort);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set amt2sort = od.amt2sort
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;

    if (ols.qty2pack != od.qty2pack) then
      zut.prt('qty2pack mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.qty2pack || ' ' || od.qty2pack || ' ' || ols.lastupdate);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set qty2pack = od.qty2pack
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.weight2pack != od.weight2pack) then
      zut.prt('weight2pack mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.weight2pack || ' ' || od.weight2pack);
      okyflag := 'N';
      qtycount := qtycount + 1;
      if updflag = 'Y' then
        update orderhdr
           set weight2pack = od.weight2pack
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.cube2pack != od.cube2pack) then
      zut.prt('cube2pack mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.cube2pack || ' ' || od.cube2pack);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set cube2pack = od.cube2pack
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.amt2pack != od.amt2pack) then
      zut.prt('amt2pack mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.amt2pack || ' ' || od.amt2pack);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set amt2pack = od.amt2pack
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;

    if (ols.qty2check != od.qty2check) then
      zut.prt('qty2check mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.qty2check || ' ' || od.qty2check || ' ' || ols.lastupdate);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set qty2check = od.qty2check
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.weight2check != od.weight2check) then
      zut.prt('weight2check mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.weight2check || ' ' || od.weight2check);
      okyflag := 'N';
      qtycount := qtycount + 1;
      if updflag = 'Y' then
        update orderhdr
           set weight2check = od.weight2check
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.cube2check != od.cube2check) then
      zut.prt('cube2check mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.cube2check || ' ' || od.cube2check);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set cube2check = od.cube2check
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if (ols.amt2check != od.amt2check) then
      zut.prt('amt2check mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.amt2check || ' ' || od.amt2check);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set amt2check = od.amt2check
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;

    if (ols.staffhrs != od.staffhrs) then
      zut.prt('staffhrs mismatch: ');
      zut.prt(ols.orderid || ' ' ||
        ols.shipid || ' ' ||
        ols.staffhrs || ' ' || od.staffhrs || ' ' || ols.lastupdate);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set staffhrs = od.staffhrs
         where orderid = ols.orderid
           and shipid = ols.shipid;
        commit;
      end if;
    end if;
    if okyflag = 'Y' then
      okycount := okycount + 1;
    end if;
  end if;
  close curOrderDtl;
<< continue_loop>>
  null;
end loop;
close curorderhdrSum;

zut.prt('totcount: ' || totcount);
zut.prt('skpcount: ' || skpcount);
zut.prt('okycount: ' || okycount);
zut.prt('ntfcount: ' || ntfcount);
zut.prt('qtycount: ' || qtycount);
zut.prt('dtlcount: ' || dtlcount);

if dtlflag != 'Y' then
  zut.prt('exiting');
  return;
end if;

totcount := 0;
okycount := 0;
ntfcount := 0;
qtycount := 0;
dtlcount := 0;

zut.prt('Comparing order detail to order header...');
open curOrderDtlSum;
while(1=1)
loop
  fetch curOrderDtlSum into ods;
  if curOrderDtlSum%notfound then
    exit;
  end if;
  totcount := totcount + 1;
  open curorderhdr;
  fetch curorderhdr into ol;
  if curorderhdr%notfound then
    zut.prt('orderhdr not found: ');
    zut.prt(ods.orderid || ' ' ||
      ods.shipid);
    ntfcount := ntfcount + 1;
    if updflag = 'Y' then
      delete from orderdtl
       where orderid = ods.orderid
         and shipid = ods.shipid;
    end if;
  else
    okyflag := 'Y';
    if (ods.qtyorder != ol.qtyorder) then
      zut.prt('qtyorder mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.qtyorder || ' ' || ol.qtyorder);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set qtyorder = ods.qtyorder
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.weightorder != ol.weightorder) then
      zut.prt('weightorder mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.weightorder || ' ' || ol.weightorder);
      okyflag := 'N';
      qtycount := qtycount + 1;
      if updflag = 'Y' then
        update orderhdr
           set weightorder = ods.weightorder
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.cubeorder != ol.cubeorder) then
      zut.prt('cubeorder mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.cubeorder || ' ' || ol.cubeorder);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set cubeorder = ods.cubeorder
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.amtorder != ol.amtorder) then
      zut.prt('amtorder mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.amtorder || ' ' || ol.amtorder);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set amtorder = ods.amtorder
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.qtycommit != ol.qtycommit) then
      zut.prt('qtycommit mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.qtycommit || ' ' || ol.qtycommit);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set qtycommit = ods.qtycommit
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.weightcommit != ol.weightcommit) then
      zut.prt('weightcommit mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.weightcommit || ' ' || ol.weightcommit);
      okyflag := 'N';
      qtycount := qtycount + 1;
      if updflag = 'Y' then
        update orderhdr
           set weightcommit = ods.weightcommit
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.cubecommit != ol.cubecommit) then
      zut.prt('cubecommit mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.cubecommit || ' ' || ol.cubecommit);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set cubecommit = ods.cubecommit
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.amtcommit != ol.amtcommit) then
      zut.prt('amtcommit mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.amtcommit || ' ' || ol.amtcommit);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set amtcommit = ods.amtcommit
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;

    if (ods.qtyship != ol.qtyship) then
      zut.prt('qtyship mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.qtyship || ' ' || ol.qtyship);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set qtyship = ods.qtyship
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.weightship != ol.weightship) then
      zut.prt('weightship mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.weightship || ' ' || ol.weightship);
      okyflag := 'N';
      qtycount := qtycount + 1;
      if updflag = 'Y' then
        update orderhdr
           set weightship = ods.weightship
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.cubeship != ol.cubeship) then
      zut.prt('cubeship mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.cubeship || ' ' || ol.cubeship);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set cubeship = ods.cubeship
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.amtship != ol.amtship) then
      zut.prt('amtship mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.amtship || ' ' || ol.amtship);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set amtship = ods.amtship
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;

    if (ods.qtytotcommit != ol.qtytotcommit) then
      zut.prt('qtytotcommit mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.qtytotcommit || ' ' || ol.qtytotcommit);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set qtytotcommit = ods.qtytotcommit
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.weighttotcommit != ol.weighttotcommit) then
      zut.prt('weighttotcommit mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.weighttotcommit || ' ' || ol.weighttotcommit);
      okyflag := 'N';
      qtycount := qtycount + 1;
      if updflag = 'Y' then
        update orderhdr
           set weighttotcommit = ods.weighttotcommit
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.cubetotcommit != ol.cubetotcommit) then
      zut.prt('cubetotcommit mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.cubetotcommit || ' ' || ol.cubetotcommit);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set cubetotcommit = ods.cubetotcommit
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.amttotcommit != ol.amttotcommit) then
      zut.prt('amttotcommit mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.amttotcommit || ' ' || ol.amttotcommit);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set amttotcommit = ods.amttotcommit
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;

    if (ods.qtyrcvd != ol.qtyrcvd) then
      zut.prt('qtyrcvd mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.qtyrcvd || ' ' || ol.qtyrcvd);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set qtyrcvd = ods.qtyrcvd
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.weightrcvd != ol.weightrcvd) then
      zut.prt('weightrcvd mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.weightrcvd || ' ' || ol.weightrcvd);
      okyflag := 'N';
      qtycount := qtycount + 1;
      if updflag = 'Y' then
        update orderhdr
           set weightrcvd = ods.weightrcvd
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.cubercvd != ol.cubercvd) then
      zut.prt('cubercvd mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.cubercvd || ' ' || ol.cubercvd);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set cubercvd = ods.cubercvd
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.amtrcvd != ol.amtrcvd) then
      zut.prt('amtrcvd mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.amtrcvd || ' ' || ol.amtrcvd);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set amtrcvd = ods.amtrcvd
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;

    if (ods.qtypick != ol.qtypick) then
      zut.prt('qtypick mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.qtypick || ' ' || ol.qtypick);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set qtypick = ods.qtypick
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.weightpick != ol.weightpick) then
      zut.prt('weightpick mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.weightpick || ' ' || ol.weightpick);
      okyflag := 'N';
      qtycount := qtycount + 1;
      if updflag = 'Y' then
        update orderhdr
           set weightpick = ods.weightpick
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.cubepick != ol.cubepick) then
      zut.prt('cubepick mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.cubepick || ' ' || ol.cubepick);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set cubepick = ods.cubepick
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.amtpick != ol.amtpick) then
      zut.prt('amtpick mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.amtpick || ' ' || ol.amtpick);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set amtpick = ods.amtpick
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;

    if (ods.qty2sort != ol.qty2sort) then
      zut.prt('qty2sort mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.qty2sort || ' ' || ol.qty2sort);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set qty2sort = ods.qty2sort
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.weight2sort != ol.weight2sort) then
      zut.prt('weight2sort mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.weight2sort || ' ' || ol.weight2sort);
      okyflag := 'N';
      qtycount := qtycount + 1;
      if updflag = 'Y' then
        update orderhdr
           set weight2sort = ods.weight2sort
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.cube2sort != ol.cube2sort) then
      zut.prt('cube2sort mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.cube2sort || ' ' || ol.cube2sort);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set cube2sort = ods.cube2sort
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.amt2sort != ol.amt2sort) then
      zut.prt('amt2sort mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.amt2sort || ' ' || ol.amt2sort);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set amt2sort = ods.amt2sort
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;

    if (ods.qty2pack != ol.qty2pack) then
      zut.prt('qty2pack mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.qty2pack || ' ' || ol.qty2pack);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set qty2pack = ods.qty2pack
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.weight2pack != ol.weight2pack) then
      zut.prt('weight2pack mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.weight2pack || ' ' || ol.weight2pack);
      okyflag := 'N';
      qtycount := qtycount + 1;
      if updflag = 'Y' then
        update orderhdr
           set weight2pack = ods.weight2pack
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.cube2pack != ol.cube2pack) then
      zut.prt('cube2pack mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.cube2pack || ' ' || ol.cube2pack);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set cube2pack = ods.cube2pack
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.amt2pack != ol.amt2pack) then
      zut.prt('amt2pack mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.amt2pack || ' ' || ol.amt2pack);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set amt2pack = ods.amt2pack
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;

    if (ods.qty2check != ol.qty2check) then
      zut.prt('qty2check mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.qty2check || ' ' || ol.qty2check);
      okyflag := 'N';
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set qty2check = ods.qty2check
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.weight2check != ol.weight2check) then
      zut.prt('weight2check mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.weight2check || ' ' || ol.weight2check);
      okyflag := 'N';
      qtycount := qtycount + 1;
      if updflag = 'Y' then
        update orderhdr
           set weight2check = ods.weight2check
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.cube2check != ol.cube2check) then
      zut.prt('cube2check mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.cube2check || ' ' || ol.cube2check);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set cube2check = ods.cube2check
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if (ods.amt2check != ol.amt2check) then
      zut.prt('amt2check mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.amt2check || ' ' || ol.amt2check);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set amt2check = ods.amt2check
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;

    if (ods.staffhrs != ol.staffhrs) then
      zut.prt('staffhrs mismatch: ');
      zut.prt(ods.orderid || ' ' ||
        ods.shipid || ' ' ||
        ods.staffhrs || ' ' || ol.staffhrs);
      qtycount := qtycount + 1;
      okyflag := 'N';
      if updflag = 'Y' then
        update orderhdr
           set staffhrs = ods.staffhrs
         where orderid = ods.orderid
           and shipid = ods.shipid;
        commit;
      end if;
    end if;
    if okyflag = 'Y' then
      okycount := okycount + 1;
    end if;
  end if;
  close curorderhdr;
end loop;
close curOrderDtlSum;

zut.prt('totcount: ' || totcount);
zut.prt('okycount: ' || okycount);
zut.prt('ntfcount: ' || ntfcount);
zut.prt('qtycount: ' || qtycount);
zut.prt('dtlcount: ' || dtlcount);

zut.prt('end of orderhdr audit');

exception when others then
  zut.prt(sqlerrm);
end;
/
exit;
