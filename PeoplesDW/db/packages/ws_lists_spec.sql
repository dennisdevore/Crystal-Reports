create or replace package ws_lists
as

  function get_initial_data return sys_refcursor;
  
  function get_customer_lists(p_nameid in varchar2, p_custid in varchar2) return sys_refcursor;

  function get_facility_list return sys_refcursor;
  
  function get_usergroup_list return sys_refcursor;
  
  function get_userstatus_list return sys_refcursor;
  
  function get_state_list return sys_refcursor;
  
  function get_country_list return sys_refcursor;
  
  function get_customer_list return sys_refcursor;
  
  function get_ordertype_list return sys_refcursor;
  function get_orderstatus_list return sys_refcursor;
  function get_orderpriority_list return sys_refcursor;

  function get_custuserfacility_list(p_nameid in varchar2, p_custid in varchar2) return sys_refcursor;
  
  function get_shipmenttype_list return sys_refcursor;
  function get_shipmentterms_list return sys_refcursor;
  
  function get_deliveryservice_list(p_carrier in varchar2) return sys_refcursor;
  
  function get_custshipto_list(p_custid in varchar2) return sys_refcursor;
  function get_custbillto_list(p_custid in varchar2) return sys_refcursor;
  function get_custshipper_list(p_custid in varchar2) return sys_refcursor;
  function get_custlotrequired_dflt(p_custid in varchar2) return sys_refcursor;
  
  function get_carriers return sys_refcursor;

  function get_reports return sys_refcursor;
  function get_report_path return sys_refcursor;
  function get_report_format(p_nameid in varchar2) return sys_refcursor;

  function get_timeout return sys_refcursor;
  function get_massentry_allowed return sys_refcursor;

  function get_page_size return sys_refcursor;
  function get_help_url return sys_refcursor;
  function get_help_urlx(p_ip in varchar2) return sys_refcursor;
  function get_report_dest return sys_refcursor;
  function get_report_url return sys_refcursor;

end ws_lists;
/

show error package ws_lists;
exit;