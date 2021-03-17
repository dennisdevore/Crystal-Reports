--
-- $Id$
--
set serveroutput on
set feedback off
set verify off
prompt
prompt This script will DELETE all rows for a specific customer
prompt and display a count of the rows deleted
prompt
accept p_custid prompt 'Enter custid: '
prompt
accept p_areyousure prompt 'Are you sure (Y/N): '
prompt

create table zethcon_purge_orders(orderid number, shipid number);

declare
	l_custid customer.custid%type := upper('&&p_custid');
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
	     	where custid = l_custid;
   commit;

	delete from asncartondtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('asncartondtl = '||sql%rowcount);
   commit;

	delete from invoiceorders where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('invoiceorders = '||sql%rowcount);
   commit;

	delete from lawsondtlex where orderid in
   	(select distinct orderid from zethcon_purge_orders);
   dbms_output.put_line('multishipdtl = '||sql%rowcount);
   commit;

	delete from multishipdtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('multishipdtl = '||sql%rowcount);
   commit;

	delete from neworderdtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('neworderdtl = '||sql%rowcount);
   commit;

	delete from oldorderdtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('oldorderdtl = '||sql%rowcount);
   commit;

	delete from ordercheck where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('ordercheck = '||sql%rowcount);
   commit;

	delete from orderdtlbolcomments where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('orderdtlbolcomments = '||sql%rowcount);
   commit;

	delete from orderdtlline where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('orderdtlline = '||sql%rowcount);
   commit;

	delete from orderhdrbolcomments where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('orderhdrbolcomments = '||sql%rowcount);
   commit;

	delete from qcresult where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('qcresult = '||sql%rowcount);
   commit;

	delete from qcresultdtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('qcresultdtl = '||sql%rowcount);
   commit;

	delete from tmsexport where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('tmsexport = '||sql%rowcount);
   commit;

	delete from worldshipdtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('worldshipdtl = '||sql%rowcount);
   commit;

	delete from multishiphdr where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('multishiphdr = '||sql%rowcount);
   commit;

	delete from orderhdr where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('orderhdr = '||sql%rowcount);
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

	delete from orderdtlrcpt where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('orderdtlrcpt = '||sql%rowcount);
   commit;

	delete from orderlabor where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('orderlabor = '||sql%rowcount);
   commit;

-- invoice related

	delete from postdtl where invoice in
   	(select invoice from posthdr where custid = l_custid);
   dbms_output.put_line('postdtl = '||sql%rowcount);
   commit;

	delete from posthdr where custid = l_custid;
	dbms_output.put_line('posthdr = '||sql%rowcount);
   commit;

-- workorder related

	delete from custworkorderinstructions where seq in
   	(select seq from custworkorder where custid = l_custid);
	dbms_output.put_line('custworkorderinstructions = '||sql%rowcount);
   commit;

	delete from custworkorder where custid = l_custid;
	dbms_output.put_line('custworkorder = '||sql%rowcount);
   commit;

	delete from workordercomponents where custid = l_custid;
	dbms_output.put_line('workordercomponents = '||sql%rowcount);
   commit;

	delete from workorderinstructions where custid = l_custid;
	dbms_output.put_line('workorderinstructions = '||sql%rowcount);

-- plate related

	delete from platehistory where lpid in
		(select lpid from plate where custid = l_custid);
	dbms_output.put_line('platehistory = '||sql%rowcount);
   commit;

	delete from plate where custid = l_custid;
	dbms_output.put_line('plate = '||sql%rowcount);
   commit;

-- customer related

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

	delete from caselabels where custid = l_custid;
	dbms_output.put_line('caselabels = '||sql%rowcount);
   commit;

	delete from commitments where custid = l_custid;
	dbms_output.put_line('commitments = '||sql%rowcount);
   commit;

	delete from custactvfacilities where custid = l_custid;
	dbms_output.put_line('custactvfacilities = '||sql%rowcount);
   commit;

	delete from custauditstageloc where custid = l_custid;
	dbms_output.put_line('custauditstageloc = '||sql%rowcount);
   commit;

	delete from custbilldates where custid = l_custid;
	dbms_output.put_line('custbilldates = '||sql%rowcount);
   commit;

	delete from custconsignee where custid = l_custid;
	dbms_output.put_line('custconsignee = '||sql%rowcount);
   commit;

	delete from custconsigneenotice where custid = l_custid;
	dbms_output.put_line('custconsigneenotice = '||sql%rowcount);
   commit;

	delete from custconsigneesipname where custid = l_custid;
	dbms_output.put_line('custconsigneesipname = '||sql%rowcount);
   commit;

	delete from custdict where custid = l_custid;
	dbms_output.put_line('custdict = '||sql%rowcount);
   commit;

	delete from custdispositionfacility where custid = l_custid;
	dbms_output.put_line('custdispositionfacility = '||sql%rowcount);
   commit;

	delete from custfacility where custid = l_custid;
	dbms_output.put_line('custfacility = '||sql%rowcount);
   commit;

	delete from custitem where custid = l_custid;
	dbms_output.put_line('custitem = '||sql%rowcount);
   commit;

	delete from custitemalias where custid = l_custid;
	dbms_output.put_line('custitemalias = '||sql%rowcount);
   commit;

	delete from custitembolcomments where custid = l_custid;
	dbms_output.put_line('custitembolcomments = '||sql%rowcount);
   commit;

	delete from custitemcount where custid = l_custid;
	dbms_output.put_line('custitemcount = '||sql%rowcount);
   commit;

	delete from custitemfacility where custid = l_custid;
	dbms_output.put_line('custitemfacility = '||sql%rowcount);
   commit;

	delete from custitemincomments where custid = l_custid;
	dbms_output.put_line('custitemincomments = '||sql%rowcount);
   commit;

	delete from custitemlabelprofiles where custid = l_custid;
	dbms_output.put_line('custitemlabelprofiles = '||sql%rowcount);
   commit;

	delete from custitemminmax where custid = l_custid;
	dbms_output.put_line('custitemminmax = '||sql%rowcount);
   commit;

	delete from custitemoutcomments where custid = l_custid;
	dbms_output.put_line('custitemoutcomments = '||sql%rowcount);
   commit;

	delete from custitemsubs where custid = l_custid;
	dbms_output.put_line('custitemsubs = '||sql%rowcount);
   commit;

	delete from custitemtot where custid = l_custid;
	dbms_output.put_line('custitemtot = '||sql%rowcount);
   commit;

	delete from custitemuom where custid = l_custid;
	dbms_output.put_line('custitemuom = '||sql%rowcount);
   commit;

	delete from custitemuomuos where custid = l_custid;
	dbms_output.put_line('custitemuomuos = '||sql%rowcount);
   commit;

	delete from custlastrenewal where custid = l_custid;
	dbms_output.put_line('custlastrenewal = '||sql%rowcount);
   commit;

	delete from customer where custid = l_custid;
	dbms_output.put_line('customer = '||sql%rowcount);
   commit;

	delete from customercarriers where custid = l_custid;
	dbms_output.put_line('customercarriers = '||sql%rowcount);
   commit;

	delete from custpacklist where custid = l_custid;
	dbms_output.put_line('custpacklist = '||sql%rowcount);
   commit;

	delete from custproductgroup where custid = l_custid;
	dbms_output.put_line('custproductgroup = '||sql%rowcount);
   commit;

	delete from custproductgroupfacility where custid = l_custid;
	dbms_output.put_line('custproductgroupfacility = '||sql%rowcount);
   commit;

	delete from custrate where custid = l_custid;
	dbms_output.put_line('custrate = '||sql%rowcount);
   commit;

	delete from custrategroup where custid = l_custid;
	dbms_output.put_line('custrategroup = '||sql%rowcount);
   commit;

	delete from custratewhen where custid = l_custid;
	dbms_output.put_line('custratewhen = '||sql%rowcount);
   commit;

	delete from custrenewal where custid = l_custid;
	dbms_output.put_line('custrenewal = '||sql%rowcount);
   commit;

	delete from custreturnreasons where custid = l_custid;
	dbms_output.put_line('custreturnreasons = '||sql%rowcount);
   commit;

	delete from custshipper where custid = l_custid;
	dbms_output.put_line('custshipper = '||sql%rowcount);
   commit;

	delete from custsqft where custid = l_custid;
	dbms_output.put_line('custsqft = '||sql%rowcount);
   commit;

	delete from custtradingpartner where custid = l_custid;
	dbms_output.put_line('custtradingpartner = '||sql%rowcount);
   commit;

	delete from cyclecountactivity where custid = l_custid;
	dbms_output.put_line('cyclecountactivity = '||sql%rowcount);
   commit;

	delete from deletedplate where custid = l_custid;
	dbms_output.put_line('deletedplate = '||sql%rowcount);
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

	delete from itempickfronts where custid = l_custid;
	dbms_output.put_line('itempickfronts = '||sql%rowcount);
   commit;

	delete from laborstandards where custid = l_custid;
	dbms_output.put_line('laborstandards = '||sql%rowcount);
   commit;

	delete from pallethistory where custid = l_custid;
	dbms_output.put_line('pallethistory = '||sql%rowcount);
   commit;

	delete from palletinventory where custid = l_custid;
	dbms_output.put_line('palletinventory = '||sql%rowcount);
   commit;

	delete from qcrequest where custid = l_custid;
	dbms_output.put_line('qcrequest = '||sql%rowcount);
   commit;

	delete from shippingaudit where custid = l_custid;
	dbms_output.put_line('shippingaudit = '||sql%rowcount);
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

	delete from tempcustitemout where custid = l_custid;
	dbms_output.put_line('tempcustitemout = '||sql%rowcount);
   commit;

	delete from temp_inbound_entry where custid = l_custid;
	dbms_output.put_line('temp_inbound_entry = '||sql%rowcount);
   commit;

	delete from temp_outbound_entry where custid = l_custid;
	dbms_output.put_line('temp_outbound_entry = '||sql%rowcount);
   commit;

	delete from usercustomer where custid = l_custid;
	dbms_output.put_line('usercustomer = '||sql%rowcount);
   commit;

	delete from userhistory where custid = l_custid;
	dbms_output.put_line('userhistory = '||sql%rowcount);
   commit;

end;
/

drop table zethcon_purge_orders;

exit;
