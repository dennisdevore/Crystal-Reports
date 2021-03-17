--
-- $Id$
--
set serveroutput on
set feedback off
set verify off
prompt
prompt This script will DELETE all rows older than a specific date
prompt and display a count of the rows deleted
prompt
accept p_cutoff prompt 'Enter cutoff date (YYYYMMDD): '
prompt
accept p_areyousure prompt 'Are you sure (Y/N): '
prompt

create table zethcon_purge_orders(orderid number, shipid number);
create table zethcon_purge_loads(loadno number);

declare
	l_cutoff date := to_date('&&p_cutoff', 'YYYYMMDD');
begin

   dbms_output.enable(1000000);

	if upper('&&p_areyousure') != 'Y' then
   	dbms_output.put_line('Delete cancelled...');
      return;
	end if;

-- orderid related

   insert into zethcon_purge_orders
     	select orderid, shipid
        	from orderhdr
	     	where lastupdate < l_cutoff;
	dbms_output.put_line('orderhdr = '||sql%rowcount);
   commit;

	delete from orderhdr where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('orderhdr = '||sql%rowcount);
   commit;

	delete from orderhdrbolcomments where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('orderhdrbolcomments = '||sql%rowcount);
   commit;

	delete from neworderhdr where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('neworderhdr = '||sql%rowcount);
   commit;

	delete from oldorderhdr where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('oldorderhdr = '||sql%rowcount);
   commit;

	delete from orderdtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('orderdtl = '||sql%rowcount);
   commit;

	delete from orderdtlbolcomments where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('orderdtlbolcomments = '||sql%rowcount);
   commit;

	delete from orderdtlline where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('orderdtlline = '||sql%rowcount);
   commit;

	delete from orderdtlrcpt where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('orderdtlrcpt = '||sql%rowcount);
   commit;

	delete from neworderdtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('neworderdtl = '||sql%rowcount);
   commit;

	delete from oldorderdtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('oldorderdtl = '||sql%rowcount);
   commit;

	delete from orderlabor where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('orderlabor = '||sql%rowcount);
   commit;

	delete from multishiphdr where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('multishiphdr = '||sql%rowcount);
   commit;

	delete from multishipdtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('multishipdtl = '||sql%rowcount);
   commit;

	delete from shippingaudit where lpid in
		(select lpid from shippingplate where (orderid, shipid) in
   		(select orderid, shipid from zethcon_purge_orders));
	dbms_output.put_line('shippingaudit = '||sql%rowcount);
   commit;

	delete from shippingplate where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('shippingplate = '||sql%rowcount);
   commit;

	delete from pallethistory where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('pallethistory = '||sql%rowcount);
   commit;

	delete from asncartondtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('asncartondtl = '||sql%rowcount);
   commit;

-- loads related

   insert into zethcon_purge_loads
     	select loadno
        	from loads
	     	where lastupdate < l_cutoff;
   commit;
   delete from zethcon_purge_loads
   	where loadno in (select loadno from orderhdr where lastupdate >= l_cutoff);
	commit;

	delete from loads where loadno in
   	(select loadno from zethcon_purge_loads);
	dbms_output.put_line('loads = '||sql%rowcount);
   commit;

	delete from loadstop where loadno in
   	(select loadno from zethcon_purge_loads);
	dbms_output.put_line('loadstop = '||sql%rowcount);
   commit;

	delete from loadstopship where loadno in
   	(select loadno from zethcon_purge_loads);
	dbms_output.put_line('loadstopship = '||sql%rowcount);
   commit;

-- plate related

	delete from platehistory where lpid in
		(select lpid from plate where lastupdate < l_cutoff
       union
		 select lpid from deletedplate where lastupdate < l_cutoff);
	dbms_output.put_line('platehistory = '||sql%rowcount);
   commit;

	delete from plate where lastupdate < l_cutoff;
	dbms_output.put_line('plate = '||sql%rowcount);
   commit;

	delete from deletedplate where lastupdate < l_cutoff;
	dbms_output.put_line('deletedplate = '||sql%rowcount);
   commit;

-- invoice related

	delete from postdtl where invoice in
   	(select invoice from invoicehdr where lastupdate < l_cutoff);
	dbms_output.put_line('postdtl = '||sql%rowcount);
   commit;

	delete from posthdr where invoice in
   	(select invoice from invoicehdr where lastupdate < l_cutoff);
	dbms_output.put_line('posthdr = '||sql%rowcount);
   commit;

	delete from invoicedtl where invoice in
   	(select invoice from invoicehdr where lastupdate < l_cutoff);
	dbms_output.put_line('invoicedtl = '||sql%rowcount);
   commit;

	delete from invoicehdr where lastupdate < l_cutoff;
	dbms_output.put_line('invoicehdr = '||sql%rowcount);
   commit;

-- asofinventory related

	delete from asofinventorydtl
   	where (facility, custid, item, nvl(lotnumber, '(none)'), uom, effdate,
      		inventoryclass, invstatus) in
   		(select facility, custid, item, nvl(lotnumber, '(none)'), uom, effdate,
         		  inventoryclass, invstatus
         	from asofinventory
         	where lastupdate < l_cutoff);
	dbms_output.put_line('asofinventorydtl = '||sql%rowcount);
   commit;

	delete from asofinventory where lastupdate < l_cutoff;
	dbms_output.put_line('asofinventory = '||sql%rowcount);
   commit;

-- physicalinventory related

	delete from physicalinventorydtl where id in
   	(select id from physicalinventoryhdr where lastupdate < l_cutoff);
	dbms_output.put_line('physicalinventorydtl = '||sql%rowcount);
   commit;

	delete from physicalinventoryhdr where lastupdate < l_cutoff;
	dbms_output.put_line('physicalinventoryhdr = '||sql%rowcount);
   commit;

-- date related

	delete from appmsgs where lastupdate < l_cutoff;
	dbms_output.put_line('appmsgs = '||sql%rowcount);
   commit;

	delete from billpalletcnt where lastupdate < l_cutoff;
	dbms_output.put_line('billpalletcnt = '||sql%rowcount);
   commit;

	delete from cyclecountactivity where lastupdate < l_cutoff;
	dbms_output.put_line('cyclecountactivity = '||sql%rowcount);
   commit;

	delete from invadjactivity where lastupdate < l_cutoff;
	dbms_output.put_line('invadjactivity = '||sql%rowcount);
   commit;

	delete from userhistory where begtime < l_cutoff;
	dbms_output.put_line('userhistory = '||sql%rowcount);
   commit;

	delete from waves where lastupdate < l_cutoff
   	and not exists (select * from orderhdr where orderhdr.wave = waves.wave
      						and lastupdate >= l_cutoff);
	dbms_output.put_line('waves = '||sql%rowcount);
   commit;

end;
/

drop table zethcon_purge_orders;
drop table zethcon_purge_loads;

exit;
