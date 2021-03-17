--
-- $Id$
--
create or replace PACKAGE alps.zimportproc7

Is

procedure begin_lawson
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_beginvoice IN number
,in_endinvoice IN number
,in_use_date_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_lawson
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_order_hdr_notes
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_qualifier IN varchar2
,in_note  IN varchar2
,in_abc_revision IN varchar2
,in_ordertype IN varchar2
,in_comment_type IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure begin_stockstat846
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_17_is_available_only_yn IN varchar2
,in_short_names IN varchar2
,in_include_lotnumber IN VARCHAR2
,in_invstatus IN VARCHAR2
,in_exclude_zero IN VARCHAR2
,in_exclude_open_receipts IN VARCHAR2
,in_exclude_crossdock IN VARCHAR2
,in_av_status_only_yn IN VARCHAR2
,in_include_lip_details_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_stockstat846
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_stockstat846_by_invstat
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_include_lotnumber IN VARCHAR2
,in_exclude_zero IN VARCHAR2
,in_exclude_open_receipts IN VARCHAR2
,in_exclude_crossdock IN VARCHAR2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_stockstat846_by_invstat
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_rcptnote944
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_summarize_lots_yn IN varchar2
,in_include_zero_qty_lines_yn IN varchar2
,in_include_cancelled_orders_yn IN varchar2
,in_exclude_ide_av_invstatus_yn IN varchar2
,in_dtv_receipt_or_return_rqn IN varchar2
,in_invclass_yn IN varchar2
,in_ide_use_received_yn IN varchar2
,in_summarize_manu_yn IN varchar2
,in_lip_line_yn IN varchar2
,in_invstatus_yn IN varchar2
,in_shipper_addr_yn IN varchar2
,in_list_serialnumber_yn IN varchar2
,in_dtlrcptlines_yn IN varchar2
,in_exclude_source IN varchar2
,in_create_944_cfs_data_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_rcptnote944
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_shipnote945
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_summarize_lots_yn IN varchar2
,in_include_zero_qty_lines_yn IN varchar2
,in_include_cancelled_orders_yn IN varchar2
,in_include_fromlpid_yn IN varchar2
,in_ltl_freight_passthru IN varchar2
,in_bol_tracking_yn IN varchar2
,in_round_freight_weight_up_yn IN varchar2
,in_invclass_yn IN varchar2
,in_carton_uom IN varchar2
,in_contents_by_po IN varchar2
,in_exclude_xdockorder_yn IN varchar2
,in_abc_revisions_yn IN varchar2
,in_abc_revisions_column IN varchar2
,in_fhd_sequence IN varchar2
,in_dtllot_yn IN varchar2
,in_include_zero_qty_lot_yn IN varchar2
,in_cnt_ignore_lot_yn IN varchar2
,in_810_yn IN varchar2
,in_transaction IN varchar2
,in_enforce_edi_trans_yn IN varchar2
,in_smallpackage_by_tn_yn IN varchar2
,in_shipment_column IN varchar2
,in_aux_shipment_column IN varchar2
,in_masterbol_column IN varchar2
,in_id_passthru_yn IN varchar2
,in_track_separator IN varchar2
,in_item_descr_dtlpassthru IN varchar2
,in_upc_dtlpassthru IN varchar2
,in_include_zero_qty_ctn_yn IN varchar2
,in_force_cnt_fromlpid_yn IN varchar2
,in_create_cnt_fs_yn IN varchar2
,in_cancel_productgroup IN varchar2
,in_force_estdelivery_yn IN varchar2
,in_estdelivery_validation_tbl in varchar2
,in_cnt_groupby_useritem IN varchar2
,in_include_zero_qty_shipped_yn IN varchar2
,in_ctn_rollup_lot_yn in varchar2
,in_create_cfs_yn IN varchar2
,in_lots_qtyorder_diff_yn IN varchar2
,in_freight_cost_once_yn IN varchar2
,in_810_seq_by_custid IN varchar2
,in_order_odl_by_qty_yn IN varchar2
,in_create_945_shipment_yn IN varchar2
,in_945_shipment_single_bol_yn IN varchar2
,in_shp_no_load_assigned_sp_yn IN varchar2
,in_cost_by_trackingno_yn IN varchar2
,in_woodpalletcount_list IN varchar2
,in_lwh_in_ea_yn in varchar2
,in_allow_pick_status_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_shipnote945
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);


procedure begin_invadj947
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_exclude_zero_yn in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_invadj947
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_invadjgt947
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_facility IN varchar2
,in_partner_edi_code IN varchar2
,in_sender_edi_code IN varchar2
,in_app_sender_code IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_invadjgt947
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_prodactv852
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_prodactv852
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_shipnote856
(in_custid IN varchar2
,in_loadno IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_allow_pick_status_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_shipnote856
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_shipnote856oldworld
(in_custid IN varchar2
,in_loadno IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_shipnote856oldworld
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);



FUNCTION load_orders
(
    in_loadno   IN      number
)
RETURN varchar2;

FUNCTION split_shipment
(
    in_custid    IN      varchar2,
    in_reference IN      varchar2
)
RETURN varchar2;

FUNCTION split_item
(
    in_custid    IN      varchar2,
    in_reference IN      varchar2,
    in_item      IN      varchar2
)
RETURN varchar2;

FUNCTION sum_shipping_weight
(in_orderid IN number
,in_shipid  IN number
) return number;

FUNCTION sscc_count
(in_orderid IN number
,in_shipid  IN number
) return number;

FUNCTION changed_qty
(
    in_orderid   IN      number,
    in_shipid    IN      number,
    in_item      IN      varchar2,
    in_lotnumber IN      varchar2
)
RETURN varchar2;

procedure begin_olson945
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_olson945
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_ship_notify
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_include_zero_shipped_yn IN varchar2
,in_include_cancelled_orders_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_ship_notify
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

function pallet_count
(in_loadno IN number
,in_custid IN varchar2
,in_facility IN varchar2
,in_orderid IN number
,in_shipid IN number
,in_type IN varchar2 default null
) return integer;

procedure begin_stock_status_nsd
(in_facility IN varchar2
,in_custid IN varchar2
,in_active_items_only_yn IN varchar2
,in_exclude_zero_balance_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_stock_status_nsd
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

FUNCTION find_po
(in_lpid IN varchar2
) return varchar2;

FUNCTION abc_reference
(in_orderid IN number
,in_shipid IN number
,in_abc_revisions_column IN varchar2
) return varchar2;

procedure begin_stdinvadj947
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_947_by_transaction_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

FUNCTION ship_plate_count
(in_orderid IN number
,in_shipid IN number
) return integer;

FUNCTION line_qty_expected
(in_orderid IN number
,in_shipid IN number
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_line_number IN number
) return number;

function VICSbolNumber
(in_loadno in number
,in_orderid in number
,in_shipid in number
,in_custid varchar2
) return varchar2;

function VICSMinBolNumber
(in_loadno in number
,in_custid varchar2
,in_orderid number
,in_shipid number
,in_shipto varchar2
) return varchar2;
function VICSsubbolNumber
(in_orderid in number
,in_shipid in number
,in_custid varchar2
) return varchar2;
function check_edi
(in_orderid in number
,in_shipid in number
,in_custid varchar2
,in_transaction varchar2
,in_sipconsigneematchfield varchar2
) return varchar2;

procedure begin_wave_notify
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_movement IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_wave_notify
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

FUNCTION gt947_document
(in_lpid IN varchar2
) return varchar2;

FUNCTION lpid_last6
(in_lpid IN varchar2
) return varchar2;

FUNCTION lpid_last7
(in_lpid IN varchar2
) return varchar2;

function sn945_include_canceled
(in_cancel_productgroup in varchar2
,in_custid varchar2
,in_orderid number
,in_shipid number
,in_item varchar2
) return boolean;

FUNCTION facility_arrival_date
(in_dateshipped IN date
,in_fromfacility IN varchar2
,in_validation_table IN varchar2
) return date;

FUNCTION getdmgreason
(in_lpid varchar2
) return varchar2;

function pallet_count_by_type
(in_loadno IN number
,in_custid IN varchar2
,in_facility IN varchar2
,in_orderid IN number
,in_shipid IN number
,in_type IN varchar2 default null
,in_pallettype IN varchar2
) return integer;

function order_pallet_count_by_type
(in_custid IN varchar2
,in_facility IN varchar2
,in_orderid IN number
,in_shipid IN number
,in_pallettype IN varchar2
) return integer;
function order_pallet_count_by_list
(in_custid IN varchar2
,in_facility IN varchar2
,in_orderid IN number
,in_shipid IN number
,in_pallettypes IN varchar2
) return integer;
function cost_by_trackingno
(in_orderid IN number
,in_shipid IN number
,in_trackingno IN varchar2
) return number;
PRAGMA RESTRICT_REFERENCES (load_orders, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (split_item, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (split_shipment, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (changed_qty, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (sum_shipping_weight, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (pallet_count, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (find_po, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (ship_plate_count, WNDS, WNPS);

end zimportproc7;
/
show error package zimportproc7;
exit;
