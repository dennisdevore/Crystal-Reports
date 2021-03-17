create or replace package ws_security
as

  -- ERROR MESSAGES --
  INVALID_USER               CONSTANT varchar2(50) := 'invalid user';
  INVALID_CUSTOMER           CONSTANT varchar2(50) := 'customer not valid or not active';
  INVALID_FACILITY           CONSTANT varchar2(50) := 'facility not valid or not active';
  INVALID_ORDER              CONSTANT varchar2(50) := 'order not found';
  NONMODIFIABLE_ORDER        CONSTANT varchar2(50) := 'order not modifiable';
  NA_CUSTOMER                CONSTANT varchar2(50) := 'user not authorized for this customer';
  NA_FACILITY                CONSTANT varchar2(50) := 'user not authorized for this facility';
  
  -- FUNCTIONS AND PROCEDURES --
  function get_user_customers (p_nameid in varchar2) return sys_refcursor;
  
  function get_user_facilities (p_nameid in varchar2) return sys_refcursor;
  
  function validate_user(p_nameid in varchar2) return varchar2;
  
  function validate_customer (p_nameid in varchar2, p_custid in varchar2) return varchar2;
  
  function validate_facility (p_nameid in varchar2, p_facility in varchar2) return varchar2;
  
  function validate_order (p_nameid in varchar2, p_orderid in number, p_shipid in number) return varchar2;
  
  function validate_order_modifiable (p_nameid in varchar2, p_orderid in number, p_shipid in number) return varchar2;

  procedure logout_ws_user
   (in_userid    in varchar2,
    out_error    out number,
    out_message  out varchar2);

  procedure kill_ws_user
   (in_userid    in varchar2,
    out_error    out number,
    out_message  out varchar2);

  procedure log_user_activity
   (in_userid    in varchar2,
    in_custid    in varchar2,
    in_facility  in varchar2,
    in_pgm       in varchar2,
    in_opcode    in varchar2,
    in_parms     in varchar2,
    in_ipaddr    in varchar2,
    in_session   in varchar2,
    out_message  out varchar2);

end ws_security;
/

show error package ws_security;
exit;