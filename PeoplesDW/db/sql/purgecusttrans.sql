--
-- $Id$
--
set serveroutput on
set feedback off
set verify off
prompt
prompt This script will DELETE all transactional data for a specific
prompt customer and display a count of the rows deleted
prompt
accept p_custid prompt 'Enter custid: '
prompt
accept p_areyousure prompt 'Are you sure (Y/N): '
prompt

create table zet_trans_purge
   (orderid number,
    shipid  number,
    loadno  number,
    stopno  number,
    shipno  number,
    wave    number);
delete from zet_trans_purge;
commit;

declare
   cursor c_wave(p_wave number) is
      select sum(nvl(OH.qtyorder,0)) as qtyorder,
             sum(nvl(OH.weightorder,0)) as weightorder,
             sum(nvl(OH.cubeorder,0)) as cubeorder,
             sum(nvl(OH.qtycommit,0)) as qtycommit,
             sum(nvl(OH.weightcommit,0)) as weightcommit,
             sum(nvl(OH.cubecommit,0)) as cubecommit
         from zet_trans_purge ZTP, orderhdr OH
         where ZTP.wave = p_wave
           and OH.orderid = ZTP.orderid
           and OH.shipid = ZTP.shipid;
   wave c_wave%rowtype;
   cursor c_load(p_loadno number, p_stopno number, p_shipno number) is
      select sum(nvl(OH.qtyorder,0)) as qtyorder,
             sum(nvl(OH.weightorder,0)) as weightorder,
             sum(nvl(OH.cubeorder,0)) as cubeorder,
             sum(nvl(OH.amtorder,0)) as amtorder,
             sum(nvl(OH.qtyship,0)) as qtyship,
             sum(nvl(OH.weightship,0)) as weightship,
             sum(nvl(OH.cubeship,0)) as cubeship,
             sum(nvl(OH.amtship,0)) as amtship,
             sum(nvl(OH.qtyrcvd,0)) as qtyrcvd,
             sum(nvl(OH.weightrcvd,0)) as weightrcvd,
             sum(nvl(OH.cubercvd,0)) as cubercvd,
             sum(nvl(OH.amtrcvd,0)) as amtrcvd
         from zet_trans_purge ZTP, orderhdr OH
         where ZTP.loadno = p_loadno
           and ZTP.stopno = p_stopno
           and ZTP.shipno = p_shipno
           and OH.orderid = ZTP.orderid
           and OH.shipid = ZTP.shipid;
   load c_load%rowtype;
   l_cnt pls_integer;
   l_ztpcnt pls_integer;
   l_allcnt pls_integer;
	l_custid customer.custid%type := upper('&&p_custid');
   l_loadstopship pls_integer := 0;
   l_loadstopshipbolcomments pls_integer := 0;
   l_loadstop pls_integer := 0;
   l_loadstopbolcomments pls_integer := 0;
   l_loads pls_integer := 0;
   l_loadsbolcomments pls_integer := 0;
   l_waves pls_integer := 0;
begin

   dbms_output.enable(1000000);

	if upper('&&p_areyousure') != 'Y' then
   	dbms_output.put_line('Delete cancelled...');
      return;
	end if;

   insert into zet_trans_purge
     	select orderid, shipid, loadno, stopno, shipno, wave
        	from orderhdr
	     	where custid = l_custid;
   commit;

-- load related

   for ld in (select distinct loadno, stopno, shipno
                  from zet_trans_purge
                  where nvl(loadno,0) != 0
                    and nvl(stopno,0) != 0
                    and nvl(shipno,0) != 0) loop

      select count(1) into l_allcnt
         from orderhdr
         where loadno = ld.loadno
           and stopno = ld.stopno
           and shipno = ld.shipno;

      select count(1) into l_ztpcnt
         from zet_trans_purge
         where loadno = ld.loadno
           and stopno = ld.stopno
           and shipno = ld.shipno;

      if l_allcnt = l_ztpcnt then
         delete from loadstopship
            where loadno = ld.loadno
              and stopno = ld.stopno
              and shipno = ld.shipno;
         l_loadstopship := l_loadstopship + sql%rowcount;

         delete from loadstopshipbolcomments
            where loadno = ld.loadno
              and stopno = ld.stopno
              and shipno = ld.shipno;
         l_loadstopshipbolcomments := l_loadstopshipbolcomments + sql%rowcount;

         select count(1) into l_cnt
            from loadstopship
            where loadno = ld.loadno
              and stopno = ld.stopno;

         if l_cnt = 0 then
            delete from loadstop
               where loadno = ld.loadno
                 and stopno = ld.stopno;
            l_loadstop := l_loadstop + sql%rowcount;

            delete from loadstopbolcomments
               where loadno = ld.loadno
                 and stopno = ld.stopno;
            l_loadstopbolcomments := l_loadstopbolcomments + sql%rowcount;

            select count(1) into l_cnt
               from loadstop
               where loadno = ld.loadno;

            if l_cnt = 0 then
               delete from loads where loadno = ld.loadno;
               l_loads := l_loads + sql%rowcount;

               delete from loadsbolcomments where loadno = ld.loadno;
               l_loadsbolcomments := l_loadsbolcomments + sql%rowcount;

            end if;
         end if;
      else
         load := null;
         open c_load(ld.loadno, ld.stopno, ld.shipno);
         fetch c_load into load;
         close c_load;

         update loadstopship
            set qtyorder = qtyorder - nvl(load.qtyorder,0),
                weightorder = weightorder - nvl(load.weightorder,0),
                cubeorder = cubeorder - nvl(load.cubeorder,0),
                amtorder = amtorder - nvl(load.amtorder,0),
                qtyship = qtyship - nvl(load.qtyship,0),
                weightship = weightship - nvl(load.weightship,0),
                cubeship = cubeship - nvl(load.cubeship,0),
                amtship = amtship - nvl(load.amtship,0),
                qtyrcvd = qtyrcvd - nvl(load.qtyrcvd,0),
                weightrcvd = weightrcvd - nvl(load.weightrcvd,0),
                cubercvd = cubercvd - nvl(load.cubercvd,0),
                amtrcvd = amtrcvd - nvl(load.amtrcvd,0)
            where loadno = ld.loadno
              and stopno = ld.stopno
              and shipno = ld.shipno;
      end if;
   end loop;
   commit;
   dbms_output.put_line('loadstopship = '||l_loadstopship);
   dbms_output.put_line('loadstopshipbolcomments = '||l_loadstopshipbolcomments);
   dbms_output.put_line('loadstop = '||l_loadstop);
   dbms_output.put_line('loadstopbolcomments = '||l_loadstopbolcomments);
   dbms_output.put_line('loads = '||l_loads);
   dbms_output.put_line('loadsbolcomments = '||l_loadsbolcomments);

-- wave related

   for wv in (select distinct wave
                  from zet_trans_purge
                  where nvl(wave,0) != 0) loop

      select count(1) into l_allcnt
         from waves
         where wave = wv.wave;

      select count(1) into l_ztpcnt
         from zet_trans_purge
         where wave = wv.wave;

      if l_allcnt = l_ztpcnt then
         delete from waves
            where wave = wv.wave;
         l_waves := l_waves + sql%rowcount;

      else
         wave := null;
         open c_wave(wv.wave);
         fetch c_wave into wave;
         close c_wave;

         update waves
            set cntorder = cntorder - 1,
                qtyorder = qtyorder - nvl(wave.qtyorder,0),
                weightorder = weightorder - nvl(wave.weightorder,0),
                cubeorder = cubeorder - nvl(wave.cubeorder,0),
                qtycommit = qtycommit - nvl(wave.qtycommit,0),
                weightcommit = weightcommit - nvl(wave.weightcommit,0),
                cubecommit = cubecommit - nvl(wave.cubecommit,0)
            where wave = wv.wave;
      end if;
   end loop;
   commit;
   dbms_output.put_line('waves = '||l_waves);

-- orderid related

	delete from asncartondtl where (orderid, shipid) in
   	(select orderid, shipid from zet_trans_purge);
   dbms_output.put_line('asncartondtl = '||sql%rowcount);
   commit;

	delete from invoiceorders where (orderid, shipid) in
   	(select orderid, shipid from zet_trans_purge);
   dbms_output.put_line('invoiceorders = '||sql%rowcount);
   commit;

	delete from mass_manifest_ctn where (orderid, shipid) in
   	(select orderid, shipid from zet_trans_purge);
   dbms_output.put_line('mass_manifest_ctn = '||sql%rowcount);
   commit;

	delete from multishipdtl where (orderid, shipid) in
   	(select orderid, shipid from zet_trans_purge);
   dbms_output.put_line('multishipdtl = '||sql%rowcount);
   commit;

	delete from multishiphdr where (orderid, shipid) in
   	(select orderid, shipid from zet_trans_purge);
	dbms_output.put_line('multishiphdr = '||sql%rowcount);
   commit;

	delete from neworderdtl where (orderid, shipid) in
   	(select orderid, shipid from zet_trans_purge);
   dbms_output.put_line('neworderdtl = '||sql%rowcount);
   commit;

	delete from neworderhdr where (orderid, shipid) in
   	(select orderid, shipid from zet_trans_purge);
	dbms_output.put_line('neworderhdr = '||sql%rowcount);
   commit;

	delete from oldorderdtl where (orderid, shipid) in
   	(select orderid, shipid from zet_trans_purge);
   dbms_output.put_line('oldorderdtl = '||sql%rowcount);
   commit;

	delete from oldorderhdr where (orderid, shipid) in
   	(select orderid, shipid from zet_trans_purge);
	dbms_output.put_line('oldorderhdr = '||sql%rowcount);
   commit;

	delete from ordercheck where (orderid, shipid) in
   	(select orderid, shipid from zet_trans_purge);
   dbms_output.put_line('ordercheck = '||sql%rowcount);
   commit;

	delete from orderdtl where (orderid, shipid) in
   	(select orderid, shipid from zet_trans_purge);
	dbms_output.put_line('orderdtl = '||sql%rowcount);
   commit;

	delete from orderdtlbolcomments where (orderid, shipid) in
   	(select orderid, shipid from zet_trans_purge);
   dbms_output.put_line('orderdtlbolcomments = '||sql%rowcount);
   commit;

	delete from orderdtlline where (orderid, shipid) in
   	(select orderid, shipid from zet_trans_purge);
   dbms_output.put_line('orderdtlline = '||sql%rowcount);
   commit;

	delete from orderdtlrcpt where (orderid, shipid) in
   	(select orderid, shipid from zet_trans_purge);
	dbms_output.put_line('orderdtlrcpt = '||sql%rowcount);
   commit;

	delete from orderhdr where (orderid, shipid) in
   	(select orderid, shipid from zet_trans_purge);
	dbms_output.put_line('orderhdr = '||sql%rowcount);
   commit;

	delete from orderhdrbolcomments where (orderid, shipid) in
   	(select orderid, shipid from zet_trans_purge);
   dbms_output.put_line('orderhdrbolcomments = '||sql%rowcount);
   commit;

	delete from orderhistory where (orderid, shipid) in
   	(select orderid, shipid from zet_trans_purge);
	dbms_output.put_line('orderhistory = '||sql%rowcount);
   commit;

	delete from orderlabor where (orderid, shipid) in
   	(select orderid, shipid from zet_trans_purge);
	dbms_output.put_line('orderlabor = '||sql%rowcount);
   commit;

	delete from p1pkcaselabels where (orderid, shipid) in
   	(select orderid, shipid from zet_trans_purge);
	dbms_output.put_line('p1pkcaselabels = '||sql%rowcount);
   commit;

	delete from qcresult where (orderid, shipid) in
   	(select orderid, shipid from zet_trans_purge);
   dbms_output.put_line('qcresult = '||sql%rowcount);
   commit;

	delete from qcresultdtl where (orderid, shipid) in
   	(select orderid, shipid from zet_trans_purge);
   dbms_output.put_line('qcresultdtl = '||sql%rowcount);
   commit;

	delete from worldshipdtl where (orderid, shipid) in
   	(select orderid, shipid from zet_trans_purge);
   dbms_output.put_line('worldshipdtl = '||sql%rowcount);
   commit;

-- customer related

   update customer
      set rnewlastbilled = null,
          misclastbilled = null,
          rcptlastbilled = null,
          outblastbilled = null,
          mastlastbilled = null
      where custid = l_custid;

	delete from appmsgs where custid = l_custid;
   dbms_output.put_line('appmsgs = '||sql%rowcount);
   commit;

	delete from asofinventory where custid = l_custid;
   dbms_output.put_line('asofinventory = '||sql%rowcount);
   commit;

	delete from asofinventorydtl where custid = l_custid;
   dbms_output.put_line('asofinventorydtl = '||sql%rowcount);
   commit;

	delete from batchtasks where custid = l_custid;
	dbms_output.put_line('batchtasks = '||sql%rowcount);
   commit;

	delete from billpalletcnt where custid = l_custid;
	dbms_output.put_line('billpalletcnt = '||sql%rowcount);
   commit;

	delete from bill_lot_renewal where custid = l_custid;
	dbms_output.put_line('bill_lot_renewal = '||sql%rowcount);
   commit;

	delete from caselabels where custid = l_custid;
	dbms_output.put_line('caselabels = '||sql%rowcount);
   commit;

	delete from commitments where custid = l_custid;
	dbms_output.put_line('commitments = '||sql%rowcount);
   commit;

	delete from custbilldates where custid = l_custid;
	dbms_output.put_line('custbilldates = '||sql%rowcount);
   commit;

	delete from custitemcatchweight where custid = l_custid;
	dbms_output.put_line('custitemcatchweight = '||sql%rowcount);
   commit;

	delete from custitemcount where custid = l_custid;
	dbms_output.put_line('custitemcount = '||sql%rowcount);
   commit;

	delete from custitemtot where custid = l_custid;
	dbms_output.put_line('custitemtot = '||sql%rowcount);
   commit;

	delete from custlastrenewal where custid = l_custid;
	dbms_output.put_line('custlastrenewal = '||sql%rowcount);
   commit;

	delete from custrenewal where custid = l_custid;
	dbms_output.put_line('custrenewal = '||sql%rowcount);
   commit;

	delete from custworkorderinstructions where seq in
   	(select seq from custworkorder where custid = l_custid);
	dbms_output.put_line('custworkorderinstructions = '||sql%rowcount);
   commit;
	delete from custworkorder where custid = l_custid;
	dbms_output.put_line('custworkorder = '||sql%rowcount);
   commit;

	delete from cyclecountactivity where custid = l_custid;
	dbms_output.put_line('cyclecountactivity = '||sql%rowcount);
   commit;

	delete from deletedplate where custid = l_custid;
	dbms_output.put_line('deletedplate = '||sql%rowcount);
   commit;

	delete from i52_item_bal where custid = l_custid;
	dbms_output.put_line('i52_item_bal = '||sql%rowcount);
   commit;

	delete from invadjactivity where custid = l_custid;
	dbms_output.put_line('invadjactivity = '||sql%rowcount);
   commit;

	delete from invoicedtl where custid = l_custid;
	dbms_output.put_line('invoicedtl = '||sql%rowcount);
   commit;

	delete from invoicehdr where custid = l_custid;
	dbms_output.put_line('invoicehdr = '||sql%rowcount);
   commit;

	delete from invsession where custid = l_custid;
	dbms_output.put_line('invsession = '||sql%rowcount);
   commit;

	delete from itemdemand where custid = l_custid;
	dbms_output.put_line('itemdemand = '||sql%rowcount);
   commit;

	delete from pallethistory where custid = l_custid;
	dbms_output.put_line('pallethistory = '||sql%rowcount);
   commit;

	delete from palletinventory where custid = l_custid;
	dbms_output.put_line('palletinventory = '||sql%rowcount);
   commit;

	delete from platehistory where lpid in
		(select lpid from plate where custid = l_custid);
	dbms_output.put_line('platehistory = '||sql%rowcount);
   commit;
	delete from plate where custid = l_custid;
	dbms_output.put_line('plate = '||sql%rowcount);
   commit;

	delete from postdtl where invoice in
   	(select invoice from posthdr where custid = l_custid);
   dbms_output.put_line('postdtl = '||sql%rowcount);
   commit;
	delete from posthdr where custid = l_custid;
	dbms_output.put_line('posthdr = '||sql%rowcount);
   commit;

	delete from qcrequest where custid = l_custid;
	dbms_output.put_line('qcrequest = '||sql%rowcount);
   commit;

	delete from shippingaudit where custid = l_custid;
	dbms_output.put_line('shippingaudit = '||sql%rowcount);
   commit;

	delete from shippingplatehistory where lpid in
		(select lpid from shippingplate where custid = l_custid);
	dbms_output.put_line('shippingplatehistory = '||sql%rowcount);
   commit;
	delete from shippingplate where custid = l_custid;
	dbms_output.put_line('shippingplate = '||sql%rowcount);
   commit;

	delete from subtasks where custid = l_custid;
	dbms_output.put_line('subtasks = '||sql%rowcount);
   commit;

	delete from tasks where custid = l_custid;
	dbms_output.put_line('tasks = '||sql%rowcount);
   commit;

	delete from userhistory where custid = l_custid;
	dbms_output.put_line('userhistory = '||sql%rowcount);
   commit;

end;
/

drop table zet_trans_purge;

exit;
