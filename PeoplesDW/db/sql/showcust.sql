--
-- $Id$
--
set serveroutput on
set feedback off
set verify off
prompt
prompt This script will show the table followed by the number
prompt of rows that would be deleted as a result of deleting
prompt a specific customer
prompt
accept p_custid prompt 'Enter custid: '
prompt

create table zethcon_purge_orders(orderid number, shipid number);

declare
	l_custid customer.custid%type := upper('&&p_custid');
	cnt pls_integer;
begin

   dbms_output.enable(1000000);

-- orderid related

   insert into zethcon_purge_orders
     	select orderid, shipid
        	from orderhdr
	     	where custid = l_custid;
	dbms_output.put_line('orderhdr = '||sql%rowcount);
   commit;

	select count(1) into cnt from asncartondtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('asncartondtl = '||cnt);

	select count(1) into cnt from invoiceorders where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('invoiceorders = '||cnt);

	select count(1) into cnt from lawsondtlex where orderid in
   	(select distinct orderid from zethcon_purge_orders);
   dbms_output.put_line('multishipdtl = '||cnt);

	select count(1) into cnt from multishipdtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('multishipdtl = '||cnt);

	select count(1) into cnt from neworderdtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('neworderdtl = '||cnt);

	select count(1) into cnt from oldorderdtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('oldorderdtl = '||cnt);

	select count(1) into cnt from ordercheck where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('ordercheck = '||cnt);

	select count(1) into cnt from orderdtlbolcomments where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('orderdtlbolcomments = '||cnt);

	select count(1) into cnt from orderdtlline where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('orderdtlline = '||cnt);

	select count(1) into cnt from orderhdrbolcomments where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('orderhdrbolcomments = '||cnt);

	select count(1) into cnt from qcresult where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('qcresult = '||cnt);

	select count(1) into cnt from qcresultdtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('qcresultdtl = '||cnt);

	select count(1) into cnt from tmsexport where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('tmsexport = '||cnt);

	select count(1) into cnt from worldshipdtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
   dbms_output.put_line('worldshipdtl = '||cnt);

	select count(1) into cnt from multishiphdr where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('multishiphdr = '||cnt);

--	select count(1) into cnt from orderhdr where (orderid, shipid) in
--   	(select orderid, shipid from zethcon_purge_orders);
--	dbms_output.put_line('orderhdr = '||cnt);

	select count(1) into cnt from neworderhdr where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('neworderhdr = '||cnt);

	select count(1) into cnt from oldorderhdr where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('oldorderhdr = '||cnt);

	select count(1) into cnt from orderdtl where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('orderdtl = '||cnt);

	select count(1) into cnt from orderdtlrcpt where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('orderdtlrcpt = '||cnt);

	select count(1) into cnt from orderlabor where (orderid, shipid) in
   	(select orderid, shipid from zethcon_purge_orders);
	dbms_output.put_line('orderlabor = '||cnt);

-- invoice related

	select count(1) into cnt from postdtl where invoice in
   	(select invoice from posthdr where custid = l_custid);
   dbms_output.put_line('postdtl = '||cnt);

	select count(1) into cnt from posthdr where custid = l_custid;
	dbms_output.put_line('posthdr = '||cnt);

-- workorder related

	select count(1) into cnt from custworkorderinstructions where seq in
   	(select seq from custworkorder where custid = l_custid);
	dbms_output.put_line('custworkorderinstructions = '||cnt);

	select count(1) into cnt from custworkorder where custid = l_custid;
	dbms_output.put_line('custworkorder = '||cnt);

	select count(1) into cnt from workordercomponents where custid = l_custid;
	dbms_output.put_line('workordercomponents = '||cnt);

	select count(1) into cnt from workorderinstructions where custid = l_custid;
	dbms_output.put_line('workorderinstructions = '||cnt);

-- plate related

	select count(1) into cnt from platehistory where lpid in
		(select lpid from plate where custid = l_custid);
	dbms_output.put_line('platehistory = '||cnt);

	select count(1) into cnt from plate where custid = l_custid;
	dbms_output.put_line('plate = '||cnt);

-- customer related

	select count(1) into cnt from appmsgs where custid = l_custid;
   dbms_output.put_line('appmsgs = '||cnt);

	select count(1) into cnt from asofinventory where custid = l_custid;
   dbms_output.put_line('asofinventory = '||cnt);

	select count(1) into cnt from asofinventorydtl where custid = l_custid;
   dbms_output.put_line('asofinventorydtl = '||cnt);

	select count(1) into cnt from batchtasks where custid = l_custid;
	dbms_output.put_line('batchtasks = '||cnt);

	select count(1) into cnt from billpalletcnt where custid = l_custid;
	dbms_output.put_line('billpalletcnt = '||cnt);

	select count(1) into cnt from caselabels where custid = l_custid;
	dbms_output.put_line('caselabels = '||cnt);

	select count(1) into cnt from commitments where custid = l_custid;
	dbms_output.put_line('commitments = '||cnt);

	select count(1) into cnt from custactvfacilities where custid = l_custid;
	dbms_output.put_line('custactvfacilities = '||cnt);

	select count(1) into cnt from custauditstageloc where custid = l_custid;
	dbms_output.put_line('custauditstageloc = '||cnt);

	select count(1) into cnt from custbilldates where custid = l_custid;
	dbms_output.put_line('custbilldates = '||cnt);

	select count(1) into cnt from custconsignee where custid = l_custid;
	dbms_output.put_line('custconsignee = '||cnt);

	select count(1) into cnt from custconsigneenotice where custid = l_custid;
	dbms_output.put_line('custconsigneenotice = '||cnt);

	select count(1) into cnt from custconsigneesipname where custid = l_custid;
	dbms_output.put_line('custconsigneesipname = '||cnt);

	select count(1) into cnt from custdict where custid = l_custid;
	dbms_output.put_line('custdict = '||cnt);

	select count(1) into cnt from custdispositionfacility where custid = l_custid;
	dbms_output.put_line('custdispositionfacility = '||cnt);

	select count(1) into cnt from custfacility where custid = l_custid;
	dbms_output.put_line('custfacility = '||cnt);

	select count(1) into cnt from custitem where custid = l_custid;
	dbms_output.put_line('custitem = '||cnt);

	select count(1) into cnt from custitemalias where custid = l_custid;
	dbms_output.put_line('custitemalias = '||cnt);

	select count(1) into cnt from custitembolcomments where custid = l_custid;
	dbms_output.put_line('custitembolcomments = '||cnt);

	select count(1) into cnt from custitemcount where custid = l_custid;
	dbms_output.put_line('custitemcount = '||cnt);

	select count(1) into cnt from custitemfacility where custid = l_custid;
	dbms_output.put_line('custitemfacility = '||cnt);

	select count(1) into cnt from custitemincomments where custid = l_custid;
	dbms_output.put_line('custitemincomments = '||cnt);

	select count(1) into cnt from custitemlabelprofiles where custid = l_custid;
	dbms_output.put_line('custitemlabelprofiles = '||cnt);

	select count(1) into cnt from custitemminmax where custid = l_custid;
	dbms_output.put_line('custitemminmax = '||cnt);

	select count(1) into cnt from custitemoutcomments where custid = l_custid;
	dbms_output.put_line('custitemoutcomments = '||cnt);

	select count(1) into cnt from custitemsubs where custid = l_custid;
	dbms_output.put_line('custitemsubs = '||cnt);

	select count(1) into cnt from custitemtot where custid = l_custid;
	dbms_output.put_line('custitemtot = '||cnt);

	select count(1) into cnt from custitemuom where custid = l_custid;
	dbms_output.put_line('custitemuom = '||cnt);

	select count(1) into cnt from custitemuomuos where custid = l_custid;
	dbms_output.put_line('custitemuomuos = '||cnt);

	select count(1) into cnt from custlastrenewal where custid = l_custid;
	dbms_output.put_line('custlastrenewal = '||cnt);

	select count(1) into cnt from customer where custid = l_custid;
	dbms_output.put_line('customer = '||cnt);

	select count(1) into cnt from customercarriers where custid = l_custid;
	dbms_output.put_line('customercarriers = '||cnt);

	select count(1) into cnt from custpacklist where custid = l_custid;
	dbms_output.put_line('custpacklist = '||cnt);

	select count(1) into cnt from custproductgroup where custid = l_custid;
	dbms_output.put_line('custproductgroup = '||cnt);

	select count(1) into cnt from custproductgroupfacility where custid = l_custid;
	dbms_output.put_line('custproductgroupfacility = '||cnt);

	select count(1) into cnt from custrate where custid = l_custid;
	dbms_output.put_line('custrate = '||cnt);

	select count(1) into cnt from custrategroup where custid = l_custid;
	dbms_output.put_line('custrategroup = '||cnt);

	select count(1) into cnt from custratewhen where custid = l_custid;
	dbms_output.put_line('custratewhen = '||cnt);

	select count(1) into cnt from custrenewal where custid = l_custid;
	dbms_output.put_line('custrenewal = '||cnt);

	select count(1) into cnt from custreturnreasons where custid = l_custid;
	dbms_output.put_line('custreturnreasons = '||cnt);

	select count(1) into cnt from custshipper where custid = l_custid;
	dbms_output.put_line('custshipper = '||cnt);

	select count(1) into cnt from custsqft where custid = l_custid;
	dbms_output.put_line('custsqft = '||cnt);

	select count(1) into cnt from custtradingpartner where custid = l_custid;
	dbms_output.put_line('custtradingpartner = '||cnt);

	select count(1) into cnt from cyclecountactivity where custid = l_custid;
	dbms_output.put_line('cyclecountactivity = '||cnt);

	select count(1) into cnt from deletedplate where custid = l_custid;
	dbms_output.put_line('deletedplate = '||cnt);

	select count(1) into cnt from invadjactivity where custid = l_custid;
	dbms_output.put_line('invadjactivity = '||cnt);

	select count(1) into cnt from invoicedtl where custid = l_custid;
	dbms_output.put_line('invoicedtl = '||cnt);

	select count(1) into cnt from invoicehdr where custid = l_custid;
	dbms_output.put_line('invoicehdr = '||cnt);

	select count(1) into cnt from invsession where custid = l_custid;
	dbms_output.put_line('invsession = '||cnt);

	select count(1) into cnt from itemdemand where custid = l_custid;
	dbms_output.put_line('itemdemand = '||cnt);

	select count(1) into cnt from itempickfronts where custid = l_custid;
	dbms_output.put_line('itempickfronts = '||cnt);

	select count(1) into cnt from laborstandards where custid = l_custid;
	dbms_output.put_line('laborstandards = '||cnt);

	select count(1) into cnt from pallethistory where custid = l_custid;
	dbms_output.put_line('pallethistory = '||cnt);

	select count(1) into cnt from palletinventory where custid = l_custid;
	dbms_output.put_line('palletinventory = '||cnt);

	select count(1) into cnt from qcrequest where custid = l_custid;
	dbms_output.put_line('qcrequest = '||cnt);

	select count(1) into cnt from shippingaudit where custid = l_custid;
	dbms_output.put_line('shippingaudit = '||cnt);

	select count(1) into cnt from shippingplate where custid = l_custid;
	dbms_output.put_line('shippingplate = '||cnt);

	select count(1) into cnt from subtasks where custid = l_custid;
	dbms_output.put_line('subtasks = '||cnt);

	select count(1) into cnt from tasks where custid = l_custid;
	dbms_output.put_line('tasks = '||cnt);

	select count(1) into cnt from tempcustitemout where custid = l_custid;
	dbms_output.put_line('tempcustitemout = '||cnt);

	select count(1) into cnt from temp_inbound_entry where custid = l_custid;
	dbms_output.put_line('temp_inbound_entry = '||cnt);

	select count(1) into cnt from temp_outbound_entry where custid = l_custid;
	dbms_output.put_line('temp_outbound_entry = '||cnt);

	select count(1) into cnt from usercustomer where custid = l_custid;
	dbms_output.put_line('usercustomer = '||cnt);

	select count(1) into cnt from userhistory where custid = l_custid;
	dbms_output.put_line('userhistory = '||cnt);

end;
/

drop table zethcon_purge_orders;

exit;
