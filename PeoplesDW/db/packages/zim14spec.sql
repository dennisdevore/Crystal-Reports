--
-- $Id$
--
create or replace PACKAGE alps.zimportproc14

Is

procedure update_confirm_date_by_orderid
(in_orderid IN number
,in_shipid IN number
,in_confirmdate IN date
,in_userid varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_med_inv_adj
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_med_inv_adj
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_med_shipments
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_med_shipments
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_med_receipts
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_med_receipts
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

FUNCTION line_qtyentered
(in_orderid IN number
,in_shipid IN number
,in_orderitem IN varchar2
,in_orderlot IN varchar2
) return number;

FUNCTION line_uomentered
(in_orderid IN number
,in_shipid IN number
,in_orderitem IN varchar2
,in_orderlot IN varchar2
) return varchar2;

procedure begin_med_shorts
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_med_shorts
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure item_master_info
(in_custid IN varchar2
,in_item IN varchar2
,in_descr IN varchar2
,in_abbrev IN varchar2
,in_baseuom IN varchar2
,in_cube IN number
,in_weight IN number
,in_hazardous IN varchar2
,in_to_uom1 IN varchar2
,in_to_uom1_qty IN number
,in_to_uom2 IN varchar2
,in_to_uom2_qty IN number
,in_to_uom3 IN varchar2
,in_to_uom3_qty IN number
,in_to_uom4 IN varchar2
,in_to_uom4_qty IN number
,in_shelflife IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

function sum_qtyrcvdgood
(in_orderid IN number
,in_shipid IN number
) return number;

function sum_cubercvdgood
(in_orderid IN number
,in_shipid IN number
) return number;

function sum_weightrcvdgood
(in_orderid IN number
,in_shipid IN number
) return number;

function sum_qtyrcvddmgd
(in_orderid IN number
,in_shipid IN number
) return number;

function sum_cubercvddmgd
(in_orderid IN number
,in_shipid IN number
) return number;

function sum_weightrcvddmgd
(in_orderid IN number
,in_shipid IN number
) return number;

function freight_total
(in_orderid IN number
,in_shipid IN number
,in_item IN varchar2 default null
,in_lotnumber IN varchar2 default null
) return number;

function freight_cost
(in_orderid IN number
,in_shipid IN number
,in_item IN varchar2 default null
,in_lotnumber IN varchar2 default null
) return number;

function freight_weight
(in_orderid IN number
,in_shipid IN number
,in_item IN varchar2 default null
,in_lotnumber IN varchar2 default null
,in_round_up_yn IN varchar2 default 'N'
) return number;

function delivery_service
(in_orderid IN number
,in_shipid IN number
,in_item IN varchar2 default null
,in_lotnumber IN varchar2 default null
) return varchar2;

FUNCTION freight_cost_once
(in_orderid IN number
,in_shipid  IN number
) return number;

function cnt_lineitems
(in_orderid IN number
,in_shipid  IN number
) return number;

function cnt_qtyship
(in_orderid IN number
,in_shipid  IN number
,shiptype IN char
) return number;

function sum_weightship
(in_orderid IN number
,in_shipid IN number
,shiptype IN char
) return number;

function freight_cost_all_items
(in_orderid IN number
,in_shipid  IN number
,shiptype IN char
) return number;

function get_carrier_name
(in_carrier IN varchar2
,in_servicecode  IN varchar2
) return varchar2;

procedure change_item_code
(in_custid IN varchar2
,in_old_item IN varchar2
,in_new_item IN varchar2
,in_adjreason IN varchar2
,in_tasktype IN varchar2
,in_custreference IN varchar2
,in_userid IN varchar2
,in_generate_947_edi_yn varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

PRAGMA RESTRICT_REFERENCES (line_qtyentered, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (line_uomentered, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (sum_qtyrcvdgood, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (sum_cubercvdgood, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (sum_weightrcvdgood, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (sum_qtyrcvddmgd, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (sum_cubercvddmgd, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (sum_weightrcvddmgd, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (freight_total, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (freight_cost, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (freight_weight, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (delivery_service, WNDS, WNPS, RNPS);

end zimportproc14;

/
show error package zimportproc14;
--exit;
