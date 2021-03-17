create or replace package ws_admin
as
  
  -- ERROR MESSAGES --
  REQUIRE_NAMEID            CONSTANT varchar2(50) := 'nameid required';
  INVALID_NAMEID            CONSTANT varchar2(50) := 'nameid invalid';
  REQUIRE_CUST_FLAG         CONSTANT varchar2(50) := 'customer flag required';
  INVALID_CUST_FLAG         CONSTANT varchar2(50) := 'customer flag invalid';
  REQUIRE_FACILITY_FLAG     CONSTANT varchar2(50) := 'facility flag required';
  INVALID_FACILITY_FLAG     CONSTANT varchar2(50) := 'facility flag invalid';

  -- TYPES --
  type ws_customer_list is table of varchar2(255) index by binary_integer;
  type ws_facility_list is table of varchar2(255) index by binary_integer;
  type ws_report_list is table of varchar2(255) index by binary_integer;
  
  -- FUNCTIONS AND PROCEDURES --
  function get_user_list (p_nameid in varchar2, p_custid in varchar2) return sys_refcursor;
  
  function validate_nameid (p_nameid in varchar2, p_update_user in varchar2 default null) return varchar2;
  
  function validate_customer_flag (p_customer_flag in varchar2) return varchar2;
  
  function validate_facility_flag (p_facility_flag in varchar2) return varchar2;
  
  procedure reset_password (p_nameid in varchar2, p_password in varchar2);
  
  procedure update_user_basic_info(p_nameid in varchar2, p_username in varchar2, 
	p_groupid in varchar2, p_facility in varchar2, p_userstatus in varchar2,
	p_ws_reports in varchar2, p_ws_report_admin in varchar2,
	p_ws_admin in varchar2, p_ws_inv_inq in varchar2,
	p_ws_ord_inq in varchar2, p_ws_ord_add in varchar2,
	p_ws_ord_can in varchar2, p_ws_ord_mod in varchar2,
	p_update_user in varchar2, p_custid in varchar2, p_pswd in varchar2);
  
  function get_user_basic_info(p_nameid in varchar2) return sys_refcursor;
  function get_user_access_info(p_nameid in varchar2) return sys_refcursor;
  
  procedure update_user_contact_info (p_nameid in varchar2, p_title in varchar2, p_street_1 in varchar2, p_street_2 in varchar2, p_city in varchar2, p_state in varchar2,
    p_postal_code in varchar2, p_country in varchar2, p_phone in varchar2, p_fax in varchar2, p_email in varchar2, p_update_user in varchar2);
    
  function get_user_contact_info (p_nameid in varchar2) return sys_refcursor;
  
  procedure update_user_customers (p_nameid in varchar2, p_customer_flag in varchar2, p_customers in ws_customer_list, p_update_user in varchar2);
  
  function get_user_customers (p_nameid in varchar2) return sys_refcursor;
  
  procedure update_user_facilities (p_nameid in varchar2, p_facility_flag in varchar2, p_facilities in ws_facility_list, p_update_user in varchar2);
  
  function get_user_facilities (p_nameid in varchar2) return sys_refcursor;
  
  procedure update_user_reports (p_nameid in varchar2, p_reports_flag in varchar2, p_reports in ws_report_list, p_update_user in varchar2);
  
  function get_user_reports (p_nameid in varchar2, p_custid in varchar2) return sys_refcursor;

  function check_user_exists (p_nameid in varchar2, p_newuser in varchar2) return sys_refcursor;
  
end ws_admin;
/

show error package ws_admin;
exit;
