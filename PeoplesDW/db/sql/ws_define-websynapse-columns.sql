delete from ws_columns;

----- INVENTORY SUMMARY Table Columns -----
insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('INVENTORY', 'item', 'Item', 1, 'string', '', 90, -1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('INVENTORY', 'custid', 'Customer', 2, 'string', '', 75, -1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('INVENTORY', 'alias', 'Alias', 3, 'string', '', 100, 1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('INVENTORY', 'descr', 'Description', 4, 'string', '', 100, 2, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('INVENTORY', 'productgroup', 'Product Group', 5, 'string', '', 80, 3, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('INVENTORY', 'facility', 'Facility', 6, 'string', '', 70, -1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('INVENTORY', 'qtytotal', 'Total', 7, 'number', '', 70, -1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('INVENTORY', 'qtyalloc', 'Available', 8, 'number', '', 70, -1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('INVENTORY', 'qtybackorder', 'Back Ordered', 9, 'number', '', 70, -1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('INVENTORY', 'baseuom', 'BaseUOM', 10, 'string', '', 60, -1, 'Y', 'SYNAPSE', sysdate);

-- add new INVENTORY columns here

----- ORDER SUMMARY Table Columns -----
insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'ordershipid', 'Order ID', 1, 'string', '', 75, -1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'custid', 'Customer', 2, 'string', '', 75, 1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'fromfacility', 'From Facility', 3, 'string', 'RI', 50, -1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'tofacility', 'To Facility', 4, 'string', 'OK', 50, -1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'orderstatusabbrev', 'Status', 5, 'string', '', 75, -1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'reference', 'Reference', 6, 'string', '', 60, -1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'po', 'PO', 7, 'string', '', 60, -1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'priorityabbrev', 'Priority', 8, 'string', '', 90, 4, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'shiptypeabbrev', 'Shipment Type', 9, 'string', '', 60, 3, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'carrier', 'Carrier', 10, 'string', 'RI', 65, -1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'shiptoname', 'Ship To', 11, 'string', 'RI', 75, -1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'qtyorder', 'Qty Order', 12, 'number', '', 60, -1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'qtyrcvd', 'Qty Rcvd', 13, 'number', 'OK', 60, -1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'qtycommit', 'Qty Commit', 14, 'number', 'RI', 60, -1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'qtypick', 'Qty Pick', 15, 'number', 'RI', 60, -1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'qtyship', 'Qty Ship', 16, 'number', 'RI', 60, -1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'shipdate', 'Ship Date', 17, 'date', 'RI', 75, -1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'arrivaldate', 'Arrival Date', 18, 'date', 'RI', 75, -1, 'Y', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'billoflading', 'BOL', 19, 'string', 'RI', 60, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'isHazardous', 'Haz Items?', 20, 'boolean', '', 60, 2, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'billtoname', 'Bill To', 21, 'string', '', 75, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'prono', 'Pro Number', 22, 'string', '', 60, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'rma', 'RMA', 23, 'string', '', 60, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'statusupdate', 'Status Update', 24, 'date', '', 75, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'deliveryservice', 'Service Class', 25, 'string', '', 75, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'weightship', 'Shipment Weight', 26, 'number', '', 60, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'requested_ship', 'Requested Ship Date', 27, 'date', 'RI', 75, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'ship_no_later', 'Ship Not After Date', 28, 'date', 'RI', 75, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'ship_not_before', 'Ship Not Before Date', 29, 'date', 'RI', 75, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'delivery_requested', 'Delivery Requested Date', 30, 'date', '', 75, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'do_not_deliver_after', 'Do Not Deliver After Date', 31, 'date', '', 75, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'do_not_deliver_before', 'Do Not Deliver Before Date', 32, 'date', '', 75, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'cancel_after', 'Cancel After Date', 33, 'date', '', 75, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'cancel_if_not_delivered_by', 'Cancel If Not Delivered By Date', 34, 'date', '', 75, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'shiptocontact', 'Ship To Contact', 35, 'string', 'RI', 75, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'shiptoaddr1', 'Ship To Addr1', 36, 'string', 'RI', 75, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'shiptoaddr2', 'Ship To Addr2', 37, 'string', 'RI', 75, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'shiptocity', 'Ship To City', 38, 'string', 'RI', 75, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'shiptostate', 'Ship To State', 39, 'string', 'RI', 75, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'shiptopostalcode', 'Ship To Zip', 40, 'string', 'RI', 75, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'shiptocountrycode', 'Ship To Country', 41, 'string', 'RI', 75, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'shiptophone', 'Ship To Phone', 42, 'string', 'RI', 75, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'shiptofax', 'Ship To Fax', 43, 'string', 'RI', 75, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'shiptoemail', 'Ship To Email', 44, 'string', 'RI', 75, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'dateshipped', 'Date Shipped', 45, 'date', 'RI', 75, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'shippingcost', 'Shipping Cost', 46, 'string', 'RI', 60, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'consignee', 'Consignee', 47, 'string', 'RI', 70, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'attachment', 'Attachment', 48, 'string', '', 70, -1, 'Y', 'SYNAPSE', sysdate);

-- add new ORDERS columns here

----- ORDER SUMMARY Table Permanently Hidden Columns: target_width = 0 makes them always invisible -----
insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'websynapse_order_status', '', 996, 'hidden', '', 0, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'modifiable', '', 997, 'hidden', '', 0, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'orderstatus', '', 998, 'hidden', '', 0, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'ordertype', '', 999, 'hidden', '', 0, -1, 'N', 'SYNAPSE', sysdate);

insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
	hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
values ('ORDERS', 'ordertypeabbrev', '', 1000, 'hidden', '', 0, -1, 'N', 'SYNAPSE', sysdate);

commit;

exit;


