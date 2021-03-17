--
-- $Id$
--
create or replace PACKAGE alps.zmi3proc

is

procedure insert_damaged_info
(in_lpid IN varchar2
,in_facility IN varchar2
,in_custid IN varchar2
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_inventoryclass IN varchar2
,in_invstatus IN varchar2
,in_uom IN varchar2
,in_adjqty IN number
,in_adjreason IN varchar2
,in_tasktype IN varchar2
,in_adjuser IN varchar2
,out_rowid IN OUT varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure insert_interface_info
(in_lpid IN varchar2
,in_facility IN varchar2
,in_custid IN varchar2
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_inventoryclass IN varchar2
,in_invstatus IN varchar2
,in_uom IN varchar2
,in_adjqty IN number
,in_adjreason IN varchar2
,in_tasktype IN varchar2
,in_adjuser IN varchar2
,out_rowid IN OUT varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure validate_interface
(in_adjrowid IN rowid
,out_movement_code IN OUT varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure get_valid_status_class_reasons
(in_change_type IN varchar2
,in_custid IN varchar2
,in_whse IN varchar2
,in_from_inventoryclass IN varchar2
,in_from_invstatus IN varchar2
,in_to_inventoryclass IN varchar2
,in_to_invstatus IN varchar2
,out_msg IN out varchar2
);

procedure get_valid_quantity_reasons
(in_change_type IN varchar2
,in_custid IN varchar2
,in_whse IN varchar2
,in_from_inventoryclass IN varchar2
,in_from_invstatus IN varchar2
,in_to_inventoryclass IN varchar2
,in_to_invstatus IN varchar2
,out_msg IN out varchar2
);

procedure get_cust_parm_value
(in_custid IN varchar2
,in_parm IN varchar2
,out_descr IN OUT varchar2
,out_abbrev IN OUT varchar2
);

procedure get_whse
(in_custid IN varchar2
,in_inventoryclass IN varchar2
,out_whse IN OUT varchar2
,out_regular_whse IN OUT varchar2
,out_returns_whse IN OUT varchar2
);

procedure get_whse_parm_value
(in_custid IN varchar2
,in_whse IN varchar2
,in_parm IN varchar2
,out_descr IN OUT varchar2
,out_abbrev IN OUT varchar2
);

procedure check_for_shipto_override
(in_custid IN varchar2
,in_shipto IN varchar2
,out_movement_code IN OUT varchar2
);

procedure get_movement_config_value
(in_code IN varchar2
,in_custid IN varchar2
,in_whse IN varchar2
,out_movement_code IN OUT varchar2
,out_descr IN OUT varchar2
,out_abbrev IN OUT varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure get_status_or_class_movement
(in_change_type IN varchar2
,in_custid IN varchar2
,in_whse IN varchar2
,in_from_inventoryclass IN varchar2
,in_from_invstatus IN varchar2
,in_to_inventoryclass IN varchar2
,in_to_invstatus IN varchar2
,in_reason_code IN varchar2
,in_adjqty IN number
,out_movement_code IN OUT varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure get_quantity_movement
(in_change_type IN varchar2
,in_custid IN varchar2
,in_whse IN varchar2
,in_from_inventoryclass IN varchar2
,in_from_invstatus IN varchar2
,in_to_inventoryclass IN varchar2
,in_to_invstatus IN varchar2
,in_reason_code IN varchar2
,in_adjqty IN number
,out_movement_code IN OUT varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure get_movement_code
(in_custid IN varchar2
,in_whse IN varchar2
,in_from_inventoryclass IN varchar2
,in_from_invstatus IN varchar2
,in_to_inventoryclass IN varchar2
,in_to_invstatus IN varchar2
,in_reason_code IN varchar2
,in_adjqty IN number
,out_movement_code IN OUT varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);


procedure get_cto_sto_prefix
(in_custid IN varchar2
,in_item IN varchar2
,out_prefix IN OUT number
);

procedure reset_cto_sto_prefix
(in_custid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure check_for_customer_return
(in_lpid IN varchar2
,in_inventoryclass IN varchar2
,out_is_customer_return IN OUT varchar2
);

end zmi3proc;
/
show error package zmi3proc;
--exit;
