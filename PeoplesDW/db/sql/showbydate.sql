--
-- $Id$
--
set serveroutput on
set feedback off
set verify off
prompt
prompt This script will show the table followed by the number
prompt of rows that are older than a specific date
prompt
accept p_cutoff prompt 'Enter cutoff date (YYYYMMDD): '
prompt

create table zethcon_purge_orders(orderid number, shipid number);
create table zethcon_purge_loads(loadno number);

declare
	l_cutoff date := to_date('&&p_cutoff', 'YYYYMMDD');
	cnt pls_integer;
begin

   dbms_output.enable(1000000);

-- orderid related

   insert into zethcon_purge_orders
     	select orderid, shipid
        	from orderhdr
	     	where lastupdate < l_cutoff;
	dbms_output.put_line('orderhdr = '||sql%rowcount);
   commit;

--	select count(1) into cnt from orderhdr where (orderid, shipid) in
--   	(select orderid, shipid from zethcon_purge_orders);
--	dbms_output.put_line('orderhdr = '||cnt);

	select count(1) into cnt from orderhdrbolcomments where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('orderhdrbolcomments = '||cnt);

	select count(1) into cnt from neworderhdr where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('neworderhdr = '||cnt);

	select count(1) into cnt from oldorderhdr where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('oldorderhdr = '||cnt);

	select count(1) into cnt from orderdtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('orderdtl = '||cnt);

	select count(1) into cnt from orderdtlbolcomments where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('orderdtlbolcomments = '||cnt);

	select count(1) into cnt from orderdtlline where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('orderdtlline = '||cnt);

	select count(1) into cnt from orderdtlrcpt where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('orderdtlrcpt = '||cnt);

	select count(1) into cnt from neworderdtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('neworderdtl = '||cnt);

	select count(1) into cnt from oldorderdtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('oldorderdtl = '||cnt);

	select count(1) into cnt from orderlabor where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('orderlabor = '||cnt);

	select count(1) into cnt from multishiphdr where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('multishiphdr = '||cnt);

	select count(1) into cnt from multishipdtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('multishipdtl = '||cnt);

	select count(1) into cnt from shippingaudit where lpid in
		(select lpid from shippingplate where (orderid, shipid) in
   		(select orderid, shipid from zethcon_purge_orders));
	dbms_output.put_line('shippingaudit = '||cnt);

	select count(1) into cnt from shippingplate where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('shippingplate = '||cnt);

	select count(1) into cnt from pallethistory where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('pallethistory = '||cnt);

	select count(1) into cnt from asncartondtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('asncartondtl = '||cnt);

-- loads related

   insert into zethcon_purge_loads
     	select loadno
        	from loads
	     	where lastupdate < l_cutoff;
   commit;
   delete from zethcon_purge_loads
   	where loadno in (select loadno from orderhdr where lastupdate >= l_cutoff);
	commit;

	select count(1) into cnt from loads where loadno in
   	(select loadno from zethcon_purge_loads);
	dbms_output.put_line('loads = '||cnt);

	select count(1) into cnt from loadstop where loadno in
   	(select loadno from zethcon_purge_loads);
	dbms_output.put_line('loadstop = '||cnt);

	select count(1) into cnt from loadstopship where loadno in
   	(select loadno from zethcon_purge_loads);
	dbms_output.put_line('loadstopship = '||cnt);

-- plate related

	select count(1) into cnt from platehistory where lpid in
		(select lpid from plate where lastupdate < l_cutoff
       union
		 select lpid from deletedplate where lastupdate < l_cutoff);
	dbms_output.put_line('platehistory = '||cnt);

	select count(1) into cnt from plate where lastupdate < l_cutoff;
	dbms_output.put_line('plate = '||cnt);

	select count(1) into cnt from deletedplate where lastupdate < l_cutoff;
	dbms_output.put_line('deletedplate = '||cnt);

-- invoice related

	select count(1) into cnt from postdtl where invoice in
   	(select invoice from invoicehdr where lastupdate < l_cutoff);
	dbms_output.put_line('postdtl = '||cnt);

	select count(1) into cnt from posthdr where invoice in
   	(select invoice from invoicehdr where lastupdate < l_cutoff);
	dbms_output.put_line('posthdr = '||cnt);

	select count(1) into cnt from invoicedtl where invoice in
   	(select invoice from invoicehdr where lastupdate < l_cutoff);
	dbms_output.put_line('invoicedtl = '||cnt);

	select count(1) into cnt from invoicehdr where lastupdate < l_cutoff;
	dbms_output.put_line('invoicehdr = '||cnt);

-- asofinventory related

	select count(1) into cnt from asofinventorydtl
   	where (facility, custid, item, nvl(lotnumber, '(none)'), uom, effdate,
      		inventoryclass, invstatus) in
   		(select facility, custid, item, nvl(lotnumber, '(none)'), uom, effdate,
         		  inventoryclass, invstatus
         	from asofinventory
         	where lastupdate < l_cutoff);
	dbms_output.put_line('asofinventorydtl = '||cnt);

	select count(1) into cnt from asofinventory where lastupdate < l_cutoff;
	dbms_output.put_line('asofinventory = '||cnt);

-- physicalinventory related

	select count(1) into cnt from physicalinventorydtl where id in
   	(select id from physicalinventoryhdr where lastupdate < l_cutoff);
	dbms_output.put_line('physicalinventorydtl = '||cnt);

	select count(1) into cnt from physicalinventoryhdr where lastupdate < l_cutoff;
	dbms_output.put_line('physicalinventoryhdr = '||cnt);

-- date related

	select count(1) into cnt from appmsgs where lastupdate < l_cutoff;
	dbms_output.put_line('appmsgs = '||cnt);

	select count(1) into cnt from billpalletcnt where lastupdate < l_cutoff;
	dbms_output.put_line('billpalletcnt = '||cnt);

	select count(1) into cnt from cyclecountactivity where lastupdate < l_cutoff;
	dbms_output.put_line('cyclecountactivity = '||cnt);

	select count(1) into cnt from invadjactivity where lastupdate < l_cutoff;
	dbms_output.put_line('invadjactivity = '||cnt);

	select count(1) into cnt from userhistory where begtime < l_cutoff;
	dbms_output.put_line('userhistory = '||cnt);

	select count(1) into cnt from waves where lastupdate < l_cutoff
   	and not exists (select * from orderhdr where orderhdr.wave = waves.wave
      						and lastupdate >= l_cutoff);
	dbms_output.put_line('waves = '||cnt);

end;
/

drop table zethcon_purge_orders;
drop table zethcon_purge_loads;

exit;
