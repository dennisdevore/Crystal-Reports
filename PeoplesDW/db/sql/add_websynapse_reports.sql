--
-- $Id: add_websynapse_reports.sql 5114 2010-06-14 15:55:21Z eric $
--
set serveroutput on
set verify off

declare
   return_status integer;
   return_msg VARCHAR2(1000);
begin
	 update tbl_report_types
	    set report_type_id='ZINVCLSITMLOC'
	  where report_type_id='ZINCLSITMLOC';
	  
	 update tbl_report_types
	    set report_type_id='ZINVCRTPRDINV'
	  where report_type_id='ZINCRTPRDINV';
	  
   pkg_manage_reports.usp_add_report(
     'ASOFSUMMARYCODELOT',
     'Inventory Summary',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'GENINV',
     'General Inventory',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ODRECPTDTL',
     'Order Exception Detail',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ODRECPTSUM',
     'Order Exception Summary',
     return_status,
     return_msg);
     
   pkg_manage_reports.usp_add_report(
     'ODRRECSUM',
     'Orders Received Summary',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ORDERLIST',
     'Order List',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ORDERLISTEXP',
     'Outbound Order List Export',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ORDERLISTOUT',
     'Outbound Order List',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ZCONTAINER',
     'Containers',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ZINVADJMNTD',
     'Inventory Adjustments',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ZINVCLSITMLOC',
     'Inventory by Class and Item',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ZINVCRTPRDINV',
     'Critical Product Inventory',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ZINVCYCCNTACT',
     'Cycle Count Activity',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ZINVEXPRTN',
     'Inventory Expiration',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ZINVSTKACT',
     'Stock Activity',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ZINVSTSMRYBYCST',
     'Inventory Status Summary',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ZITMMSTR',
     'Item Master',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ZORDRCVD',
     'Orders Received Summary',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ZORDREORDR',
     'Items to be Reordered',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ZORDSHPDLST',
     'Shipped Order List',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ZORDSRTSHPORDS',
     'Short-Shipped Orders',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ZPINV2CNTDTL',
     'PI Variance Two Count',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ZPIRNCTITM',
     'Inventory Variance Report',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ZRECEXPRCTORD',
     'Expected Receipts',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ZRECOPNRCPTS',
     'Open Receiving',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ZRECPOCNFMN',
     'PO Confirmation',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ZRECRCVRACT',
     'Receiver Activity',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ZREVRPTNGCDS',
     'Revenue Reporting Codes',
     return_status,
     return_msg);

   pkg_manage_reports.usp_add_report(
     'ZSHPDTLRPT',
     'Shipping Detail',
     return_status,
     return_msg);

end;
/
exit;
