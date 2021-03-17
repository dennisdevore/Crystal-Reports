--
-- $Id$
--
create or replace PACKAGE alps.zediproc

is

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

function get_sscc18_code
(
    in_custid   IN  varchar2,
    in_type     IN  varchar2,
    in_lpid     IN  varchar2
)
return varchar2;

function get_sscc14_code
(
    in_type     IN  varchar2,
    in_upc      IN  varchar2
)
return varchar2;

function check_ancestor
(
    in_plpid    IN  varchar2,
    in_clpid    IN  varchar2
)
return varchar2;

function get_ucc128_code
   (in_custid in varchar2,
    in_type   in varchar2,
    in_lpid   in varchar2,
    in_seq    in number)
return varchar2;

function get_load_stop_seq
   (in_orderid in number,
    in_shipid  in number)
return number;

function get_custom_bol
    (in_orderid number,
     in_shipid  number)
return varchar2;

function check_custom_bol
    (in_orderid number,
     in_shipid  number,
     in_cbol    varchar2)
return varchar2;

function import_po
    (in_custid  varchar2,
     in_po      varchar2,
     in_ord_po  varchar2)
return varchar2;

PROCEDURE edi_import_log
(
    in_transaction   in varchar2,
    in_importfileid in varchar2,
    in_custid   in varchar2,
    in_msgtext  in varchar2,
    out_msg     in out varchar2
);



PRAGMA RESTRICT_REFERENCES (get_sscc18_code, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (get_sscc14_code, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (check_ancestor, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (get_ucc128_code, WNDS, WNPS, RNPS);
-- PRAGMA RESTRICT_REFERENCES (get_load_stop_seq, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (get_custom_bol, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (import_po, WNDS, WNPS, RNPS);

end zediproc;
/
show error package zediproc;
exit;
