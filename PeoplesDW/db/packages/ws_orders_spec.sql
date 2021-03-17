create or replace package ws_orders
as

  -- ERROR MESSAGES --
  REQUIRE_CUSTOMER          CONSTANT varchar2(50) := 'customer required';
  REQUIRE_FACILITY          CONSTANT varchar2(50) := 'facility required';
  INVALID_FACILITY          CONSTANT varchar2(50) := 'facility not for customer';
  REQUIRE_ORDERS            CONSTANT varchar2(50) := 'order numbers required';
  INVALID_QUALIFIER         CONSTANT varchar2(50) := 'invalid order qualifier';
  INVALID_STRING_COMP       CONSTANT varchar2(50) := 'invalid string comparison';
  INVALID_DATE_COMP         CONSTANT varchar2(50) := 'invalid date comparison';
  INVALID_NUMBER_COMP       CONSTANT varchar2(50) := 'invalid number comparison';
  
  NOT_IMPLEMENTED_YET       CONSTANT varchar2(50) := 'not implemented yet';
  

  -- TYPES --
  type ws_qualifier_list is table of varchar2(255) index by binary_integer;
  type ws_cancelorder_list is table of varchar2(255) index by binary_integer;
  type ws_savedata_list is table of varchar2(255) index by binary_integer;

  -- FUNCTIONS AND PROCEDURES --
  function get_orders(p_nameid in varchar2, p_custid in varchar2, p_order_type in varchar2, 
	p_order_age in varchar2, p_hdrpassthru in varchar2,
    p_qualifier_list in ws_qualifier_list) return sys_refcursor;
  
  function get_customer_items (p_custid in varchar2, p_orderid in varchar2, p_shipid in varchar2) return sys_refcursor;

  function get_custitems(p_nameid in varchar2, p_custid in varchar2, p_ordertype in varchar2) return sys_refcursor;
    
  function get_item_lots(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, p_item in varchar2) return sys_refcursor;
  function get_item_uoms(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, p_item in varchar2) return sys_refcursor;
  function get_item_baseuom(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, p_item in varchar2) return sys_refcursor;
    
  function get_order_item_count(p_nameid in varchar2, p_orderid in varchar2, p_shipid in varchar2) return number;
  function get_order_items(p_nameid in varchar2, p_orderid in varchar2, p_shipid in varchar2) return sys_refcursor;
  function get_order_wsstatus(p_nameid in varchar2, p_orderid in varchar2, p_shipid in varchar2) return sys_refcursor;
  function get_order_attachments(p_nameid in varchar2, p_orderid in varchar2) return sys_refcursor;
  
  function get_order_ship_details(p_nameid in varchar2, p_orderid in varchar2, p_shipid in varchar2) return sys_refcursor;
  
  function get_order_type(p_nameid in varchar2, p_orderid in varchar2, p_shipid in varchar2) return sys_refcursor;
  
  procedure cancel_orders(p_nameid in varchar2, p_order_list in ws_cancelorder_list, p_message out varchar2);
  
  function get_order_header(p_nameid in varchar2, p_orderid in varchar2, p_shipid in varchar2) return sys_refcursor;
  
  function create_inbound_order(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, p_savedata in ws_savedata_list) return number;
  
  function create_outbound_order(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, p_savedata in ws_savedata_list) return number;
  
  function update_order_header(p_nameid in varchar2, p_orderid in varchar2, p_shipid in varchar2, p_savedata in ws_savedata_list) return sys_refcursor;

  function get_qualifier_string(p_qualifier_row in ws_order_qualifiers%rowtype) return varchar2;
  function get_detail_qualifier_string(p_qualifier_row in ws_order_qualifiers%rowtype) return varchar2;
  function get_modifiable_qualifier_str(p_qualifier_row in ws_order_qualifiers%rowtype) return varchar2;
  
  function get_update_segment(p_update_row in ws_order_updates%rowtype) return varchar2;
  
  function create_order_item(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, 
	p_orderid in varchar2, p_shipid in varchar2, 
	p_item in varchar2, p_qty in number, p_lot in varchar2, p_uom in varchar2) return varchar2;
  
  function remove_order_item(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, 
	p_orderid in varchar2, p_shipid in varchar2, 
	p_item in varchar2, p_lot in varchar2) return varchar2;
  
  function reactivate_order_item(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, 
	p_orderid in varchar2, p_shipid in varchar2, 
	p_item in varchar2, p_lot in varchar2) return varchar2;
  
  function mark_order_complete(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, 
	p_orderid in varchar2, p_shipid in varchar2) return varchar2; 

  function save_query_parms(p_nameid in varchar2, p_custid in varchar2, p_rqst_type in varchar2,
	p_qryid in varchar2, p_savedata in ws_savedata_list) return number;

  function get_query_parms(p_nameid in varchar2, p_custid in varchar2, p_rqst_type in varchar2,
	p_qryid in varchar2) return sys_refcursor;

  function delete_query_parms(p_nameid in varchar2, p_custid in varchar2, p_rqst_type in varchar2,
	p_qryid in varchar2) return number;
    
  function get_saved_queries(p_nameid in varchar2, p_rqst_type in varchar2) return sys_refcursor;
    
  function get_custdict(p_custid in varchar2) return sys_refcursor;
  function get_custdict_label(p_custid in varchar2, p_colname in varchar2, p_dflt in varchar2) return varchar2;
    
  function query_summary_get_prefs(p_nameid in varchar2, p_qtype in varchar2, 
	p_otype in varchar2, p_hdrpassthru in varchar2, p_custid in varchar2) return sys_refcursor;
  function query_summary_save_prefs(p_nameid in varchar2, p_custid in varchar2, 
	p_qtype in varchar2, p_otype in varchar2, p_collist in ws_savedata_list) return varchar2; 
  function query_summary_reset_prefs(p_nameid in varchar2, p_custid in varchar2, 
	p_qtype in varchar2, p_otype in varchar2) return varchar2; 

  function get_hdr_passthru_columns(p_tabid in varchar2) return varchar2;
  
  function get_order_attachment(p_orderid in number) return varchar2;
  
  function check_order_duplicate(p_custid in varchar2, p_ref in varchar2, p_po in varchar2,
		p_orderid in varchar2, p_shipid in varchar2) return varchar2;

  procedure set_massitem_settings(p_nameid in varchar2, 
	p_include_status in varchar2, p_include_class in varchar2, p_display_ic in varchar2, p_message out varchar2);

  procedure get_massitem_settings(p_nameid in varchar2, 
	p_include_status out varchar2, p_include_class out varchar2, p_display_ic out varchar2, 
	p_allow_gt_allocable out varchar2, p_rlse_orders out varchar2, p_message out varchar2);
    
  function get_allocable_items(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, 
	p_invstatus in varchar2, p_invclass in varchar2, p_display_ic in varchar2) return sys_refcursor;
  
  function add_order_items(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, 
	p_orderid in varchar2, p_shipid in varchar2, p_savedata in ws_savedata_list) return number;

PROCEDURE compute_shipdate
(in_facility varchar2
,in_shipto varchar2
,in_arrivaldate varchar2
,out_shipdate  OUT varchar2
,out_msg  OUT varchar2
);

PROCEDURE compute_arrivaldate
(in_facility varchar2
,in_shipto varchar2
,in_shipdate varchar2
,out_arrivaldate IN OUT varchar2
,out_msg IN OUT varchar2
);

end ws_orders;
/

show error package ws_orders;
exit;